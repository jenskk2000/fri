import SwiftUI

struct CravingView: View {
    @Environment(AppStore.self) private var store
    @State private var endDate: Date?
    @State private var sessionID = UUID()
    @State private var trigger: Trigger?
    @State private var completed: CravingWin?
    @State private var saving = false
    private var duration: TimeInterval {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-fast-timer") { return 2 }
        #endif
        return 120
    }
    var body: some View {
        Group {
            if let completed { WinFeedbackView(existing: completed, suggestion: store.journey?.action(for: trigger), justCompleted: true) }
            else { support }
        }.onAppear {
            endDate = store.journey?.pauseEndsAt
            sessionID = store.journey?.pauseSessionID ?? sessionID
            trigger = store.journey?.pauseTrigger
        }
    }
    private var support: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Hjælp lige nu")
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeading(eyebrow: "Ét øjeblik ad gangen", title: "Du har en plan.", subtitle: "Du behøver kun vælge dit næste lille skridt.")
                        NotePanel {
                            Eyebrow(text: trigger?.rawValue ?? "Dit næste lille skridt")
                            Text(store.journey?.action(for: trigger) ?? Trigger.routine.suggestion)
                                .font(Ink.body(.title3, weight: .semibold)).accessibilityIdentifier("activeCopingAction")
                            Picker("Situation (valgfrit)", selection: $trigger) {
                                Text("Min generelle plan").tag(Trigger?.none)
                                ForEach(store.journey?.triggers ?? []) { item in Text(item.rawValue).tag(Optional(item)) }
                            }.accessibilityIdentifier("cravingSituation")
                        }
                        if let endDate {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                let remaining = min(Int(duration), max(0, Int(ceil(endDate.timeIntervalSince(context.date)))))
                                VStack(spacing: 12) {
                                    Text(remaining == 0 ? "Tag din tid." : String(format: "%d:%02d", remaining / 60, remaining % 60))
                                        .font(Ink.title(44)).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                                    ProgressView(value: 1 - Double(remaining) / duration).tint(Ink.mint)
                                    Text(remaining == 0 ? "Du bestemmer, hvornår du er klar." : "Sænk skuldrene. Træk vejret i dit eget tempo.")
                                        .font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                                }.frame(maxWidth: .infinity).accessibilityElement(children: .combine)
                            }
                            PrimaryButton(title: "Jeg er kommet videre", symbol: "checkmark") {
                                guard !saving else { return }; saving = true
                                if store.addWin(id: sessionID, trigger: trigger?.rawValue, action: nil) {
                                    completed = store.journey?.wins.first { $0.id == sessionID }
                                }
                                saving = false
                            }.disabled(saving).accessibilityIdentifier("finishPause")
                            QuietButton(title: "Tag 2 minutter mere") { startPause() }
                        } else {
                            PrimaryButton(title: "Tag 2 minutter", symbol: "play.fill") { startPause() }.accessibilityIdentifier("startPause")
                            Text("Læg dåsen lidt væk, hvis du kan. Pausen fortsætter, selv om du lukker appen.").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                        }
                        Link("Hjælp hos Stoplinien ↗", destination: URL(string: "https://stoplinien.dk")!).font(Ink.body(.footnote)).frame(minHeight: 44)
                    }.padding(26)
                }
            }
        }.onChange(of: trigger) { _, value in
            if endDate != nil { _ = store.edit { $0.pauseTrigger = value } }
        }
    }
    private func startPause() {
        let end = Date().addingTimeInterval(duration)
        if store.edit({ $0.pauseEndsAt = end; $0.pauseSessionID = sessionID; $0.pauseTrigger = trigger }) { endDate = end }
    }
}

struct WinFeedbackView: View {
    let existing: CravingWin
    var suggestion: String? = nil
    var justCompleted = false
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var trigger = ""
    @State private var action = ""
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: justCompleted ? "Din pause er gemt" : "Ret din pause")
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeading(eyebrow: "Til næste gang", title: "Hvad hjalp dig?", subtitle: justCompleted ? "Din pause tæller allerede. Tilføj en note, hvis du har lyst." : "Du kan rette situationen og det, der hjalp.")
                        TextField("Situation (valgfrit)", text: $trigger).padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 12)).accessibilityIdentifier("winTrigger")
                        TextField("Det, der hjalp (valgfrit)", text: $action, axis: .vertical).lineLimit(2...5).padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 12)).accessibilityIdentifier("winAction")
                        if let suggestion {
                            Button("Min valgte handling hjalp") { action = String(suggestion.prefix(250)) }.font(Ink.body(.subheadline)).frame(minHeight: 44)
                        }
                        Text("Situation: højst 100 tegn. Handling: højst 250 tegn.").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                        PrimaryButton(title: "Gem og luk", symbol: "checkmark") { save() }
                            .disabled(trigger.count > 100 || action.count > 250).accessibilityIdentifier("saveWinFeedback")
                        QuietButton(title: justCompleted ? "Spring over" : "Annuller") { dismiss() }.accessibilityIdentifier("skipWinFeedback")
                    }.padding(26)
                }.scrollDismissesKeyboard(.interactively)
            }
        }.onAppear { trigger = existing.trigger ?? ""; action = existing.action ?? "" }
    }
    private func save() {
        guard var next = store.journey, let index = next.wins.firstIndex(where: { $0.id == existing.id }) else { return }
        next.wins[index].trigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        next.wins[index].action = action.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        if store.commit(next) { dismiss() }
    }
}

