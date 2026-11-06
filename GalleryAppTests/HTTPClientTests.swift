import XCTest
@testable import GalleryApp

final class HTTPClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.stub(nil)
        super.tearDown()
    }

    func testDataReturnsBodyForSuccessfulResponse() async throws {
        let payload = Data("payload".utf8)
        URLProtocolStub.stub(.success(statusCode: 200, data: payload))
        let sut = makeSUT()

        let (data, response) = try await sut.data(for: makeRequest())

        XCTAssertEqual(data, payload)
        XCTAssertEqual(response.statusCode, 200)
    }

    func testMapsUnauthorizedStatus() async throws {
        URLProtocolStub.stub(.success(statusCode: 401, data: Data()))
        let sut = makeSUT()

        await assertAPIError(.unauthorized) {
            _ = try await sut.data(for: makeRequest())
        }
    }

    func testMapsRateLimitedStatus() async throws {
        URLProtocolStub.stub(.success(statusCode: 429, data: Data()))
        let sut = makeSUT()

        await assertAPIError(.rateLimited) {
            _ = try await sut.data(for: makeRequest())
        }
    }

    func testMapsServerErrorStatus() async throws {
        URLProtocolStub.stub(.success(statusCode: 503, data: Data()))
        let sut = makeSUT()

        await assertAPIError(.http(statusCode: 503)) {
            _ = try await sut.data(for: makeRequest())
        }
    }

    func testMapsTransportFailure() async throws {
        URLProtocolStub.stub(.failure(URLError(.notConnectedToInternet)))
        let sut = makeSUT()

        await assertAPIError(.transport) {
            _ = try await sut.data(for: makeRequest())
        }
    }

    func testMapsCancellation() async throws {
        URLProtocolStub.stub(.failure(URLError(.cancelled)))
        let sut = makeSUT()

        await assertAPIError(.cancelled) {
            _ = try await sut.data(for: makeRequest())
        }
    }

    private func makeSUT() -> URLSessionHTTPClient {
        URLSessionHTTPClient(session: URLProtocolStub.makeSession())
    }

    private func makeRequest() throws -> URLRequest {
        let url = try XCTUnwrap(URL(string: "https://api.unsplash.com/photos"))
        return URLRequest(url: url)
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
