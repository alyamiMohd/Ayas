import Foundation

/// Read-only access to the bundled Quran text.
///
/// The text lives in flat UTF-8 files with a companion offset index, so fetching one ayah
/// is a seek and a short read rather than parsing a multi-megabyte document. That matters
/// in the widget extension, which runs under a tight memory limit and only ever needs a
/// single ayah.
///
/// Files (bundled as the `Quran` folder):
///   `surahs.json`     — 114 metadata records
///   `ar.uthmani.txt`  — 6,236 ayahs, one per line
///   `ar.uthmani.idx`  — little-endian UInt32 byte offsets, 6,237 entries
///   `en.sahih.txt` / `en.sahih.idx` — same shape, English translation
///
/// Adding a translation later means dropping in another `.txt`/`.idx` pair and registering
/// it below; nothing else changes.
final class QuranLibrary: @unchecked Sendable {
    static let shared = QuranLibrary()

    static let ayahCount = 6236

    struct Surah: Codable, Hashable, Identifiable, Sendable {
        let number: Int
        /// Arabic name, e.g. "سُورَةُ البَقَرَةِ".
        let name: String
        /// Transliterated name, e.g. "Al-Baqara".
        let latinName: String
        /// Meaning in English, e.g. "The Cow".
        let meaning: String
        /// "meccan" or "medinan".
        let place: String
        let ayahCount: Int

        var id: Int { number }
    }

    let surahs: [Surah]
    /// 1-based global index of each surah's first ayah, parallel to `surahs`.
    private let surahStart: [Int]
    private let arabicEdition: Edition?
    private let englishEdition: Edition?

    private init() {
        let bundle = Bundle.main
        surahs = Self.loadSurahs(from: bundle)
        var running = 1
        var starts: [Int] = []
        starts.reserveCapacity(surahs.count)
        for surah in surahs {
            starts.append(running)
            running += surah.ayahCount
        }
        surahStart = starts
        arabicEdition = Edition(slug: "ar.uthmani", bundle: bundle)
        englishEdition = Edition(slug: "en.sahih", bundle: bundle)
    }

    var isAvailable: Bool { !surahs.isEmpty && arabicEdition != nil }

    // MARK: - Lookup

    /// Wraps around at the end of the Quran so a long-running habit begins again rather
    /// than reaching a dead end.
    static func wrappedIndex(start: Int, step: Int) -> Int {
        let span = ayahCount
        let zeroBased = (start - 1) + step
        let wrapped = ((zeroBased % span) + span) % span
        return wrapped + 1
    }

    func location(ofAyah global: Int) -> (surah: Surah, ayah: Int)? {
        guard global >= 1, global <= Self.ayahCount, !surahs.isEmpty else { return nil }
        var low = 0
        var high = surahs.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if surahStart[mid] <= global {
                low = mid
            } else {
                high = mid - 1
            }
        }
        let surah = surahs[low]
        return (surah, global - surahStart[low] + 1)
    }

    func globalIndex(surah: Int, ayah: Int) -> Int? {
        guard let position = surahs.firstIndex(where: { $0.number == surah }) else { return nil }
        guard ayah >= 1, ayah <= surahs[position].ayahCount else { return nil }
        return surahStart[position] + ayah - 1
    }

    func arabic(at global: Int) -> String? {
        arabicEdition?.line(at: global - 1)
    }

    func translation(at global: Int) -> String? {
        englishEdition?.line(at: global - 1)
    }

    func surah(numbered number: Int) -> Surah? {
        surahs.first { $0.number == number }
    }

    // MARK: - Loading

    private static func loadSurahs(from bundle: Bundle) -> [Surah] {
        guard let url = bundle.url(forResource: "surahs", withExtension: "json", subdirectory: "Quran"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Surah].self, from: data)
        else { return [] }
        return decoded
    }

    /// One text file plus its offset index.
    private final class Edition {
        private let url: URL
        private let offsets: [UInt32]

        init?(slug: String, bundle: Bundle) {
            guard let textURL = bundle.url(forResource: slug, withExtension: "txt", subdirectory: "Quran"),
                  let indexURL = bundle.url(forResource: slug, withExtension: "idx", subdirectory: "Quran"),
                  let indexData = try? Data(contentsOf: indexURL),
                  indexData.count >= 8
            else { return nil }
            url = textURL
            offsets = Edition.decodeOffsets(indexData)
        }

        /// Zero-based line number.
        func line(at index: Int) -> String? {
            guard index >= 0, index + 1 < offsets.count else { return nil }
            let start = Int(offsets[index])
            // The stored span includes the trailing newline; drop it.
            let length = Int(offsets[index + 1]) - start - 1
            guard length > 0 else { return nil }

            guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
            defer { try? handle.close() }
            do {
                try handle.seek(toOffset: UInt64(start))
                guard let data = try handle.read(upToCount: length), data.count == length else { return nil }
                return String(data: data, encoding: .utf8)
            } catch {
                return nil
            }
        }

        /// Explicit little-endian decode, byte by byte, so alignment never matters.
        private static func decodeOffsets(_ data: Data) -> [UInt32] {
            let count = data.count / 4
            var result = [UInt32]()
            result.reserveCapacity(count)
            data.withUnsafeBytes { raw in
                let bytes = raw.bindMemory(to: UInt8.self)
                for slot in 0..<count {
                    let base = slot * 4
                    let value = UInt32(bytes[base])
                        | UInt32(bytes[base + 1]) << 8
                        | UInt32(bytes[base + 2]) << 16
                        | UInt32(bytes[base + 3]) << 24
                    result.append(value)
                }
            }
            return result
        }
    }
}
