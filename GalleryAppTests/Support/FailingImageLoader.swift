import UIKit
@testable import GalleryApp

/// Image loader that fails immediately; layout tests do not need real images.
struct FailingImageLoader: ImageLoading {
    func image(for url: URL, maxPixelSize: CGFloat) async throws -> UIImage {
        throw APIError.transport
    }

    func cancelLoading(for url: URL) {}
}
