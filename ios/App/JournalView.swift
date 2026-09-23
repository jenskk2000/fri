import SwiftUI

private enum JournalFilter: String, CaseIterable { case all = "Alle", reflections = "Tjek ind", pouches = "Poser", pauses = "Pauser" }
private enum JournalEditor: Identifiable {
    case checkIn(DailyCheckIn), lapse(Lapse), win(CravingWin)
    var id: UUID { switch self { case .checkIn(let item): item.id; case .lapse(let item): item.id; case .win(let item): item.id } }
}
private enum JournalPayload {
    case checkIn(DailyCheckIn), lapse(Lapse), win(CravingWin)
}
private struct JournalItem: Identifiable {
    let id: String
    let date: Date
    let title: String
    let detail: String
    let symbol: String
    let filter: JournalFilter
    let payload: JournalPayload
    var isLapse: Bool { if case .lapse = payload { true } else { false } }
}

struct JournalView: View {
    @Environment(AppStore.self) private var store
    @State private var filter = JournalFilter.all
    @State private var query = ""
    @State private var editor: JournalEditor?
    @State private var removal: JournalItem?
    private var items: [JournalItem] {
        guard let j = store.journey else { return [] }
        let notes = j.reflections.map { JournalItem(id: "c-\($0.id)", date: $0.date, title: "Dit tjek ind", detail: "Overskud \($0.energy)/5 · trang \($0.craving)/4\n\($0.note)", symbol: "pencil", filter: .reflections, payload: .checkIn($0)) }
        let pouches = j.lapses.map { JournalItem(id: "l-\($0.id)", date: $0.date, title: "\($0.count) \($0.count == 1 ? "pose" : "poser") · \($0.trigger)", detail: "− \(Danish.money(Double($0.count) * $0.unitCostOre / 100, decimals: 2)) kr. i dit estimat", symbol: "arrow.uturn.forward", filter: .pouches, payload: .lapse($0)) }
        let pauses = j.wins.map { JournalItem(id: "w-\($0.id)", date: $0.date, title: "Du kom videre fra trangen", detail: [$0.trigger, $0.action].compactMap { $0 }.joined(separator: " · "), symbol: "checkmark", filter: .pauses, payload: .win($0)) }
        return (notes + pouches + pauses).filter { (filter == .all || $0.filter == filter) && (query.isEmpty || "\($0.title) \($0.detail)".localizedCaseInsensitiveContains(query)) }.sorted { $0.date > $1.date }
    }
    var body: some View {
        let displayedItems = items
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Historik og rettelser")
                VStack(spacing: 14) {
                    Picker("Vis", selection: $filter) { ForEach(JournalFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                    HStack { Image(systemName: "magnifyingglass"); TextField("Søg i din dagbog", text: $query).accessibilityIdentifier("journalSearch") }
                        .padding(13).background(Ink.surface, in: RoundedRectangle(cornerRadius: 12))
                }.padding(.horizontal, 26).padding(.vertical, 18)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if displayedItems.isEmpty { ContentUnavailableView(query.isEmpty ? "Her begynder din historie" : "Ingen noter fundet", systemImage: "book.closed", description: Text(query.isEmpty ? "Dine tjek ind, pauser og registrerede poser samles her." : "Prøv et andet ord eller filter.")) }
                        ForEach(displayedItems) { item in
                            VStack(alignment: .leading, spacing: 9) {
                                Label(item.title, systemImage: item.symbol).font(Ink.body(.headline))
                                Text(item.date.formatted(.dateTime.day().month(.wide).year().hour().minute().locale(Locale(identifier: "da_DK")))).font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                                Text(item.detail.trimmingCharacters(in: .whitespacesAndNewlines)).font(Ink.body(.subheadline)).fixedSize(horizontal: false, vertical: true)
                                HStack {
                                    switch item.payload {
                                    case .checkIn(let checkIn):
                                        Button("Ret") { editor = .checkIn(checkIn) }.frame(minHeight: 44)
                                    case .lapse(let lapse):
                                        Button("Ret") { editor = .lapse(lapse) }.frame(minHeight: 44).accessibilityIdentifier("editLapse-\(lapse.id)")
                                    case .win(let win):
                                        Button("Ret") { editor = .win(win) }.frame(minHeight: 44).accessibilityIdentifier("editWin-\(win.id)")
                                    }
                                    Spacer()
                                    Button(item.isLapse ? "Fortryd registrering" : "Slet") { removal = item }.frame(minHeight: 44)
                                }.font(Ink.body(.subheadline, weight: .bold))
                                Divider()
                            }
                        }
                    }.padding(.horizontal, 26).padding(.bottom, 30)
                }.scrollDismissesKeyboard(.interactively)
            }
        }
        .sheet(item: $editor) { item in
            switch item {
            case .checkIn(let entry): CheckInView(existing: entry)
            case .lapse(let entry): LapseView(existing: entry)
            case .win(let entry): WinFeedbackView(existing: entry)
            }
        }
        .confirmationDialog(removal?.isLapse == true ? "Fortryd disse poser?" : "Slet denne note?", isPresented: Binding(get: { removal != nil }, set: { if !$0 { removal = nil } }), titleVisibility: .visible) {
            Button("Ja, fjern registreringen", role: .destructive) {
                guard let item = removal else { return }
                switch item.payload {
                case .checkIn(let checkIn):
                    _ = store.deleteCheckIn(checkIn.id)
                case .lapse(let lapse):
                    store.undoLapse(lapse.id)
                case .win(let win):
                    _ = store.deleteWin(win.id)
                }
                removal = nil
            }
            Button("Behold", role: .cancel) { removal = nil }
        } message: { Text(removal?.isLapse == true ? "Sparebeløb og stime beregnes igen uden disse poser." : "Denne note bliver fjernet fra din dagbog.") }
    }
}

struct MilestonesView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Dine milepæle")
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        PageHeading(eyebrow: "Hver indsats tæller", title: "Det har du\nallerede vist.", subtitle: "Milepæle bygger på tiden mellem dine registrerede poser, ikke på bekræftede dage. En senere pose tager ikke din tidligere indsats fra dig.")
                        if let j = store.journey {
                            let best = j.longestStreakDays(at: Date())
                            ForEach(Milestone.all) { milestone in
                                HStack(spacing: 16) {
                                    Image(systemName: best >= milestone.days ? "checkmark.seal.fill" : "circle.dashed").font(.title).frame(width: 36)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(milestone.title).font(Ink.body(.headline))
                                        Text("\(milestone.days) \(milestone.days == 1 ? "døgn" : "dage") mellem registrerede poser").font(Ink.body(.subheadline)).foregroundStyle(Ink.muted)
                                    }
                                    Spacer()
                                }.padding(.vertical, 10).opacity(best >= milestone.days ? 1 : 0.6)
                                    .accessibilityElement(children: .combine).accessibilityValue(best >= milestone.days ? "Nået" : "Ikke nået endnu")
                                Divider()
                            }
                        }
                    }.padding(26)
                }
            }
        }
    }
}
