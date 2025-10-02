//
//  ARGestureDelegate.swift
//  ChefHelper
//
//  Created by AI Assistant on 2025/9/15.
//

import Foundation

// MARK: - AR 手勢委託協議
protocol ARGestureDelegate: AnyObject {
    /// 辨識到手勢動作
    func didRecognizeGesture(_ gestureType: GestureType)
    
    /// 手勢狀態改變
    func gestureStateDidChange(_ state: GestureState)
    
    /// 懸停進度更新
    func hoverProgressDidUpdate(_ progress: Float)
    
    /// 手掌狀態改變
    func palmStateDidChange(_ palmState: PalmState)
    
    /// 手勢辨識出錯
    func gestureRecognitionDidFail(with error: GestureRecognitionError)
}
