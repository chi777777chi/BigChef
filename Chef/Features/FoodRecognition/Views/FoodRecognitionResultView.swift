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
    let onGenerateRecipe: (() -> Void)?  // 新增：直接生成食譜的回調

    @State private var expandedFoodIds: Set<UUID> = []

    init(
        result: FoodRecognitionResponse,
        selectedImage: UIImage?,
        onRetry: @escaping () -> Void,
        onGenerateRecipe: (() -> Void)? = nil
    ) {
        self.result = result
        self.selectedImage = selectedImage
        self.onRetry = onRetry
        self.onGenerateRecipe = onGenerateRecipe
    }

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
                        // 功能移除：不再支援選擇特定食物
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
                selectedIngredients: Set<UUID>(),
                showSelection: false,
                groupByType: true,
                onSelectionChanged: { _ in
                    // 功能移除：不再支援選擇功能
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
                selectedEquipment: Set<UUID>(),
                showSelection: false,
                groupByType: true,
                onSelectionChanged: { _ in
                    // 功能移除：不再支援選擇功能
                }
            )
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // 生成食譜按鈕 - 直接跳轉到食譜推薦頁面
                ActionButtonView.primary(
                    title: "生成食譜",
                    icon: "chef.hat",
                    action: {
                        print("生成食譜按鈕被點擊，直接導航到食譜推薦頁面")
                        if let generateRecipe = onGenerateRecipe {
                            generateRecipe()
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
            onGenerateRecipe: {
                print("生成食譜")
            }
        )
    }
}