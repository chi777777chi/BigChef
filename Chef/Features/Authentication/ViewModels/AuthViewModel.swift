//
//  AuthViewModel.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/6.
//

// AuthViewModel.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore // 確保導入 FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userSession: FirebaseAuth.User?
    @Published var didAuthenticateUser = false // 可以用來觸發 UI 更新或流程轉換
    @Published var currentUser: User? // 您的 User model
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    // private var tempUserSession: FirebaseAuth.User? // 在註冊流程中暫存用戶 session
    
    // MARK: - Private Properties
    private let service = UserService()
    private var isShowingError = false // 防止重複顯示錯誤

    // MARK: - Coordinator Callbacks
    // 由 AuthCoordinator 設定這些回調
    var onLoginSuccess: (() -> Void)?
    var onRegistrationSuccess: (() -> Void)? // 註冊成功 (通常也意味著登入成功)
    var onAuthFailure: ((Error) -> Void)?
    var onNavigateToRegistration: (() -> Void)? // 從登入頁導航到註冊頁
    var onNavigateBackToLogin: (() -> Void)?    // 從註冊頁導航回登入頁
    var onUserWantsToCancelAuth: (() -> Void)?  // 用戶明確取消驗證流程

    init() {
        self.userSession = Auth.auth().currentUser
        if let userSession = self.userSession {
            Task {
                service.fetchUser(withUid: userSession.uid) { [weak self] user in
                    Task { @MainActor in
                        self?.currentUser = user
                    }
                }
            }
        }
        print("AuthViewModel: 初始化完成。User session: \(String(describing: userSession?.uid))")
    }
    
    // MARK: - Login
    func login(withEmail email: String, password: String) async {
        guard !isLoading else { return }
        
        do {
            try ValidationUtils.validateEmail(email)
            try ValidationUtils.validatePassword(password)
            
            isLoading = true
            defer { isLoading = false }
            
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user
            self.userSession = firebaseUser
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                service.fetchUser(withUid: firebaseUser.uid) { [weak self] fetchedUser in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if let fetchedUser = fetchedUser {
                            self.currentUser = fetchedUser
                            self.didAuthenticateUser = true
                            self.onLoginSuccess?()
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: ValidationError.emptyField("用戶資料"))
                        }
                    }
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Register
    func register(withEmail email: String, password: String, fullname: String, username: String, profileImage: UIImage? = nil) async {
        guard !isLoading else { return }
        
        do {
            try ValidationUtils.validateEmail(email)
            try ValidationUtils.validatePassword(password)
            try ValidationUtils.validateUsername(username)
            try ValidationUtils.validateFullname(fullname)
            
            isLoading = true
            defer { isLoading = false }
            
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let firebaseUser = authResult.user
            let userData: [String: Any] = [
                "email": email,
                "username": username.lowercased(),
                "fullname": fullname,
                "uid": firebaseUser.uid
            ]
            
            try await Firestore.firestore().collection("users")
                .document(firebaseUser.uid)
                .setData(userData)
            
            self.userSession = firebaseUser
            
            if let imageToUpload = profileImage {
                do {
                    let profileImageUrl = try await uploadProfileImage(imageToUpload)
                    try await Firestore.firestore().collection("users")
                        .document(firebaseUser.uid)
                        .updateData(["profileImageUrl": profileImageUrl])
                } catch {
                    print("警告：個人圖片上傳失敗，但註冊流程繼續")
                }
            }
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                service.fetchUser(withUid: firebaseUser.uid) { [weak self] fetchedUser in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if let fetchedUser = fetchedUser {
                            self.currentUser = fetchedUser
                            self.didAuthenticateUser = true
                            self.onRegistrationSuccess?()
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: ValidationError.emptyField("用戶資料"))
                        }
                    }
                }
            }
        } catch {
            await handleError(error)
        }
    }

    private func handleError(_ error: Error) async {
        guard !isShowingError else { return }
        isShowingError = true
        
        await MainActor.run {
            self.error = error
            self.showError = true
            self.onAuthFailure?(error)
        }
        
        // 延遲重置錯誤狀態，防止快速重複顯示
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        await MainActor.run {
            self.isShowingError = false
        }
    }
    
    // MARK: - Logout
    func logout() {
        print("AuthViewModel: 嘗試登出")
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            self.didAuthenticateUser = false
            print("AuthViewModel DEBUG: 用戶已登出")
            // 登出通常由 AppCoordinator 或 ProfileCoordinator 觸發，
            // 這裡 ViewModel 執行登出操作，然後 AppCoordinator 會轉換到 AuthCoordinator 流程。
            // 所以 ViewModel 本身不需要 onLogoutSuccess 回調給 AuthCoordinator。
        } catch let error {
            print("AuthViewModel DEBUG: 登出失敗，錯誤: \(error.localizedDescription)")
            // 登出失敗通常是個問題，但一般不會阻止 UI 轉換到登入頁
        }
    }
    
    // MARK: - Profile Image Upload
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        print("AuthViewModel: 上傳個人圖片中...")
        return try await withCheckedThrowingContinuation { continuation in
            ImageUploader.uploadImage(image: image) { imageUrl in
                if !imageUrl.isEmpty {
                    continuation.resume(returning: imageUrl)
                } else {
                    continuation.resume(throwing: ValidationError.emptyField("圖片上傳失敗"))
                }
            }
        }
    }
    
    // MARK: - Navigation Triggers (called by View, handled by Coordinator)
    func requestNavigateToRegistration() {
        print("AuthViewModel: 請求導航到註冊頁面")
        onNavigateToRegistration?()
    }

    func requestNavigateBackToLogin() {
        print("AuthViewModel: 請求導航回登入頁面")
        onNavigateBackToLogin?()
    }

    func requestCancelAuthentication() {
        print("AuthViewModel: 請求取消驗證流程")
        onUserWantsToCancelAuth?()
    }

    // MARK: - Public Methods
    func fetchCurrentUser() async throws -> User? {
        guard let userSession = userSession else { return nil }
        
        return try await withCheckedThrowingContinuation { continuation in
            service.fetchUser(withUid: userSession.uid) { [weak self] user in
                Task { @MainActor in
                    if let user = user {
                        self?.currentUser = user
                        continuation.resume(returning: user)
                    } else {
                        continuation.resume(throwing: ValidationError.emptyField("用戶資料"))
                    }
                }
            }
        }
    }
}
