# JSON 欄位映射修正

## 問題診斷

從 Console 日誌可以看到：
```
⚠️ [CookingARView] 無 AR 動畫：arType=nil, arParameters=nil
```

所有步驟的 AR 參數都是 `nil`，表示 JSON 解碼失敗。

## 根本原因

後端回傳的 JSON 欄位名稱與 Swift 模型不一致：

### 後端 JSON 格式
```json
{
  "ARtype": "torch",           // ← 注意是大寫 "AR"
  "ar_parameters": {           // ← 注意是蛇形命名
    "type": "torch",
    "ingredient": "salmon",
    ...
  }
}
```

### Swift 模型期望
```swift
struct RecipeStep {
    var arType: ARAnimationType?      // ← 駝峰命名
    var arParameters: ARAnimationParams?
}
```

## 修正方案

### 1. RecipeStep 添加 CodingKeys

```swift
struct RecipeStep: Codable {
    var arType: ARAnimationType?
    var arParameters: ARAnimationParams?

    private enum CodingKeys: String, CodingKey {
        case step_number
        case title
        case description
        case actions
        case estimated_total_time
        case temperature
        case warnings
        case notes
        case arType = "ARtype"              // ✅ 映射 "ARtype" → arType
        case arParameters = "ar_parameters" // ✅ 映射 "ar_parameters" → arParameters
    }
}
```

### 2. ARAnimationParams 忽略 type 欄位

```swift
struct ARAnimationParams: Codable {
    var coordinate: [Double]?
    var container: String?
    var ingredient: String?
    // ... 其他欄位

    private enum CodingKeys: String, CodingKey {
        case coordinate
        case container
        case ingredient
        case color
        case time
        case temperature
        case flameLevel
        // ✅ 不包含 "type"，因為它已經在 arType 中
    }
}
```

## 測試結果預期

修正後重新運行 App，你應該會看到：

### 步驟 1 (cut)
```
🎬 [CookingARView] updateUIView called for step 1
📝 [CookingARView] Step title: 準備鮭魚
✅ [CookingARView] 檢測到 AR 動畫：cut
📦 [CookingARView] AR 參數：container=nil, ingredient=salmon
```

### 步驟 2 (putIntoContainer)
```
🎬 [CookingARView] updateUIView called for step 2
📝 [CookingARView] Step title: 放置鮭魚片
✅ [CookingARView] 檢測到 AR 動畫：putIntoContainer
📦 [CookingARView] AR 參數：container=sushi, ingredient=salmon
```

### 步驟 3 (torch) 🔥
```
🎬 [CookingARView] updateUIView called for step 3
📝 [CookingARView] Step title: 炙燒鮭魚
✅ [CookingARView] 檢測到 AR 動畫：torch
📦 [CookingARView] AR 參數：container=nil, ingredient=salmon
🏭 [AnimationFactory] 創建 TorchAnimation
🔥 [TorchAnimation] 初始化 TorchAnimation
🔥 [TorchAnimation] 嘗試載入 torch.usdz
✅ [TorchAnimation] torch.usdz 載入成功
✅ [TorchAnimation] 動畫播放指令已發送
```

## 後端 JSON 完整範例

```json
{
  "recipe": [
    {
      "step_number": 3,
      "title": "炙燒鮭魚",
      "description": "使用噴槍炙燒鮭魚表面，直到表面呈現金黃色。",
      "ARtype": "torch",
      "ar_parameters": {
        "type": "torch",
        "ingredient": "salmon",
        "color": null,
        "time": null,
        "temperature": null,
        "flameLevel": null
      },
      "actions": [...],
      "estimated_total_time": "3分鐘",
      "temperature": "高溫",
      "warnings": "噴槍使用時請注意安全，避免燙傷。",
      "notes": "炙燒時間不宜過長，以免鮭魚過熟，影響口感。"
    }
  ]
}
```

## 下一步測試

1. **重新編譯並運行 App**
2. **進入烹飪模式**
3. **觀察 Console 日誌**

如果看到：
- ✅ `檢測到 AR 動畫：torch` → JSON 解碼成功
- ✅ `torch.usdz 載入成功` → 模型檔案存在
- ✅ `動畫播放指令已發送` → 動畫應該顯示

如果仍然看到問題，請提供完整的 Console 日誌。
