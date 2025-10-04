//
//  RecipeRecommendationView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct RecipeRecommendationView: View {
    @StateObject private var viewModel: RecipeRecommendationViewModel
    let coordinator: RecipeRecommendationCoordinator
    @State private var showingIngredientInput = false
    @State private var showingEquipmentInput = false
    @State private var showingIngredientScan = false
    @State private var showingEquipmentScan = false
    @State private var showingAddIngredientOptions = false
    @State private var showingAddEquipmentOptions = false
    @State private var editingIngredientIndex: Int? = nil
    @State private var editingEquipmentIndex: Int? = nil

    init(viewModel: RecipeRecommendationViewModel, coordinator: RecipeRecommendationCoordinator) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.coordinator = coordinator
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        switch viewModel.state {
        case .success:
            return "推薦結果"
        default:
            return "食譜推薦"
        }
    }

    private var navigationTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        switch viewModel.state {
        case .success:
            return .inline
        default:
            return .large
        }
    }

    var body: some View {
        Group {
                switch viewModel.state {
                case .idle, .configuring:
                    mainConfigurationView
                case .loading:
                    RecommendationLoadingView(onCancel: {
                        viewModel.cancelCurrentRequest()
                    })
                case .success(let result):
                    RecommendationResultView(result: result, viewModel: viewModel, coordinator: coordinator)
                case .error(let error):
                    RecommendationErrorView(
                        error: error,
                        onRetry: {
                            Task { await viewModel.retryRecommendation() }
                        },
                        onBackToConfiguration: {
                            viewModel.backToConfiguration()
                        },
                        onResetConfiguration: {
                            viewModel.resetToConfiguring()
                        }
                    )
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(navigationTitleDisplayMode)
        .sheet(isPresented: $showingIngredientInput) {
            IngredientInputView(
                editingIngredient: editingIngredientIndex != nil ? viewModel.availableIngredients[editingIngredientIndex!] : nil
            ) { ingredient in
                if let index = editingIngredientIndex {
                    viewModel.updateIngredient(at: index, with: ingredient)
                } else {
                    viewModel.addIngredient(ingredient)
                }
                editingIngredientIndex = nil
            }
        }
        .sheet(isPresented: $showingEquipmentInput) {
            EquipmentInputView(
                editingEquipment: editingEquipmentIndex != nil ? viewModel.availableEquipment[editingEquipmentIndex!] : nil
            ) { equipment in
                if let index = editingEquipmentIndex {
                    viewModel.updateEquipment(at: index, with: equipment)
                } else {
                    viewModel.addEquipment(equipment)
                }
                editingEquipmentIndex = nil
            }
        }
        .sheet(isPresented: $showingIngredientScan) {
            IngredientScanView(scanMode: .ingredientOnly) { ingredients, equipment in
                // 只加入食材
                for ingredient in ingredients {
                    viewModel.addIngredient(ingredient)
                }
            }
        }
        .sheet(isPresented: $showingEquipmentScan) {
            IngredientScanView(scanMode: .equipmentOnly) { ingredients, equipment in
                // 只加入器具
                for equip in equipment {
                    viewModel.addEquipment(equip)
                }
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
        VStack(alignment: .center, spacing: 12) {
            // 置中的標題
            Text("可用食材")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)

            if viewModel.availableIngredients.isEmpty {
                // 空狀態：置中的新增按鈕
                VStack(spacing: 16) {
                    Image(systemName: "carrot.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("點擊新增您擁有的食材")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        showingAddIngredientOptions = true
                    }) {
                        Text("新增食材")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.brandOrange)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 有食材時：顯示列表
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.availableIngredients.enumerated()), id: \.element.id) { index, ingredient in
                        IngredientListItemView(
                            ingredient: ingredient,
                            onEdit: {
                                editingIngredientIndex = index
                                showingIngredientInput = true
                            },
                            onDelete: {
                                withAnimation(.easeInOut) {
                                    viewModel.removeIngredient(at: index)
                                }
                            }
                        )
                    }
                }

                // 列表下方的置中新增按鈕
                Button(action: {
                    showingAddIngredientOptions = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("新增更多食材")
                    }
                    .font(.headline)
                    .foregroundColor(.brandOrange)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brandOrange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .confirmationDialog("選擇新增方式", isPresented: $showingAddIngredientOptions) {
            Button("手動輸入") {
                editingIngredientIndex = nil
                showingIngredientInput = true
            }
            Button("掃描辨識") {
                showingIngredientScan = true
            }
            Button("取消", role: .cancel) {}
        }
    }

    private var equipmentSection: some View {
        VStack(alignment: .center, spacing: 12) {
            // 置中的標題
            Text("可用器具")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)

            if viewModel.availableEquipment.isEmpty {
                // 空狀態：置中的新增按鈕
                VStack(spacing: 16) {
                    Image(systemName: "frying.pan.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("點擊新增您擁有的廚房器具")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        showingAddEquipmentOptions = true
                    }) {
                        Text("新增器具")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.brandOrange)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 有器具時：顯示列表
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.availableEquipment.enumerated()), id: \.element.id) { index, equipment in
                        EquipmentListItemView(
                            equipment: equipment,
                            onEdit: {
                                editingEquipmentIndex = index
                                showingEquipmentInput = true
                            },
                            onDelete: {
                                withAnimation(.easeInOut) {
                                    viewModel.removeEquipment(at: index)
                                }
                            }
                        )
                    }
                }

                // 列表下方的置中新增按鈕
                Button(action: {
                    showingAddEquipmentOptions = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("新增更多器具")
                    }
                    .font(.headline)
                    .foregroundColor(.brandOrange)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brandOrange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .confirmationDialog("選擇新增方式", isPresented: $showingAddEquipmentOptions) {
            Button("手動輸入") {
                editingEquipmentIndex = nil
                showingEquipmentInput = true
            }
            Button("掃描辨識") {
                showingEquipmentScan = true
            }
            Button("取消", role: .cancel) {}
        }
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

// MARK: - Supporting Views (置中設計已整合到主要區塊中)

// MARK: - Preview

#Preview {
    let coordinator = RecipeRecommendationCoordinator(navigationController: UINavigationController())
    RecipeRecommendationView(viewModel: RecipeRecommendationViewModel(), coordinator: coordinator)
}