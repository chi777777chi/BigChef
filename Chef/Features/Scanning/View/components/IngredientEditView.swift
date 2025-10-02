import SwiftUI

struct IngredientListView: View {
    @Binding var ingredients: [Ingredient]
    var onAdd: () -> Void
    var onEdit: (Ingredient) -> Void
    var onDelete: (Ingredient) -> Void

    var body: some View {
        CommonListView(
            title: "Ingredients",
            items: $ingredients,
            itemName: { $0.name },
            onAdd: onAdd,
            onEdit: onEdit,
            onDelete: onDelete
        )
    }
}

struct IngredientEditView: View {
    @State private var ingredient: Ingredient
    let onSave: (Ingredient) -> Void
    let onCancel: () -> Void
    
    private var isNameValid: Bool {
        !ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(
        ingredient: Ingredient,
        onSave: @escaping (Ingredient) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _ingredient = State(initialValue: ingredient)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("名稱", text: $ingredient.name)
                        .foregroundColor(isNameValid ? .primary : .red)
                    TextField("類型", text: $ingredient.type)
                }
                
                Section("數量") {
                    TextField("數量", text: $ingredient.amount)
                        .keyboardType(.decimalPad)
                    TextField("單位", text: $ingredient.unit)
                }
                
                Section("備註") {
                    TextField("處理方式", text: $ingredient.preparation)
                }
            }
            .navigationTitle(ingredient.name.isEmpty ? "新增食材" : "編輯食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        onSave(ingredient)
                    }
                    .disabled(!isNameValid)
                }
            }
        }
    }
}
