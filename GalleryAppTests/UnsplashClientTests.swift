import XCTest
@testable import GalleryApp

final class UnsplashClientTests: XCTestCase {
    private let accessKey = "test-access-key"

    override func tearDown() {
        URLProtocolStub.stub(nil)
        super.tearDown()
    }

    func testFetchPhotosSendsAuthenticatedPaginatedRequest() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: Data("[]".utf8)))

        _ = try await makeSUT().fetchPhotos(page: 2, perPage: 30)

        let request = try XCTUnwrap(URLProtocolStub.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Client-ID test-access-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Version"), "v1")

        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/photos")

        let queryItems = components.queryItems ?? []
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "page", value: "2")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "per_page", value: "30")))
    }

    func testFetchPhotosDecodesPhotoPage() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: try fixtureData("photos_page")))

        let page = try await makeSUT().fetchPhotos(page: 1, perPage: 2)

        XCTAssertEqual(page.photos.count, 2)
        XCTAssertTrue(page.hasMore)

        let first = try XCTUnwrap(page.photos.first)
        XCTAssertEqual(first.id, "LBI7cgq3pbM")
        XCTAssertEqual(first.title, "man in black crew neck t-shirt drinking coffee")
        XCTAssertEqual(first.descriptionText, "A man drinking a coffee.")
        XCTAssertEqual(
            first.thumbnailURL,
            URL(string: "https://images.unsplash.com/photo-1?ixid=abc&w=400")
        )
        XCTAssertEqual(
            first.regularURL,
            URL(string: "https://images.unsplash.com/photo-1?ixid=abc&w=1080")
        )
        XCTAssertEqual(first.photographerName, "Gilbert Kane")
        XCTAssertEqual(
            first.photographerProfileURL,
            URL(string: "https://unsplash.com/@poorkane")
        )

        let second = try XCTUnwrap(page.photos.last)
        XCTAssertEqual(second.title, "sunset over the sea")
        XCTAssertNil(second.descriptionText)
        XCTAssertEqual(second.photographerName, "Unknown photographer")
    }

    func testFetchPhotosUsesAltDescriptionAsTitle() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: try fixtureData("photos_page")))

        let page = try await makeSUT().fetchPhotos(page: 1, perPage: 2)
        let first = try XCTUnwrap(page.photos.first)

        XCTAssertEqual(first.title, "man in black crew neck t-shirt drinking coffee")
        XCTAssertEqual(first.descriptionText, "A man drinking a coffee.")
    }

    func testFetchPhotosHidesDescriptionWhenItMatchesTitle() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: try fixtureData("photos_text")))

        let page = try await makeSUT().fetchPhotos(page: 1, perPage: 2)
        let duplicate = try XCTUnwrap(page.photos.first)

        XCTAssertEqual(duplicate.title, "Same caption")
        XCTAssertNil(duplicate.descriptionText)
    }

    func testFetchPhotosFallsBackToDescriptionWhenAltIsMissing() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: try fixtureData("photos_text")))

        let page = try await makeSUT().fetchPhotos(page: 1, perPage: 2)
        let fallback = try XCTUnwrap(page.photos.last)

        XCTAssertEqual(fallback.title, "Only a long description")
        XCTAssertNil(fallback.descriptionText)
    }

    func testFetchPhotosReportsNoMorePagesWhenResponseIsShort() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: try fixtureData("photos_page")))

        let page = try await makeSUT().fetchPhotos(page: 1, perPage: 3)

        XCTAssertEqual(page.photos.count, 2)
        XCTAssertFalse(page.hasMore)
    }

    func testFetchPhotosReportsNoMorePagesForEmptyResponse() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: Data("[]".utf8)))

        let page = try await makeSUT().fetchPhotos(page: 5, perPage: 30)

        XCTAssertTrue(page.photos.isEmpty)
        XCTAssertFalse(page.hasMore)
    }

    func testFetchPhotosMapsMalformedPayloadToDecodingError() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: Data("not json".utf8)))
        let sut = makeSUT()

        await assertAPIError(.decoding) {
            _ = try await sut.fetchPhotos(page: 1, perPage: 30)
        }
    }

    func testFetchPhotosPropagatesUnauthorizedError() async throws {
        URLProtocolStub.stub(.success(statusCode: 401, data: Data()))
        let sut = makeSUT()

        await assertAPIError(.unauthorized) {
            _ = try await sut.fetchPhotos(page: 1, perPage: 30)
        }
    }

    func testFetchPhotosRejectsInvalidPaginationWithoutSendingRequest() async {
        let sut = makeSUT()

        await assertAPIError(.invalidURL) {
            _ = try await sut.fetchPhotos(page: 0, perPage: 30)
        }
        await assertAPIError(.invalidURL) {
            _ = try await sut.fetchPhotos(page: 1, perPage: 0)
        }
        await assertAPIError(.invalidURL) {
            _ = try await sut.fetchPhotos(page: 1, perPage: PhotoPaging.pageSize + 1)
        }

        XCTAssertTrue(URLProtocolStub.requests.isEmpty)
    }

    private func makeSUT() -> UnsplashClient {
        UnsplashClient(
            httpClient: URLSessionHTTPClient(session: URLProtocolStub.makeSession()),
            accessKey: accessKey
        )
    }

    private func fixtureData(_ name: String) throws -> Data {
        let bundle = Bundle(for: UnsplashClientTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private func assertAPIError(
        _ expected: APIError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? APIError, expected, file: file, line: line)
        }
    }
}
