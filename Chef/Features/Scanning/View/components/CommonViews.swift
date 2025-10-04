import SwiftUI

// MARK: - Common List View
struct CommonListView<T: Identifiable & Equatable>: View {
    let title: String
    @Binding var items: [T]
    let itemName: (T) -> String
    var onAdd: () -> Void
    var onEdit: (T) -> Void
    var onDelete: (T) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title).font(.title2).bold()
                Spacer()
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus.circle")
                        .labelStyle(IconOnlyLabelStyle())
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
            
            LazyVStack {
                ForEach(items) { item in
                    HStack {
                        Text(itemName(item))
                        Spacer()
                        Button("Edit") { onEdit(item) }
                            .buttonStyle(BorderlessButtonStyle())
                        Button(role: .destructive) { onDelete(item) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Common Edit View
struct CommonEditView<T: Identifiable & Equatable>: View {
    let title: String
    @Binding var item: T
    var fields: [(String, Binding<String>, Bool)]
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errors: [String: String] = [:]
    
    private var hasErrors: Bool {
        !errors.isEmpty
    }
    
    private var requiredFieldsAreValid: Bool {
        fields.allSatisfy { field in
            let (_, binding, isRequired) = field
            if !isRequired { return true }
            return !binding.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    private var canSave: Bool {
        !hasErrors && requiredFieldsAreValid
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(fields, id: \.0) { field in
                        VStack(alignment: .leading, spacing: 4) {
                            TextField(field.0 + (field.2 ? " *" : ""), text: field.1)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: field.1.wrappedValue) { oldValue, newValue in
                                    validateField(field.0, binding: field.1, isRequired: field.2)
                                }
                            if let error = errors[field.0] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    if fields.contains(where: { $0.2 }) {
                        Text("Fields marked with * are required")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func validateField(_ name: String, binding: Binding<String>, isRequired: Bool) {
        if isRequired && binding.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty {
            errors[name] = "\(name) is required"
        } else {
            errors.removeValue(forKey: name)
        }
    }
}

// MARK: - View Modifiers
extension View {
    func roundedTextField() -> some View {
        self.textFieldStyle(.roundedBorder)
    }
    
    func listRowStyle() -> some View {
        self.padding(.vertical, 4)
    }
} 
