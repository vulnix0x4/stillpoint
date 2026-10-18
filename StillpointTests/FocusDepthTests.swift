import Foundation
import Testing
@testable import Stillpoint

struct FocusDepthTests {
    @Test(arguments: [
        (0.0, FocusDepth.settling),
        (299.0, .settling),
        (300.0, .focused),
        (899.0, .focused),
        (900.0, .deep),
        (5_000.0, .deep),
    ])
    func levelsFollowCalmTime(seconds: TimeInterval, expected: FocusDepth) {
        #expect(FocusDepth(calmSeconds: seconds) == expected)
    }

    @Test func turbulenceFallsAsCalmGrows() {
        let start = FocusDepth.turbulence(calmSeconds: 0)
        let later = FocusDepth.turbulence(calmSeconds: 600)
        let deep = FocusDepth.turbulence(calmSeconds: 3_600)
        #expect(start == 1)
        #expect(later < start)
        #expect(deep < later)
        #expect(deep > 0.09, "The orb never goes completely still")
    }

    @Test func parkingAThoughtHalvesCalm() {
        var calm = CalmTracker()
        calm.noteThoughtParked(atElapsed: 600)
        #expect(calm.calmSeconds(atElapsed: 600) == 300)
        #expect(calm.longestStretch == 600)
        #expect(calm.calmSeconds(atElapsed: 700) == 400)
    }

    @Test func resumingAfterAPauseRestartsCalm() {
        var calm = CalmTracker()
        calm.noteResumed(atElapsed: 1_200)
        #expect(calm.calmSeconds(atElapsed: 1_200) == 0)
        #expect(calm.calmSeconds(atElapsed: 1_500) == 300)
        #expect(calm.longest(atElapsed: 1_500) == 1_200)
    }

    @Test func longestStretchTracksTheLiveStretchToo() {
        var calm = CalmTracker()
        calm.noteResumed(atElapsed: 100)
        #expect(calm.longest(atElapsed: 2_000) == 1_900)
    }
}
