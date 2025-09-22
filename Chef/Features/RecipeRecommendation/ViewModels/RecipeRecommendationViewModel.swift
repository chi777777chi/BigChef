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

    // MARK: - Private Properties
    private let recommendationService: RecipeRecommendationService
    private var cancellables = Set<AnyCancellable>()
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
        case .configuring:
            return !availableIngredients.isEmpty && validateForm()
        case .error:
            return !availableIngredients.isEmpty && validateForm()
        default:
            return false
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

    // MARK: - Private Methods

    private func setupObservations() {
        // 監控食材和設備變化來更新狀態
        Publishers.CombineLatest($availableIngredients, $availableEquipment)
            .sink { [weak self] ingredients, equipment in
                self?.updateStateBasedOnInput()
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

    private func validateForm() -> Bool {
        // 檢查必須有食材
        guard !availableIngredients.isEmpty else {
            return false
        }

        // 檢查食材資料完整性
        for ingredient in availableIngredients {
            if ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               ingredient.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }

        // 檢查設備資料完整性（如果有的話）
        for equipment in availableEquipment {
            if equipment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               equipment.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }

        return true
    }

    private func handleRecommendationError(_ error: Error) {
        retryCount += 1

        if let recommendationError = error as? RecipeRecommendationError {
            updateState(.error(recommendationError))
        } else {
            let wrappedError = RecipeRecommendationError.networkError(error.localizedDescription)
            updateState(.error(wrappedError))
        }
    }

    // MARK: - Public Methods - 食材管理

    func addIngredient(_ ingredient: AvailableIngredient) {
        availableIngredients.append(ingredient)
        print("🥬 RecipeRecommendationViewModel: 新增食材 - \(ingredient.name)")
    }

    func removeIngredient(at index: Int) {
        guard index < availableIngredients.count else { return }
        let removedIngredient = availableIngredients[index]
        availableIngredients.remove(at: index)
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
        availableEquipment.append(equipment)
        print("🔧 RecipeRecommendationViewModel: 新增設備 - \(equipment.name)")
    }

    func removeEquipment(at index: Int) {
        guard index < availableEquipment.count else { return }
        let removedEquipment = availableEquipment[index]
        availableEquipment.remove(at: index)
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
        guard canRequestRecommendation else {
            print("❌ RecipeRecommendationViewModel: 無法開始推薦 - 表單驗證失敗")
            return
        }

        print("🍳 RecipeRecommendationViewModel: 開始食譜推薦")
        updateState(.loading)
        retryCount = 0

        do {
            let response = try await recommendationService.recommendRecipe(
                ingredients: availableIngredients,
                equipment: availableEquipment,
                preference: preference
            )

            recommendationResult = response
            updateState(.success(response))
            print("✅ RecipeRecommendationViewModel: 推薦成功")

        } catch {
            print("❌ RecipeRecommendationViewModel: 推薦失敗 - \(error.localizedDescription)")
            handleRecommendationError(error)
        }
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