# 食物辨識功能畫面跳轉流程圖

> 本文件包含 Mermaid 流程圖，可直接在 HackMD、GitHub 或支援 Mermaid 的 Markdown 編輯器中查看

## 1. FoodRecognitionView 完整狀態流程

```mermaid
stateDiagram-v2
    [*] --> Initial: 開啟 App

    Initial: 初始狀態<br/>顯示相機/相簿按鈕
    ImageSelected: 已選擇圖片<br/>顯示圖片預覽<br/>描述輸入框
    Recognizing: 辨識中<br/>顯示進度動畫
    Result: 辨識結果<br/>RecipeGenerationFlowView
    Error: 辨識失敗<br/>顯示錯誤訊息

    Initial --> ImageSelected: 選擇圖片
    ImageSelected --> Recognizing: 開始辨識
    Recognizing --> Result: 辨識成功
    Recognizing --> Error: 辨識失敗
    Error --> Recognizing: 重試
    Error --> Initial: 重新選擇圖片
    ImageSelected --> Initial: 重新開始
    Result --> Initial: 重新開始
```

## 2. RecipeGenerationFlowView 狀態流程

```mermaid
stateDiagram-v2
    [*] --> ShowResult: 從辨識結果進入

    ShowResult: 顯示辨識結果<br/>FoodRecognitionResultView
    Adjusting: 調整食材器具<br/>IngredientAdjustmentView
    Loading: 生成食譜中<br/>RecommendationLoadingView
    Success: 生成成功<br/>RecipeDetailView
    GenerationError: 生成失敗<br/>顯示錯誤
    ARCooking: AR 烹飪模式

    ShowResult --> Adjusting: 調整食材
    ShowResult --> Loading: 生成食譜
    ShowResult --> [*]: 重新辨識

    Adjusting --> ShowResult: 返回
    Adjusting --> ShowResult: 確認食材

    Loading --> Success: 生成成功
    Loading --> GenerationError: 生成失敗
    Loading --> ShowResult: 取消生成

    Success --> ShowResult: 返回
    Success --> ARCooking: 開始烹飪

    GenerationError --> Loading: 重試
    GenerationError --> ShowResult: 返回

    note right of Loading
        可切換到其他 Tab
        狀態會保留
    end note
```

## 3. 完整用戶操作流程

```mermaid
flowchart TD
    Start([用戶打開 App]) --> SelectTab[選擇辨識 Tab]
    SelectTab --> ChooseSource{選擇圖片來源}

    ChooseSource -->|拍照| Camera[開啟相機]
    ChooseSource -->|相簿| Gallery[開啟相簿]

    Camera --> ImageSelected[圖片已選擇]
    Gallery --> ImageSelected

    ImageSelected --> OptionalDesc{輸入描述?}
    OptionalDesc -->|是| InputDesc[輸入描述提示]
    OptionalDesc -->|否| StartRecognition
    InputDesc --> StartRecognition[點擊開始辨識]

    StartRecognition --> Recognizing[辨識中...]

    Recognizing --> RecognitionSuccess{辨識成功?}
    RecognitionSuccess -->|是| ShowResult[顯示辨識結果]
    RecognitionSuccess -->|否| ShowError[顯示錯誤]

    ShowError --> RetryOrReselect{用戶選擇}
    RetryOrReselect -->|重試| Recognizing
    RetryOrReselect -->|重新選擇| ChooseSource

    ShowResult --> UserAction{用戶操作}

    UserAction -->|調整食材| AdjustIngredients[進入調整食材頁面]
    UserAction -->|生成食譜| GenerateRecipe[開始生成食譜]
    UserAction -->|重新辨識| ChooseSource

    AdjustIngredients --> EditActions{編輯操作}
    EditActions -->|新增| AddItem[新增食材/器具]
    EditActions -->|編輯| EditItem[編輯食材/器具]
    EditActions -->|刪除| DeleteItem[刪除食材/器具]
    EditActions -->|勾選/取消| ToggleItem[切換選擇狀態]

    AddItem --> AdjustIngredients
    EditItem --> AdjustIngredients
    DeleteItem --> AdjustIngredients
    ToggleItem --> AdjustIngredients

    AdjustIngredients --> ConfirmOrBack{用戶選擇}
    ConfirmOrBack -->|確認食材| ShowResult
    ConfirmOrBack -->|返回| ShowResult

    GenerateRecipe --> Generating[生成中...]

    Generating --> CanSwitchTab{可切換 Tab}
    CanSwitchTab -.->|切換| OtherTab[其他 Tab]
    OtherTab -.->|返回| CheckGeneration
    CanSwitchTab --> CheckGeneration{生成完成?}

    CheckGeneration -->|生成中| Generating
    CheckGeneration -->|成功| RecipeDetail[顯示食譜詳情]
    CheckGeneration -->|失敗| GenerationError[顯示生成錯誤]

    GenerationError --> ErrorAction{用戶選擇}
    ErrorAction -->|重試| GenerateRecipe
    ErrorAction -->|返回| ShowResult

    RecipeDetail --> RecipeAction{用戶操作}
    RecipeAction -->|開始烹飪| ARMode[進入 AR 烹飪模式]
    RecipeAction -->|收藏| Favorite[收藏食譜]
    RecipeAction -->|返回| ShowResult

    ARMode --> End([結束])
    Favorite --> RecipeDetail

    style Start fill:#e1f5e1
    style End fill:#ffe1e1
    style Recognizing fill:#fff4e1
    style Generating fill:#fff4e1
    style ShowError fill:#ffe1e1
    style GenerationError fill:#ffe1e1
    style RecipeDetail fill:#e1f0ff
    style ARMode fill:#f0e1ff
```

