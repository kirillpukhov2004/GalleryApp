import Foundation

/// Typed failures shared by the networking and data layers.
///
/// The presentation layer maps these once to user-facing text, so raw transport or
/// decoding errors never reach the UI.
enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case transport
    case invalidResponse
    case unauthorized
    case rateLimited
    case http(statusCode: Int)
    case decoding
    case cancelled
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The request address is invalid."
        case .transport:
            "The network request failed. Check your connection and try again."
        case .invalidResponse:
            "The server returned an unexpected response."
        case .unauthorized:
            "The Unsplash access key is missing or invalid."
        case .rateLimited:
            "The Unsplash rate limit has been reached. Try again later."
        case .http(let statusCode):
            "The server responded with status \(statusCode)."
        case .decoding:
            "The response could not be read."
        case .cancelled:
            "The request was cancelled."
        }
    }
}
