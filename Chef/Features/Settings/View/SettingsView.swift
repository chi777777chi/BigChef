import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("cookingLevel") private var cookingLevel: String = "初學者"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    private let cookingLevels = ["初學者", "中級", "進階", "專業"]
    
    var body: some View {
        NavigationStack {
            Form {
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