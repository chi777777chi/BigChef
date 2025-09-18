//
//  FoodRecognitionCoordinator.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import UIKit
import SwiftUI

@MainActor
final class FoodRecognitionCoordinator: Coordinator, ObservableObject {

    // MARK: - Protocol Requirements
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: MainTabCoordinator?

    // MARK: - Dependencies
    private var viewModel: FoodRecognitionViewModel?
    private var hostingController: UIHostingController<AnyView>?

    // MARK: - Init
    init(navigationController: UINavigationController, parentCoordinator: MainTabCoordinator? = nil) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
    }

    // MARK: - Lifecycle Methods
    func start() {
        print("🔄 FoodRecognitionCoordinator: 啟動食物辨識流程")

        // 創建 ViewModel 和 View
        let viewModel = FoodRecognitionViewModel()
        self.viewModel = viewModel

        let view = FoodRecognitionView(viewModel: viewModel)
            .environmentObject(self)

        let hostingController = UIHostingController(rootView: AnyView(view))
        self.hostingController = hostingController

        // 設置導航標題
        hostingController.title = "食物辨識"
        hostingController.navigationItem.largeTitleDisplayMode = .automatic

        navigationController.pushViewController(hostingController, animated: true)
    }

    func stop() {
        print("🛑 FoodRecognitionCoordinator: 停止食物辨識流程")

        // 清理資源
        viewModel?.resetAll()
        viewModel = nil
        hostingController = nil

        // 清除所有子協調器
        childCoordinators.removeAll()
    }

    func restart() {
        print("🔄 FoodRecognitionCoordinator: 重新啟動食物辨識流程")
        stop()
        start()
    }

    // MARK: - Navigation Methods

    /// 顯示相機界面
    func showCamera() {
        print("📷 FoodRecognitionCoordinator: 啟動相機")
        let coordinator = CameraCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }

    /// 顯示食譜詳細信息
    func showRecipeDetail(_ recipe: SuggestRecipeResponse) {
        print("📄 FoodRecognitionCoordinator: 顯示食譜詳細信息")
        let coordinator = RecipeCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.showRecipeDetail(recipe)
    }

    /// 從食物辨識結果導航到食譜生成
    func navigateToRecipeGeneration(with result: FoodRecognitionResponse) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 從食物辨識結果導航到食譜生成")

        guard let primaryFood = result.primaryFood else {
            print("❌ 沒有主要食物，無法生成食譜")
            return
        }

        // 創建食譜建議請求
        let availableIngredients = result.allIngredients.map { ingredient in
            Ingredient(
                name: ingredient.name,
                type: ingredient.type,
                amount: "適量",
                unit: "",
                preparation: ""
            )
        }

        let availableEquipment = result.allEquipment.map { equipment in
            Equipment(
                name: equipment.name,
                type: equipment.type,
                size: "",
                material: "",
                power_source: ""
            )
        }

        let preference = Preference(
            cooking_method: "",
            dietary_restrictions: [],
            serving_size: "2人份"
        )

        let request = SuggestRecipeRequest(
            available_ingredients: availableIngredients,
            available_equipment: availableEquipment,
            preference: preference
        )

        // 導航到食譜生成頁面
        let coordinator = RecipeCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.start() // 使用現有的 start 方法
    }

    /// 使用選中的食材和器具導航到食譜生成
    func navigateToRecipeGeneration(
        ingredients: [String],
        equipment: [String],
        descriptionHint: String? = nil
    ) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 使用選中的食材導航到食譜生成")

        let availableIngredients = ingredients.map { name in
            Ingredient(
                name: name,
                type: "未分類",
                amount: "適量",
                unit: "",
                preparation: ""
            )
        }

        let availableEquipment = equipment.map { name in
            Equipment(
                name: name,
                type: "未分類",
                size: "",
                material: "",
                power_source: ""
            )
        }

        let preference = Preference(
            cooking_method: "",
            dietary_restrictions: [],
            serving_size: "2人份"
        )

        let request = SuggestRecipeRequest(
            available_ingredients: availableIngredients,
            available_equipment: availableEquipment,
            preference: preference
        )

        let coordinator = RecipeCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.start() // 使用現有的 start 方法
    }

    /// 顯示錯誤提示
    func showError(_ error: Error) {
        print("❌ FoodRecognitionCoordinator: 顯示錯誤提示：\(error)")

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
        print("✅ FoodRecognitionCoordinator: 顯示成功提示：\(message)")

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
        print("🏠 FoodRecognitionCoordinator: 導航到首頁")
        navigationController.popToRootViewController(animated: true)
    }

    /// 導航回上一個頁面
    func goBack() {
        print("⬅️ FoodRecognitionCoordinator: 導航回上一個頁面")
        navigationController.popViewController(animated: true)
    }

    func handleLogout() {
        print("FoodRecognitionCoordinator: 開始處理登出")

        // 清除所有子協調器
        print("FoodRecognitionCoordinator: 清除子協調器")
        childCoordinators.removeAll()

        // 通知父協調器處理登出
        if let parentCoordinator = parentCoordinator {
            print("FoodRecognitionCoordinator: 找到父協調器，通知處理登出")
            parentCoordinator.handleLogout()
        } else {
            print("FoodRecognitionCoordinator: 錯誤 - 父協調器為空")
        }
    }
}