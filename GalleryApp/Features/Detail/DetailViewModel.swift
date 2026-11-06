import Combine
import Foundation

@MainActor
final class DetailViewModel {
    struct State {
        var currentIndex: Int
        var isFavourite = false
        var isUpdatingFavourite = false
        var errorMessage: String?
    }

    @Published private(set) var state: State

    private let photos: [Photo]
    private let favouritesRepository: any FavouritesRepositoryProtocol
    private var favouriteIDs: Set<String> = []
    private var cancellables = Set<AnyCancellable>()

    init(
        photos: [Photo],
        startIndex: Int,
        favouritesRepository: any FavouritesRepositoryProtocol
    ) {
        self.photos = photos
        self.favouritesRepository = favouritesRepository

        let clampedIndex = photos.isEmpty ? 0 : min(max(startIndex, 0), photos.count - 1)
        state = State(currentIndex: clampedIndex)

        favouritesRepository.favouritesIDs
            .sink { [weak self] ids in
                self?.favouriteIDs = ids
                self?.refreshFavouriteState()
            }
            .store(in: &cancellables)
    }

    var photoCount: Int {
        photos.count
    }

    var currentPhoto: Photo? {
        photo(at: state.currentIndex)
    }

    func photo(at index: Int) -> Photo? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }

    func setCurrentIndex(_ index: Int) {
        guard photos.indices.contains(index), index != state.currentIndex else { return }
        state.currentIndex = index
        refreshFavouriteState()
    }

    func toggleFavourite() async {
        guard let photo = currentPhoto, !state.isUpdatingFavourite else { return }

        state.isUpdatingFavourite = true
        defer { state.isUpdatingFavourite = false }

        do {
            try await favouritesRepository.toggle(photo)
        } catch {
            state.errorMessage = Self.message(for: error)
        }
    }

    private func refreshFavouriteState() {
        guard let photo = currentPhoto else {
            state.isFavourite = false
            return
        }
        state.isFavourite = favouriteIDs.contains(photo.id)
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return "Couldn't update favourites. Please try again."
    }
}
