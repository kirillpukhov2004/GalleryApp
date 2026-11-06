import Foundation

enum PhotoPaging {
    /// The assignment requires 30 photos per request.
    static let pageSize = 30
}

protocol PhotoFetching: Sendable {
    func fetchPhotos(page: Int, perPage: Int) async throws -> PhotoPage
}

extension PhotoFetching {
    func fetchPhotos(page: Int) async throws -> PhotoPage {
        try await fetchPhotos(page: page, perPage: PhotoPaging.pageSize)
    }
}
