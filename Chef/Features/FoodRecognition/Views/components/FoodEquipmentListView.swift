//
//  FoodEquipmentListView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 器具列表元件
struct FoodEquipmentListView: View {
    let equipment: [PossibleEquipment]
    let selectedEquipment: Set<UUID>
    let showSelection: Bool
    let groupByType: Bool
    let onSelectionChanged: ((Set<UUID>) -> Void)?

    init(
        equipment: [PossibleEquipment],
        selectedEquipment: Set<UUID> = [],
        showSelection: Bool = false,
        groupByType: Bool = true,
        onSelectionChanged: ((Set<UUID>) -> Void)? = nil
    ) {
        self.equipment = equipment
        self.selectedEquipment = selectedEquipment
        self.showSelection = showSelection
        self.groupByType = groupByType
        self.onSelectionChanged = onSelectionChanged
    }

    // 按類型分組的器具
    private var groupedEquipment: [String: [PossibleEquipment]] {
        if groupByType {
            return Dictionary(grouping: equipment, by: { $0.type })
        } else {
            return ["所有器具": equipment]
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 標頭
            SectionHeaderView.titleWithSubtitle(
                title: "可能的器具",
                subtitle: "共 \(equipment.count) 件器具",
                icon: "fork.knife"
            )

            // 器具列表
            if groupByType {
                groupedEquipmentView
            } else {
                simpleEquipmentView
            }

            // 全選/取消全選按鈕（如果啟用選擇模式）
            if showSelection {
                selectionControlButtons
            }
        }
    }

    // MARK: - 分組顯示

    private var groupedEquipmentView: some View {
        VStack(spacing: 16) {
            ForEach(groupedEquipment.keys.sorted(), id: \.self) { type in
                if let equipmentInType = groupedEquipment[type] {
                    equipmentGroupSection(
                        type: type,
                        equipment: equipmentInType
                    )
                }
            }
        }
    }

    private func equipmentGroupSection(
        type: String,
        equipment: [PossibleEquipment]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分組標題
            HStack {
                Text(type)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Spacer()

                Text("\(equipment.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 器具項目
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(equipment) { item in
                    equipmentItemView(item)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 簡單列表顯示

    private var simpleEquipmentView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(equipment) { item in
                equipmentItemView(item)
            }
        }
    }

    // MARK: - 器具項目視圖

    private func equipmentItemView(_ item: PossibleEquipment) -> some View {
        HStack(spacing: 8) {
            // 選擇框（如果啟用選擇模式）
            if showSelection {
                Image(systemName: isSelected(item) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected(item) ? .blue : .gray)
                    .onTapGesture {
                        toggleSelection(item)
                    }
            }

            // 器具圖示
            RoundedRectangle(cornerRadius: 6)
                .fill(typeColor(for: item.type).opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(equipmentEmoji(for: item))
                        .font(.body)
                )

            // 器具資訊
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if !groupByType {
                    Text(item.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 必需性指示器
            if isEssential(item) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            isSelected(item) ?
            Color.blue.opacity(0.1) :
            Color(.systemBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected(item) ?
                    Color.blue :
                    Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if showSelection {
                toggleSelection(item)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected(item))
    }

    // MARK: - 選擇控制按鈕

    private var selectionControlButtons: some View {
        HStack(spacing: 16) {
            Button("全部選擇") {
                let allIds = Set(equipment.map { $0.id })
                onSelectionChanged?(allIds)
            }
            .foregroundColor(.blue)

            Divider()
                .frame(height: 20)

            Button("取消全選") {
                onSelectionChanged?(Set())
            }
            .foregroundColor(.blue)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("已選擇 \(selectedEquipment.count) 項")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if hasEssentialItems {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("包含必需器具")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 輔助方法

    private func isSelected(_ item: PossibleEquipment) -> Bool {
        selectedEquipment.contains(item.id)
    }

    private func toggleSelection(_ item: PossibleEquipment) {
        var newSelection = selectedEquipment
        if newSelection.contains(item.id) {
            newSelection.remove(item.id)
        } else {
            newSelection.insert(item.id)
        }
        onSelectionChanged?(newSelection)
    }

    private func isEssential(_ item: PossibleEquipment) -> Bool {
        ["鍋具", "爐具", "主要工具"].contains(item.type)
    }

    private var hasEssentialItems: Bool {
        equipment.contains { isEssential($0) && isSelected($0) }
    }

    private func typeColor(for type: String) -> Color {
        switch type {
        case "鍋具":
            return .red
        case "工具":
            return .blue
        case "電器":
            return .purple
        case "餐具":
            return .green
        case "容器":
            return .orange
        default:
            return .gray
        }
    }

    private func equipmentEmoji(for item: PossibleEquipment) -> String {
        let name = item.name.lowercased()
        let type = item.type.lowercased()

        // 根據名稱和類型選擇 emoji
        if name.contains("鍋") {
            if name.contains("炒") {
                return "🍳"
            } else {
                return "🥘"
            }
        } else if name.contains("刀") {
            return "🔪"
        } else if name.contains("鏟") || name.contains("勺") {
            return "🥄"
        } else if name.contains("筷") {
            return "🥢"
        } else if name.contains("碗") {
            return "🥣"
        } else if name.contains("盤") {
            return "🍽️"
        } else if name.contains("爐") {
            return "🔥"
        } else if name.contains("微波") {
            return "📱"
        } else if name.contains("烤") {
            return "🔥"
        } else if type.contains("鍋具") {
            return "🍳"
        } else if type.contains("工具") {
            return "🔧"
        } else if type.contains("電器") {
            return "⚡"
        } else if type.contains("餐具") {
            return "🍽️"
        } else if type.contains("容器") {
            return "🥫"
        } else {
            return "🔧"
        }
    }
}

// MARK: - 預覽
#Preview {
    let sampleEquipment = [
        PossibleEquipment(name: "炒鍋", type: "鍋具"),
        PossibleEquipment(name: "鍋鏟", type: "工具"),
        PossibleEquipment(name: "菜刀", type: "工具"),
        PossibleEquipment(name: "砧板", type: "工具"),
        PossibleEquipment(name: "湯勺", type: "餐具"),
        PossibleEquipment(name: "碗", type: "餐具"),
        PossibleEquipment(name: "盤子", type: "餐具")
    ]

    VStack(spacing: 20) {
        FoodEquipmentListView(
            equipment: sampleEquipment,
            groupByType: true
        )

        FoodEquipmentListView(
            equipment: sampleEquipment,
            selectedEquipment: Set([sampleEquipment[0].id, sampleEquipment[1].id]),
            showSelection: true,
            groupByType: false,
            onSelectionChanged: { selection in
                print("選擇變更：\(selection)")
            }
        )
    }
    .padding()
}