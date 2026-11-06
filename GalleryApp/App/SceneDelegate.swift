import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        if Self.isRunningTests {
            // The unit test host launches the app, but tests never exercise the live UI.
            // Skipping the composition root keeps tests off the network and out of the store.
            let placeholder = UIViewController()
            placeholder.view.backgroundColor = .systemBackground
            window.rootViewController = placeholder
        } else {
            configureRootViewController(in: window)
        }

        window.makeKeyAndVisible()
        self.window = window
    }

    private func configureRootViewController(in window: UIWindow) {
        do {
            let dependencies = try AppDependencies.live()
            let coordinator = AppCoordinator(dependencies: dependencies)
            window.rootViewController = coordinator.start()
            appCoordinator = coordinator
        } catch {
            window.rootViewController = ConfigurationErrorViewController(
                message: Self.message(for: error)
            )
        }
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return "The app could not start. Check the project configuration and try again."
    }
}
