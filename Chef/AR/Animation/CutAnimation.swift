import Foundation
import simd
import RealityKit
import ARKit

/// 切割動作動畫（顯示 ingredient 文字，並將模型放在鏡頭前方）
class CutAnimation: Animation {
    override var requiresContainerDetection: Bool { false }
    override var containerType: Container? { nil }

    /// 顯示的食材名稱（小寫英文字）
    private let ingredient: String

    /// 預載入的 USDZ 模型
    private let model: Entity

    /// 單一實例的節點參考（避免重複建立）
    private var rootAnchor: AnchorEntity?
    private var holder: Entity?
    private var modelInstance: Entity?
    private var labelInstance: ModelEntity?

    /// 是否跟隨鏡頭（true = 永遠在視野中）
    private var followCamera: Bool = true
    /// 與鏡頭距離（公尺）
    private var followDistance: Float = 0.35

    /// 初始化時載入模型與建立文字（保留原本的 scale / isRepeat 參數）
    /// - Parameters:
    ///   - ingredient: 要顯示的食材英文名稱（例如 "salmon"）
    ///   - scale: 縮放
    ///   - isRepeat: 是否重複播放（若 USDZ 內含動畫）
    init(ingredient: String, scale: Float = 1.0, isRepeat: Bool = false) {
        self.ingredient = ingredient.lowercased()

        // 從資源載入 USDZ
        let url = Bundle.main.url(forResource: "cut", withExtension: "usdz")!
        self.model = (try? AnimationModelCache.entity(for: url)) ?? ModelEntity()

        super.init(type: .cut, scale: scale, isRepeat: isRepeat)
    }

    /// 將模型加到 Anchor 並執行動畫
    /// - 位置策略：放在鏡頭前方約 0.35m，並讓文字位於模型上方一點
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        // 若已建立就直接重用，不再新增第二個
        rootAnchor?.removeFromParent()

        let parentAnchor: AnchorEntity
        if followCamera {
            parentAnchor = AnchorEntity(.camera)
        } else {
            parentAnchor = AnchorEntity(world: .zero)
        }
        self.anchorEntity = parentAnchor
        arView.scene.addAnchor(parentAnchor)
        self.rootAnchor = parentAnchor

        let holder = Entity()
        holder.position = SIMD3<Float>(0, 0, -followDistance)
        parentAnchor.addChild(holder)
        self.holder = holder

        let entity = model.clone(recursive: true)
        entity.scale = SIMD3<Float>(repeating: scale)
        holder.addChild(entity)
        self.modelInstance = entity

        labelInstance?.removeFromParent()
        if !ingredient.isEmpty {
            let label = ARText.addLabel(text: ingredient, to: entity, padding: 0.06)
            self.labelInstance = label
        }

        // 播放 USDZ 內建動畫（若存在）
        if let animation = entity.availableAnimations.first {
            let resource = isRepeat ? animation.repeat(duration: .infinity) : animation
            _ = entity.playAnimation(resource)
        }
    }

    /// 以世界座標移動唯一 cut 實例
    override func updatePosition(_ pos: SIMD3<Float>) {
        if followCamera {
            // 視為相機座標系下的偏移（保持在視野中）
            holder?.position = pos
        } else {
            // 世界座標下移動
            anchorEntity?.transform.translation = pos
        }
    }

    /// 調整跟隨距離（僅在 followCamera = true 時生效）
    func setFollowDistance(_ meters: Float) {
        followDistance = max(0.05, meters)
        if followCamera {
            holder?.position.z = -followDistance
        }
    }

    override func stop() {
        super.stop()
        rootAnchor?.removeFromParent()
        rootAnchor = nil
        holder = nil
        modelInstance = nil
        labelInstance = nil
    }
}
