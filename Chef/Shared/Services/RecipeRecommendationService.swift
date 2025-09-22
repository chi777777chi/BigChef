//
//  RecipeRecommendationService.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import Foundation

protocol RecipeRecommendationServiceProtocol {
    func recommendRecipe(
        ingredients: [AvailableIngredient],
        equipment: [AvailableEquipment],
        preference: RecommendationPreference
    ) async throws -> RecipeRecommendationResponse
}

class RecipeRecommendationService: RecipeRecommendationServiceProtocol {

    // MARK: - Private Properties
    private let maxRetryCount = 3
    private let timeoutInterval: TimeInterval = 30.0

    // MARK: - Public Methods

    func recommendRecipe(
        ingredients: [AvailableIngredient],
        equipment: [AvailableEquipment],
        preference: RecommendationPreference
    ) async throws -> RecipeRecommendationResponse {

        // 驗證輸入參數
        try validateInputs(ingredients: ingredients, equipment: equipment)

        // 轉換資料格式以配合現有的 API
        let convertedIngredients = convertToIngredients(from: ingredients)
        let convertedEquipment = convertToEquipment(from: equipment)
        let convertedPreference = convertToPreference(from: preference)

        // 建立請求
        let request = SuggestRecipeRequest(
            available_ingredients: convertedIngredients,
            available_equipment: convertedEquipment,
            preference: convertedPreference
        )

        // 記錄請求資訊
        logRequest(ingredients: ingredients, equipment: equipment, preference: preference)

        do {
            // 使用現有的 RecipeService.generateRecipe 方法
            let response = try await RecipeService.generateRecipe(using: request)

            // 轉換回應格式
            let recommendationResponse = convertToRecommendationResponse(from: response)

            // 記錄成功結果
            logSuccess(response: recommendationResponse)

            return recommendationResponse

        } catch {
            // 記錄錯誤
            logError(error)

            // 轉換錯誤類型
            throw convertToRecommendationError(error)
        }
    }

    // MARK: - Private Methods

    private func validateInputs(
        ingredients: [AvailableIngredient],
        equipment: [AvailableEquipment]
    ) throws {
        // 檢查必須有食材
        guard !ingredients.isEmpty else {
            throw RecipeRecommendationError.noIngredientsProvided
        }

        // 檢查食材資料完整性
        for (index, ingredient) in ingredients.enumerated() {
            guard !ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RecipeRecommendationError.invalidIngredientData("第 \(index + 1) 項食材名稱不能為空")
            }

            guard !ingredient.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RecipeRecommendationError.invalidIngredientData("第 \(index + 1) 項食材類型不能為空")
            }
        }

        // 檢查設備資料完整性（如果有的話）
        for (index, equipment) in equipment.enumerated() {
            guard !equipment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RecipeRecommendationError.invalidEquipmentData("第 \(index + 1) 項設備名稱不能為空")
            }
        }
    }

    // MARK: - Data Conversion Methods

    private func convertToIngredients(from availableIngredients: [AvailableIngredient]) -> [Ingredient] {
        return availableIngredients.map { available in
            Ingredient(
                name: available.name,
                type: available.type,
                amount: available.amount,
                unit: available.unit,
                preparation: available.preparation
            )
        }
    }

    private func convertToEquipment(from availableEquipment: [AvailableEquipment]) -> [Equipment] {
        return availableEquipment.map { available in
            Equipment(
                name: available.name,
                type: available.type,
                size: available.size,
                material: available.material,
                power_source: available.powerSource
            )
        }
    }

    private func convertToPreference(from recommendation: RecommendationPreference) -> Preference {
        return Preference(
            cooking_method: recommendation.cookingMethod ?? "一般烹調",
            dietary_restrictions: recommendation.dietaryRestrictions ?? [],
            serving_size: recommendation.servingSize ?? "1人份"
        )
    }

    private func convertToRecommendationResponse(from response: SuggestRecipeResponse) -> RecipeRecommendationResponse {
        return RecipeRecommendationResponse(
            dishName: response.dish_name,
            dishDescription: response.dish_description,
            ingredients: response.ingredients,
            equipment: response.equipment,
            recipe: response.recipe
        )
    }

    private func convertToRecommendationError(_ error: Error) -> RecipeRecommendationError {
        // Check for NetworkError from RecipeService first
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                return .networkError("無效的請求地址")
            case .invalidResponse:
                return .networkError("伺服器回應無效")
            case .httpError(let code):
                return .apiError("API 錯誤 (\(code))")
            case .noData:
                return .networkError("沒有收到資料")
            case .unknown(let message):
                return .networkError(message)
            }
        }

        return .networkError(error.localizedDescription)
    }

    // MARK: - Logging Methods

    private func logRequest(
        ingredients: [AvailableIngredient],
        equipment: [AvailableEquipment],
        preference: RecommendationPreference
    ) {
        print("🍳 RecipeRecommendationService: 開始食譜推薦")
        print("📋 食材數量: \(ingredients.count)")
        print("🔧 設備數量: \(equipment.count)")
        print("⚙️ 烹飪方式: \(preference.cookingMethod ?? "未指定")")
        print("🥗 飲食限制: \(preference.dietaryRestrictions?.joined(separator: ", ") ?? "無")")
        print("👥 份量: \(preference.servingSize ?? "未指定")")

        // 詳細記錄食材
        for (index, ingredient) in ingredients.enumerated() {
            print("🥬 食材 \(index + 1): \(ingredient.name) (\(ingredient.type)) - \(ingredient.amount)\(ingredient.unit)")
        }

        // 詳細記錄設備
        for (index, equipment) in equipment.enumerated() {
            print("🔧 設備 \(index + 1): \(equipment.name) (\(equipment.type))")
        }
    }

    private func logSuccess(response: RecipeRecommendationResponse) {
        print("✅ RecipeRecommendationService: 推薦成功")
        print("🍽️ 推薦菜名: \(response.dishName)")
        print("📝 菜品描述: \(response.dishDescription)")
        print("📊 步驟數量: \(response.totalSteps)")
        print("⏱️ 預估時間: \(response.totalEstimatedTime)")
    }

    private func logError(_ error: Error) {
        print("❌ RecipeRecommendationService: 推薦失敗")
        print("🔍 錯誤詳情: \(error.localizedDescription)")

        if let networkError = error as? NetworkError {
            print("🌐 網路錯誤類型: \(networkError)")
        }
    }
}

// MARK: - Recipe Recommendation Error

enum RecipeRecommendationError: LocalizedError, Equatable {
    case noIngredientsProvided
    case invalidIngredientData(String)
    case invalidEquipmentData(String)
    case networkError(String)
    case apiError(String)
    case invalidResponse(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .noIngredientsProvided:
            return "請至少新增一項食材"
        case .invalidIngredientData(let message):
            return "食材資料錯誤：\(message)"
        case .invalidEquipmentData(let message):
            return "設備資料錯誤：\(message)"
        case .networkError(let message):
            return "網路錯誤：\(message)"
        case .apiError(let message):
            return "推薦失敗：\(message)"
        case .invalidResponse(let message):
            return "回應格式錯誤：\(message)"
        case .validationFailed(let message):
            return "驗證失敗：\(message)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .apiError, .invalidResponse:
            return true
        case .noIngredientsProvided, .invalidIngredientData, .invalidEquipmentData, .validationFailed:
            return false
        }
    }
}