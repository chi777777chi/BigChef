//
//  LoginView.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/4/10.
//

//import Firebase
import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordValid = false
    @State private var isEmailValid = false
    
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
                    
                    SecureInputField(
                        placeholder: "密碼",
                        iconName: "lock",
                        text: $password,
                        mode: .login,
                        onValidationChanged: { isValid in
                            isPasswordValid = isValid
                        }
                    )
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)
                
                // Forgot password
                Button {
                    // TODO: Implement forgot password
                } label: {
                    Text("忘記密碼？")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandOrange)
                        .padding(.top, 8)
                }
                
                // Sign in button
                Button {
                    Task {
                        await viewModel.login(withEmail: email, password: password)
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text("登入")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 64, height: 48)
                    .background(
                        (isEmailValid && isPasswordValid) ? Color.brandOrange : Color.gray
                    )
                    .cornerRadius(10)
                }
                .disabled(!isEmailValid || !isPasswordValid || viewModel.isLoading)
                .padding(.top, 24)
                
                Spacer()
                
                // Sign up link
                NavigationLink(destination: RegistrationView(viewModel: viewModel)) {
                    HStack(spacing: 3) {
                        Text("還沒有帳號？")
                            .foregroundColor(.gray)
                        Text("註冊")
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: AuthViewModel())
    }
}
