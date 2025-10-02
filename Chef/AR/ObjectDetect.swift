import UIKit
import Vision
import CoreML
import ARKit

/// 單例，用於 2D 物件偵測並繪製在 overlayView 上
class ObjectDetector {
    static let shared = ObjectDetector()

    private weak var overlayView: UIView?
    private var boxLayers = [CAShapeLayer]()
    private var textLayers = [CATextLayer]()
    private let vnModel: VNCoreMLModel

    private init() {
        do {
            let coreMLModel = try CookDetect(configuration: MLModelConfiguration()).model
            vnModel = try VNCoreMLModel(for: coreMLModel)
        } catch {
            fatalError("❌ 無法載入 CookDetect 模型：\(error)")
        }
    }

    /// 設定用於繪製偵測結果的 Overlay
    func configure(overlay: UIView) {
        overlayView = overlay
    }

    /// 清除所有舊的繪製 Layer
    func clear() {
        boxLayers.forEach { $0.removeFromSuperlayer() }
        textLayers.forEach { $0.removeFromSuperlayer() }
        boxLayers.removeAll()
        textLayers.removeAll()
    }

    /// 偵測指定容器，回傳 (boundingRect, label, confidence) 或 nil
    func detectContainer(target container: Container,
                         in pixelBuffer: CVPixelBuffer,
                         completion: @escaping ((CGRect, String, Float)?) -> Void)
    {
        let request = VNCoreMLRequest(model: vnModel) { [weak self] request, error in
            guard let self = self else { completion(nil); return }
            if let error = error {
                print("🛑 VNCoreMLRequest 錯誤：\(error)")
                completion(nil)
                return
            }

            // 只取第一個符合 container label 的偵測結果
            let observations = (request.results as? [VNRecognizedObjectObservation]) ?? []
            for obs in observations {
                guard let top = obs.labels.first,
                      top.identifier == container.rawValue,
                      let overlay = self.overlayView
                else { continue }

                let box = obs.boundingBox

                DispatchQueue.main.async {
                    guard let overlay = self.overlayView else { completion(nil); return }
                    self.clear()
                    // 以主執行緒安全存取 overlay.bounds 並換算 viewRect
                    let viewW = overlay.bounds.width
                    let viewH = overlay.bounds.height
                    let x = box.minX * viewW
                    let w = box.width * viewW
                    let y = (1 - box.maxY) * viewH  // Vision 座標轉 UIKit
                    let h = box.height * viewH
                    let viewRect = CGRect(x: x, y: y, width: w, height: h)
                    
                    // （保持繪製程式碼為註解，僅計算 rect）
                    /*
                    // 1. Bounding box（若未來要顯示可解除註解）
                    // ...
                    // 2. Label + confidence（若未來要顯示可解除註解）
                    // ...
                    */
                    
                    // 回傳畫在 overlay 座標系中的矩形
                    completion((viewRect, top.identifier, top.confidence))
                }
                return
            }

            // 沒偵測到
            completion(nil)
        }

        // 記得帶上 orientation 才不會因為畫面旋轉導致框不對齊
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,  // 或根據你的 ARView 畫面方向調整
            options: [:]
        )
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("🛑 VNImageRequestHandler 錯誤：\(error)")
                completion(nil)
                
            }
        }
    }
}
