import UIKit

@MainActor
final class GalleryCoordinator {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies
    private let viewModel: GalleryViewModel

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
        viewModel = GalleryViewModel(
            photoFetching: dependencies.photoFetching,
            favouritesRepository: dependencies.favouritesRepository
        )
    }

    func start() {
        let viewController = GalleryViewController(
            viewModel: viewModel,
            imageLoader: dependencies.imageLoader
        )
        navigationController.setViewControllers([viewController], animated: false)
    }
}
