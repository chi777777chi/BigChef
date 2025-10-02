import Foundation

enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidEmail
    case invalidPassword
    case passwordTooShort
    case passwordMismatch
    case invalidUsername
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field)不能為空"
        case .invalidEmail:
            return "請輸入有效的電子郵件地址"
        case .invalidPassword:
            return "密碼必須包含大小寫字母和數字"
        case .passwordTooShort:
            return "密碼長度必須至少為8個字符"
        case .passwordMismatch:
            return "兩次輸入的密碼不一致"
        case .invalidUsername:
            return "用戶名只能包含字母、數字和下劃線"
        }
    }
}

struct ValidationUtils {
    static func validateEmail(_ email: String) throws {
        if email.isEmpty {
            throw ValidationError.emptyField("電子郵件")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            throw ValidationError.invalidEmail
        }
    }
    
    static func validatePassword(_ password: String) throws {
        if password.isEmpty {
            throw ValidationError.emptyField("密碼")
        }
        
        if password.count < 8 {
            throw ValidationError.passwordTooShort
        }
        
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
        if !passwordPredicate.evaluate(with: password) {
            throw ValidationError.invalidPassword
        }
    }
    
    static func validateUsername(_ username: String) throws {
        if username.isEmpty {
            throw ValidationError.emptyField("用戶名")
        }
        
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        if !usernamePredicate.evaluate(with: username) {
            throw ValidationError.invalidUsername
        }
    }
    
    static func validateFullname(_ fullname: String) throws {
        if fullname.isEmpty {
            throw ValidationError.emptyField("姓名")
        }
    }
    
    static func validatePasswordConfirmation(_ password: String, _ confirmation: String) throws {
        if password != confirmation {
            throw ValidationError.passwordMismatch
        }
    }
} 