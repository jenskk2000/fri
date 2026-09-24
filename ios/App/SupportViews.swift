import SwiftUI

/// Free Danish counselling; person-delivered support is the strongest behavioural lever.
enum Stoplinien {
    static let phone = URL(string: "tel:80313131")!
    static let sms = URL(string: "sms:1231&body=Snusfri")!
    static let web = URL(string: "https://stoplinien.dk")!
}

struct SupportCard: View {
    var body: some View {
        NotePanel {
            Eyebrow(text: "Tal med en rådgiver")
            Text("Stoplinien er gratis og kender til snus.").font(Ink.body(.headline, weight: .semibold))
            HStack(spacing: 10) {
                Link(destination: Stoplinien.phone) { Label("Ring", systemImage: "phone.fill").frame(maxWidth: .infinity) }
                Link(destination: Stoplinien.sms) { Label("Skriv", systemImage: "message.fill").frame(maxWidth: .infinity) }
            }.font(Ink.body(.subheadline, weight: .semibold)).buttonStyle(.glass).controlSize(.large)
            Text("80 31 31 31 · eller sms “Snusfri” til 1231").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
        }
    }
}

/// Stop → Move → Surf. Naming the urge, a few minutes of movement, then riding it out.
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
        return 300
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
        AppScreen(photograph: true) {
            VStack(spacing: 0) {
                SheetHeader(title: "Trang")
                ScrollView {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = endDate.map { min(Int(duration), max(0, Int(ceil($0.timeIntervalSince(context.date))))) }
                        let step = remaining.map { Double($0) > duration / 2 ? 1 : 2 } ?? 0
                        VStack(alignment: .leading, spacing: 22) {
                            StepDots(step: step)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(["Det er en trang.", "Bevæg dig.", "Lad den komme og gå."][step])
                                    .scaledTitle(38).tracking(-1.2).fixedSize(horizontal: false, vertical: true)
                                Text(["Den topper og falder på få minutter.", "Gå rask, tag trapperne eller pres hænderne sammen.", "Mærk den toppe og falde. Du behøver ikke gøre noget."][step])
                                    .font(Ink.body(.body)).foregroundStyle(Ink.muted).fixedSize(horizontal: false, vertical: true)
                            }
                            if let remaining {
                                TimerDial(remaining: remaining, duration: duration).frame(maxWidth: .infinity)
                                if step == 1 { MoveIdeas() }
                            }
                            if step == 1 {
                                Text(store.journey?.action(for: trigger) ?? Trigger.routine.suggestion)
                                    .font(Ink.body(.subheadline, weight: .semibold)).foregroundStyle(Ink.muted)
                                    .accessibilityIdentifier("activeCopingAction")
                            } else { plan }
                            if remaining != nil {
                                PrimaryButton(title: "Jeg er kommet videre", symbol: "checkmark") {
                                    guard !saving else { return }; saving = true
                                    if store.addWin(id: sessionID, trigger: trigger?.rawValue, action: nil) {
                                        completed = store.journey?.wins.first { $0.id == sessionID }
                                    }
                                    saving = false
                                }.disabled(saving).accessibilityIdentifier("finishPause")
                                QuietButton(title: "5 minutter mere") { startPause() }
                            } else {
                                PrimaryButton(title: "Start 5 minutter", symbol: "play.fill") { startPause() }.accessibilityIdentifier("startPause")
                                Text("Læg dåsen væk. Tiden fortsætter, selv om du lukker appen.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                            }
                            Link(destination: Stoplinien.phone) { Label("Ring til en rådgiver", systemImage: "phone.fill") }
                                .font(Ink.body(.subheadline, weight: .semibold)).frame(minHeight: 44)
                        }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 26)
                    }
                }.scrollIndicators(.hidden)
            }
        }.onChange(of: trigger) { _, value in
            if endDate != nil { _ = store.updateActivePauseTrigger(value) }
        }
    }
    private var plan: some View {
        NotePanel {
            Eyebrow(text: trigger?.rawValue ?? "Din plan")
            Text(store.journey?.action(for: trigger) ?? Trigger.routine.suggestion)
                .font(Ink.body(.headline, weight: .semibold)).accessibilityIdentifier("activeCopingAction")
            Picker("Situation", selection: $trigger) {
                Text("Min generelle plan").tag(Trigger?.none)
                ForEach(store.journey?.triggers ?? []) { item in Text(item.rawValue).tag(Optional(item)) }
            }.accessibilityIdentifier("cravingSituation")
        }
    }
    private func startPause() {
        let end = Date().addingTimeInterval(duration)
        if store.startPause(id: sessionID, until: end, trigger: trigger) { endDate = end }
    }
}

