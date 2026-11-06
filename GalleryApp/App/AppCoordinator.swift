import UIKit

@MainActor
final class AppCoordinator {
    private let dependencies: AppDependencies
    private let tabBarController = UITabBarController()
    private var galleryCoordinator: GalleryCoordinator?

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

        let favouritesViewController = PlaceholderViewController(
            title: "Favourites",
            systemImage: "heart"
        )
        favouritesViewController.tabBarItem = UITabBarItem(
            title: "Favourites",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        tabBarController.viewControllers = [
            galleryNavigationController,
            UINavigationController(rootViewController: favouritesViewController)
        ]

        return tabBarController
    }
}
