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
        print("🎭 [Animation] play() 開始，type=\(type), reuseAnchor=\(reuseAnchor)")

        // A. 若要重用，直接重新掛回 scene
        if reuseAnchor, let anchor = anchorEntity, anchor.isAnchored {
            print("♻️ [Animation] 重用現有 anchor")
            arView.scene.addAnchor(anchor)
            return
        }

        // B. 清理舊 Anchor（避免對已釋放實體再次 remove）
        if let old = anchorEntity, old.isAnchored {
            print("🧹 [Animation] 移除舊 anchor")
            old.removeFromParent()            // 或 arView.scene.removeAnchor(old)
        }
        anchorEntity = nil                    // 釋放舊指標

        // C. 建立新 Anchor
        print("🆕 [Animation] 創建新 AnchorEntity")
        let anchor = AnchorEntity(world: .zero)
        print("🎨 [Animation] 呼叫 applyAnimation(to: anchor, on: arView)")
        applyAnimation(to: anchor, on: arView)
        print("➕ [Animation] 將 anchor 添加到 scene")
        arView.scene.addAnchor(anchor)
        anchorEntity = anchor                 // 更新參考
        print("✅ [Animation] play() 完成，anchor 已添加到場景")
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

enum AnimationModelCache {
    private static var cache = LRUCache<URL, Entity>(capacity: 20)
    private static let lock = NSLock()

    static func entity(for url: URL) throws -> Entity {
        try entity(for: url) { try Entity.load(contentsOf: url) }
    }

    static func entity(for url: URL, loader: () throws -> Entity) rethrows -> Entity {
        try lock.withLock {
            if let cached = cache[url] {
                return cached
            }
            let loaded = try loader()
            cache[url] = loaded
            return loaded
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
