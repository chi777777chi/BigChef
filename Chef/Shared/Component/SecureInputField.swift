import SwiftUI

struct PasswordValidationRule {
    let regex: String
    let message: String
    let isRequired: Bool
    let weight: Double  // 新增權重屬性
    
    static let rules: [PasswordValidationRule] = [
        PasswordValidationRule(
            regex: "^.{8,}$",
            message: "密碼長度至少8個字符",
            isRequired: true,
            weight: 0.0  // 基礎要求，不計入強度
        ),
        PasswordValidationRule(
            regex: ".*[A-Z].*",
            message: "包含大寫字母",
            isRequired: true,
            weight: 0.25
        ),
        PasswordValidationRule(
            regex: ".*[a-z].*",
            message: "包含小寫字母",
            isRequired: true,
            weight: 0.25
        ),
        PasswordValidationRule(
            regex: ".*[0-9].*",
            message: "包含數字",
            isRequired: true,
            weight: 0.25
        )
    ]
}

struct SecureInputField: View {
    enum Mode {
        case login      // 登入模式：只顯示密碼輸入框和顯示/隱藏按鈕
        case register   // 註冊模式：包含密碼強度、驗證規則等
    }
    
    let placeholder: String
    let iconName: String
    @Binding var text: String
    var confirmText: Binding<String>?
    var mode: Mode = .login  // 默認為登入模式
    var isConfirmField: Bool = false
    var onValidationChanged: ((Bool) -> Void)?
    
    @State private var isSecured: Bool = true
    @State private var validationResults: [Bool] = []
    @State private var showValidationRules: Bool = false
    @State private var isCapsLockOn: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showMaxLengthWarning: Bool = false
    
    private let maxPasswordLength = 20
    
    private var isValid: Bool {
        switch mode {
        case .login:
            return !text.isEmpty
        case .register:
            if isConfirmField {
                // 確認密碼欄位只需要檢查是否與密碼相同
                return !text.isEmpty && text == confirmText?.wrappedValue
            }
            // 密碼欄位需要檢查所有驗證規則
            return validationResults.allSatisfy { $0 } && text.count <= maxPasswordLength
        }
    }
    
    private var passwordStrength: Double {
        guard mode == .register else { return 1.0 }
        
        // 如果超過最大長度，返回0表示無效
        if text.count > maxPasswordLength {
            return 0.0
        }
        
        // 完全基於長度判斷強度
        switch text.count {
        case 1..<6:
            return 0.3  // 無效
        case 6..<10:
            return 0.6  // 弱
        case 10..<15:
            return 0.8  // 中
        case 15..<21:
            return 1.0  // 強
        default:
            return 0.0  // 無效
        }
    }
    
