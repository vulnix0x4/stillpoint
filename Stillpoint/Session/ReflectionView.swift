import SwiftUI

/// A minute of looking back: did the intention land, how deep did it go, and what got parked.
struct ReflectionView: View {
    var palette: OrbPalette

    @Environment(SessionEngine.self) private var engine
    @State private var outcome: SessionOutcome?
    @State private var depth: Int?
    @State private var note = ""
    @State private var isConfirmingDiscard = false

    var body: some View {
        let session = engine.activeSession
        let focused = session?.focusedDuration ?? 0

        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                ReflectionHeader(
                    focused: focused,
                    planned: session?.plannedDuration,
                    reachedGoal: session?.reachedGoal ?? false,
                    longestCalm: session?.longestCalmStretch ?? 0,
                    thoughtCount: session?.thoughts?.count ?? 0,
                    palette: palette
                )

                if let intention = session?.intention, !intention.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("You set out to")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(intention)
                            .font(.intention)
                        OutcomePicker(selection: $outcome, tint: palette.accent)
                    }
                    .cardSurface()
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    Text("How deep did it go?")
                        .font(.sectionTitle)
                    DepthRatingControl(rating: $depth, palette: palette)
                }
                .cardSurface()

                if let thoughts = session?.sortedThoughts, !thoughts.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text("Parked along the way")
                            .font(.sectionTitle)
                        Text("Tick off anything already handled. The rest waits in Parked.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ForEach(thoughts) { thought in
                            ThoughtCheckRow(thought: thought)
                        }
                    }
                    .cardSurface()
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text("Anything worth remembering?")
                        .font(.sectionTitle)
                    TextField("A note for future you", text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }
                .cardSurface()

                VStack(spacing: Theme.Spacing.medium) {
                    Button(action: save) {
                        Text("Save session")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)

                    Button("Discard", role: .destructive, action: confirmDiscard)
                        .font(.subheadline)
                        .frame(minHeight: 44)
                        .confirmationDialog("Discard this session?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                            Button("Discard Session", role: .destructive, action: engine.discardSession)
                        } message: {
                            Text("It won't count toward your stats. Parked thoughts are kept.")
                        }
                }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.xLarge)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.selection, trigger: depth)
        .sensoryFeedback(.selection, trigger: outcome)
    }

    private func save() {
        engine.saveReflection(outcome: outcome, depth: depth, note: note)
    }

    private func confirmDiscard() {
        isConfirmingDiscard = true
    }
}
