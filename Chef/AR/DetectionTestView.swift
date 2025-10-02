import SwiftUI
import RealityKit
import ARKit
import UIKit
import Vision
import CoreML

// MARK: – SwiftUI 包裝 UIViewController
struct DetectionTestView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DetectionViewController {
        return DetectionViewController()
    }
    func updateUIViewController(_ vc: DetectionViewController, context: Context) { }
}

// MARK: – 測試用的 UIViewController
class DetectionViewController: UIViewController, ARSessionDelegate {
    
    var arView: ARView!
    var overlay: UIView!
    
    // 用 Vision 建立一個簡單的偵測請求（以預設模型為例）
    lazy var visionRequest: VNCoreMLRequest = {
        // 假設你已經把 .mlmodel 加入專案並生成了 MyObjectDetector().model
        let model = try! VNCoreMLModel(for: CookDetect().model)
        let req = VNCoreMLRequest(model: model) { [weak self] req, _ in
            self?.processDetections(from: req)
        }
        req.imageCropAndScaleOption = .scaleFill
        return req
    }()
    
    // 用來暫存最新偵測結果
    private var currentDetections: [VNRecognizedObjectObservation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. 建立 ARView
        arView = ARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)
        
        // 2. 建立透明 overlay
        overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = false
        view.addSubview(overlay)
        
        // 3. 啟動 AR session
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)
        arView.session.delegate = self
    }
    
    // MARK: – ARSession Delegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 每次拿到新的相機影像
        let pixelBuffer = frame.capturedImage
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([self.visionRequest])
        }
    }
    
    // MARK: – 處理偵測結果
    private func processDetections(from request: VNRequest) {
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return
        }
        DispatchQueue.main.async {
            self.currentDetections = results
            self.updateOverlay()
        }
    }
    
    // MARK: – 更新／清除 overlay
    private func updateOverlay() {
        // 先清除所有子視圖
        overlay.subviews.forEach { $0.removeFromSuperview() }
        
        // 如果沒有偵測到物件，就結束
        guard !currentDetections.isEmpty else { return }
        
        // 反覆畫出所有偵測到的物件
        for det in currentDetections {
            // det.boundingBox 是歸一化座標 (0~1)，origin 在左下
            let rectNorm = det.boundingBox
            let w = overlay.bounds.width
            let h = overlay.bounds.height
            let rect = CGRect(
                x: rectNorm.minX * w,
                y: (1 - rectNorm.maxY) * h,
                width: rectNorm.width * w,
                height: rectNorm.height * h
            )
            
            // 畫邊界框
            let box = UIView(frame: rect)
            box.layer.borderColor = UIColor.red.cgColor
            box.layer.borderWidth = 2
            overlay.addSubview(box)
            
            // 取信心最高的 label
            let topLabel = det.labels.first!
            let label = UILabel(frame: CGRect(x: rect.minX, y: rect.minY - 18, width: 150, height: 18))
            label.text = "\(topLabel.identifier) \(String(format:"%.2f", topLabel.confidence))"
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .red
            overlay.addSubview(label)
        }
    }
}
