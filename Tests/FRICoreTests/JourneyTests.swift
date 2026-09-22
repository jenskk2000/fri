import XCTest
@testable import FRICore

final class JourneyTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_790_000_000)
    func sample() -> Journey { Journey(quitDate: start, motivation: .money, triggers: [.coffee], consumption: Consumption()) }
    func testFifteenDaysMatchesSelectedMockup() {
        let j = sample(), now = start.addingTimeInterval(15 * 86400)
        XCTAssertEqual(j.savingsKr(at: now), 375, accuracy: 0.0001)
        XCTAssertEqual(j.streakDays(at: now), 15)
        XCTAssertEqual(j.avoidedPouches(at: now), 150)
    }
    func testPartialDayAccruesContinuously() {
        XCTAssertEqual(sample().savingsKr(at: start.addingTimeInterval(43200)), 12.5, accuracy: 0.0001)
    }
    func testFutureQuitDateNeverCreatesNegativeValues() {
        let now = start.addingTimeInterval(-86400)
        XCTAssertEqual(sample().savingsKr(at: now), 0)
        XCTAssertEqual(sample().streakDays(at: now), 0)
        XCTAssertEqual(sample().avoidedPouches(at: now), 0)
    }
    func testMidnightDoesNotGrantFullDay() {
        XCTAssertEqual(sample().streakDays(at: start.addingTimeInterval(3600)), 0)
        XCTAssertEqual(sample().savingsKr(at: start.addingTimeInterval(3600)), 25 / 24, accuracy: 0.0001)
    }
    func testLapseResetsStreakButPreservesNetSavings() {
        var j = sample()
        let lapseTime = start.addingTimeInterval(15 * 86400)
        XCTAssertNotNil(j.recordLapse(count: 2, trigger: "Til kaffen", at: lapseTime))
        XCTAssertEqual(j.savingsKr(at: lapseTime), 370, accuracy: 0.0001)
        XCTAssertEqual(j.streakDays(at: lapseTime), 0)
        XCTAssertEqual(j.elapsedDays(at: lapseTime), 15)
        XCTAssertEqual(j.avoidedPouches(at: lapseTime), 148)
    }
    func testUndoRestoresStreakAndSavings() {
        var j = sample()
        let now = start.addingTimeInterval(15 * 86400)
        let id = j.recordLapse(count: 1, trigger: "Fest", at: now)
        j.lapses.removeAll { $0.id == id }
        XCTAssertEqual(j.savingsKr(at: now), 375)
        XCTAssertEqual(j.streakDays(at: now), 15)
    }
    func testChangedBaselineOnlyAffectsFuture() {
        var j = sample()
        let change = start.addingTimeInterval(86400)
        j.updateConsumption(Consumption(pouchesPerDay: 20, pouchesPerTin: 20, priceOre: 6000), at: change)
        XCTAssertEqual(j.savingsKr(at: change), 25, accuracy: 0.0001)
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(2 * 86400)), 85, accuracy: 0.0001)
        XCTAssertEqual(j.avoidedPouches(at: start.addingTimeInterval(2 * 86400)), 30)
    }
    func testOldLapseKeepsOriginalUnitPrice() {
        var j = sample()
        _ = j.recordLapse(count: 2, trigger: "", at: start.addingTimeInterval(3600))
        j.updateConsumption(Consumption(pouchesPerDay: 10, pouchesPerTin: 20, priceOre: 10000), at: start.addingTimeInterval(86400))
        XCTAssertEqual(j.usedCostOre(at: start.addingTimeInterval(2 * 86400)), 500)
    }
    func testInvalidBaselineRejected() {
        var j = sample()
        j.updateConsumption(Consumption(pouchesPerDay: 10, pouchesPerTin: 0, priceOre: 5000), at: start)
        XCTAssertEqual(j.baselines.count, 1)
        XCTAssertEqual(j.consumption(at: start).pouchesPerTin, 20)
        XCTAssertFalse(Consumption(pouchesPerDay: -1).isValid)
        XCTAssertFalse(Consumption(priceOre: 0).isValid)
    }
    func testLapseValidationAndFutureEventsIgnored() {
        var j = sample()
        XCTAssertNil(j.recordLapse(count: 0, trigger: "", at: start))
        XCTAssertNil(j.recordLapse(count: 1, trigger: "", at: start.addingTimeInterval(-1)))
        _ = j.recordLapse(count: 3, trigger: "", at: start.addingTimeInterval(2 * 86400))
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(86400)), 25)
        XCTAssertEqual(j.streakDays(at: start.addingTimeInterval(86400)), 1)
    }
    func testOverspendingIsFlooredButStillDeductedLater() {
        var j = sample()
        _ = j.recordLapse(count: 20, trigger: "", at: start)
        XCTAssertEqual(j.savingsKr(at: start), 0)
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(3 * 86400)), 25)
    }
    func testFractionalPouchPriceNotRoundedPrematurely() {
        let j = Journey(quitDate: start, motivation: .money, triggers: [], consumption: Consumption(pouchesPerDay: 7, pouchesPerTin: 24, priceOre: 4995))
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(24 * 86400)), 349.65, accuracy: 0.0001)
    }
    func testDSTUsesElapsedTime() {
        let j = sample()
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(23 * 3600)), 25 * 23 / 24, accuracy: 0.0001)
        XCTAssertEqual(j.streakDays(at: start.addingTimeInterval(23 * 3600)), 0)
    }
    func testEditingBeforeScheduledStartReplacesBaseline() {
        var j = sample()
        j.updateConsumption(Consumption(pouchesPerDay: 5), at: start.addingTimeInterval(-100))
        XCTAssertEqual(j.baselines.count, 1)
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(86400)), 12.5)
    }
    func testPersistenceRoundTripAndDelete() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = JourneyArchive(url: root.appendingPathComponent("data.json"))
        XCTAssertNil(try archive.load())
        var j = sample(); _ = j.recordLapse(count: 1, trigger: "Til kaffen", at: start)
        j.discreetWidget = true
        try archive.save(j)
        let loaded = try XCTUnwrap(archive.load())
        XCTAssertEqual(loaded.lapses.count, 1)
        XCTAssertTrue(loaded.discreetWidget)
        XCTAssertEqual(loaded.savingsKr(at: start.addingTimeInterval(86400)), 22.5)
        try archive.delete()
        XCTAssertNil(try archive.load())
    }
    func testCorruptArchiveThrowsAndIsPreserved() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let bytes = Data("not valid json".utf8)
        try bytes.write(to: url)
        XCTAssertThrowsError(try JourneyArchive(url: url).load())
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }
    func testDanishCurrencyFormatting() {
        XCTAssertEqual(Danish.money(1234.5, decimals: 2), "1.234,50")
    }
}
