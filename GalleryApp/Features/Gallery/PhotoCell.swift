import UIKit

final class PhotoCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let badgeContainer = UIView()
    private let badgeImageView = UIImageView()
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
        badgeContainer.isHidden = true
    }

    func configure(photo: Photo, isFavourite: Bool, imageLoader: any ImageLoading) {
        badgeContainer.isHidden = !isFavourite

        isAccessibilityElement = true
        accessibilityLabel = "\(photo.title), by \(photo.photographerName)"
        accessibilityTraits = .button
        accessibilityValue = isFavourite ? "Favourite" : nil

        imageTask = Task { [weak self] in
            do {
                let image = try await imageLoader.thumbnail(for: photo.thumbnailURL)
                guard !Task.isCancelled else { return }
                self?.imageView.image = image
            } catch {
                guard !Task.isCancelled else { return }
                self?.imageView.image = UIImage(systemName: "photo")
            }
        }
    }

    private func configureLayout() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .tertiaryLabel
        contentView.addSubview(imageView)

        badgeContainer.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        badgeContainer.layer.cornerRadius = 13
        badgeContainer.isHidden = true
        badgeContainer.translatesAutoresizingMaskIntoConstraints = false

        badgeImageView.image = UIImage(systemName: "heart.fill")
        badgeImageView.tintColor = .white
        badgeImageView.contentMode = .scaleAspectFit
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(badgeImageView)
        contentView.addSubview(badgeContainer)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            badgeContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            badgeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            badgeContainer.widthAnchor.constraint(equalToConstant: 26),
            badgeContainer.heightAnchor.constraint(equalToConstant: 26),

            badgeImageView.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
            badgeImageView.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 14),
            badgeImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
}
