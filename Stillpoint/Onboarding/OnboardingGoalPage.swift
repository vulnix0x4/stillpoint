import SwiftUI

struct OnboardingGoalPage: View {
    @Binding var goal: Int
    @Binding var paletteName: String
    var finish: () -> Void

    private static let options = [30, 60, 90, 120, 180, 240]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text("A daily goal")
                    .font(.display)
                Text("How much deep work would make a good day? Start modest; four focused hours is a lot for anyone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: Theme.Spacing.small)], spacing: Theme.Spacing.small) {
                ForEach(Self.options, id: \.self) { option in
                    let isSelected = option == goal
                    Button {
                        goal = option
                    } label: {
                        Text(TimeText.short(Double(option) * 60))
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(isSelected ? Theme.ink : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(isSelected ? .regular.tint(.white.opacity(0.85)).interactive() : .regular.interactive(), in: .rect(cornerRadius: Theme.Radius.control))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: goal)

            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text("Pick a colour")
                    .font(.headline)
                PalettePicker(selection: $paletteName)
            }
            .padding(.top, Theme.Spacing.small)

            Spacer(minLength: 0)
            OnboardingButton(title: "Begin", action: finish)
        }
        .padding(.horizontal, Theme.Spacing.xLarge)
        .padding(.bottom, Theme.Spacing.xLarge * 1.5)
    }
}
