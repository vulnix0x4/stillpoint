import Foundation

/// A stereo sound source rendered on the real-time audio thread.
///
/// Implementations must not allocate, lock, or call into Objective-C while rendering.
nonisolated protocol SignalGenerator: AnyObject {
    /// Overwrites `frames` samples in each buffer.
    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int)
}
