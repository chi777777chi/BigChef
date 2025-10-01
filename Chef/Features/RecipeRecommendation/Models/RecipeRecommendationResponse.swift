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
        // 解析每個步驟的 estimated_total_time 並加總
        let totalMinutes = recipe.reduce(0) { total, step in
            total + parseTimeToMinutes(step.estimated_total_time)
        }

        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)小時\(minutes)分鐘" : "\(hours)小時"
        } else {
            return "\(totalMinutes)分鐘"
        }
    }

    /// 解析時間字串（如「3分鐘」、「1小時30分鐘」）為分鐘數
    private func parseTimeToMinutes(_ timeString: String) -> Int {
        var totalMinutes = 0

        // 匹配「X小時」或「X 小時」
        if let hoursMatch = timeString.range(of: #"(\d+)\s*小時"#, options: .regularExpression) {
            let hoursString = timeString[hoursMatch].replacingOccurrences(of: "小時", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let hours = Int(hoursString) {
                totalMinutes += hours * 60
            }
        }

        // 匹配「X分鐘」或「X 分鐘」或「X分」
        if let minutesMatch = timeString.range(of: #"(\d+)\s*分"#, options: .regularExpression) {
            let minutesString = timeString[minutesMatch].replacingOccurrences(of: "分鐘", with: "")
                .replacingOccurrences(of: "分", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let minutes = Int(minutesString) {
                totalMinutes += minutes
            }
        }

        // 如果沒有匹配到任何格式，嘗試直接解析數字（假設是分鐘）
        if totalMinutes == 0 {
            let numberString = timeString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let minutes = Int(numberString), !numberString.isEmpty {
                totalMinutes = minutes
            }
        }

        return totalMinutes
    }

    var allIngredientNames: [String] {
        ingredients.map { $0.name }
    }

    var allEquipmentNames: [String] {
        equipment.map { $0.name }
    }
}