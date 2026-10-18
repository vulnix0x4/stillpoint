import SwiftUI

/// A small labelled value.
struct DetailFact: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded))
                .bold()
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
