import Foundation

enum Motivation: String, Codable, CaseIterable, Identifiable {
    case freedom = "Mere frihed", energy = "Mere overskud", money = "Flere penge"
    var id: String { rawValue }
    var detail: String {
        switch self {
        case .freedom: "En hverdag, hvor dåsen ikke bestemmer."
        case .energy: "Mere plads til det, du gerne vil."
        case .money: "Brug pengene på noget, der betyder noget."
        }
    }
    var symbol: String {
        switch self { case .freedom: "sun.max"; case .energy: "sparkles"; case .money: "banknote" }
    }
}

enum Trigger: String, Codable, CaseIterable, Identifiable {
    case coffee = "Til kaffen", study = "Når jeg læser", work = "På arbejdet", party = "Til fest", stress = "Når jeg er presset", routine = "Bare af vane"
    var id: String { rawValue }
    var suggestion: String {
        switch self {
        case .coffee: "Drik din næste kop et andet sted. Lad dåsen blive væk."
        case .study: "Læg en kort pause ind. Rejs dig, og hent et glas vand."
        case .work: "Tag din næste pause uden dåsen. Gå en lille tur."
        case .party: "Fortæl en ven om din plan. Øv dit: ‘Nej tak, jeg er stoppet.’"
        case .stress: "Giv dig selv et øjeblik. Sænk skuldrene, og træk vejret roligt."
        case .routine: "Læg mærke til øjeblikket. Vælg én lille ting at gøre anderledes."
        }
    }
}

struct Consumption: Codable, Equatable {
    var pouchesPerDay: Int = 10
    var pouchesPerTin: Int = 20
    var priceOre: Int = 5000
    var isValid: Bool { (1...100).contains(pouchesPerDay) && (1...100).contains(pouchesPerTin) && (100...100000).contains(priceOre) }
    var pouchCostOre: Double { isValid ? Double(priceOre) / Double(pouchesPerTin) : 0 }
    var dailyCostOre: Double { pouchCostOre * Double(pouchesPerDay) }
    var monthlyKr: Double { dailyCostOre * 30 / 100 }
}

struct Baseline: Codable, Identifiable {
    var id = UUID()
    var effectiveFrom: Date
    var consumption: Consumption
}

struct Lapse: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var count: Int
    var trigger: String
    // Freeze the unit price at the time of the event; later edits cannot rewrite history.
    var unitCostOre: Double
}

struct CravingWin: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var trigger: String? = nil
    var action: String? = nil
}

struct Journey: Codable {
    enum Limits {
        static let generalAction = 500
        static let personalAction = 250
        static let triggerText = 100
    }
    var version = 1
    var quitDate: Date
    var motivation: Motivation
    var triggers: [Trigger]
    var copingAction: String
    var baselines: [Baseline]
    var lapses: [Lapse] = []
    var wins: [CravingWin] = []
    var goalName = "Noget godt til mig"
    var goalOre = 100000
    var discreetWidget = false
    // Optional fields let the original v1 archive decode without losing existing journeys.
    var checkIns: [DailyCheckIn]? = nil
    var pauseEndsAt: Date? = nil
    var copingPlans: [CopingPlan]? = nil
    var dayConfirmations: [ConfirmedDay]? = nil
    var pauseSessionID: UUID? = nil
    var pauseTrigger: Trigger? = nil

    init(quitDate: Date, motivation: Motivation, triggers: [Trigger], consumption: Consumption) {
        self.quitDate = quitDate
        self.motivation = motivation
        self.triggers = triggers
        self.copingAction = triggers.first?.suggestion ?? Trigger.routine.suggestion
        self.baselines = [Baseline(effectiveFrom: quitDate, consumption: consumption)]
    }

    func consumption(at date: Date) -> Consumption {
        let sorted = baselines.sorted { $0.effectiveFrom < $1.effectiveFrom }
        return sorted.last(where: { $0.effectiveFrom <= date })?.consumption ?? sorted.first?.consumption ?? Consumption()
    }

    /// Integrate the original consumption rate over real elapsed time. A day is 24 hours,
    /// so midnight and daylight-saving transitions never manufacture a day's savings.
    func baselineCostOre(at now: Date) -> Double {
        guard now > quitDate else { return 0 }
        let sorted = baselines.sorted { $0.effectiveFrom < $1.effectiveFrom }
        return sorted.enumerated().reduce(0) { total, item in
            let (index, baseline) = item
            let start = max(quitDate, baseline.effectiveFrom)
            let end = min(now, index + 1 < sorted.count ? sorted[index + 1].effectiveFrom : now)
            return total + max(0, end.timeIntervalSince(start)) / 86400 * baseline.consumption.dailyCostOre
        }
    }

