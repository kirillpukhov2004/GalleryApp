import UIKit
import XCTest
@testable import GalleryApp

@MainActor
final class PhotoCellTests: XCTestCase {
    func testShowsBadgeForFavouritePhoto() throws {
        let cell = PhotoCell(frame: CGRect(x: 0, y: 0, width: 120, height: 120))

        cell.configure(photo: try makePhoto(), isFavourite: true, imageLoader: FailingImageLoader())

        XCTAssertFalse(try badge(in: cell).isHidden)
    }

    func testHidesBadgeForNonFavouritePhoto() throws {
        let cell = PhotoCell(frame: CGRect(x: 0, y: 0, width: 120, height: 120))

        cell.configure(photo: try makePhoto(), isFavourite: false, imageLoader: FailingImageLoader())

        XCTAssertTrue(try badge(in: cell).isHidden)
    }

    func testPrepareForReuseHidesBadge() throws {
        let cell = PhotoCell(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        cell.configure(photo: try makePhoto(), isFavourite: true, imageLoader: FailingImageLoader())

        cell.prepareForReuse()

        XCTAssertTrue(try badge(in: cell).isHidden)
    }

    func testExposesFavouriteStateToAccessibility() throws {
        let cell = PhotoCell(frame: CGRect(x: 0, y: 0, width: 120, height: 120))

        cell.configure(photo: try makePhoto(), isFavourite: true, imageLoader: FailingImageLoader())
        XCTAssertEqual(cell.accessibilityValue, "Favourite")

        cell.configure(photo: try makePhoto(), isFavourite: false, imageLoader: FailingImageLoader())
        XCTAssertNil(cell.accessibilityValue)
    }

    private func badge(in cell: PhotoCell) throws -> UIView {
        try XCTUnwrap(find("photo.favouriteBadge", in: cell.contentView))
    }

    private func find(_ identifier: String, in root: UIView) -> UIView? {
        if root.accessibilityIdentifier == identifier {
            return root
        }

        for subview in root.subviews {
            if let match = find(identifier, in: subview) {
                return match
            }
        }

        return nil
    }

    private func makePhoto() throws -> Photo {
        Photo(
            id: "photo-1",
            title: "A title",
            descriptionText: nil,
            thumbnailURL: try XCTUnwrap(URL(string: "https://example.com/thumb.jpg")),
            regularURL: try XCTUnwrap(URL(string: "https://example.com/regular.jpg")),
            photographerName: "Photographer",
            photographerProfileURL: nil,
            width: 100,
            height: 100
        )
    }
}
