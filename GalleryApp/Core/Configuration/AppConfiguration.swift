import Foundation

/// Runtime configuration read from the application's Info.plist.
///
/// The access key is injected at build time from the gitignored `Config.xcconfig`.
/// A missing, blank or unresolved value is treated as a configuration failure so the
/// app can present an actionable message instead of crashing.
struct AppConfiguration: Sendable {
    enum ConfigurationError: Error, Equatable {
        case missingAccessKey
    }

    let accessKey: String

    init(bundle: Bundle = .main) throws {
        try self.init(infoDictionary: bundle.infoDictionary ?? [:])
    }

    init(infoDictionary: [String: Any]) throws {
        guard let rawValue = infoDictionary[Self.accessKeyKey] as? String else {
            throw ConfigurationError.missingAccessKey
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, !trimmedValue.hasPrefix("$(") else {
            throw ConfigurationError.missingAccessKey
        }

        accessKey = trimmedValue
    }

    private static let accessKeyKey = "UNSPLASH_ACCESS_KEY"
}
