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
            VStack(alignment: .leading, spacing: 8) {
                Text("份量")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("份量", selection: Binding(
                    get: { viewModel.preference.servingSize ?? "1人份" },
                    set: { viewModel.updateServingSize($0) }
                )) {
                    ForEach(viewModel.servingSizes, id: \.self) { size in
                        HStack {
                            Image(systemName: "person.fill")
                            Text(size)
                        }
                        .tag(size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
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