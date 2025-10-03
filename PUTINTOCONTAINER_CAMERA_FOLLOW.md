# PutIntoContainerAnimation 相機跟隨功能

## 修改內容

將 `PutIntoContainerAnimation` 的食材模型和文字改為始終跟隨相機移動並面對相機。

## 實現方式

### 1. 使用相機錨點（Camera Anchor）

**修改前**：
```swift
// 模型掛在世界座標錨點上，位置固定
let anchor = AnchorEntity(world: .zero)
```

**修改後**：
```swift
// 創建相機錨點，模型會跟隨相機移動
let cameraAnchor = AnchorEntity(.camera)
cameraAnchor.name = "PutIntoContainerCameraAnchor"
arView.scene.addAnchor(cameraAnchor)

// 將原本的 anchor 設為相機錨點的子物件
anchor.setParent(cameraAnchor)
```

### 2. 添加 Billboard 效果

使用 `BillboardComponent` 讓模型始終面對相機：

```swift
// 讓模型面對相機
entity.components.set(BillboardComponent())

// 如果有文字子實體，也讓它面對相機
for child in entity.children {
    child.components.set(BillboardComponent())
}
```

### 3. 設置相對位置

模型位置改為相對於相機：

```swift
// 相機前方 0.5 公尺，向上 0.2 公尺
var start = SIMD3<Float>(0, 0.2, -0.5)
entity.position = start
```

## 效果說明

### 相機跟隨
- 當用戶移動相機（手機）時，食材模型會保持在相機前方
- 模型距離相機約 0.5 公尺
- 模型始終在視野中心偏上方

### Billboard 效果
- 食材 3D 模型始終正面朝向相機
- 文字標籤始終正面朝向相機
- 無論相機如何旋轉，模型都不會側面或背面朝向用戶

## 座標系統

```
相機座標系統：
- X 軸：左(-) 右(+)
- Y 軸：下(-) 上(+)
- Z 軸：前(-) 後(+)

位置設定：
SIMD3<Float>(0, 0.2, -0.5)
             │   │    └─ 相機前方 0.5 公尺
             │   └────── 向上 0.2 公尺
             └────────── 水平居中
```

## 測試步驟

### 1. 運行 App 並進入烹飪模式

選擇有 `putIntoContainer` 動畫的步驟。

### 2. 觀察 Console 日誌

```
🍽️ [PutIntoContainer] applyAnimation 開始
🆕 [PutIntoContainer] 創建新的 PutIntoContainerCameraAnchor
✅ [PutIntoContainer] 模型已添加到相機錨點，初始位置: (0.0, 0.2, -0.5)
```

### 3. 移動手機測試

- **左右移動手機**：模型應該跟隨相機移動
- **上下移動手機**：模型應該跟隨相機移動
- **旋轉手機**：模型應該始終正面朝向你

### 4. 預期結果

✅ 食材模型始終在視野中
✅ 模型正面朝向相機
✅ 文字可清楚閱讀（不會側面或顛倒）
✅ 相機移動時模型跟隨移動

## 調整參數

如果覺得模型位置不理想，可以調整以下參數：

### 距離調整

```swift
// 更近（0.3 公尺）
var start = SIMD3<Float>(0, 0.2, -0.3)

// 更遠（0.8 公尺）
var start = SIMD3<Float>(0, 0.2, -0.8)
```

### 高度調整

```swift
// 更高（視野上方）
var start = SIMD3<Float>(0, 0.4, -0.5)

// 更低（視野下方）
var start = SIMD3<Float>(0, 0, -0.5)
```

### 水平調整

```swift
// 偏左
var start = SIMD3<Float>(-0.2, 0.2, -0.5)

// 偏右
var start = SIMD3<Float>(0.2, 0.2, -0.5)
```

## 技術細節

### BillboardComponent

RealityKit 內建組件，功能：
- 自動旋轉實體使其面對相機
- 只影響旋轉，不影響位置
- 適合文字標籤和 2D 元素

### 相機錨點重用

```swift
// 檢查是否已存在相機錨點
if let existing = arView.scene.findEntity(named: "PutIntoContainerCameraAnchor") {
    cameraAnchor = existing
} else {
    // 創建新錨點
    cameraAnchor = AnchorEntity(.camera)
    arView.scene.addAnchor(cameraAnchor)
}
```

好處：
- 避免創建多個相機錨點
- 性能更好
- 場景更整潔

## 注意事項

### 1. 容器偵測衝突

由於模型現在跟隨相機移動，原本的容器偵測邏輯可能需要調整：

- `updateBoundingBox(rect:)` 可能不再適用
- `drop(to:)` 的目標位置需要重新計算

### 2. 掉落動畫

目前掉落動畫是相對於相機座標，如果需要掉落到真實世界的容器位置，需要額外計算。

### 3. 性能考慮

Billboard 組件會每幀更新旋轉，對性能有輕微影響，但一般不明顯。

## 未來改進

1. **混合模式**：
   - 初始階段：跟隨相機（方便查看）
   - 掉落階段：固定到世界座標（真實物理感）

2. **平滑過渡**：
   - 添加動畫讓模型從相機錨點過渡到世界錨點

3. **距離自適應**：
   - 根據設備螢幕大小自動調整模型距離

## 相關檔案

- `/Chef/AR/Animation/PutIntoContainerAnimation.swift` - 主要修改檔案
- `/Chef/AR/Animation/Animation.swift` - 基礎動畫類別
- `/Chef/AR/CookingARView.swift` - AR 視圖容器
