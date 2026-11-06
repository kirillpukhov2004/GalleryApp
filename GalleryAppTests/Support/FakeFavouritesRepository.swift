import Combine
@testable import GalleryApp

@MainActor
final class FakeFavouritesRepository: FavouritesRepositoryProtocol {
    private let favouritesSubject: CurrentValueSubject<[Photo], Never>
    private let favouriteIDsSubject: CurrentValueSubject<Set<String>, Never>

    private(set) var toggledPhotos: [Photo] = []
    private(set) var removedPhotoIDs: [String] = []
    var toggleError: Error?
    var removeError: Error?

    init(favourites: [Photo] = []) {
        favouritesSubject = CurrentValueSubject(favourites)
        favouriteIDsSubject = CurrentValueSubject(Set(favourites.map(\.id)))
    }

    var favourites: AnyPublisher<[Photo], Never> {
        favouritesSubject.eraseToAnyPublisher()
    }

    var favouritesIDs: AnyPublisher<Set<String>, Never> {
        favouriteIDsSubject.eraseToAnyPublisher()
    }

    func toggle(_ photo: Photo) async throws {
        if let toggleError {
            throw toggleError
        }
        toggledPhotos.append(photo)
    }

    func remove(photoID: String) async throws {
        if let removeError {
            throw removeError
        }
        removedPhotoIDs.append(photoID)
    }

    func sendFavouriteIDs(_ ids: Set<String>) {
        favouriteIDsSubject.send(ids)
    }

    func sendFavourites(_ photos: [Photo]) {
        favouritesSubject.send(photos)
        favouriteIDsSubject.send(Set(photos.map(\.id)))
    }
}
