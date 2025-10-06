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

    // MARK: - State Management
    private var currentRecipeResult: RecipeRecommendationResponse?  // 儲存當前食譜
    private var currentCookCoordinator: CookCoordinator?  // 儲存當前 AR Coordinator

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

    /// 顯示食譜推薦結果的詳細頁面（從辨識流程）
    func showRecipeRecommendationDetail(_ result: RecipeRecommendationResponse) {
        print("📋 FoodRecognitionCoordinator: 顯示推薦結果詳細頁面")

        let detailView = RecipeDetailView(
            recommendationResult: result,
            showNavigationBar: false,  // 使用系統導航欄，保持 tab bar 顯示
            onStartCooking: { [weak self] in
                self?.startARCooking(with: result.recipe, dishName: result.dishName)
            },
            onBack: { [weak self] in
                self?.goBack()
            },
            onFavorite: {
                // TODO: Implement favorite functionality
                print("❤️ 收藏食譜：\(result.dishName)")
            }
        )

        let hostingController = UIHostingController(rootView: detailView)
        hostingController.title = result.dishName
        hostingController.navigationItem.largeTitleDisplayMode = .never
        hostingController.hidesBottomBarWhenPushed = false

        navigationController.pushViewController(hostingController, animated: true)
    }

    /// 啟動 AR 烹飪模式
    func startARCooking(with steps: [RecipeStep], dishName: String = "料理") {
        print("🥽 FoodRecognitionCoordinator: 啟動 AR 烹飪模式 - \(dishName)")

        // 生成辨識 tab 的食譜 ID
        let recipeID = "recognition_\(dishName)"
        print("📌 FoodRecognitionCoordinator: 辨識食譜 ID - \(recipeID)")

        let cookCoordinator = CookCoordinator(
            navigationController: navigationController,
            parentCoordinator: self
        )
        cookCoordinator.onComplete = { [weak self] in
            // 烹飪完成後，返回到首頁（tab bar 的根頁面）
            self?.navigationController.popToRootViewController(animated: true)

            // 清除 AR Coordinator 引用
            self?.currentCookCoordinator = nil
        }

        // 儲存當前 CookCoordinator
        currentCookCoordinator = cookCoordinator

        childCoordinators.append(cookCoordinator)

        // TODO: 將 recipeID 傳遞給 CookCoordinator，讓它在載入動畫時註冊
        // 目前先使用現有的 start 方法
        cookCoordinator.start(with: steps, dishName: dishName)

        // 註記：AR 動畫會在 CookViewController 內部載入
        // 我們需要修改 Animation 類別來支援註冊機制
        print("⚠️ AR 動畫註冊將在首次載入時自動完成（食譜ID: \(recipeID)）")
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
                self?.generateAndShowRecipe(
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

    /// 生成食譜並直接顯示詳細頁面（不經過推薦頁面）
    private func generateAndShowRecipe(
        ingredients: [String],
        equipment: [String],
        recognizedFoodName: String?
    ) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 開始生成食譜")
        print("  辨識食物：\(recognizedFoodName ?? "未知")")
        print("  確認食材：\(ingredients)")
        print("  確認器具：\(equipment)")

        // ⚠️ 檢查是否有舊的食譜，如果有則清除相關資源
        if let oldRecipe = currentRecipeResult {
            print("🗑️ FoodRecognitionCoordinator: 偵測到舊食譜，準備覆蓋")
            print("   舊食譜：\(oldRecipe.dishName)")
            clearOldRecipeResources()
        }

        // 顯示載入指示器
        showLoadingIndicator()

        // 使用 RecipeRecommendationService 生成食譜
        let service = RecipeRecommendationService()

        let availableIngredients = ingredients.map { ingredient in
            AvailableIngredient(
                name: ingredient,
                type: "食材",
                amount: "適量",
                unit: "",
                preparation: ""
            )
        }

        let availableEquipment = equipment.map { equip in
            AvailableEquipment(
                name: equip,
                type: "器具",
                size: "中等",
                material: "",
                powerSource: "無"
            )
        }

        let preference = RecommendationPreference(
            cookingMethod: recognizedFoodName.map { "製作 \($0)" },
            dietaryRestrictions: [],
            servingSize: "2人份",
            recipeDescription: nil
        )

        Task { @MainActor in
            do {
                let result = try await service.recommendRecipe(
                    ingredients: availableIngredients,
                    equipment: availableEquipment,
                    preference: preference
                )

                hideLoadingIndicator()

                // 儲存新食譜
                self.currentRecipeResult = result
                print("✅ FoodRecognitionCoordinator: 新食譜已儲存 - \(result.dishName)")

                // 直接顯示食譜詳情頁面
                self.showRecipeRecommendationDetail(result)

            } catch {
                hideLoadingIndicator()
                showError(error)
            }
        }
    }

    /// 清除舊食譜的 AR 快取資源（選擇性清除，不影響推薦 tab）
    private func clearOldRecipeResources() {
        guard let oldRecipe = currentRecipeResult else {
            print("ℹ️ FoodRecognitionCoordinator: 沒有舊食譜需要清除")
            return
        }

        print("🧹 FoodRecognitionCoordinator: 開始清除舊食譜資源")
        print("   舊食譜 ID: \(oldRecipe.dishName)")  // 使用 dishName 作為 ID

        // 1. 清除舊的 CookCoordinator（如果還在運行）
        if let oldCookCoordinator = currentCookCoordinator {
            print("   - 移除舊的 CookCoordinator")
            removeChildCoordinator(oldCookCoordinator)
            currentCookCoordinator = nil
        }

        // 2. ✅ 只清除此食譜的 AR 動畫快取（不影響推薦 tab）
        print("   - 清除辨識 tab 食譜的 AR 動畫快取")
        let recipeID = "recognition_\(oldRecipe.dishName)"  // 辨識 tab 前綴
        AnimationModelCache.clearAnimations(forRecipe: recipeID)

        // 3. 清除舊食譜引用
        currentRecipeResult = nil

        print("✅ FoodRecognitionCoordinator: 舊食譜資源清除完成（推薦 tab 快取保留）")
    }

    /// 顯示載入指示器
    private func showLoadingIndicator() {
        let loadingAlert = UIAlertController(
            title: nil,
            message: "正在生成食譜...",
            preferredStyle: .alert
        )

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()

        loadingAlert.view.addSubview(loadingIndicator)
        navigationController.present(loadingAlert, animated: true)
    }

    /// 隱藏載入指示器
    private func hideLoadingIndicator() {
        navigationController.dismiss(animated: true)
    }

    /// 從食物辨識結果導航到食譜生成（已廢棄，保留向後兼容）
    func navigateToRecipeGeneration(with result: FoodRecognitionResponse) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 從食物辨識結果導航到食譜生成（舊方法）")

        // 直接導航到確認頁面
        navigateToIngredientConfirmation(with: result)
    }

    /// 基於辨識食物名稱直接生成食譜（跳過確認步驟）
    func navigateToRecipeGenerationWithFoodName(
        ingredients: [String],
        equipment: [String],
        recognizedFoodName: String? = nil
    ) {
        print("🧑‍🍳 FoodRecognitionCoordinator: 基於辨識食物直接生成食譜（跳過確認）")
        print("  辨識食物：\(recognizedFoodName ?? "未知")")
        print("  食材：\(ingredients)")
        print("  器具：\(equipment)")

        // 直接生成食譜，跳過確認步驟
        generateAndShowRecipe(
            ingredients: ingredients,
            equipment: equipment,
            recognizedFoodName: recognizedFoodName
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