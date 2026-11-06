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
