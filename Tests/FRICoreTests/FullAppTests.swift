import XCTest
@testable import FRICore

final class FullAppTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_790_000_000)
    func journey() -> Journey { Journey(quitDate: start, motivation: .freedom, triggers: [.coffee], consumption: Consumption()) }
    func temporaryArchive() -> JourneyArchive { JourneyArchive(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("journey.json")) }
    func testOriginalMVPArchiveStillDecodes() throws {
        let data = try JSONEncoder().encode(journey())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "checkIns"); json.removeValue(forKey: "pauseEndsAt")
        let loaded = try JourneyArchive.decode(JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(loaded.reflections.isEmpty)
        XCTAssertNil(loaded.pauseEndsAt)
        XCTAssertEqual(loaded.savingsKr(at: start.addingTimeInterval(86400)), 25)
    }
    func testOneCheckInPerLocalDayPreservesID() {
        var j = journey()
        let first = DailyCheckIn(date: start, dayKey: "2026-09-22", energy: 2, craving: 4, note: "En svær morgen")
        XCTAssertTrue(j.saveCheckIn(first))
        XCTAssertTrue(j.saveCheckIn(DailyCheckIn(date: start, dayKey: first.dayKey, energy: 4, craving: 1, note: "Bedre nu")))
        XCTAssertEqual(j.reflections.count, 1)
        XCTAssertEqual(j.reflections.first?.id, first.id)
        XCTAssertEqual(j.reflections.first?.note, "Bedre nu")
    }
    func testInvalidCheckInCannotReplaceValidNote() {
        var j = journey()
        let entry = DailyCheckIn(date: start, dayKey: "2026-09-22", energy: 3, craving: 2, note: "ok")
        XCTAssertTrue(j.saveCheckIn(entry))
        var invalid = entry; invalid.energy = 0
        XCTAssertFalse(j.saveCheckIn(invalid))
        invalid = entry; invalid.note = String(repeating: "a", count: 501)
        XCTAssertFalse(j.saveCheckIn(invalid))
        invalid = entry; invalid.dayKey = "2026-02-31"
        XCTAssertFalse(j.saveCheckIn(invalid))
        XCTAssertEqual(j.reflections, [entry])
    }
    func testCheckInRemovalIsTargetedAndIdempotent() {
        var j = journey(); let a = DailyCheckIn(date: start, dayKey: "2026-09-22", energy: 3, craving: 2, note: "a")
        let b = DailyCheckIn(date: start, dayKey: "2026-09-23", energy: 4, craving: 1, note: "b")
        XCTAssertTrue(j.saveCheckIn(a)); XCTAssertTrue(j.saveCheckIn(b))
        XCTAssertTrue(j.removeCheckIn(id: a.id)); XCTAssertEqual(j.reflections, [b])
        XCTAssertFalse(j.removeCheckIn(id: a.id))
    }
    func testLocalDateKeysRespectTimezoneBoundary() {
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        var a = Calendar(identifier: .gregorian); a.timeZone = TimeZone(secondsFromGMT: -12 * 3600)!
        var b = a; b.timeZone = TimeZone(secondsFromGMT: 14 * 3600)!
        XCTAssertNotEqual(DailyCheckIn.key(for: date, calendar: a), DailyCheckIn.key(for: date, calendar: b))
    }
    func testMilestonesRemainAfterSetback() {
        var j = journey()
        _ = j.recordLapse(count: 1, trigger: "kaffe", at: start.addingTimeInterval(15 * 86400))
        let now = start.addingTimeInterval(16 * 86400)
        XCTAssertEqual(j.streakDays(at: now), 1)
        XCTAssertEqual(j.longestStreakDays(at: now), 15)
        XCTAssertEqual(Milestone.all.filter { $0.days <= j.longestStreakDays(at: now) }.last?.days, 14)
    }
    func testLongestStreakWithMultipleSetbacksAndFutureEvents() {
        var j = journey()
        for day in [2, 10, 30] { _ = j.recordLapse(count: 1, trigger: "", at: start.addingTimeInterval(Double(day) * 86400)) }
        XCTAssertEqual(j.longestStreakDays(at: start.addingTimeInterval(14 * 86400)), 8)
        XCTAssertEqual(j.longestStreakDays(at: start.addingTimeInterval(-1)), 0)
    }
    func testDateCorrectionKeepsLaterPriceHistory() {
        var j = journey()
        j.updateConsumption(Consumption(pouchesPerDay: 20), at: start.addingTimeInterval(86400))
        XCTAssertTrue(j.correctQuitDate(to: start.addingTimeInterval(-86400)))
        XCTAssertTrue(j.isValid)
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(2 * 86400)), 100)
        XCTAssertTrue(j.correctQuitDate(to: start.addingTimeInterval(86400)))
        XCTAssertEqual(j.savingsKr(at: start.addingTimeInterval(2 * 86400)), 50)
        XCTAssertEqual(j.baselines.count, 1)
    }
    func testDateCorrectionRejectsLosingRecordedPouches() {
        var j = journey()
        _ = j.recordLapse(count: 1, trigger: "", at: start.addingTimeInterval(3600))
        XCTAssertFalse(j.correctQuitDate(to: start.addingTimeInterval(7200)))
        XCTAssertEqual(j.quitDate, start)
        XCTAssertEqual(j.lapses.count, 1)
    }
    func testBackdatedPouchUsesHistoricalPriceAndLatestStreak() {
        var j = journey()
        j.updateConsumption(Consumption(priceOre: 10000), at: start.addingTimeInterval(86400))
        _ = j.recordLapse(count: 1, trigger: "", at: start.addingTimeInterval(2 * 86400))
        _ = j.recordLapse(count: 1, trigger: "", at: start.addingTimeInterval(3600))
        XCTAssertEqual(j.usedCostOre(at: start.addingTimeInterval(3 * 86400)), 750)
        XCTAssertEqual(j.streakDays(at: start.addingTimeInterval(3 * 86400)), 1)
    }
    func testPauseAndNotesPersist() throws {
        let archive = temporaryArchive(); defer { try? FileManager.default.removeItem(at: archive.url.deletingLastPathComponent()) }
        var j = journey(); j.pauseEndsAt = start.addingTimeInterval(120)
        _ = j.saveCheckIn(DailyCheckIn(date: start, dayKey: "2026-09-22", energy: 3, craving: 1, note: "Gik en tur"))
        try archive.save(j)
        let loaded = try XCTUnwrap(archive.load())
        XCTAssertEqual(loaded.pauseEndsAt, j.pauseEndsAt)
        XCTAssertEqual(loaded.reflections, j.reflections)
    }
    func testBackupRotatesAndRestoreIsReversible() throws {
        let archive = temporaryArchive(); defer { try? FileManager.default.removeItem(at: archive.url.deletingLastPathComponent()) }
        let old = journey(); try archive.save(old)
        var next = old; next.goalName = "En cykel"; try archive.save(next)
        XCTAssertEqual(try archive.loadBackup().goalName, old.goalName)
        try archive.restore(archive.loadBackup())
        XCTAssertEqual(try archive.load()?.goalName, old.goalName)
        XCTAssertEqual(try archive.loadBackup().goalName, "En cykel")
    }
    func testCorruptPrimaryPreservedDuringRecovery() throws {
        let archive = temporaryArchive(); defer { try? FileManager.default.removeItem(at: archive.url.deletingLastPathComponent()) }
        try archive.save(journey()); try archive.save(journey())
        let corrupt = Data("broken".utf8); try corrupt.write(to: archive.url)
        XCTAssertThrowsError(try archive.save(journey()))
        XCTAssertEqual(try Data(contentsOf: archive.url), corrupt)
        try archive.restore(archive.loadBackup())
        XCTAssertEqual(try Data(contentsOf: archive.recoveryURL), corrupt)
        XCTAssertNotNil(try archive.load())
    }
    func testInvalidImportCannotOverwritePrimaryOrBackup() throws {
        let archive = temporaryArchive(); defer { try? FileManager.default.removeItem(at: archive.url.deletingLastPathComponent()) }
        let j = journey(); try archive.save(j); try archive.save(j)
        let before = try Data(contentsOf: archive.url), backup = try Data(contentsOf: archive.backupURL)
        var invalid = j; invalid.version = 999
        XCTAssertThrowsError(try archive.restore(invalid))
        XCTAssertEqual(try Data(contentsOf: archive.url), before)
        XCTAssertEqual(try Data(contentsOf: archive.backupURL), backup)
    }
    func testMalformedHistoricalSegmentsAndDuplicateIDsRejected() throws {
        var j = journey(); j.baselines.append(j.baselines[0]); XCTAssertFalse(j.isValid)
        j = journey(); j.quitDate = start.addingTimeInterval(1); XCTAssertFalse(j.isValid)
        j = journey(); let win = CravingWin(date: start); j.wins = [win, win]; XCTAssertFalse(j.isValid)
        j = journey(); j.goalOre = Int.max; XCTAssertFalse(j.isValid)
        j = journey(); j.quitDate = Date(timeIntervalSince1970: .infinity); XCTAssertFalse(j.isValid)
    }
    func testResetDeletesBackupAndRecoveryToo() throws {
        let archive = temporaryArchive(); defer { try? FileManager.default.removeItem(at: archive.url.deletingLastPathComponent()) }
        try archive.save(journey()); try archive.save(journey())
        try Data("bad".utf8).write(to: archive.recoveryURL)
        try archive.delete()
        for path in [archive.url, archive.backupURL, archive.recoveryURL] { XCTAssertFalse(FileManager.default.fileExists(atPath: path.path)) }
    }
}
