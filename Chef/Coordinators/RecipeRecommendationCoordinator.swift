//
//  RecipeRecommendationCoordinator.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import UIKit
import SwiftUI

@MainActor
final class RecipeRecommendationCoordinator: Coordinator, ObservableObject {

    // MARK: - Protocol Requirements
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: MainTabCoordinator?

    // MARK: - Dependencies
    private var viewModel: RecipeRecommendationViewModel?
    private var hostingController: UIHostingController<AnyView>?

    // MARK: - Init
    init(navigationController: UINavigationController, parentCoordinator: MainTabCoordinator? = nil) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
    }

    // MARK: - Lifecycle Methods
    func start() {
        print("🔄 RecipeRecommendationCoordinator: 啟動食譜推薦流程")

        // 創建 ViewModel 和 View
        let viewModel = RecipeRecommendationViewModel()
        self.viewModel = viewModel

        let view = RecipeRecommendationView(viewModel: viewModel)
            .environmentObject(self)

        let hostingController = UIHostingController(rootView: AnyView(view))
        self.hostingController = hostingController

        // 設置導航標題
        hostingController.title = "食譜推薦"
        hostingController.navigationItem.largeTitleDisplayMode = .automatic

        navigationController.pushViewController(hostingController, animated: true)
    }

    func stop() {
        print("🛑 RecipeRecommendationCoordinator: 停止食譜推薦流程")

        // 清理資源
        viewModel = nil
        hostingController = nil

        // 清除所有子協調器
        childCoordinators.removeAll()
    }

    func restart() {
        print("🔄 RecipeRecommendationCoordinator: 重新啟動食譜推薦流程")
        stop()
        start()
    }

    // MARK: - Navigation Methods

    /// 顯示食譜詳細信息
    func showRecipeDetail(_ recipe: SuggestRecipeResponse) {
        print("📄 RecipeRecommendationCoordinator: 顯示食譜詳細信息")
        let coordinator = RecipeCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.showRecipeDetail(recipe)
    }

    /// 顯示錯誤提示
    func showError(_ error: Error) {
        print("❌ RecipeRecommendationCoordinator: 顯示錯誤提示：\(error)")

        let alert = UIAlertController(
            title: "錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "確定", style: .default))

        DispatchQueue.main.async { [weak self] in
            self?.navigationController.present(alert, animated: true)
        }
    }

    /// 顯示成功提示
    func showSuccess(message: String) {
        print("✅ RecipeRecommendationCoordinator: 顯示成功提示：\(message)")

        let alert = UIAlertController(
            title: "成功",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "確定", style: .default))

        DispatchQueue.main.async { [weak self] in
            self?.navigationController.present(alert, animated: true)
        }
    }

    /// 導航到首頁
    func navigateToHome() {
        print("🏠 RecipeRecommendationCoordinator: 導航到首頁")
        navigationController.popToRootViewController(animated: true)
    }

    /// 導航回上一個頁面
    func goBack() {
        print("⬅️ RecipeRecommendationCoordinator: 導航回上一個頁面")
        navigationController.popViewController(animated: true)
    }

    func handleLogout() {
        print("RecipeRecommendationCoordinator: 開始處理登出")

        // 清除所有子協調器
        print("RecipeRecommendationCoordinator: 清除子協調器")
        childCoordinators.removeAll()

        // 通知父協調器處理登出
        if let parentCoordinator = parentCoordinator {
            print("RecipeRecommendationCoordinator: 找到父協調器，通知處理登出")
            parentCoordinator.handleLogout()
        } else {
            print("RecipeRecommendationCoordinator: 錯誤 - 父協調器為空")
        }
    }
}