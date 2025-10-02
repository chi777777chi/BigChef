//
//  HandDetectionManager.swift
//  Hand detection operating system
//
//  Created by ipad on 2025/9/14.
//

import Foundation
import Vision
import AVFoundation
import UIKit

// MARK: - Hand Landmark Data Model
struct HandLandmark {
    let point: CGPoint
    let confidence: Float
    let jointName: VNHumanHandPoseObservation.JointName
}

struct HandDetectionResult {
    let landmarks: [HandLandmark]
    let boundingBox: CGRect
    let chirality: VNChirality
    let confidence: Float
}

// MARK: - Hand Detection Manager
class HandDetectionManager: ObservableObject {
    @Published var detectedHands: [HandDetectionResult] = []
    @Published var isDetecting = false
    @Published var error: String?
    
    // 手勢辨識相關
    @Published var gestureRecognizer: HandGestureRecognizer
    @Published var isGestureEnabled = false
    
    private var handPoseRequest: VNDetectHumanHandPoseRequest
    
    // ✅ 背景線程專用 queue，避免阻塞 ARKit 渲染
    private let visionQueue = DispatchQueue(label: "com.chef.vision.handpose", qos: .userInitiated)
    
    // 診斷用計數器
    private var visionFrameCount = 0
    private var visionSuccessCount = 0
    
    // 手指關節名稱映射
    private let jointNames: [VNHumanHandPoseObservation.JointName] = [
        // 拇指
        .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
        // 食指
        .indexTip, .indexDIP, .indexPIP, .indexMCP,
        // 中指
        .middleTip, .middleDIP, .middlePIP, .middleMCP,
        // 無名指
        .ringTip, .ringDIP, .ringPIP, .ringMCP,
        // 小指
        .littleTip, .littleDIP, .littlePIP, .littleMCP,
        // 手腕
        .wrist
    ]
    
    init() {
        // 初始化手勢辨識器
        gestureRecognizer = HandGestureRecognizer()
        
        // 初始化手部姿勢檢測請求
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 2 // 最多檢測兩隻手
        
        print("🔧 [HandDetection] Vision 請求初始化 - 最大手數: \(handPoseRequest.maximumHandCount)")
        
        // 設定手勢辨識器的委託
        setupGestureRecognizer()
    }
    
    // MARK: - Public Methods
    
    /// 處理相機幀進行手部檢測（來自 ARFrame）
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // ✅ 移除 isDetecting 檢查，讓 Vision 可以持續處理 frame
        // ARKit 會以 60fps 傳入 frame，Vision 處理較慢沒關係，會自動跳過
        
        // 計數接收到的幀
        visionFrameCount += 1
        
