import SwiftUI

struct IngredientSectionView: View {
    let ingredients: [Ingredient]
    let onAdd: () -> Void
    let onEdit: (Ingredient) -> Void
    let onDelete: (Ingredient) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "可用食材",
                onAdd: onAdd
            )
            
            ForEach(ingredients) { item in
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