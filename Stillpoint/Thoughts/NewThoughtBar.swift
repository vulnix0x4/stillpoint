import SwiftUI

/// A glass field pinned above the tab bar for adding a thought by hand.
struct NewThoughtBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onAdd: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                TextField("Park something…", text: $text)
                    .focused(isFocused)
                    .submitLabel(.done)
                    .onSubmit(onAdd)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .frame(minHeight: 48)
                    .glassEffect(.regular.interactive(), in: .capsule)

                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add", systemImage: "arrow.up", action: onAdd)
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .frame(width: 48, height: 48)
                        .buttonStyle(.plain)
                        .glassEffect(.regular.tint(.white.opacity(0.3)).interactive(), in: .circle)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.small)
        .animation(Theme.Motion.quick, value: text.isEmpty)
    }
}
