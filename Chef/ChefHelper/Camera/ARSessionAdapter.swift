//
//  ARSessionAdapter.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/7.
//

import UIKit
import ARKit

/// ARKit 的包裝，符合 CameraSession，整合手勢辨識
final class ARSessionAdapter: NSObject, CameraSession, ARSessionDelegate {
    private let sceneView = ARSCNView(frame: .zero)
    let previewView: UIView
    
    // MARK: - ARSession 管理
    /// ✅ 暴露 ARSession 給其他模組使用（如 CookingARView）
    var arSession: ARSession {
        return sceneView.session
    }
    
    /// ✅ 多重 delegate 廣播器
    private let multicastDelegate = MulticastARSessionDelegate()
    
    // MARK: - 手勢檢測相關
    private let handDetectionManager = HandDetectionManager()
    /// ✅ 多重手勢 delegate 廣播器
    private let multicastGestureDelegate = MulticastGestureDelegate()
    private var isGestureEnabled = false
    
    // ✅ 節流機制：避免 Vision 每幀都處理（性能優化）
    private var lastVisionProcessTime = Date()
    private let visionProcessInterval: TimeInterval = 0.066  // ~15fps (1/15 ≈ 0.066)
    
    // 診斷用計數器
    private var frameCount = 0
    private var processedFrameCount = 0

    override init() {
        previewView = sceneView
        super.init()
        print("🆕 [ARSessionAdapter] init - 創建新實例")
        sceneView.automaticallyUpdatesLighting = true

        // ✅ 關鍵修正：使用多重 delegate
        sceneView.session.delegate = multicastDelegate

        // 將自己加入多重 delegate，以接收手勢辨識相關事件
        multicastDelegate.addDelegate(self)

        // 設定手勢檢測
        setupGestureDetection()

        // ✅ 設定 HandGestureRecognizer 的 delegate 以接收狀態更新
        handDetectionManager.gestureRecognizer.delegate = self
    }
    
    /// ✅ 讓其他模組（如 CookingARView）註冊為 ARSession delegate
    func addSessionDelegate(_ delegate: ARSessionDelegate) {
        multicastDelegate.addDelegate(delegate)
    }

    func removeSessionDelegate(_ delegate: ARSessionDelegate) {
        multicastDelegate.removeDelegate(delegate)
    }

    /// ✅ 讓其他模組（如 CookingARView, CookViewController）註冊為手勢 delegate
    func addGestureDelegate(_ delegate: ARGestureDelegate) {
        multicastGestureDelegate.addDelegate(delegate)
    }

    func removeGestureDelegate(_ delegate: ARGestureDelegate) {
        multicastGestureDelegate.removeDelegate(delegate)
    }
    
    deinit {
        print("🧹 ARSessionAdapter: deinit - 開始清理資源")

        // 停止 AR session
        sceneView.session.pause()
        sceneView.session.delegate = nil

        // 清理通知監聽
        NotificationCenter.default.removeObserver(self)

        // 清理多重委託
        multicastDelegate.removeAllDelegates()
        multicastGestureDelegate.removeAllDelegates()

        // 清理手勢檢測
        handDetectionManager.setGestureEnabled(false)

        print("🧹 ARSessionAdapter: deinit - 完成")
    }

    // MARK: - CameraSession
    func start() {
        let cfg = ARWorldTrackingConfiguration()
        cfg.planeDetection = [.horizontal]

        // ✅ 啟用 scene depth 以支持 CookingARView
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            cfg.frameSemantics.insert(.sceneDepth)
        }

        sceneView.session.run(cfg, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        print("🛑 [ARSessionAdapter] stop - 開始停止")
        sceneView.session.pause()
        // 停用手勢檢測
        setGestureEnabled(false)
        print("✅ [ARSessionAdapter] stop - 完成")
    }
    
    // MARK: - 手勢檢測控制
    func setGestureEnabled(_ enabled: Bool) {
        isGestureEnabled = enabled
        handDetectionManager.setGestureEnabled(enabled)

        if enabled {
            frameCount = 0
            processedFrameCount = 0
        }
    }
    
