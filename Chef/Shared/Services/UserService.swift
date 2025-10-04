//
//  UserService.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/6.
//

import FirebaseFirestore // 確保導入

struct UserService {
    
    func fetchUser(withUid uid: String, completion: @escaping(User?) -> Void) { // 回調改為 User?
        Firestore.firestore().collection("users")
            .document(uid)
            .getDocument { snapshot, error in // 檢查 error
                if let error = error {
                    print("UserService DEBUG: 獲取用戶文件失敗，UID: \(uid), 錯誤: \(error.localizedDescription)")
                    completion(nil) // 錯誤情況下回調 nil
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    print("UserService DEBUG: 用戶文件不存在，UID: \(uid)")
                    completion(nil) // 文件不存在或 snapshot 為 nil 時回調 nil
                    return
                }
                
                do {
                    let user = try snapshot.data(as: User.self)
                    completion(user) // 成功解析後回調 user
                } catch let decodingError {
                    print ("UserService DEBUG: 解析用戶資料失敗，UID: \(uid), 錯誤: \(decodingError.localizedDescription)")
                    completion(nil) // 解析錯誤時回調 nil
                }
            }
    }
    
    // fetchUsers 方法保持不變，除非您也想讓它處理可能的錯誤
    func fetchUsers(completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("users")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([]) // 如果沒有文件，回傳空陣列
                    return
                }
                // compactMap 會自動忽略那些解碼失敗的元素
                let users = documents.compactMap({ try? $0.data(as: User.self)})
                completion(users)
            }
    }
}