## 4. API 呼叫流程

### 食物辨識 API

```mermaid
sequenceDiagram
    participant User as 用戶
    participant View as FoodRecognitionView
    participant VM as FoodRecognitionViewModel
    participant Service as FoodRecognitionService
    participant API as Backend API

    User->>View: 選擇圖片
    User->>View: 點擊「開始辨識」
    View->>VM: recognizeFood()
    VM->>VM: 更新狀態為 .recognizing
    VM->>Service: recognizeFood(image, description)
    Service->>API: POST /api/v1/vision/recognize

    alt 辨識成功
        API-->>Service: FoodRecognitionResponse
        Service-->>VM: 返回結果
        VM->>VM: 更新狀態為 .result(response)
        VM-->>View: 更新 UI
        View-->>User: 顯示辨識結果
    else 辨識失敗
        API-->>Service: Error
        Service-->>VM: 拋出錯誤
        VM->>VM: 更新狀態為 .error
        VM-->>View: 更新 UI
        View-->>User: 顯示錯誤訊息
    end
```

### 食譜生成 API

```mermaid
sequenceDiagram
    participant User as 用戶
    participant View as RecipeGenerationFlowView
    participant VM as RecipeGenerationViewModel
    participant Service as RecipeService
    participant API as Backend API

    User->>View: 點擊「生成食譜」
    View->>VM: generateRecipe()
    VM->>VM: 更新狀態為 .loading

    Note over VM: 準備請求參數<br/>dish_name<br/>preferred_ingredients<br/>preferred_equipment<br/>preference

    VM->>Service: generateRecipeByName(request)
    Service->>API: POST /api/v1/recipe/generate

    Note over User,View: 用戶可切換 Tab<br/>狀態會保留

    alt 生成成功
        API-->>Service: GenerateRecipeByNameResponse
        Service-->>VM: 返回結果
        VM->>VM: 轉換為 RecipeRecommendationResponse
        VM->>VM: 更新狀態為 .success(result)
        VM-->>View: 更新 UI
        View-->>User: 顯示食譜詳情
    else 生成失敗
        API-->>Service: Error
        Service-->>VM: 拋出錯誤
        VM->>VM: 更新狀態為 .error
        VM-->>View: 更新 UI
        View-->>User: 顯示錯誤訊息
    end
```

## 5. 食材調整功能流程

