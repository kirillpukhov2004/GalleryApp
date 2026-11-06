import Foundation

/// Composition root for the live application. Every feature receives protocols only.
@MainActor
struct AppDependencies {
    let photoFetching: any PhotoFetching
    let favouritesRepository: any FavouritesRepositoryProtocol
    let imageLoader: any ImageLoading

    static func live() throws -> AppDependencies {
        let configuration = try AppConfiguration()
        let httpClient = URLSessionHTTPClient()
        let unsplashClient = UnsplashClient(
            httpClient: httpClient,
            accessKey: configuration.accessKey
        )
        let stack = try CoreDataStack()
        let favouritesRepository = try FavouritesRepository(stack: stack)

        return AppDependencies(
            photoFetching: unsplashClient,
            favouritesRepository: favouritesRepository,
            imageLoader: ImageLoader()
        )
    }
}
