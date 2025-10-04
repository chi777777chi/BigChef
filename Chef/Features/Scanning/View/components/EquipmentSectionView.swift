import SwiftUI

struct EquipmentSectionView: View {
    let equipment: [Equipment]
    let onAdd: () -> Void
    let onEdit: (Equipment) -> Void
    let onDelete: (Equipment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "可用設備",
                onAdd: onAdd
            )
            
            ForEach(equipment) { item in
                HStack {
                    Text(item.name)
                        .font(.body)
                    
                    Spacer()
                    
                    Button(action: { onEdit(item) }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.accentColor)
                    }
                    
                    Button(action: { onDelete(item) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    EquipmentSectionView(
        equipment: [],
        onAdd: {},
        onEdit: { _ in },
        onDelete: { _ in }
    )
} 