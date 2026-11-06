import UIKit

/// Temporary screen used until a feature view controller exists.
final class PlaceholderViewController: UIViewController {
    private let placeholderTitle: String
    private let systemImageName: String

    init(title: String, systemImage: String) {
        placeholderTitle = title
        systemImageName = systemImage
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureContent()
    }

    private func configureContent() {
        let imageView = UIImageView(image: UIImage(systemName: systemImageName))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = placeholderTitle
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel
        label.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
