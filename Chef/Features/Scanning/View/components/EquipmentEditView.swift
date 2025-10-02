import SwiftUI

struct EquipmentListView: View {
    @Binding var equipment: [Equipment]
    var onAdd: () -> Void
    var onEdit: (Equipment) -> Void
    var onDelete: (Equipment) -> Void

    var body: some View {
        CommonListView(
            title: "Equipment",
            items: $equipment,
            itemName: { $0.name },
            onAdd: onAdd,
            onEdit: onEdit,
            onDelete: onDelete
        )
    }
}

struct EquipmentEditView: View {
    @State private var equipment: Equipment
    let onSave: (Equipment) -> Void
    let onCancel: () -> Void
    
    private var isNameValid: Bool {
        !equipment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(
        equipment: Equipment,
        onSave: @escaping (Equipment) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _equipment = State(initialValue: equipment)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("名稱", text: $equipment.name)
                        .foregroundColor(isNameValid ? .primary : .red)
                    TextField("類型", text: $equipment.type)
                }
                
                Section("規格") {
                    TextField("尺寸", text: $equipment.size)
                    TextField("材質", text: $equipment.material)
                    TextField("電源", text: $equipment.power_source)
                }
            }
            .navigationTitle(equipment.name.isEmpty ? "新增設備" : "編輯設備")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        onSave(equipment)
                    }
                    .disabled(!isNameValid)
                }
            }
        }
    }
}
