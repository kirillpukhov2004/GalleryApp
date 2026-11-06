import Combine

/// Single source of truth for favourite photos across every screen.
///
/// Main-actor isolated because it feeds view models directly and keeps Combine
/// subjects on the main queue.
@MainActor
protocol FavouritesRepositoryProtocol: AnyObject {
    var favourites: AnyPublisher<[Photo], Never> { get }
    var favouritesIDs: AnyPublisher<Set<String>, Never> { get }

    func toggle(_ photo: Photo) async throws
    func remove(photoID: String) async throws
}
