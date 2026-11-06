import Combine
import CoreData

@MainActor
final class FavouritesRepository: FavouritesRepositoryProtocol {
    private let stack: CoreDataStack
    private let favouritesSubject: CurrentValueSubject<[Photo], Never>
    private let favouriteIDsSubject: CurrentValueSubject<Set<String>, Never>

    var favourites: AnyPublisher<[Photo], Never> {
        favouritesSubject.eraseToAnyPublisher()
    }

    var favouritesIDs: AnyPublisher<Set<String>, Never> {
        favouriteIDsSubject.eraseToAnyPublisher()
    }

    init(stack: CoreDataStack) throws {
        self.stack = stack

        let photos = try Self.fetchFavourites(in: stack.container.viewContext)
        favouritesSubject = CurrentValueSubject(photos)
        favouriteIDsSubject = CurrentValueSubject(Set(photos.map(\.id)))
    }

    func toggle(_ photo: Photo) async throws {
        try await mutate { context in
            let request = FavouriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "photoID == %@", photo.id)
            request.fetchLimit = 1

            if let existing = try context.fetch(request).first {
                context.delete(existing)
            } else {
                _ = FavouriteEntity(photo: photo, in: context)
            }

            try context.save()
        }
    }

    func remove(photoID: String) async throws {
        try await mutate { context in
            let request = FavouriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "photoID == %@", photoID)

            for entity in try context.fetch(request) {
                context.delete(entity)
            }

            try context.save()
        }
    }

    private func mutate(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> Void
    ) async throws {
        let context = stack.container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        try await context.perform {
            try block(context)
        }

        try refresh()
    }

    private func refresh() throws {
        let photos = try Self.fetchFavourites(in: stack.container.viewContext)
        favouritesSubject.send(photos)
        favouriteIDsSubject.send(Set(photos.map(\.id)))
    }

    private static func fetchFavourites(in context: NSManagedObjectContext) throws -> [Photo] {
        let request = FavouriteEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "dateFavourited", ascending: false),
            NSSortDescriptor(key: "title", ascending: true)
        ]
        return try context.fetch(request).compactMap { $0.toDomain() }
    }
}
