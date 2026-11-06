import Foundation

/// `URLProtocol` subclass that intercepts requests made by a stubbed `URLSession`,
/// so tests never touch the network.
final class URLProtocolStub: URLProtocol {
    enum Result: Sendable {
        case success(statusCode: Int, data: Data, delay: TimeInterval = 0)
        case failure(URLError)
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var stubbedResult: Result?
    nonisolated(unsafe) private static var capturedRequests: [URLRequest] = []

    static func stub(_ result: Result?) {
        lock.withLock {
            stubbedResult = result
            capturedRequests = []
        }
    }

    static var requests: [URLRequest] {
        lock.withLock { capturedRequests }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let result = Self.currentResult() else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        Self.record(request)

        switch result {
        case .success(let statusCode, let data, let delay):
            if delay > 0 {
                Thread.sleep(forTimeInterval: delay)
            }

            guard let url = request.url,
                  let response = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                  ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)

        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func currentResult() -> Result? {
        lock.withLock { stubbedResult }
    }

    private static func record(_ request: URLRequest) {
        lock.withLock { capturedRequests.append(request) }
    }
}
