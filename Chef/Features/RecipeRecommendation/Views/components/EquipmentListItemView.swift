//
//  EquipmentListItemView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct EquipmentListItemView: View {
    let equipment: AvailableEquipment
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

                    Text("(\(equipment.type))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                HStack(spacing: 8) {
                    if !equipment.size.isEmpty {
                        Text(equipment.size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.material.isEmpty {
                        Text("• \(equipment.material)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.powerSource.isEmpty && equipment.powerSource != "無" {
                        Text("• \(equipment.powerSource)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
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
            onDelete: {}
        )
    }
    .padding()
}