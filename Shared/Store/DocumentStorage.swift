import Foundation

/// Reads and writes the single JSON document that holds all habit state.
///
/// Two processes touch this file — the app and the widget extension — so every access goes
/// through `NSFileCoordinator` and every write is atomic. A half-written document would
/// cost someone their streak history, which is the one thing this app must not lose.
struct DocumentStorage: Sendable {
    static let shared = DocumentStorage()

    static let fileName = "habits.json"

    let fileURL: URL
    /// False when the app group container was unavailable and state fell back to the app's
    /// own sandbox. The app still works; the widget just cannot see it.
    let isShared: Bool

    /// Used by tests to point at a scratch file.
    init(fileURL: URL) {
        self.fileURL = fileURL
        isShared = false
    }

    init() {
        if let container = AppGroup.containerURL {
            fileURL = container.appendingPathComponent(Self.fileName)
            isShared = true
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            fileURL = documents.appendingPathComponent(Self.fileName)
            isShared = false
        }
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return encoder
    }

    func load() -> AyasDocument {
        var result = AyasDocument()
        var coordinationError: NSError?
        NSFileCoordinator(filePresenter: nil).coordinate(
            readingItemAt: fileURL,
            options: [],
            error: &coordinationError
        ) { url in
            guard let data = try? Data(contentsOf: url), !data.isEmpty else { return }
            do {
                result = try JSONDecoder().decode(AyasDocument.self, from: data)
            } catch {
                // Keep the bytes we could not read rather than overwriting them on the
                // next save; a person's history is worth more than a clean directory.
                quarantine(data)
            }
        }
        return result
    }

    func save(_ document: AyasDocument) {
        guard let data = try? encoder.encode(document) else { return }
        var coordinationError: NSError?
        NSFileCoordinator(filePresenter: nil).coordinate(
            writingItemAt: fileURL,
            options: .forReplacing,
            error: &coordinationError
        ) { url in
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: url, options: .atomic)
        }
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    private func quarantine(_ data: Data) {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("habits-unreadable-\(stamp).json")
        try? data.write(to: backup, options: .atomic)
    }
}
