//
//  GestureModels.swift
//  Hand detection operating system
//
//  Created by AI Assistant on 2025/9/15.
//

import Foundation
import CoreGraphics
import Vision

// MARK: - 手勢類型定義
enum GestureType: String, CaseIterable {
    case previousStep = "上一步"
    case nextStep = "下一步"
    
    var description: String {
        return self.rawValue
    }
    
    var systemImageName: String {
        switch self {
        case .previousStep: return "arrow.left"
        case .nextStep: return "arrow.right"
        }
    }
}

// MARK: - 手勢狀態
enum GestureState: String, CaseIterable {
    case idle = "空閒"           // 沒有檢測到手部或手部未比七
    case detecting = "檢測中"     // 檢測到手部，正在判斷是否比七
    case hovering = "懸停中"      // 比七手勢，正在計時懸停
    case ready = "準備就緒"       // 懸停完成，準備接收動作
    case processing = "處理中"    // 正在處理動作
    case completed = "完成"       // 動作完成
    
    var description: String {
        return self.rawValue
    }
}

// MARK: - 手勢辨識結果
struct GestureResult {
    let gestureType: GestureType
    let confidence: Float
    let timestamp: Date
    let handPosition: CGPoint
    
    init(gestureType: GestureType, confidence: Float, handPosition: CGPoint) {
        self.gestureType = gestureType
        self.confidence = confidence
        self.handPosition = handPosition
        self.timestamp = Date()
    }
}

// MARK: - 手掌狀態
struct PalmState {
    let isSevenGesture: Bool            // 是否為比七手勢（食指和大拇指伸直，其餘彎曲）
    let confidence: Float               // 比七手勢的信心度
    let centerPoint: CGPoint            // 手掌中心點
    let fingerExtensions: [Bool]        // 各手指是否伸展 [拇指, 食指, 中指, 無名指, 小指]
    let timestamp: Date
    
    init(isSevenGesture: Bool, confidence: Float, centerPoint: CGPoint, fingerExtensions: [Bool]) {
        self.isSevenGesture = isSevenGesture
        self.confidence = confidence
        self.centerPoint = centerPoint
        self.fingerExtensions = fingerExtensions
        self.timestamp = Date()
    }
    
    // 為了向後兼容，保留 isOpen 屬性
    var isOpen: Bool {
        return isSevenGesture
    }
}

// MARK: - 懸停狀態
struct HoverState {
    let startTime: Date                 // 開始懸停時間
    let startPosition: CGPoint          // 開始位置
    let currentPosition: CGPoint        // 當前位置
    let isStable: Bool                  // 是否穩定
    let duration: TimeInterval          // 已懸停時間
    
    var isCompleted: Bool {
        // 只要時間達到就算完成，不需要嚴格要求最後一刻的穩定性
        return duration >= GestureConfig.shared.hoverDuration
    }
}

// MARK: - 動作追蹤狀態
struct MotionTrackingState {
    let startPosition: CGPoint          // 開始位置
    let currentPosition: CGPoint        // 當前位置
    let velocity: CGVector              // 移動速度
    let direction: MotionDirection      // 移動方向
    let distance: Float                 // 移動距離
    let startTime: Date                 // 開始時間
    
    var duration: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
}

// MARK: - 移動方向
enum MotionDirection: String, CaseIterable {
    case up = "向上"
    case down = "向下"
    case left = "向左"
    case right = "向右"
    case none = "無方向"
    
    var description: String {
        return self.rawValue
    }
}

// MARK: - 手勢辨識配置
class GestureConfig {
    static let shared = GestureConfig()
    
    private init() {}
    
    // MARK: - 比七手勢檢測配置
    /// 手指伸展判斷的最小距離比例
    var fingerExtensionThreshold: Float = 0.3
    
    /// 比七手勢的最小信心度
    var sevenGestureConfidenceThreshold: Float = 0.5
    
    /// 比七手勢需要伸展的手指數量（食指和大拇指）
    var sevenGestureRequiredFingers: Int = 2
    
    /// 比七手勢需要彎曲的手指數量（中指、無名指、小指）
    var sevenGestureBentFingers: Int = 3
    
    // MARK: - 懸停檢測配置
    /// 懸停所需的時間（秒）
    var hoverDuration: TimeInterval = 1.0
    
    /// 懸停時允許的最大位置變化（比例）
    var hoverStabilityThreshold: Float = 0.15
    
    /// 懸停檢測的採樣間隔（秒）
    var hoverSampleInterval: TimeInterval = 0.1
    
    // MARK: - 動作檢測配置
    /// 左右動作的最小移動距離（比例）
    var minimumMotionDistance: Float = 0.15
    
    /// 動作檢測的最大時間窗口（秒）
    var motionTimeWindow: TimeInterval = 2.0
    
    
    /// 動作檢測的最小信心度
    var motionConfidenceThreshold: Float = 0.8
    
    /// 食指指向檢測的最小距離（比例）
    var pointingMinimumDistance: Float = 0.1
    
    // MARK: - 效能配置
    /// 手勢檢測的最大頻率（FPS）
    var maxDetectionFrequency: Double = 15.0
    
    /// 連續檢測失敗後的冷卻時間（秒）
    var cooldownDuration: TimeInterval = 0.5
}

// MARK: - 手勢辨識委託協議
protocol HandGestureDelegate: AnyObject {
    /// 手勢狀態改變
    func gestureStateDidChange(_ state: GestureState)
    
    /// 手掌狀態改變
    func palmStateDidChange(_ palmState: PalmState)
    
    /// 懸停進度更新
    func hoverProgressDidUpdate(_ progress: Float)
    
    /// 檢測到手勢動作
    func didRecognizeGesture(_ result: GestureResult)
    
    /// 手勢辨識出錯
    func gestureRecognitionDidFail(with error: GestureRecognitionError)
}

// MARK: - 手勢辨識錯誤
enum GestureRecognitionError: Error, LocalizedError {
    case noHandDetected
    case palmNotOpen
    case hoverTimeout
    case motionTooSlow
    case motionTooFast
    case ambiguousMotion
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .noHandDetected:
            return "未檢測到手部"
        case .palmNotOpen:
            return "未做出比七手勢"
        case .hoverTimeout:
            return "懸停時間不足"
        case .motionTooSlow:
            return "動作太慢"
        case .motionTooFast:
            return "動作太快"
        case .ambiguousMotion:
            return "動作不明確"
        case .systemError(let message):
            return "系統錯誤: \(message)"
        }
    }
}
