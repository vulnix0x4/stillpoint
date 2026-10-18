import SwiftUI

/// Captures a stray thought in a few words, then gets out of the way.
struct ParkThoughtComposer: View {
    var onPark: (String) -> Void
    var onCancel: () -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                Text("Park it")
                    .font(.sectionTitle)
                Text("Write it down and let it go. It'll wait for you in Parked.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("What's pulling at you?", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .focused($isFocused)
                .submitLabel(.done)
                .padding(Theme.Spacing.medium)
                .background(Color.white.opacity(0.06), in: .rect(cornerRadius: Theme.Radius.control - 6))
                .onChange(of: text) { _, newValue in
                    if newValue.contains("\n") {
                        text = newValue.replacing("\n", with: "")
                        park()
                    }
                }

            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.glass)
                Spacer()
                Button("Park", systemImage: "tray.and.arrow.down", action: park)
                    .buttonStyle(.glassProminent)
                    .disabled(trimmed.isEmpty)
            }
            .controlSize(.large)
        }
        .padding(Theme.Spacing.large)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.card))
        .padding(Theme.Spacing.medium)
        .task {
            isFocused = true
        }
    }

    private func park() {
        guard !trimmed.isEmpty else { return }
        onPark(trimmed)
        text = ""
    }
}
