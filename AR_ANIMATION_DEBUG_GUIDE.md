# AR 動畫除錯指南

## 已添加的日誌追蹤

我已經在整個 AR 動畫流程中添加了詳細的日誌輸出，幫助你追蹤噴槍（或其他）動畫是否正確觸發和顯示。

## 日誌流程圖

```
步驟切換
    ↓
🎬 [CookingARView] updateUIView called
    ↓
📝 [CookingARView] Step title/description  ← 確認步驟資訊
    ↓
✅ [CookingARView] 檢測到 AR 動畫：torch  ← 確認有 arType
    ↓
📦 [CookingARView] AR 參數：...  ← 確認 arParameters
    ↓
🏭 [AnimationFactory] 開始創建動畫：torch
    ↓
🔥 [TorchAnimation] 初始化 TorchAnimation
    ↓
🔥 [TorchAnimation] 嘗試載入 torch.usdz  ← 檢查模型檔案
    ↓
✅ [TorchAnimation] torch.usdz 載入成功
    ↓
🎬 [Coordinator] playAnimationLoop 被呼叫
    ↓
▶️ [Coordinator] 開始播放動畫...
    ↓
🎭 [Animation] play() 開始
    ↓
🔥 [TorchAnimation] applyAnimation 開始
    ↓
✅ [TorchAnimation] 動畫播放指令已發送
```

## 測試步驟

### 1. 確認步驟資料包含 AR 參數

在開始烹飪前，確認 `RecipeStep` 包含：
```json
{
  "step_number": 2,
  "title": "炙燒魚片",
  "description": "使用噴槍炙燒鮭魚表面",
  "arType": "torch",
  "arParameters": {
    "ingredient": "鮭魚"
  }
}
```

### 2. 啟動 App 並進入烹飪模式

1. 打開 Xcode Console（Cmd + Shift + Y）
2. 啟動 App
3. 選擇包含噴槍步驟的食譜
4. 點擊「開始烹飪」

### 3. 觀察日誌輸出

當你切換到噴槍步驟時，應該看到以下日誌序列：

#### ✅ 正常情況（動畫應該顯示）

```
🎬 [CookingARView] updateUIView called for step 2
📝 [CookingARView] Step title: 炙燒魚片
📝 [CookingARView] Step description: 使用噴槍炙燒鮭魚表面
✅ [CookingARView] 檢測到 AR 動畫：torch
📦 [CookingARView] AR 參數：container=nil, ingredient=鮭魚
✅ [CookingARView] AnimationType 轉換成功：torch
🎨 [CookingARView] 動畫參數準備完成
🏭 [CookingARView] 呼叫 AnimationFactory.make(type: torch, params: ...)
🏭 [AnimationFactory] 開始創建動畫：torch
🏭 [AnimationFactory] 創建 TorchAnimation
🔥 [AnimationFactory] Torch 參數：ingredient=鮭魚, scale=1.0
🔥 [TorchAnimation] 初始化 TorchAnimation
🔥 [TorchAnimation] 嘗試載入 torch.usdz
✅ [TorchAnimation] 找到 torch.usdz：/path/to/torch.usdz
✅ [TorchAnimation] torch.usdz 載入成功
✅ [TorchAnimation] 初始化完成
✅ [AnimationFactory] 動畫創建完成：TorchAnimation
🎭 [CookingARView] 動畫創建完成：TorchAnimation
🔍 [CookingARView] 需要容器偵測：false
▶️ [CookingARView] 開始播放動畫...
✅ [CookingARView] playAnimationLoop() 已呼叫
🎬 [Coordinator] playAnimationLoop 被呼叫
🎬 [Coordinator] 動畫類型：torch
🎬 [Coordinator] 需要容器偵測：false
✅ [Coordinator] 不需要容器偵測，直接設置 isDetectionActive=true
▶️ [Coordinator] 開始播放動畫...
🎬 [Coordinator] 呼叫 animation.play(on: arView, reuseAnchor: false)
🎭 [Animation] play() 開始，type=torch, reuseAnchor=false
🆕 [Animation] 創建新 AnchorEntity
🎨 [Animation] 呼叫 applyAnimation(to: anchor, on: arView)
🔥 [TorchAnimation] applyAnimation 開始
🔥 [TorchAnimation] ARView scene anchors 數量：0
🔥 [TorchAnimation] 模型已添加到 anchor，scale=1.0, initial position=(0.0, -0.5, -0.5)
🔥 [TorchAnimation] 創建新的 TorchCameraAnchor
🔥 [TorchAnimation] anchor 已設置為相機子物件，最終 position=(0.0, 0.0, -0.5), distance=0.5
🔥 [TorchAnimation] 檢查可用動畫數量：1
🔥 [TorchAnimation] 找到動畫 clip，開始播放（isRepeat=true）
✅ [TorchAnimation] 動畫播放指令已發送
✅ [TorchAnimation] applyAnimation 完成
➕ [Animation] 將 anchor 添加到 scene
✅ [Animation] play() 完成，anchor 已添加到場景
✅ [Coordinator] animation.play() 已呼叫
```

