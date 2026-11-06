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
    private let pageLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let attributionButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()
    private var hasAppliedSnapshot = false
    private var hasScrolledToInitialIndex = false
    private var lastShownError: String?

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
        bind()
        render(viewModel.state)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           layout.itemSize != collectionView.bounds.size {
            layout.itemSize = collectionView.bounds.size
            layout.invalidateLayout()
        }

        scrollToInitialIndexIfNeeded()
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55)
        ])
    }

    private func configureMetadata() {
        pageLabel.font = .preferredFont(forTextStyle: .caption1)
        pageLabel.textColor = .secondaryLabel
        pageLabel.adjustsFontForContentSizeCategory = true

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.adjustsFontForContentSizeCategory = true

        attributionButton.contentHorizontalAlignment = .leading
        attributionButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        attributionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        attributionButton.addTarget(
            self,
            action: #selector(handleAttributionTap),
            for: .touchUpInside
        )

        let stackView = UIStackView(
            arrangedSubviews: [pageLabel, titleLabel, descriptionLabel, attributionButton]
        )
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            )
        ])
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

        attributionButton.setTitle(
            photo.map { "Photo by \($0.photographerName) on Unsplash" },
            for: .normal
        )
        attributionButton.isHidden = photo?.photographerProfileURL == nil

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

    private func scrollToInitialIndexIfNeeded() {
        guard !hasScrolledToInitialIndex,
              collectionView.bounds.width > 0,
              viewModel.photoCount > 0 else {
            return
        }

        hasScrolledToInitialIndex = true
        collectionView.layoutIfNeeded()
        let indexPath = IndexPath(item: viewModel.state.currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }

    private func presentErrorIfNeeded(_ message: String?) {
        guard let message, message != lastShownError else { return }
        lastShownError = message

        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
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
