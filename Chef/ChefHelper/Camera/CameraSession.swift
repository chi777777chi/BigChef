//
//  CameraSession.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/7.
//

import UIKit

/// 把不同「攝影流程」抽象成同一介面
public protocol CameraSession {
    /// 用來顯示即時畫面的 UIView（AV 或 AR）
    var previewView: UIView { get }

    /// 開始或恢復 Session
    func start()

    /// 暫停並盡量釋放資源
    func stop()
}
