import AVFoundation
import Observation
import os

/// Owns the audio engine and the person's soundscape mix.
///
/// Different parts of the app "hold" the engine for different reasons (a session, a preview
/// in the mixer, a breathing exercise, a ringing bell). The engine fades in when the first
/// reason appears and shuts down shortly after the last one goes away.
@Observable
final class SoundscapeEngine {
    enum Reason: Hashable {
        case session
        case preview
        case breathing
        case bell
    }

    private(set) var mix: SoundMix
    private(set) var band: BinauralBand
    /// Overall soundscape volume, 0...1.
    var volume: Double {
        didSet {
            applyMaster()
            defaults.set(volume, forKey: PreferenceKey.soundVolume)
        }
    }

    private(set) var isRunning = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private var renderer: SoundscapeRenderer?
    @ObservationIgnored private var reasons: Set<Reason> = []
    @ObservationIgnored private var stopTask: Task<Void, Never>?
    @ObservationIgnored private var bellTask: Task<Void, Never>?
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []
    @ObservationIgnored private let logger = Logger(subsystem: "dev.stillpoint", category: "sound")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: PreferenceKey.soundMix),
           let saved = try? JSONDecoder().decode(SoundMix.self, from: data) {
            mix = saved
        } else {
            mix = .default
        }
        band = BinauralBand(rawValue: defaults.string(forKey: PreferenceKey.binauralBand) ?? "") ?? .alpha
        volume = defaults.object(forKey: PreferenceKey.soundVolume) as? Double ?? PreferenceKey.Default.soundVolume
        observeAudioSession()
    }

    // MARK: - Holding the engine

    func acquire(_ reason: Reason) {
        reasons.insert(reason)
        stopTask?.cancel()
        startEngineIfNeeded()
        applyMaster()
    }

    func release(_ reason: Reason) {
        reasons.remove(reason)
        applyMaster()
        if reasons.isEmpty {
            scheduleStop()
        }
    }

    // MARK: - Mix

    func setLevel(_ level: Double, for layer: SoundLayer) {
        mix = mix.setting(level, for: layer)
        renderer?.setTarget(Self.gain(for: mix.level(for: layer)), for: layer)
        persistMix()
    }

    func apply(_ preset: SoundMix) {
        mix = preset
        pushLevels()
        persistMix()
    }

    func setBand(_ band: BinauralBand) {
        self.band = band
        renderer?.binaural.beatFrequency.set(band.frequency)
        defaults.set(band.rawValue, forKey: PreferenceKey.binauralBand)
    }

    /// Strikes the singing bowl, starting the engine briefly if it isn't already running.
    func ringBell(strength: Float = 0.8) {
        acquire(.bell)
        renderer?.bell.ring(strength: strength)
        bellTask?.cancel()
        bellTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(9))
            guard !Task.isCancelled else { return }
            self?.release(.bell)
        }
    }

    // MARK: - Engine lifecycle

    private func startEngineIfNeeded() {
        if let engine, engine.isRunning { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            let engine = try engine ?? makeEngine()
            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            logger.error("Couldn't start audio: \(error.localizedDescription)")
            isRunning = false
        }
    }

    private func makeEngine() throws -> AVAudioEngine {
        let engine = AVAudioEngine()
        let hardwareRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let sampleRate = hardwareRate > 0 ? hardwareRate : 48_000
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            throw SoundscapeError.unsupportedFormat
        }
        let renderer = SoundscapeRenderer(sampleRate: Float(sampleRate))
        renderer.binaural.beatFrequency.set(band.frequency)
        let node = SoundscapeRenderer.makeSourceNode(for: renderer, format: format)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)

        self.engine = engine
        self.renderer = renderer
        pushLevels()
        observeConfigurationChanges(of: engine)
        return engine
    }

    private func scheduleStop() {
        stopTask?.cancel()
        stopTask = Task { [weak self] in
            // Let the master fade finish before stopping.
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, let self, self.reasons.isEmpty else { return }
            self.engine?.stop()
            self.isRunning = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func applyMaster() {
        let isAudible = !reasons.subtracting([.bell]).isEmpty
        renderer?.master.set(isAudible ? Float(volume * volume) : 0)
    }

    private func pushLevels() {
        for layer in SoundLayer.allCases {
            renderer?.setTarget(Self.gain(for: mix.level(for: layer)), for: layer)
        }
    }

    private func persistMix() {
        if let data = try? JSONEncoder().encode(mix) {
            defaults.set(data, forKey: PreferenceKey.soundMix)
        }
    }

    /// Slider positions feel linear to the ear when squared.
    private static func gain(for level: Double) -> Float {
        Float(level * level)
    }

    // MARK: - System events

    private func observeAudioSession() {
        let token = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            MainActor.assumeIsolated {
                guard rawType == AVAudioSession.InterruptionType.ended.rawValue else { return }
                self?.recoverAfterInterruption()
            }
        }
        observers.append(token)
    }

    private func observeConfigurationChanges(of engine: AVAudioEngine) {
        let token = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.recoverAfterInterruption()
            }
        }
        observers.append(token)
    }

    private func recoverAfterInterruption() {
        guard !reasons.isEmpty else { return }
        startEngineIfNeeded()
        applyMaster()
    }
}
