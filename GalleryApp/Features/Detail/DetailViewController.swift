import Combine
import UIKit

final class DetailViewController: UIViewController {
    enum Section {
        case main
    }

    private let viewModel: DetailViewModel
    private let imageLoader: any ImageLoading

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeLayout()
    )
    private lazy var heartButton = UIBarButtonItem(
        image: UIImage(systemName: "heart"),
        style: .plain,
        target: self,
        action: #selector(handleHeartTap)
    )
    private var dataSource: UICollectionViewDiffableDataSource<Section, Int>?

    private let metadataScrollView = UIScrollView()
    private let metadataStackView = UIStackView()
    private let pageLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let attributionLabel = UILabel()

    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []
    private var layoutMode: DetailLayoutMode?
    private var hasAppliedSnapshot = false
    private var lastShownError: String?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: DetailViewModel, imageLoader: any ImageLoading) {
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
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = heartButton

        configureCollectionView()
        configureMetadata()
        configureDataSource()
        configureLayoutConstraints()
        bind()
        render(viewModel.state)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayoutModeIfNeeded()
        syncPagingItemSizeIfNeeded()
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.accessibilityIdentifier = "detail.paging"
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
    }

    private func configureMetadata() {
        metadataScrollView.alwaysBounceVertical = false
        metadataScrollView.showsVerticalScrollIndicator = true
        metadataScrollView.accessibilityIdentifier = "detail.metadata"
        metadataScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metadataScrollView)

        configureLabels()
        configureAttributionLabel()
        configureMetadataStack()
    }

    private func configureLabels() {
        pageLabel.font = .preferredFont(forTextStyle: .caption1)
        pageLabel.textColor = .secondaryLabel
        pageLabel.adjustsFontForContentSizeCategory = true
        pageLabel.accessibilityIdentifier = "detail.page"

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityIdentifier = "detail.title"

        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.accessibilityIdentifier = "detail.description"
    }

    private func configureAttributionLabel() {
        attributionLabel.font = .preferredFont(forTextStyle: .footnote)
        attributionLabel.textColor = .link
        attributionLabel.numberOfLines = 0
        attributionLabel.adjustsFontForContentSizeCategory = true
        attributionLabel.isUserInteractionEnabled = true
        attributionLabel.accessibilityTraits = .link
        attributionLabel.accessibilityIdentifier = "detail.attribution"
        attributionLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleAttributionTap))
        )
    }

    private func configureMetadataStack() {
        metadataStackView.axis = .vertical
        metadataStackView.alignment = .leading
        metadataStackView.spacing = 8
        metadataStackView.translatesAutoresizingMaskIntoConstraints = false
        [pageLabel, titleLabel, descriptionLabel, attributionLabel]
            .forEach(metadataStackView.addArrangedSubview)
        metadataScrollView.addSubview(metadataStackView)

        NSLayoutConstraint.activate([
            metadataStackView.topAnchor.constraint(
                equalTo: metadataScrollView.contentLayoutGuide.topAnchor,
                constant: 16
            ),
            metadataStackView.leadingAnchor.constraint(
                equalTo: metadataScrollView.contentLayoutGuide.leadingAnchor,
                constant: 20
            ),
            metadataStackView.trailingAnchor.constraint(
                equalTo: metadataScrollView.contentLayoutGuide.trailingAnchor,
                constant: -20
            ),
            metadataStackView.bottomAnchor.constraint(
                equalTo: metadataScrollView.contentLayoutGuide.bottomAnchor,
                constant: -24
            ),
            metadataStackView.widthAnchor.constraint(
                equalTo: metadataScrollView.frameLayoutGuide.widthAnchor,
                constant: -40
            )
        ])
    }

    private func configureLayoutConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        let portraitImageHeight = collectionView.heightAnchor.constraint(
            equalTo: view.heightAnchor,
            multiplier: 0.5
        )
        portraitImageHeight.priority = .defaultHigh

        portraitConstraints = [
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            portraitImageHeight,
            collectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
            collectionView.heightAnchor.constraint(lessThanOrEqualToConstant: 520),

            metadataScrollView.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            metadataScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metadataScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metadataScrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ]

        landscapeConstraints = [
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),

            metadataScrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            metadataScrollView.leadingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            metadataScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metadataScrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ]
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<DetailImageCell, Int> { [weak self] cell, _, index in
            guard let self, let photo = self.viewModel.photo(at: index) else { return }
            cell.configure(photo: photo, imageLoader: self.imageLoader)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Int>(
            collectionView: collectionView
        ) { collectionView, indexPath, index in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: index
            )
        }
    }

    private func bind() {
        viewModel.$state
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: DetailViewModel.State) {
        applySnapshotIfNeeded()

        let photo = viewModel.currentPhoto
        titleLabel.text = photo?.title
        descriptionLabel.text = photo?.descriptionText
        descriptionLabel.isHidden = (photo?.descriptionText?.isEmpty ?? true)
        pageLabel.text = "\(state.currentIndex + 1) of \(viewModel.photoCount)"

        let heartImageName = state.isFavourite ? "heart.fill" : "heart"
        heartButton.image = UIImage(systemName: heartImageName)
        heartButton.accessibilityLabel = state.isFavourite
            ? "Remove from favourites"
            : "Add to favourites"

        attributionLabel.text = photo.map { "Photo by \($0.photographerName) on Unsplash" }
        attributionLabel.isHidden = photo?.photographerProfileURL == nil

        if state.errorMessage == nil {
            lastShownError = nil
        }
        presentErrorIfNeeded(state.errorMessage)
    }

    private func applySnapshotIfNeeded() {
        guard !hasAppliedSnapshot else { return }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(0..<viewModel.photoCount))
        dataSource?.apply(snapshot, animatingDifferences: false)
        hasAppliedSnapshot = true
    }

    private func updateLayoutModeIfNeeded() {
        let mode = DetailLayoutMode.mode(for: view.bounds.size)
        guard mode != layoutMode else { return }
        layoutMode = mode

        NSLayoutConstraint.deactivate(portraitConstraints + landscapeConstraints)
        NSLayoutConstraint.activate(
            mode == .portrait ? portraitConstraints : landscapeConstraints
        )
        titleLabel.font = .preferredFont(forTextStyle: mode == .portrait ? .title2 : .title3)

        view.setNeedsLayout()
    }

    private func syncPagingItemSizeIfNeeded() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let size = collectionView.bounds.size
        guard size.width > 0, size.height > 0, layout.itemSize != size else { return }

        layout.itemSize = size
        layout.invalidateLayout()
        collectionView.layoutIfNeeded()
        scrollToCurrentIndex()
    }

    private func scrollToCurrentIndex() {
        guard viewModel.photoCount > 0 else { return }

        let indexPath = IndexPath(item: viewModel.state.currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }

    @objc private func handleHeartTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { await viewModel.toggleFavourite() }
    }

    @objc private func handleAttributionTap() {
        guard let url = viewModel.currentPhoto?.photographerProfileURL else { return }
        UIApplication.shared.open(url)
    }
}

private extension DetailViewController {
    func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }

    func presentErrorIfNeeded(_ message: String?) {
        guard let message, message != lastShownError else { return }
        lastShownError = message

        let alert = UIAlertController(
            title: "Something went wrong",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension DetailViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateIndex(from: scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateIndex(from: scrollView)
    }

    private func updateIndex(from scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        viewModel.setCurrentIndex(index)
    }
}
