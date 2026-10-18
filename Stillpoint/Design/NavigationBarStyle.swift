import UIKit

/// SwiftUI has no API for navigation title fonts, so the serif titles are set through the
/// bar's appearance proxy once at launch.
enum NavigationBarStyle {
    static func apply() {
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: serif(.largeTitle, bold: true)]
        appearance.titleTextAttributes = [.font: serif(.headline, bold: false)]
    }

    private static func serif(_ style: UIFont.TextStyle, bold: Bool) -> UIFont {
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        var descriptor = base.withDesign(.serif) ?? base
        if bold {
            descriptor = descriptor.withSymbolicTraits(.traitBold) ?? descriptor
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
