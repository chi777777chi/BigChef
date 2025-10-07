//
//  IngredientAdjustmentView.swift
//  ChefHelper
//
//  Created by Claude on 2025/10/07.
//

import SwiftUI

struct IngredientAdjustmentView: View {
    @StateObject private var viewModel: IngredientAdjustmentViewModel

    let onConfirm: ([String], [String]) -> Void

    init(
        ingredients: [PossibleIngredient],
        equipment: [PossibleEquipment],
        onConfirm: @escaping ([String], [String]) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: IngredientAdjustmentViewModel(
            ingredients: ingredients,
            equipment: equipment
        ))
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // 說明文字
                    instructionSection

                    // 食材區塊
                    ingredientsSection

                    // 器具區塊
                    equipmentSection

                    // 底部留白，避免內容被按鈕遮住
                    Color.clear.frame(height: 80)
                }
                .padding()
            }

            // 確認按鈕固定在底部
            VStack(spacing: 0) {
                Divider()
                confirmButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("調整食材器具")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var instructionSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 40))
                .foregroundColor(.brandOrange)

            Text("調整辨識結果")
                .font(.headline)

            Text("您可以刪除或修改辨識出的食材和器具，也可以新增其他項目")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.brandOrange.opacity(0.1))
        .cornerRadius(12)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("食材")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(viewModel.selectedIngredients.count) 項")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if viewModel.ingredients.isEmpty {
                emptyStateView(message: "尚未選擇任何食材")
            } else {
                ForEach(Array(viewModel.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    ingredientRow(ingredient: ingredient, at: index)
                }
            }

            // 新增食材按鈕
            Button(action: {
                viewModel.showingAddIngredient = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新增食材")
                }
                .font(.subheadline)
                .foregroundColor(.brandOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brandOrange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $viewModel.showingAddIngredient) {
            AddIngredientSheet(onAdd: { name in
                viewModel.addIngredient(name: name)
            })
        }
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("器具")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(viewModel.selectedEquipment.count) 項")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if viewModel.equipment.isEmpty {
                emptyStateView(message: "尚未選擇任何器具")
            } else {
                ForEach(Array(viewModel.equipment.enumerated()), id: \.offset) { index, equipment in
                    equipmentRow(equipment: equipment, at: index)
                }
            }

            // 新增器具按鈕
            Button(action: {
                viewModel.showingAddEquipment = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新增器具")
                }
                .font(.subheadline)
                .foregroundColor(.brandOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brandOrange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $viewModel.showingAddEquipment) {
            AddEquipmentSheet(onAdd: { name in
                viewModel.addEquipment(name: name)
            })
        }
        .sheet(item: Binding(
            get: { viewModel.editingIngredientIndex.map { EditItem(index: $0) } },
            set: { viewModel.editingIngredientIndex = $0?.index }
        )) { item in
            if item.index < viewModel.ingredients.count {
                EditIngredientSheet(
                    currentName: viewModel.ingredients[item.index].name,
                    onUpdate: { newName in
                        viewModel.updateIngredient(at: item.index, newName: newName)
                    }
                )
            }
        }
        .sheet(item: Binding(
            get: { viewModel.editingEquipmentIndex.map { EditItem(index: $0) } },
            set: { viewModel.editingEquipmentIndex = $0?.index }
        )) { item in
            if item.index < viewModel.equipment.count {
                EditEquipmentSheet(
                    currentName: viewModel.equipment[item.index].name,
                    onUpdate: { newName in
                        viewModel.updateEquipment(at: item.index, newName: newName)
                    }
                )
            }
        }
    }

    private struct EditItem: Identifiable {
        let id = UUID()
        let index: Int
    }

    private var confirmButton: some View {
        Button(action: {
            onConfirm(viewModel.selectedIngredients, viewModel.selectedEquipment)
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("確認食材")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canConfirm ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canConfirm)
    }

    // MARK: - Helper Views

    private func ingredientRow(ingredient: PossibleIngredient, at index: Int) -> some View {
        HStack {
            Image(systemName: viewModel.isIngredientSelected(ingredient.name) ? "checkmark.circle.fill" : "circle")
                .foregroundColor(viewModel.isIngredientSelected(ingredient.name) ? .blue : .gray)
                .onTapGesture {
                    viewModel.toggleIngredient(ingredient.name)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.body)
                Text(ingredient.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                viewModel.editIngredient(at: index)
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .padding(.trailing, 8)

            Button(action: {
                viewModel.removeIngredient(at: index)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private func equipmentRow(equipment: PossibleEquipment, at index: Int) -> some View {
        HStack {
            Image(systemName: viewModel.isEquipmentSelected(equipment.name) ? "checkmark.circle.fill" : "circle")
                .foregroundColor(viewModel.isEquipmentSelected(equipment.name) ? .orange : .gray)
                .onTapGesture {
                    viewModel.toggleEquipment(equipment.name)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.body)
                Text(equipment.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                viewModel.editEquipment(at: index)
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .padding(.trailing, 8)

            Button(action: {
                viewModel.removeEquipment(at: index)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private func emptyStateView(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}

// MARK: - ViewModel

@MainActor
class IngredientAdjustmentViewModel: ObservableObject {
    @Published var ingredients: [PossibleIngredient]
    @Published var equipment: [PossibleEquipment]
    @Published var selectedIngredientNames: Set<String>
    @Published var selectedEquipmentNames: Set<String>
    @Published var showingAddIngredient = false
    @Published var showingAddEquipment = false
    @Published var editingIngredientIndex: Int?
    @Published var editingEquipmentIndex: Int?

    var selectedIngredients: [String] {
        Array(selectedIngredientNames)
    }

    var selectedEquipment: [String] {
        Array(selectedEquipmentNames)
    }

    var canConfirm: Bool {
        !selectedIngredientNames.isEmpty
    }

    init(ingredients: [PossibleIngredient], equipment: [PossibleEquipment]) {
        self.ingredients = ingredients
        self.equipment = equipment
        self.selectedIngredientNames = Set(ingredients.map { $0.name })
        self.selectedEquipmentNames = Set(equipment.map { $0.name })
    }

    func isIngredientSelected(_ name: String) -> Bool {
        selectedIngredientNames.contains(name)
    }

    func isEquipmentSelected(_ name: String) -> Bool {
        selectedEquipmentNames.contains(name)
    }

    func toggleIngredient(_ name: String) {
        if selectedIngredientNames.contains(name) {
            selectedIngredientNames.remove(name)
        } else {
            selectedIngredientNames.insert(name)
        }
    }

    func toggleEquipment(_ name: String) {
        if selectedEquipmentNames.contains(name) {
            selectedEquipmentNames.remove(name)
        } else {
            selectedEquipmentNames.insert(name)
        }
    }

    func removeIngredient(at index: Int) {
        guard index < ingredients.count else { return }
        let ingredient = ingredients[index]
        selectedIngredientNames.remove(ingredient.name)
        ingredients.remove(at: index)
    }

    func removeEquipment(at index: Int) {
        guard index < equipment.count else { return }
        let equip = equipment[index]
        selectedEquipmentNames.remove(equip.name)
        equipment.remove(at: index)
    }

    func addIngredient(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newIngredient = PossibleIngredient(name: trimmedName, type: "其他")
        ingredients.append(newIngredient)
        selectedIngredientNames.insert(trimmedName)
    }

    func addEquipment(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newEquipment = PossibleEquipment(name: trimmedName, type: "其他")
        equipment.append(newEquipment)
        selectedEquipmentNames.insert(trimmedName)
    }

    func editIngredient(at index: Int) {
        guard index < ingredients.count else { return }
        editingIngredientIndex = index
    }

    func updateIngredient(at index: Int, newName: String) {
        guard index < ingredients.count else { return }
        let oldName = ingredients[index].name
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // 更新食材名稱
        ingredients[index] = PossibleIngredient(name: trimmedName, type: ingredients[index].type)

        // 更新選擇狀態
        if selectedIngredientNames.contains(oldName) {
            selectedIngredientNames.remove(oldName)
            selectedIngredientNames.insert(trimmedName)
        }
    }

    func editEquipment(at index: Int) {
        guard index < equipment.count else { return }
        editingEquipmentIndex = index
    }

    func updateEquipment(at index: Int, newName: String) {
        guard index < equipment.count else { return }
        let oldName = equipment[index].name
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // 更新器具名稱
        equipment[index] = PossibleEquipment(name: trimmedName, type: equipment[index].type)

        // 更新選擇狀態
        if selectedEquipmentNames.contains(oldName) {
            selectedEquipmentNames.remove(oldName)
            selectedEquipmentNames.insert(trimmedName)
        }
    }
}

// MARK: - Add Ingredient Sheet

struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ingredientName = ""
    @FocusState private var isFocused: Bool

    let onAdd: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("輸入食材名稱", text: $ingredientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .padding()

                Button(action: {
                    onAdd(ingredientName)
                    dismiss()
                }) {
                    Text("新增")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("新增食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Add Equipment Sheet

struct AddEquipmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var equipmentName = ""
    @FocusState private var isFocused: Bool

    let onAdd: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("輸入器具名稱", text: $equipmentName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .padding()

                Button(action: {
                    onAdd(equipmentName)
                    dismiss()
                }) {
                    Text("新增")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(equipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(equipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("新增器具")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Edit Ingredient Sheet

struct EditIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ingredientName: String
    @FocusState private var isFocused: Bool

    let onUpdate: (String) -> Void

    init(currentName: String, onUpdate: @escaping (String) -> Void) {
        self._ingredientName = State(initialValue: currentName)
        self.onUpdate = onUpdate
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("修改食材名稱", text: $ingredientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .padding()

                Button(action: {
                    onUpdate(ingredientName)
                    dismiss()
                }) {
                    Text("更新")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("編輯食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Edit Equipment Sheet

struct EditEquipmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var equipmentName: String
    @FocusState private var isFocused: Bool

    let onUpdate: (String) -> Void

    init(currentName: String, onUpdate: @escaping (String) -> Void) {
        self._equipmentName = State(initialValue: currentName)
        self.onUpdate = onUpdate
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("修改器具名稱", text: $equipmentName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .padding()

                Button(action: {
                    onUpdate(equipmentName)
                    dismiss()
                }) {
                    Text("更新")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(equipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(equipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("編輯器具")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    IngredientAdjustmentView(
        ingredients: [
            PossibleIngredient(name: "番茄", type: "蔬菜"),
            PossibleIngredient(name: "雞蛋", type: "蛋類")
        ],
        equipment: [
            PossibleEquipment(name: "炒鍋", type: "鍋具")
        ],
        onConfirm: { ingredients, equipment in
            print("選擇的食材：\(ingredients)")
            print("選擇的器具：\(equipment)")
        }
    )
}
