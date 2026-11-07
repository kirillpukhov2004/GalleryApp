import UIKit
import XCTest
@testable import GalleryApp

@MainActor
final class DetailViewControllerLayoutTests: XCTestCase {
    func testPortraitPlacesMetadataBelowPagingArea() throws {
        let sut = try makeSUT(size: CGSize(width: 390, height: 844))
        layout(sut.viewController)

        let paging = try XCTUnwrap(view("detail.paging", in: sut.viewController.view))
        let metadata = try XCTUnwrap(view("detail.metadata", in: sut.viewController.view))

        XCTAssertEqual(paging.frame.width, sut.viewController.view.bounds.width, accuracy: 1)
        XCTAssertEqual(metadata.frame.minY, paging.frame.maxY, accuracy: 1)
        XCTAssertEqual(metadata.frame.maxY, sut.viewController.view.bounds.maxY, accuracy: 1)
        XCTAssertFalse(sut.viewController.view.hasAmbiguousLayout)
    }

    func testLandscapeSplitsPagingAndMetadataColumns() throws {
        let sut = try makeSUT(size: CGSize(width: 844, height: 390))
        layout(sut.viewController)

        let paging = try XCTUnwrap(view("detail.paging", in: sut.viewController.view))
        let metadata = try XCTUnwrap(view("detail.metadata", in: sut.viewController.view))

        XCTAssertEqual(paging.frame.width, 844 * 0.6, accuracy: 1)
        XCTAssertEqual(metadata.frame.minX, paging.frame.maxX, accuracy: 1)
        XCTAssertEqual(metadata.frame.maxX, sut.viewController.view.bounds.maxX, accuracy: 1)
        XCTAssertFalse(sut.viewController.view.hasAmbiguousLayout)
    }

    func testRotationKeepsCurrentPageAligned() throws {
        let sut = try makeSUT(size: CGSize(width: 390, height: 844))
        layout(sut.viewController)

        let paging = try XCTUnwrap(view("detail.paging", in: sut.viewController.view) as? UICollectionView)
        sut.viewModel.setCurrentIndex(2)
        paging.contentOffset.x = paging.bounds.width * 2

        sut.window.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        sut.viewController.view.frame = sut.window.bounds
        layout(sut.viewController)
        layout(sut.viewController)

        XCTAssertEqual(paging.contentOffset.x, paging.bounds.width * 2, accuracy: 1)
    }

    func testLongDescriptionScrollsInsteadOfClipping() throws {
        let sut = try makeSUT(size: CGSize(width: 390, height: 844))
        layout(sut.viewController)

        let metadata = try XCTUnwrap(view("detail.metadata", in: sut.viewController.view) as? UIScrollView)
        let title = try XCTUnwrap(view("detail.title", in: sut.viewController.view))
        let description = try XCTUnwrap(view("detail.description", in: sut.viewController.view))

        XCTAssertGreaterThan(metadata.contentSize.height, metadata.bounds.height)
        XCTAssertGreaterThan(title.frame.height, 0)
        XCTAssertGreaterThan(description.frame.height, 0)
        XCTAssertFalse(title.isHidden)
        XCTAssertFalse(description.isHidden)
    }

    private struct SUT {
        let viewController: DetailViewController
        let viewModel: DetailViewModel
        let window: UIWindow
    }

    private func makeSUT(size: CGSize) throws -> SUT {
        let photos = try makePhotos()
        let viewModel = DetailViewModel(
            photos: photos,
            startIndex: 0,
            favouritesRepository: FakeFavouritesRepository()
        )
        let viewController = DetailViewController(
            viewModel: viewModel,
            imageLoader: FailingImageLoader()
        )

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.frame = window.bounds

        return SUT(viewController: viewController, viewModel: viewModel, window: window)
    }

    private func makePhotos() throws -> [Photo] {
        let longDescription = String(
            repeating: "A long description that must scroll instead of being clipped. ",
            count: 8
        )

        return try (0..<3).map { index in
            Photo(
                id: "photo-\(index)",
                title: "A short title \(index)",
                descriptionText: longDescription,
                thumbnailURL: try XCTUnwrap(URL(string: "https://example.com/\(index)-thumb.jpg")),
                regularURL: try XCTUnwrap(URL(string: "https://example.com/\(index)-regular.jpg")),
                photographerName: "Photographer",
                photographerProfileURL: try XCTUnwrap(URL(string: "https://unsplash.com/@photographer")),
                width: 4000,
                height: 3000
            )
        }
    }

    private func layout(_ viewController: UIViewController) {
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
    }

    private func view(_ identifier: String, in root: UIView) -> UIView? {
        if root.accessibilityIdentifier == identifier {
            return root
        }

        for subview in root.subviews {
            if let match = view(identifier, in: subview) {
                return match
            }
        }

        return nil
    }
}
