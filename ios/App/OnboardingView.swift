import SwiftUI

struct ConsumptionInput {
    var daily = "10"
    var tin = "20"
    var price = "50"
    init(_ value: Consumption = Consumption()) {
        daily = String(value.pouchesPerDay)
        tin = String(value.pouchesPerTin)
        price = Danish.money(Double(value.priceOre) / 100, decimals: value.priceOre % 100 == 0 ? 0 : 2).replacingOccurrences(of: ".", with: "")
    }
    var value: Consumption? {
        guard let d = Int(daily), let t = Int(tin), let p = Double(price.replacingOccurrences(of: ",", with: ".")), p.isFinite, p >= 1, p <= 1000 else { return nil }
        let candidate = Consumption(pouchesPerDay: d, pouchesPerTin: t, priceOre: Int((p * 100).rounded()))
        return candidate.isValid ? candidate : nil
    }
}

struct ConsumptionFields: View {
    @Binding var input: ConsumptionInput
    var body: some View {
        VStack(spacing: 20) {
            field("Poser om dagen", suffix: "poser", text: $input.daily, id: "dailyPouches", decimal: false)
            field("Poser i en dåse", suffix: "poser", text: $input.tin, id: "tinPouches", decimal: false)
            field("Pris for en dåse", suffix: "kr.", text: $input.price, id: "tinPrice", decimal: true)
        }
    }
    private func field(_ label: String, suffix: String, text: Binding<String>, id: String, decimal: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(.subheadline, design: .default).weight(.semibold))
            HStack {
                TextField(label, text: text).scaledTitle(30).keyboardType(decimal ? .decimalPad : .numberPad)
                    .accessibilityIdentifier(id).accessibilityLabel(label)
                Text(suffix).font(Ink.body(.body)).foregroundStyle(Ink.muted)
            }.padding(.horizontal, 18).padding(.vertical, 12)
                .background(Ink.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Ink.text.opacity(0.2)))
        }
    }
}

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var restored = false
    @State private var importingBackup = false
    @State private var motivation = Motivation.freedom
    @State private var input = ConsumptionInput()
    @State private var triggers: [Trigger] = [.coffee]
    @State private var startMode = 0
    @State private var quitDate = Date()
    @State private var firstAction = ""

    private var draft: OnboardingDraft {
        OnboardingDraft(step: step, motivation: motivation, daily: input.daily, tin: input.tin, price: input.price, triggers: triggers, startMode: startMode, quitDate: quitDate, firstAction: firstAction)
    }
    private var valid: Bool {
        if step == 2 { return input.value != nil }
        if step == 4 && startMode == 1 { return quitDate <= Date() }
        if step == 3 { return !triggers.isEmpty }
        if step == 5 { return input.value != nil && !triggers.isEmpty && firstAction.count <= Journey.Limits.generalAction }
        return true
    }
    var body: some View {
        AppScreen(photograph: step == 0) {
            VStack(spacing: 0) {
                if step == 0 { BrandHeader() }
                else {
                    HStack(spacing: 18) {
                        Button { changeStep(-1) } label: { Image(systemName: "arrow.left").font(.system(size: 19, weight: .medium)).frame(width: 40, height: 44) }
                            .accessibilityLabel("Tilbage")
                        ProgressView(value: Double(step), total: 5).tint(Ink.mint)
                        Text("\(step) / 5").font(.system(size: 12, weight: .semibold)).monospacedDigit()
                    }.padding(.horizontal, 20).padding(.top, 5)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        content
                    }.padding(.horizontal, 28).padding(.top, step == 0 ? 24 : 25).padding(.bottom, 26)
                }.scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively)
                VStack(spacing: 9) {
                    PrimaryButton(title: step == 0 ? "Find min frihed" : step == 5 ? "Lad os komme i gang" : "Fortsæt") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if step == 5 { finish() } else { changeStep(1) }
                    }.accessibilityIdentifier("onboardingNext").disabled(!valid).opacity(valid ? 1 : 0.4)
                    if step == 0 {
                        QuietButton(title: "Jeg har allerede en sikkerhedskopi") { importingBackup = true }.accessibilityIdentifier("restoreFromWelcome")
                    }
                    Text(step == 0 ? "Ingen konto. Ingen løftede pegefingre." : step == 2 && !valid ? "Angiv 1–100 poser og en pris på 1–1.000 kr." : "Din kladde gemmes automatisk på telefonen.")
                        .font(.system(size: 11)).foregroundStyle(Ink.muted).multilineTextAlignment(.center)
                }.padding(.horizontal, 28).padding(.top, 10).padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $importingBackup) { DataManagementView() }
        .onAppear {
            guard !restored else { return }
            if let saved = store.readDraft() {
                step = saved.step; motivation = saved.motivation
                input.daily = saved.daily; input.tin = saved.tin; input.price = saved.price
                triggers = saved.triggers; startMode = saved.startMode; quitDate = saved.quitDate; firstAction = saved.firstAction ?? ""
            }
            restored = true
        }
        .onChange(of: step) { _, value in
            if value == 5 && firstAction.isEmpty { firstAction = triggers.first?.suggestion ?? Trigger.routine.suggestion }
        }
        .onChange(of: draft) { _, newValue in if restored { store.saveDraft(newValue) } }
    }

    @ViewBuilder private var content: some View {
        switch step {
        case 0:
            Color.clear.frame(height: 115).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 15) {
                Eyebrow(text: "Din næste begyndelse")
                Text("Fylder snus\n\(Text("lidt for meget?").foregroundStyle(Ink.mint))")
                    .scaledTitle(38).tracking(-1.3).fixedSize(horizontal: false, vertical: true)
                Text("Få mere plads til dig selv.\nOg lad pengene blive hos dig.")
                    .font(Ink.body(.title3)).foregroundStyle(Ink.muted).lineSpacing(5)
            }
            VStack(alignment: .leading, spacing: 15) {
                introLine("En plan, der passer til din hverdag.", symbol: "pencil.line")
                introLine("Se dine sparede kroner vokse.", symbol: "banknote")
                introLine("Hjælp, når trangen dukker op.", symbol: "hand.raised")
            }
        case 1:
            PageHeading(eyebrow: "Det starter med dit hvorfor", title: "Hvad vil du\nhave mere af?", subtitle: "Vælg det, der betyder mest for dig lige nu.")
            VStack(spacing: 12) {
                ForEach(Motivation.allCases) { item in
                    ChoiceRow(title: item.rawValue, detail: item.detail, symbol: item.symbol, selected: motivation == item) { motivation = item }
                }
            }
            Text("Det er din grund. Den er god nok.").font(Ink.hand(20)).padding(.top, 5)
        case 2:
            PageHeading(eyebrow: "Lad os regne på det", title: "Hvad går der\npå en dag?", subtitle: "Tænk på en typisk dag før dit stop. Ret tallene, så de passer til dig.")
            ConsumptionFields(input: $input)
            if let value = input.value {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Danish.money(value.monthlyKr)) kr.").scaledTitle(30).contentTransition(.numericText())
                    Spacer()
                    Text("på 30 dage").font(Ink.body(.subheadline))
                }.padding(.top, 6)
            }
        case 3:
            PageHeading(eyebrow: "Vi kender de svære øjeblikke", title: "Hvornår kalder\ndåsen på dig?", subtitle: "Vælg én eller flere. Vi bruger dem i din plan.")
            VStack(spacing: 10) {
                ForEach(Trigger.allCases) { trigger in
                    ChoiceRow(title: trigger.rawValue, selected: triggers.contains(trigger)) {
                        if triggers.contains(trigger) { triggers.removeAll { $0 == trigger } } else { triggers.append(trigger) }
                    }
                }
            }
        case 4:
            PageHeading(eyebrow: "Din start", title: "Hvornår tager\ndu første skridt?", subtitle: "Er du allerede stoppet, tæller vi fra dit sidste nikotinindtag fra snus eller poser.")
            VStack(spacing: 10) {
                ChoiceRow(title: "Jeg stopper nu", detail: "Start med det næste øjeblik.", selected: startMode == 0) { startMode = 0 }
                ChoiceRow(title: "Jeg er allerede stoppet", detail: "Tag dine fremskridt med.", selected: startMode == 1) { startMode = 1; quitDate = min(quitDate, Date()) }
                ChoiceRow(title: "Jeg vælger en stopdato", detail: "Gør plads til din start.", selected: startMode == 2) { startMode = 2; quitDate = max(quitDate, Date()) }
            }
            if startMode == 1 {
                DatePicker("Sidste pose", selection: $quitDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.compact)
            } else if startMode == 2 {
                DatePicker("Min stopdato", selection: $quitDate, in: Date()...Date().addingTimeInterval(30 * 86400), displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.compact)
            }
        default:
            PageHeading(eyebrow: "Din plan er klar", title: "Mere plads\ntil \(motivation == .money ? "det gode" : "dig").", subtitle: "Din grund: \(motivation.rawValue.lowercased()).")
            if let c = input.value {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(Danish.money(c.monthlyKr)) kr.").scaledTitle(52).tracking(-2)
                    Text("kan blive hos dig på 30 dage").font(Ink.body(.subheadline))
                }
            }
            NotePanel {
                Eyebrow(text: "Dit første lille skridt")
                Text(triggers.first?.rawValue ?? "Når trangen kommer").font(Ink.body(.subheadline))
                TextField(triggers.first?.suggestion ?? Trigger.routine.suggestion, text: $firstAction, axis: .vertical)
                    .lineLimit(2...5).font(Ink.body(.body)).accessibilityIdentifier("firstCopingAction")
                Text("Ret forslaget, hvis noget andet passer dig bedre. Højst \(Journey.Limits.generalAction) tegn.").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
            }
            HStack(spacing: 12) {
                Image(systemName: "calendar").font(Ink.body(.title2))
                VStack(alignment: .leading, spacing: 3) {
                    Text(startMode == 0 ? "Du starter i dag" : "Din start: \(Danish.date(quitDate))").font(Ink.body(.headline))
                    Text("Ét øjeblik ad gangen.").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                }
            }
            Text("Vi er med dig. Også på de svære dage.").font(Ink.hand(22))
        }
    }
    private func introLine(_ title: String, symbol: String) -> some View {
        HStack(spacing: 12) { Image(systemName: symbol).frame(width: 23); Text(title).font(.system(.subheadline, design: .default).weight(.medium)) }
    }
    private func changeStep(_ delta: Int) { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { step += delta } }
    private func finish() {
        guard let c = input.value else { return }
        let start = startMode == 0 ? Date() : quitDate
        var journey = Journey(quitDate: start, motivation: motivation, triggers: triggers, consumption: c)
        let chosenAction = firstAction.trimmingCharacters(in: .whitespacesAndNewlines)
        if !chosenAction.isEmpty { journey.copingAction = chosenAction }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { _ = store.commit(journey) }
    }
}
