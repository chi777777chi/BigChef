//
//  PreferenceSettingView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct PreferenceSettingView: View {
    @ObservedObject var viewModel: RecipeRecommendationViewModel
    @State private var selectedDietaryRestrictions: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Text("偏好設定")
                .font(.headline)
                .fontWeight(.semibold)

            // Cooking Method
            VStack(alignment: .leading, spacing: 8) {
                Text("烹飪方式")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("烹飪方式", selection: Binding(
                    get: { viewModel.preference.cookingMethod ?? "一般烹調" },
                    set: { viewModel.updateCookingMethod($0) }
                )) {
                    ForEach(viewModel.cookingMethods, id: \.self) { method in
                        HStack {
                            Image(systemName: iconForCookingMethod(method))
                            Text(method)
                        }
                        .tag(method)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }

            // Dietary Restrictions
            VStack(alignment: .leading, spacing: 8) {
                Text("飲食限制")
                    .font(.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(viewModel.dietaryRestrictions, id: \.self) { restriction in
                        DietaryRestrictionChip(
                            restriction: restriction,
                            isSelected: selectedDietaryRestrictions.contains(restriction),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedDietaryRestrictions.insert(restriction)
                                } else {
                                    selectedDietaryRestrictions.remove(restriction)
                                }
                                updateDietaryRestrictions()
                            }
                        )
                    }
                }
            }

            // Serving Size
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.brandOrange)
                    Text("烹飪份量")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text("選擇您想要準備的份量，AI 將根據人數調整各食材的用量")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // 使用卡片式選擇器
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(viewModel.servingSizes, id: \.self) { size in
                        ServingSizeCard(
                            size: size,
                            isSelected: viewModel.preference.servingSize == size,
                            onTap: {
                                viewModel.updateServingSize(size)
                            }
                        )
                    }
                }
            }

            // Recipe Description
            VStack(alignment: .leading, spacing: 8) {
                Text("食譜敘述")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("描述您想要的食譜特色，例如：簡單易做的家常菜、辣味濃郁、清爽健康等")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: Binding(
                    get: { viewModel.preference.recipeDescription ?? "" },
                    set: { viewModel.updateRecipeDescription($0.isEmpty ? nil : $0) }
                ))
                .font(.body)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .frame(minHeight: 80, maxHeight: 120)
            }
        }
        .onAppear {
            // Initialize selected dietary restrictions
            selectedDietaryRestrictions = Set(viewModel.preference.dietaryRestrictions ?? [])
        }
    }

    // MARK: - Helper Methods

    private func updateDietaryRestrictions() {
        let restrictions = selectedDietaryRestrictions.isEmpty ? [] : Array(selectedDietaryRestrictions)
        viewModel.updateDietaryRestrictions(restrictions)
    }

    private func iconForCookingMethod(_ method: String) -> String {
        switch method {
        case "煎":
            return "circle.fill"
        case "炒":
            return "tornado"
        case "煮":
            return "drop.fill"
        case "蒸":
            return "cloud.fill"
        case "炸":
            return "burst.fill"
        case "烤":
            return "flame.fill"
        case "燉":
            return "slowcooker.fill"
        case "涼拌":
            return "leaf.fill"
        default:
            return "chef.hat"
        }
    }
}

// MARK: - Serving Size Card

private struct ServingSizeCard: View {
    let size: String
    let isSelected: Bool
    let onTap: () -> Void

    private var personCount: String {
        // 從 "2人份" 提取數字
        let digits = size.filter { $0.isNumber }
        return digits.isEmpty ? size : digits
    }

    private var displayText: String {
        if size.contains("以上") {
            return "6+"
        }
        return personCount
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: personIconForSize(size))
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .brandOrange)

                Text(displayText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)

                Text("人份")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.brandOrange : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandOrange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func personIconForSize(_ size: String) -> String {
        let count = Int(personCount) ?? 1
        switch count {
        case 1:
            return "person.fill"
        case 2:
            return "person.2.fill"
        case 3:
            return "person.3.fill"
        default:
            return "person.3.sequence.fill"
        }
    }
}

// MARK: - Dietary Restriction Chip

private struct DietaryRestrictionChip: View {
    let restriction: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 6) {
                Image(systemName: iconForRestriction(restriction))
                    .font(.caption)

                Text(restriction)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.brandOrange : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandOrange : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func iconForRestriction(_ restriction: String) -> String {
        switch restriction {
        case "素食":
            return "leaf.fill"
        case "純素":
            return "leaf.circle.fill"
        case "無麩質":
            return "grain"
        case "無乳製品":
            return "drop.circle"
        case "低糖":
            return "cube"
        case "低鈉":
            return "saltshaker"
        case "低脂":
            return "heart.circle"
        default:
            return "checkmark.circle"
        }
    }
}

// MARK: - Preview

#Preview {
    PreferenceSettingView(viewModel: RecipeRecommendationViewModel())
        .padding()
}