private struct StepDots: View {
    let step: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in Capsule().fill(i <= step ? Ink.mint : Ink.text.opacity(0.18)).frame(height: 5) }
        }.accessibilityElement().accessibilityLabel("Trin \(step + 1) af 3")
    }
}

private struct TimerDial: View {
    let remaining: Int
    let duration: TimeInterval
    var body: some View {
        ZStack {
            Circle().trim(from: 0, to: 1 - Double(remaining) / duration)
                .stroke(Ink.mint, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90)).padding(10)
            VStack(spacing: 2) {
                Text(remaining == 0 ? "Klar" : String(format: "%d:%02d", remaining / 60, remaining % 60))
                    .font(Ink.title(44)).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                Text(remaining == 0 ? "når du er" : "tilbage").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
            }
        }.frame(width: 180, height: 180)
            .glassEffect(.regular, in: .circle)
            .accessibilityElement(children: .combine)
    }
}

private struct MoveIdeas: View {
    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                idea("Gå rask et par minutter", "figure.walk")
                idea("Tag trapperne", "figure.stairs")
                idea("Pres hænderne hårdt sammen", "hand.raised.fingers.spread")
            }
        }
    }
    private func idea(_ text: String, _ symbol: String) -> some View {
        Label(text, systemImage: symbol).font(Ink.body(.subheadline, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading).glassChip()
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
                            Button("Min valgte handling hjalp") { action = String(suggestion.prefix(Journey.Limits.personalAction)) }.font(Ink.body(.subheadline)).frame(minHeight: 44)
                        }
                        Text("Situation: højst \(Journey.Limits.triggerText) tegn. Handling: højst \(Journey.Limits.personalAction) tegn.").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                        PrimaryButton(title: "Gem og luk", symbol: "checkmark") { save() }
                            .disabled(trigger.count > Journey.Limits.triggerText || action.count > Journey.Limits.personalAction).accessibilityIdentifier("saveWinFeedback")
                        QuietButton(title: justCompleted ? "Spring over" : "Annuller") { dismiss() }.accessibilityIdentifier("skipWinFeedback")
                    }.padding(26)
                }.scrollDismissesKeyboard(.interactively)
            }
        }.onAppear { trigger = existing.trigger ?? ""; action = existing.action ?? "" }
    }
    private func save() {
        let cleanedTrigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let cleanedAction = action.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        if store.updateWin(id: existing.id, trigger: cleanedTrigger, action: cleanedAction) { dismiss() }
    }
}

private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }

