//
//  AppCoordinator.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/3.
//

import UIKit
import FirebaseAuth

@MainActor
final class AppCoordinator: Coordinator {
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let window: UIWindow
    private let authViewModel: AuthViewModel
    
    // MARK: - Initialization
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.authViewModel = AuthViewModel()
    }
    
    // MARK: - Coordinator
    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        if Auth.auth().currentUser != nil {
            // 用戶已登入，啟動主頁面
            let mainCoordinator = MainTabCoordinator(navigationController: navigationController, parentCoordinator: self, authViewModel: authViewModel)
            addChildCoordinator(mainCoordinator)
            mainCoordinator.start()
        } else {
//            // 用戶未登入，啟動登入流程
//            let authCoordinator = AuthCoordinator(navigationController: navigationController, appCoordinator: self)
//            addChildCoordinator(authCoordinator)
//            authCoordinator.start()
            let mainCoordinator = MainTabCoordinator(navigationController: navigationController, parentCoordinator: self, authViewModel: authViewModel)
            addChildCoordinator(mainCoordinator)
            mainCoordinator.start()
        }
    }
    
    // MARK: - Public Methods
    func showAuthFlow() {
        // 清除現有的 child coordinators
        childCoordinators.removeAll()
        
        // 啟動登入流程
        let authCoordinator = AuthCoordinator(navigationController: navigationController, appCoordinator: self)
        addChildCoordinator(authCoordinator)
        authCoordinator.start()
    }
    
    func showMainFlow() {
        // 清除現有的 child coordinators
        childCoordinators.removeAll()

        // 啟動主頁面
        let mainCoordinator = MainTabCoordinator(navigationController: navigationController, parentCoordinator: self, authViewModel: authViewModel)
        addChildCoordinator(mainCoordinator)
        mainCoordinator.start()
    }
    
    func handleLogout() {
        // 使用 AuthViewModel 執行登出
        authViewModel.logout()
        
        // 切換到登入流程
        showAuthFlow()
    }
}
