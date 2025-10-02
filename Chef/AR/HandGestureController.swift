import UIKit
import AVFoundation
import Vision

class HandGestureController: NSObject {
    // MARK: — 屬性
    private let session = AVCaptureSession()
    private let handPoseReq = VNDetectHumanHandPoseRequest()
    private let sequenceHandler = VNSequenceRequestHandler()
    
    /// 前一幀的手掌 X 座標
    private var previousHandX: CGFloat?
    /// 判定滑動的最小位移（畫素）
    private let swipeThreshold: CGFloat = 50
    
    // Callback
    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    
    // MARK: — 初始化並啟動
    func start() throws {
        // 1. 設定相機
        session.sessionPreset = .high
        guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: cam)
        else { throw NSError(domain: "HandGesture", code: -1, userInfo: nil) }
        
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(output)
        
        session.startRunning()
        
        // 2. Hand Pose Request 參數
        handPoseReq.maximumHandCount = 1
    }
    
    func stop() {
        session.stopRunning()
    }
}

extension HandGestureController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        
        // 1. 執行手勢偵測
        let reqs: [VNRequest] = [handPoseReq]
        do {
            try sequenceHandler.perform(reqs, on: pixelBuffer)
        } catch {
            return
        }
        
        // 2. 取出偵測結果
        guard let result = handPoseReq.results?.first,
              let wristPoint = try? result.recognizedPoint(.wrist),
              wristPoint.confidence > 0.3
        else {
            previousHandX = nil
            return
        }
        
        // 3. 換算成畫面座標（0…1 轉成實際畫素）
        let normalized = CGPoint(x: wristPoint.location.x, y: 1 - wristPoint.location.y)
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let currentHandX = normalized.x * width
        
        // 4. 如果有前一幀，計算位移
        if let prevX = previousHandX {
            let dx = currentHandX - prevX
            if dx > swipeThreshold {
                // 右滑
                DispatchQueue.main.async { self.onSwipeRight?() }
                previousHandX = nil  // 一次滑動只觸發一次
            } else if dx < -swipeThreshold {
                // 左滑
                DispatchQueue.main.async { self.onSwipeLeft?() }
                previousHandX = nil
            }
        } else {
            // 第一次初始化
            previousHandX = currentHandX
        }
    }
}
