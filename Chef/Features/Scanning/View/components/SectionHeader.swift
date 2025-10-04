import SwiftUI

struct SectionHeader: View {
    let title: String
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
} 