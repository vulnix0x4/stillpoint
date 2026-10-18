import SwiftUI

/// The single most important input in the app: what this session is for.
struct IntentionField: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        TextField("What deserves your attention?", text: $text, axis: .vertical)
            .font(.system(.title3, design: .serif))
            .multilineTextAlignment(.center)
            .lineLimit(1...3)
            .submitLabel(.done)
            .focused(focus)
            .onChange(of: text) { _, newValue in
                // A vertical text field inserts newlines on return; treat return as "done".
                if newValue.contains("\n") {
                    text = newValue.replacing("\n", with: "")
                    focus.wrappedValue = false
                }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Theme.Radius.control))
            .accessibilityLabel("Intention")
            .accessibilityHint("Describe the one thing this session is for")
    }
}
