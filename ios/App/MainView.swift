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
        // The native tab bar provides the floating Liquid Glass bar and its scroll minimisation.
        TabView(selection: $tab) {
            Tab(AppTab.today.rawValue, systemImage: AppTab.today.symbol, value: AppTab.today) {
                page(photograph: true) { HomeView(sheet: $sheet) }
            }
            Tab(AppTab.plan.rawValue, systemImage: AppTab.plan.symbol, value: AppTab.plan) {
                page { PlanView(sheet: $sheet) }
            }
            Tab(AppTab.progress.rawValue, systemImage: AppTab.progress.symbol, value: AppTab.progress) {
                page { ProgressScreen(sheet: $sheet) }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Ink.mint)
        .onChange(of: tab) { store.notice = nil }
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
    private func page<Content: View>(photograph: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        let inner = content()
        return AppScreen(photograph: photograph) {
            VStack(spacing: 0) {
                BrandHeader { sheet = .settings }
                inner.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let notice = store.notice {
                HStack(spacing: 10) {
                    Text(notice).font(Ink.body(.footnote, weight: .medium))
                    Spacer(minLength: 4)
                    Button { store.notice = nil } label: { Image(systemName: "xmark").frame(width: 28, height: 28) }.accessibilityLabel("Luk besked")
                }.glassChip().padding(.horizontal, 16).padding(.bottom, 6).foregroundStyle(Ink.text)
            }
        }
    }
}

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Binding var sheet: SheetRoute?
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        GeometryReader { proxy in
            if let journey = store.journey {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer(minLength: typeSize.isAccessibilitySize ? 16 : max(40, proxy.size.height * 0.12))
                        HomeClock(journey: journey, sheet: $sheet)
                        Spacer(minLength: 26)
                        HomeActions(journey: journey, sheet: $sheet)
                    }.padding(.horizontal, 22).padding(.bottom, 8).frame(minHeight: proxy.size.height, alignment: .bottomLeading)
                }.scrollIndicators(.hidden)
            }
        }
    }
}

/// The home screen's one job: the time since the last recorded pouch, and where it sits in the current phase.
private struct HomeClock: View {
    let journey: Journey
    @Binding var sheet: SheetRoute?
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let planned = journey.quitDate > now
            let reference = planned ? journey.quitDate : journey.streakStart(at: now)
            let clock = ClockParts(seconds: abs(now.timeIntervalSince(reference)))
            VStack(alignment: .leading, spacing: 0) {
                Text(planned ? "Din start nærmer sig." : "Jeg bruger ikke snus.")
                    .font(Ink.body(.headline, weight: .semibold)).foregroundStyle(Ink.text.opacity(0.9))
                Text("\(clock.days)").font(Ink.title(132)).tracking(-5).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.4).padding(.top, 2).padding(.bottom, -12)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(planned ? (clock.days == 1 ? "dag til start" : "dage til start") : (clock.days == 1 ? "dag" : "dage"))
                        .font(Ink.title(30))
                    Text(clock.hms).font(Ink.body(.title2, weight: .semibold)).monospacedDigit().foregroundStyle(Ink.muted)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(planned ? "\(clock.days) dage til din start" : "\(Danish.duration(from: reference, to: now)) siden sidste registrerede pose")
                .accessibilityIdentifier("elapsedTime")

                GlassEffectContainer(spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let phase = journey.phase(at: now) { PhaseBar(phase: phase) }
                        else { Text("Din start: \(Danish.fullDate(journey.quitDate))").font(Ink.body(.subheadline, weight: .semibold)).glassChip() }
                        HStack(spacing: 10) {
                            let saved = Danish.money(journey.savingsKr(at: now), decimals: 2)
                            Button { sheet = .savings } label: {
                                Text("\(saved) kr. sparet").font(Ink.body(.subheadline, weight: .semibold)).monospacedDigit().glassChip()
                            }.buttonStyle(.plain).accessibilityIdentifier("savingsCounter")
                                .accessibilityLabel("Anslået sparet \(saved) kroner. Se beregning.")
                            if journey.phase(at: now)?.stage == .critical {
                                Link(destination: Stoplinien.phone) {
                                    Label("Rådgiver", systemImage: "phone.fill").font(Ink.body(.subheadline, weight: .semibold)).glassChip()
                                }.accessibilityLabel("Ring gratis til Stoplinien")
                            }
                        }
                    }
                }.padding(.top, 22)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ClockParts {
    let days: Int
    let hms: String
    init(seconds: TimeInterval) {
        let total = Int(seconds)
        days = total / 86400
        hms = String(format: "%02d:%02d:%02d", (total % 86400) / 3600, (total % 3600) / 60, total % 60)
    }
}

