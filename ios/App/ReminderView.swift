import SwiftUI
import UserNotifications

struct ReminderView: View {
    @Environment(\.scenePhase) private var phase
    @State private var time = Calendar.current.date(from: DateComponents(hour: 20)) ?? Date()
    @State private var enabled = false
    @State private var denied = false
    @State private var busy = false
    @State private var message = ""
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Din påmindelse")
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        PageHeading(eyebrow: "En venlig påmindelse", title: "På dit\ntidspunkt.", subtitle: "En diskret påmindelse om din plan. Ingen ord om snus på låseskærmen.")
                        NotePanel {
                            Label("Et øjeblik til dig", systemImage: "bell").font(Ink.body(.headline))
                            Text("Hvordan gik din dag? Din plan er klar, når du har brug for den.").font(Ink.body(.subheadline))
                        }
                        DatePicker("Hver dag klokken", selection: $time, displayedComponents: .hourAndMinute)
                        Text(enabled ? (denied ? "Din påmindelse er planlagt, men blokeret af iOS." : "Daglig påmindelse er slået til.") : "Du har ingen aktiv daglig påmindelse.").font(Ink.body(.subheadline)).accessibilityIdentifier("reminderStatus")
                        if denied {
                            Text("Notifikationer er slået fra i iOS. Tillad dem i Indstillinger, og kom tilbage for at aktivere tidspunktet.").font(Ink.body(.subheadline))
                            Button("Åbn iPhones indstillinger") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }.frame(minHeight: 44)
                        }
                        PrimaryButton(title: busy ? "Et øjeblik …" : enabled ? "Gem tidspunkt" : "Slå påmindelse til", symbol: "bell") {
                            Task { await schedule() }
                        }.disabled(busy || denied).accessibilityIdentifier("enableReminder")
                        if enabled {
                            QuietButton(title: "Slå påmindelse fra") {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["fri.daily"])
                                enabled = false; message = "Påmindelsen er slået fra."
                            }.accessibilityIdentifier("disableReminder")
                        }
                        if !message.isEmpty { Text(message).font(Ink.body(.subheadline)).accessibilityIdentifier("reminderMessage") }
                        Text("Tidspunktet følger telefonens lokale tidszone. Fokus og iPhones notifikationsindstillinger kan gøre påmindelsen lydløs eller forsinke den.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                    }.padding(26)
                }
            }
        }.task { await refresh() }.onChange(of: phase) { _, value in if value == .active { Task { await refresh() } } }
    }
    private func refresh() async {
        let center = UNUserNotificationCenter.current()
        denied = await center.notificationSettings().authorizationStatus == .denied
        let pending = await center.pendingNotificationRequests()
        let request = pending.first { $0.identifier == "fri.daily" }
        enabled = request != nil
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger,
           let date = Calendar.current.date(from: trigger.dateComponents) { time = date }
    }
    private func schedule() async {
        busy = true; defer { busy = false }
        let center = UNUserNotificationCenter.current()
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound]) else { await refresh(); return }
            let content = UNMutableNotificationContent()
            content.title = "Et øjeblik til dig"
            content.body = "Hvordan gik din dag? Din plan er klar, når du har brug for den."
            content.sound = .default
            let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
            try await center.add(UNNotificationRequest(identifier: "fri.daily", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)))
            await refresh(); message = "Gemt. Vi minder dig om din plan hver dag."
        } catch { message = "Påmindelsen kunne ikke gemmes. Prøv igen." }
    }
}
