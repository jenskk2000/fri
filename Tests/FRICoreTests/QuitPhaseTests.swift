import XCTest
@testable import FRICore

final class QuitPhaseTests: XCTestCase {
    private let day: TimeInterval = 86400

    func testFirstFourteenDaysAreTheCriticalWindow() {
        let start = QuitPhase(elapsed: 0)
        XCTAssertEqual(start.stage, .critical)
        XCTAssertEqual(start.targetDays, 14)
        XCTAssertEqual(start.daysLeft, 14)
        XCTAssertEqual(start.fraction, 0)

        let nine = QuitPhase(elapsed: 9 * day + 3600)
        XCTAssertEqual(nine.stage, .critical)
        XCTAssertEqual(nine.daysLeft, 5)
        XCTAssertEqual(nine.fraction, (9 * day + 3600) / (14 * day), accuracy: 0.0001)
    }

    func testConsolidationThenMaintenanceTargets() {
        XCTAssertEqual(QuitPhase(elapsed: 14 * day).targetDays, 30)
        XCTAssertEqual(QuitPhase(elapsed: 14 * day).stage, .consolidation)
        XCTAssertEqual(QuitPhase(elapsed: 14 * day).fraction, 0, accuracy: 0.0001)
        XCTAssertEqual(QuitPhase(elapsed: 45 * day).targetDays, 90)
        XCTAssertEqual(QuitPhase(elapsed: 45 * day).stage, .consolidation)
        XCTAssertEqual(QuitPhase(elapsed: 100 * day).targetDays, 180)
        XCTAssertEqual(QuitPhase(elapsed: 100 * day).stage, .maintenance)
        XCTAssertEqual(QuitPhase(elapsed: 200 * day).targetDays, 365)
        XCTAssertEqual(QuitPhase(elapsed: 400 * day).targetDays, 730)
        XCTAssertEqual(QuitPhase(elapsed: 800 * day).targetDays, 1095)
    }

    func testDaysLeftRoundsUpPartialDays() {
        XCTAssertEqual(QuitPhase(elapsed: 13 * day + 1).daysLeft, 1)
        XCTAssertEqual(QuitPhase(elapsed: 13.5 * day).daysLeft, 1)
    }

    func testNegativeElapsedIsClampedToStart() {
        XCTAssertEqual(QuitPhase(elapsed: -500), QuitPhase(elapsed: 0))
    }

    func testJourneyPhaseFollowsCurrentStreakAndIsNilBeforeStart() {
        let quit = Date(timeIntervalSince1970: 1_780_000_000)
        var j = Journey(quitDate: quit, motivation: .freedom, triggers: [.coffee], consumption: Consumption())
        XCTAssertNil(j.phase(at: quit.addingTimeInterval(-60)))
        XCTAssertEqual(j.phase(at: quit.addingTimeInterval(20 * day))?.targetDays, 30)
        _ = j.recordLapse(count: 1, trigger: "Kaffe", at: quit.addingTimeInterval(18 * day))
        let afterLapse = j.phase(at: quit.addingTimeInterval(20 * day))
        XCTAssertEqual(afterLapse?.stage, .critical)
        XCTAssertEqual(afterLapse?.daysLeft, 12)
    }
}
