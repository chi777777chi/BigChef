import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                Alert(
                    title: Text("錯誤"),
                    message: Text(error?.localizedDescription ?? "發生未知錯誤"),
                    dismissButton: .default(Text("確定")) {
                        error = nil
                    }
                )
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, isPresented: Binding<Bool>) -> some View {
        modifier(ErrorAlertModifier(error: error, isPresented: isPresented))
    }
} 