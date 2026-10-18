import Foundation

enum SoundscapeError: Error {
    /// The device refused a standard stereo float format.
    case unsupportedFormat
}
