import SwiftUI
import WidgetKit

struct FRIEntry: TimelineEntry {
    let date: Date
    let hasJourney: Bool
    let saved: String
    let days: Int
    let planned: Bool
    let discreet: Bool

    init(date: Date, journey: Journey?) {
        self.date = date
        hasJourney = journey != nil
        saved = Danish.money(journey?.savingsKr(at: date) ?? 0)
        days = journey?.streakDays(at: date) ?? 0
        planned = (journey?.quitDate ?? .distantPast) > date
        discreet = journey?.discreetWidget ?? false
    }
}

struct FRIProvider: TimelineProvider {
    func placeholder(in context: Context) -> FRIEntry { sample() }
    func getSnapshot(in context: Context, completion: @escaping (FRIEntry) -> Void) {
        completion(context.isPreview ? sample() : FRIEntry(date: Date(), journey: try? JourneyArchive.shared().load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FRIEntry>) -> Void) {
        let journey = try? JourneyArchive.shared().load()
        let now = Date()
        // Precomputed values keep the estimate moving even when the app stays closed.
        let entries = (0..<96).map { FRIEntry(date: now.addingTimeInterval(Double($0) * 900), journey: journey) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
    private func sample() -> FRIEntry {
        let now = Date()
        return FRIEntry(date: now, journey: Journey(quitDate: now.addingTimeInterval(-15 * 86400), motivation: .freedom, triggers: [.coffee], consumption: Consumption()))
    }
}

struct FRIWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FRIEntry
    private let mint = Color(red: 74 / 255, green: 222 / 255, blue: 155 / 255)
    private let charcoal = Color(red: 11 / 255, green: 13 / 255, blue: 18 / 255)
    private var accessory: Bool { family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular }
    var body: some View {
        Group {
            if !entry.hasJourney {
                if family == .accessoryInline { Text("FRI · Åbn FRI for at se din plan") }
                else { VStack(alignment: .leading, spacing: 3) { Text("FRI").font(.headline); Text("Åbn FRI for at se din plan").font(.caption) } }
            } else {
                switch family {
                case .accessoryInline:
                    Text("FRI · \(entry.saved) kr. anslået")
                case .accessoryCircular:
                    VStack(spacing: 0) {
                        Text(entry.saved).font(.system(size: 23, weight: .bold, design: .default)).minimumScaleFactor(0.4).lineLimit(1)
                        Text("kr. anslået").font(.system(size: 9))
                    }.containerBackground(for: .widget) { AccessoryWidgetBackground() }
                case .accessoryRectangular:
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 1).frame(width: 3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.saved) kr. anslået").font(.headline).minimumScaleFactor(0.6).lineLimit(1)
                            if entry.discreet { Text("Mere plads til dig.").font(.caption) }
                            else { Text(entry.planned ? "Din start venter" : "\(entry.days) døgn siden noteret pose").font(.caption) }
                        }
                    }
                default:
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text("FRI").font(.custom("MarkerFelt-Wide", size: 24)).foregroundStyle(mint); Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(mint) }
                        Spacer(minLength: 0)
                        Text("\(entry.saved) kr.").font(.system(size: 32, weight: .heavy, design: .default)).minimumScaleFactor(0.4).lineLimit(1)
                        Text("Anslået sparet").font(.caption)
                        Spacer(minLength: 0)
                        if !entry.discreet { Text(entry.planned ? "Din start venter" : "\(entry.days) døgn siden noteret pose").font(.caption.bold()) }
                    }.foregroundStyle(.white)
                }
            }
        }
        .containerBackground(for: .widget) { accessory ? Color.clear : charcoal }
        .widgetURL(URL(string: "fri://progress"))
    }
}

@main
struct FRIWidgets: Widget {
    let kind = "FRISavings"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FRIProvider()) { entry in FRIWidgetView(entry: entry) }
            .configurationDisplayName("Dine sparede kroner")
            .description("En lille påmindelse om din frihed. Følg dine anslåede besparelser og din stime.")
            .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall])
    }
}
