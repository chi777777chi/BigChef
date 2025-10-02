//
//  User.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/16.
//

import FirebaseFirestore
import FirebaseAuth

struct User: Identifiable, Codable { // 改為 Codable 以便於與 Firestore 互動
    @DocumentID var id: String? // Firestore 會自動填入文件 ID
    let username: String
    let fullname: String
    var profileImageUrl: String?
    let email: String

    // 如果您希望在創建 User 物件時 id 就有值 (例如等於 uid)，
    // 可以在初始化時手動賦值，或者在從 Firestore 讀取後它會被自動填充。
}

extension User {
    var avatarUrl: String {
        profileImageUrl ?? "https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?d=mp" //  在沒有圖片時顯示預設圖示
    }

    var isCurrentUser: Bool {
        Auth.auth().currentUser?.uid == id
    }
}
