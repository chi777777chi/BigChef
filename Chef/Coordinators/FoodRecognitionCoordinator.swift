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
        hostingController.hidesBottomBarWhenPushed = false

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

    /// 從食物辨識結果直接導航到食材確認頁面（簡化流程）
    func navigateToIngredientConfirmation(with result: FoodRecognitionResponse) {
        print("🔍 FoodRecognitionCoordinator: 直接導航到食材確認頁面，跳過中間步驟")
        print("   辨識出的食物：\(result.recognizedFoods.map { $0.name }.joined(separator: ", "))")
        print("   辨識出的食材：\(result.recognizedFoods.flatMap { $0.possibleIngredients }.count) 個")
        print("   辨識出的器具：\(result.recognizedFoods.flatMap { $0.possibleEquipment }.count) 個")

        let confirmationView = IngredientConfirmationView(
            recognitionResult: result,
            onConfirm: { [weak self] selectedIngredients, selectedEquipment in
                // 獲取辨識出的主要食物名稱，用於生成特定食譜
                let recognizedFoodName = result.recognizedFoods.first?.name
                self?.navigateToRecipeGenerationWithFoodName(
                    ingredients: selectedIngredients,
                    equipment: selectedEquipment,
                    recognizedFoodName: recognizedFoodName
                )
            },
            onCancel: { [weak self] in
                self?.goBack()
            }
        )
        .environmentObject(self)

        let hostingController = UIHostingController(rootView: confirmationView)
        hostingController.title = "確認食材器具"
        hostingController.navigationItem.largeTitleDisplayMode = .never
        hostingController.hidesBottomBarWhenPushed = false

        navigationController.pushViewController(hostingController, animated: true)
    }

    /// 從食物辨識結果導航到食譜生成（已廢棄，保留向後兼容）
    func navigateToRecipeGeneration(with result: FoodRecognitionResponse) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 從食物辨識結果導航到食譜生成（舊方法）")

        // 直接導航到確認頁面
        navigateToIngredientConfirmation(with: result)
    }


    /// 基於辨識食物名稱導航到食譜推薦頁面（新的主要方法）
    func navigateToRecipeGenerationWithFoodName(
        ingredients: [String],
        equipment: [String],
        recognizedFoodName: String? = nil
    ) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 基於辨識食物生成食譜")
        print("  辨識食物：\(recognizedFoodName ?? "未知")")
        print("  確認食材：\(ingredients)")
        print("  確認器具：\(equipment)")

        // 直接使用 RecipeRecommendationCoordinator
        let recipeRecommendationCoordinator = RecipeRecommendationCoordinator(
            navigationController: navigationController,
            parentCoordinator: parentCoordinator
        )

        addChildCoordinator(recipeRecommendationCoordinator)

        // 使用預填資料啟動，包含辨識食物名稱
        recipeRecommendationCoordinator.startWithPrefillData(
            ingredients: ingredients,
            equipment: equipment,
            recognizedFoodName: recognizedFoodName
        )
    }

    /// 使用選中的食材和器具導航到食譜推薦頁面（舊方法，保留向後兼容）
    func navigateToRecipeGeneration(
        ingredients: [String],
        equipment: [String],
        descriptionHint: String? = nil
    ) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 直接導航到食譜推薦（舊方法）")

        // 使用新方法
        navigateToRecipeGenerationWithFoodName(
            ingredients: ingredients,
            equipment: equipment,
            recognizedFoodName: nil
        )
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