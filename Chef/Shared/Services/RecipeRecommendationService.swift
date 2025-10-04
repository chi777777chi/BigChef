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
        // 只檢查必須有食材
        guard !ingredients.isEmpty else {
            throw RecipeRecommendationError.noIngredientsProvided
        }

        // 移除所有防呆檢查，讓使用者自由輸入
    }

    // MARK: - Validation Helper Methods

    private func isLikelyIngredientName(_ name: String) -> Bool {
        let commonIngredients = [
            // 肉類
            "牛排", "豬肉", "雞肉", "魚", "蝦", "蟹", "羊肉", "鴨肉", "火腿", "香腸",
            // 蔬菜
            "白菜", "高麗菜", "花椰菜", "胡蘿蔔", "洋蔥", "蒜", "薑", "蔥", "韭菜", "菠菜",
            "番茄", "馬鈴薯", "地瓜", "玉米", "豆腐", "豆芽", "青椒", "茄子", "黃瓜",
            // 主食
            "米", "麵條", "麵包", "饅頭", "水餃", "包子", "年糕", "麵粉",
            // 蛋奶類
            "蛋", "雞蛋", "牛奶", "起司", "奶油", "優格",
            // 調料
            "鹽", "糖", "醋", "醬油", "味精", "胡椒", "辣椒", "香菜", "芝麻"
        ]

        let lowercaseName = name.lowercased()
        return commonIngredients.contains { ingredient in
            lowercaseName.contains(ingredient.lowercased())
        }
    }

    private func isLikelyEquipmentName(_ name: String) -> Bool {
        let commonEquipment = [
            // 鍋具
            "平底鍋", "炒鍋", "湯鍋", "蒸鍋", "壓力鍋", "電鍋", "砂鍋", "不沾鍋", "鐵鍋", "不鏽鋼鍋",
            // 刀具
            "菜刀", "水果刀", "麵包刀", "剁刀", "削皮刀", "刨刀",
            // 電器
            "微波爐", "烤箱", "電磁爐", "瓦斯爐", "攪拌機", "果汁機", "咖啡機", "電熱水壺", "烤土司機",
            "氣炸鍋", "電子鍋", "慢燉鍋", "豆漿機",
            // 餐具和工具
            "鍋鏟", "湯勺", "漏勺", "夾子", "開瓶器", "削皮器", "磨刀器", "砧板", "量杯", "打蛋器",
            "篩子", "漏斗", "保鮮盒", "烘焙紙"
        ]

        let lowercaseName = name.lowercased()

        // 檢查是否包含常見器具關鍵字
        let equipmentKeywords = ["鍋", "刀", "機", "爐", "器", "杯", "盤", "碗", "鏟", "勺", "夾", "板"]
        let hasEquipmentKeyword = equipmentKeywords.contains { keyword in
            lowercaseName.contains(keyword)
        }

        // 檢查是否為常見器具名稱
        let isCommonEquipment = commonEquipment.contains { equipment in
            lowercaseName.contains(equipment.lowercased()) || equipment.lowercased().contains(lowercaseName)
        }

        return hasEquipmentKeyword || isCommonEquipment
    }

    // MARK: - Data Conversion Methods

    private func convertToIngredients(from availableIngredients: [AvailableIngredient]) -> [Ingredient] {
        return availableIngredients.map { available in
            // 如果份量是「未知」或「適量」，傳空字串讓 AI 根據 serving_size 決定
            let (amount, unit) = normalizeAmountAndUnit(amount: available.amount, unit: available.unit)

            return Ingredient(
                name: available.name,
                type: available.type,
                amount: amount,
                unit: unit,
                preparation: available.preparation
            )
        }
    }

    private func normalizeAmountAndUnit(amount: String, unit: String) -> (String, String) {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 檢查是否為「未知」或「適量」
        let isUnknownAmount = trimmedAmount == "適量" ||
                              trimmedAmount == "适量" ||
                              trimmedAmount == "未知" ||
                              trimmedAmount == "unknown" ||
                              trimmedAmount.isEmpty

        if isUnknownAmount {
            // 返回空字串，讓 AI 根據 serving_size 決定份量
            return ("", "")
        } else {
            // 有具體份量，直接使用
            return (amount, unit)
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
            serving_size: recommendation.servingSize ?? "1人份",
            recipe_description: recommendation.recipeDescription
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
                // 針對特定HTTP錯誤碼提供更詳細的訊息
                switch code {
                case 400:
                    return .validationFailed("請求資料格式錯誤，請檢查輸入的食材和器具名稱是否正確")
                case 422:
                    return .validationFailed("輸入資料不符合要求，請確認食材和器具資訊填寫正確")
                case 500:
                    return .apiError("伺服器處理錯誤，可能是輸入的器具或食材資訊不正確，請檢查並重新輸入")
                case 502, 503:
                    return .networkError("伺服器暫時無法服務，請稍後再試")
                case 504:
                    return .networkError("請求超時，請稍後再試")
                default:
                    return .apiError("API 錯誤 (\(code))")
                }
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