import XCTest
@testable import GalleryApp

@MainActor
final class GalleryViewModelTests: XCTestCase {
    func testLoadInitialPublishesFirstPage() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["a", "b"], hasMore: true)))
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadInitial()

        XCTAssertEqual(sut.state.photos.map(\.id), ["a", "b"])
        XCTAssertTrue(sut.state.hasMore)
        XCTAssertFalse(sut.state.isLoadingInitial)
        XCTAssertNil(sut.state.errorMessage)
    }

    func testLoadInitialRequestsFirstPageOnlyOnce() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["a"], hasMore: true)))
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadInitial()
        await sut.loadInitial()

        let requestedPages = await fetcher.requestedPages
        XCTAssertEqual(requestedPages, [1])
    }

    func testLoadMoreAppendsNextPage() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["a", "b"], hasMore: true)))
        await fetcher.stub(page: 2, result: .success(try makePage(ids: ["c"], hasMore: false)))
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadInitial()
        await sut.loadMore()

        XCTAssertEqual(sut.state.photos.map(\.id), ["a", "b", "c"])
        XCTAssertFalse(sut.state.hasMore)
        XCTAssertFalse(sut.state.isLoadingMore)

        let requestedPages = await fetcher.requestedPages
        XCTAssertEqual(requestedPages, [1, 2])
    }

    func testLoadMoreStopsWhenNoMorePages() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["a"], hasMore: false)))
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadInitial()
        await sut.loadMore()

        let requestedPages = await fetcher.requestedPages
        XCTAssertEqual(requestedPages, [1])
    }

    func testLoadMoreDoesNothingBeforeInitialLoad() async {
        let fetcher = FakePhotoFetching()
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadMore()

        let requestedPages = await fetcher.requestedPages
        XCTAssertTrue(requestedPages.isEmpty)
    }

    func testLoadMoreSkipsDuplicatePhotos() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["a", "b"], hasMore: true)))
        await fetcher.stub(page: 2, result: .success(try makePage(ids: ["b", "c"], hasMore: false)))
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadInitial()
        await sut.loadMore()

        XCTAssertEqual(sut.state.photos.map(\.id), ["a", "b", "c"])
    }

    func testFailureSetsErrorMessage() async {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .failure(APIError.unauthorized))
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadInitial()

        XCTAssertTrue(sut.state.photos.isEmpty)
        XCTAssertEqual(
            sut.state.errorMessage,
            "The Unsplash access key is missing or invalid."
        )
        XCTAssertFalse(sut.state.isLoadingInitial)
    }

    func testRetryRecoversAfterFailure() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .failure(APIError.transport))
        let sut = makeSUT(fetcher: fetcher)
        await sut.loadInitial()

        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["a"], hasMore: false)))
        await sut.retry()

        XCTAssertEqual(sut.state.photos.map(\.id), ["a"])
        XCTAssertNil(sut.state.errorMessage)
    }

    func testRefreshReplacesPhotosAndResetsPagination() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["a", "b"], hasMore: true)))
        await fetcher.stub(page: 2, result: .success(try makePage(ids: ["c"], hasMore: false)))
        let sut = makeSUT(fetcher: fetcher)

        await sut.loadInitial()
        await sut.loadMore()

        await fetcher.stub(page: 1, result: .success(try makePage(ids: ["d"], hasMore: true)))
        await sut.refresh()

        XCTAssertEqual(sut.state.photos.map(\.id), ["d"])

        await sut.loadMore()

        XCTAssertEqual(sut.state.photos.map(\.id), ["d", "c"])
    }

    func testPublishesFavouriteIDsFromRepository() {
        let repository = FakeFavouritesRepository()
        let sut = makeSUT(fetcher: FakePhotoFetching(), repository: repository)

        repository.sendFavouriteIDs(["a", "b"])

        XCTAssertEqual(sut.state.favouriteIDs, ["a", "b"])
    }

    private func makeSUT(
        fetcher: FakePhotoFetching,
        repository: FakeFavouritesRepository = FakeFavouritesRepository()
    ) -> GalleryViewModel {
        GalleryViewModel(photoFetching: fetcher, favouritesRepository: repository)
    }

    private func makePage(ids: [String], hasMore: Bool) throws -> PhotoPage {
        let photos = try makePhotos(ids: ids)
        return PhotoPage(photos: photos, hasMore: hasMore)
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
