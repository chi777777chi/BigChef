# ChefHelper iOS App

## 設置說明

### 1. 環境配置

#### 配置文件設置
1. 複製 `Config.plist.template` 為 `Config.plist`
2. 編輯 `Config.plist` 中的設置：
   - `API_BASE_URL`: 你的後端 API 服務器地址
   - `API_VERSION`: API 版本 (預設: v1)
   - `DEBUG_MODE`: 除錯模式開關
   - `TIMEOUT_INTERVAL`: 網路請求超時時間

#### Firebase 配置
1. 從 Firebase Console 下載你的 `GoogleService-Info.plist`
2. 將文件添加到項目根目錄
3. 在 Xcode 中將文件添加到目標中

### 2. 安全注意事項

以下文件包含敏感信息，**不應**提交到版本控制：
- `GoogleService-Info.plist` - Firebase 配置
- `Config.plist` - API 配置
- `*.p12` - 證書文件
- `*.mobileprovision` - 佈建描述檔

### 3. 項目結構

```
Chef/
├── Features/           # 功能模組
│   ├── Home/          # 首頁
│   ├── Favorites/     # 收藏
│   ├── Recipe/        # 食譜
│   └── ...
├── Shared/            # 共用組件
│   ├── Services/      # 網路服務
│   ├── Models/        # 資料模型
│   ├── Utils/         # 工具類
│   └── Views/         # 共用視圖
├── Coordinators/      # 導航協調器
└── Config.plist       # 配置文件 (不提交)
```

### 4. 開發環境設置

1. 克隆項目
2. 設置配置文件（見上述步驟）
3. 在 Xcode 中打開 `ChefHelper.xcodeproj`
4. 選擇合適的模擬器或設備
5. 運行項目

### 5. API 配置

預設 API 端點：
- 食譜列表: `{API_BASE_URL}/api/v1/recipes`
- 用戶收藏: `{API_BASE_URL}/api/v1/favorites`
- 用戶登入: `{API_BASE_URL}/api/v1/auth/login`

### 6. 功能特色

- 🏠 首頁瀏覽食譜
- ❤️ 收藏管理
- 🔍 食譜搜索
- 👤 用戶認證
- 📱 響應式設計

### 7. 故障排除

#### 常見問題
1. **配置文件缺失**: 確保已複製並編輯 `Config.plist`
2. **Firebase 錯誤**: 檢查 `GoogleService-Info.plist` 是否正確添加
3. **網路連接**: 驗證 API 服務器地址和網路連接

#### 除錯模式
在 `Config.plist` 中將 `DEBUG_MODE` 設為 `true` 可以看到詳細的除錯日誌。