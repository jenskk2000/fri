import SwiftUI

struct CheckInView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var existing: DailyCheckIn? = nil
    @State private var energy = 3
    @State private var craving = 2
    @State private var note = ""
    @State private var entryDate = Date()
    private let cravingLabels = ["Ingen", "Lidt", "Noget", "Meget", "Stærk"]
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: existing == nil ? "Dit daglige tjek ind" : "Ret dit tjek ind")
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        PageHeading(eyebrow: "Plads til hele din dag", title: "Hvordan\nhar du det?", subtitle: "Et lille øjeblik til at mærke efter. Der er ingen rigtige svar.")
                        ratings("Dit overskud", value: $energy, range: 1...5, labels: ["Lavt", "Lidt", "Okay", "Godt", "Højt"])
                        ratings("Din trang til snus", value: $craving, range: 0...4, labels: cravingLabels)
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Hvad vil du huske? (valgfrit)").font(Ink.body(.headline))
                            TextField("En sejr, et svært øjeblik eller noget, der hjalp …", text: $note, axis: .vertical)
                                .lineLimit(3...6).padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 14))
                                .accessibilityIdentifier("checkInNote")
                            Text("\(note.count) / 500 tegn · kun på din telefon").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                        }
                        PrimaryButton(title: "Gem mit tjek ind", symbol: "checkmark") {
                            let old = existing ?? store.journey?.checkIn(on: entryDate)
                            let date = old?.date ?? entryDate
                            let entry = DailyCheckIn(id: old?.id ?? UUID(), date: date, dayKey: old?.dayKey ?? DailyCheckIn.key(for: date), energy: energy, craving: craving, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
                            if store.saveCheckIn(entry) { dismiss() }
                        }.disabled(note.count > 500).accessibilityIdentifier("saveCheckIn")
                        Text("Dine vurderinger beskriver din oplevelse. De er ikke en måling af din sundhed.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                    }.padding(26)
                }.scrollDismissesKeyboard(.interactively)
            }
        }.onAppear {
            if let entry = existing ?? store.journey?.checkIn(on: entryDate) { energy = entry.energy; craving = entry.craving; note = entry.note }
        }
    }
    private func ratings(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, labels: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(Ink.body(.headline))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 7) { ForEach(Array(range), id: \.self) { i in rating(i, label: labels[i - range.lowerBound], value: value) } }
                VStack(spacing: 7) { ForEach(Array(range), id: \.self) { i in rating(i, label: labels[i - range.lowerBound], value: value) } }
            }
        }
    }
    private func rating(_ i: Int, label: String, value: Binding<Int>) -> some View {
        Button { value.wrappedValue = i } label: {
            VStack(spacing: 5) { Text("\(i)").font(Ink.body(.title3, weight: .bold)); Text(label).font(Ink.body(.caption)) }
                .padding(.vertical, 12).frame(minWidth: 48, maxWidth: .infinity)
                .foregroundStyle(value.wrappedValue == i ? Ink.background : Ink.text)
                .background(value.wrappedValue == i ? Ink.mint : Ink.surface, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityLabel("\(label), \(i)")
            .accessibilityAddTraits(value.wrappedValue == i ? [.isSelected] : [])
    }
}
