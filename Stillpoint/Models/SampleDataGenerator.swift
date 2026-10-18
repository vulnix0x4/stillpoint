import Foundation
import SwiftData

/// Generates believable history: stronger mornings, quieter weekends, deeper ratings for
/// longer sessions and sessions that began with breathing. Deterministic for a given seed.
struct SampleDataGenerator {
    var days = 70
    var seed: UInt64 = 2026
    var now: Date = .now
    var calendar: Calendar = .current

    private static let intentions = [
        "Draft the introduction", "Refactor the sync engine", "Outline chapter three",
        "Review the pull request", "Sketch onboarding screens", "Write the weekly update",
        "Fix the flaky test", "Read the research paper", "Plan next sprint", "Edit the essay",
        "Prepare the talk slides", "Study for the exam", "Design the pricing page",
        "Answer the hard email", "Practice scales", "Clean up the backlog",
    ]

    private static let thoughts = [
        "Reply to Sam about Friday", "Book dentist appointment", "Look up that keyboard",
        "Idea: dark mode for the dashboard", "Buy oat milk", "Check flight prices",
        "Call mum back", "Rename the build scripts", "Pay the electricity bill",
        "Podcast idea about rituals", "Water the plants", "Ask Priya about the API",
    ]

    func populate(_ context: ModelContext) {
        var random = SplitMix64(seed: seed)
        let today = calendar.startOfDay(for: now)

        for dayOffset in stride(from: days, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            let isWeekend = weekday == 1 || weekday == 7
            // Habit strengthens over time: early days are patchier.
            let consistency = 0.55 + 0.35 * (1 - Double(dayOffset) / Double(days))
            let skipChance = isWeekend ? 0.55 : 1 - consistency
            if dayOffset > 0, random.unit() < skipChance { continue }

            let sessionCount = isWeekend ? 1 : 1 + Int(random.unit() * 3.2)
            var hour = 8 + Int(random.unit() * 2)
            for _ in 0..<sessionCount {
                guard let start = calendar.date(bySettingHour: hour, minute: Int(random.unit() * 50), second: 0, of: day),
                      start < now
                else { break }
                insertSession(startingAt: start, random: &random, into: context)
                hour += 2 + Int(random.unit() * 3)
                if hour > 21 { break }
            }
        }

        for (index, text) in Self.thoughts.prefix(4).enumerated() {
            context.insert(ParkedThought(text: text, createdAt: now.addingTimeInterval(Double(-index) * 5_400)))
        }
        try? context.save()
    }

    private func insertSession(startingAt start: Date, random: inout SplitMix64, into context: ModelContext) {
        let plans = [25, 25, 45, 50, 60, 90]
        let planned = plans[Int(random.unit() * Double(plans.count)) % plans.count]
        let usedArrival = random.unit() < 0.6
        let endedEarly = random.unit() < 0.15
        let flowBonus = random.unit() < 0.25 ? random.unit() * 20 : 0
        let focusedMinutes = endedEarly ? Double(planned) * (0.4 + random.unit() * 0.5) : Double(planned) + flowBonus

        let hour = calendar.component(.hour, from: start)
        var depth = 2.6 + (focusedMinutes >= 45 ? 0.9 : 0) + (usedArrival ? 0.5 : 0) + (hour < 12 ? 0.4 : -0.2)
        depth += (random.unit() - 0.5) * 1.6
        if endedEarly { depth -= 1 }

        let session = FocusSession(
            startDate: start,
            plannedDuration: Double(planned) * 60,
            intention: Self.intentions[Int(random.unit() * Double(Self.intentions.count)) % Self.intentions.count],
            usedArrival: usedArrival,
            soundscapeName: SoundMix.presets.randomElement(using: &random)?.name
        )
        session.focusedDuration = focusedMinutes * 60
        session.endDate = start.addingTimeInterval(session.focusedDuration)
        session.depthRating = min(5, max(1, Int(depth.rounded())))
        session.reachedGoal = !endedEarly
        session.longestCalmStretch = session.focusedDuration * (0.4 + random.unit() * 0.5)
        session.outcome = endedEarly ? (random.unit() < 0.5 ? .notYet : .partly) : (random.unit() < 0.75 ? .achieved : .partly)
        session.isFinalized = true
        context.insert(session)

        if random.unit() < 0.45 {
            let count = 1 + Int(random.unit() * 2.5)
            for index in 0..<count {
                let thought = ParkedThought(
                    text: Self.thoughts[Int(random.unit() * Double(Self.thoughts.count)) % Self.thoughts.count],
                    createdAt: start.addingTimeInterval(Double(index + 1) * 420),
                    session: session
                )
                if random.unit() < 0.8 {
                    thought.toggleDone(at: start.addingTimeInterval(session.focusedDuration + 600))
                }
                context.insert(thought)
            }
        }
    }
}
