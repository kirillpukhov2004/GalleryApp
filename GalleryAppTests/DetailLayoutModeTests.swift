import XCTest
@testable import GalleryApp

final class DetailLayoutModeTests: XCTestCase {
    func testUsesPortraitForTallSizes() {
        XCTAssertEqual(DetailLayoutMode.mode(for: CGSize(width: 390, height: 844)), .portrait)
    }

    func testUsesLandscapeForWideSizes() {
        XCTAssertEqual(DetailLayoutMode.mode(for: CGSize(width: 844, height: 390)), .landscape)
    }

    func testUsesPortraitForSquareSizes() {
        XCTAssertEqual(DetailLayoutMode.mode(for: CGSize(width: 500, height: 500)), .portrait)
    }
}
