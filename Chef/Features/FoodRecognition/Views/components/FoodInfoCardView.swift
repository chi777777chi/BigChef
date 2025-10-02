//
//  FoodInfoCardView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 食物資訊卡片元件
struct FoodInfoCardView: View {
    let food: RecognizedFood
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    init(
        food: RecognizedFood,
        isExpanded: Bool = false,
        onToggleExpanded: @escaping () -> Void
    ) {
        self.food = food
        self.isExpanded = isExpanded
        self.onToggleExpanded = onToggleExpanded
    }

    var body: some View {
        VStack(spacing: 0) {
            // 主要資訊區域
            mainInfoSection
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onToggleExpanded()
                    }
                }

            // 詳細資訊區域（可展開）
            if isExpanded {
                detailedInfoSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - 主要資訊區域

    private var mainInfoSection: some View {
        HStack(spacing: 16) {
            // 食物圖示
            foodIconView

            // 食物資訊
            VStack(alignment: .leading, spacing: 8) {
                // 食物名稱
                Text(food.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // 食物描述
                Text(food.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)

                // 統計資訊
                statisticsRow
            }

            Spacer()

            // 展開/收起圖示
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.title3)
                .foregroundColor(.brandOrange)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .padding()
    }

    // MARK: - 詳細資訊區域

    private var detailedInfoSection: some View {
        VStack(spacing: 16) {
            Divider()

            // 食材和設備統計
            ingredientAndEquipmentStats
        }
        .padding(.bottom)
    }

    // MARK: - 子元件

    private var foodIconView: some View {
        Circle()
            .fill(Color.brandOrange.opacity(0.15))
            .frame(width: 60, height: 60)
            .overlay(
                Text(foodEmoji)
                    .font(.title)
            )
    }

    private var statisticsRow: some View {
        HStack(spacing: 16) {
            statItem(
                icon: "leaf.fill",
                count: food.possibleIngredients.count,
                label: "食材"
            )

            statItem(
                icon: "fork.knife",
                count: food.possibleEquipment.count,
                label: "器具"
            )
        }
    }

    private var ingredientAndEquipmentStats: some View {
        HStack(spacing: 20) {
            // 主要食材統計
            VStack(spacing: 8) {
                Text("主要食材")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(food.mainIngredients.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.brandOrange)

                Text("個")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // 調料統計
            VStack(spacing: 8) {
                Text("調料")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(food.seasonings.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text("種")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // 必需設備統計
            VStack(spacing: 8) {
                Text("必需器具")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(food.essentialEquipment.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }

    // MARK: - 輔助方法

    private func statItem(icon: String, count: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.brandOrange)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // 根據食物名稱選擇合適的 emoji
    private var foodEmoji: String {
        let name = food.name.lowercased()

        // 常見食物的 emoji 映射
        if name.contains("飯") || name.contains("米") {
            return "🍚"
        } else if name.contains("麵") || name.contains("面") {
            return "🍜"
        } else if name.contains("湯") {
            return "🍲"
        } else if name.contains("肉") {
            return "🥩"
        } else if name.contains("蛋") {
            return "🥚"
        } else if name.contains("魚") {
            return "🐟"
        } else if name.contains("菜") || name.contains("蔬") {
            return "🥬"
        } else if name.contains("水果") || name.contains("果") {
            return "🍎"
        } else if name.contains("餅") || name.contains("糕") {
            return "🍰"
        } else if name.contains("麵包") || name.contains("包") {
            return "🍞"
        } else {
            return "🍽️"
        }
    }
}

// MARK: - 預覽
#Preview {
    let sampleFood = RecognizedFood(
        name: "蛋炒飯",
        description: "經典的中式蛋炒飯，香氣撲鼻，色香味俱全",
        possibleIngredients: [
            PossibleIngredient(name: "米飯", type: "主食"),
            PossibleIngredient(name: "雞蛋", type: "蛋類"),
            PossibleIngredient(name: "蔥", type: "蔬菜"),
            PossibleIngredient(name: "鹽", type: "調料"),
            PossibleIngredient(name: "醬油", type: "調料")
        ],
        possibleEquipment: [
            PossibleEquipment(name: "炒鍋", type: "鍋具"),
            PossibleEquipment(name: "鍋鏟", type: "工具")
        ]
    )

    VStack(spacing: 16) {
        FoodInfoCardView(
            food: sampleFood,
            isExpanded: false,
            onToggleExpanded: {}
        )

        FoodInfoCardView(
            food: sampleFood,
            isExpanded: true,
            onToggleExpanded: {}
        )
    }
    .padding()
}