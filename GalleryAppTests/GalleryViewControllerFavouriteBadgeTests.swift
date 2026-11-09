import UIKit
import XCTest
@testable import GalleryApp

@MainActor
final class GalleryViewControllerFavouriteBadgeTests: XCTestCase {
    func testBadgeAppearsWhenRepositoryMarksPhotoFavourite() async throws {
        let fetcher = FakePhotoFetching()
        await fetcher.stub(
            page: 1,
            result: .success(PhotoPage(photos: [try makePhoto(id: "a")], hasMore: false))
        )
        let repository = FakeFavouritesRepository()
        let viewModel = GalleryViewModel(
            photoFetching: fetcher,
            favouritesRepository: repository
        )
        let viewController = GalleryViewController(
            viewModel: viewModel,
            imageLoader: FailingImageLoader()
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.frame = window.bounds

        await viewModel.loadInitial()
        layout(viewController)

        let collectionView = try XCTUnwrap(
            find("gallery.collection", in: viewController.view) as? UICollectionView
        )
        XCTAssertTrue(try badge(in: collectionView).isHidden)

        repository.sendFavouriteIDs(["a"])
        layout(viewController)

        XCTAssertFalse(try badge(in: collectionView).isHidden)
    }

    private func badge(in collectionView: UICollectionView) throws -> UIView {
        let cell = try XCTUnwrap(
            collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        )
        return try XCTUnwrap(find("photo.favouriteBadge", in: cell))
    }

    private func layout(_ viewController: UIViewController) {
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
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

    private func makePhoto(id: String) throws -> Photo {
        Photo(
            id: id,
            title: "Title \(id)",
            descriptionText: nil,
            thumbnailURL: try XCTUnwrap(URL(string: "https://example.com/\(id)-thumb.jpg")),
            regularURL: try XCTUnwrap(URL(string: "https://example.com/\(id)-regular.jpg")),
            photographerName: "Photographer",
            photographerProfileURL: nil,
            width: 100,
            height: 100
        )
    }
}
