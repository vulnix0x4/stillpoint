import SwiftData
import SwiftUI

/// Everything about one past session, with the reflection still editable.
struct SessionDetailView: View {
    @Bindable var session: FocusSession
    var palette: OrbPalette

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(session.startDate, format: .dateTime.weekday(.wide).day().month(.wide).hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(session.intention.isEmpty ? "Untitled session" : session.intention)
                        .font(.display)
                    HStack(spacing: Theme.Spacing.medium) {
                        DetailFact(title: "Focused", value: TimeText.short(session.focusedDuration))
                        DetailFact(title: "Planned", value: session.plannedDuration.map(TimeText.short) ?? "Open")
                        DetailFact(title: "Calmest", value: TimeText.short(session.longestCalmStretch))
                    }
                    if let soundscape = session.soundscapeName {
                        Label(soundscape, systemImage: "speaker.wave.2")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !session.intention.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Outcome")
                            .font(.sectionTitle)
                        OutcomePicker(selection: $session.outcome, tint: palette.accent)
                    }
                    .cardSurface()
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    Text("Depth")
                        .font(.sectionTitle)
                    DepthRatingControl(rating: $session.depthRating, palette: palette)
                }
                .cardSurface()

                if !session.sortedThoughts.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text("Parked thoughts")
                            .font(.sectionTitle)
                        ForEach(session.sortedThoughts) { thought in
                            ThoughtCheckRow(thought: thought)
                        }
                    }
                    .cardSurface()
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text("Note")
                        .font(.sectionTitle)
                    TextField("A note for future you", text: $session.note, axis: .vertical)
                        .lineLimit(2...8)
                }
                .cardSurface()
            }
            .padding(Theme.Spacing.medium)
        }
        .scrollDismissesKeyboard(.interactively)
        .background {
            AmbientBackground(palette: palette, intensity: 0.6)
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete", systemImage: "trash", role: .destructive, action: confirmDelete)
                    .confirmationDialog("Delete this session?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                        Button("Delete Session", role: .destructive, action: delete)
                    } message: {
                        Text("Its parked thoughts will stay in Parked.")
                    }
            }
        }
        .onDisappear(perform: saveChanges)
    }

    private func confirmDelete() {
        isConfirmingDelete = true
    }

    private func delete() {
        modelContext.delete(session)
        try? modelContext.save()
        WidgetSync.refresh(using: modelContext)
        dismiss()
    }

    private func saveChanges() {
        guard !session.isDeleted else { return }
        try? modelContext.save()
    }
}
