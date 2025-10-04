import Foundation
import simd
import RealityKit
import ARKit

/// 炙燒（Torch）動畫：不依賴容器與座標，預設放在鏡頭前方
class TorchAnimation: Animation {
    // 不需要容器偵測
    override var requiresContainerDetection: Bool { false }
    override var containerType: Container? { nil }

    private let torchModel: Entity
    private let ingredient: String?
    private let distance: Float

    init(ingredient: String? = nil,
         scale: Float,
         isRepeat: Bool = true,
         distance: Float = 0.5) {
        self.ingredient = ingredient
        self.distance = distance

        // 載入 torch.usdz
        guard let url = Bundle.main.url(forResource: "torch", withExtension: "usdz") else {
            fatalError("❌ 找不到 torch.usdz")
        }

        do {
            self.torchModel = try AnimationModelCache.entity(for: url)
        } catch {
            fatalError("❌ 無法載入 torch.usdz：\(error)")
        }

        super.init(type: .torch, scale: scale, isRepeat: isRepeat)
    }

    /// 加入 Anchor 並播放動畫（固定放在鏡頭前方）
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        let model = torchModel.clone(recursive: true)
        model.scale = SIMD3<Float>(repeating: scale)
        if let name = ingredient, !name.isEmpty {
            _ = ARText.addLabel(text: name, to: model)
        }
        anchor.position = SIMD3<Float>(0, -0.5, -distance)
        anchor.addChild(model)

        // 以相機為基準的錨點，確保距離可控；重用同一個 camera anchor，避免多重父層造成位置看似不變
        let cameraAnchor: AnchorEntity
        if let existing = arView.scene.findEntity(named: "TorchCameraAnchor") as? AnchorEntity {
            cameraAnchor = existing
        } else {
            let ca = AnchorEntity(.camera)
            ca.name = "TorchCameraAnchor"
            arView.scene.addAnchor(ca)
            cameraAnchor = ca
        }
        anchor.setParent(cameraAnchor)
        anchor.position = SIMD3<Float>(0, 0, -distance)

        // 播放動畫
        if let clip = model.availableAnimations.first {
            let resource = isRepeat ? clip.repeat(duration: .infinity) : clip
            model.playAnimation(resource, transitionDuration: 0.1, startsPaused: false)
        } else {
            print("⚠️ [TorchAnimation] USDZ 無可用動畫：torch")
        }
    }

    override func updateBoundingBox(rect: CGRect) {
        // no-op
    }
}
