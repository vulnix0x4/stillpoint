import Foundation

/// Looks for honest, specific patterns in session history. Every rule needs enough data
/// before it speaks, so early insights aren't built on one or two sessions.
nonisolated struct InsightGenerator {
    var calendar: Calendar = .current
    var locale: Locale = .current

    private var stats: StatsCalculator {
        StatsCalculator(calendar: calendar)
    }

    func insights(for records: [SessionRecord], now: Date) -> [Insight] {
        [
            momentum(records, now: now),
            peakWindow(records),
            lengthAndDepth(records),
            arrivalEffect(records),
            followThrough(records),
            strongestWeekday(records),
            parkedThoughts(records),
        ].compactMap(\.self)
    }

    // MARK: - Rules

    /// The two-hour window holding the most focus.
    func peakWindow(_ records: [SessionRecord]) -> Insight? {
        guard records.count >= 5 else { return nil }
        let hours = stats.hourlyTotals(records).map(\.minutes)
        let total = hours.reduce(0, +)
        guard total > 0 else { return nil }

        var bestStart = 0
        var bestMinutes = 0.0
        for start in 0..<24 {
            let minutes = hours[start] + hours[(start + 1) % 24]
            // On a tie, prefer the window that opens with the busier hour.
            let isTieWithStrongerStart = minutes == bestMinutes && hours[start] > hours[bestStart]
            if minutes > bestMinutes || isTieWithStrongerStart {
                bestMinutes = minutes
                bestStart = start
            }
        }

        let share = bestMinutes / total
        let range = "\(hourLabel(bestStart))–\(hourLabel((bestStart + 2) % 24))"
        return Insight(
            id: "peak",
            symbol: "sun.max",
            title: "Your peak window is \(range)",
            detail: "\(share.formatted(.percent.precision(.fractionLength(0)))) of your focused time lands here. Protect it on your calendar."
        )
    }

    /// Whether longer sessions are rated deeper than short ones.
    func lengthAndDepth(_ records: [SessionRecord]) -> Insight? {
        let rated = records.filter { $0.depth != nil }
        let long = rated.filter { $0.focused >= 45 * 60 }
        let short = rated.filter { $0.focused < 45 * 60 }
        guard long.count >= 3, short.count >= 3,
              let longDepth = stats.averageDepth(long),
              let shortDepth = stats.averageDepth(short),
              abs(longDepth - shortDepth) >= 0.3
        else { return nil }

        let longText = longDepth.formatted(.number.precision(.fractionLength(1)))
        let shortText = shortDepth.formatted(.number.precision(.fractionLength(1)))
        if longDepth > shortDepth {
            return Insight(
                id: "length-depth",
                symbol: "hourglass",
                title: "Longer sessions run deeper",
                detail: "Sessions over 45 minutes average a depth of \(longText), against \(shortText) for shorter ones."
            )
        }
        return Insight(
            id: "length-depth",
            symbol: "hourglass",
            title: "Shorter sessions suit you",
            detail: "Sessions under 45 minutes average a depth of \(shortText), against \(longText) for longer ones."
        )
    }

    /// Whether breathing before a session is associated with deeper focus.
    func arrivalEffect(_ records: [SessionRecord]) -> Insight? {
        let rated = records.filter { $0.depth != nil }
        let with = rated.filter(\.usedArrival)
        let without = rated.filter { !$0.usedArrival }
        guard with.count >= 3, without.count >= 3,
              let withDepth = stats.averageDepth(with),
              let withoutDepth = stats.averageDepth(without),
              withDepth - withoutDepth >= 0.3
        else { return nil }

        let difference = (withDepth - withoutDepth).formatted(.number.precision(.fractionLength(1)))
        return Insight(
            id: "arrival",
            symbol: "wind",
            title: "Breathing first helps",
            detail: "Sessions that begin with a minute of breathing rate \(difference) points deeper on average."
        )
    }

    func followThrough(_ records: [SessionRecord]) -> Insight? {
        guard records.count(where: { $0.outcome != nil }) >= 5,
              let rate = stats.followThroughRate(records)
        else { return nil }

        let percent = rate.formatted(.percent.precision(.fractionLength(0)))
        let detail = switch rate {
        case 0.75...: "Your intentions are well sized. Keep them this concrete."
        case 0.45..<0.75: "Solid. Ending each intention with a visible result, like \u{201C}send the draft\u{201D}, makes it easier to finish."
        default: "Try smaller, sharper intentions: \u{201C}outline section two\u{201D} beats \u{201C}work on the report\u{201D}."
        }
        return Insight(id: "follow-through", symbol: "target", title: "You follow through on \(percent) of intentions", detail: detail)
    }

    func strongestWeekday(_ records: [SessionRecord]) -> Insight? {
        guard records.count >= 8,
              let first = records.map(\.start).min(),
              let last = records.map(\.start).max(),
              last.timeIntervalSince(first) >= 14 * 86_400
        else { return nil }

        let averages = stats.averageMinutesByWeekday(records)
        guard let best = averages.max(by: { $0.value < $1.value }), averages.count >= 3 else { return nil }
        let names = calendar.standaloneWeekdaySymbols
        guard names.indices.contains(best.key - 1) else { return nil }
        let name = names[best.key - 1]
        let minutes = Duration.seconds(best.value * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))
        return Insight(
            id: "weekday",
            symbol: "calendar",
            title: "\(name)s are your strongest day",
            detail: "You average \(minutes) of focus on \(name)s you work."
        )
    }

    func parkedThoughts(_ records: [SessionRecord]) -> Insight? {
        let count = records.reduce(0) { $0 + $1.thoughtCount }
        guard count >= 5 else { return nil }
        return Insight(
            id: "parked",
            symbol: "tray.and.arrow.down",
            title: "\(count) thoughts parked, not chased",
            detail: "Each one was a pull you noticed and set aside. That's the skill, getting stronger."
        )
    }

    /// Compares the last seven days with the seven before.
    func momentum(_ records: [SessionRecord], now: Date) -> Insight? {
        let days = stats.dailyTotals(records, days: 14, endingOn: now)
        guard days.count == 14 else { return nil }
        let previous = days.prefix(7).reduce(0) { $0 + $1.minutes }
        let recent = days.suffix(7).reduce(0) { $0 + $1.minutes }
        guard previous >= 30 else { return nil }

        let change = (recent - previous) / previous
        let percent = abs(change).formatted(.percent.precision(.fractionLength(0)))
        if change >= 0.2 {
            return Insight(
                id: "momentum",
                symbol: "arrow.up.right",
                title: "Momentum is building",
                detail: "Up \(percent) on the previous week. Whatever you changed, it's working."
            )
        }
        if change <= -0.3 {
            return Insight(
                id: "momentum",
                symbol: "leaf",
                title: "A quieter week",
                detail: "Down \(percent) on the week before. One short session is enough to pick the thread back up."
            )
        }
        return nil
    }

    // MARK: - Formatting

    private func hourLabel(_ hour: Int) -> String {
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        var style = Date.FormatStyle(locale: locale, calendar: calendar).hour()
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }
}
