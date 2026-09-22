import Foundation

struct DailyCheckIn: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    // The local date at entry time remains stable when the phone changes time zone.
    var dayKey: String
    var energy: Int
    var craving: Int
    var note: String
    var isValid: Bool {
        date.timeIntervalSince1970.isFinite && (1...5).contains(energy) && (0...4).contains(craving)
        && note.count <= 500 && Self.validDayKey(dayKey)
    }
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
    private static func validDayKey(_ key: String) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: key) else { return false }
        return formatter.string(from: date) == key
    }
}

struct Milestone: Identifiable {
    let days: Int
    let title: String
    var id: Int { days }
    static let all = [
        Milestone(days: 1, title: "Det første døgn"), Milestone(days: 3, title: "Tre dage på din måde"),
        Milestone(days: 7, title: "En hel uge"), Milestone(days: 14, title: "To uger med mere plads"),
        Milestone(days: 30, title: "30 dage fri"), Milestone(days: 60, title: "En ny rytme"),
        Milestone(days: 100, title: "100 små sejre"), Milestone(days: 365, title: "Et helt år")
    ]
}

extension Journey {
    var reflections: [DailyCheckIn] { checkIns ?? [] }
    func checkIn(on date: Date, calendar: Calendar = .current) -> DailyCheckIn? {
        reflections.first { $0.dayKey == DailyCheckIn.key(for: date, calendar: calendar) }
    }
    @discardableResult mutating func saveCheckIn(_ entry: DailyCheckIn) -> Bool {
        guard entry.isValid else { return false }
        var entries = reflections
        if let i = entries.firstIndex(where: { $0.dayKey == entry.dayKey }) {
            var updated = entry
            updated.id = entries[i].id
            entries[i] = updated
        } else { entries.append(entry) }
        checkIns = entries
        return true
    }
    func longestStreakDays(at now: Date) -> Int {
        guard now > quitDate else { return 0 }
        let boundaries = [quitDate] + lapses.filter { $0.date >= quitDate && $0.date <= now }.map(\.date).sorted() + [now]
        return zip(boundaries, boundaries.dropFirst()).map { Int(max(0, $1.timeIntervalSince($0)) / 86400) }.max() ?? 0
    }
    /// An explicit date correction recalculates the estimate, retaining every later price segment.
    @discardableResult mutating func correctQuitDate(to date: Date) -> Bool {
        guard date.timeIntervalSince1970.isFinite,
              date >= Date(timeIntervalSince1970: 0),
              !lapses.contains(where: { $0.date < date }) else { return false }
        let rate = consumption(at: date)
        let later = baselines.filter { $0.effectiveFrom > date }
        quitDate = date
        baselines = [Baseline(effectiveFrom: date, consumption: rate)] + later
        return true
    }
}
