//
//  RecipeRecommendationResponse.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import Foundation

// MARK: - Recipe Recommendation Response Model
// 重用現有的 Ingredient, Equipment, RecipeStep, Action 模型

struct RecipeRecommendationResponse: Codable {
    let dishName: String
    let dishDescription: String
    let ingredients: [Ingredient]
    let equipment: [Equipment]
    let recipe: [RecipeStep]

    enum CodingKeys: String, CodingKey {
        case dishName = "dish_name"
        case dishDescription = "dish_description"
        case ingredients, equipment, recipe
    }
}

// MARK: - Extensions for convenience

extension RecipeRecommendationResponse {
    static func sample() -> RecipeRecommendationResponse {
        let sampleIngredient = Ingredient(
            name: "蛋",
            type: "蛋類",
            amount: "2",
            unit: "顆",
            preparation: "打散"
        )

        let sampleEquipment = Equipment(
            name: "平底鍋",
            type: "鍋具",
            size: "小型",
            material: "不沾",
            power_source: "電"
        )

        let sampleAction = Action(
            action: "煎",
            tool_required: "平底鍋",
            material_required: ["蛋"],
            time_minutes: 3,
            instruction_detail: "蛋液均勻攤平"
        )

        let sampleStep = RecipeStep(
            step_number: 1,
            title: "煎蛋",
            description: "將蛋液倒入鍋中，小火煎熟。",
            actions: [sampleAction],
            estimated_total_time: "3分鐘",
            temperature: "小火",
            warnings: nil,
            notes: "可加鹽調味"
        )

        return RecipeRecommendationResponse(
            dishName: "煎蛋",
            dishDescription: "簡單快速的早餐料理",
            ingredients: [sampleIngredient],
            equipment: [sampleEquipment],
            recipe: [sampleStep]
        )
    }

    // Helper computed properties
    var totalSteps: Int {
        recipe.count
    }

    var totalEstimatedTime: String {
        let totalMinutes = recipe.compactMap { step in
            step.actions.reduce(0) { $0 + $1.time_minutes }
        }.reduce(0, +)

        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)小時\(minutes)分鐘" : "\(hours)小時"
        } else {
            return "\(totalMinutes)分鐘"
        }
    }

    var allIngredientNames: [String] {
        ingredients.map { $0.name }
    }

    var allEquipmentNames: [String] {
        equipment.map { $0.name }
    }
}