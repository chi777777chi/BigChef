import Foundation
import simd
import RealityKit
import UIKit
import ARKit

/// 倒液體動畫
class PourLiquidAnimation: Animation {
    override var requiresContainerDetection: Bool { true }
    override var containerType: Container? { container }

    private let container: Container
    private let ingredient: String?
    private let color: UIColor
    private let model: Entity
    private weak var arViewRef: ARView?

    init(container: Container,
         ingredient: String? = nil,
         color: UIColor = .white,
         scale: Float = 1.0,
         isRepeat: Bool = false) {
        self.container = container
        self.ingredient = ingredient
        self.color = color
        if let url = Bundle.main.url(forResource: "pourLiquid", withExtension: "usdz"),
           let template = try? AnimationModelCache.entity(for: url) {
            self.model = template
        } else {
            self.model = ModelEntity()
        }
        super.init(type: .pourLiquid, scale: scale, isRepeat: isRepeat)
    }

    /// 將模型加入 Anchor 並播放動畫
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        self.arViewRef = arView
        let entity = model.clone(recursive: true)
        if let me = entity as? ModelEntity {
            me.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
        }
        entity.scale = SIMD3<Float>(repeating: scale)
        anchor.addChild(entity)
        let labelText: String
        if let ingredient, !ingredient.isEmpty {
            labelText = ingredient
        } else {
            labelText = container.rawValue
        }

        if !labelText.isEmpty {
            _ = ARText.addLabel(text: labelText, to: entity)
        }
        if let anim = entity.availableAnimations.first {
            let resource = isRepeat
                ? anim.repeat(duration: .infinity)
                : anim
            _ = entity.playAnimation(resource)
        } else {
            print("⚠️ USDZ 無可用動畫：pourLiquid")
        }
    }

    /// 更新位置：在容器框上方
    override func updateBoundingBox(rect: CGRect) {
        guard let anchor = anchorEntity else { return }
        var newPos = anchor.transform.translation
        newPos.y += 0.1
        newPos.y += Float(rect.height) * scale * 0.5 + 0.05
        newPos.z -= 0.2
        anchor.transform.translation = newPos
    }
}
