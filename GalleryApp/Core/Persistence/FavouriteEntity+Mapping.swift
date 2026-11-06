import CoreData
import Foundation

extension FavouriteEntity {
    convenience init(photo: Photo, in context: NSManagedObjectContext) {
        self.init(context: context)
        photoID = photo.id
        title = photo.title
        descriptionText = photo.descriptionText
        thumbnailURLString = photo.thumbnailURL.absoluteString
        regularURLString = photo.regularURL.absoluteString
        photographerName = photo.photographerName
        photographerProfileURLString = photo.photographerProfileURL?.absoluteString
        width = Int32(clamping: photo.width)
        height = Int32(clamping: photo.height)
        dateFavourited = Date()
    }

    /// Returns `nil` only when stored URLs are unreadable, which indicates corrupt data.
    func toDomain() -> Photo? {
        guard let thumbnailURL = URL(string: thumbnailURLString),
              let regularURL = URL(string: regularURLString) else {
            return nil
        }

        return Photo(
            id: photoID,
            title: title,
            descriptionText: descriptionText,
            thumbnailURL: thumbnailURL,
            regularURL: regularURL,
            photographerName: photographerName,
            photographerProfileURL: photographerProfileURLString.flatMap { URL(string: $0) },
            width: Int(width),
            height: Int(height)
        )
    }
}
