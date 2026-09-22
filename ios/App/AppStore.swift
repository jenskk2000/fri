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
        do {
            try archive.save(value)
            try? clearDraft()
            journey = value
            WidgetCenter.shared.reloadAllTimelines()
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
        if edit({ $0.lapses.removeAll { $0.id == id } }) { notice = "Registreringen er fortrudt." }
    }
    @discardableResult func addWin(id: UUID, trigger: String?, action: String?) -> Bool {
        guard var next = journey, next.finishPause(id: id, at: Date(), trigger: trigger, action: action) else { return false }
        if commit(next) { notice = "Du kom videre. Din pause er gemt."; return true }
        return false
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
