//
//  AppDelegate.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/4.
//

// Chef/Shared/Services/AppDelegate.swift
import UIKit
import Firebase

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, UIWindowSceneDelegate { // 確保遵從協定

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 在應用程序啟動時配置 Firebase
        FirebaseApp.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let cfg = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        cfg.delegateClass = Self.self
        return cfg
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // 建立並啟動 AppCoordinator
        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator
        coordinator.start()
    }
}
