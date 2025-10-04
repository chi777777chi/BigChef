import Foundation
import simd
import RealityKit
import ARKit

/// 炙皮（Peel）動畫：與 Torch 相同風格，固定放在鏡頭前方
class PeelAnimation: Animation {
    // 不需要容器偵測
    override var requiresContainerDetection: Bool { false }
    override var containerType: Container? { nil }

    private let peelModel: Entity
    private let ingredient: String?
    private let distance: Float

    init(ingredient: String? = nil,
         scale: Float,
         isRepeat: Bool = true,
         distance: Float = 0.5) {
        self.ingredient = ingredient?.lowercased()
        self.distance = distance

        // 載入 peel.usdz
        guard let url = Bundle.main.url(forResource: "peel", withExtension: "usdz") else {
            fatalError("❌ 找不到 peel.usdz")
        }
        do {
            self.peelModel = try AnimationModelCache.entity(for: url)
        } catch {
            fatalError("❌ 無法載入 peel.usdz：\(error)")
        }

        super.init(type: .peel, scale: scale, isRepeat: isRepeat)
    }

    /// 加入 Anchor 並播放動畫（固定放在鏡頭前方，與 Torch 相同流程）
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        // 建立模型
        let model = peelModel.clone(recursive: true)
        model.scale = SIMD3<Float>(repeating: scale)
        anchor.addChild(model)

        if let ingredient = ingredient {
            _ = ARText.addLabel(text: ingredient, to: model, padding: 0.04)
        }

        // 以相機為基準的錨點；重用同一個 camera anchor
        let cameraAnchor: AnchorEntity
        if let existing = arView.scene.findEntity(named: "PeelCameraAnchor") as? AnchorEntity {
            cameraAnchor = existing
        } else {
            let ca = AnchorEntity(.camera)
            ca.name = "PeelCameraAnchor"
            arView.scene.addAnchor(ca)
            cameraAnchor = ca
        }

        // 把外部傳入的 anchor 掛到 camera anchor 底下，並設定距離
        anchor.setParent(cameraAnchor)
        anchor.position = SIMD3<Float>(0, 0, -distance)

        // 播放 USDZ 內建動畫（若存在）
        if let clip = model.availableAnimations.first {
            let resource = isRepeat ? clip.repeat(duration: .infinity) : clip
            model.playAnimation(resource, transitionDuration: 0.1, startsPaused: false)
        } else {
            print("⚠️ USDZ 無可用動畫：peel")
        }
    }

    override func updateBoundingBox(rect: CGRect) {
        // no-op
    }
}
