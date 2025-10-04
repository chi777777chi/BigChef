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
        print("⏱️ 開始計算總時間，共 \(recipe.count) 個步驟")

        // 解析每個步驟的 estimated_total_time 並加總
        let totalMinutes = recipe.reduce(0) { total, step in
            var stepMinutes = parseTimeToMinutes(step.estimated_total_time)

            // 如果步驟時間為 0（可能是"未知"或無法解析），則計算該步驟所有 actions 的時間總和
            if stepMinutes == 0 && !step.actions.isEmpty {
                stepMinutes = calculateStepTimeFromActions(step.actions)
                print("  步驟 \(step.step_number): \(step.estimated_total_time) → 自動計算 = \(stepMinutes) 分鐘 (來自 \(step.actions.count) 個子步驟)")
            } else {
                print("  步驟 \(step.step_number): \(step.estimated_total_time) = \(stepMinutes) 分鐘")
            }

            return total + stepMinutes
        }

        print("⏱️ 總計時間: \(totalMinutes) 分鐘")

        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)小時\(minutes)分鐘" : "\(hours)小時"
        } else {
            return "\(totalMinutes)分鐘"
        }
    }

    /// 從 actions 計算步驟時間，智能判斷是秒數還是分鐘
    private func calculateStepTimeFromActions(_ actions: [Action]) -> Int {
        let totalTime = actions.reduce(0) { sum, action in
            sum + action.time_minutes
        }

        // 智能判斷：如果總時間超過 120，很可能是秒數（烹飪步驟很少超過 2 小時）
        // 如果總時間 <= 120，假設已經是分鐘
        if totalTime > 120 {
            // 判斷為秒數，轉換為分鐘
            let minutes = Int(round(Double(totalTime) / 60.0))
            print("    → 判斷為秒數: \(totalTime) 秒 = \(minutes) 分鐘")
            return minutes
        } else {
            // 判斷為分鐘，直接使用
            print("    → 判斷為分鐘: \(totalTime) 分鐘")
            return totalTime
        }
    }

    /// 解析時間字串（如「3分鐘」、「1小時30分鐘」、「0.5分鐘」）為分鐘數
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

        // 匹配「X分鐘」或「X 分鐘」或「X分」（支持小數點，如「0.5分鐘」）
        if let minutesMatch = timeString.range(of: #"(\d+\.?\d*)\s*分"#, options: .regularExpression) {
            let minutesString = timeString[minutesMatch]
                .replacingOccurrences(of: "分鐘", with: "")
                .replacingOccurrences(of: "分", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let minutes = Double(minutesString) {
                // 四捨五入到最近的整數分鐘
                totalMinutes += Int(round(minutes))
            }
        }

        // 如果沒有匹配到任何格式，嘗試直接解析數字（假設是分鐘）
        if totalMinutes == 0 {
            // 支持小數點數字
            let numberPattern = #"(\d+\.?\d*)"#
            if let range = timeString.range(of: numberPattern, options: .regularExpression) {
                let numberString = String(timeString[range])
                if let minutes = Double(numberString) {
                    totalMinutes = Int(round(minutes))
                }
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