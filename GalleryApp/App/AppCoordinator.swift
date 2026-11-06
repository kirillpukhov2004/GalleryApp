import UIKit

@MainActor
final class AppCoordinator {
    private let tabBarController = UITabBarController()

    func start() -> UIViewController {
        let galleryViewController = PlaceholderViewController(
            title: "Gallery",
            systemImage: "photo.on.rectangle.angled"
        )
        galleryViewController.tabBarItem = UITabBarItem(
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
            UINavigationController(rootViewController: galleryViewController),
            UINavigationController(rootViewController: favouritesViewController)
        ]

        return tabBarController
    }
}
