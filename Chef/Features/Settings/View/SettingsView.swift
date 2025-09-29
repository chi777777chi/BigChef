import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("cookingLevel") private var cookingLevel: String = "初學者"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @EnvironmentObject private var authViewModel: AuthViewModel

    private let cookingLevels = ["初學者", "中級", "進階", "專業"]
    
    var body: some View {
        NavigationStack {
            Form {
                // 用戶資訊 Section
                if authViewModel.isAuthenticated {
                    Section(header: Text("用戶資訊")) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.brandOrange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authViewModel.displayName)
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Text(authViewModel.userEmail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // 登入狀態指示器
                            VStack(alignment: .trailing, spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)

                                Text("已登入")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)

                        // 登出按鈕
                        if authViewModel.isLoggedInWithAPI {
                            Button(action: {
                                authViewModel.logoutFromAPI()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("登出")
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                } else {
                    Section(header: Text("用戶狀態")) {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("未登入")
                                    .font(.headline)
                                    .foregroundColor(.gray)

                                Text("登入後可享受更多功能")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("個人設定")) {
                    TextField("使用者名稱", text: $userName)

                    Picker("烹飪等級", selection: $cookingLevel) {
                        ForEach(cookingLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                }
                
                Section(header: Text("通知設定")) {
                    Toggle("啟用通知", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("關於")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
} 