    private var borderColor: Color {
        switch mode {
        case .login:
            return Color(.systemGray4)  // 使用系統灰色
        case .register:
            if isConfirmField {
                // 確認密碼欄位的邊框顏色只取決於是否與密碼相同
                if text.isEmpty {
                    return Color(.systemGray4)
                }
                return text == confirmText?.wrappedValue ? .green : .red
            }
            // 密碼欄位使用原有的驗證邏輯
            return isValid ? .green : .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                Group {
                    if isSecured {
                        SecureField(placeholder, text: Binding(
                            get: { text },
                            set: { newValue in
                                if newValue.count <= maxPasswordLength {
                                    text = newValue
                                    handleTextChange(newValue)
                                } else {
                                    // 觸發搖晃動畫
                                    withAnimation(.default) {
                                        shakeOffset = 10
                                        showMaxLengthWarning = true
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
                            }
                        ))
                        .textContentType(isConfirmField ? .newPassword : .password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    } else {
                        TextField(placeholder, text: Binding(
                            get: { text },
                            set: { newValue in
                                if newValue.count <= maxPasswordLength {
                                    text = newValue
                                    handleTextChange(newValue)
                                } else {
                                    // 觸發搖晃動畫
                                    withAnimation(.default) {
                                        shakeOffset = 10
                                        showMaxLengthWarning = true
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
                            }
                        ))
                        .textContentType(isConfirmField ? .newPassword : .password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    }
                }
                
                Button(action: { isSecured.toggle() }) {
                    Image(systemName: isSecured ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .offset(x: shakeOffset)
            
            if mode == .register {
                if !isConfirmField {
                    // 密碼強度指示器和驗證規則（只在密碼欄位顯示）
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("密碼強度")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(strengthText)
                                .font(.caption)
                                .foregroundColor(strengthColor)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 4)
                                    .opacity(0.3)
                                    .foregroundColor(.gray)
                                
                                Rectangle()
                                    .frame(width: geometry.size.width * passwordStrength, height: 4)
                                    .foregroundColor(strengthColor)
                            }
                        }
                        .frame(height: 4)
                        
                        if showMaxLengthWarning {
                            Text("密碼長度不能超過\(maxPasswordLength)個字符")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        
                        if showValidationRules {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(PasswordValidationRule.rules.enumerated()), id: \.offset) { index, rule in
                                    HStack {
                                        Image(systemName: validationResults[index] ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(validationResults[index] ? .green : .red)
                                        Text(rule.message)
                                            .font(.caption)
                                            .foregroundColor(validationResults[index] ? .green : .red)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                } else {
                    // 確認密碼欄位的提示信息
                    if !text.isEmpty {
                        if text == confirmText?.wrappedValue {
                            Text("密碼相符")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.leading, 4)
                        } else {
                            Text("兩次輸入的密碼不一致")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                }
            }
            
            if isCapsLockOn {
                Text("大寫鎖定已開啟")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.leading, 4)
            }
        }
        .onAppear {
            if mode == .register {
                validationResults = Array(repeating: false, count: PasswordValidationRule.rules.count)
            }
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        if mode == .register {
            showMaxLengthWarning = false
            validatePassword(newValue)
            if isConfirmField {
                validateConfirmation()
            }
        }
        onValidationChanged?(isValid)
    }
    
    private var strengthText: String {
        if text.count > maxPasswordLength {
            return "無效"
        }
        switch text.count {
        case 1..<6:
            return "弱"
        case 6..<10:
            return "中"
        case 10..<15:
            return "強"
        case 15..<21:
            return "非常強"
        default:
            return "無效"
        }
    }
    
    private var strengthColor: Color {
        if text.count > maxPasswordLength {
            return .red
        }
        switch text.count {
        case 1..<6:
            return .red
        case 6..<10:
            return .orange
        case 10..<15:
            return .green
        case 15..<21:
            return .blue
        default:
            return .red
        }
    }
    
    private func validatePassword(_ password: String) {
        if isConfirmField {
            // 確認密碼欄位不需要驗證規則，只需要檢查是否與密碼相同
            validationResults = Array(repeating: true, count: PasswordValidationRule.rules.count)
            showValidationRules = false
        } else {
            // 密碼欄位需要驗證所有規則
            validationResults = PasswordValidationRule.rules.map { rule in
                let predicate = NSPredicate(format: "SELF MATCHES %@", rule.regex)
                return predicate.evaluate(with: password)
            }
            showValidationRules = !password.isEmpty
        }
        onValidationChanged?(isValid)
    }
    
    private func validateConfirmation() {
        if let confirmText = confirmText, text != confirmText.wrappedValue {
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
    }
}

struct SecureInputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // 登入時的密碼輸入
            SecureInputField(
                placeholder: "密碼",
                iconName: "lock",
                text: .constant(""),
                mode: .login
            )
            .padding()
            
            // 註冊時的密碼輸入
            SecureInputField(
                placeholder: "密碼",
                iconName: "lock",
                text: .constant(""),
                confirmText: .constant(""),
                mode: .register
            )
            .padding()
            
            // 註冊時的確認密碼輸入
            SecureInputField(
                placeholder: "確認密碼",
                iconName: "lock",
                text: .constant(""),
                confirmText: .constant(""),
                mode: .register,
                isConfirmField: true
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
} 
