import CoreData
import Foundation

enum CoreDataStackError: Error, Equatable {
    case missingModel
    case missingStoreDescription
}

/// Owns the persistent container. The view context serves reads on the main queue,
/// writes happen on background contexts created by the repository.
final class CoreDataStack {
    static let modelName = "GalleryApp"

    let container: NSPersistentContainer

    init(inMemory: Bool = false) throws {
        let bundle = Bundle(for: CoreDataStack.self)
        guard let modelURL = bundle.url(forResource: Self.modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataStackError.missingModel
        }

        let container = NSPersistentContainer(name: Self.modelName, managedObjectModel: model)
        guard let description = container.persistentStoreDescriptions.first else {
            throw CoreDataStackError.missingStoreDescription
        }

        description.shouldAddStoreAsynchronously = false
        if inMemory {
            description.type = NSInMemoryStoreType
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.container = container
    }
}
