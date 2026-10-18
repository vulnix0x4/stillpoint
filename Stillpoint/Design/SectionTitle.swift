import SwiftUI

/// A serif heading for a group of content.
struct SectionTitle: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.sectionTitle)
            .padding(.horizontal, Theme.Spacing.tight)
            .accessibilityAddTraits(.isHeader)
    }
}
