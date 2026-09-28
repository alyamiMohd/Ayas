import Foundation

/// The shared container the app and the widget both write to.
///
/// The identifier is injected into both Info.plists from the `AYAS_APP_GROUP` build
/// setting, so changing it for your own developer account is a one-line edit in the
/// project rather than a hunt through source.
enum AppGroup {
    static let fallbackIdentifier = "group.com.ayas.shared"

    static let identifier: String = {
        let declared = Bundle.main.object(forInfoDictionaryKey: "AyasAppGroup") as? String
        guard let declared, !declared.isEmpty, declared.hasPrefix("group.") else {
            return fallbackIdentifier
        }
        return declared
    }()

    /// Nil when the App Groups entitlement is missing or the identifier does not match the
    /// one provisioned for this build.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
