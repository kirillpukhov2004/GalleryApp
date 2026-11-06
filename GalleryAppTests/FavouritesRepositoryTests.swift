import Combine
import XCTest
@testable import GalleryApp

@MainActor
final class FavouritesRepositoryTests: XCTestCase {
    func testStartsEmpty() throws {
        let repository = try makeRepository()

        XCTAssertTrue(currentFavourites(repository).isEmpty)
        XCTAssertTrue(currentFavouriteIDs(repository).isEmpty)
    }

    func testToggleAddsFavourite() async throws {
        let repository = try makeRepository()
        let photo = try makePhoto()

        try await repository.toggle(photo)

        XCTAssertEqual(currentFavourites(repository).map(\.id), [photo.id])
        XCTAssertEqual(currentFavouriteIDs(repository), [photo.id])
    }

    func testToggleTwiceRemovesFavourite() async throws {
        let repository = try makeRepository()
        let photo = try makePhoto()

        try await repository.toggle(photo)
        try await repository.toggle(photo)

        XCTAssertTrue(currentFavourites(repository).isEmpty)
        XCTAssertTrue(currentFavouriteIDs(repository).isEmpty)
    }

    func testToggleDoesNotCreateDuplicateRows() async throws {
        let repository = try makeRepository()
        let photo = try makePhoto()

        try await repository.toggle(photo)

        XCTAssertEqual(currentFavourites(repository).count, 1)
    }

    func testRemoveDeletesOnlyRequestedPhoto() async throws {
        let repository = try makeRepository()
        let first = try makePhoto(id: "photo-1")
        let second = try makePhoto(id: "photo-2")

        try await repository.toggle(first)
        try await repository.toggle(second)
        try await repository.remove(photoID: first.id)

        XCTAssertEqual(currentFavouriteIDs(repository), [second.id])
    }

    func testPersistsAcrossRepositoryInstances() async throws {
        let stack = try CoreDataStack(inMemory: true)
        let photo = try makePhoto()

        let first = try FavouritesRepository(stack: stack)
        try await first.toggle(photo)

        let second = try FavouritesRepository(stack: stack)

        XCTAssertEqual(currentFavouriteIDs(second), [photo.id])
    }

    func testRoundTripsPhotoMetadata() async throws {
        let repository = try makeRepository()
        let photo = try makePhoto()

        try await repository.toggle(photo)

        let stored = try XCTUnwrap(currentFavourites(repository).first)
        XCTAssertEqual(stored, photo)
    }

    func testPublishesChangesToSubscribers() async throws {
        let repository = try makeRepository()
        let photo = try makePhoto()
        var emissions: [[Photo]] = []

        let cancellable = repository.favourites.sink { emissions.append($0) }
        defer { cancellable.cancel() }

        try await repository.toggle(photo)

        XCTAssertEqual(emissions.count, 2)
        XCTAssertEqual(emissions.last?.map(\.id), [photo.id])
    }

    private func makeRepository() throws -> FavouritesRepository {
        let stack = try CoreDataStack(inMemory: true)
        return try FavouritesRepository(stack: stack)
    }

    private func currentFavourites(_ repository: FavouritesRepository) -> [Photo] {
        var photos: [Photo] = []
        let cancellable = repository.favourites.sink { photos = $0 }
        cancellable.cancel()
        return photos
    }

    private func currentFavouriteIDs(_ repository: FavouritesRepository) -> Set<String> {
        var ids: Set<String> = []
        let cancellable = repository.favouritesIDs.sink { ids = $0 }
        cancellable.cancel()
        return ids
    }

    private func makePhoto(id: String = "photo-1") throws -> Photo {
        let thumbnailURL = try XCTUnwrap(URL(string: "https://images.unsplash.com/\(id)?w=400"))
        let regularURL = try XCTUnwrap(URL(string: "https://images.unsplash.com/\(id)?w=1080"))
        let profileURL = try XCTUnwrap(URL(string: "https://unsplash.com/@photographer"))

        return Photo(
            id: id,
            title: "A title",
            descriptionText: "A description",
            thumbnailURL: thumbnailURL,
            regularURL: regularURL,
            photographerName: "Photographer",
            photographerProfileURL: profileURL,
            width: 4000,
            height: 3000
        )
    }
}