```mermaid
flowchart TD
    Entry[進入調整食材頁面] --> Display[顯示當前食材器具]

    Display --> Actions{用戶操作}

    Actions -->|新增食材| ShowAddIngredient[顯示新增食材 Sheet]
    Actions -->|編輯食材| ShowEditIngredient[顯示編輯食材 Sheet]
    Actions -->|刪除食材| DeleteIngredient[刪除食材]
    Actions -->|勾選/取消食材| ToggleIngredient[切換選擇狀態]

    Actions -->|新增器具| ShowAddEquipment[顯示新增器具 Sheet]
    Actions -->|編輯器具| ShowEditEquipment[顯示編輯器具 Sheet]
    Actions -->|刪除器具| DeleteEquipment[刪除器具]
    Actions -->|勾選/取消器具| ToggleEquipment[切換選擇狀態]

    Actions -->|確認食材| Confirm[確認並返回]
    Actions -->|返回| Back[返回辨識結果]

    ShowAddIngredient --> InputNewIngredient[輸入新食材名稱]
    InputNewIngredient --> AddToList[加入食材列表]
    AddToList --> Display

    ShowEditIngredient --> InputEditIngredient[修改食材名稱]
    InputEditIngredient --> UpdateList[更新食材列表]
    UpdateList --> Display

    DeleteIngredient --> Display
    ToggleIngredient --> Display

    ShowAddEquipment --> InputNewEquipment[輸入新器具名稱]
    InputNewEquipment --> AddEquipmentToList[加入器具列表]
    AddEquipmentToList --> Display

    ShowEditEquipment --> InputEditEquipment[修改器具名稱]
    InputEditEquipment --> UpdateEquipmentList[更新器具列表]
    UpdateEquipmentList --> Display

    DeleteEquipment --> Display
    ToggleEquipment --> Display

    Confirm --> UpdateResponse[更新 FoodRecognitionResponse]
    UpdateResponse --> ReturnResult[返回辨識結果頁面]

    Back --> ReturnResult

    style Entry fill:#e1f5e1
    style ReturnResult fill:#e1f0ff
    style ShowAddIngredient fill:#fff4e1
    style ShowEditIngredient fill:#fff4e1
    style ShowAddEquipment fill:#fff4e1
    style ShowEditEquipment fill:#fff4e1
```

## 6. 狀態管理架構

```mermaid
classDiagram
    class FoodRecognitionViewModel {
        +FoodRecognitionViewState currentViewState
        +UIImage? selectedImage
        +String descriptionHint
        +recognizeFood()
        +handleImageSelection()
        +clearSelection()
        +retryRecognition()
    }

    class FoodRecognitionViewState {
        <<enumeration>>
        initial
        imageSelected
        recognizing
        result(FoodRecognitionResponse)
        error(FoodRecognitionError)
    }

    class RecipeGenerationViewModel {
        +RecipeGenerationViewState state
        +String[] selectedIngredients
        +String[] selectedEquipment
        +FoodRecognitionResponse originalResponse
        +FoodRecognitionResponse currentResponse
        +generateRecipe()
        +showAdjustment()
        +updateIngredients()
        +backToInitial()
    }

    class RecipeGenerationViewState {
        <<enumeration>>
        initial(FoodRecognitionResponse)
        adjusting(FoodRecognitionResponse)
        loading
        success(RecipeRecommendationResponse)
        error(Error)
    }

    class IngredientAdjustmentViewModel {
        +PossibleIngredient[] ingredients
        +PossibleEquipment[] equipment
        +Set~String~ selectedIngredientNames
        +Set~String~ selectedEquipmentNames
        +toggleIngredient()
        +editIngredient()
        +addIngredient()
        +removeIngredient()
    }

    FoodRecognitionViewModel --> FoodRecognitionViewState
    RecipeGenerationViewModel --> RecipeGenerationViewState
    RecipeGenerationViewModel --> IngredientAdjustmentViewModel: uses
```

## 7. 導航層級結構

