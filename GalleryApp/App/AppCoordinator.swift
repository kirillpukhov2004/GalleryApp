import UIKit

@MainActor
final class AppCoordinator {
    private let dependencies: AppDependencies
    private let tabBarController = UITabBarController()
    private var galleryCoordinator: GalleryCoordinator?
    private var favouritesCoordinator: FavouritesCoordinator?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func start() -> UIViewController {
        let galleryNavigationController = UINavigationController()
        let galleryCoordinator = GalleryCoordinator(
            navigationController: galleryNavigationController,
            dependencies: dependencies
        )
        galleryCoordinator.start()
        self.galleryCoordinator = galleryCoordinator
        galleryNavigationController.tabBarItem = UITabBarItem(
            title: "Gallery",
            image: UIImage(systemName: "photo.on.rectangle.angled"),
            selectedImage: nil
        )

        let favouritesNavigationController = UINavigationController()
        let favouritesCoordinator = FavouritesCoordinator(
            navigationController: favouritesNavigationController,
            dependencies: dependencies
        )
        favouritesCoordinator.start()
        self.favouritesCoordinator = favouritesCoordinator
        favouritesNavigationController.tabBarItem = UITabBarItem(
            title: "Favourites",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        tabBarController.viewControllers = [
            galleryNavigationController,
            favouritesNavigationController
        ]

        return tabBarController
    }
}
