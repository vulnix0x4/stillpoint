import SwiftUI

/// A parked thought in the inbox list, with where and when it came from.
struct ThoughtRow: View {
    @Bindable var thought: ParkedThought

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Button(thought.isDone ? "Reopen" : "Mark done", systemImage: thought.isDone ? "checkmark.circle.fill" : "circle", action: toggle)
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(.tint)
                .contentTransition(.symbolEffect(.replace))
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Theme.Spacing.hairline) {
                Text(thought.text)
                    .strikethrough(thought.isDone)
                    .foregroundStyle(thought.isDone ? .secondary : .primary)
                Text(origin)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, Theme.Spacing.tight)
        }
        .listRowBackground(Theme.surface)
        .swipeActions(edge: .leading) {
            Button(thought.isDone ? "Reopen" : "Done", systemImage: thought.isDone ? "arrow.uturn.backward" : "checkmark", action: toggle)
                .tint(.green)
        }
        .sensoryFeedback(.selection, trigger: thought.isDone)
    }

    private var origin: String {
        let when = thought.createdAt.formatted(.relative(presentation: .named))
        if let intention = thought.session?.intention, !intention.isEmpty {
            return "\(when) · during \u{201C}\(intention)\u{201D}"
        }
        return when.prefix(1).uppercased() + when.dropFirst()
    }

    private func toggle() {
        withAnimation(Theme.Motion.quick) {
            thought.toggleDone()
        }
    }
}
