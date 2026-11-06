import XCTest
@testable import GalleryApp

@MainActor
final class DetailViewModelTests: XCTestCase {
    func testClampsNegativeStartIndexToFirstPhoto() throws {
        let sut = try makeSUT(startIndex: -3)

        XCTAssertEqual(sut.state.currentIndex, 0)
        XCTAssertEqual(sut.currentPhoto?.id, "a")
    }

    func testClampsStartIndexPastEndToLastPhoto() throws {
        let sut = try makeSUT(startIndex: 99)

        XCTAssertEqual(sut.state.currentIndex, 2)
        XCTAssertEqual(sut.currentPhoto?.id, "c")
    }

    func testCurrentPhotoMatchesStartIndex() throws {
        let sut = try makeSUT(startIndex: 1)

        XCTAssertEqual(sut.currentPhoto?.id, "b")
        XCTAssertEqual(sut.photoCount, 3)
    }

    func testSetCurrentIndexUpdatesPhoto() throws {
        let sut = try makeSUT()

        sut.setCurrentIndex(2)

        XCTAssertEqual(sut.state.currentIndex, 2)
        XCTAssertEqual(sut.currentPhoto?.id, "c")
    }

    func testIgnoresOutOfRangeIndex() throws {
        let sut = try makeSUT()

        sut.setCurrentIndex(10)

        XCTAssertEqual(sut.state.currentIndex, 0)
    }

    func testFavouriteStateFollowsRepository() throws {
        let repository = FakeFavouritesRepository()
        let sut = try makeSUT(repository: repository)

        repository.sendFavouriteIDs(["a"])
        XCTAssertTrue(sut.state.isFavourite)

        repository.sendFavouriteIDs([])
        XCTAssertFalse(sut.state.isFavourite)
    }

    func testFavouriteStateUpdatesWhenSwiping() throws {
        let repository = FakeFavouritesRepository()
        let sut = try makeSUT(repository: repository)
        repository.sendFavouriteIDs(["b"])

        XCTAssertFalse(sut.state.isFavourite)

        sut.setCurrentIndex(1)

        XCTAssertTrue(sut.state.isFavourite)
    }

    func testToggleSendsCurrentPhotoToRepository() async throws {
        let repository = FakeFavouritesRepository()
        let sut = try makeSUT(startIndex: 1, repository: repository)

        await sut.toggleFavourite()

        XCTAssertEqual(repository.toggledPhotos.map(\.id), ["b"])
        XCTAssertFalse(sut.state.isUpdatingFavourite)
    }

    func testToggleFailureSetsErrorMessage() async throws {
        let repository = FakeFavouritesRepository()
        repository.toggleError = APIError.transport
        let sut = try makeSUT(repository: repository)

        await sut.toggleFavourite()

        XCTAssertEqual(
            sut.state.errorMessage,
            "The network request failed. Check your connection and try again."
        )
        XCTAssertFalse(sut.state.isUpdatingFavourite)
    }

    private func makeSUT(
        startIndex: Int = 0,
        repository: FakeFavouritesRepository = FakeFavouritesRepository()
    ) throws -> DetailViewModel {
        DetailViewModel(
            photos: try makePhotos(),
            startIndex: startIndex,
            favouritesRepository: repository
        )
    }

    private func makePhotos() throws -> [Photo] {
        try ["a", "b", "c"].map { id in
            Photo(
                id: id,
                title: "Title \(id)",
                descriptionText: "Description \(id)",
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
