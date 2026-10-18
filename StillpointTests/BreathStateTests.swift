import Foundation
import Testing
@testable import Stillpoint

struct BreathStateTests {
    @Test func boxBreathingWalksThroughFourPhases() {
        let pattern = BreathPattern.box
        #expect(BreathState(pattern: pattern, elapsed: 1).phase.kind == .inhale)
        #expect(BreathState(pattern: pattern, elapsed: 5).phase.kind == .hold)
        #expect(BreathState(pattern: pattern, elapsed: 9).phase.kind == .exhale)
        #expect(BreathState(pattern: pattern, elapsed: 13).phase.kind == .rest)
        #expect(BreathState(pattern: pattern, elapsed: 17).cycle == 1)
    }

    @Test func fullnessEasesBetweenEmptyAndFull() {
        let pattern = BreathPattern.coherent
        #expect(BreathState(pattern: pattern, elapsed: 0).fullness == 0)
        #expect(abs(BreathState(pattern: pattern, elapsed: 2.75).fullness - 0.5) < 0.0001)
        #expect(abs(BreathState(pattern: pattern, elapsed: 5.5).fullness - 1) < 0.0001)
        #expect(abs(BreathState(pattern: pattern, elapsed: 11).fullness) < 0.0001)
    }

    @Test func sighTopsUpBeforeTheLongExhale() {
        let pattern = BreathPattern.sigh
        let first = BreathState(pattern: pattern, elapsed: 2.1)
        let second = BreathState(pattern: pattern, elapsed: 2.6)
        #expect(first.phase.kind == .inhale)
        #expect(second.phase.kind == .topUp)
        #expect(second.fullness > first.fullness)
        #expect(BreathState(pattern: pattern, elapsed: 4).phase.kind == .exhale)
    }

    @Test func phaseRemainingCountsDown() {
        let state = BreathState(pattern: .relax478, elapsed: 6)
        #expect(state.phase.kind == .hold)
        #expect(abs(state.phaseRemaining - 5) < 0.0001)
    }

    @Test(arguments: BreathPattern.allCases)
    func arrivalFillsAtLeastAMinute(pattern: BreathPattern) {
        let cycles = pattern.cycles(toFill: 60)
        #expect(Double(cycles) * pattern.cycleDuration >= 60)
        #expect(Double(cycles - 1) * pattern.cycleDuration < 60)
    }
}
