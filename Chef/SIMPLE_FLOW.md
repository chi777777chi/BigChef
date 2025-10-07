# App 完整畫面流程圖

> 可直接複製到 HackMD 查看

## 所有 Tab 總覽

```mermaid
flowchart TD
    App([打開 App]) --> MainTabs{選擇 Tab}

    MainTabs -->|首頁| HomeTab[首頁 Tab]
    MainTabs -->|食譜| ScanningTab[食譜 Tab]
    MainTabs -->|辨識| RecognitionTab[辨識 Tab]
    MainTabs -->|推薦| RecommendationTab[推薦 Tab]
    MainTabs -->|收藏| FavoritesTab[收藏 Tab]
    MainTabs -->|設定| SettingsTab[設定 Tab]

    HomeTab -.->|查看食譜| RecipeDetail[食譜詳情]
    ScanningTab -.->|掃描完成| RecipeDetail
    RecognitionTab -.->|生成完成| RecipeDetail
    RecommendationTab -.->|推薦完成| RecipeDetail
    FavoritesTab -.->|查看收藏| RecipeDetail

    RecipeDetail -.->|開始烹飪| ARCooking[AR 烹飪模式]

    style App fill:#e1f5e1
    style MainTabs fill:#fff4e1
    style RecipeDetail fill:#e1f0ff
    style ARCooking fill:#f0e1ff
```

---

## 1. 首頁 Tab 流程

```mermaid
flowchart TD
    Home[首頁畫面<br/>推薦菜餚<br/>熱門食譜<br/>最近瀏覽] -->|點擊菜餚| DishDetail[菜餚詳情畫面]
    Home -->|點擊食譜| RecipeDetail[食譜詳情畫面]
    Home -->|查看全部| AllRecipes[所有食譜列表]

    AllRecipes -->|選擇食譜| RecipeDetail
    DishDetail -->|查看相關食譜| RecipeDetail

    style Home fill:#e1f0ff
```

---

## 2. 食譜 Tab 流程

```mermaid
flowchart TD
    Scanning[食譜掃描畫面<br/>相機/相簿選擇] -->|選擇圖片| Selected[圖片已選擇<br/>開始掃描按鈕]

    Selected -->|開始掃描| Scanning2[掃描中<br/>載入動畫]

    Scanning2 -->|成功| Result[掃描結果<br/>識別的食材/器具<br/>生成食譜按鈕]
    Scanning2 -->|失敗| Error[錯誤畫面<br/>重試按鈕]

    Error -->|重試| Scanning2

    Result -->|生成食譜| RecipeDetail[食譜詳情]

    style Scanning fill:#fff
    style Scanning2 fill:#fff4e1
    style Error fill:#ffe1e1
    style RecipeDetail fill:#e1f0ff
```

---

## 3. 辨識 Tab 流程

```mermaid
flowchart TD
    Initial[初始畫面<br/>拍照/相簿按鈕] -->|選擇圖片| ImageSelected[圖片預覽畫面<br/>描述輸入框<br/>開始辨識按鈕]

    ImageSelected -->|開始辨識| Recognizing[辨識中畫面<br/>載入動畫<br/>進度百分比]

    Recognizing -->|成功| ResultView[辨識結果畫面<br/>辨識摘要<br/>食材清單<br/>器具清單]

    Recognizing -->|失敗| ErrorView[錯誤畫面<br/>錯誤訊息<br/>重試按鈕]

    ErrorView -->|重試| Recognizing
    ErrorView -->|重新選擇| Initial

    ResultView -->|調整食材| AdjustView[調整食材畫面<br/>編輯食材器具<br/>返回/確認按鈕]

    AdjustView -->|返回/確認| ResultView

    ResultView -->|生成食譜| LoadingView[生成中畫面<br/>載入動畫<br/>可切換Tab]

    LoadingView -->|成功| RecipeView[食譜詳情畫面<br/>完整步驟<br/>開始烹飪按鈕]

    LoadingView -->|失敗| GenErrorView[生成失敗畫面<br/>錯誤訊息<br/>重試/返回按鈕]

    GenErrorView -->|重試| LoadingView
    GenErrorView -->|返回| ResultView

    RecipeView -->|返回| ResultView
    RecipeView -->|開始烹飪| ARView[AR 烹飪模式]

    ResultView -->|重新辨識| Initial

    style Initial fill:#fff
    style ImageSelected fill:#fff
    style Recognizing fill:#fff4e1
    style ResultView fill:#e1f0ff
    style AdjustView fill:#fff
    style LoadingView fill:#fff4e1
    style RecipeView fill:#e1f0ff
    style ErrorView fill:#ffe1e1
    style GenErrorView fill:#ffe1e1
    style ARView fill:#f0e1ff
```

---

