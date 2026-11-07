import Foundation

/// Unsplash `List Photos` client using public (access-key) authentication.
///
/// The access key is sent as `Authorization: Client-ID <key>`. No user OAuth flow is
/// involved because the app only reads public data.
struct UnsplashClient: PhotoFetching {
    private static let baseURLString = "https://api.unsplash.com"

    private let httpClient: any HTTPClient
    private let accessKey: String

    init(httpClient: any HTTPClient, accessKey: String) {
        self.httpClient = httpClient
        self.accessKey = accessKey
    }

    func fetchPhotos(page: Int, perPage: Int) async throws -> PhotoPage {
        let request = try makeRequest(page: page, perPage: perPage)
        let (data, _) = try await httpClient.data(for: request)

        let photos = try decodePhotos(from: data)
        return PhotoPage(
            photos: photos,
            hasMore: !photos.isEmpty && photos.count == perPage
        )
    }

    private func makeRequest(page: Int, perPage: Int) throws -> URLRequest {
        guard page >= 1, (1...PhotoPaging.pageSize).contains(perPage) else {
            throw APIError.invalidURL
        }

        guard var components = URLComponents(string: "\(Self.baseURLString)/photos") else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func decodePhotos(from data: Data) throws -> [Photo] {
        let dtos: [UnsplashPhotoDTO]
        do {
            dtos = try JSONDecoder().decode([UnsplashPhotoDTO].self, from: data)
        } catch {
            throw APIError.decoding
        }

        do {
            return try dtos.map { try $0.toDomain() }
        } catch {
            throw APIError.decoding
        }
    }
}

private extension UnsplashPhotoDTO {
    func toDomain() throws -> Photo {
        guard let thumbnailURL = URL(string: urls.small),
              let regularURL = URL(string: urls.regular) else {
            throw APIError.decoding
        }

        let trimmedAltDescription = altDescription?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let title = [trimmedAltDescription, trimmedDescription]
            .compactMap { $0 }
            .first { !$0.isEmpty } ?? "Untitled"

        let descriptionText: String? = {
            guard let trimmedDescription,
                  !trimmedDescription.isEmpty,
                  trimmedDescription != title else {
                return nil
            }
            return trimmedDescription
        }()

        return Photo(
            id: id,
            title: title,
            descriptionText: descriptionText,
            thumbnailURL: thumbnailURL,
            regularURL: regularURL,
            photographerName: user?.name ?? user?.username ?? "Unknown photographer",
            photographerProfileURL: user?.links?.html.flatMap { URL(string: $0) },
            width: width ?? 0,
            height: height ?? 0
        )
    }
}
