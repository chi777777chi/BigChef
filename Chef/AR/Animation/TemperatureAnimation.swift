import Foundation
import simd
import RealityKit

class TemperatureAnimation: Animation {
    /// 預先載入的溫度 USDZ 實體（可選，如果沒有檔案會改用純文字顯示）
    private let temperatureUsdzEntity: Entity?

    // 需要容器偵測
    override var requiresContainerDetection: Bool { true }
    override var containerType: Container? { container }

    private let temperatureValue: Int
    private let container: Container
    init(container: Container,
         temperatureValue: Int,
         scale: Float = 0.05,
         isRepeat: Bool = true) {
        self.temperatureValue = temperatureValue
        self.container = container

        // 嘗試載入溫度動畫模型（若無此檔案，使用純文字即可）
        if let url = Bundle.main.url(forResource: "temperature", withExtension: "usdz") {
            temperatureUsdzEntity = try? AnimationModelCache.entity(for: url)
        } else {
            temperatureUsdzEntity = nil
        }

        // 傳遞 type, scale, isRepeat 給父類
        super.init(type: .temperature, scale: scale, isRepeat: isRepeat)
    }

    // 在 Anchor 上加入文字模型並運行動畫（若有 USDZ clip 也一併啟動）
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        let labelText = "\(temperatureValue)°C"

        if let usdz = temperatureUsdzEntity?.clone(recursive: true) {
            usdz.scale = SIMD3(repeating: scale)
            anchor.addChild(usdz)
            _ = ARText.addLabel(text: labelText, to: usdz, padding: 0.04, maxWidthRatio: 0.8, fontSize: 0.28)
            if let clip = usdz.availableAnimations.first {
                usdz.playAnimation(isRepeat ? clip.repeat(duration: .infinity) : clip,
                                   transitionDuration: 0.0,
                                   startsPaused: false)
            }
        } else {
            let holder = Entity()
            anchor.addChild(holder)
            let halfExtents = SIMD3<Float>(0.15, 0.05, 0.05)
            let bounds = BoundingBox(min: -halfExtents, max: halfExtents)
            _ = ARText.addLabel(text: labelText, to: holder, padding: 0.03, maxWidthRatio: 1.0, fontSize: 0.3, boundingOverride: bounds)
        }
    }

    // 根據邊界框更新世界座標（讓數值浮在容器上方）
    override func updateBoundingBox(rect: CGRect) {
        let worldPos = worldPosition(from: rect,
                                     offsetY: Float(rect.height / 2 + 0.05))
        anchorEntity?.transform.translation = worldPos
    }

    /// 將 2D 匡轉為 3D 世界座標（暫以 anchorEntity 為基準）
    private func worldPosition(from rect: CGRect, offsetY: Float = 0) -> SIMD3<Float> {
        let base = anchorEntity?.transform.translation ?? SIMD3<Float>(0, 0, 0)
        return SIMD3<Float>(base.x, base.y + offsetY, base.z)
    }
}
