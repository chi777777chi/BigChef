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

    let onSave: (AvailableIngredient) -> Void
    @Environment(\.dismiss) private var dismiss

    private var isFormValid: Bool {
        validateForm()
        return validationErrors.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("食材資訊") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("食材名稱")
                            .font(.caption)
                            .foregroundColor(.secondary)

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
                            Text("數量")
                                .font(.caption)
                                .foregroundColor(.secondary)

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
            }
            .navigationTitle("新增食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        if isFormValid {
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
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .brandOrange : .gray)
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

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            validationErrors.append("請輸入食材名稱")
        }

        if trimmedAmount.isEmpty {
            validationErrors.append("請輸入數量")
        }

        return validationErrors.isEmpty
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
    IngredientInputView { ingredient in
        print("保存食材: \(ingredient)")
    }
}