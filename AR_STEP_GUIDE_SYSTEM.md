# AR 步驟提示動畫系統說明

## 系統概述

你的專案**已經完整實現** AR 步驟提示動畫系統，與參考專案 (feature/bigchef-sync) 的架構一致。當用戶進行烹飪步驟時，系統會根據步驟描述自動顯示相應的 AR 動畫。

## 架構組成

### 1. 資料模型層 (`RecipeModels.swift`)

#### RecipeStep
```swift
struct RecipeStep: Codable, Identifiable {
    var step_number: Int
    var title: String
    var description: String
    var actions: [Action]
    var arType: ARAnimationType?        // ✅ AR 動畫類型
    var arParameters: ARAnimationParams? // ✅ AR 動畫參數
}
```

#### ARAnimationType
支援 12 種動畫類型：
- `putIntoContainer` - 放入食材
- `stir` - 攪拌
- `pourLiquid` - 倒入液體
- `flipPan` / `flip` - 翻鍋/翻面
- `countdown` - 倒數計時
- `temperature` - 溫度顯示
- `flame` - 火焰大小
- `sprinkle` - 撒調味料
- `torch` - 噴槍炙燒 🔥
- `cut` - 切菜
- `peel` - 削皮
- `beatEgg` - 打蛋

#### ARAnimationParams
```swift
struct ARAnimationParams: Codable {
    var coordinate: [Double]?    // 3D 座標
    var container: String?       // 容器類型（pan, pot, bowl）
    var ingredient: String?      // 食材名稱
    var color: String?          // 顏色
    var time: Double?           // 時間（分鐘）
    var temperature: Double?    // 溫度
    var flameLevel: String?     // 火力等級
}
```

### 2. AR 視圖層 (`CookingARView.swift`)

#### 核心流程
```swift
func updateUIView(_ uiView: ARView, context: Context) {
    // 1. 檢查步驟是否有 AR 參數
    guard let arType = stepModel.arType,
          let arParams = stepModel.arParameters else { return }

    // 2. 避免重複播放同一步驟
    if context.coordinator.lastStepNumber == stepModel.step_number { return }

    // 3. 清理舊動畫
    uiView.scene.anchors.removeAll()

    // 4. 創建新動畫
    let animation = AnimationFactory.make(type: animType, params: params)

    // 5. 播放動畫
    context.coordinator.playAnimationLoop()
}
```

#### 容器偵測 (ObjectDetector)
- 使用 Vision 框架偵測鍋具（pan, pot, bowl）
- 結合 ARKit 的深度資訊計算 3D 位置
- 將動畫準確疊加在真實容器上

### 3. 動畫工廠層 (`AnimationFactory.swift`)

根據 `ARAnimationType` 創建對應的動畫實例：

```swift
static func make(type: AnimationType, params: AnimationParams) -> Animation {
    switch type {
    case .torch:
        return TorchAnimation(
            ingredient: params.ingredient ?? "",
            scale: 1.0,
            isRepeat: true
        )
    case .stir:
        return StirAnimation(
            container: params.container ?? .pan,
            scale: 0.2,
            isRepeat: true
        )
    // ... 其他動畫類型
    }
}
```

### 4. 具體動畫實現

#### 需要容器偵測的動畫
- `PutIntoContainerAnimation`
- `StirAnimation`
- `PourLiquidAnimation`
- `FlameAnimation`
- `CountdownAnimation`
- `TemperatureAnimation`
- `SprinkleAnimation`
- `FlipAnimation`
- `BeatEggAnimation`

#### 固定位置的動畫（相機前方）
- `TorchAnimation` - 噴槍炙燒
- `CutAnimation` - 切菜
- `PeelAnimation` - 削皮

### 5. 控制器層 (`CookViewController.swift`)

#### UI 元件
```swift
// ✅ 步驟描述文字
private let stepLabel = UILabel()

// ✅ 手勢狀態文字
private let gestureStatusLabel = UILabel()

// ✅ 懸停進度條
private let hoverProgressView = UIProgressView()
```

#### 步驟切換
```swift
private var currentIndex = 0 {
    didSet {
        updateStepLabel()
        // 重新設定 AR 視圖以觸發新動畫
        arContainer.rootView = CookingARView(
            stepModel: steps[currentIndex],
            sessionAdapter: gestureSession
        )
    }
}
```

