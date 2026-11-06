import UIKit

final class StatusView: UIView {
    var onAction: (() -> Void)?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String?
    ) {
        imageView.image = UIImage(systemName: systemImage)
        titleLabel.text = title
        messageLabel.text = message

        if let actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }

    private func configureLayout() {
        backgroundColor = .systemBackground

        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true

        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true

        actionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [imageView, titleLabel, messageLabel, actionButton].forEach(stackView.addArrangedSubview)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
        ])
    }

    @objc private func handleAction() {
        onAction?()
    }
}
