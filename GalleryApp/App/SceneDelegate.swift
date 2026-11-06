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

        window.makeKeyAndVisible()
        self.window = window
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return "The app could not start. Check the project configuration and try again."
    }
}
