import Foundation

struct OnboardingDraft: Codable, Equatable {
    var step: Int
    var motivation: Motivation
    var daily: String
    var tin: String
    var price: String
    var triggers: [Trigger]
    var startMode: Int
    var quitDate: Date
    var firstAction: String? = nil
    var isValid: Bool {
        (firstAction?.count ?? 0) <= 250 && (0...5).contains(step) && (0...2).contains(startMode) && daily.count <= 12 && tin.count <= 12 && price.count <= 16
        && quitDate.timeIntervalSince1970.isFinite && quitDate > Date(timeIntervalSince1970: 0)
    }
}

extension AppStore {
    var draftURL: URL { archive.url.appendingPathExtension("onboarding") }
    func readDraft() -> OnboardingDraft? {
        guard let data = try? Data(contentsOf: draftURL), let draft = try? JSONDecoder().decode(OnboardingDraft.self, from: data), draft.isValid else { return nil }
        return draft
    }
    func saveDraft(_ draft: OnboardingDraft) {
        guard journey == nil, draft.isValid else { return }
        do {
            try FileManager.default.createDirectory(at: draftURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(draft).write(to: draftURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch { self.error = "Din kladde kunne ikke gemmes. Hold appen åben, og prøv igen." }
    }
    func clearDraft() throws {
        if FileManager.default.fileExists(atPath: draftURL.path) { try FileManager.default.removeItem(at: draftURL) }
    }
}
