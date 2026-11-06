import Combine
import UIKit

final class GalleryViewController: UIViewController {
    enum Section {
        case main
    }

    var onSelectPhoto: ((Int) -> Void)?

    private let viewModel: GalleryViewModel
    private let imageLoader: any ImageLoading

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: GridLayout.make()
    )
    private var dataSource: UICollectionViewDiffableDataSource<Section, Photo.ID>?
    private let statusView = StatusView(frame: .zero)
    private let initialSpinner = UIActivityIndicatorView(style: .large)
    private let footerSpinner = UIActivityIndicatorView(style: .medium)
    private var photosByID: [Photo.ID: Photo] = [:]
    private var renderedFavouriteIDs: Set<String> = []
    private var hasAppliedSnapshot = false
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: GalleryViewModel, imageLoader: any ImageLoading) {
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
        title = "Gallery"
        view.backgroundColor = .systemBackground

        configureCollectionView()
        configureOverlays()
        bind()
        Task { await viewModel.loadInitial() }
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        configureDataSource()
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<PhotoCell, Photo.ID> { [weak self] cell, _, photoID in
            guard let self, let photo = self.photosByID[photoID] else { return }
            cell.configure(
                photo: photo,
                isFavourite: self.viewModel.state.favouriteIDs.contains(photoID),
                imageLoader: self.imageLoader
            )
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

    private func configureOverlays() {
        statusView.isHidden = true
        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)

        initialSpinner.hidesWhenStopped = true
        initialSpinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(initialSpinner)

        footerSpinner.hidesWhenStopped = true
        footerSpinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footerSpinner)

        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: view.topAnchor),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            initialSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            initialSpinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            footerSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            footerSpinner.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            )
        ])
    }

    private func bind() {
        viewModel.$state
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: GalleryViewModel.State) {
        photosByID = Dictionary(uniqueKeysWithValues: state.photos.map { ($0.id, $0) })
        applySnapshot(state)
        updateSpinners(state)
        updateStatus(state)
    }

    private func applySnapshot(_ state: GalleryViewModel.State) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Photo.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(state.photos.map(\.id))

        if state.favouriteIDs != renderedFavouriteIDs {
            snapshot.reconfigureItems(snapshot.itemIdentifiers)
        }

        dataSource?.apply(snapshot, animatingDifferences: hasAppliedSnapshot)
        hasAppliedSnapshot = true
        renderedFavouriteIDs = state.favouriteIDs
    }

    private func updateSpinners(_ state: GalleryViewModel.State) {
        if state.isLoadingInitial, state.photos.isEmpty {
            initialSpinner.startAnimating()
        } else {
            initialSpinner.stopAnimating()
        }

        if state.isLoadingMore {
            footerSpinner.startAnimating()
        } else {
            footerSpinner.stopAnimating()
        }
    }

    private func updateStatus(_ state: GalleryViewModel.State) {
        guard state.photos.isEmpty, !state.isLoadingInitial else {
            statusView.isHidden = true
            return
        }

        if let message = state.errorMessage {
            statusView.configure(
                title: "Couldn't load photos",
                message: message,
                systemImage: "wifi.exclamationmark",
                actionTitle: "Try Again"
            )
            statusView.onAction = { [weak self] in
                Task { await self?.viewModel.retry() }
            }
        } else {
            statusView.configure(
                title: "No photos yet",
                message: "Pull to refresh to try again.",
                systemImage: "photo.on.rectangle",
                actionTitle: nil
            )
        }

        statusView.isHidden = false
    }

    @objc private func handleRefresh() {
        Task { [weak self] in
            await self?.viewModel.refresh()
            self?.collectionView.refreshControl?.endRefreshing()
        }
    }
}

extension GalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onSelectPhoto?(indexPath.item)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        guard contentHeight > 0 else { return }

        let remaining = contentHeight - scrollView.contentOffset.y - scrollView.bounds.height
        guard remaining < 600 else { return }

        Task { await viewModel.loadMore() }
    }
}