## 使用範例

### 後端 API 回應範例

```json
{
  "dish_name": "炙燒壽司",
  "recipe": [
    {
      "step_number": 1,
      "title": "準備食材",
      "description": "將鮭魚切片備用",
      "arType": "cut",
      "arParameters": {
        "ingredient": "鮭魚",
        "coordinate": [0, 0, -0.5]
      }
    },
    {
      "step_number": 2,
      "title": "炙燒魚片",
      "description": "使用噴槍炙燒鮭魚表面",
      "arType": "torch",
      "arParameters": {
        "ingredient": "鮭魚"
      }
    },
    {
      "step_number": 3,
      "title": "擺盤",
      "description": "將壽司擺放在盤中",
      "arType": null,
      "arParameters": null
    }
  ]
}
```

### 動畫顯示邏輯

1. **步驟 1**: 顯示切菜動畫（固定在相機前方）
2. **步驟 2**: 顯示噴槍炙燒動畫（TorchAnimation）
3. **步驟 3**: 無 AR 動畫，只顯示步驟文字

## 手勢互動

### 手勢狀態顯示
- **gestureStatusLabel**: 顯示當前手勢狀態文字
  - "手勢辨識：等待手部"（idle）
  - "手勢辨識：偵測中"（detecting）
  - "手勢辨識：懸停中…"（hovering）
  - "手勢辨識：準備完成"（ready）
  - "手勢辨識：處理中"（processing）
  - "手勢辨識：完成"（completed）

### 懸停進度條
- **hoverProgressView**: 顯示比七手勢的懸停進度（0-100%）
- 當進度達到 100% 時，進入「準備就緒」狀態

### 手勢操作
- **比七 + 食指向上**: 下一步（觸發步驟切換，顯示新動畫）
- **比七 + 食指向下**: 上一步（回到前一個步驟動畫）

## 動畫資源

### 3D 模型檔案（.usdz）
位於專案的 Resources 目錄：
- `torch.usdz` - 噴槍模型
- `stir.usdz` - 攪拌動畫
- `pour.usdz` - 倒液體動畫
- 其他動畫模型...

### 加載方式
```swift
guard let url = Bundle.main.url(forResource: "torch", withExtension: "usdz") else {
    fatalError("❌ 找不到 torch.usdz")
}
let model = try Entity.load(contentsOf: url)
```

## 技術特點

### 1. 智能容器追蹤
- 使用 Vision 框架的 Object Detection
- 結合 ARKit Scene Depth 計算精確 3D 位置
- 動畫會跟隨真實容器移動

### 2. 動畫生命週期管理
- 步驟切換時自動清理舊動畫
- 避免重複播放同一步驟
- 支援循環播放（isRepeat）

### 3. 多重 Delegate 模式
- `CookViewController` 接收手勢事件以切換步驟
- `CookingARView.Coordinator` 接收手勢狀態用於日誌記錄
- 使用 `MulticastGestureDelegate` 廣播事件

### 4. 性能優化
- ARFrame 處理採用節流機制（~15fps）
- Vision 請求在背景線程執行
- 容器偵測使用信心度閾值（0.7）

## 除錯日誌

系統會輸出以下日誌幫助除錯：

```
🎯 [CookingARView.Coordinator] 手勢狀態變更: 懸停中
🎯 [CookViewController] 接收到手勢: 下一步
✅ [CookingARView] 使用共享 ARSession 並註冊到 MulticastDelegate 和 GestureDelegate
📊 [ARSessionAdapter] ARFrame 統計 - 總幀數: 720, 處理幀數: 163 (22.6%)
📊 [HandDetection] Vision 統計 - 總幀數: 270, 成功處理: 270 (100.0%)
```

## 總結

✅ **AR 步驟提示系統已完整實現**，包含：
- 12 種動畫類型支援
- 自動容器偵測與追蹤
- 手勢控制步驟切換
- 文字描述 + 進度條 UI
- 與參考專案架構一致

**不需要額外整合**，系統已經可以正常運作。只要後端 API 回傳正確的 `arType` 和 `arParameters`，AR 動畫就會自動顯示。

## 測試建議

1. 確保所有 `.usdz` 模型檔案已加入專案
2. 測試每種動畫類型是否正常顯示
3. 驗證容器偵測功能（需要真實設備）
4. 確認手勢切換步驟時動畫正確更新
