import Foundation
import simd
import RealityKit

class Animation {
    let type: AnimationType
    let scale: Float
    let isRepeat: Bool
    
    var anchorEntity: AnchorEntity?

    /// 是否需要容器偵測（子類覆寫）
    var requiresContainerDetection: Bool { false }
    /// 對應容器類型（子類覆寫）
    var containerType: Container? { nil }
    init(type: AnimationType, scale: Float = 1.0, isRepeat: Bool = false) {
        self.type = type
        self.scale = scale
        self.isRepeat = isRepeat
    }

    /// 在指定 ARView 上播放動畫
    @MainActor
    func play(on arView: ARView, reuseAnchor: Bool = false) {
        // A. 若要重用，直接重新掛回 scene
        if reuseAnchor, let anchor = anchorEntity, anchor.isAnchored {
            arView.scene.addAnchor(anchor)
            return
        }

        // B. 清理舊 Anchor（避免對已釋放實體再次 remove）
        if let old = anchorEntity, old.isAnchored {
            old.removeFromParent()            // 或 arView.scene.removeAnchor(old)
        }
        anchorEntity = nil                    // 釋放舊指標

        // C. 建立新 Anchor
        let anchor = AnchorEntity(world: .zero)
        applyAnimation(to: anchor, on: arView)
        arView.scene.addAnchor(anchor)
        anchorEntity = anchor                 // 更新參考
    }
    /// 子類應覆寫此方法：將模型與動畫加入 AnchorEntity
    func applyAnimation(to anchor: AnchorEntity, on arView: ARView) { }

    /// 由 2D→3D 映射回傳的絕對座標
    func updatePosition(_ position: SIMD3<Float>) {
        anchorEntity?.transform.translation = position
    }

    /// 需要同步 2D 偵測框時覆寫此方法
    func updateBoundingBox(rect: CGRect) { }
}

enum AnimationType: String, CaseIterable {
    case putIntoContainer
    case stir
    case pourLiquid
    case flipPan
    case countdown
    case temperature
    case flame
    case sprinkle
    case torch
    case cut
    case peel
    case flip
    case beatEgg
}
