//
//  IngredientListItemView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct IngredientListItemView: View {
    let ingredient: AvailableIngredient
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconForIngredientType(ingredient.type))
                .foregroundColor(.brandOrange)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ingredient.name)
                        .font(.body)
                        .fontWeight(.medium)

                    Spacer()
                }

                HStack(spacing: 8) {
                    // 只在不是「適量」時顯示份量
                    if !isUnknownAmount(ingredient.amount) {
                        Text("\(ingredient.amount)\(ingredient.unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !ingredient.preparation.isEmpty && !isUnknownValue(ingredient.preparation) {
                        Text("• \(ingredient.preparation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                // Edit Button
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.title3)
                }

                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onEdit() // 點擊整個項目也能編輯
        }
    }

    // MARK: - Helper Methods

    private func iconForIngredientType(_ type: String) -> String {
        switch type {
        case "主食":
            return "grain.fill"
        case "蔬菜":
            return "carrot.fill"
        case "肉類":
            return "fork.knife"
        case "蛋類":
            return "oval.fill"
        case "海鮮":
            return "fish.fill"
        case "調料", "調味料":
            return "shippingbox.fill"
        default:
            return "questionmark.circle.fill"
        }
    }

    private func isUnknownAmount(_ amount: String) -> Bool {
        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed == "適量" ||
               trimmed == "适量" ||
               trimmed == "unknown" ||
               trimmed.isEmpty
    }

    private func isUnknownValue(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed == "未知" ||
               trimmed == "無" ||
               trimmed == "無特殊處理" ||
               trimmed == "unknown" ||
               trimmed.isEmpty
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        IngredientListItemView(
            ingredient: AvailableIngredient(
                name: "雞蛋",
                type: "蛋類",
                amount: "2",
                unit: "顆",
                preparation: "打散"
            ),
            onEdit: {},
            onDelete: {}
        )

        IngredientListItemView(
            ingredient: AvailableIngredient(
                name: "番茄",
                type: "蔬菜",
                amount: "1",
                unit: "顆",
                preparation: ""
            ),
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
}