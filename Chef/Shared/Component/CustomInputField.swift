//
//  CustomInputField.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//

import SwiftUI

struct CustomInputField: View {
    let imageName: String
    let placeholderText: String
    @Binding var text: String
    var textCase: Text.Case?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var textInputAutoCapital: TextInputAutocapitalization = .never
    var isSecureField: Bool = false
    var validationRules: [(String) -> Bool] = []
    var errorMessage: String?
    
    @State private var isValid: Bool = true
    @State private var showError: Bool = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(.darkGray))
                
                Group {
                    if isSecureField {
                        SecureField(placeholderText, text: $text)
                            .textContentType(textContentType)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(textInputAutoCapital)
                    } else {
                        TextField(placeholderText, text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(textInputAutoCapital)
                            .onChange(of: text) { oldValue, newValue in
                                if textCase != nil {
                                    text = applyTextCase(newValue)
                                }
                                validateInput(newValue)
                            }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.gray.opacity(0.3) : Color.red, lineWidth: 1)
            )
            .offset(x: shakeOffset)
            
            if showError, let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
    
    private func validateInput(_ input: String) {
        let newIsValid = validationRules.isEmpty || validationRules.allSatisfy { $0(input) }
        
        if !newIsValid && isValid {
            withAnimation(.default) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) {
                    shakeOffset = -10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.default) {
                        shakeOffset = 0
                    }
                }
            }
        }
        
        isValid = newIsValid
        showError = !newIsValid && !input.isEmpty
    }
    
    private func applyTextCase(_ text: String) -> String {
        switch textCase {
        case .lowercase:
            return text.lowercased()
        case .uppercase:
            return text.uppercased()
        case .none:
            return text
        @unknown default:
            return text
        }
    }
}

struct CustomInputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomInputField(
                imageName: "envelope",
                placeholderText: "電子郵件",
                text: .constant(""),
                textCase: .lowercase,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                validationRules: [
                    { $0.contains("@") },
                    { $0.contains(".") }
                ],
                errorMessage: "請輸入有效的電子郵件地址"
            )
            
            CustomInputField(
                imageName: "person",
                placeholderText: "使用者名稱",
                text: .constant(""),
                textCase: .lowercase,
                keyboardType: .default,
                textContentType: .username,
                validationRules: [
                    { $0.count >= 3 },
                    { $0.count <= 20 }
                ],
                errorMessage: "使用者名稱長度需在3-20個字符之間"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
