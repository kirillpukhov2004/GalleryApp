import UIKit

@MainActor
final class FavouritesCoordinator {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies
    private let viewModel: FavouritesViewModel

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
        viewModel = FavouritesViewModel(repository: dependencies.favouritesRepository)
    }

    func start() {
        let viewController = FavouritesViewController(
            viewModel: viewModel,
            imageLoader: dependencies.imageLoader
        )
        viewController.onSelectPhoto = { [weak self] index in
            self?.showDetail(at: index)
        }
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showDetail(at index: Int) {
        let detailViewModel = DetailViewModel(
            photos: viewModel.photos,
            startIndex: index,
            favouritesRepository: dependencies.favouritesRepository
        )
        let detailViewController = DetailViewController(
            viewModel: detailViewModel,
            imageLoader: dependencies.imageLoader
        )
        navigationController.pushViewController(detailViewController, animated: true)
    }
}
