//
//  IngredientInputView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct IngredientInputView: View {
    @State private var name = ""
    @State private var selectedType = "主食"
    @State private var amount = ""
    @State private var selectedUnit = "個"
    @State private var preparation = ""
    @State private var validationErrors: [String] = []

    let ingredientTypes = ["主食", "蔬菜", "肉類", "蛋類", "海鮮", "調料", "其他"]
    let units = ["個", "顆", "片", "克", "毫升", "湯匙", "茶匙", "少許", "適量"]

    let editingIngredient: AvailableIngredient?
    let onSave: (AvailableIngredient) -> Void
    @Environment(\.dismiss) private var dismiss

    var isEditing: Bool {
        editingIngredient != nil
    }

    init(editingIngredient: AvailableIngredient? = nil, onSave: @escaping (AvailableIngredient) -> Void) {
        self.editingIngredient = editingIngredient
        self.onSave = onSave

        // 如果是編輯模式，預填現有資料
        if let ingredient = editingIngredient {
            self._name = State(initialValue: ingredient.name)
            self._selectedType = State(initialValue: ingredient.type)
            self._amount = State(initialValue: ingredient.amount)
            self._selectedUnit = State(initialValue: ingredient.unit)
            self._preparation = State(initialValue: ingredient.preparation == "無特殊處理" ? "" : ingredient.preparation)
        }
    }

    private var isFormValid: Bool {
        _ = validateForm()
        return validationErrors.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("食材資訊") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("食材名稱")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("*")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                        }

                        HStack {
                            Image(systemName: "carrot.fill")
                                .foregroundColor(.brandOrange)
                                .frame(width: 20)

                            TextField("例如：雞蛋", text: $name)
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
                        Text("食材類型")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("食材類型", selection: $selectedType) {
                            ForEach(ingredientTypes, id: \.self) { type in
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

                Section("數量") {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("數量")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("*")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(.brandOrange)
                                    .frame(width: 20)

                                TextField("例如：2", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !validationErrors.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("單位")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("單位", selection: $selectedUnit) {
                                ForEach(units, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }

                Section("處理方式（可選）") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("處理方式")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "scissors")
                                .foregroundColor(.brandOrange)
                                .frame(width: 20)

                            TextField("例如：切塊、打散", text: $preparation)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    Text("描述如何預處理這個食材，例如：切塊、切絲、打散等")
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
            .navigationTitle(isEditing ? "編輯食材" : "新增食材")
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
                            let ingredient = AvailableIngredient(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                type: selectedType,
                                amount: amount.trimmingCharacters(in: .whitespacesAndNewlines),
                                unit: selectedUnit,
                                preparation: preparation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "無特殊處理" : preparation.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            onSave(ingredient)
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Private Methods

    private func validateForm() -> Bool {
        validationErrors.removeAll()

        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedAmount.isEmpty {
            validationErrors.append("請輸入數量")
        }

        return validationErrors.isEmpty
    }

    // MARK: - Validation Helper Methods

    private func isLikelyEquipmentName(_ name: String) -> Bool {
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

    private func isValidIngredientName(_ name: String) -> Bool {
        let commonIngredients = [
            // 肉類
            "牛排", "豬肉", "雞肉", "魚", "蝦", "蟹", "羊肉", "鴨肉", "火腿", "香腸", "牛肉", "豬排", "雞翅", "雞腿",
            "培根", "臘肉", "鮭魚", "鯖魚", "蛤蜊", "花枝", "章魚", "干貝",
            // 蔬菜
            "白菜", "高麗菜", "花椰菜", "胡蘿蔔", "洋蔥", "蒜", "薑", "蔥", "韭菜", "菠菜",
            "番茄", "馬鈴薯", "地瓜", "玉米", "豆腐", "豆芽", "青椒", "茄子", "黃瓜", "萵苣",
            "芹菜", "韭黃", "空心菜", "小白菜", "青江菜", "A菜", "絲瓜", "冬瓜", "南瓜",
            // 主食
            "米", "麵條", "麵包", "饅頭", "水餃", "包子", "年糕", "麵粉", "白米", "糙米", "義大利麵",
            "烏龍麵", "拉麵", "河粉", "米粉", "粄條", "吐司",
            // 蛋奶類
            "蛋", "雞蛋", "鴨蛋", "鵪鶉蛋", "牛奶", "起司", "奶油", "優格", "鮮奶油", "煉乳",
            // 調料和香料
            "鹽", "糖", "醋", "醬油", "味精", "胡椒", "辣椒", "香菜", "芝麻", "八角", "桂皮", "花椒",
            "孜然", "咖哩粉", "五香粉", "白胡椒", "黑胡椒", "蒜粉", "薑粉",
            // 豆類和堅果
            "黃豆", "黑豆", "紅豆", "綠豆", "花生", "杏仁", "核桃", "腰果", "開心果",
            // 水果（有時也會入菜）
            "蘋果", "香蕉", "鳳梨", "芒果", "檸檬", "橘子", "葡萄", "草莓", "奇異果",
            // 海帶類
            "海帶", "紫菜", "昆布", "海苔"
        ]

        let lowercaseName = name.lowercased()

        // 檢查是否包含常見食材關鍵字
        let ingredientKeywords = ["肉", "菜", "蛋", "豆", "粉", "醬", "油", "糖", "鹽", "米", "麵"]
        let hasIngredientKeyword = ingredientKeywords.contains { keyword in
            lowercaseName.contains(keyword)
        }

        // 檢查是否為常見食材名稱
        let isCommonIngredient = commonIngredients.contains { ingredient in
            lowercaseName.contains(ingredient.lowercased()) || ingredient.lowercased().contains(lowercaseName)
        }

        return hasIngredientKeyword || isCommonIngredient
    }

    // MARK: - Helper Methods

    private func iconForType(_ type: String) -> String {
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
        case "調料":
            return "shippingbox.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    IngredientInputView(editingIngredient: nil) { ingredient in
        print("保存食材: \(ingredient)")
    }
}