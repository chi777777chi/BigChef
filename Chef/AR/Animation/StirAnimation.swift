import Foundation
import simd
import RealityKit

/// 攪拌（Stir）動畫：在容器偵測後，在容器內部位置執行攪拌動作
class StirAnimation: Animation {
    private let container: Container
    private let model: Entity
    private var boundingBoxRect: CGRect?

    /// 簡易 LRUCache: 每個子類可維護自己的快取
    private static let modelCache = LRUCache<URL, Entity>(capacity: 10)

    init(container: Container,
         scale: Float = 1.0,
         isRepeat: Bool = true) {
        self.container = container
        // 快取或載入 USDZ 模型
        let url = Bundle.main.url(forResource: "stir", withExtension: "usdz")!
        if let cached = StirAnimation.modelCache[url] {
            model = cached
        } else {
            let loaded = try! Entity.load(contentsOf: url)
            StirAnimation.modelCache[url] = loaded
            model = loaded
        }
        super.init(type: .stir, scale: scale, isRepeat: isRepeat)
    }

    override var requiresContainerDetection: Bool { true }
    override var containerType: Container? { container }

    /// 當父類的 play 被呼叫時，自動注入到 Anchor 上並播放動畫
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        
        let instance = model.clone(recursive: true)
        instance.scale = SIMD3<Float>(repeating: scale)
        instance.position.x += 0.5
        instance.position.z -= 1
        instance.position.y -= 0.5
        anchor.addChild(instance)
        if let res = instance.availableAnimations.first {
            instance.playAnimation(res,
                                     transitionDuration: 0.2,
                                     startsPaused: false)
        }
    }

    /// 每次物件偵測框更新時記錄，實際定位由 Coordinator 處理
    override func updateBoundingBox(rect: CGRect) {
        boundingBoxRect = rect
    }
}