struct PhaseBar: View {
    let phase: QuitPhase
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(phase.title).font(Ink.body(.footnote, weight: .semibold))
                Spacer()
                Text(phase.daysLeft == 1 ? "1 dag tilbage" : "\(phase.daysLeft) dage tilbage")
                    .font(Ink.body(.footnote, weight: .semibold)).foregroundStyle(Ink.mint).monospacedDigit()
            }
            ProgressView(value: phase.fraction).tint(Ink.mint)
        }.padding(.horizontal, 16).padding(.vertical, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .accessibilityElement(children: .combine)
    }
}

extension QuitPhase {
    var title: String {
        switch targetDays {
        case 14: "De første 14 dage"
        case 30: "Mod 1 måned"
        case 90: "Mod 3 måneder"
        case 180: "Mod 6 måneder"
        default: targetDays == 365 ? "Mod 1 år" : "Mod \(targetDays / 365) år"
        }
    }
}

private struct HomeActions: View {
    let journey: Journey
    @Binding var sheet: SheetRoute?
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let planned = journey.quitDate > context.date
            VStack(spacing: 4) {
                PrimaryButton(title: journey.pauseEndsAt == nil ? "Jeg har lyst lige nu" : "Fortsæt min pause") { sheet = .craving }.accessibilityIdentifier("cravingHelp")
                if !planned { QuietButton(title: "Jeg tog en pose") { sheet = .lapse }.accessibilityIdentifier("logLapse") }
                else { QuietButton(title: "Se min forberedelse") { sheet = .craving } }
            }
        }
    }
}

struct PlanView: View {
    @Environment(AppStore.self) private var store
    @Binding var sheet: SheetRoute?
    var body: some View {
        ScrollView {
            if let journey = store.journey {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "Din grund", title: journey.motivation.rawValue + ".", subtitle: "")
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
                        Label("Widget på låseskærmen", systemImage: "iphone").font(Ink.body(.headline)).frame(minHeight: 44)
                    }.accessibilityIdentifier("widgetGuide")
                    SupportCard()
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
                    let savingsKr = j.savingsKr(at: now)
                    let preciseSavings = Danish.money(savingsKr, decimals: 2)
                    let roundedSavings = Danish.money(savingsKr)
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeading(eyebrow: "Dit overblik", title: "Det går fremad.", subtitle: "")
                        if let phase = j.phase(at: now) { PhaseBar(phase: phase) }
                        NotePanel {
                            Eyebrow(text: "Siden sidste registrerede pose")
                            Text(Danish.duration(from: j.streakStart(at: now), to: now)).font(Ink.title(28))
                            Text("Følger dine registreringer. Start: \(Danish.fullDate(j.quitDate)).").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        }
                        Button { sheet = .savings } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(preciseSavings) kr.").font(Ink.title(42)).lineLimit(1).minimumScaleFactor(0.4)
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
                            ProgressView(value: min(1, savingsKr * 100 / Double(j.goalOre))).tint(Ink.mint)
                            Text("\(roundedSavings) af \(Danish.money(Double(j.goalOre) / 100)) kr.").font(Ink.body(.subheadline))
                            Button("Ret mit mål") { sheet = .settings }.font(Ink.body(.subheadline)).frame(minHeight: 44)
                        }
                        Text("\(j.wins.count) \(j.wins.count == 1 ? "trang" : "trange") klaret").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                        Button("Tidligere milepæle") { sheet = .milestones }.font(Ink.body(.subheadline)).frame(minHeight: 44)
                    }.padding(26)
                }
            }.scrollIndicators(.hidden)
        }
    }
}