#### ❌ 問題情況 1：沒有 AR 參數

```
🎬 [CookingARView] updateUIView called for step 2
📝 [CookingARView] Step title: 炙燒魚片
📝 [CookingARView] Step description: 使用噴槍炙燒鮭魚表面
⚠️ [CookingARView] 無 AR 動畫：arType=nil, arParameters=nil
```

**解決方法**：確認後端 API 有回傳 `arType` 和 `arParameters`

#### ❌ 問題情況 2：找不到 torch.usdz 檔案

```
🔥 [TorchAnimation] 嘗試載入 torch.usdz
❌ [TorchAnimation] 找不到 torch.usdz 檔案
```

**解決方法**：
1. 確認專案中有 `torch.usdz` 檔案
2. 確認檔案已添加到 Target Membership
3. 路徑：專案 → Resources → torch.usdz

#### ❌ 問題情況 3：USDZ 無可用動畫

```
🔥 [TorchAnimation] 檢查可用動畫數量：0
⚠️ [TorchAnimation] USDZ 無可用動畫：torch
```

**解決方法**：
1. 確認 `torch.usdz` 檔案包含動畫
2. 使用 Xcode 的 Reality Composer 檢查模型
3. 或重新匯出包含動畫的 USDZ 檔案

## 常見問題排查

### 問題 1：完全沒有日誌輸出

**可能原因**：
- `updateUIView` 沒被呼叫
- SwiftUI 視圖沒有更新

**檢查**：
```swift
// CookViewController.swift
private var currentIndex = 0 {
    didSet {
        updateStepLabel()
        // ✅ 確認這裡有重新設定 arContainer.rootView
        arContainer.rootView = CookingARView(
            stepModel: steps[currentIndex],
            sessionAdapter: gestureSession
        )
    }
}
```

### 問題 2：有日誌但看不到動畫

**可能原因**：
1. ARSession 未啟動
2. 相機權限未授權
3. 動畫位置不正確（太遠或太近）
4. 模型檔案損壞

**檢查清單**：
- [ ] ARSession 已啟動（查看 `✅ [ARSessionAdapter] ARSession 已啟動`）
- [ ] 相機畫面正常顯示
- [ ] anchor 已添加到場景（查看 `✅ [Animation] play() 完成，anchor 已添加到場景`）
- [ ] 動畫位置合理（distance=0.5 表示相機前方 0.5 公尺）

### 問題 3：步驟切換後動畫消失

**可能原因**：
- `uiView.scene.anchors.removeAll()` 清除了所有 anchor

**這是正常的**：每次步驟切換都會清除舊動畫並播放新動畫。

## 手動測試步驟資料

如果你想手動測試而不依賴後端 API，可以在 `CookViewController` 中添加測試資料：

```swift
// 測試用的步驟資料
let testSteps: [RecipeStep] = [
    RecipeStep(
        step_number: 1,
        title: "準備食材",
        description: "將鮭魚切片備用",
        actions: [],
        estimated_total_time: "5分鐘",
        temperature: "無",
        warnings: nil,
        notes: "",
        arType: .cut,
        arParameters: ARAnimationParams(
            coordinate: nil,
            container: nil,
            ingredient: "鮭魚",
            color: nil,
            time: nil,
            temperature: nil,
            flameLevel: nil
        )
    ),
    RecipeStep(
        step_number: 2,
        title: "炙燒魚片",
        description: "使用噴槍炙燒鮭魚表面",
        actions: [],
        estimated_total_time: "3分鐘",
        temperature: "無",
        warnings: nil,
        notes: "",
        arType: .torch,  // ← 噴槍動畫
        arParameters: ARAnimationParams(
            coordinate: nil,
            container: nil,
            ingredient: "鮭魚",
            color: nil,
            time: nil,
            temperature: nil,
            flameLevel: nil
        )
    )
]
```

## 下一步

1. **運行 App 並切換到噴槍步驟**
2. **複製完整的 Console 日誌**
3. **回報以下資訊**：
   - 看到哪些日誌？
   - 在哪個步驟停止？
   - 有任何錯誤訊息嗎？
   - 相機畫面是否正常？

根據你提供的日誌，我可以精確定位問題所在。
