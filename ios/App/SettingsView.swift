import SwiftUI
import UserNotifications

enum AppInfo {
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0" }
}

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var input = ConsumptionInput()
    @State private var goalName = ""
    @State private var goalAmount = "1000"
    @State private var confirmReset = false
    @State private var subSheet: SheetRoute?
    private var goalOre: Int? {
        guard let amount = Double(goalAmount.replacingOccurrences(of: ",", with: ".")), amount.isFinite, amount >= 1, amount <= 1000000 else { return nil }
        return Int((amount * 100).rounded())
    }
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Indstillinger")
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        PageHeading(eyebrow: "Din hverdag ændrer sig", title: "Gør planen\ntil din.", subtitle: "Nye forbrugstal gælder fra nu. Din historik bliver bevaret.")
                        AppearancePicker()
                        Divider()
                        ConsumptionFields(input: $input, exactPrice: true)
                        VStack(alignment: .leading, spacing: 14) {
                            Eyebrow(text: "Noget at glæde dig til")
                            TextField("Hvad sparer du op til?", text: $goalName).textInputAutocapitalization(.sentences).accessibilityIdentifier("goalName")
                                .padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 12))
                            HStack { TextField("Beløb", text: $goalAmount).keyboardType(.decimalPad).accessibilityIdentifier("goalAmount"); Text("kr.") }.padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        PrimaryButton(title: "Gem ændringer", symbol: "checkmark") {
                            guard let c = input.value, let goal = goalOre else { return }
                            if store.saveSettings(consumption: c, goalOre: goal, goalName: goalName) { dismiss() }
                        }.disabled(input.value == nil || goalOre == nil || goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveSettings")
                        Divider()
                        Toggle("Diskret widget", isOn: Binding(get: { store.journey?.discreetWidget ?? false }, set: { value in _ = store.setDiscreetWidget(value) }))
                            .font(Ink.body(.headline)).tint(Ink.mint).accessibilityIdentifier("discreetWidget")
                        Text("Vis kun kroner på låseskærmen. Ordet snus og din stime skjules.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        Button { subSheet = .editPlan } label: { Label("Ret min stopdato og plan", systemImage: "pencil").font(Ink.body(.headline)).frame(minHeight: 44) }.accessibilityIdentifier("editPlan")
                        Button { subSheet = .reminder } label: { Label("Min daglige påmindelse", systemImage: "bell").font(Ink.body(.headline)).frame(minHeight: 44) }.accessibilityIdentifier("reminderSettings")
                        Button { subSheet = .data } label: { Label("Sikkerhedskopi og gendannelse", systemImage: "externaldrive").font(Ink.body(.headline)).frame(minHeight: 44) }.accessibilityIdentifier("dataSettings")
                        Button { subSheet = .privacy } label: { Label("Privatliv og hjælp", systemImage: "hand.raised").font(Ink.body(.headline)).frame(minHeight: 44) }.accessibilityIdentifier("privacyHelp")
                        Button("Slet mine data og start forfra", role: .destructive) { confirmReset = true }.font(Ink.body(.subheadline)).frame(minHeight: 44).padding(.top, 15)
                        Text("FRI · Version \(AppInfo.version)\nLavet til en friere hverdag.").font(Ink.body(.caption)).foregroundStyle(Ink.muted).padding(.bottom, 10)
                    }.padding(26)
                }.scrollDismissesKeyboard(.interactively).scrollIndicators(.hidden)
            }
        }
        .sheet(item: $subSheet) { item in
            switch item {
            case .editPlan: PlanEditorView()
            case .reminder: ReminderView()
            case .data: DataManagementView()
            default: PrivacyHelpView()
            }
        }
        .onAppear {
            if let j = store.journey { input = ConsumptionInput(j.consumption(at: Date())); goalName = j.goalName; goalAmount = Danish.money(Double(j.goalOre) / 100, decimals: j.goalOre % 100 == 0 ? 0 : 2).replacingOccurrences(of: ".", with: "") }
        }
        .confirmationDialog("Slet din plan, historik og lokale kopier?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Slet alle mine FRI-data", role: .destructive) { if store.reset() { dismiss() } }
            Button("Behold mine data", role: .cancel) {}
        } message: { Text("Det kan ikke fortrydes. Dine data på denne telefon bliver slettet, og widgetten nulstilles.") }
    }
}

struct WidgetGuideView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Din låseskærm")
                ScrollView {
                    VStack(alignment: .leading, spacing: 27) {
                        PageHeading(eyebrow: "En lille påmindelse om det gode", title: "Dine fremskridt.\nLige ved hånden.", subtitle: "Se dine sparede kroner, hver gang du tager telefonen frem.")
                        if let j = store.journey {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("FRI").font(Ink.body(.caption, weight: .bold))
                                Text("\(Danish.money(j.savingsKr(at: Date()))) kr. anslået sparet").font(Ink.body(.title2, weight: .bold))
                                if !j.discreetWidget { Text("\(j.streakDays(at: Date())) døgn siden registreret pose").font(Ink.body(.subheadline)) }
                            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Ink.text).background(Ink.surface, in: RoundedRectangle(cornerRadius: 24))
                        }
                        Text("FORHÅNDSVISNING").font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(Ink.muted)
                        VStack(alignment: .leading, spacing: 22) {
                            guide("1", "Hold fingeren på låseskærmen.")
                            guide("2", "Vælg Tilpas og derefter Låseskærm.")
                            guide("3", "Tryk på widgetfeltet under uret, og vælg FRI.")
                            guide("4", "Vælg din widget, og tryk Færdig.")
                        }
                        Text("iOS opdaterer widgetten med mellemrum. I appen følger tælleren tiden løbende. Tryk på widgetten for at se dine fremskridt.").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted).lineSpacing(4)
                        Text("Vil du holde det diskret? Slå ‘Diskret widget’ til i Indstillinger.").font(Ink.hand(19))
                    }.padding(26)
                }
            }
        }
    }
    private func guide(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 15) { Text(n).font(Ink.hand(23)).frame(width: 25); Text(text).font(Ink.body(.body)).fixedSize(horizontal: false, vertical: true) }
    }
}
