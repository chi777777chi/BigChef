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
        validateForm()
        return validationErrors.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("器具資訊") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("器具名稱")
                            .font(.caption)
                            .foregroundColor(.secondary)

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
                        if isFormValid {
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
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .brandOrange : .gray)
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

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            validationErrors.append("請輸入器具名稱")
        }

        return validationErrors.isEmpty
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