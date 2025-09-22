//
//  RecommendationResultView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct RecommendationResultView: View {
    let result: RecipeRecommendationResponse
    @ObservedObject var viewModel: RecipeRecommendationViewModel
    @EnvironmentObject private var coordinator: RecipeRecommendationCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Recipe Header
                recipeHeaderSection

                // Ingredients Section
                ingredientsSection

                // Equipment Section
                equipmentSection

                // Recipe Steps Section
                recipeStepsSection

                // Action Buttons
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("推薦結果")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("重新配置") {
                    viewModel.resetToConfiguring()
                }
                .foregroundColor(.brandOrange)
            }
        }
    }

    // MARK: - View Components

    private var recipeHeaderSection: some View {
        VStack(spacing: 16) {
            // Recipe Icon
            Image(systemName: "chef.hat.fill")
                .font(.system(size: 60))
                .foregroundColor(.brandOrange)

            // Recipe Title and Description
            VStack(spacing: 8) {
                Text(result.dishName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(result.dishDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Recipe Info
            HStack(spacing: 20) {
                RecipeInfoItem(
                    icon: "clock",
                    title: "總時間",
                    value: result.totalEstimatedTime
                )

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)

                RecipeInfoItem(
                    icon: "list.number",
                    title: "步驟",
                    value: "\(result.totalSteps)個"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "carrot.fill")
                    .foregroundColor(.brandOrange)

                Text("使用食材")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(result.ingredients.count)種")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(result.ingredients, id: \.name) { ingredient in
                    ResultIngredientItemView(ingredient: ingredient)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "frying.pan.fill")
                    .foregroundColor(.brandOrange)

                Text("使用器具")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(result.equipment.count)種")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(result.equipment, id: \.name) { equipment in
                    ResultEquipmentItemView(equipment: equipment)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var recipeStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.brandOrange)

                Text("製作步驟")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            VStack(spacing: 16) {
                ForEach(Array(result.recipe.enumerated()), id: \.element.step_number) { index, step in
                    RecipeStepView(step: step, stepIndex: index + 1)
                }
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Retry Button
            Button(action: {
                Task {
                    await viewModel.startRecommendation()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                    Text("重新推薦")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // View Detail Button (for future integration)
            Button(action: {
                // TODO: Navigate to detailed recipe view
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.title3)
                    Text("查看詳細食譜")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange.opacity(0.1))
                .foregroundColor(.brandOrange)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Supporting Views

private struct RecipeInfoItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandOrange)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

private struct ResultIngredientItemView: View {
    let ingredient: Ingredient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(.brandOrange)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(ingredient.name)
                        .font(.body)
                        .fontWeight(.medium)

                    Text("(\(ingredient.type))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(ingredient.amount) \(ingredient.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !ingredient.preparation.isEmpty {
                    Text(ingredient.preparation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ResultEquipmentItemView: View {
    let equipment: Equipment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(.brandOrange)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(equipment.name)
                        .font(.body)
                        .fontWeight(.medium)

                    Text("(\(equipment.type))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                HStack(spacing: 8) {
                    if !equipment.size.isEmpty {
                        Text(equipment.size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.material.isEmpty {
                        Text("• \(equipment.material)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.power_source.isEmpty && equipment.power_source != "無" {
                        Text("• \(equipment.power_source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let sampleResponse = RecipeRecommendationResponse.sample()
    let viewModel = RecipeRecommendationViewModel()

    RecommendationResultView(result: sampleResponse, viewModel: viewModel)
}