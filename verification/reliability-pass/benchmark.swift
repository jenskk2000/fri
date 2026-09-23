// Compile as main.swift alongside ios/Shared/*.swift with swiftc -O.
// Local synthetic history timing, not an iPhone responsiveness measurement.
import Foundation
import Dispatch

func milliseconds(_ work: () throws -> Void) rethrows -> Double {
    let start = DispatchTime.now().uptimeNanoseconds
    try work()
    return Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
}
let now = Date(timeIntervalSince1970: 1_790_078_400)
for count in [365, 1825] {
    let start = Journey.dayCalendar.startOfDay(for: now.addingTimeInterval(-Double(count + 1) * 86400))
    var journey = Journey(quitDate: start, motivation: .freedom, triggers: [.coffee], consumption: Consumption())
    for index in 0..<count {
        let date = Journey.dayCalendar.date(byAdding: .day, value: index, to: start)!
        let key = DailyCheckIn.key(for: date, calendar: Journey.dayCalendar)
        journey.dayConfirmations = (journey.dayConfirmations ?? []) + [ConfirmedDay(dayKey: key, confirmedAt: date.addingTimeInterval(2 * 86400))]
        journey.checkIns = (journey.checkIns ?? []) + [DailyCheckIn(date: date, dayKey: key, energy: 3, craving: 2, note: "En almindelig dag")]
        journey.wins.append(CravingWin(date: date, trigger: "Til kaffen", action: "Et glas vand"))
        if index % 7 == 0 { journey.lapses.append(Lapse(date: date, count: 1, trigger: "Til kaffen", unitCostOre: 250)) }
        if index > 0 && index % 30 == 0 { journey.baselines.append(Baseline(effectiveFrom: date, consumption: Consumption())) }
    }
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("fri-benchmark-\(UUID())")
    defer { try? FileManager.default.removeItem(at: directory) }
    let archive = JourneyArchive(url: directory.appendingPathComponent("journey.json"))
    try archive.save(journey)
    let bytes = try Data(contentsOf: archive.url)
    var validation: [Double] = [], save: [Double] = [], decode: [Double] = [], tick: [Double] = []
    for _ in 0..<5 {
        validation.append(milliseconds { precondition(journey.isValid) })
        decode.append(try milliseconds { _ = try JourneyArchive.decode(bytes) })
        save.append(try milliseconds { try archive.save(journey) })
        tick.append(milliseconds {
            // Same workload before/after to isolate shared helper cost.
            for offset in 0..<100 {
                let date = now.addingTimeInterval(Double(offset))
                let value = Danish.money(journey.savingsKr(at: date), decimals: 2)
                precondition(!value.isEmpty)
                _ = Danish.duration(from: journey.streakStart(at: date), to: date)
            }
        } / 100)
    }
    func median(_ values: [Double]) -> String { String(format: "%.3f", values.sorted()[values.count / 2]) }
    print("days=\(count) bytes=\(bytes.count) median_ms validation=\(median(validation)) decode=\(median(decode)) save_with_backup=\(median(save)) live_value=\(median(tick))")
}
