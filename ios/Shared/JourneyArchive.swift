import Foundation

struct JourneyArchive {
    static let group = "group.dk.fri.shared"
    static let maximumImportBytes = 20 * 1024 * 1024
    let url: URL
    var backupURL: URL { url.appendingPathExtension("previous") }
    var recoveryURL: URL { url.appendingPathExtension("unreadable") }
    static func shared() -> JourneyArchive {
        #if os(iOS)
        let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        #else
        let root = FileManager.default.temporaryDirectory
        #endif
        return JourneyArchive(url: root.appendingPathComponent("fri-journey-v1.json"))
    }
    static func decode(_ data: Data) throws -> Journey {
        guard data.count <= maximumImportBytes else { throw CocoaError(.fileReadTooLarge) }
        var journey = try JSONDecoder().decode(Journey.self, from: data)
        journey.normalizeLegacyPlan()
        guard journey.isValid else { throw CocoaError(.fileReadCorruptFile) }
        return journey
    }
    func load() throws -> Journey? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Self.decode(Data(contentsOf: url))
    }
    func loadBackup() throws -> Journey { try Self.decode(Data(contentsOf: backupURL)) }
    func save(_ journey: Journey) throws {
        guard journey.isValid else { throw CocoaError(.fileWriteUnknown) }
        let data = try JSONEncoder().encode(journey)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let previous = try Data(contentsOf: url)
            _ = try Self.decode(previous) // Never overwrite an unreadable archive through a normal edit.
            try write(previous, to: backupURL)
        }
        try write(data, to: url)
    }
    func restore(_ journey: Journey) throws {
        guard journey.isValid else { throw CocoaError(.fileReadCorruptFile) }
        let data = try JSONEncoder().encode(journey)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let previous = try Data(contentsOf: url)
            // Preserve corrupt bytes for recovery without rotating over the last valid backup.
            try write(previous, to: (try? Self.decode(previous)) == nil ? recoveryURL : backupURL)
        }
        try write(data, to: url)
    }
    private func write(_ data: Data, to destination: URL) throws {
        #if os(iOS)
        try data.write(to: destination, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: destination, options: .atomic)
        #endif
    }
    func delete() throws {
        // Delete ancillary copies first; keep the active journey if cleanup fails.
        for location in [backupURL, recoveryURL, url] where FileManager.default.fileExists(atPath: location.path) {
            try FileManager.default.removeItem(at: location)
        }
    }
}
