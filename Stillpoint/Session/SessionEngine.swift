import Foundation
import Observation
import os
import SwiftData

/// Runs a focus session from arrival to reflection, and keeps every side effect in step:
/// sound, Live Activity, notifications, screen wake, persistence and widgets.
@Observable
final class SessionEngine {
    private(set) var stage: SessionStage = .idle {
        didSet {
            if stage != oldValue {
                logger.info("Stage \(String(describing: oldValue)) → \(String(describing: self.stage))")
            }
        }
    }
    /// Drives the full-screen session presentation.
    var isSessionPresented = false {
        didSet {
            if isSessionPresented != oldValue {
                logger.info("Presented \(self.isSessionPresented) at stage \(String(describing: self.stage))")
            }
        }
    }
    private(set) var plan = SessionPlan()
    private(set) var clock: SessionClock?
    private(set) var calm = CalmTracker()
    private(set) var goalReached = false
    /// The session being focused on or reflected upon.
    private(set) var activeSession: FocusSession?
    /// Increments each time a thought is parked, so views can respond.
    private(set) var parkedCount = 0

    @ObservationIgnored let sound: SoundscapeEngine
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let liveActivity = LiveActivityController()
    @ObservationIgnored private let notifications = NotificationScheduler()
    @ObservationIgnored private let store: ActiveSessionStore
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var reportedDepth: FocusDepth?
    @ObservationIgnored private var lastCheckpoint = Date.distantPast
    @ObservationIgnored private let logger = Logger(subsystem: "dev.stillpoint", category: "session")

    init(modelContext: ModelContext, sound: SoundscapeEngine, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.sound = sound
        self.defaults = defaults
        store = ActiveSessionStore(defaults: defaults)
    }

    // MARK: - Derived state

    func frame(at now: Date) -> SessionFrame {
        guard let clock else { return .idle }
        return SessionFrame(clock: clock, calm: calm, goalReached: goalReached, at: now)
    }

    var thoughtsThisSession: [ParkedThought] {
        activeSession?.sortedThoughts ?? []
    }

    // MARK: - Starting

    func begin(_ plan: SessionPlan) {
        guard stage == .idle else { return }
        self.plan = plan
        isSessionPresented = true
        if plan.arriveFirst {
            stage = .arriving
            sound.acquire(.breathing)
        } else {
            startFocus()
        }
    }

    /// Called when the arrival breathing finishes or is skipped.
    func finishArrival() {
        guard stage == .arriving else { return }
        startFocus()
        sound.release(.breathing)
    }

    func cancelArrival() {
        guard stage == .arriving else { return }
        sound.release(.breathing)
        reset()
    }

    func startFromShortcut(minutes: Int?, intention: String) {
        // A shortcut can launch the app before the UI's restore runs; never start a new
        // session on top of one that is still in the store.
        restoreIfNeeded()
        guard stage == .idle else { return }
        begin(SessionPlan(intention: intention, plannedMinutes: minutes, arriveFirst: false))
    }

    private func startFocus(at now: Date = .now) {
        let clock = SessionClock(plannedDuration: plan.plannedDuration, startedAt: now)
        let session = FocusSession(
            startDate: now,
            plannedDuration: clock.plannedDuration,
            intention: plan.intention,
            usedArrival: plan.arriveFirst,
            soundscapeName: sound.mix.isSilent ? nil : sound.mix.name
        )
        modelContext.insert(session)
        try? modelContext.save()

        self.clock = clock
        calm = CalmTracker()
        goalReached = false
        reportedDepth = .settling
        activeSession = session
        lastCheckpoint = now
        stage = .focusing

        sound.acquire(.session)
        if chimeEnabled {
            sound.ringBell(strength: 0.45)
        }
        ScreenAwake.set(defaults.bool(forKey: PreferenceKey.keepScreenAwake, default: PreferenceKey.Default.keepScreenAwake))
        scheduleNotification()
        if liveActivitiesEnabled {
            liveActivity.start(attributes: activityAttributes, state: activityState(at: now))
        }
        persist()
        startTicking()
    }

