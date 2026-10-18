import SwiftData
import SwiftUI

/// The inbox of everything parked during sessions, ready to deal with on your own terms.
struct ThoughtsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParkedThought.createdAt, order: .reverse) private var thoughts: [ParkedThought]
    @AppStorage(PreferenceKey.palette) private var paletteName = OrbPalette.ember.rawValue
    @State private var searchText = ""
    @State private var newThought = ""
    @FocusState private var isAdding: Bool

    var body: some View {
        let palette = OrbPalette.named(paletteName)
        let matching = searchText.isEmpty ? thoughts : thoughts.filter { $0.text.localizedStandardContains(searchText) }
        let open = matching.filter { !$0.isDone }
        let done = matching.filter(\.isDone)

        NavigationStack {
            List {
                if thoughts.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing parked", systemImage: "tray")
                    } description: {
                        Text("When a stray thought pulls at you mid-session, park it. It'll wait here, so you don't have to hold it.")
                    }
                    .listRowBackground(Color.clear)
                } else if matching.isEmpty {
                    ContentUnavailableView.search
                        .listRowBackground(Color.clear)
                }

                if !open.isEmpty {
                    Section("Open") {
                        ForEach(open) { thought in
                            ThoughtRow(thought: thought)
                        }
                        .onDelete { offsets in
                            delete(offsets.map { open[$0] })
                        }
                    }
                }

                if !done.isEmpty {
                    Section("Done") {
                        ForEach(done) { thought in
                            ThoughtRow(thought: thought)
                        }
                        .onDelete { offsets in
                            delete(offsets.map { done[$0] })
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                AmbientBackground(palette: palette, intensity: 0.6)
            }
            .searchable(text: $searchText, prompt: "Search parked thoughts")
            .navigationTitle("Parked")
            .toolbar {
                if !done.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear Done", systemImage: "checkmark.circle.badge.xmark", action: clearDone)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                NewThoughtBar(text: $newThought, isFocused: $isAdding, onAdd: add)
            }
        }
    }

    private func add() {
        let trimmed = newThought.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            modelContext.insert(ParkedThought(text: trimmed))
        }
        try? modelContext.save()
        newThought = ""
    }

    private func delete(_ items: [ParkedThought]) {
        withAnimation {
            items.forEach(modelContext.delete)
        }
        try? modelContext.save()
    }

    private func clearDone() {
        delete(thoughts.filter(\.isDone))
    }
}
