import SwiftUI

/// A parked thought with a checkbox, used inside cards.
struct ThoughtCheckRow: View {
    @Bindable var thought: ParkedThought

    var body: some View {
        Button(action: toggle) {
            Label {
                Text(thought.text)
                    .strikethrough(thought.isDone)
                    .foregroundStyle(thought.isDone ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } icon: {
                Image(systemName: thought.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(.tint)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityValue(thought.isDone ? "Done" : "Open")
        .sensoryFeedback(.selection, trigger: thought.isDone)
    }

    private func toggle() {
        withAnimation(Theme.Motion.quick) {
            thought.toggleDone()
        }
    }
}
