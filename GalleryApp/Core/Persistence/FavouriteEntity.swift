import CoreData

/// Persisted metadata for a favourited photo. Image bytes are never stored.
@objc(FavouriteEntity)
final class FavouriteEntity: NSManagedObject {
    @NSManaged var photoID: String
    @NSManaged var title: String
    @NSManaged var descriptionText: String?
    @NSManaged var thumbnailURLString: String
    @NSManaged var regularURLString: String
    @NSManaged var photographerName: String
    @NSManaged var photographerProfileURLString: String?
    @NSManaged var width: Int32
    @NSManaged var height: Int32
    @NSManaged var dateFavourited: Date
}

extension FavouriteEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<FavouriteEntity> {
        NSFetchRequest<FavouriteEntity>(entityName: "FavouriteEntity")
    }
}
