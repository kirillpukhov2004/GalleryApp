import Foundation

/// One page of photos plus whether another page is likely to exist.
struct PhotoPage: Equatable, Sendable {
    let photos: [Photo]
    let hasMore: Bool
}
