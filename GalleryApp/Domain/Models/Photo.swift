import Foundation

/// A photo as the rest of the app understands it.
///
/// Holds only metadata and remote URLs: image bytes are never persisted.
struct Photo: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let descriptionText: String?
    let thumbnailURL: URL
    let regularURL: URL
    let photographerName: String
    let photographerProfileURL: URL?
    let width: Int
    let height: Int
}
