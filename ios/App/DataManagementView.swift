import SwiftUI
import UniformTypeIdentifiers

struct JourneyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(journey: Journey) throws { data = try JSONEncoder().encode(journey) }
    init(configuration: ReadConfiguration) throws {
        guard let bytes = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        _ = try JourneyArchive.decode(bytes); data = bytes
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct DataManagementView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var importing = false
    @State private var exporting = false
    @State private var document: JourneyDocument?
    @State private var candidate: Journey?
    @State private var message = ""
    @State private var confirmRestore = false
    @State private var usingBackup = false
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Dine data")
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        PageHeading(eyebrow: "Du bestemmer", title: "Din historie.\nHos dig.", subtitle: "Gem en kopi, eller flyt din plan til en anden iPhone. FRI har ingen konto og ingen automatisk synkronisering.")
                        if let j = store.journey {
                            PrimaryButton(title: "Gem en sikkerhedskopi", symbol: "square.and.arrow.up") {
                                do { document = try JourneyDocument(journey: j); exporting = true }
                                catch { message = "Kopien kunne ikke oprettes." }
                            }.accessibilityIdentifier("exportBackup")
                        }
                        PrimaryButton(title: "Indlæs en sikkerhedskopi", symbol: "square.and.arrow.down") { importing = true }.accessibilityIdentifier("importBackup")
                        Text("Kopien indeholder din plan, forbrug, noter og registreringer. Vælg selv, hvor du gemmer den. Del den kun med nogen, du ønsker skal se dine oplysninger.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        if (try? store.archive.loadBackup()) != nil {
                            Button("Gendan seneste lokale kopi") {
                                do { candidate = try store.archive.loadBackup(); usingBackup = true }
                                catch { message = "Den lokale kopi kunne ikke læses." }
                            }.frame(minHeight: 44).font(Ink.body(.headline)).accessibilityIdentifier("recoverBackup")
                            Text("FRI beholder den forrige gemte version på telefonen. Det er ikke en ekstern sikkerhedskopi.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        }
                        if let preview = candidate {
                            NotePanel {
                                Eyebrow(text: usingBackup ? "Seneste lokale kopi" : "Klar til gennemsyn")
                                Text("Start: \(Danish.date(preview.quitDate))").font(Ink.body(.headline))
                                Text("\(preview.lapses.count) poseregistreringer · \(preview.reflections.count) tjek ind · \(preview.wins.count) pauser").font(Ink.body(.subheadline))
                                Text("\(Danish.money(preview.savingsKr(at: Date()), decimals: 2)) kr. anslået sparet").font(Ink.body(.headline))
                                Text("Denne plan erstatter den nuværende. Der flettes ikke. Din nuværende version bevares som lokal kopi. Påmindelser aktiveres ikke af import.").font(Ink.body(.footnote))
                                PrimaryButton(title: "Brug denne kopi", symbol: "checkmark") { confirmRestore = true }.accessibilityIdentifier("confirmImport")
                                Button("Annuller import") { candidate = nil }.frame(minHeight: 44)
                            }
                        }
                        if !message.isEmpty { Text(message).font(Ink.body(.subheadline)).accessibilityIdentifier("dataMessage") }
                    }.padding(26)
                }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
                candidate = try JourneyArchive.decode(bytes); usingBackup = false; message = ""
            } catch { candidate = nil; message = "Filen kunne ikke indlæses. Vælg en gyldig FRI-kopi på højst 20 MB. Dine nuværende data er ikke ændret." }
        }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "FRI-sikkerhedskopi") { result in
            switch result { case .success: message = "Din kopi er gemt."; case .failure: message = "Kopien blev ikke gemt. Prøv igen." }
        }
        .confirmationDialog("Erstat din nuværende plan?", isPresented: $confirmRestore, titleVisibility: .visible) {
            Button("Gendan denne plan") {
                if let next = candidate, store.restore(next) { dismiss() }
            }
            Button("Annuller", role: .cancel) {}
        } message: { Text("Der importeres præcis den plan, du har gennemset. Dine nuværende data bevares som den lokale kopi.") }
    }
}

struct PrivacyHelpView: View {
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                SheetHeader(title: "Om FRI og dit privatliv")
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeading(eyebrow: "Fri for lidt mere", title: "Ingen konto.\nBare din plan.", subtitle: "FRI er gratis. Der er ingen reklamer, abonnementer eller analyseværktøjer i appen.")
                        section("Hvor ligger mine oplysninger?", "Din plan, dit forbrug og dine noter ligger på din iPhone, i et beskyttet område delt med din FRI-widget. Vi sender dem ikke til en server. iPhones egen sikkerhedskopiering kan omfatte appdata afhængigt af dine Apple-indstillinger.")
                        section("Hvad deler jeg?", "Kun det, du selv vælger at eksportere. En sikkerhedskopi indeholder din historik og dine noter. FRI gemmer også den forrige lokale version, så du kan gendanne efter en fejl.")
                        section("Kan jeg slette det hele?", "Ja. Nederst i Indstillinger kan du slette planen, historikken, den lokale kopi og påmindelsen. Kopier, du selv har eksporteret, skal du selv slette dér, hvor du gemte dem.")
                        section("Hvad betyder snus her?", "Vi bruger hverdagens ord ‘snus’ om både snus og nikotinposer. Tælleren handler om de poser, du har valgt at stoppe med. Den måler ikke dit samlede nikotinindtag fra andre produkter.")
                        section("Hvorfor er beløbet anslået?", "Vi beregner det forbrug, du ville have haft, ud fra dine egne tal. Hele dåser, tilbud og udgifter til nikotinerstatning indgår ikke. Tryk på sparebeløbet for at se regnestykket.")
                        section("Har jeg brug for mere støtte?", "FRI hjælper med overblik og vaner. Appen erstatter ikke personlig rådgivning og lover ikke bestemte helbredseffekter. Stoplinien tilbyder gratis rådgivning om nikotinstop, også for snus og nikotinposer.")
                        Link("Stoplinien · hjælp til dit stop ↗", destination: URL(string: "https://stoplinien.dk")!).font(Ink.body(.headline)).frame(minHeight: 44)
                        Link("Ring 80 31 31 31", destination: URL(string: "tel:80313131")!).font(Ink.body(.headline)).frame(minHeight: 44)
                        Text("Eksterne links åbner uden for FRI. Den pågældende tjenestes privatlivspolitik gælder dér.").font(Ink.body(.footnote)).foregroundStyle(Ink.muted)
                        Text("FRI 1.0 · Privatlivstekst opdateret 22. september 2026").font(Ink.body(.caption)).foregroundStyle(Ink.muted)
                    }.padding(26)
                }
            }
        }
    }
    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 9) { Text(title).font(Ink.body(.headline)); Text(text).font(Ink.body(.subheadline)).foregroundStyle(Ink.muted).lineSpacing(4) }
    }
}
