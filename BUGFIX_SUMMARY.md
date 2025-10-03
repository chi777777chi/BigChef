# 編譯錯誤修正摘要

## 錯誤描述
```
/Users/mchiii/Desktop/BigChef/Chef/ChefHelper/Camera/ARSessionAdapter.swift:206:19
Value of type 'ARSessionAdapter' has no member 'gestureDelegate'

/Users/mchiii/Desktop/BigChef/Chef/ChefHelper/Camera/ARSessionAdapter.swift:206:69
Cannot infer contextual base in reference to member 'systemError'
```

## 根本原因
在重構 `ARSessionAdapter` 時，將原本的 `weak var gestureDelegate: ARGestureDelegate?` 改為 `MulticastGestureDelegate`，但在 `session(_:didFailWithError:)` 方法中仍使用了舊的 `gestureDelegate` 變數名稱。

## 修正內容

### 修改檔案：`Chef/ChefHelper/Camera/ARSessionAdapter.swift`

**修正前 (第 206 行)：**
```swift
self?.gestureDelegate?.gestureRecognitionDidFail(with: .systemError(error.localizedDescription))
```

**修正後：**
```swift
self?.multicastGestureDelegate.gestureRecognitionDidFail(with: .systemError(error.localizedDescription))
```

## 完整修改區塊

```swift
// MARK: - ARSession 錯誤處理
func session(_ session: ARSession, didFailWithError error: Error) {
    print("❌ [ARSessionAdapter] ARSession 錯誤: \(error.localizedDescription)")
    // 可以轉發錯誤給所有註冊的委託
    DispatchQueue.main.async { [weak self] in
        self?.multicastGestureDelegate.gestureRecognitionDidFail(with: .systemError(error.localizedDescription))
    }
}
```

## 驗證
- ✅ `MulticastGestureDelegate` 存在且實現了 `ARGestureDelegate` 協議
- ✅ `GestureRecognitionError.systemError(String)` case 已定義
- ✅ `multicastGestureDelegate` 在 `ARSessionAdapter` 中已正確宣告
- ✅ 所有其他使用 `gestureDelegate` 的地方已更新為 `multicastGestureDelegate`

## 相關變更
此修正是 AR 手勢狀態動畫系統重構的一部分，詳見 `AR_GESTURE_ANIMATION_UPDATE.md`。

## 影響範圍
僅影響 ARSession 錯誤處理的事件轉發，不影響現有功能。錯誤訊息現在會正確轉發給所有註冊的手勢 delegate。
