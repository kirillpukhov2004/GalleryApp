import Foundation

/// Wire format of the Unsplash `List Photos` response. Decoded only in the data layer.
struct UnsplashPhotoDTO: Decodable, Sendable {
    let id: String
    let description: String?
    let altDescription: String?
    let width: Int?
    let height: Int?
    let urls: UnsplashPhotoURLsDTO
    let user: UnsplashUserDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case altDescription = "alt_description"
        case width
        case height
        case urls
        case user
    }
}

struct UnsplashPhotoURLsDTO: Decodable, Sendable {
    let small: String
    let regular: String
}

struct UnsplashUserDTO: Decodable, Sendable {
    let name: String?
    let username: String?
    let links: UnsplashUserLinksDTO?
}

struct UnsplashUserLinksDTO: Decodable, Sendable {
    let html: String?
}
