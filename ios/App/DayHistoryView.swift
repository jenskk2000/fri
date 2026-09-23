import SwiftUI

private struct HistoryDay: Identifiable {
    let date: Date
    var id: String { DailyCheckIn.key(for: date, calendar: Journey.dayCalendar) }
}

private struct HistoryDaySnapshot: Identifiable {
    let date: Date
    let status: DayStatus
    var id: Date { date }
}

struct DayHistoryView: View {
    let journey: Journey
    let now: Date
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selected: HistoryDay?
    @State private var otherDate = Date()
    private var days: [Date] {
        (0..<14).reversed().compactMap { Journey.dayCalendar.date(byAdding: .day, value: -$0, to: Journey.dayCalendar.startOfDay(for: now)) }
    }
    var body: some View {
        let daySnapshots = days.map { HistoryDaySnapshot(date: $0, status: journey.dayStatus(on: $0, at: now)) }
        let confirmedCount = daySnapshots.lazy.filter { $0.status == .confirmed }.count
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(text: "Dine seneste 14 dage")
            Text(confirmedLabel(count: confirmedCount))
                .font(Ink.body(.headline)).accessibilityIdentifier("confirmedDaysCount")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: typeSize.isAccessibilitySize ? 3 : 7), spacing: 12) {
                ForEach(daySnapshots) { day in
                    Button { selected = HistoryDay(date: day.date) } label: {
                        VStack(spacing: 8) {
                            Text(dayNumber(day.date)).font(Ink.body(.caption))
                            Image(systemName: day.status.symbol).font(.system(size: 19))
                        }.frame(maxWidth: .infinity, minHeight: 58)
                            .foregroundStyle(day.status == .confirmed ? Ink.mint : Ink.text)
                            .background(Ink.surface, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                        .accessibilityLabel("\(dayLabel(day.date)): \(day.status.rawValue)")
                        .accessibilityIdentifier("day-\(DailyCheckIn.key(for: day.date, calendar: Journey.dayCalendar))")
                }
            }
            Text("✓ Bekræftet · − Poser · ? Ukendt · ◷ I gang\nTryk på en dag for at se eller rette den.").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
            DisclosureGroup("Se en anden dato") {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("Dato", selection: $otherDate, in: min(journey.quitDate, now)...now, displayedComponents: .date)
                        .environment(\.timeZone, Journey.dayCalendar.timeZone)
                        .environment(\.calendar, Journey.dayCalendar)
                    Button("Vis dagen") { selected = HistoryDay(date: otherDate) }.frame(minHeight: 44)
                }.padding(.top, 12)
            }.font(Ink.body(.subheadline))
            Text("Dage følger dansk tid. I dag kan først bekræftes, når dagen er slut.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
        }.sheet(item: $selected) { day in DayDetailView(date: day.date) }
    }
    private func confirmedLabel(count: Int) -> String {
        return count == 1 ? "1 bekræftet dag uden poser" : "\(count) bekræftede dage uden poser"
    }
    private func dayNumber(_ date: Date) -> String { String(Journey.dayCalendar.component(.day, from: date)) }
    private func dayLabel(_ date: Date) -> String { Danish.fullDate(date).components(separatedBy: " kl.").first ?? "" }
}

private struct DayDetailView: View {
    let date: Date
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: Lapse?
    var body: some View {
        let now = Date()
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Din dag")
                ScrollView {
                    if let journey = store.journey {
                        let status = journey.dayStatus(on: date, at: now)
                        let recordedLapses = journey.lapses.filter { Journey.dayCalendar.isDate($0.date, inSameDayAs: date) }
                        VStack(alignment: .leading, spacing: 24) {
                            PageHeading(eyebrow: "Dansk tid", title: Danish.fullDate(date).components(separatedBy: " kl.").first ?? "Din dag", subtitle: status.rawValue)
                            if status == .unknown {
                                Text("Var hele dagen uden snus og nikotinposer? Bekræft kun, hvis du selv ved det. Det ændrer ikke dit spareestimat.").font(Ink.body(.body))
                                PrimaryButton(title: "Hele dagen var uden poser", symbol: "checkmark") { if store.confirmDay(date) { dismiss() } }.accessibilityIdentifier("confirmDay")
                            } else if status == .confirmed {
                                Text("Du har selv bekræftet denne dag. En registreret pose vil altid veje tungere end en bekræftelse.").font(Ink.body(.body))
                                QuietButton(title: "Fjern min bekræftelse") {
                                    if store.edit({ $0.unconfirmDay(date) }) { dismiss() }
                                }.accessibilityIdentifier("unconfirmDay")
                            } else if status == .used {
                                Text("Her er registreret poser. Du kan rette en fejl eller fortryde registreringen i Historik.").font(Ink.body(.body))
                            } else {
                                Text(status == .ongoing ? "Dagen er ikke afsluttet endnu. Kom tilbage i morgen, hvis du vil bekræfte den." : "Vi tæller kun hele dage efter din stopdato som bekræftede dage.").font(Ink.body(.body))
                            }
                            ForEach(recordedLapses) { lapse in
                                Button { editing = lapse } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Label("\(lapse.count) \(lapse.count == 1 ? "pose" : "poser") · \(lapse.trigger) · Ret", systemImage: "pencil")
                                        if lapse.date > now {
                                            Text("Registreret med et fremtidigt tidspunkt").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                                        }
                                    }.frame(minHeight: 48, alignment: .leading)
                                }
                            }
                            QuietButton(title: "Luk") { dismiss() }
                        }.padding(26)
                    }
                }
            }
        }.sheet(item: $editing) { lapse in LapseView(existing: lapse) }
    }
}
