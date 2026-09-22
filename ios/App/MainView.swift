import SwiftUI

enum AppTab: String, CaseIterable {
    case today = "I dag", plan = "Min plan", progress = "Fremskridt"
    var symbol: String { switch self { case .today: "house.fill"; case .plan: "note.text"; case .progress: "chart.bar.xaxis" } }
}

struct MainView: View {
    @Environment(AppStore.self) private var store
    @State private var tab = AppTab.today
    @State private var sheet: SheetRoute?
    var body: some View {
        AppScreen(photograph: tab == .today) {
            VStack(spacing: 0) {
                BrandHeader { sheet = .settings }
                Group {
                    switch tab {
                    case .today: HomeView(sheet: $sheet)
                    case .plan: PlanView(sheet: $sheet)
                    case .progress: ProgressScreen(sheet: $sheet)
                    }
                }.id(tab).frame(maxWidth: .infinity, maxHeight: .infinity)
                if let notice = store.notice {
                    HStack {
                        Text(notice).font(.system(size: 12, weight: .medium))
                        Spacer()
                        Button { store.notice = nil } label: { Image(systemName: "xmark").frame(width: 32, height: 32) }.accessibilityLabel("Luk besked")
                    }.padding(.horizontal, 24).background(Ink.text.opacity(0.07))
                }
                navigation
            }
        }
        .sheet(item: $sheet) { item in
            switch item {
            case .craving: CravingView()
            case .lapse: LapseView()
            case .settings: SettingsView()
            case .savings: SavingsDetailView()
            case .widget: WidgetGuideView()
            case .journal: JournalView()
            case .milestones: MilestonesView()
            case .editPlan: PlanEditorView()
            case .reminder: ReminderView()
            case .data: DataManagementView()
            case .privacy: PrivacyHelpView()
            }
        }
        .onOpenURL { url in
            guard url.scheme == "fri" else { return }
            switch url.host {
            case "craving": sheet = .craving
            case "checkin": sheet = .journal
            case "progress": tab = .progress
            default: break
            }
        }
    }
    private var navigation: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Ink.text.opacity(0.16)).frame(height: 1)
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { item in
                    Button {
                        tab = item
                        store.notice = nil
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: item.symbol).font(.system(size: 22, weight: tab == item ? .semibold : .regular))
                            Text(item.rawValue).font(.system(.caption2, design: .default).weight(tab == item ? .bold : .medium))
                        }.frame(maxWidth: .infinity).padding(.top, 15).padding(.bottom, 8)
                            .foregroundStyle(tab == item ? Ink.mint : Ink.muted)
                    }.buttonStyle(.plain).accessibilityIdentifier("tab-\(item.rawValue)").accessibilityAddTraits(tab == item ? [.isSelected] : [])
                }
            }
        }.background(Ink.background).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Binding var sheet: SheetRoute?
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        GeometryReader { proxy in
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let journey = store.journey {
                    let now = context.date
                    let planned = journey.quitDate > now
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer(minLength: typeSize.isAccessibilitySize ? 24 : max(70, proxy.size.height * 0.17))
                            VStack(alignment: .leading, spacing: 11) {
                                Text("DIN FRIHED, DAG FOR DAG").font(Ink.body(.caption, weight: .semibold)).tracking(2)
                                (Text(planned ? "Din nye" : journey.motivation.homeTitle) + Text("\n" + (planned ? "begyndelse." : journey.motivation.homeAccent)).foregroundColor(Ink.mint))
                                    .scaledTitle(43).tracking(-1.5).fixedSize(horizontal: false, vertical: true)
                            }.padding(.bottom, 25)
                            Button { sheet = .savings } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Eyebrow(text: "Anslået sparet")
                                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                                        Text(Danish.money(journey.savingsKr(at: now), decimals: 2)).font(Ink.title(57)).tracking(-2).monospacedDigit()
                                        Text("kr.").font(Ink.title(27))
                                    }.lineLimit(1).minimumScaleFactor(0.35)
                                    Text("\(Danish.money(journey.consumption(at: now).dailyCostOre / 100)) kr. pr. døgn ud fra dit tidligere forbrug.")
                                        .font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("savingsCounter")
                                .accessibilityLabel("Anslået sparet \(Danish.money(journey.savingsKr(at: now), decimals: 2)) kroner. Se beregning.")
                            HStack(spacing: 9) {
                                Image(systemName: "calendar").foregroundStyle(Ink.mint)
                                Text(streakLabel(journey, at: now)).font(Ink.body(.subheadline, weight: .medium))
                            }.padding(.horizontal, 16).padding(.vertical, 12)
                                .overlay(Capsule().strokeBorder(Ink.text.opacity(0.4))).padding(.top, 19)
                                .accessibilityElement(children: .combine)
                            Text(planned ? "Du bestemmer tempoet." : "Siden sidste registrerede pose")
                                .font(Ink.body(.caption)).foregroundStyle(Ink.muted).padding(.top, 8)
                            if journey.motivation == .money {
                                Text("Dit mål: \(journey.goalName) · \(Danish.money(Double(journey.goalOre) / 100)) kr.")
                                    .font(Ink.body(.subheadline)).padding(.top, 12)
                            }
                            Spacer(minLength: 24)
                            VStack(spacing: 3) {
                                PrimaryButton(title: journey.pauseEndsAt == nil ? "Jeg har lyst lige nu" : "Fortsæt min pause") { sheet = .craving }.accessibilityIdentifier("cravingHelp")
                                if !planned { QuietButton(title: "Jeg tog en pose") { sheet = .lapse }.accessibilityIdentifier("logLapse") }
                                else { QuietButton(title: "Se min forberedelse") { sheet = .craving } }
                            }
                        }.padding(.horizontal, 26).padding(.bottom, 6).frame(minHeight: proxy.size.height, alignment: .bottomLeading)
                    }.scrollIndicators(.hidden)
                }
            }
        }
    }
    private func streakLabel(_ journey: Journey, at now: Date) -> String {
        if journey.quitDate > now { return "Din start: \(Danish.date(journey.quitDate))" }
        return Danish.duration(from: journey.streakStart(at: now), to: now)
    }
}

