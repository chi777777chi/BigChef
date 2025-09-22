//
//  RecipeRecommendationView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct RecipeRecommendationView: View {
    @StateObject private var viewModel: RecipeRecommendationViewModel
    @EnvironmentObject private var coordinator: RecipeRecommendationCoordinator
    @State private var showingIngredientInput = false
    @State private var showingEquipmentInput = false

    init(viewModel: RecipeRecommendationViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .configuring:
                    mainConfigurationView
                case .loading:
                    RecommendationLoadingView()
                case .success(let result):
                    RecommendationResultView(result: result, viewModel: viewModel)
                case .error(let error):
                    RecommendationErrorView(error: error) {
                        Task { await viewModel.retryRecommendation() }
                    }
                }
            }
            .navigationTitle("食譜推薦")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingIngredientInput) {
            IngredientInputView { ingredient in
                viewModel.addIngredient(ingredient)
            }
        }
        .sheet(isPresented: $showingEquipmentInput) {
            EquipmentInputView { equipment in
                viewModel.addEquipment(equipment)
            }
        }
    }

    // MARK: - Main Configuration View

    private var mainConfigurationView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Logo Section
                logoSection

                // Ingredients Section
                ingredientsSection

                // Equipment Section
                equipmentSection

                // Preferences Section
                preferencesSection

                // Action Button
                recommendationButton

                // Validation Errors
                if !viewModel.validationErrors.isEmpty {
                    validationErrorsSection
                }
            }
            .padding()
        }
    }

    private var validationErrorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("請修正以下問題：")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(viewModel.validationErrors, id: \.self) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - View Components

    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.brandOrange)

            Text("根據您的食材和器具推薦最適合的食譜")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RecommendationSectionHeader(
                title: "可用食材",
                onAdd: { showingIngredientInput = true }
            )

            if viewModel.availableIngredients.isEmpty {
                EmptyStateView(
                    icon: "carrot.fill",
                    message: "點擊 + 新增您擁有的食材",
                    buttonTitle: "新增食材",
                    buttonAction: { showingIngredientInput = true }
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.availableIngredients.enumerated()), id: \.element.id) { index, ingredient in
                        IngredientListItemView(
                            ingredient: ingredient,
                            onDelete: {
                                withAnimation(.easeInOut) {
                                    viewModel.removeIngredient(at: index)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RecommendationSectionHeader(
                title: "可用器具",
                onAdd: { showingEquipmentInput = true }
            )

            if viewModel.availableEquipment.isEmpty {
                EmptyStateView(
                    icon: "frying.pan.fill",
                    message: "點擊 + 新增您擁有的廚房器具",
                    buttonTitle: "新增器具",
                    buttonAction: { showingEquipmentInput = true }
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.availableEquipment.enumerated()), id: \.element.id) { index, equipment in
                        EquipmentListItemView(
                            equipment: equipment,
                            onDelete: {
                                withAnimation(.easeInOut) {
                                    viewModel.removeEquipment(at: index)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var preferencesSection: some View {
        PreferenceSettingView(viewModel: viewModel)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }

    private var recommendationButton: some View {
        Button(action: {
            Task {
                await viewModel.startRecommendation()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title3)
                Text("推薦食譜")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.canRequestRecommendation ? Color.brandOrange : Color.gray
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canRequestRecommendation)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canRequestRecommendation)
    }
}

// MARK: - Supporting Views

private struct RecommendationSectionHeader: View {
    let title: String
    let onAdd: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.brandOrange)
                    .font(.title2)
            }
        }
    }
}

private struct EmptyStateView: View {
    let icon: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: buttonAction) {
                Text(buttonTitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.brandOrange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.brandOrange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Preview

#Preview {
    RecipeRecommendationView(viewModel: RecipeRecommendationViewModel())
}