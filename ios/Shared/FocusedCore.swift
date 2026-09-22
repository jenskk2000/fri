import Foundation

struct CopingPlan: Codable, Equatable, Identifiable {
    var trigger: Trigger
    var action: String
    var id: String { trigger.rawValue }
    var isValid: Bool { !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && action.count <= 250 }
}

struct ConfirmedDay: Codable, Identifiable {
    var dayKey: String
    var confirmedAt: Date
    var id: String { dayKey }
}

enum DayStatus: String {
    case confirmed = "Bekræftet uden poser"
    case used = "Poser registreret"
    case unknown = "Ikke bekræftet"
    case ongoing = "Dagen er i gang"
    case beforeStart = "Før første hele dag"
    var symbol: String {
        switch self {
        case .confirmed: "checkmark.circle.fill"
        case .used: "minus.circle.fill"
        case .unknown: "questionmark.circle"
        case .ongoing: "clock"
        case .beforeStart: "circle.dotted"
        }
    }
}

extension Journey {
    // A fixed calendar prevents travel or a changed phone timezone from reclassifying old days.
    static var dayCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        calendar.locale = Locale(identifier: "da_DK")
        calendar.firstWeekday = 2
        return calendar
    }
    var personalPlans: [CopingPlan] { copingPlans ?? [] }
    var confirmedDays: [ConfirmedDay] { dayConfirmations ?? [] }
    func action(for trigger: Trigger?) -> String {
        guard let trigger else { return copingAction }
        return personalPlans.first { $0.trigger == trigger }?.action ?? copingAction
    }
    func dayStatus(on date: Date, at now: Date) -> DayStatus {
        let calendar = Self.dayCalendar
        guard let interval = calendar.dateInterval(of: .day, for: date) else { return .unknown }
        if lapses.contains(where: { interval.contains($0.date) && $0.date < interval.end && $0.date <= now }) { return .used }
        if interval.start >= calendar.startOfDay(for: now) { return .ongoing }
        guard interval.start >= quitDate else { return .beforeStart }
        return confirmedDays.contains { $0.dayKey == DailyCheckIn.key(for: date, calendar: calendar) } ? .confirmed : .unknown
    }
    @discardableResult mutating func confirmDay(_ date: Date, at now: Date) -> Bool {
        guard let interval = Self.dayCalendar.dateInterval(of: .day, for: date), interval.end <= now,
              interval.start >= quitDate, dayStatus(on: date, at: now) != .used else { return false }
        let key = DailyCheckIn.key(for: date, calendar: Self.dayCalendar)
        guard !confirmedDays.contains(where: { $0.dayKey == key }) else { return true }
        dayConfirmations = confirmedDays + [ConfirmedDay(dayKey: key, confirmedAt: now)]
        return true
    }
    mutating func unconfirmDay(_ date: Date) {
        let key = DailyCheckIn.key(for: date, calendar: Self.dayCalendar)
        dayConfirmations = confirmedDays.filter { $0.dayKey != key }
    }
    @discardableResult mutating func finishPause(id: UUID, at date: Date, trigger: String?, action: String?) -> Bool {
        guard date.timeIntervalSince1970.isFinite, (trigger?.count ?? 0) <= 100, (action?.count ?? 0) <= 250 else { return false }
        // The persisted session ID makes retries and resumed sessions idempotent.
        if !wins.contains(where: { $0.id == id }) {
            wins.append(CravingWin(id: id, date: date, trigger: trigger, action: action))
        }
        pauseEndsAt = nil; pauseSessionID = nil; pauseTrigger = nil
        return true
    }
    @discardableResult mutating func updateLapse(id: UUID, count: Int, trigger: String, at date: Date, now: Date) -> Bool {
        guard let index = lapses.firstIndex(where: { $0.id == id }), (1...100).contains(count),
              date >= quitDate, date <= now, trigger.count <= 100 else { return false }
        let previous = lapses[index]
        // Preserve captured unit cost for a count/description correction; date changes use that date's baseline.
        let cost = date == previous.date ? previous.unitCostOre : consumption(at: date).pouchCostOre
        lapses[index] = Lapse(id: id, date: date, count: count, trigger: trigger, unitCostOre: cost)
        return true
    }
    var focusedFieldsAreValid: Bool {
        guard personalPlans.count <= Trigger.allCases.count,
              personalPlans.allSatisfy(\.isValid), Set(personalPlans.map(\.trigger)).count == personalPlans.count,
              confirmedDays.count <= 100000, Set(confirmedDays.map(\.dayKey)).count == confirmedDays.count,
              wins.allSatisfy({ ($0.trigger?.count ?? 0) <= 100 && ($0.action?.count ?? 0) <= 250 }) else { return false }
        return confirmedDays.allSatisfy { day in
            guard let start = Self.date(forDayKey: day.dayKey),
                  let end = Self.dayCalendar.date(byAdding: .day, value: 1, to: start) else { return false }
            return day.confirmedAt.timeIntervalSince1970.isFinite && day.confirmedAt >= end
                && day.confirmedAt < Date(timeIntervalSince1970: 32_503_680_000)
        }
    }
    static func date(forDayKey key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = dayCalendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = dayCalendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: key), formatter.string(from: date) == key else { return nil }
        return date
    }
}

extension Motivation {
    var homeTitle: String {
        switch self { case .freedom: "Mere plads"; case .energy: "På vej mod"; case .money: "Flere penge" }
    }
    var homeAccent: String {
        switch self { case .freedom: "til dig."; case .energy: "mere overskud."; case .money: "til dit liv." }
    }
}

extension Danish {
    static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "da_DK")
        formatter.timeZone = Journey.dayCalendar.timeZone
        formatter.dateFormat = "d. MMMM yyyy 'kl.' HH.mm"
        return formatter.string(from: date)
    }
    static func duration(from start: Date, to end: Date, calendar: Calendar = Journey.dayCalendar) -> String {
        guard end >= start else { return "Ikke startet endnu" }
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start, to: end)
        var items: [String] = []
        if let years = parts.year, years > 0 { items.append("\(years) år") }
        if let months = parts.month, months > 0 { items.append("\(months) \(months == 1 ? "måned" : "måneder")") }
        if let days = parts.day, days > 0 { items.append("\(days) \(days == 1 ? "dag" : "dage")") }
        if items.isEmpty {
            if let hours = parts.hour, hours > 0 { items.append("\(hours) \(hours == 1 ? "time" : "timer")") }
            else { let minutes = parts.minute ?? 0; items.append("\(minutes) \(minutes == 1 ? "minut" : "minutter")") }
        }
        if items.count < 2 { return items[0] }
        return items.dropLast().joined(separator: ", ") + " og " + items.last!
    }
}
