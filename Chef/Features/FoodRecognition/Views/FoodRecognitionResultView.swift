//
//  FoodRecognitionResultView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 食物辨識結果顯示頁面
struct FoodRecognitionResultView: View {
    let result: FoodRecognitionResponse
    let selectedImage: UIImage?
    let onRetry: () -> Void
    let onUseIngredients: () -> Void

    @State private var expandedFoodIds: Set<UUID> = []
    @State private var selectedIngredients: Set<UUID> = []
    @State private var selectedEquipment: Set<UUID> = []
    @State private var showSelectionMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 成功標頭
                successHeader

                // 選中的圖片（小預覽）
                if let image = selectedImage {
                    selectedImagePreview(image)
                }

                // 辨識結果摘要
                resultSummary

                // 辨識出的食物清單
                recognizedFoodsSection

                // 所有食材清單
                allIngredientsSection

                // 所有器具清單
                allEquipmentSection

                // 動作按鈕
                actionButtonsSection
            }
            .padding()
        }
        .navigationBarHidden(true)
    }

    // MARK: - 子視圖

    private var successHeader: some View {
        VStack(spacing: 16) {
            // 成功圖示
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("辨識成功！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("AI 已成功分析您的食物圖片")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func selectedImagePreview(_ image: UIImage) -> some View {
        VStack(spacing: 8) {
            Text("辨識圖片")
                .font(.caption)
                .foregroundColor(.secondary)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
        }
    }

    private var resultSummary: some View {
        VStack(spacing: 16) {
            SectionHeaderView.titleWithIcon(
                title: "辨識摘要",
                icon: "chart.bar.fill"
            )

            HStack(spacing: 20) {
                summaryStatCard(
                    title: "食物種類",
                    count: result.recognizedFoods.count,
                    icon: "🍽️",
                    color: .brandOrange
                )

                summaryStatCard(
                    title: "可能食材",
                    count: result.allIngredients.count,
                    icon: "🥬",
                    color: .green
                )

                summaryStatCard(
                    title: "需要器具",
                    count: result.allEquipment.count,
                    icon: "🍳",
                    color: .blue
                )
            }
        }
    }

    private var recognizedFoodsSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView.titleWithSubtitle(
                title: "辨識出的食物",
                subtitle: "點擊展開查看詳細資訊",
                icon: "list.bullet.rectangle"
            )

            ForEach(result.recognizedFoods) { food in
                FoodInfoCardView(
                    food: food,
                    isExpanded: expandedFoodIds.contains(food.id),
                    onToggleExpanded: {
                        withAnimation {
                            if expandedFoodIds.contains(food.id) {
                                expandedFoodIds.remove(food.id)
                            } else {
                                expandedFoodIds.insert(food.id)
                            }
                        }
                    },
                    onSelectFood: {
                        // 使用特定食物的食材和器具
                        selectedIngredients = Set(food.possibleIngredients.map { $0.id })
                        selectedEquipment = Set(food.possibleEquipment.map { $0.id })
                        showSelectionMode = true
                    }
                )
            }
        }
    }

    private var allIngredientsSection: some View {
        VStack(spacing: 16) {
            FoodIngredientListView(
                ingredients: result.allIngredients.map { ingredient in
                    // 轉換為 PossibleIngredient
                    PossibleIngredient(name: ingredient.name, type: ingredient.type)
                },
                selectedIngredients: selectedIngredients,
                showSelection: showSelectionMode,
                groupByType: true,
                onSelectionChanged: { newSelection in
                    selectedIngredients = newSelection
                }
            )
        }
    }

    private var allEquipmentSection: some View {
        VStack(spacing: 16) {
            FoodEquipmentListView(
                equipment: result.allEquipment.map { equipment in
                    // 轉換為 PossibleEquipment
                    PossibleEquipment(name: equipment.name, type: equipment.type)
                },
                selectedEquipment: selectedEquipment,
                showSelection: showSelectionMode,
                groupByType: true,
                onSelectionChanged: { newSelection in
                    selectedEquipment = newSelection
                }
            )
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if showSelectionMode {
                // 選擇模式下的按鈕
                VStack(spacing: 12) {
                    ActionButtonView.success(
                        title: "使用選中的食材和器具",
                        icon: "checkmark.circle",
                        isEnabled: !selectedIngredients.isEmpty || !selectedEquipment.isEmpty,
                        action: onUseIngredients
                    )

                    Button("取消選擇") {
                        withAnimation {
                            showSelectionMode = false
                            selectedIngredients.removeAll()
                            selectedEquipment.removeAll()
                        }
                    }
                    .foregroundColor(.brandOrange)
                }
            } else {
                // 一般模式下的按鈕
                VStack(spacing: 12) {
                    ActionButtonView.success(
                        title: "使用所有食材",
                        icon: "checkmark.circle",
                        action: onUseIngredients
                    )

                    ActionButtonView.secondary(
                        title: "選擇特定食材",
                        icon: "checklist",
                        action: {
                            withAnimation {
                                showSelectionMode = true
                                // 預設選擇主要食物的食材
                                if let primaryFood = result.recognizedFoods.first {
                                    selectedIngredients = Set(primaryFood.possibleIngredients.map { $0.id })
                                    selectedEquipment = Set(primaryFood.possibleEquipment.map { $0.id })
                                }
                            }
                        }
                    )

                    ActionButtonView.secondary(
                        title: "重新辨識",
                        icon: "arrow.clockwise",
                        action: onRetry
                    )
                }
            }
        }
        .padding(.top)
    }

    // MARK: - 輔助視圖

    private func summaryStatCard(
        title: String,
        count: Int,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 預覽
#Preview {
    let sampleResult = FoodRecognitionResponse(
        recognizedFoods: [
            RecognizedFood(
                name: "蛋炒飯",
                description: "經典的中式蛋炒飯，香氣撲鼻，色香味俱全",
                possibleIngredients: [
                    PossibleIngredient(name: "米飯", type: "主食"),
                    PossibleIngredient(name: "雞蛋", type: "蛋類"),
                    PossibleIngredient(name: "蔥", type: "蔬菜"),
                    PossibleIngredient(name: "鹽", type: "調料")
                ],
                possibleEquipment: [
                    PossibleEquipment(name: "炒鍋", type: "鍋具"),
                    PossibleEquipment(name: "鍋鏟", type: "工具")
                ]
            )
        ]
    )

    NavigationView {
        FoodRecognitionResultView(
            result: sampleResult,
            selectedImage: nil,
            onRetry: {
                print("重新辨識")
            },
            onUseIngredients: {
                print("使用食材")
            }
        )
    }
}