private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }

struct LapseView: View {
    var existing: Lapse? = nil
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var count = 1
    @State private var reason = "Bare af vane"
    @State private var saving = false
    @State private var date = Date()
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "En note til dig selv")
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        PageHeading(eyebrow: "Du er stadig på vej", title: "En pose er\nikke hele historien.", subtitle: "Notér det, lær lidt af det, og fortsæt. Dine tidligere fremskridt bliver hos dig.")
                        Stepper(value: $count, in: 1...100) {
                            VStack(alignment: .leading, spacing: 4) { Text("Hvor mange poser?").font(Ink.body(.subheadline)); Text("\(count)").scaledTitle(36) }
                        }.accessibilityIdentifier("lapseCount")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hvad skete der?").font(Ink.body(.headline))
                            Picker("Situation", selection: $reason) {
                                if !Trigger.allCases.map(\.rawValue).contains(reason) && reason != "Noget andet" { Text(reason).tag(reason) }
                                ForEach(Trigger.allCases) { Text($0.rawValue).tag($0.rawValue) }; Text("Noget andet").tag("Noget andet") }.pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(10).background(Ink.text.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                        }
                        if let j = store.journey {
                            DatePicker("Hvornår var det?", selection: $date, in: min(j.quitDate, Date())...Date(), displayedComponents: [.date, .hourAndMinute]).accessibilityIdentifier("lapseDate")
                            NotePanel {
                                Text("Hvad ændrer sig?").font(Ink.body(.headline))
                                Text("Din stime beregnes fra den seneste registrerede pose. Denne registrering fratrækker \(Danish.money(Double(count) * ((existing?.date == date ? existing?.unitCostOre : nil) ?? j.consumption(at: date).pouchCostOre) / 100, decimals: 2)) kr. fra dit anslåede sparebeløb.").font(Ink.body(.subheadline)).lineSpacing(3)
                                Text("Din samlede indsats og din plan bliver bevaret. Du kan fortryde i Fremskridt.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                            }
                        }
                        PrimaryButton(title: existing == nil ? "Notér og fortsæt" : "Gem rettelse", symbol: "checkmark") {
                            guard !saving else { return }; saving = true
                            let success: Bool
                            if let existing, var next = store.journey {
                                success = next.updateLapse(id: existing.id, count: count, trigger: reason, at: date, now: Date()) && store.commit(next)
                            } else { success = store.addLapse(count: count, trigger: reason, at: date) }
                            if success { dismiss() } else { saving = false }
                        }.disabled(saving).accessibilityIdentifier("confirmLapse")
                        QuietButton(title: "Annuller") { dismiss() }
                    }.padding(26)
                }
            }
        }.onAppear {
            if let existing { count = existing.count; reason = existing.trigger; date = existing.date }
        }
    }
}

struct SavingsDetailView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Sådan regner vi")
                ScrollView {
                    if let j = store.journey {
                        let now = Date()
                        let c = j.consumption(at: now)
                        VStack(alignment: .leading, spacing: 25) {
                            PageHeading(eyebrow: "Kroner, du kan beholde", title: "Dit forbrug.\nDit sparebeløb.", subtitle: "Et estimat af det snusforbrug, du har undgået. Det er ikke en bankkonto.")
                            Text("\(Danish.money(j.savingsKr(at: now), decimals: 2)) kr.").scaledTitle(45).minimumScaleFactor(0.5).lineLimit(1)
                            NotePanel {
                                row("Pris pr. dåse", "\(Danish.money(Double(c.priceOre) / 100, decimals: 2)) kr.")
                                row("Poser i en dåse", "\(c.pouchesPerTin)")
                                row("Dit tidligere daglige forbrug", "\(c.pouchesPerDay) poser")
                                Divider().overlay(Ink.text.opacity(0.1))
                                row("Dagligt udgangspunkt", "\(Danish.money(c.dailyCostOre / 100, decimals: 2)) kr.")
                            }
                            Text("Pris pr. dåse ÷ poser pr. dåse × poser pr. dag = dit daglige udgangspunkt.").font(.system(.body, design: .default).weight(.medium))
                            VStack(spacing: 15) {
                                row("Forventet forbrug siden start", "\(Danish.money(j.baselineCostOre(at: now) / 100, decimals: 2)) kr.")
                                row("Registrerede poser", "− \(Danish.money(j.usedCostOre(at: now) / 100, decimals: 2)) kr.")
                            }
                            Text("Beløbet vokser løbende fra din stopdato. Vi bruger faktisk forløbet tid: 24 timer er én dag. Registrerede poser trækkes fra til prisen på registreringstidspunktet. Beløbet vises aldrig under 0 kr.").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted).lineSpacing(4)
                            Text("Retter du dit forbrug, gælder ændringen fremadrettet. Tidligere besparelser bliver ikke skrevet om. Køb af hele dåser og nikotinerstatning indgår ikke i dette forbrugsestimat.").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted).lineSpacing(4)
                        }.padding(26)
                    }
                }
            }
        }
    }
    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) { Text(label).font(Ink.body(.subheadline)); Spacer(minLength: 10); Text(value).font(Ink.body(.subheadline, weight: .bold)).multilineTextAlignment(.trailing) }
    }
}