    // MARK: - During focus

    func pause(at now: Date = .now) {
        guard stage == .focusing, var clock, !clock.isPaused else { return }
        clock.pause(at: now)
        self.clock = clock
        notifications.cancelCompletion()
        sound.release(.session)
        liveActivity.update(activityState(at: now))
        persist()
    }

    func resume(at now: Date = .now) {
        guard stage == .focusing, var clock, clock.isPaused else { return }
        clock.resume(at: now)
        self.clock = clock
        calm.noteResumed(atElapsed: clock.elapsed(at: now))
        reportedDepth = .settling
        sound.acquire(.session)
        scheduleNotification()
        liveActivity.update(activityState(at: now))
        persist()
    }

    func togglePause() {
        if clock?.isPaused == true {
            resume()
        } else {
            pause()
        }
    }

    /// Saves a stray thought without leaving the session.
    func parkThought(_ text: String, at now: Date = .now) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let thought = ParkedThought(text: trimmed, createdAt: now, session: stage == .focusing ? activeSession : nil)
        modelContext.insert(thought)

        if stage == .focusing, let clock {
            calm.noteThoughtParked(atElapsed: clock.elapsed(at: now))
            parkedCount += 1
            persist()
        } else if stage == .idle {
            attachToStoredSession(thought, at: now)
        }
        try? modelContext.save()
    }

    /// When a shortcut launches the app in the background, the session UI hasn't been
    /// restored, but a session may still be running. Attach the thought to it quietly.
    private func attachToStoredSession(_ thought: ParkedThought, at now: Date) {
        guard var saved = store.load(), saved.isReflecting != true else { return }
        let id = saved.sessionID
        let descriptor = FetchDescriptor<FocusSession>(predicate: #Predicate { $0.id == id })
        guard let session = try? modelContext.fetch(descriptor).first else { return }
        thought.session = session
        saved.calm.noteThoughtParked(atElapsed: saved.clock.elapsed(at: now))
        store.save(saved)
    }

    /// Ends focus and moves to reflection.
    func finish(at now: Date = .now) {
        guard stage == .focusing, let clock, let activeSession else { return }
        let elapsed = clock.elapsed(at: now)
        activeSession.endDate = now
        activeSession.focusedDuration = elapsed
        activeSession.pauseCount = clock.pauseCount
        activeSession.reachedGoal = goalReached || clock.hasReachedGoal(at: now)
        activeSession.longestCalmStretch = calm.longest(atElapsed: elapsed)
        try? modelContext.save()

        stopTicking()
        notifications.cancelCompletion()
        liveActivity.end()
        sound.release(.session)
        ScreenAwake.set(false)
        stage = .reflecting
        persist()
    }

    // MARK: - Reflection

    func saveReflection(outcome: SessionOutcome?, depth: Int?, note: String) {
        guard stage == .reflecting, let activeSession else { return }
        activeSession.outcome = outcome
        activeSession.depthRating = depth
        activeSession.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        activeSession.isFinalized = true
        try? modelContext.save()
        store.clear()
        WidgetSync.refresh(using: modelContext, defaults: defaults)
        reset()
    }

    func discardSession() {
        if stage == .focusing {
            stopTicking()
            notifications.cancelCompletion()
            liveActivity.end()
            sound.release(.session)
            ScreenAwake.set(false)
            store.clear()
        }
        store.clear()
        if let activeSession {
            modelContext.delete(activeSession)
            try? modelContext.save()
        }
        reset()
    }

    // MARK: - Restoration

    /// Brings back a session that was running when the app was terminated.
    func restoreIfNeeded(at now: Date = .now) {
        logger.info("Restore requested at stage \(String(describing: self.stage))")
        guard stage == .idle else { return }
        guard let saved = store.load() else {
            cleanUpAbandonedSessions(keeping: nil)
            liveActivity.end()
            return
        }
        let id = saved.sessionID
        cleanUpAbandonedSessions(keeping: id)
        let descriptor = FetchDescriptor<FocusSession>(predicate: #Predicate { $0.id == id })
        guard let session = try? modelContext.fetch(descriptor).first else {
            store.clear()
            liveActivity.end()
            return
        }

        plan = saved.plan
        clock = saved.clock
        calm = saved.calm
        goalReached = saved.goalReached
        activeSession = session
        isSessionPresented = true

        // Focus already ended; only the reflection was interrupted.
        if saved.isReflecting == true {
            stage = .reflecting
            liveActivity.end()
            return
        }

        stage = .focusing
        reportedDepth = frame(at: now).depth

        // The app was dead for a long while with the session still running. Rather than
        // count hours nobody was there for, close the session where it plausibly ended.
        lastCheckpoint = saved.lastSeenAt ?? saved.clock.startedAt
        if let ended = Self.unattendedEnd(of: saved.clock, lastSeen: lastCheckpoint, now: now) {
            finish(at: ended)
            return
        }

        liveActivity.adoptExisting()
        if !liveActivity.isRunning, liveActivitiesEnabled {
            liveActivity.start(attributes: activityAttributes, state: activityState(at: now))
        } else {
            liveActivity.update(activityState(at: now))
        }
        if !saved.clock.isPaused {
            sound.acquire(.session)
        }
        ScreenAwake.set(defaults.bool(forKey: PreferenceKey.keepScreenAwake, default: PreferenceKey.Default.keepScreenAwake))
        startTicking()
    }

    /// How long the app can be gone before a still-running session counts as unattended.
    static let unattendedLimit: TimeInterval = 30 * 60
    /// Open-ended sessions end themselves after this long.
    static let openEndedCap: TimeInterval = 4 * 3600

    /// Overtime is capped at an hour, or the planned length if that's longer.
    static func overtimeCap(for planned: TimeInterval) -> TimeInterval {
        max(3600, planned)
    }

    /// Decides whether a running session has really already ended, and when. A session left
    /// running while nobody was there shouldn't pile up hours of focus:
    /// - past its goal and unattended for a while → it ended at the goal;
    /// - overtime beyond the cap → it ended at the cap;
    /// - open-ended beyond four hours → it ended at four hours.
    /// Returns `nil` when the session should simply carry on.
    static func unattendedEnd(of clock: SessionClock, lastSeen: Date, now: Date) -> Date? {
        guard !clock.isPaused else { return nil }
        guard let goal = clock.goalDate, let planned = clock.plannedDuration else {
            let capEnd = clock.effectiveStart.addingTimeInterval(openEndedCap)
            return now > capEnd ? capEnd : nil
        }
        let capEnd = goal.addingTimeInterval(overtimeCap(for: planned))
        if now > capEnd {
            return max(goal, min(capEnd, max(lastSeen, goal)))
        }
        guard goal < now, now.timeIntervalSince(lastSeen) > unattendedLimit else { return nil }
        return max(goal, min(lastSeen, now))
    }

    /// Sessions that were never reflected on and aren't being restored: keep anything
    /// substantial (counted, unrated), drop the rest.
    private func cleanUpAbandonedSessions(keeping keptID: UUID?) {
        let descriptor = FetchDescriptor<FocusSession>(predicate: #Predicate { !$0.isFinalized })
        guard let abandoned = try? modelContext.fetch(descriptor) else { return }
        for session in abandoned where session.id != keptID {
            if session.focusedDuration >= 60 {
                session.isFinalized = true
            } else {
                modelContext.delete(session)
            }
        }
        try? modelContext.save()
    }

    // MARK: - Ticking

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick(at: .now)
            }
        }
    }

    private func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    /// Advances time-based state. Called every second while focusing; internal so tests can
    /// drive time directly.
    func tick(at now: Date) {
        guard stage == .focusing, let clock else { return }

        // Catches a suspended app waking long after the goal, and runaway overtime.
        if let ended = Self.unattendedEnd(of: clock, lastSeen: lastCheckpoint, now: now) {
            finish(at: ended)
            return
        }

        if now.timeIntervalSince(lastCheckpoint) >= 60 {
            checkpoint(at: now)
        }

        if !goalReached, clock.hasReachedGoal(at: now) {
            reachGoal(at: now)
            return
        }

        let depth = frame(at: now).depth
        if depth != reportedDepth {
            reportedDepth = depth
            liveActivity.update(activityState(at: now))
        }
    }

    private func reachGoal(at now: Date) {
        let goalAt = clock?.goalDate ?? now
        goalReached = true
        // Only ring if we're actually there for the moment, not hours later after a relaunch.
        if chimeEnabled, now.timeIntervalSince(goalAt) < 10 {
            sound.ringBell(strength: 0.9)
        }
        persist()

        if completionBehavior == .endSession {
            finish(at: min(now, goalAt))
        } else {
            liveActivity.update(activityState(at: now))
        }
    }

    // MARK: - Helpers

    private var completionBehavior: CompletionBehavior {
        CompletionBehavior(rawValue: defaults.string(forKey: PreferenceKey.completionBehavior) ?? "") ?? .keepFlowing
    }

    private var liveActivitiesEnabled: Bool {
        defaults.bool(forKey: PreferenceKey.liveActivitiesEnabled, default: PreferenceKey.Default.liveActivitiesEnabled)
    }

    private var chimeEnabled: Bool {
        defaults.bool(forKey: PreferenceKey.chimeEnabled, default: PreferenceKey.Default.chimeEnabled)
    }

    private func scheduleNotification() {
        guard let goalDate = clock?.goalDate, !goalReached else { return }
        let intention = plan.intention
        let notifications = notifications
        Task {
            await notifications.scheduleCompletion(at: goalDate, intention: intention)
        }
    }

    private var activityAttributes: FocusActivityAttributes {
        FocusActivityAttributes(
            intention: plan.intention,
            plannedDuration: plan.plannedDuration,
            paletteName: defaults.string(forKey: PreferenceKey.palette) ?? OrbPalette.ember.rawValue
        )
    }

    private func activityState(at now: Date) -> FocusActivityAttributes.ContentState {
        let frame = frame(at: now)
        let phase: FocusActivityAttributes.ContentState.Phase = if frame.isPaused {
            .paused
        } else if frame.goalReached {
            .overtime
        } else {
            .focusing
        }

        // While overtime, the goal date is in the past and the widget counts up from it.
        let goalDate = clock.flatMap { clock in
            clock.plannedDuration.map { clock.effectiveStart.addingTimeInterval($0) }
        }

        return FocusActivityAttributes.ContentState(
            phase: phase,
            goalDate: frame.isPaused ? nil : goalDate,
            effectiveStart: clock?.effectiveStart ?? now,
            frozenSeconds: frame.goalReached && !frame.isOpenEnded ? frame.overtime : (frame.remaining ?? frame.elapsed),
            depthTitle: frame.depth.title,
            isOvertime: frame.goalReached && !frame.isOpenEnded
        )
    }

    private func persist(at now: Date = .now) {
        guard let clock, let activeSession else { return }
        store.save(PersistedSession(
            sessionID: activeSession.id,
            plan: plan,
            clock: clock,
            calm: calm,
            goalReached: goalReached,
            isReflecting: stage == .reflecting,
            lastSeenAt: now
        ))
    }

    /// Writes progress so far into the session record and the store, so that if the app
    /// is killed, the focus already done isn't lost. Called every minute and when the app
    /// leaves the foreground.
    func checkpoint(at now: Date = .now) {
        guard stage == .focusing, let clock, let activeSession else { return }
        lastCheckpoint = now
        activeSession.endDate = now
        activeSession.focusedDuration = clock.elapsed(at: now)
        try? modelContext.save()
        persist(at: now)
    }

    private func reset() {
        stopTicking()
        stage = .idle
        isSessionPresented = false
        clock = nil
        calm = CalmTracker()
        goalReached = false
        activeSession = nil
        reportedDepth = nil
    }
}