```mermaid
graph TD
    MainTabView[MainTabView]

    MainTabView --> RecognitionTab[辨識 Tab]
    MainTabView --> RecommendationTab[推薦 Tab]
    MainTabView --> OtherTabs[其他 Tabs]

    RecognitionTab --> NavView[NavigationView]

    NavView --> FoodRecognitionView

    FoodRecognitionView --> InitialView[初始狀態視圖]
    FoodRecognitionView --> ImageSelectedView[圖片已選視圖]
    FoodRecognitionView --> RecognizingView[辨識中視圖]
    FoodRecognitionView --> RecipeGenFlow[RecipeGenerationFlowView]
    FoodRecognitionView --> ErrorView[錯誤視圖]

    RecipeGenFlow --> ResultView[FoodRecognitionResultView]
    RecipeGenFlow --> AdjustView[IngredientAdjustmentView]
    RecipeGenFlow --> LoadingView[RecommendationLoadingView]
    RecipeGenFlow --> SuccessView[RecipeDetailView]
    RecipeGenFlow --> GenErrorView[生成錯誤視圖]

    AdjustView -.->|Sheet| AddIngredientSheet
    AdjustView -.->|Sheet| EditIngredientSheet
    AdjustView -.->|Sheet| AddEquipmentSheet
    AdjustView -.->|Sheet| EditEquipmentSheet

    FoodRecognitionView -.->|Sheet| ImagePicker[ImagePicker]

    SuccessView --> ARCooking[AR 烹飪模式]

    style NavView fill:#e1f5e1
    style RecipeGenFlow fill:#fff4e1
    style AddIngredientSheet fill:#ffe1e1
    style EditIngredientSheet fill:#ffe1e1
    style AddEquipmentSheet fill:#ffe1e1
    style EditEquipmentSheet fill:#ffe1e1
    style ImagePicker fill:#ffe1e1
    style ARCooking fill:#f0e1ff
```

## 關鍵文件對應

| 畫面/功能 | 檔案路徑 |
|---------|---------|
| 主要辨識視圖 | Features/FoodRecognition/Views/FoodRecognitionView.swift |
| 辨識結果視圖 | Features/FoodRecognition/Views/FoodRecognitionResultView.swift |
| 食譜生成流程 | Features/FoodRecognition/Views/RecipeGenerationFlowView.swift |
| 食材調整視圖 | Features/FoodRecognition/Views/IngredientAdjustmentView.swift |
| 辨識錯誤視圖 | Features/FoodRecognition/Views/FoodRecognitionErrorView.swift |
| 辨識 ViewModel | Features/FoodRecognition/ViewModels/FoodRecognitionViewModel.swift |
| 生成 ViewModel | Features/FoodRecognition/ViewModels/RecipeGenerationViewModel.swift |
| 導航協調器 | Features/FoodRecognition/Coordinators/FoodRecognitionCoordinator.swift |
| 辨識服務 | Features/FoodRecognition/Services/FoodRecognitionService.swift |
| 食譜服務 | Features/Recommendation/Services/RecipeService.swift |

## 注意事項

1. **NavigationView 不可嵌套**：FoodRecognitionView 已有導航功能，子視圖不應再包 NavigationView
2. **狀態保留**：在食譜生成時切換 Tab 不會中斷生成過程
3. **食材更新**：調整食材後會創建新的 FoodRecognitionResponse，保留原始結果
4. **工具列按鈕**：「重新開始」按鈕只在有圖片或結果時顯示
5. **返回按鈕**：調整食材頁面使用自定義返回按鈕，隱藏系統預設按鈕

## 如何在 HackMD 中使用

1. 複製上面任何一個 Mermaid 代碼塊（包含 \`\`\`mermaid 和 \`\`\`）
2. 貼到 HackMD 編輯器中
3. 流程圖會自動渲染顯示

### Mermaid 語法快速參考

- **狀態圖**：`stateDiagram-v2`
- **流程圖**：`flowchart TD` (上到下) 或 `flowchart LR` (左到右)
- **時序圖**：`sequenceDiagram`
- **類別圖**：`classDiagram`
- **箭頭**：`-->` 或 `-.->` (虛線)
- **帶文字箭頭**：`-->|文字|`
- **判斷節點**：`{判斷內容}`
- **圓角節點**：`([內容])`
- **註解**：`note right of NodeName: 註解內容`
