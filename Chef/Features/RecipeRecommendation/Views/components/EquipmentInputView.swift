//
//  EquipmentInputView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct EquipmentInputView: View {
    @State private var name = ""
    @State private var selectedType = "鍋具"
    @State private var selectedSize = "中等"
    @State private var selectedMaterial = ""
    @State private var selectedPowerSource = "無"
    @State private var validationErrors: [String] = []

    let equipmentTypes = ["鍋具", "刀具", "電器", "餐具", "其他"]
    let sizes = ["小型", "中等", "大型"]
    let materials = ["不鏽鋼", "鐵", "鋁", "不沾", "陶瓷", "玻璃", "塑膠", "木材", "其他"]
    let powerSources = ["無", "電", "瓦斯", "電池"]

    let editingEquipment: AvailableEquipment?
    let onSave: (AvailableEquipment) -> Void
    @Environment(\.dismiss) private var dismiss

    var isEditing: Bool {
        editingEquipment != nil
    }

    init(editingEquipment: AvailableEquipment? = nil, onSave: @escaping (AvailableEquipment) -> Void) {
        self.editingEquipment = editingEquipment
        self.onSave = onSave

        // 如果是編輯模式，預填現有資料
        if let equipment = editingEquipment {
            self._name = State(initialValue: equipment.name)
            self._selectedType = State(initialValue: equipment.type)
            self._selectedSize = State(initialValue: equipment.size)
            self._selectedMaterial = State(initialValue: equipment.material)
            self._selectedPowerSource = State(initialValue: equipment.powerSource)
        }
    }

    private var isFormValid: Bool {
        _ = validateForm()
        return validationErrors.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("器具資訊") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("器具名稱")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("*")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                        }

                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                                .foregroundColor(.brandOrange)
                                .frame(width: 20)

                            TextField("例如：平底鍋", text: $name)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !validationErrors.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("器具類型")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("器具類型", selection: $selectedType) {
                            ForEach(equipmentTypes, id: \.self) { type in
                                HStack {
                                    Image(systemName: iconForType(type))
                                    Text(type)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                Section("規格") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("大小")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("大小", selection: $selectedSize) {
                            ForEach(sizes, id: \.self) { size in
                                Text(size).tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("材質")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("材質", selection: $selectedMaterial) {
                            Text("未指定").tag("")
                            ForEach(materials, id: \.self) { material in
                                Text(material).tag(material)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("電源需求")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("電源", selection: $selectedPowerSource) {
                            ForEach(powerSources, id: \.self) { source in
                                HStack {
                                    Image(systemName: iconForPowerSource(source))
                                    Text(source)
                                }
                                .tag(source)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                Section {
                    Text("填寫您擁有的廚房器具資訊，幫助AI推薦更適合的食譜")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !validationErrors.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("請修正以下問題：")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(validationErrors, id: \.self) { error in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle(isEditing ? "編輯器具" : "新增器具")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "更新" : "完成") {
                        _ = validateForm()
                        if validationErrors.isEmpty {
                            let equipment = AvailableEquipment(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                type: selectedType,
                                size: selectedSize,
                                material: selectedMaterial,
                                powerSource: selectedPowerSource
                            )
                            onSave(equipment)
                            dismiss()
                        }
                    }
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Private Methods

    private func validateForm() -> Bool {
        validationErrors.removeAll()
        return true
    }

    // MARK: - Validation Helper Methods

    private func isLikelyIngredientName(_ name: String) -> Bool {
        let commonIngredients = [
            // 肉類
            "牛排", "豬肉", "雞肉", "魚", "蝦", "蟹", "羊肉", "鴨肉", "火腿", "香腸",
            // 蔬菜
            "白菜", "高麗菜", "花椰菜", "胡蘿蔔", "洋蔥", "蒜", "薑", "蔥", "韭菜", "菠菜",
            "番茄", "馬鈴薯", "地瓜", "玉米", "豆腐", "豆芽", "青椒", "茄子", "黃瓜",
            // 主食
            "米", "麵條", "麵包", "饅頭", "水餃", "包子", "年糕", "麵粉",
            // 蛋奶類
            "蛋", "雞蛋", "牛奶", "起司", "奶油", "優格",
            // 調料
            "鹽", "糖", "醋", "醬油", "味精", "胡椒", "辣椒", "香菜", "芝麻"
        ]

        let lowercaseName = name.lowercased()
        return commonIngredients.contains { ingredient in
            lowercaseName.contains(ingredient.lowercased())
        }
    }

    private func isValidEquipmentName(_ name: String) -> Bool {
        let commonEquipment = [
            // 鍋具
            "平底鍋", "炒鍋", "湯鍋", "蒸鍋", "壓力鍋", "電鍋", "砂鍋", "不沾鍋", "鐵鍋", "不鏽鋼鍋",
            // 刀具
            "菜刀", "水果刀", "麵包刀", "剁刀", "削皮刀", "刨刀",
            // 電器
            "微波爐", "烤箱", "電磁爐", "瓦斯爐", "攪拌機", "果汁機", "咖啡機", "電熱水壺", "烤土司機",
            "氣炸鍋", "電子鍋", "慢燉鍋", "豆漿機",
            // 餐具和工具
            "鍋鏟", "湯勺", "漏勺", "夾子", "開瓶器", "削皮器", "磨刀器", "砧板", "量杯", "打蛋器",
            "篩子", "漏斗", "保鮮盒", "烘焙紙"
        ]

        let lowercaseName = name.lowercased()

        // 檢查是否包含常見器具關鍵字
        let equipmentKeywords = ["鍋", "刀", "機", "爐", "器", "杯", "盤", "碗", "鏟", "勺", "夾", "板"]
        let hasEquipmentKeyword = equipmentKeywords.contains { keyword in
            lowercaseName.contains(keyword)
        }

        // 檢查是否為常見器具名稱
        let isCommonEquipment = commonEquipment.contains { equipment in
            lowercaseName.contains(equipment.lowercased()) || equipment.lowercased().contains(lowercaseName)
        }

        return hasEquipmentKeyword || isCommonEquipment
    }

    // MARK: - Helper Methods

    private func iconForType(_ type: String) -> String {
        switch type {
        case "鍋具":
            return "frying.pan.fill"
        case "刀具":
            return "scissors"
        case "電器":
            return "power.circle.fill"
        case "餐具":
            return "fork.knife.circle.fill"
        default:
            return "wrench.and.screwdriver.fill"
        }
    }

    private func iconForPowerSource(_ source: String) -> String {
        switch source {
        case "電":
            return "power.circle.fill"
        case "瓦斯":
            return "flame.fill"
        case "電池":
            return "battery.100.bolt"
        default:
            return "minus.circle"
        }
    }
}

// MARK: - Preview

#Preview {
    EquipmentInputView(editingEquipment: nil) { equipment in
        print("保存器具: \(equipment)")
    }
}