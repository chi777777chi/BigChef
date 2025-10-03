# AR 手勢狀態動畫實現

## 概述
此次更新實現了根據手勢狀態（懸停中、準備就緒等）在 AR 場景中顯示相應的視覺回饋動畫。

## 主要修改

### 1. 新增檔案

#### `Chef/ChefHelper/Camera/MulticastGestureDelegate.swift`
- 手勢 delegate 的多重廣播器
- 允許多個對象（CookViewController 和 CookingARView.Coordinator）同時接收手勢事件
- 使用 weak reference 避免記憶體洩漏

### 2. 修改檔案

#### `Chef/AR/CookingARView.swift`
**新增功能：**
- Coordinator 實現 `ARGestureDelegate` 協議
- 根據不同手勢狀態顯示視覺指示器：
  - **檢測中** (detecting): 黃色脈動球體
  - **懸停中** (hovering): 橙色環形進度指示器
  - **準備就緒** (ready): 綠色勾選標記
  - **處理中** (processing): 藍色旋轉指示器
  - **完成** (completed): 綠色閃爍效果
  - **空閒** (idle): 不顯示指示器

**主要方法：**
- `gestureStateDidChange(_:)` - 監聽手勢狀態變化
- `hoverProgressDidUpdate(_:)` - 更新懸停進度（動畫放大效果）
- `updateGestureIndicator(for:)` - 根據狀態創建視覺指示器
- `createPulsingIndicator(color:radius:)` - 創建脈動動畫
- `createRingIndicator(color:radius:)` - 創建環形指示器
- `createSpinningIndicator(color:radius:)` - 創建旋轉動畫

#### `Chef/ChefHelper/Camera/ARSessionAdapter.swift`
**主要修改：**
- 將 `weak var gestureDelegate` 改為 `MulticastGestureDelegate`
- 新增 `addGestureDelegate(_:)` 和 `removeGestureDelegate(_:)` 方法
- 所有手勢事件轉發給 multicast delegate，支援多個監聽者

#### `Chef/Features/Cooking/CookViewController.swift`
**主要修改：**
- `viewWillAppear(_:)` 中使用 `addGestureDelegate(self)` 註冊
- `viewWillDisappear(_:)` 中使用 `removeGestureDelegate(self)` 移除註冊

## 視覺回饋說明

### 手勢狀態對應的視覺效果

| 手勢狀態 | 視覺效果 | 顏色 | 動畫 |
|---------|---------|------|------|
| idle (空閒) | 無指示器 | - | - |
| detecting (檢測中) | 球體 | 黃色 | 脈動 |
| hovering (懸停中) | 環形 | 橙色 | 隨進度放大 |
| ready (準備就緒) | 球體 | 綠色 | 靜態 |
| processing (處理中) | 方塊 | 藍色 | 旋轉 |
| completed (完成) | 球體 | 綠色 | 閃爍 |

### 懸停進度效果
- 懸停期間，指示器會根據進度（0.0 ~ 1.0）逐漸放大
- 進度 0%: 正常大小
- 進度 100%: 放大 1.5 倍

## 技術細節

### 多重 Delegate 模式
使用 `MulticastGestureDelegate` 允許：
- CookViewController 接收手勢事件以切換步驟
- CookingARView.Coordinator 接收手勢狀態以顯示視覺回饋
- 避免單一 delegate 被覆蓋的問題

### 記憶體管理
- 所有 delegate 使用 weak reference
- 自動清理已釋放的 delegate
- 避免循環引用

### 線程安全
- 所有 UI 更新都在 main thread 執行
- 使用 `@MainActor` 確保 RealityKit 操作的正確性

## 使用示例

```swift
// 在 viewWillAppear 中註冊
gestureSession.addGestureDelegate(self)

// 在 viewWillDisappear 中移除
gestureSession.removeGestureDelegate(self)
```

## 未來改進方向

1. **更豐富的視覺效果**
   - 使用自定義 3D 模型（如勾選符號、箭頭等）
   - 添加粒子效果
   - 實現更流暢的動畫過渡

2. **可配置性**
   - 允許用戶自定義指示器顏色
   - 調整動畫速度和大小
   - 選擇不同的視覺風格

3. **性能優化**
   - 重用 entity 減少創建/銷毀開銷
   - 優化動畫循環
   - 降低渲染負擔

## 日誌輸出

系統會輸出以下日誌以便調試：
```
🎯 [CookingARView.Coordinator] 手勢狀態變更: 檢測中
🎯 [CookingARView.Coordinator] 手勢狀態變更: 懸停中
🎯 [CookingARView.Coordinator] 手勢狀態變更: 準備就緒
🎯 [CookingARView.Coordinator] 接收到手勢: 下一步
🔗 [MulticastGestureDelegate] 添加 delegate: Coordinator, 總數: 2
```
