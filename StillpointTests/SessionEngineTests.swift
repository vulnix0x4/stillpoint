import Foundation
import SwiftData
import Testing
@testable import Stillpoint

/// Drives the engine end to end against an in-memory store and isolated preferences.
@Suite(.serialized)
struct SessionEngineTests {
    let container: ModelContainer
    let defaults: UserDefaults
    let sound: SoundscapeEngine

    init() {
        container = ModelContainerFactory.make(inMemory: true)
        let suite = "SessionEngineTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.set(false, forKey: PreferenceKey.chimeEnabled)
        defaults.set(false, forKey: PreferenceKey.liveActivitiesEnabled)
        defaults.set(false, forKey: PreferenceKey.keepScreenAwake)
        sound = SoundscapeEngine(defaults: defaults)
        sound.apply(.silence)
    }

    func makeEngine() -> SessionEngine {
        SessionEngine(modelContext: container.mainContext, sound: sound, defaults: defaults)
    }

    func sessions() throws -> [FocusSession] {
        try container.mainContext.fetch(FetchDescriptor<FocusSession>())
    }

    @Test func beginningWithoutArrivalStartsFocusImmediately() throws {
        let engine = makeEngine()
        engine.begin(SessionPlan(intention: "  Write tests  ", plannedMinutes: 25))
        #expect(engine.stage == .focusing)
        #expect(engine.isSessionPresented)
        #expect(engine.plan.intention == "Write tests")
        let stored = try sessions()
        #expect(stored.count == 1)
        #expect(stored.first?.isFinalized == false)
        engine.discardSession()
    }

    @Test func arrivalComesFirstWhenRequested() {
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: 25, arriveFirst: true))
        #expect(engine.stage == .arriving)
        engine.finishArrival()
        #expect(engine.stage == .focusing)
        #expect(engine.activeSession?.usedArrival == true)
        engine.discardSession()
    }

    @Test func cancellingArrivalLeavesNoTrace() throws {
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: 25, arriveFirst: true))
        engine.cancelArrival()
        #expect(engine.stage == .idle)
        #expect(!engine.isSessionPresented)
        #expect(try sessions().isEmpty)
    }

    @Test func parkingAThoughtAttachesItAndDisturbsCalm() throws {
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: 25))
        engine.parkThought("Email the landlord")
        engine.parkThought("   ")
        #expect(engine.parkedCount == 1)
        #expect(engine.thoughtsThisSession.map(\.text) == ["Email the landlord"])
        engine.discardSession()
    }

    @Test func thoughtsParkedOutsideASessionGoToTheInbox() throws {
        let engine = makeEngine()
        engine.parkThought("Buy stamps")
        let thoughts = try container.mainContext.fetch(FetchDescriptor<ParkedThought>())
        #expect(thoughts.count == 1)
        #expect(thoughts.first?.session == nil)
        #expect(engine.parkedCount == 0)
    }

    @Test func pausingFreezesTheClock() throws {
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: 25))
        engine.pause()
        #expect(engine.clock?.isPaused == true)
        #expect(engine.frame(at: .now.addingTimeInterval(600)).isPaused)
        engine.resume()
        #expect(engine.clock?.isPaused == false)
        #expect(engine.clock?.pauseCount == 1)
        engine.discardSession()
    }

    @Test func finishingThenSavingFinalizesTheSession() throws {
        let engine = makeEngine()
        engine.begin(SessionPlan(intention: "Outline", plannedMinutes: 25))
        engine.finish()
        #expect(engine.stage == .reflecting)
        #expect(engine.isSessionPresented)

        engine.saveReflection(outcome: .achieved, depth: 4, note: " Good one ")
        #expect(engine.stage == .idle)
        #expect(!engine.isSessionPresented)
        let session = try #require(try sessions().first)
        #expect(session.isFinalized)
        #expect(session.outcome == .achieved)
        #expect(session.depthRating == 4)
        #expect(session.note == "Good one")
    }

    @Test func discardingKeepsParkedThoughts() throws {
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: 25))
        engine.parkThought("Keep me")
        engine.finish()
        engine.discardSession()
        #expect(try sessions().isEmpty)
        let thoughts = try container.mainContext.fetch(FetchDescriptor<ParkedThought>())
        #expect(thoughts.map(\.text) == ["Keep me"])
    }

    @Test func reachingTheGoalKeepsFlowingByDefault() {
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: 5))
        engine.tick(at: .now.addingTimeInterval(301))
        #expect(engine.goalReached)
        #expect(engine.stage == .focusing)
        engine.finish()
        #expect(engine.activeSession?.reachedGoal == true)
        engine.discardSession()
    }

    @Test func reachingTheGoalCanEndTheSession() {
        defaults.set(CompletionBehavior.endSession.rawValue, forKey: PreferenceKey.completionBehavior)
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: 5))
        engine.tick(at: .now.addingTimeInterval(301))
        #expect(engine.stage == .reflecting)
        engine.discardSession()
    }

    @Test func openEndedSessionsNeverReachAGoal() {
        let engine = makeEngine()
        engine.begin(SessionPlan(plannedMinutes: nil))
        engine.tick(at: .now.addingTimeInterval(10_000))
        #expect(!engine.goalReached)
        #expect(engine.stage == .focusing)
        engine.discardSession()
    }

    @Test func aRunningSessionSurvivesRelaunch() throws {
        let first = makeEngine()
        first.begin(SessionPlan(intention: "Survive", plannedMinutes: 45))
        first.parkThought("Midway thought")
        let id = try #require(first.activeSession?.id)

        let relaunched = makeEngine()
        relaunched.restoreIfNeeded()
        #expect(relaunched.stage == .focusing)
        #expect(relaunched.isSessionPresented)
        #expect(relaunched.activeSession?.id == id)
        #expect(relaunched.plan.intention == "Survive")
        #expect(relaunched.clock == first.clock)
        relaunched.discardSession()
    }

    @Test func anInterruptedReflectionSurvivesRelaunch() throws {
        let first = makeEngine()
        first.begin(SessionPlan(intention: "Reflect later", plannedMinutes: 25))
        first.finish()

        let relaunched = makeEngine()
        relaunched.restoreIfNeeded()
        #expect(relaunched.stage == .reflecting)
        relaunched.saveReflection(outcome: nil, depth: 3, note: "")
        #expect(try sessions().first?.isFinalized == true)
    }

    @Test func abandonedSessionsAreTidiedOnLaunch() throws {
        let context = container.mainContext
        let substantial = FocusSession(startDate: .now.addingTimeInterval(-3_600), plannedDuration: 1_500, intention: "Long", usedArrival: false, soundscapeName: nil)
        substantial.focusedDuration = 1_200
        let trivial = FocusSession(startDate: .now.addingTimeInterval(-600), plannedDuration: 1_500, intention: "Blip", usedArrival: false, soundscapeName: nil)
        trivial.focusedDuration = 20
        context.insert(substantial)
        context.insert(trivial)
        try context.save()

        makeEngine().restoreIfNeeded()
        let remaining = try sessions()
        #expect(remaining.map(\.intention) == ["Long"])
        #expect(remaining.first?.isFinalized == true)
    }
}