struct LapseView: View {
    var existing: Lapse? = nil
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var count = 1
    @State private var reason = Trigger.routine.rawValue
    @State private var saving = false
    @State private var date = Date()
    @State private var recorded = false
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: recorded ? "Start igen" : "En pose")
                ScrollView {
                    if recorded { RecommitView(reason: reason) }
                    else { form }
                }.scrollDismissesKeyboard(.interactively)
            }
        }.onAppear {
            if let existing { count = existing.count; reason = existing.trigger; date = existing.date }
        }
    }
    private var form: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("En pose er ikke\nhele historien.").scaledTitle(34).tracking(-1.1).fixedSize(horizontal: false, vertical: true)
            Stepper(value: $count, in: 1...100) {
                HStack(alignment: .firstTextBaseline, spacing: 8) { Text("\(count)").scaledTitle(36).monospacedDigit(); Text(count == 1 ? "pose" : "poser").font(Ink.body(.headline)) }
            }.accessibilityIdentifier("lapseCount")
            VStack(alignment: .leading, spacing: 10) {
                Text("Hvad udløste det?").font(Ink.body(.headline))
                TriggerChips(selection: $reason)
            }
            if let j = store.journey {
                DatePicker("Hvornår", selection: $date, in: min(j.quitDate, Date())...Date(), displayedComponents: [.date, .hourAndMinute]).accessibilityIdentifier("lapseDate")
                let cost = Double(count) * ((existing?.date == date ? existing?.unitCostOre : nil) ?? j.consumption(at: date).pouchCostOre) / 100
                Text("Trækker \(Danish.money(cost, decimals: 2)) kr. fra. Dine milepæle bevares, og du kan fortryde.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
            }
            PrimaryButton(title: existing == nil ? "Notér" : "Gem rettelse", symbol: "checkmark") {
                guard !saving else { return }; saving = true
                if let existing {
                    if store.updateLapse(id: existing.id, count: count, trigger: reason, at: date) { dismiss() } else { saving = false }
                } else if store.addLapse(count: count, trigger: reason, at: date) {
                    withAnimation { recorded = true }
                } else { saving = false }
            }.disabled(saving).accessibilityIdentifier("confirmLapse")
            QuietButton(title: "Annuller") { dismiss() }
        }.padding(22)
    }
}

private struct TriggerChips: View {
    @Binding var selection: String
    private var options: [String] { Trigger.allCases.map(\.rawValue) + ["Noget andet"] + ([selection].filter { !Trigger.allCases.map(\.rawValue).contains($0) && $0 != "Noget andet" }) }
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button { selection = option } label: {
                    Text(option).font(Ink.body(.subheadline, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }.buttonStyle(.glass).tint(selection == option ? Ink.mint : nil)
                    .foregroundStyle(selection == option ? Ink.mint : Ink.text)
                    .accessibilityAddTraits(selection == option ? [.isSelected] : [])
            }
        }
    }
}

/// After a slip: stop the "I've blown it" spiral, turn the trigger into a plan, recommit to zero now.
private struct RecommitView: View {
    let reason: String
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var action = ""
    @State private var saved = false
    private var trigger: Trigger? { Trigger(rawValue: reason) }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Et glip er data,\nikke et nederlag.").scaledTitle(34).tracking(-1.1).fixedSize(horizontal: false, vertical: true)
                Text("Smid resten væk. Dine milepæle er bevaret.").font(Ink.body(.body)).foregroundStyle(Ink.muted)
            }
            if let trigger {
                NotePanel {
                    Eyebrow(text: "Ny plan · \(trigger.rawValue)")
                    Text("Næste gang gør jeg:").font(Ink.body(.headline, weight: .semibold))
                    TextField("Fx en rask tur i 5 minutter", text: $action, axis: .vertical).lineLimit(2...4)
                        .padding(14).background(Ink.background, in: RoundedRectangle(cornerRadius: 14)).accessibilityIdentifier("recommitAction")
                    Button(saved ? "Gemt i din plan" : "Gem i min plan") { savePlan(for: trigger) }
                        .buttonStyle(.glass).disabled(saved || action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                      || action.count > Journey.Limits.personalAction)
                        .accessibilityIdentifier("saveRecommitPlan")
                }
            }
            PrimaryButton(title: "Start igen fra nu") { dismiss() }.accessibilityIdentifier("recommit")
            Link(destination: Stoplinien.phone) { Label("Ring til en rådgiver", systemImage: "phone.fill") }
                .font(Ink.body(.subheadline, weight: .semibold)).frame(minHeight: 44)
        }.padding(22).onAppear {
            if let trigger { action = store.journey?.personalPlans.first { $0.trigger == trigger }?.action ?? trigger.suggestion }
        }
    }
    private func savePlan(for trigger: Trigger) {
        guard let j = store.journey else { return }
        var actions = Dictionary(uniqueKeysWithValues: j.personalPlans.map { ($0.trigger, $0.action) })
        actions[trigger] = action.trimmingCharacters(in: .whitespacesAndNewlines)
        let triggers = j.triggers.contains(trigger) ? j.triggers : j.triggers + [trigger]
        saved = store.savePlan(quitDate: j.quitDate, motivation: j.motivation, triggers: triggers, copingAction: j.copingAction, personalActions: actions)
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
