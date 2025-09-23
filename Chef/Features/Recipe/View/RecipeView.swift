//
//  RecipeView.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/4.
//
import SwiftUI

struct RecipeView: View {
    @ObservedObject var viewModel: RecipeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RecipeDetailView(
            dishName: viewModel.dishName,
            dishDescription: viewModel.dishDescription,
            ingredients: viewModel.ingredients,
            equipment: viewModel.equipment,
            recipeSteps: viewModel.steps,
            showARButton: true,
            showNavigationBar: true,
            onStartCooking: {
                viewModel.cookButtonTapped()
            },
            onBack: {
                if viewModel.onBackRequested != nil {
                    viewModel.backButtonTapped()
                } else {
                    dismiss()
                }
            },
            onFavorite: {
                print("收藏按鈕被點擊")
            }
        )
    }
}

#Preview {
    let sampleAction = Action(
        action: "煎",
        tool_required: "平底鍋",
        material_required: ["牛排"],
        time_minutes: 5,
        instruction_detail: "煎至表面微焦並鎖住肉汁"
    )

    let sampleStep = RecipeStep(
        step_number: 1,
        title: "煎牛排",
        description: "將牛排從冰箱取出，放置於室溫約 20 分鐘，讓其回溫。",
        actions: [sampleAction],
        estimated_total_time: "5分鐘",
        temperature: "中火",
        warnings: nil,
        notes: "可加海鹽與胡椒調味"
    )

    let sampleIngredient = Ingredient(
        name: "牛排",
        type: "肉類",
        amount: "1",
        unit: "塊",
        preparation: "室溫退冰"
    )

    let sampleEquipment = Equipment(
        name: "平底鍋",
        type: "鍋具",
        size: "中型",
        material: "鐵",
        power_source: "瓦斯"
    )

    let response = SuggestRecipeResponse(
        dish_name: "健康沙拉",
        dish_description: "一道清爽健康的料理",
        ingredients: [sampleIngredient],
        equipment: [sampleEquipment],
        recipe: [sampleStep, sampleStep]
    )

    let viewModel = RecipeViewModel(response: response)
    return RecipeView(viewModel: viewModel)
}
