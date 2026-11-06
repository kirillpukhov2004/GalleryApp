import Combine
import Foundation

@MainActor
final class GalleryViewModel {
    struct State {
        var photos: [Photo] = []
        var favouriteIDs: Set<String> = []
        var isLoadingInitial = false
        var isLoadingMore = false
        var hasMore = true
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    private let photoFetching: any PhotoFetching
    private let favouritesRepository: any FavouritesRepositoryProtocol
    private var nextPage = 1
    private var cancellables = Set<AnyCancellable>()

    init(
        photoFetching: any PhotoFetching,
        favouritesRepository: any FavouritesRepositoryProtocol
    ) {
        self.photoFetching = photoFetching
        self.favouritesRepository = favouritesRepository

        favouritesRepository.favouritesIDs
            .sink { [weak self] ids in
                self?.state.favouriteIDs = ids
            }
            .store(in: &cancellables)
    }

    var photos: [Photo] {
        state.photos
    }

    func loadInitial() async {
        guard state.photos.isEmpty, !state.isLoadingInitial else { return }
        await load(page: 1, replacing: true)
    }

    func loadMore() async {
        guard state.hasMore,
              !state.isLoadingMore,
              !state.isLoadingInitial,
              !state.photos.isEmpty else {
            return
        }
        await load(page: nextPage, replacing: false)
    }

    func refresh() async {
        await load(page: 1, replacing: true)
    }

    func retry() async {
        if state.photos.isEmpty {
            await load(page: 1, replacing: true)
        } else {
            await loadMore()
        }
    }

    private func load(page: Int, replacing: Bool) async {
        if replacing {
            state.isLoadingInitial = state.photos.isEmpty
        } else {
            state.isLoadingMore = true
        }
        state.errorMessage = nil

        defer {
            state.isLoadingInitial = false
            state.isLoadingMore = false
        }

        do {
            let pageResult = try await photoFetching.fetchPhotos(page: page)

            if replacing {
                state.photos = pageResult.photos
            } else {
                let existingIDs = Set(state.photos.map(\.id))
                state.photos += pageResult.photos.filter { !existingIDs.contains($0.id) }
            }

            nextPage = page + 1
            state.hasMore = pageResult.hasMore
        } catch {
            state.errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }
}
