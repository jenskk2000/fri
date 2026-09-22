import SwiftUI

struct PlanEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var motivation = Motivation.freedom
    @State private var triggers: [Trigger] = []
    @State private var action = ""
    @State private var actions: [Trigger: String] = [:]
    @State private var quitDate = Date()
    @State private var originalDate = Date()
    @State private var confirmDate = false
    private var corrected: Journey? {
        guard var j = store.journey, j.correctQuitDate(to: quitDate) else { return nil }
        return j
    }
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Ret din plan")
                ScrollView {
                    VStack(alignment: .leading, spacing: 23) {
                        PageHeading(eyebrow: "Din hverdag, din retning", title: "En plan, der\nkan følge med.", subtitle: "Du kan ændre din grund og dine svære øjeblikke, når du vil.")
                        ForEach(Motivation.allCases) { item in
                            ChoiceRow(title: item.rawValue, symbol: item.symbol, selected: motivation == item) { motivation = item }
                        }
                        Eyebrow(text: "Dine svære øjeblikke")
                        ForEach(Trigger.allCases) { trigger in
                            ChoiceRow(title: trigger.rawValue, selected: triggers.contains(trigger)) {
                                if triggers.contains(trigger) { triggers.removeAll { $0 == trigger } } else { triggers.append(trigger) }
                            }
                        }
                        Text("Mit næste lille skridt").font(Ink.body(.headline))
                        TextField("Hvad vil du gøre, når trangen kommer?", text: $action, axis: .vertical).lineLimit(2...5)
                            .padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 12)).accessibilityIdentifier("copingAction")
                        Text("Bruges, når du ikke har valgt en særlig handling til situationen. Højst 250 tegn.").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                        ForEach(triggers) { trigger in
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow(text: trigger.rawValue)
                                TextField("Brug mit næste lille skridt", text: Binding(get: { actions[trigger] ?? "" }, set: { actions[trigger] = $0 }), axis: .vertical)
                                    .lineLimit(2...4).padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 12))
                                    .accessibilityIdentifier("action-\(trigger.id)")
                                Text("Valgfri handling til netop dette øjeblik.").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                            }
                        }
                        Divider()
                        Text("Ret min stopdato").font(Ink.body(.headline))
                        DatePicker("Sidste pose / planlagt start", selection: $quitDate, in: Date(timeIntervalSince1970: 0)...Date().addingTimeInterval(365 * 86400), displayedComponents: [.date, .hourAndMinute])
                        Text("Brug datoen for dit oprindelige stop. En pose undervejs skal registreres med ‘Jeg tog en pose’. Så bevarer du din historik.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        if quitDate != originalDate {
                            if let preview = corrected {
                                NotePanel {
                                    Text("Sparebeløb med den nye dato").font(Ink.body(.subheadline))
                                    Text("\(Danish.money(preview.savingsKr(at: Date()), decimals: 2)) kr.").font(Ink.body(.title2, weight: .bold))
                                    Text("Datoændringen beregner hele dit forløb igen. Senere prisændringer og registrerede poser bevares.").font(Ink.body(.footnote))
                                }
                            } else {
                                Text("Stopdatoen skal ligge før dine registrerede poser. Fortryd eventuelle fejlregistreringer i dagbogen først.").font(Ink.body(.footnote)).foregroundStyle(.red)
                            }
                        }
                        PrimaryButton(title: "Gem min plan", symbol: "checkmark") {
                            if quitDate != originalDate { confirmDate = true } else { save() }
                        }.disabled(triggers.isEmpty || action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || action.count > 250 || actions.values.contains(where: { $0.count > 250 }) || corrected == nil).accessibilityIdentifier("savePlan")
                    }.padding(26)
                }.scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            if let j = store.journey { motivation = j.motivation; triggers = j.triggers; action = j.copingAction; actions = Dictionary(uniqueKeysWithValues: j.personalPlans.map { ($0.trigger, $0.action) }); quitDate = j.quitDate; originalDate = j.quitDate }
        }
        .confirmationDialog("Gem stopdatoen og genberegn forløbet?", isPresented: $confirmDate, titleVisibility: .visible) {
            Button("Gem dato og plan") { save() }
            Button("Annuller", role: .cancel) {}
        } message: { Text("Dine besparelser og stimer beregnes med den nye startdato. Registreringerne i dagbogen bevares.") }
    }
    private func save() {
        guard var next = corrected else { return }
        next.motivation = motivation; next.triggers = triggers
        next.copingAction = action.trimmingCharacters(in: .whitespacesAndNewlines)
        next.copingPlans = triggers.compactMap { trigger in
            let text = (actions[trigger] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : CopingPlan(trigger: trigger, action: text)
        }
        if store.commit(next) { store.notice = "Din plan er opdateret."; dismiss() }
    }
}
