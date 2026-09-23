import XCTest
@testable import FRICore

final class FocusedCoreTests: XCTestCase {
    func date(_ key: String) -> Date { Journey.date(forDayKey: key)! }
    func journey() -> Journey {
        Journey(quitDate: date("2026-03-27"), motivation: .money, triggers: [.coffee, .stress], consumption: Consumption())
    }
    func testUnknownIsNotAbstinenceAndCurrentDayCannotBeConfirmed() {
        var j = journey(); let today = date("2026-03-30").addingTimeInterval(3600)
        XCTAssertEqual(j.dayStatus(on: date("2026-03-29"), at: today), .unknown)
        XCTAssertFalse(j.confirmDay(today, at: today))
        XCTAssertFalse(j.confirmDay(date("2026-03-31"), at: today))
        XCTAssertEqual(j.dayStatus(on: today, at: today), .ongoing)
        XCTAssertTrue(j.confirmDay(date("2026-03-29"), at: today))
        XCTAssertTrue(j.confirmDay(date("2026-03-29"), at: today))
        XCTAssertEqual(j.confirmedDays.count, 1)
        XCTAssertEqual(j.dayStatus(on: date("2026-03-29"), at: today), .confirmed)
    }
    func testPouchOverridesConfirmationAndUndoRestoresIt() {
        var j = journey(); let day = date("2026-03-28"); let now = date("2026-03-30")
        XCTAssertTrue(j.confirmDay(day, at: now))
        let before = j.savingsKr(at: now)
        _ = j.recordLapse(count: 2, trigger: "Kaffe", at: day.addingTimeInterval(3600))
        XCTAssertEqual(j.dayStatus(on: day, at: now), .used)
        XCTAssertFalse(j.confirmDay(day, at: now))
        XCTAssertEqual(j.savingsKr(at: now), before - 5)
        j.lapses.removeAll()
        XCTAssertEqual(j.dayStatus(on: day, at: now), .confirmed)
        XCTAssertEqual(j.savingsKr(at: now), before)
        j.unconfirmDay(day)
        XCTAssertEqual(j.dayStatus(on: day, at: now), .unknown)
    }
    func testPartialStartDayCannotBeConfirmedAndCorrectionReclassifiesWithoutDataLoss() {
        var j = journey(); j.quitDate = date("2026-03-27").addingTimeInterval(3600)
        XCTAssertFalse(j.confirmDay(date("2026-03-27"), at: date("2026-03-30")))
        XCTAssertTrue(j.confirmDay(date("2026-03-28"), at: date("2026-03-30")))
        XCTAssertTrue(j.correctQuitDate(to: date("2026-03-29")))
        XCTAssertEqual(j.dayStatus(on: date("2026-03-28"), at: date("2026-03-30")), .beforeStart)
        XCTAssertEqual(j.confirmedDays.count, 1)
    }
    func testDanishDaysHandle23And25HourDSTDays() {
        XCTAssertEqual(date("2026-03-30").timeIntervalSince(date("2026-03-29")), 23 * 3600)
        XCTAssertEqual(date("2026-10-26").timeIntervalSince(date("2026-10-25")), 25 * 3600)
        var j = journey()
        XCTAssertFalse(j.confirmDay(date("2026-03-29"), at: date("2026-03-30").addingTimeInterval(-1)))
        XCTAssertTrue(j.confirmDay(date("2026-03-29"), at: date("2026-03-30")))
        XCTAssertFalse(j.confirmDay(date("2026-10-25"), at: date("2026-10-26").addingTimeInterval(-1)))
        XCTAssertTrue(j.confirmDay(date("2026-10-25"), at: date("2026-10-26")))
        XCTAssertEqual(Journey.dayCalendar.timeZone.identifier, "Europe/Copenhagen")
    }
    func testMidnightPouchBelongsOnlyToNewDay() {
        var j = journey(); let midnight = date("2026-03-29"); let now = date("2026-03-30")
        _ = j.recordLapse(count: 1, trigger: "", at: midnight)
        XCTAssertEqual(j.dayStatus(on: midnight, at: now), .used)
        XCTAssertEqual(j.dayStatus(on: date("2026-03-28"), at: now), .unknown)
        XCTAssertTrue(j.lapses(on: date("2026-03-28"), at: now).isEmpty)
        XCTAssertEqual(j.lapses(on: midnight, at: now).count, 1)
    }
    func testLongDurationsUseCalendarYearsMonthsAndDays() {
        XCTAssertEqual(Danish.duration(from: date("2023-03-20"), to: date("2026-09-22")), "3 år, 6 måneder og 2 dage")
        XCTAssertEqual(Danish.duration(from: date("2026-03-29"), to: date("2026-03-30")), "1 dag")
        XCTAssertEqual(Danish.duration(from: date("2026-03-30"), to: date("2026-03-29")), "Ikke startet endnu")
        XCTAssertEqual(Danish.fullDate(date("2026-03-30")), "30. marts 2026 kl. 00.00")
    }
    func testNewFieldsRoundTripAndOldArchivesMigrate() throws {
        var j = journey(); j.copingPlans = [CopingPlan(trigger: .coffee, action: "Tag tyggegummi frem")]
        j.pauseSessionID = UUID(); j.pauseEndsAt = date("2026-03-30"); j.pauseTrigger = .coffee
        XCTAssertTrue(j.confirmDay(date("2026-03-28"), at: date("2026-03-30")))
        let decoded = try JourneyArchive.decode(JSONEncoder().encode(j))
        XCTAssertEqual(decoded.action(for: .coffee), "Tag tyggegummi frem")
        XCTAssertEqual(decoded.pauseSessionID, j.pauseSessionID)
        XCTAssertEqual(decoded.pauseTrigger, .coffee)
        XCTAssertEqual(decoded.confirmedDays.first?.dayKey, "2026-03-28")
        var old = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(j)) as? [String: Any])
        for key in ["copingPlans", "dayConfirmations", "pauseSessionID", "pauseTrigger"] { old.removeValue(forKey: key) }
        let migrated = try JourneyArchive.decode(JSONSerialization.data(withJSONObject: old))
        XCTAssertEqual(migrated.action(for: .coffee), j.copingAction)
        XCTAssertTrue(migrated.confirmedDays.isEmpty)
        XCTAssertNil(migrated.pauseSessionID)
    }
    func testPauseCompletionIsIdempotentAndLegacyWinsRemainValid() throws {
        var j = journey(); let id = UUID(); j.pauseSessionID = id; j.pauseEndsAt = date("2026-03-30"); j.pauseTrigger = .coffee
        XCTAssertTrue(j.finishPause(id: id, at: date("2026-03-30"), trigger: "Til kaffen", action: nil))
        XCTAssertTrue(j.finishPause(id: id, at: date("2026-03-31"), trigger: nil, action: "Different retry"))
        XCTAssertEqual(j.wins.count, 1); XCTAssertEqual(j.wins[0].trigger, "Til kaffen")
        XCTAssertEqual(j.wins[0].date, date("2026-03-30")); XCTAssertNil(j.pauseSessionID); XCTAssertNil(j.pauseTrigger); XCTAssertNil(j.pauseEndsAt)
        j.wins.append(CravingWin(date: date("2026-03-29")))
        XCTAssertEqual(try JourneyArchive.decode(JSONEncoder().encode(j)).wins.count, 2)
    }
    func testPauseTransitionsRejectCompetingSessionAndUpdateFeedback() {
        var j = journey(); let first = UUID(), second = UUID(), end = date("2026-03-30")
        XCTAssertTrue(j.startPause(id: first, until: end, trigger: .coffee))
        XCTAssertFalse(j.startPause(id: second, until: end, trigger: .stress))
        XCTAssertTrue(j.updatePauseTrigger(.stress)); XCTAssertEqual(j.pauseTrigger, .stress)
        XCTAssertFalse(j.finishPause(id: second, at: end, trigger: nil, action: nil))
        XCTAssertTrue(j.finishPause(id: first, at: end, trigger: " Stress ", action: " Gik en tur "))
        XCTAssertTrue(j.updateWin(id: first, trigger: " Kaffe ", action: " Vand "))
        XCTAssertEqual(j.wins[0].trigger, "Kaffe"); XCTAssertEqual(j.wins[0].action, "Vand")
        XCTAssertFalse(j.updatePauseTrigger(.coffee))
    }
    func testUnchangedQuitDatePreservesBaselineIDs() {
        var j = journey(); let ids = j.baselines.map(\.id)
        XCTAssertTrue(j.correctQuitDate(to: j.quitDate)); XCTAssertEqual(j.baselines.map(\.id), ids)
    }
    func testDayLapsesOnlyCountRecordsKnownByNow() {
        var j = journey(); let day = date("2026-03-29"), now = day.addingTimeInterval(3600)
        _ = j.recordLapse(count: 1, trigger: "", at: now.addingTimeInterval(1))
        XCTAssertTrue(j.lapses(on: day, at: now).isEmpty); XCTAssertEqual(j.dayStatus(on: day, at: now), .ongoing)
        XCTAssertEqual(j.lapses.count, 1)
    }
    func testLapseCorrectionUsesHistoricalPriceAndPreservesID() {
        var j = journey(); let early = date("2026-03-28"), late = date("2026-03-30"), now = date("2026-04-01")
        j.updateConsumption(Consumption(priceOre: 10000), at: date("2026-03-29"))
        let id = j.recordLapse(count: 1, trigger: "", at: early)!
        XCTAssertTrue(j.updateLapse(id: id, count: 3, trigger: "Stress", at: early, now: now))
        XCTAssertEqual(j.lapses[0].unitCostOre, 250)
        XCTAssertTrue(j.updateLapse(id: id, count: 2, trigger: "Kaffe", at: late, now: now))
        XCTAssertEqual(j.lapses[0].unitCostOre, 500); XCTAssertEqual(j.lapses[0].id, id)
        XCTAssertEqual(j.dayStatus(on: early, at: now), .unknown); XCTAssertEqual(j.dayStatus(on: late, at: now), .used)
        XCTAssertFalse(j.updateLapse(id: id, count: 1, trigger: "", at: now.addingTimeInterval(1), now: now))
        XCTAssertFalse(j.updateLapse(id: id, count: 0, trigger: "", at: late, now: now))
    }
    func testMalformedNewFieldsAreRejected() {
        var j = journey()
        j.dayConfirmations = [ConfirmedDay(dayKey: "2026-02-31", confirmedAt: date("2026-03-30"))]; XCTAssertFalse(j.isValid)
        j.dayConfirmations = [ConfirmedDay(dayKey: "2026-03-29", confirmedAt: date("2026-03-29"))]; XCTAssertFalse(j.isValid)
        j.dayConfirmations = nil
        j.copingPlans = [CopingPlan(trigger: .coffee, action: "   ")]; XCTAssertFalse(j.isValid)
        j.copingPlans = [CopingPlan(trigger: .coffee, action: "A"), CopingPlan(trigger: .coffee, action: "B")]; XCTAssertFalse(j.isValid)
        j.copingPlans = nil
        j.wins = [CravingWin(date: date("2026-03-29"), action: String(repeating: "a", count: 251))]; XCTAssertFalse(j.isValid)
        XCTAssertNil(Journey.date(forDayKey: "2026-+1-01"))
        XCTAssertNil(Journey.date(forDayKey: "2026-01-+1"))
    }
}
