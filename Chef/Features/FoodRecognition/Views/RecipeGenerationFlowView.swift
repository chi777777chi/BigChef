//
//  RecipeGenerationFlowView.swift
//  ChefHelper
//
//  Created by Claude on 2025/10/07.
//

import SwiftUI

struct RecipeGenerationFlowView: View {
    @StateObject private var viewModel: RecipeGenerationViewModel
    @EnvironmentObject private var coordinator: FoodRecognitionCoordinator

    init(recognitionResponse: FoodRecognitionResponse) {
        self._viewModel = StateObject(wrappedValue: RecipeGenerationViewModel(recognitionResponse: recognitionResponse))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .initial(let response):
                initialView(response: response)
            case .adjusting(let response):
                adjustingView(response: response)
            case .loading:
                loadingView
            case .success(let result):
                successView(result: result)
            case .error(let error):
                errorView(error: error)
            }
        }
    }

    // MARK: - State Views

    private func initialView(response: FoodRecognitionResponse) -> some View {
        FoodRecognitionResultView(
            result: response,
            selectedImage: nil,
            onRetry: {
                // 返回辨識頁面重新辨識
                coordinator.goBack()
            },
            onAdjustIngredients: {
                viewModel.showAdjustment()
            },
            onGenerateRecipe: {
                Task {
                    await viewModel.generateRecipe()
                }
            }
        )
    }

    private func adjustingView(response: FoodRecognitionResponse) -> some View {
        IngredientAdjustmentView(
            ingredients: response.allIngredients.map { ingredient in
                PossibleIngredient(name: ingredient.name, type: ingredient.type)
            },
            equipment: response.allEquipment.map { equip in
                PossibleEquipment(name: equip.name, type: equip.type)
            },
            onConfirm: { ingredients, equipment in
                viewModel.updateIngredients(ingredients, equipment: equipment)
            }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    viewModel.backToInitial()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        RecommendationLoadingView(onCancel: {
            viewModel.cancelGeneration()
        })
    }

    private func successView(result: RecipeRecommendationResponse) -> some View {
        RecipeDetailView(
            recommendationResult: result,
            showNavigationBar: false,
            onStartCooking: {
                coordinator.startARCooking(with: result.recipe, dishName: result.dishName)
            },
            onBack: {
                viewModel.backToInitial()
            },
            onFavorite: {
                print("❤️ 收藏食譜：\(result.dishName)")
            }
        )
    }

    private func errorView(error: Error) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("食譜生成失敗")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.retryGeneration()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重試")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Button(action: {
                    viewModel.backToInitial()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("返回")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    let sampleResponse = FoodRecognitionResponse(
        recognizedFoods: [
            RecognizedFood(
                name: "番茄炒蛋",
                description: "經典的中式家常菜",
                possibleIngredients: [
                    PossibleIngredient(name: "番茄", type: "蔬菜"),
                    PossibleIngredient(name: "雞蛋", type: "蛋類")
                ],
                possibleEquipment: [
                    PossibleEquipment(name: "炒鍋", type: "鍋具")
                ]
            )
        ]
    )

    RecipeGenerationFlowView(recognitionResponse: sampleResponse)
        .environmentObject(FoodRecognitionCoordinator(navigationController: UINavigationController()))
}
