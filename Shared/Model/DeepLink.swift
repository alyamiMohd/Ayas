import Foundation

/// Links the widget uses to open the app on the right habit.
enum DeepLink {
    static let scheme = "ayas"

    static var rootURL: URL {
        URL(string: "\(scheme)://today") ?? URL(fileURLWithPath: "/")
    }

    static func habitURL(_ id: UUID) -> URL {
        URL(string: "\(scheme)://habit/\(id.uuidString)") ?? URL(fileURLWithPath: "/")
    }

    static func habitID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == "habit" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
