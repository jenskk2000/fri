import SwiftUI
import Observation
import WidgetKit
import UserNotifications

@MainActor @Observable
final class AppStore {
    private(set) var journey: Journey?
    var error: String?
    var loadFailed = false
    var notice: String?
    var restorationID = UUID()
    let archive: JourneyArchive

    init() {
        var selected = JourneyArchive.shared()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            selected = JourneyArchive(url: selected.url.deletingLastPathComponent().appendingPathComponent("fri-uitest.json"))
            if ProcessInfo.processInfo.arguments.contains("-reset-state") {
                try? selected.delete()
                try? FileManager.default.removeItem(at: selected.url.appendingPathExtension("onboarding"))
            }
        }
        #endif
        archive = selected
        do { journey = try archive.load() }
        catch { self.error = "Dine data kunne ikke åbnes. De er bevaret på telefonen. Prøv at åbne appen igen."; loadFailed = true }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demo"), journey == nil {
            var demo = Journey(quitDate: Date().addingTimeInterval(-15 * 86400), motivation: .freedom, triggers: [.study, .coffee], consumption: Consumption())
            demo.goalName = "En weekend væk"
            demo.goalOre = 150000
            _ = commit(demo)
        }
        #endif
    }

    @discardableResult func commit(_ value: Journey) -> Bool {
        guard !loadFailed else { return false }
        let shouldReloadWidgets = journey.map { widgetContentChanged(from: $0, to: value) } ?? true
        do {
            try archive.save(value)
            try? clearDraft()
            journey = value
            if shouldReloadWidgets { WidgetCenter.shared.reloadAllTimelines() }
            return true
        } catch {
            self.error = "Ændringen kunne ikke gemmes. Dine tidligere data er bevaret. Prøv igen."
            return false
        }
    }
    @discardableResult func edit(_ update: (inout Journey) -> Void) -> Bool {
        guard var updated = journey else { return false }
        update(&updated)
        return commit(updated)
    }
    @discardableResult func reset() -> Bool {
        do {
            try clearDraft()
            try archive.delete()
            journey = nil
            loadFailed = false
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["fri.daily"])
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch { self.error = "Data kunne ikke slettes. Prøv igen."; return false }
    }
    func addLapse(count: Int, trigger: String, at date: Date = Date()) -> Bool {
        guard date <= Date(), var next = journey, next.recordLapse(count: count, trigger: trigger, at: date) != nil else { return false }
        if commit(next) { notice = "Noteret. Du fortsætter herfra."; return true }
        return false
    }
    func undoLapse(_ id: UUID) {
        guard var next = journey, next.removeLapse(id: id) else { return }
        if commit(next) { notice = "Registreringen er fortrudt." }
    }
    @discardableResult func addWin(id: UUID, trigger: String?, action: String?) -> Bool {
        guard var next = journey, next.finishPause(id: id, at: Date(), trigger: trigger, action: action) else { return false }
        if commit(next) { notice = "Du kom videre. Din pause er gemt."; return true }
        return false
    }
    @discardableResult func startPause(id: UUID, until: Date, trigger: Trigger?) -> Bool {
        guard var next = journey, next.startPause(id: id, until: until, trigger: trigger) else { return false }
        return commit(next)
    }
    @discardableResult func updateActivePauseTrigger(_ trigger: Trigger?) -> Bool {
        guard var next = journey, next.updatePauseTrigger(trigger) else { return false }
        return commit(next)
    }
    @discardableResult func updateWin(id: UUID, trigger: String?, action: String?) -> Bool {
        guard var next = journey, next.updateWin(id: id, trigger: trigger, action: action) else { return false }
        return commit(next)
    }
    @discardableResult func updateLapse(id: UUID, count: Int, trigger: String, at date: Date) -> Bool {
        guard var next = journey, next.updateLapse(id: id, count: count, trigger: trigger, at: date, now: Date()) else { return false }
        return commit(next)
    }
    @discardableResult func deleteWin(_ id: UUID) -> Bool {
        guard var next = journey, next.removeWin(id: id) else { return false }
        return commit(next)
    }
    @discardableResult func deleteCheckIn(_ id: UUID) -> Bool {
        guard var next = journey, next.removeCheckIn(id: id) else { return false }
        return commit(next)
    }
    @discardableResult func savePlan(quitDate: Date, motivation: Motivation, triggers: [Trigger], copingAction: String, personalActions: [Trigger: String]) -> Bool {
        guard var next = journey else { return false }
        if quitDate != next.quitDate, !next.correctQuitDate(to: quitDate) { return false }
        guard next.updatePlan(motivation: motivation, triggers: triggers, copingAction: copingAction, personalActions: personalActions) else { return false }
        if commit(next) { notice = "Din plan er opdateret."; return true }
        return false
    }
    @discardableResult func saveSettings(consumption: Consumption, goalOre: Int, goalName: String, at date: Date = Date()) -> Bool {
        guard var next = journey else { return false }
        if next.consumption(at: date) != consumption { next.updateConsumption(consumption, at: date) }
        next.goalOre = goalOre
        next.goalName = String(goalName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard next.isValid else { return false }
        if commit(next) { notice = "Din plan er opdateret."; return true }
        return false
    }
    @discardableResult func setDiscreetWidget(_ value: Bool) -> Bool {
        edit { $0.discreetWidget = value }
    }
    @discardableResult func confirmDay(_ date: Date) -> Bool {
        guard var next = journey, next.confirmDay(date, at: Date()) else { return false }
        return commit(next)
    }
    @discardableResult func saveCheckIn(_ entry: DailyCheckIn) -> Bool {
        guard var next = journey, next.saveCheckIn(entry) else { return false }
        if commit(next) { notice = "Dit tjek ind er gemt."; return true }
        return false
    }
    @discardableResult func restore(_ value: Journey) -> Bool {
        do {
            try archive.restore(value)
            try? clearDraft()
            journey = value; loadFailed = false; error = nil
            restorationID = UUID()
            notice = "Din sikkerhedskopi er gendannet."
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch { self.error = "Kopien kunne ikke gendannes. Dine nuværende data er bevaret."; return false }
    }

    private func widgetContentChanged(from old: Journey, to new: Journey) -> Bool {
        guard old.quitDate == new.quitDate, old.discreetWidget == new.discreetWidget,
              old.baselines.count == new.baselines.count, old.lapses.count == new.lapses.count else { return true }
        let sameBaselines = zip(old.baselines, new.baselines).allSatisfy {
            $0.id == $1.id && $0.effectiveFrom == $1.effectiveFrom && $0.consumption == $1.consumption
        }
        let sameLapses = zip(old.lapses, new.lapses).allSatisfy {
            $0.id == $1.id && $0.date == $1.date && $0.count == $1.count && $0.unitCostOre == $1.unitCostOre
        }
        return !sameBaselines || !sameLapses
    }

}

enum SheetRoute: String, Identifiable {
    case craving, lapse, settings, savings, widget, journal, milestones, editPlan, reminder, data, privacy
    var id: String { rawValue }
}

@main
struct FRIApp: App {
    @State private var store = AppStore()
    @AppStorage("appearance", store: AppearancePreference.defaults) private var appearance: AppAppearance = .light
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.locale, Locale(identifier: "da_DK"))
                .tint(Ink.mint)
                .background(AppearanceOverride(appearance: appearance).allowsHitTesting(false))
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var recovery = false
    var body: some View {
        Group {
            if store.loadFailed {
                AppScreen {
                    VStack(spacing: 24) {
                        ContentUnavailableView("Dine data er bevaret", systemImage: "externaldrive.badge.exclamationmark", description: Text("Vi kunne ikke læse din gemte plan. Du kan gendanne en kopi uden at overskrive den ulæselige fil."))
                        PrimaryButton(title: "Gendan en sikkerhedskopi", symbol: "arrow.clockwise") { recovery = true }.padding(26)
                    }
                }
            } else if store.journey == nil { OnboardingView() }
            else { MainView().id(store.restorationID) }
        }
        .sheet(isPresented: $recovery) { DataManagementView() }
        .alert("Noget gik galt", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
    }
}