        // ✅ 在背景線程執行 Vision，不阻塞 ARKit 渲染
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 創建 request handler（每次都新建，避免狀態競爭）
            let requestHandler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up,
                options: [:]
            )
            
            do {
                // ✅ 在背景線程執行 Vision 請求
                try requestHandler.perform([self.handPoseRequest])
                
                self.visionSuccessCount += 1
                
                // 每 30 幀打印一次診斷資訊
                if self.visionFrameCount % 30 == 0 {
                    let successRate = Float(self.visionSuccessCount) / Float(self.visionFrameCount) * 100
                    print("📊 [HandDetection] Vision 統計 - 總幀數: \(self.visionFrameCount), 成功處理: \(self.visionSuccessCount) (\(String(format: "%.1f", successRate))%)")
                }
                
                // ✅ 在背景線程處理結果，只有 UI 更新才回主線程
                self.processHandPoseResults(request: self.handPoseRequest, error: nil)
                
            } catch {
                // 錯誤處理回主線程
                DispatchQueue.main.async {
                    self.error = "手部檢測失敗: \(error.localizedDescription)"
                    print("❌ [HandDetection] Vision 處理錯誤: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 處理靜態圖像進行手部檢測
    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { [weak self] in
                self?.error = "無法處理圖像"
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isDetecting = true
        }
        
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try imageRequestHandler.perform([self.handPoseRequest])
                
                // 處理結果
                self.processHandPoseResults(request: self.handPoseRequest, error: nil)
                
                DispatchQueue.main.async {
                    self.isDetecting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "圖像手部檢測失敗: \(error.localizedDescription)"
                    self.isDetecting = false
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func processHandPoseResults(request: VNRequest, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = "檢測錯誤: \(error.localizedDescription)"
                print("❌ [HandDetection] processHandPoseResults 錯誤: \(error.localizedDescription)")
            }
            return
        }
        
        guard let observations = request.results as? [VNHumanHandPoseObservation] else {
            return
        }
        
        // ✅ 在背景線程處理觀察結果
        var newResults: [HandDetectionResult] = []
        
        for observation in observations {
            if let handResult = processHandObservation(observation) {
                newResults.append(handResult)
            }
        }
        
        // ✅ 只有 UI 更新才回主線程
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.detectedHands = newResults
            self.error = nil
        }
        
        // ✅ 修正：無論有沒有手部都要呼叫，這樣才能處理「手離開」的情況
        if isGestureEnabled {
            gestureRecognizer.processHandDetection(newResults)
        }
    }
    
    private func processHandObservation(_ observation: VNHumanHandPoseObservation) -> HandDetectionResult? {
        var landmarks: [HandLandmark] = []
        
        // 提取所有關節點
        for jointName in jointNames {
            do {
                let jointPoint = try observation.recognizedPoint(jointName)
                
                // 只添加置信度足夠高的關節點
                if jointPoint.confidence > 0.3 {
                    let landmark = HandLandmark(
                        point: CGPoint(x: jointPoint.location.x, y: 1 - jointPoint.location.y), // Vision 坐標系轉換
                        confidence: jointPoint.confidence,
                        jointName: jointName
                    )
                    landmarks.append(landmark)
                }
            } catch {
                // 某些關節點可能無法識別，繼續處理其他關節點
                continue
            }
        }
        
        guard !landmarks.isEmpty else { 
            return nil 
        }
        
        // 計算邊界框
        let boundingBox = calculateBoundingBox(for: landmarks)
        
        return HandDetectionResult(
            landmarks: landmarks,
            boundingBox: boundingBox,
            chirality: observation.chirality,
            confidence: Float(observation.confidence)
        )
    }
    
    private func calculateBoundingBox(for landmarks: [HandLandmark]) -> CGRect {
        guard !landmarks.isEmpty else { return .zero }
        
        let xCoordinates = landmarks.map { $0.point.x }
        let yCoordinates = landmarks.map { $0.point.y }
        
        let minX = xCoordinates.min() ?? 0
        let maxX = xCoordinates.max() ?? 0
        let minY = yCoordinates.min() ?? 0
        let maxY = yCoordinates.max() ?? 0
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    // MARK: - Utility Methods
    
    /// 獲取特定手指的所有關節點
    func getLandmarksForFinger(_ finger: FingerType) -> [HandLandmark] {
        let allLandmarks = detectedHands.flatMap { $0.landmarks }
        
        return allLandmarks.filter { landmark in
            finger.jointNames.contains(landmark.jointName)
        }
    }
    
    /// 檢查是否檢測到手部
    var hasDetectedHands: Bool {
        return !detectedHands.isEmpty
    }
    
    /// 獲取檢測到的手部數量
    var detectedHandCount: Int {
        return detectedHands.count
    }
    
    // MARK: - Gesture Recognition Methods
    
    /// 啟用/停用手勢辨識
    func setGestureEnabled(_ enabled: Bool) {
        isGestureEnabled = enabled
        gestureRecognizer.setEnabled(enabled)
    }
    
    /// 重置手勢辨識狀態
    func resetGestureRecognition() {
        gestureRecognizer.reset()
    }
    
    // MARK: - Private Gesture Methods
    
    private func setupGestureRecognizer() {
        // 這裡可以設定手勢辨識器的委託，如果需要的話
        // 目前使用 Published 屬性來觀察狀態變化
    }
}

// MARK: - Finger Type Enum
enum FingerType: String, CaseIterable {
    case thumb = "拇指"
    case index = "食指"
    case middle = "中指"
    case ring = "無名指"
    case little = "小指"
    
    var jointNames: [VNHumanHandPoseObservation.JointName] {
        switch self {
        case .thumb:
            return [.thumbTip, .thumbIP, .thumbMP, .thumbCMC]
        case .index:
            return [.indexTip, .indexDIP, .indexPIP, .indexMCP]
        case .middle:
            return [.middleTip, .middleDIP, .middlePIP, .middleMCP]
        case .ring:
            return [.ringTip, .ringDIP, .ringPIP, .ringMCP]
        case .little:
            return [.littleTip, .littleDIP, .littlePIP, .littleMCP]
        }
    }
    
    var color: UIColor {
        switch self {
        case .thumb: return .systemRed
        case .index: return .systemBlue
        case .middle: return .systemGreen
        case .ring: return .systemOrange
        case .little: return .systemPurple
        }
    }
}
