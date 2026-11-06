import UIKit

final class DetailImageCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var imageTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        spinner.stopAnimating()
    }

    func configure(photo: Photo, imageLoader: any ImageLoading) {
        imageView.accessibilityLabel = "\(photo.title), by \(photo.photographerName)"
        spinner.startAnimating()

        imageTask = Task { [weak self] in
            do {
                let image = try await imageLoader.fullImage(for: photo.regularURL)
                guard !Task.isCancelled else { return }
                self?.spinner.stopAnimating()
                self?.imageView.image = image
            } catch {
                guard !Task.isCancelled else { return }
                self?.spinner.stopAnimating()
                self?.imageView.image = UIImage(systemName: "photo")
            }
        }
    }

    private func configureLayout() {
        contentView.backgroundColor = .secondarySystemBackground

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = .tertiaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spinner)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
