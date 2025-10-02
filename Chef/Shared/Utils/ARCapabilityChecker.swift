//
//  ARCapabilityChecker.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/23.
//

import ARKit
import Foundation

struct ARCapabilityChecker {
    enum ARCapability {
        case supported        // 真實設備支援 AR
        case simulatorMode    // 模擬器，使用模擬模式
        case notSupported     // 真實設備但不支援 AR
    }

    /// 檢查 AR 能力
    static func checkARCapability() -> ARCapability {
        #if targetEnvironment(simulator)
        // 在模擬器中運行
        print("🖥️ 檢測到模擬器環境，將使用 AR 模擬模式")
        return .simulatorMode
        #else
        // 在真實設備上運行
        if ARWorldTrackingConfiguration.isSupported {
            print("📱 檢測到真實設備支援 AR")
            return .supported
        } else {
            print("❌ 真實設備不支援 AR")
            return .notSupported
        }
        #endif
    }

    /// 是否在模擬器中運行
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否可以使用 AR（包含模擬模式）
    static var canUseAR: Bool {
        switch checkARCapability() {
        case .supported, .simulatorMode:
            return true
        case .notSupported:
            return false
        }
    }

    /// 獲取 AR 模式描述
    static func getARModeDescription() -> String {
        switch checkARCapability() {
        case .supported:
            return "真實 AR 模式"
        case .simulatorMode:
            return "模擬器模式"
        case .notSupported:
            return "不支援 AR"
        }
    }

    /// 檢查相機權限（模擬器中返回模擬結果）
    static func checkCameraPermission() -> Bool {
        #if targetEnvironment(simulator)
        // 模擬器中模擬權限已授予
        return true
        #else
        // 真實設備檢查實際權限
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        #endif
    }
}

// MARK: - AR Error Types

enum ARError: LocalizedError {
    case deviceNotSupported
    case cameraPermissionDenied
    case simulatorModeOnly
    case initializationFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .deviceNotSupported:
            return "此設備不支援 AR 功能"
        case .cameraPermissionDenied:
            return "需要相機權限才能使用 AR 功能，請到設定中開啟"
        case .simulatorModeOnly:
            return "模擬器中只能使用 AR 模擬模式"
        case .initializationFailed:
            return "AR 初始化失敗"
        case .unknown(let message):
            return "AR 啟動失敗: \(message)"
        }
    }

    var recoveryMessage: String? {
        switch self {
        case .cameraPermissionDenied:
            return "請點擊「前往設定」開啟相機權限"
        case .deviceNotSupported:
            return "請使用支援 AR 的設備"
        case .simulatorModeOnly:
            return "請在真實設備上測試完整 AR 功能"
        default:
            return nil
        }
    }

    var showSettingsButton: Bool {
        switch self {
        case .cameraPermissionDenied:
            return true
        default:
            return false
        }
    }
}