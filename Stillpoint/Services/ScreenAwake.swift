import UIKit

/// Keeps the display on during a session, if the person wants that.
enum ScreenAwake {
    static func set(_ isAwake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = isAwake
    }
}
