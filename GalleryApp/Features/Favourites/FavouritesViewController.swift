import Combine
import UIKit

final class FavouritesViewController: UIViewController {
    enum Section {
        case main
    }

    var onSelectPhoto: ((Int) -> Void)?

    private let viewModel: FavouritesViewModel
    private let imageLoader: any ImageLoading

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: GridLayout.make()
    )
    private var dataSource: UICollectionViewDiffableDataSource<Section, Photo.ID>?
    private let statusView = StatusView(frame: .zero)
    private var photosByID: [Photo.ID: Photo] = [:]
    private var hasAppliedSnapshot = false
    private var lastShownError: String?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: FavouritesViewModel, imageLoader: any ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favourites"
        view.backgroundColor = .systemBackground

        configureCollectionView()
        configureStatusView()
        bind()
        render(viewModel.state)
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        configureDataSource()
    }

    private func configureDataSource() {
        typealias CellRegistration = UICollectionView.CellRegistration<PhotoCell, Photo.ID>
        let registration = CellRegistration { [weak self] cell, indexPath, photoID in
            guard let self, let photo = self.photosByID[photoID] else { return }
            cell.configure(photo: photo, isFavourite: true, imageLoader: self.imageLoader)
            cell.accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: "Remove from Favourites") { [weak self] _ in
                    Task { await self?.viewModel.remove(at: indexPath.item) }
                    return true
                }
            ]
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Photo.ID>(
            collectionView: collectionView
        ) { collectionView, indexPath, photoID in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: photoID
            )
        }
    }

    private func configureStatusView() {
        statusView.isHidden = true
        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)

        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: view.topAnchor),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func bind() {
        viewModel.$state
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: FavouritesViewModel.State) {
        photosByID = Dictionary(uniqueKeysWithValues: state.photos.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Section, Photo.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(state.photos.map(\.id))
        dataSource?.apply(snapshot, animatingDifferences: hasAppliedSnapshot)
        hasAppliedSnapshot = true

        let isEmpty = state.photos.isEmpty
        statusView.isHidden = !isEmpty
        if isEmpty {
            statusView.configure(
                title: "No favourites yet",
                message: "Photos you favourite appear here. Tap the heart on any photo.",
                systemImage: "heart",
                actionTitle: nil
            )
        }

        presentErrorIfNeeded(state.errorMessage)
    }

    private func presentErrorIfNeeded(_ message: String?) {
        guard let message, message != lastShownError else { return }
        lastShownError = message

        let alert = UIAlertController(
            title: "Something went wrong",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.clearError()
        })
        present(alert, animated: true)
    }
}

extension FavouritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onSelectPhoto?(indexPath.item)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard viewModel.photos.indices.contains(indexPath.item) else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let removeAction = UIAction(
                title: "Remove from Favourites",
                image: UIImage(systemName: "heart.slash"),
                attributes: .destructive
            ) { _ in
                Task { await self?.viewModel.remove(at: indexPath.item) }
            }
            return UIMenu(children: [removeAction])
        }
    }
}
