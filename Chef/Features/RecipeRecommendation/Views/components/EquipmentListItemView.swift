//
//  EquipmentListItemView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct EquipmentListItemView: View {
    let equipment: AvailableEquipment
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconForEquipmentType(equipment.type))
                .foregroundColor(.brandOrange)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(equipment.name)
                        .font(.body)
                        .fontWeight(.medium)

                    Spacer()
                }

                HStack(spacing: 8) {
                    if !equipment.size.isEmpty && !isUnknownValue(equipment.size) {
                        Text(equipment.size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.material.isEmpty && !isUnknownValue(equipment.material) {
                        Text("• \(equipment.material)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.powerSource.isEmpty && !isUnknownOrManualPower(equipment.powerSource) {
                        Text("• \(equipment.powerSource)")
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

    private func iconForEquipmentType(_ type: String) -> String {
        switch type {
        case "鍋具":
            return "frying.pan.fill"
        case "刀具":
            return "fork.knife"
        case "電器":
            return "power.circle.fill"
        case "餐具":
            return "fork.knife.circle.fill"
        default:
            return "wrench.and.screwdriver.fill"
        }
    }

    private func isUnknownValue(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed == "未知" || trimmed == "無" || trimmed == "unknown" || trimmed.isEmpty
    }

    private func isUnknownOrManualPower(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed == "未知" ||
               trimmed == "無" ||
               trimmed == "人力" ||
               trimmed == "manual" ||
               trimmed == "unknown" ||
               trimmed.isEmpty
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        EquipmentListItemView(
            equipment: AvailableEquipment(
                name: "平底鍋",
                type: "鍋具",
                size: "中型",
                material: "不沾",
                powerSource: "電"
            ),
            onEdit: {},
            onDelete: {}
        )

        EquipmentListItemView(
            equipment: AvailableEquipment(
                name: "菜刀",
                type: "刀具",
                size: "標準",
                material: "不鏽鋼",
                powerSource: ""
            ),
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
}