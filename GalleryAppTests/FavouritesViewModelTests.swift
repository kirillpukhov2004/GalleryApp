import XCTest
@testable import GalleryApp

@MainActor
final class FavouritesViewModelTests: XCTestCase {
    func testPublishesExistingFavourites() throws {
        let photos = try makePhotos(ids: ["a", "b"])
        let repository = FakeFavouritesRepository(favourites: photos)

        let sut = FavouritesViewModel(repository: repository)

        XCTAssertEqual(sut.state.photos.map(\.id), ["a", "b"])
    }

    func testUpdatesWhenRepositoryEmits() throws {
        let repository = FakeFavouritesRepository()
        let sut = FavouritesViewModel(repository: repository)

        repository.sendFavourites(try makePhotos(ids: ["a"]))

        XCTAssertEqual(sut.state.photos.map(\.id), ["a"])
    }

    func testRemoveCallsRepositoryWithSelectedPhoto() async throws {
        let photos = try makePhotos(ids: ["a", "b"])
        let repository = FakeFavouritesRepository(favourites: photos)
        let sut = FavouritesViewModel(repository: repository)

        await sut.remove(at: 1)

        XCTAssertEqual(repository.removedPhotoIDs, ["b"])
    }

    func testRemoveIgnoresOutOfRangeIndex() async throws {
        let repository = FakeFavouritesRepository(favourites: try makePhotos(ids: ["a"]))
        let sut = FavouritesViewModel(repository: repository)

        await sut.remove(at: 5)

        XCTAssertTrue(repository.removedPhotoIDs.isEmpty)
    }

    func testRemoveFailureSetsErrorMessage() async throws {
        let repository = FakeFavouritesRepository(favourites: try makePhotos(ids: ["a"]))
        repository.removeError = APIError.transport
        let sut = FavouritesViewModel(repository: repository)

        await sut.remove(at: 0)

        XCTAssertEqual(
            sut.state.errorMessage,
            "The network request failed. Check your connection and try again."
        )
    }

    func testClearErrorRemovesMessage() async throws {
        let repository = FakeFavouritesRepository(favourites: try makePhotos(ids: ["a"]))
        repository.removeError = APIError.transport
        let sut = FavouritesViewModel(repository: repository)
        await sut.remove(at: 0)

        sut.clearError()

        XCTAssertNil(sut.state.errorMessage)
    }

    func testStartsEmptyWhenRepositoryHasNoFavourites() {
        let sut = FavouritesViewModel(repository: FakeFavouritesRepository())

        XCTAssertTrue(sut.state.photos.isEmpty)
    }

    private func makePhotos(ids: [String]) throws -> [Photo] {
        try ids.map { id in
            Photo(
                id: id,
                title: "Title \(id)",
                descriptionText: nil,
                thumbnailURL: try XCTUnwrap(URL(string: "https://example.com/\(id)-thumb.jpg")),
                regularURL: try XCTUnwrap(URL(string: "https://example.com/\(id)-regular.jpg")),
                photographerName: "Photographer",
                photographerProfileURL: nil,
                width: 100,
                height: 100
            )
        }
    }
}
