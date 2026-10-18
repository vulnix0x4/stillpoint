import Synchronization

/// A lock-free float that the main thread writes and the audio thread reads.
nonisolated final class AtomicFloat: Sendable {
    private let storage: Atomic<UInt32>

    init(_ value: Float) {
        storage = Atomic(value.bitPattern)
    }

    var value: Float {
        Float(bitPattern: storage.load(ordering: .relaxed))
    }

    func set(_ value: Float) {
        storage.store(value.bitPattern, ordering: .relaxed)
    }
}