struct PlanView: View {
    @Environment(AppStore.self) private var store
    @Binding var sheet: SheetRoute?
    var body: some View {
        ScrollView {
            if let journey = store.journey {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "Din grund", title: journey.motivation.rawValue + ".", subtitle: journey.motivation.detail)
                    Button { sheet = .editPlan } label: {
                        Label("Ret min plan", systemImage: "slider.horizontal.3").font(Ink.body(.headline)).frame(minHeight: 44)
                    }.accessibilityIdentifier("editPlan")
                    NotePanel {
                        Eyebrow(text: "Mit næste lille skridt")
                        Text(journey.copingAction).font(Ink.body(.title3, weight: .semibold))
                        let sharedTriggers = journey.triggers.filter { trigger in !journey.personalPlans.contains { $0.trigger == trigger } }
                        if !sharedTriggers.isEmpty {
                            Text(sharedTriggers.map(\.rawValue).joined(separator: " · "))
                                .font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        }
                    }
                    ForEach(journey.personalPlans.filter { journey.triggers.contains($0.trigger) }) { plan in
                        NotePanel {
                            Eyebrow(text: plan.trigger.rawValue)
                            Text(plan.action).font(Ink.body(.body))
                        }
                    }
                    PrimaryButton(title: "Brug min plan nu") { sheet = .craving }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Din stopdato").font(Ink.body(.headline))
                        Text(Danish.fullDate(journey.quitDate)).font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                    }
                    Button { sheet = .reminder } label: {
                        Label("Min påmindelse", systemImage: "bell").font(Ink.body(.headline)).frame(minHeight: 44)
                    }.accessibilityIdentifier("reminderSettings")
                    Button { sheet = .widget } label: {
                        Label("Mine kroner på låseskærmen", systemImage: "iphone").font(Ink.body(.headline)).frame(minHeight: 44)
                    }.accessibilityIdentifier("widgetGuide")
                    Link("Hjælp hos Stoplinien ↗", destination: URL(string: "https://stoplinien.dk")!).font(Ink.body(.subheadline)).frame(minHeight: 44)
                }.padding(26)
            }
        }.scrollIndicators(.hidden)
    }
}

struct ProgressScreen: View {
    @Environment(AppStore.self) private var store
    @Binding var sheet: SheetRoute?
    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            ScrollView {
                if let j = store.journey {
                    let now = context.date
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeading(eyebrow: "Dit overblik", title: "Det går fremad.", subtitle: "Din start: \(Danish.fullDate(j.quitDate)).")
                        NotePanel {
                            Eyebrow(text: "Siden sidste registrerede pose")
                            Text(Danish.duration(from: j.streakStart(at: now), to: now)).font(Ink.title(28)).accessibilityIdentifier("elapsedTime")
                            Text("Tiden følger dine registreringer. Dage uden en registrering er ikke automatisk bekræftet uden snus.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        }
                        Button { sheet = .savings } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(Danish.money(j.savingsKr(at: now), decimals: 2)) kr.").font(Ink.title(42)).lineLimit(1).minimumScaleFactor(0.4)
                                Text("Anslået sparet · se beregning").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)
                        DayHistoryView(journey: j, now: now)
                        if let lapse = j.lapses.sorted(by: { $0.date > $1.date }).first {
                            NotePanel {
                                Text("Senest registreret: \(lapse.count) \(lapse.count == 1 ? "pose" : "poser")").font(Ink.body(.headline))
                                Text(Danish.fullDate(lapse.date)).font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                                Button("Fortryd") { store.undoLapse(lapse.id) }.frame(minHeight: 44)
                            }
                        }
                        Button { sheet = .journal } label: {
                            Label("Historik og rettelser", systemImage: "clock.arrow.circlepath").font(Ink.body(.headline)).frame(minHeight: 48)
                        }.accessibilityIdentifier("openJournal")
                        NotePanel {
                            Eyebrow(text: "Dit opsparingsmål")
                            Text(j.goalName).font(Ink.body(.title3, weight: .semibold))
                            ProgressView(value: min(1, j.savingsKr(at: now) * 100 / Double(j.goalOre))).tint(Ink.mint)
                            Text("\(Danish.money(j.savingsKr(at: now))) af \(Danish.money(Double(j.goalOre) / 100)) kr.").font(Ink.body(.subheadline))
                            Button("Ret mit mål") { sheet = .settings }.font(Ink.body(.subheadline)).frame(minHeight: 44)
                        }
                        Text("\(j.wins.count) \(j.wins.count == 1 ? "pause" : "pauser") registreret. Din tidligere indsats bliver hos dig.").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                        Button("Tidligere milepæle") { sheet = .milestones }.font(Ink.body(.subheadline)).frame(minHeight: 44)
                    }.padding(26)
                }
            }.scrollIndicators(.hidden)
        }
    }
}
