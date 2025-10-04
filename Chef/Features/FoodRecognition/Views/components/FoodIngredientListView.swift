//
//  FoodIngredientListView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 食材列表元件
struct FoodIngredientListView: View {
    let ingredients: [PossibleIngredient]
    let selectedIngredients: Set<UUID>
    let showSelection: Bool
    let groupByType: Bool
    let onSelectionChanged: ((Set<UUID>) -> Void)?

    init(
        ingredients: [PossibleIngredient],
        selectedIngredients: Set<UUID> = [],
        showSelection: Bool = false,
        groupByType: Bool = true,
        onSelectionChanged: ((Set<UUID>) -> Void)? = nil
    ) {
        self.ingredients = ingredients
        self.selectedIngredients = selectedIngredients
        self.showSelection = showSelection
        self.groupByType = groupByType
        self.onSelectionChanged = onSelectionChanged
    }

    // 按類型分組的食材
    private var groupedIngredients: [String: [PossibleIngredient]] {
        if groupByType {
            return Dictionary(grouping: ingredients, by: { $0.type })
        } else {
            return ["所有食材": ingredients]
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 標頭
            SectionHeaderView.titleWithSubtitle(
                title: "可能的食材",
                subtitle: "共 \(ingredients.count) 種食材",
                icon: "leaf.fill"
            )

            // 食材列表
            if groupByType {
                groupedIngredientsView
            } else {
                simpleIngredientsView
            }

            // 全選/取消全選按鈕（如果啟用選擇模式）
            if showSelection {
                selectionControlButtons
            }
        }
    }

    // MARK: - 分組顯示

    private var groupedIngredientsView: some View {
        VStack(spacing: 16) {
            ForEach(groupedIngredients.keys.sorted(), id: \.self) { type in
                if let ingredientsInType = groupedIngredients[type] {
                    ingredientGroupSection(
                        type: type,
                        ingredients: ingredientsInType
                    )
                }
            }
        }
    }

    private func ingredientGroupSection(
        type: String,
        ingredients: [PossibleIngredient]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分組標題
            HStack {
                Text(type)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandOrange)

                Spacer()

                Text("\(ingredients.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandOrange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 食材項目
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(ingredients) { ingredient in
                    ingredientItemView(ingredient)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 簡單列表顯示

    private var simpleIngredientsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(ingredients) { ingredient in
                ingredientItemView(ingredient)
            }
        }
    }

    // MARK: - 食材項目視圖

    private func ingredientItemView(_ ingredient: PossibleIngredient) -> some View {
        HStack(spacing: 8) {
            // 選擇框（如果啟用選擇模式）
            if showSelection {
                Image(systemName: isSelected(ingredient) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected(ingredient) ? .brandOrange : .gray)
                    .onTapGesture {
                        toggleSelection(ingredient)
                    }
            }

            // 食材圖示
            Circle()
                .fill(typeColor(for: ingredient.type).opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(ingredientEmoji(for: ingredient))
                        .font(.body)
                )

            // 食材資訊
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if !groupByType {
                    Text(ingredient.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            isSelected(ingredient) ?
            Color.brandOrange.opacity(0.1) :
            Color(.systemBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected(ingredient) ?
                    Color.brandOrange :
                    Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if showSelection {
                toggleSelection(ingredient)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected(ingredient))
    }

    // MARK: - 選擇控制按鈕

    private var selectionControlButtons: some View {
        HStack(spacing: 16) {
            Button("全部選擇") {
                let allIds = Set(ingredients.map { $0.id })
                onSelectionChanged?(allIds)
            }
            .foregroundColor(.brandOrange)

            Divider()
                .frame(height: 20)

            Button("取消全選") {
                onSelectionChanged?(Set())
            }
            .foregroundColor(.brandOrange)

            Spacer()

            Text("已選擇 \(selectedIngredients.count) 項")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 輔助方法

    private func isSelected(_ ingredient: PossibleIngredient) -> Bool {
        selectedIngredients.contains(ingredient.id)
    }

    private func toggleSelection(_ ingredient: PossibleIngredient) {
        var newSelection = selectedIngredients
        if newSelection.contains(ingredient.id) {
            newSelection.remove(ingredient.id)
        } else {
            newSelection.insert(ingredient.id)
        }
        onSelectionChanged?(newSelection)
    }

    private func typeColor(for type: String) -> Color {
        switch type {
        case "主食":
            return .orange
        case "蛋類":
            return .yellow
        case "蔬菜":
            return .green
        case "調料", "調味料", "香料":
            return .red
        case "肉類":
            return .pink
        case "魚類":
            return .blue
        case "水果":
            return .purple
        default:
            return .gray
        }
    }

    private func ingredientEmoji(for ingredient: PossibleIngredient) -> String {
        let name = ingredient.name.lowercased()
        let type = ingredient.type.lowercased()

        // 根據名稱和類型選擇 emoji
        if name.contains("米") || name.contains("飯") {
            return "🍚"
        } else if name.contains("蛋") {
            return "🥚"
        } else if name.contains("蔥") {
            return "🧅"
        } else if name.contains("蒜") {
            return "🧄"
        } else if name.contains("鹽") {
            return "🧂"
        } else if name.contains("油") {
            return "🫒"
        } else if name.contains("肉") {
            return "🥩"
        } else if name.contains("魚") {
            return "🐟"
        } else if type.contains("蔬菜") {
            return "🥬"
        } else if type.contains("調料") || type.contains("調味") {
            return "🧂"
        } else if type.contains("主食") {
            return "🍚"
        } else {
            return "🥄"
        }
    }
}

// MARK: - 預覽
#Preview {
    let sampleIngredients = [
        PossibleIngredient(name: "米飯", type: "主食"),
        PossibleIngredient(name: "雞蛋", type: "蛋類"),
        PossibleIngredient(name: "蔥", type: "蔬菜"),
        PossibleIngredient(name: "蒜", type: "蔬菜"),
        PossibleIngredient(name: "鹽", type: "調料"),
        PossibleIngredient(name: "醬油", type: "調料"),
        PossibleIngredient(name: "食用油", type: "調料")
    ]

    VStack(spacing: 20) {
        FoodIngredientListView(
            ingredients: sampleIngredients,
            groupByType: true
        )

        FoodIngredientListView(
            ingredients: sampleIngredients,
            selectedIngredients: Set([sampleIngredients[0].id, sampleIngredients[1].id]),
            showSelection: true,
            groupByType: false,
            onSelectionChanged: { selection in
                print("選擇變更：\(selection)")
            }
        )
    }
    .padding()
}