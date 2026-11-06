import UIKit

/// Memory-cached image loader with in-flight de-duplication and downsampling.
///
/// State is guarded by `lock`, so the loader is safe to share between screens while
/// keeping the synchronous `cancelLoading` API that cell reuse needs.
final class ImageLoader: ImageLoading, @unchecked Sendable {
    private let session: URLSession
    private let cache: NSCache<NSString, UIImage>
    private let lock = NSLock()
    private var inFlightTasks: [String: Task<UIImage, Error>] = [:]

    init(
        session: URLSession = .shared,
        countLimit: Int = 200,
        totalCostLimit: Int = 100 * 1024 * 1024
    ) {
        self.session = session
        cache = NSCache()
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func image(for url: URL, maxPixelSize: CGFloat) async throws -> UIImage {
        let key = Self.cacheKey(url: url, maxPixelSize: maxPixelSize)

        if let cachedImage = cache.object(forKey: key as NSString) {
            return cachedImage
        }

        let task: Task<UIImage, Error> = lock.withLock {
            if let existingTask = inFlightTasks[key] {
                return existingTask
            }

            let newTask = Task<UIImage, Error> {
                try await Self.fetchImage(
                    session: session,
                    url: url,
                    maxPixelSize: maxPixelSize
                )
            }
            inFlightTasks[key] = newTask
            return newTask
        }

        do {
            let image = try await task.value
            lock.withLock { inFlightTasks[key] = nil }
            cache.setObject(image, forKey: key as NSString, cost: Self.cost(of: image))
            return image
        } catch {
            lock.withLock { inFlightTasks[key] = nil }
            throw Self.mapError(error)
        }
    }

    func cancelLoading(for url: URL) {
        let prefix = url.absoluteString + "#"
        let tasksToCancel: [Task<UIImage, Error>] = lock.withLock {
            let keys = inFlightTasks.keys.filter { $0.hasPrefix(prefix) }
            let tasks = keys.compactMap { inFlightTasks[$0] }
            keys.forEach { inFlightTasks[$0] = nil }
            return tasks
        }

        tasksToCancel.forEach { $0.cancel() }
    }

    nonisolated private static func fetchImage(
        session: URLSession,
        url: URL,
        maxPixelSize: CGFloat
    ) async throws -> UIImage {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch is CancellationError {
            throw APIError.cancelled
        } catch let error as URLError where error.code == .cancelled {
            throw APIError.cancelled
        } catch {
            throw APIError.transport
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        guard let image = downsample(data: data, maxPixelSize: maxPixelSize) else {
            throw APIError.decoding
        }

        return image
    }

    nonisolated private static func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    nonisolated private static func cacheKey(url: URL, maxPixelSize: CGFloat) -> String {
        "\(url.absoluteString)#\(Int(maxPixelSize.rounded()))"
    }

    nonisolated private static func cost(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }

    nonisolated private static func mapError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        if error is CancellationError {
            return .cancelled
        }
        return .transport
    }
}