    func usedCostOre(at now: Date) -> Double {
        countedLapses(at: now).reduce(0) { $0 + Double($1.count) * $1.unitCostOre }
    }
    func savingsKr(at now: Date) -> Double { max(0, baselineCostOre(at: now) - usedCostOre(at: now)) / 100 }
    func streakStart(at now: Date) -> Date {
        max(quitDate, countedLapses(at: now).map(\.date).max() ?? quitDate)
    }
    func streakDays(at now: Date) -> Int { Int(max(0, now.timeIntervalSince(streakStart(at: now))) / 86400) }
    func elapsedDays(at now: Date) -> Int { Int(max(0, now.timeIntervalSince(quitDate))) / 86400 }
    func avoidedPouches(at now: Date) -> Int {
        let sorted = baselines.sorted { $0.effectiveFrom < $1.effectiveFrom }
        let expected = sorted.enumerated().reduce(0.0) { total, item in
            let (i, b) = item
            let end = min(now, i + 1 < sorted.count ? sorted[i + 1].effectiveFrom : now)
            return total + max(0, end.timeIntervalSince(max(quitDate, b.effectiveFrom))) / 86400 * Double(b.consumption.pouchesPerDay)
        }
        let used = countedLapses(at: now).reduce(0) { $0 + $1.count }
        return max(0, Int(expected) - used)
    }
    mutating func updateConsumption(_ value: Consumption, at date: Date) {
        guard value.isValid else { return }
        if date <= quitDate { baselines = [Baseline(effectiveFrom: quitDate, consumption: value)] }
        else { baselines.removeAll { $0.effectiveFrom == date }; baselines.append(Baseline(effectiveFrom: date, consumption: value)) }
    }
    mutating func recordLapse(count: Int, trigger: String, at date: Date) -> UUID? {
        guard (1...100).contains(count), date >= quitDate, trigger.count <= Limits.triggerText else { return nil }
        let lapse = Lapse(date: date, count: count, trigger: trigger, unitCostOre: consumption(at: date).pouchCostOre)
        lapses.append(lapse)
        return lapse.id
    }

    var isValid: Bool {
        let epoch = Date(timeIntervalSince1970: 0)
        let latest = Date(timeIntervalSince1970: 32_503_680_000) // year 3000, bounds imported dates
        let dates = [quitDate] + baselines.map(\.effectiveFrom) + lapses.map(\.date) + wins.map(\.date) + reflections.map(\.date) + [pauseEndsAt].compactMap { $0 }
        return focusedFieldsAreValid && version == 1 && !baselines.isEmpty && baselines.count <= 10000
        && dates.allSatisfy { $0.timeIntervalSince1970.isFinite && $0 >= epoch && $0 < latest }
        && baselines.allSatisfy { $0.consumption.isValid && $0.effectiveFrom >= quitDate }
        && baselines.map(\.effectiveFrom).min() == quitDate
        && Set(baselines.map(\.effectiveFrom)).count == baselines.count
        && (1...100000000).contains(goalOre) && !goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && goalName.count <= 80
        && !triggers.isEmpty && Set(triggers).count == triggers.count
        && !copingAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && copingAction.count <= Limits.generalAction
        && lapses.count <= 100000 && wins.count <= 100000 && reflections.count <= 10000
        && lapses.allSatisfy { (1...100).contains($0.count) && $0.unitCostOre.isFinite && (0...100000).contains($0.unitCostOre) && $0.date >= quitDate && $0.trigger.count <= Limits.triggerText }
        && reflections.allSatisfy(\.isValid)
        && Set(lapses.map(\.id)).count == lapses.count && Set(wins.map(\.id)).count == wins.count
        && Set(reflections.map(\.id)).count == reflections.count && Set(reflections.map(\.dayKey)).count == reflections.count
    }
}

enum Danish {
    static func money(_ kroner: Double, decimals: Int = 0) -> String {
        kroner.formatted(.number.locale(Locale(identifier: "da_DK")).grouping(.automatic).precision(.fractionLength(decimals)))
    }
    static func date(_ date: Date) -> String { date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "da_DK"))) }
}