## 4. 推薦 Tab 流程

```mermaid
flowchart TD
    Config[食材器具配置畫面<br/>食材列表<br/>器具列表<br/>生成推薦按鈕] -->|新增食材| AddIngredient[新增食材<br/>手動輸入/掃描]

    Config -->|新增器具| AddEquipment[新增器具<br/>手動輸入/掃描]

    Config -->|編輯| EditItem[編輯食材/器具]

    AddIngredient --> Config
    AddEquipment --> Config
    EditItem --> Config

    Config -->|生成推薦| Loading[生成中畫面<br/>載入動畫<br/>可切換Tab]

    Loading -->|成功| Success[推薦結果畫面<br/>推薦食譜<br/>查看詳情按鈕]

    Loading -->|失敗| Error[錯誤畫面<br/>重試/返回按鈕]

    Error -->|重試| Loading
    Error -->|返回| Config

    Success -->|查看詳情| RecipeDetail[食譜詳情]
    Success -->|返回| Config

    RecipeDetail -->|開始烹飪| ARCooking[AR 烹飪模式]

    style Config fill:#e1f0ff
    style Loading fill:#fff4e1
    style Success fill:#e1f0ff
    style Error fill:#ffe1e1
    style RecipeDetail fill:#e1f0ff
    style ARCooking fill:#f0e1ff
```

---

## 5. 收藏 Tab 流程

```mermaid
flowchart TD
    Favorites[收藏列表畫面<br/>我的收藏食譜<br/>我的收藏菜餚] -->|未登入| Login[登入提示]

    Favorites -->|點擊食譜| RecipeDetail[食譜詳情]
    Favorites -->|點擊菜餚| DishDetail[菜餚詳情]

    DishDetail -->|查看相關食譜| RecipeDetail

    RecipeDetail -->|開始烹飪| ARCooking[AR 烹飪模式]

    Login -->|登入後| Favorites

    style Favorites fill:#e1f0ff
    style Login fill:#fff4e1
```

---

## 6. 設定 Tab 流程

```mermaid
flowchart TD
    Settings[設定畫面<br/>帳號資訊<br/>偏好設定<br/>登出按鈕] -->|登出| Logout[登出確認]

    Settings -->|修改設定| UpdateSettings[更新設定]

    UpdateSettings --> Settings
    Logout -->|確認| LoginScreen[登入畫面]

    style Settings fill:#e1f0ff
```

---

## Tab 之間的關係

```mermaid
flowchart LR
    Home[首頁 Tab] -.->|共用| RecipeDetail[食譜詳情]
    Scanning[食譜 Tab] -.->|共用| RecipeDetail
    Recognition[辨識 Tab] -.->|共用| RecipeDetail
    Recommendation[推薦 Tab] -.->|共用| RecipeDetail
    Favorites[收藏 Tab] -.->|共用| RecipeDetail

    RecipeDetail -.->|共用| ARCooking[AR 烹飪模式]

    style RecipeDetail fill:#e1f0ff
    style ARCooking fill:#f0e1ff
```

---

## 主要畫面說明

### 辨識 Tab

| 畫面 | 顯示內容 |
|------|---------|
| 初始畫面 | 拍照按鈕、相簿按鈕 |
| 圖片預覽 | 圖片、描述輸入框、開始辨識按鈕 |
| 辨識中 | 載入動畫、進度條 |
| 辨識結果 | 食材清單、器具清單、三個按鈕（生成食譜、調整食材、重新辨識） |
| 調整食材 | 食材/器具列表、編輯功能、確認按鈕 |
| 生成中 | 載入動畫、可切換Tab |
| 食譜詳情 | 完整步驟、開始烹飪按鈕、返回按鈕 |
| 錯誤畫面 | 錯誤訊息、重試按鈕 |

### 推薦 Tab

| 畫面 | 顯示內容 |
|------|---------|
| 配置畫面 | 食材列表、器具列表、新增/編輯按鈕、生成推薦按鈕 |
| 新增食材/器具 | 手動輸入、掃描選項 |
| 生成中 | 載入動畫、可切換Tab |
| 推薦結果 | 推薦的食譜、查看詳情按鈕 |
| 錯誤畫面 | 錯誤訊息、重試/返回按鈕 |

### 其他 Tab

| Tab | 主要內容 |
|-----|---------|
| 首頁 | 推薦菜餚、熱門食譜、最近瀏覽 |
| 食譜 | 掃描功能、食材識別 |
| 收藏 | 收藏的食譜和菜餚列表 |
| 設定 | 帳號資訊、偏好設定、登出 |

### 共用畫面

| 畫面 | 出現位置 |
|------|---------|
| 食譜詳情 | 所有 Tab 都可以進入 |
| AR 烹飪模式 | 從食譜詳情進入 |
