import UIKit

/// Shown when the app cannot start because configuration is missing.
final class ConfigurationErrorViewController: UIViewController {
    private let message: String

    init(message: String) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let statusView = StatusView(frame: .zero)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.configure(
            title: "Configuration needed",
            message: message,
            systemImage: "key.slash",
            actionTitle: nil
        )
        view.addSubview(statusView)

        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: view.topAnchor),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
