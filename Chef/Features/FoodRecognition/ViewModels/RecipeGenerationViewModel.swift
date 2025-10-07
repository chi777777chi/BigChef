//
//  RecipeGenerationViewModel.swift
//  ChefHelper
//
//  Created by Claude on 2025/10/07.
//

import Foundation
import SwiftUI

// MARK: - Recipe Generation State
enum RecipeGenerationViewState {
    case initial(FoodRecognitionResponse)  // 顯示辨識結果
    case adjusting(FoodRecognitionResponse) // 調整食材器具
    case loading                          // 生成食譜中
    case success(RecipeRecommendationResponse) // 生成成功
    case error(Error)                    // 生成失敗
}

@MainActor
final class RecipeGenerationViewModel: ObservableObject {
    @Published var state: RecipeGenerationViewState
    @Published var selectedIngredients: [String] = []
    @Published var selectedEquipment: [String] = []

    private var currentTask: Task<Void, Never>?
    private let originalResponse: FoodRecognitionResponse
    private var currentResponse: FoodRecognitionResponse

    init(recognitionResponse: FoodRecognitionResponse) {
        self.originalResponse = recognitionResponse
        self.currentResponse = recognitionResponse
        self.state = .initial(recognitionResponse)

        // 初始化選中的食材和器具
        self.selectedIngredients = recognitionResponse.allIngredients.map { $0.name }
        self.selectedEquipment = recognitionResponse.allEquipment.map { $0.name }
    }

    var dishName: String? {
        originalResponse.recognizedFoods.first?.name
    }

    // MARK: - Public Methods

    func showAdjustment() {
        state = .adjusting(currentResponse)
    }

    func backToInitial() {
        state = .initial(currentResponse)
    }

    func updateIngredients(_ ingredients: [String], equipment: [String]) {
        selectedIngredients = ingredients
        selectedEquipment = equipment

        // 創建更新後的 response
        let updatedIngredients = ingredients.map { name in
            PossibleIngredient(name: name, type: "其他")
        }
        let updatedEquipment = equipment.map { name in
            PossibleEquipment(name: name, type: "其他")
        }

        // 更新 recognizedFoods 中的食材和器具
        let updatedFoods = originalResponse.recognizedFoods.map { food in
            RecognizedFood(
                name: food.name,
                description: food.description,
                possibleIngredients: updatedIngredients,
                possibleEquipment: updatedEquipment
            )
        }

        currentResponse = FoodRecognitionResponse(recognizedFoods: updatedFoods)
        state = .initial(currentResponse)
    }

    func generateRecipe() async {
        guard let dishName = dishName else {
            state = .error(NSError(
                domain: "RecipeGeneration",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "無法識別菜名"]
            ))
            return
        }

        print("🍳 RecipeGenerationViewModel: 開始生成食譜")
        print("  菜名：\(dishName)")
        print("  食材：\(selectedIngredients)")
        print("  器具：\(selectedEquipment)")

        state = .loading

        currentTask = Task {
            do {
                // 使用 RecipeService 的 generateRecipeByName API
                let request = GenerateRecipeByNameRequest(
                    dish_name: dishName,
                    preferred_ingredients: selectedIngredients,
                    excluded_ingredients: [],
                    preferred_equipment: selectedEquipment,
                    preference: GenerateRecipeByNameRequest.GeneratePreference(
                        cooking_method: nil,
                        doneness: nil,
                        serving_size: "2人份"
                    )
                )

                let response = try await RecipeService.generateRecipeByName(using: request)

                guard !Task.isCancelled else { return }

                // 轉換為 RecipeRecommendationResponse
                let result = RecipeRecommendationResponse(
                    dishName: response.dish_name,
                    dishDescription: response.dish_description,
                    ingredients: response.ingredients,
                    equipment: response.equipment,
                    recipe: response.recipe
                )

                await MainActor.run {
                    state = .success(result)
                    print("✅ RecipeGenerationViewModel: 食譜生成成功")
                }

            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    state = .error(error)
                    print("❌ RecipeGenerationViewModel: 食譜生成失敗 - \(error.localizedDescription)")
                }
            }
        }

        await currentTask?.value
        currentTask = nil
    }

    func cancelGeneration() {
        currentTask?.cancel()
        currentTask = nil
        state = .initial(currentResponse)
    }

    func retryGeneration() async {
        await generateRecipe()
    }
}
