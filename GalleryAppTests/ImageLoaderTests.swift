import XCTest
@testable import GalleryApp

@MainActor
final class ImageLoaderTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.stub(nil)
        super.tearDown()
    }

    func testLoadsAndDownsamplesImage() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: makePNG(size: CGSize(width: 200, height: 100))))
        let sut = makeSUT()

        let image = try await sut.image(for: makeURL(), maxPixelSize: 40)

        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 40.5)
    }

    func testServesSecondRequestFromCache() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: makePNG(size: CGSize(width: 100, height: 100))))
        let sut = makeSUT()
        let url = try makeURL()

        _ = try await sut.image(for: url, maxPixelSize: 40)
        _ = try await sut.image(for: url, maxPixelSize: 40)

        XCTAssertEqual(URLProtocolStub.requests.count, 1)
    }

    func testDeduplicatesConcurrentRequests() async throws {
        URLProtocolStub.stub(
            .success(
                statusCode: 200,
                data: makePNG(size: CGSize(width: 100, height: 100)),
                delay: 0.1
            )
        )
        let sut = makeSUT()
        let url = try makeURL()

        async let first = sut.image(for: url, maxPixelSize: 40)
        async let second = sut.image(for: url, maxPixelSize: 40)
        _ = try await (first, second)

        XCTAssertEqual(URLProtocolStub.requests.count, 1)
    }

    func testMapsServerErrorToInvalidResponse() async throws {
        URLProtocolStub.stub(.success(statusCode: 500, data: Data()))
        let sut = makeSUT()

        await assertAPIError(.invalidResponse) {
            _ = try await sut.image(for: self.makeURL(), maxPixelSize: 40)
        }
    }

    func testMapsUnreadableDataToDecodingError() async throws {
        URLProtocolStub.stub(.success(statusCode: 200, data: Data("not an image".utf8)))
        let sut = makeSUT()

        await assertAPIError(.decoding) {
            _ = try await sut.image(for: self.makeURL(), maxPixelSize: 40)
        }
    }

    func testCancelLoadingCancelsPendingRequest() async throws {
        URLProtocolStub.stub(
            .success(
                statusCode: 200,
                data: makePNG(size: CGSize(width: 100, height: 100)),
                delay: 0.3
            )
        )
        let sut = makeSUT()
        let url = try makeURL()

        let task = Task { try await sut.image(for: url, maxPixelSize: 40) }
        try await Task.sleep(nanoseconds: 50_000_000)
        sut.cancelLoading(for: url)

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertEqual(error as? APIError, .cancelled)
        }
    }

    private func makeSUT() -> ImageLoader {
        ImageLoader(session: URLProtocolStub.makeSession())
    }

    private func makeURL() throws -> URL {
        try XCTUnwrap(URL(string: "https://images.unsplash.com/photo-1?w=400"))
    }

    private func makePNG(size: CGSize) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.pngData { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
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