    // MARK: - 手勢檢測設定
    private func setupGestureDetection() {
        // 監聽手勢辨識結果通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGestureNotification),
            name: NSNotification.Name("GestureRecognized"),
            object: nil
        )
        
    }
    
    @objc private func handleGestureNotification(_ notification: Notification) {
        guard isGestureEnabled,
              let gestureTypeString = notification.userInfo?["type"] as? String else {
            return
        }
        
        let gestureType: GestureType
        switch gestureTypeString {
        case "上一步":
            gestureType = .previousStep
        case "下一步":
            gestureType = .nextStep
        default:
            return
        }
        
        // 轉發給所有註冊的委託
        DispatchQueue.main.async { [weak self] in
            self?.multicastGestureDelegate.didRecognizeGesture(gestureType)
        }
    }
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 計數所有接收到的幀
        frameCount += 1

        // 第一幀時打印診斷資訊
        // 第一幀時可在需要時加入診斷

        // 只有在啟用手勢檢測時才處理畫面
        guard isGestureEnabled else { return }
        
        // ✅ 節流機制：避免 Vision 處理過於頻繁，與 ARKit 爭搶資源
        let now = Date()
        let timeSinceLastProcess = now.timeIntervalSince(lastVisionProcessTime)
        
        guard timeSinceLastProcess >= visionProcessInterval else {
            // 跳過此幀，不處理
            return
        }
        
        // 更新最後處理時間
        lastVisionProcessTime = now
        processedFrameCount += 1
        
        // 每 60 幀打印一次診斷資訊
        // 可視情況加入統計輸出
        
        // ✅ 用 ARFrame 的畫面，避免爭搶相機資源
        // processFrame 內部已經用背景線程處理
        handDetectionManager.processFrame(frame.capturedImage)
    }
    
    // MARK: - ARSession 錯誤處理
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ [ARSessionAdapter] ARSession 錯誤: \(error.localizedDescription)")
        // 可以轉發錯誤給所有註冊的委託
        DispatchQueue.main.async { [weak self] in
            self?.multicastGestureDelegate.gestureRecognitionDidFail(with: .systemError(error.localizedDescription))
        }
    }
    
    func session(_ session: ARSession, wasInterrupted: Bool) {
        print("⚠️ [ARSessionAdapter] ARSession 被中斷")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ [ARSessionAdapter] ARSession 中斷開始")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ [ARSessionAdapter] ARSession 中斷結束")
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            if frameCount == 0 {
                print("✅ [ARSessionAdapter] ARCamera 追蹤正常，開始接收幀")
            }
        case .limited(let reason):
            print("⚠️ [ARSessionAdapter] ARCamera 追蹤受限: \(reason)")
        case .notAvailable:
            print("❌ [ARSessionAdapter] ARCamera 追蹤不可用")
        }
    }
}

// MARK: - HandGestureDelegate
extension ARSessionAdapter: HandGestureDelegate {
    func gestureStateDidChange(_ state: GestureState) {
        // 轉發給所有註冊的 ARGestureDelegate
        multicastGestureDelegate.gestureStateDidChange(state)
    }

    func palmStateDidChange(_ palmState: PalmState) {
        // 轉發給所有註冊的 ARGestureDelegate
        multicastGestureDelegate.palmStateDidChange(palmState)
    }

    func hoverProgressDidUpdate(_ progress: Float) {
        // 轉發給所有註冊的 ARGestureDelegate
        multicastGestureDelegate.hoverProgressDidUpdate(progress)
    }

    func didRecognizeGesture(_ result: GestureResult) {
        // 這個已經通過 NotificationCenter 處理，不需要再轉發
        // 避免重複觸發
    }

    func gestureRecognitionDidFail(with error: GestureRecognitionError) {
        // 轉發給所有註冊的 ARGestureDelegate
        multicastGestureDelegate.gestureRecognitionDidFail(with: error)
    }
}
