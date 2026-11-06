import Combine
import Foundation

@MainActor
final class FavouritesViewModel {
    struct State {
        var photos: [Photo] = []
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    private let repository: any FavouritesRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: any FavouritesRepositoryProtocol) {
        self.repository = repository

        repository.favourites
            .sink { [weak self] photos in
                self?.state.photos = photos
            }
            .store(in: &cancellables)
    }

    var photos: [Photo] {
        state.photos
    }

    func remove(at index: Int) async {
        guard state.photos.indices.contains(index) else { return }

        do {
            try await repository.remove(photoID: state.photos[index].id)
        } catch {
            state.errorMessage = Self.message(for: error)
        }
    }

    func clearError() {
        state.errorMessage = nil
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return "Couldn't remove the photo. Please try again."
    }
}
