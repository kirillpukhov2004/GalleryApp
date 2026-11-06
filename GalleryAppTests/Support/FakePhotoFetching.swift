import Foundation
@testable import GalleryApp

actor FakePhotoFetching: PhotoFetching {
    private var pages: [Int: Result<PhotoPage, Error>] = [:]
    private(set) var requestedPages: [Int] = []

    func stub(page: Int, result: Result<PhotoPage, Error>) {
        pages[page] = result
    }

    func fetchPhotos(page: Int, perPage: Int) async throws -> PhotoPage {
        requestedPages.append(page)

        guard let result = pages[page] else {
            throw APIError.transport
        }

        return try result.get()
    }
}
