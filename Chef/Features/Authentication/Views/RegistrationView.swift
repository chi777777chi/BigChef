//
//  RegistrationView.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/5.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var username = ""
    @State private var fullname = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordValid = false
    @State private var isConfirmPasswordValid = false
    @State private var isEmailValid = false
    @State private var isUsernameValid = false
    @State private var isFullnameValid = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Logo
                Image("QuickFeatLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .padding(.vertical, 32)
                
                // Form fields
                VStack(spacing: 24) {
                    CustomInputField(
                        imageName: "envelope",
                        placeholderText: "電子郵件",
                        text: $email,
                        textCase: .lowercase,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        validationRules: [
                            { $0.contains("@") },
                            { $0.contains(".") },
                            { $0.count >= 5 }
                        ],
                        errorMessage: "請輸入有效的電子郵件地址"
                    )
                    .onChange(of: email) { oldValue, newValue in
                        isEmailValid = newValue.contains("@") && newValue.contains(".") && newValue.count >= 5
                    }
                    
                    CustomInputField(
                        imageName: "person",
                        placeholderText: "使用者名稱",
                        text: $username,
                        textCase: .lowercase,
                        keyboardType: .default,
                        textContentType: .username,
                        validationRules: [
                            { $0.count >= 3 },
                            { $0.count <= 20 },
                            { $0.range(of: "^[a-zA-Z0-9_]+$", options: .regularExpression) != nil }
                        ],
                        errorMessage: "使用者名稱需為3-20個字符，只能包含英文字母、數字和底線"
                    )
                    .onChange(of: username) { oldValue, newValue in
                        isUsernameValid = newValue.count >= 3 && newValue.count <= 20 &&
                            newValue.range(of: "^[a-zA-Z0-9_]+$", options: .regularExpression) != nil
                    }
                    
                    CustomInputField(
                        imageName: "person.fill",
                        placeholderText: "姓名",
                        text: $fullname,
                        textCase: nil,
                        keyboardType: .default,
                        textContentType: .name,
                        validationRules: [
                            { $0.count >= 2 },
                            { $0.count <= 50 }
                        ],
                        errorMessage: "姓名長度需在2-50個字符之間"
                    )
                    .onChange(of: fullname) { oldValue, newValue in
                        isFullnameValid = newValue.count >= 2 && newValue.count <= 50
                    }
                    
                    SecureInputField(
                        placeholder: "密碼",
                        iconName: "lock",
                        text: $password,
                        confirmText: $confirmPassword,
                        mode: .register,
                        onValidationChanged: { isValid in
                            isPasswordValid = isValid
                        }
                    )
                    
                    SecureInputField(
                        placeholder: "確認密碼",
                        iconName: "lock",
                        text: $confirmPassword,
                        confirmText: $password,
                        mode: .register,
                        isConfirmField: true,
                        onValidationChanged: { isValid in
                            isConfirmPasswordValid = isValid
                        }
                    )
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)
                
                // Sign up button
                Button {
                    Task {
                        await viewModel.register(
                            withEmail: email,
                            password: password,
                            fullname: fullname,
                            username: username
                        )
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text("註冊")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 64, height: 48)
                    .background(
                        (isEmailValid && isUsernameValid && isFullnameValid && 
                         isPasswordValid && isConfirmPasswordValid) ? Color.brandOrange : Color.gray
                    )
                    .cornerRadius(10)
                }
                .disabled(
                    !isEmailValid || !isUsernameValid || !isFullnameValid || 
                    !isPasswordValid || !isConfirmPasswordValid || viewModel.isLoading
                )
                .padding(.top, 24)
                
                Spacer()
                
                // Sign in link
                NavigationLink {
                    LoginView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 3) {
                        Text("已有帳號？")
                            .foregroundColor(.gray)
                        Text("登入")
                            .fontWeight(.bold)
                            .foregroundColor(.brandOrange)
                    }
                    .font(.footnote)
                }
                .padding(.bottom, 32)
            }
        }
        .alert("錯誤", isPresented: $viewModel.showError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "發生未知錯誤")
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView(viewModel: AuthViewModel())
    }
}
