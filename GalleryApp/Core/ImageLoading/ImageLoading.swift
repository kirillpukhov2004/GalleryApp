import UIKit

protocol ImageLoading: Sendable {
    /// Loads and downsamples the image so it never decodes larger than `maxPixelSize`.
    func image(for url: URL, maxPixelSize: CGFloat) async throws -> UIImage
    func cancelLoading(for url: URL)
}

extension ImageLoading {
    func thumbnail(for url: URL) async throws -> UIImage {
        try await image(for: url, maxPixelSize: 400)
    }

    func fullImage(for url: URL) async throws -> UIImage {
        try await image(for: url, maxPixelSize: 1080)
    }
}
