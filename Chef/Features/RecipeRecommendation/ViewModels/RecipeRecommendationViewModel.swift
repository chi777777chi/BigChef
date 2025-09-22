//
//  RecipeRecommendationViewModel.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RecipeRecommendationViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var state: RecipeRecommendationStatus = .idle
    @Published var availableIngredients: [AvailableIngredient] = []
    @Published var availableEquipment: [AvailableEquipment] = []
    @Published var preference: RecommendationPreference
    @Published var recommendationResult: RecipeRecommendationResponse?
    @Published var errorMessage: String?
    @Published var retryCount = 0
    @Published var isFormValid: Bool = false
    @Published var validationErrors: [String] = []

    // MARK: - Private Properties
    private let recommendationService: RecipeRecommendationService
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    private let maxRetryCount = 3

    // MARK: - Computed Properties

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var hasError: Bool {
        if case .error = state { return true }
        return false
    }

    var hasResult: Bool {
        if case .success = state { return true }
        return false
    }

    var canRequestRecommendation: Bool {
        switch state {
        case .configuring, .idle:
            return isFormValid
        case .error:
            return isFormValid
        case .loading:
            return false
        case .success:
            return true // Allow re-recommendation from success state
        }
    }

    var canRetry: Bool {
        if case .error(let error) = state {
            return error.isRetryable && retryCount < maxRetryCount
        }
        return false
    }

    var currentError: RecipeRecommendationError? {
        if case .error(let error) = state {
            return error
        }
        return nil
    }

    var ingredientTypes: [String] {
        ["主食", "蔬菜", "肉類", "蛋類", "海鮮", "調料", "其他"]
    }

    var equipmentTypes: [String] {
        ["鍋具", "刀具", "電器", "餐具", "其他"]
    }

    var cookingMethods: [String] {
        ["一般烹調", "煎", "炒", "煮", "蒸", "炸", "烤", "燉", "涼拌"]
    }

    var dietaryRestrictions: [String] {
        ["無", "素食", "純素", "無麩質", "無乳製品", "低糖", "低鈉", "低脂"]
    }

    var servingSizes: [String] {
        ["1人份", "2人份", "3人份", "4人份", "5人份", "6人份以上"]
    }

    // MARK: - Initializer

    init(recommendationService: RecipeRecommendationService = RecipeRecommendationService()) {
        self.recommendationService = recommendationService
        self.preference = RecommendationPreference(
            cookingMethod: "一般烹調",
            dietaryRestrictions: [],
            servingSize: "1人份"
        )
        setupObservations()
    }

    deinit {
        currentTask?.cancel()
        cancellables.removeAll()
    }

    // MARK: - Public Methods - Task Management

    func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil

        if case .loading = state {
            updateState(.configuring)
        }
    }

    // MARK: - Private Methods

    private func setupObservations() {
        // 監控食材和設備變化來更新狀態和驗證表單
        Publishers.CombineLatest3($availableIngredients, $availableEquipment, $preference)
            .sink { [weak self] ingredients, equipment, preference in
                self?.updateStateBasedOnInput()
                self?.validateFormData()
            }
            .store(in: &cancellables)
    }

    private func updateStateBasedOnInput() {
        if availableIngredients.isEmpty {
            updateState(.idle)
        } else {
            if case .idle = state {
                updateState(.configuring)
            }
        }
    }

    private func updateState(_ newState: RecipeRecommendationStatus) {
        state = newState

        // 清除錯誤訊息（除非是錯誤狀態）
        if case .error(let error) = newState {
            errorMessage = error.localizedDescription
        } else {
            errorMessage = nil
        }
    }

    private func validateFormData() {
        validationErrors.removeAll()

        // 檢查必須有食材
        guard !availableIngredients.isEmpty else {
            validationErrors.append("請至少新增一種食材")
            isFormValid = false
            return
        }

        // 檢查食材資料完整性
        for (index, ingredient) in availableIngredients.enumerated() {
            if ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("食材 \(index + 1): 請輸入食材名稱")
            }
            if ingredient.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("食材 \(index + 1): 請選擇食材類型")
            }
            if ingredient.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("食材 \(index + 1): 請輸入數量")
            }
        }

        // 檢查設備資料完整性（如果有的話）
        for (index, equipment) in availableEquipment.enumerated() {
            if equipment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("設備 \(index + 1): 請輸入設備名稱")
            }
            if equipment.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("設備 \(index + 1): 請選擇設備類型")
            }
        }

        // 檢查偏好設定
        if let cookingMethod = preference.cookingMethod, cookingMethod.isEmpty {
            validationErrors.append("請選擇烹飪方式")
        }

        if let servingSize = preference.servingSize, servingSize.isEmpty {
            validationErrors.append("請選擇份量")
        }

        isFormValid = validationErrors.isEmpty
    }

    private func validateForm() -> Bool {
        validateFormData()
        return isFormValid
    }

    private func handleRecommendationError(_ error: Error) {
        retryCount += 1

        let recommendationError: RecipeRecommendationError

        if let recError = error as? RecipeRecommendationError {
            recommendationError = recError
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                recommendationError = .networkError("請檢查網路連線")
            case .timedOut:
                recommendationError = .networkError("請求超時，請稍後再試")
            case .cannotFindHost:
                recommendationError = .networkError("無法連接到伺服器")
            default:
                recommendationError = .networkError("網路錯誤：\(urlError.localizedDescription)")
            }
        } else {
            recommendationError = .networkError("未知錯誤：\(error.localizedDescription)")
        }

        updateState(.error(recommendationError))
    }

    // MARK: - Public Methods - 食材管理

    func addIngredient(_ ingredient: AvailableIngredient) {
        withAnimation(.easeInOut) {
            availableIngredients.append(ingredient)
        }
        print("🥬 RecipeRecommendationViewModel: 新增食材 - \(ingredient.name)")
    }

    func removeIngredient(at index: Int) {
        guard index < availableIngredients.count else { return }
        let removedIngredient = availableIngredients[index]
        withAnimation(.easeInOut) {
            availableIngredients.remove(at: index)
        }
        print("🗑️ RecipeRecommendationViewModel: 移除食材 - \(removedIngredient.name)")
    }

    func updateIngredient(at index: Int, with ingredient: AvailableIngredient) {
        guard index < availableIngredients.count else { return }
        availableIngredients[index] = ingredient
        print("✏️ RecipeRecommendationViewModel: 更新食材 - \(ingredient.name)")
    }

    func createEmptyIngredient() -> AvailableIngredient {
        return AvailableIngredient(
            name: "",
            type: ingredientTypes.first ?? "其他",
            amount: "適量",
            unit: "",
            preparation: ""
        )
    }

    // MARK: - Public Methods - 設備管理

    func addEquipment(_ equipment: AvailableEquipment) {
        withAnimation(.easeInOut) {
            availableEquipment.append(equipment)
        }
        print("🔧 RecipeRecommendationViewModel: 新增設備 - \(equipment.name)")
    }

    func removeEquipment(at index: Int) {
        guard index < availableEquipment.count else { return }
        let removedEquipment = availableEquipment[index]
        withAnimation(.easeInOut) {
            availableEquipment.remove(at: index)
        }
        print("🗑️ RecipeRecommendationViewModel: 移除設備 - \(removedEquipment.name)")
    }

    func updateEquipment(at index: Int, with equipment: AvailableEquipment) {
        guard index < availableEquipment.count else { return }
        availableEquipment[index] = equipment
        print("✏️ RecipeRecommendationViewModel: 更新設備 - \(equipment.name)")
    }

    func createEmptyEquipment() -> AvailableEquipment {
        return AvailableEquipment(
            name: "",
            type: equipmentTypes.first ?? "其他",
            size: "中等",
            material: "",
            powerSource: ""
        )
    }

    // MARK: - Public Methods - 偏好設定管理

    func updatePreference(_ newPreference: RecommendationPreference) {
        preference = newPreference
        print("⚙️ RecipeRecommendationViewModel: 更新偏好設定")
        print("   烹飪方式: \(newPreference.cookingMethod ?? "未指定")")
        print("   飲食限制: \(newPreference.dietaryRestrictions?.joined(separator: ", ") ?? "無")")
        print("   份量: \(newPreference.servingSize ?? "未指定")")
    }

    func updateCookingMethod(_ method: String) {
        preference = RecommendationPreference(
            cookingMethod: method,
            dietaryRestrictions: preference.dietaryRestrictions,
            servingSize: preference.servingSize
        )
    }

    func updateDietaryRestrictions(_ restrictions: [String]) {
        preference = RecommendationPreference(
            cookingMethod: preference.cookingMethod,
            dietaryRestrictions: restrictions,
            servingSize: preference.servingSize
        )
    }

    func updateServingSize(_ size: String) {
        preference = RecommendationPreference(
            cookingMethod: preference.cookingMethod,
            dietaryRestrictions: preference.dietaryRestrictions,
            servingSize: size
        )
    }

    // MARK: - Public Methods - 推薦流程

    func startRecommendation() async {
        // Cancel any existing request
        currentTask?.cancel()

        guard canRequestRecommendation else {
            print("❌ RecipeRecommendationViewModel: 無法開始推薦 - 表單驗證失敗")
            if !isFormValid {
                updateState(.error(.validationFailed("請檢查表單輸入")))
            }
            return
        }

        print("🍳 RecipeRecommendationViewModel: 開始食譜推薦")
        updateState(.loading)
        if case .success = state {
            // Don't reset retry count if re-recommending from success state
        } else {
            retryCount = 0
        }

        currentTask = Task {
            do {
                let response = try await recommendationService.recommendRecipe(
                    ingredients: availableIngredients,
                    equipment: availableEquipment,
                    preference: preference
                )

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    recommendationResult = response
                    updateState(.success(response))
                    print("✅ RecipeRecommendationViewModel: 推薦成功")
                }

            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    print("❌ RecipeRecommendationViewModel: 推薦失敗 - \(error.localizedDescription)")
                    handleRecommendationError(error)
                }
            }
        }

        await currentTask?.value
        currentTask = nil
    }

    func retryRecommendation() async {
        guard canRetry else {
            print("❌ RecipeRecommendationViewModel: 無法重試推薦")
            return
        }

        print("🔄 RecipeRecommendationViewModel: 重試推薦 (第 \(retryCount + 1) 次)")
        await startRecommendation()
    }

    func resetToInitial() {
        print("🔄 RecipeRecommendationViewModel: 重置到初始狀態")
        availableIngredients.removeAll()
        availableEquipment.removeAll()
        preference = RecommendationPreference(
            cookingMethod: "一般烹調",
            dietaryRestrictions: [],
            servingSize: "1人份"
        )
        recommendationResult = nil
        retryCount = 0
        updateState(.idle)
    }

    func resetToConfiguring() {
        print("🔄 RecipeRecommendationViewModel: 重置到配置狀態")
        recommendationResult = nil
        retryCount = 0

        if !availableIngredients.isEmpty {
            updateState(.configuring)
        } else {
            updateState(.idle)
        }
    }
}