//
//  AuthCoordinator.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/16.
//

import UIKit
import SwiftUI
import FirebaseAuth

@MainActor
final class AuthCoordinator: Coordinator, ObservableObject {
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let authViewModel: AuthViewModel
    private weak var appCoordinator: AppCoordinator?
    
    // MARK: - Initialization
    init(navigationController: UINavigationController, appCoordinator: AppCoordinator? = nil) {
        self.navigationController = navigationController
        self.authViewModel = AuthViewModel()
        self.appCoordinator = appCoordinator
        setupViewModelCallbacks()
    }
    
    // MARK: - Coordinator
    func start() {
        if Auth.auth().currentUser != nil && authViewModel.currentUser != nil {
            // 用戶已登入，切換到主頁面
            appCoordinator?.showMainFlow()
            return
        }
        
        if authViewModel.userSession != nil && authViewModel.currentUser == nil {
            // 嘗試重新獲取用戶資料
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    if let _ = try await self.authViewModel.fetchCurrentUser() {
                        self.appCoordinator?.showMainFlow()
                    } else {
                        self.showLoginView()
                    }
                } catch {
                    self.showLoginView()
                }
            }
        } else {
            showLoginView()
        }
    }
    
    // MARK: - Private Methods
    private func setupViewModelCallbacks() {
        authViewModel.onLoginSuccess = { [weak self] in
            guard let self = self else { return }
            self.appCoordinator?.showMainFlow()
        }
        
        authViewModel.onRegistrationSuccess = { [weak self] in
            guard let self = self else { return }
            self.appCoordinator?.showMainFlow()
        }
        
        authViewModel.onNavigateToRegistration = { [weak self] in
            guard let self = self else { return }
            self.showRegistrationView()
        }
        
        authViewModel.onNavigateBackToLogin = { [weak self] in
            guard let self = self else { return }
            self.navigationController.popViewController(animated: true)
        }
        
        authViewModel.onAuthFailure = { [weak self] error in
            guard let self = self else { return }
            self.showError(error)
        }
    }
    
    private func showLoginView() {
        let loginView = LoginView(viewModel: self.authViewModel)
        let hostingController = UIHostingController(rootView: loginView)
        navigationController.setViewControllers([hostingController], animated: false)
    }
    
    private func showRegistrationView() {
        let registrationView = RegistrationView(viewModel: self.authViewModel)
        let hostingController = UIHostingController(rootView: registrationView)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "驗證錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        
        if let topVC = navigationController.topViewController,
           topVC.presentedViewController == nil {
            topVC.present(alert, animated: true)
        }
    }
}
