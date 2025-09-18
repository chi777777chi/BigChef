//
//  FoodRecognitionResponse.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import Foundation

// MARK: - 食物辨識回應模型
/// 食物辨識 API 的完整回應結構
struct FoodRecognitionResponse: Codable {
    /// 辨識出的食物清單
    let recognizedFoods: [RecognizedFood]

    enum CodingKeys: String, CodingKey {
        case recognizedFoods = "recognized_foods"
    }

    /// 取得第一個辨識結果（通常是最準確的）
    var primaryFood: RecognizedFood? {
        recognizedFoods.first
    }

    /// 檢查是否有辨識結果
    var hasResults: Bool {
        !recognizedFoods.isEmpty
    }
}

// MARK: - 辨識出的食物模型
/// 單一辨識出的食物資訊
struct RecognizedFood: Codable, Identifiable {
    let id = UUID() // SwiftUI 用的本地 ID
    /// 食物名稱
    let name: String
    /// 食物描述
    let description: String
    /// 可能的食材清單
    let possibleIngredients: [PossibleIngredient]
    /// 可能的設備清單
    let possibleEquipment: [PossibleEquipment]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case possibleIngredients = "possible_ingredients"
        case possibleEquipment = "possible_equipment"
    }

    /// 取得主要食材（排除調料類）
    var mainIngredients: [PossibleIngredient] {
        possibleIngredients.filter { ingredient in
            !["調料", "調味料", "香料"].contains(ingredient.type)
        }
    }

    /// 取得調料類食材
    var seasonings: [PossibleIngredient] {
        possibleIngredients.filter { ingredient in
            ["調料", "調味料", "香料"].contains(ingredient.type)
        }
    }

    /// 取得必需設備（排除可選工具）
    var essentialEquipment: [PossibleEquipment] {
        possibleEquipment.filter { equipment in
            ["鍋具", "爐具", "主要工具"].contains(equipment.type)
        }
    }
}

// MARK: - 可能的食材模型
/// 辨識結果中的食材資訊
struct PossibleIngredient: Codable, Identifiable {
    let id = UUID() // SwiftUI 用的本地 ID
    /// 食材名稱
    let name: String
    /// 食材類型（如：主食、蛋類、蔬菜等）
    let type: String

    enum CodingKeys: String, CodingKey {
        case name
        case type
    }

    /// 轉換為專案中的 Ingredient 模型
    func toIngredient() -> Ingredient {
        return Ingredient(
            name: name,
            type: type,
            amount: "", // 預設空值，後續使用者可以填入
            unit: "",   // 預設空值，後續使用者可以填入
            preparation: "" // 預設空值，後續使用者可以填入
        )
    }
}

// MARK: - 可能的設備模型
/// 辨識結果中的設備資訊
struct PossibleEquipment: Codable, Identifiable {
    let id = UUID() // SwiftUI 用的本地 ID
    /// 設備名稱
    let name: String
    /// 設備類型（如：鍋具、工具等）
    let type: String

    enum CodingKeys: String, CodingKey {
        case name
        case type
    }

    /// 轉換為專案中的 Equipment 模型
    func toEquipment() -> Equipment {
        return Equipment(
            name: name,
            type: type,
            size: "",        // 預設空值，後續使用者可以填入
            material: "",    // 預設空值，後續使用者可以填入
            power_source: "" // 預設空值，後續使用者可以填入
        )
    }
}

// MARK: - Response Extensions
extension FoodRecognitionResponse {

    /// 將所有辨識結果轉換為 Ingredient 清單
    var allIngredients: [Ingredient] {
        recognizedFoods.flatMap { food in
            food.possibleIngredients.map { $0.toIngredient() }
        }
    }

    /// 將所有辨識結果轉換為 Equipment 清單
    var allEquipment: [Equipment] {
        recognizedFoods.flatMap { food in
            food.possibleEquipment.map { $0.toEquipment() }
        }
    }

    /// 取得所有食物名稱
    var foodNames: [String] {
        recognizedFoods.map { $0.name }
    }

    /// 產生辨識結果摘要
    var summary: String {
        if recognizedFoods.isEmpty {
            return "未辨識出任何食物"
        }

        let foodCount = recognizedFoods.count
        let ingredientCount = allIngredients.count
        let equipmentCount = allEquipment.count

        let primaryFoodName = recognizedFoods.first?.name ?? "未知食物"

        return "辨識出 \(foodCount) 種食物（主要：\(primaryFoodName)），包含 \(ingredientCount) 種食材和 \(equipmentCount) 種設備"
    }
}