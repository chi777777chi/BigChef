import Foundation
import simd
import RealityKit
import ARKit

/// 定義容器類型
enum Container: String, CaseIterable, Codable {
    case airFryer, bowl, microWaveOven, oven, pan, plate, riceCooker, soupPot
}

/// 食材掉入容器動畫
class PutIntoContainerAnimation: Animation {
    override var requiresContainerDetection: Bool { true }
    override var containerType: Container? { container }

    /// USDZ 實體快取
    private static let cache = LRUCache<URL, Entity>(capacity: 10)

    private let container: Container
    private let model: Entity
    private weak var arViewRef: ARView?

    /// 最後一次更新的容器底部位置
    private var _containerPosition: SIMD3<Float>?
    var containerPosition: SIMD3<Float>? { _containerPosition }

    /// 掉落持續時間
    private let dropDuration: TimeInterval = 2

    init(ingredientName: String,
         container: Container,
         scale: Float = 1.0,
         isRepeat: Bool = false) {
        // 載入模型或 fallback
        if let url = Bundle.main.url(forResource: ingredientName, withExtension: "usdz"),
           let cached = PutIntoContainerAnimation.cache[url] {
            model = cached
        } else if let url = Bundle.main.url(forResource: ingredientName, withExtension: "usdz") {
            do {
                let loaded = try Entity.load(contentsOf: url)
                PutIntoContainerAnimation.cache[url] = loaded
                model = loaded
            } catch {
                print("⚠️ 載入 \(ingredientName).usdz 失敗：\(error)，改用預設")
                let fallbackURL = Bundle.main.url(forResource: "ingredient", withExtension: "usdz")!
                model = (try? Entity.load(contentsOf: fallbackURL)) ?? ModelEntity()
            }
        } else if let fallbackURL = Bundle.main.url(forResource: "ingredient", withExtension: "usdz"),
                  let baseModel = try? Entity.load(contentsOf: fallbackURL) {
              // 1. 取得模型底部 Y 座標
              let bounds = baseModel.visualBounds(relativeTo: baseModel)
              let bottomY = bounds.min.y

              // 2. 建立文字 Mesh（食材名稱）
              let textMesh = MeshResource.generateText(
                  ingredientName,
                  extrusionDepth: 0.01,
                  font: .systemFont(ofSize: 10),
                  containerFrame: .zero,
                  alignment: .center,
                  lineBreakMode: .byWordWrapping
              )
              let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
              let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

              // 3. 把文字放在模型頂部（距底部 +5cm）
            textEntity.position = SIMD3<Float>(-0.5, bottomY + 2, 0)
              textEntity.scale = SIMD3<Float>(repeating: scale)

              // 4. 掛在 baseModel 上
              baseModel.addChild(textEntity)

              // 5. 指定為最終的 model
              model = baseModel
          }
          // ingredient.usdz 也不存在時，純文字 fallback
        else {
                let textMesh = MeshResource.generateText(
                    ingredientName,
                    extrusionDepth: 0.01,
                    font: .systemFont(ofSize: 20),
                    containerFrame: .zero,
                    alignment: .center,
                    lineBreakMode: .byWordWrapping
                )
                let mat = SimpleMaterial(color: .white, isMetallic: false)
                model = ModelEntity(mesh: textMesh, materials: [mat])
            }

        self.container = container
        super.init(type: .putIntoContainer, scale: scale, isRepeat: isRepeat)
    }

    /// 新增：掉落動畫輔助
    func drop(to targetPosition: SIMD3<Float>) {
        guard let anchor = anchorEntity else { return }
        // 直接移動 Anchor，所有子 Entity (模型和文字) 都會跟著
        var t = anchor.transform
        t.translation = targetPosition
        anchor.move(
            to: t,
            relativeTo: anchor.parent,
            duration: dropDuration,
            timingFunction: .easeIn
        )
    }
    /// 把模型加到 Anchor 並觸發掉落
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        arViewRef = arView
        let entity = model.clone(recursive: true)
        entity.scale = SIMD3<Float>(repeating: scale)
        anchor.addChild(entity)
        var start = anchor.transform.translation
        start.y += 0.2
        entity.position = start
        if let rawEnd = containerPosition {
                var endPos = rawEnd

                // 手動微調 endPos
                endPos.y -= 50

                drop(to: endPos)
            }
        // 完成後再度呼叫 drop(to:) 重播掉落
        NotificationCenter.default.addObserver(
            forName: Notification.Name("PutIntoContainerAnimationCompleted"),
            object: self,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let pos = self.containerPosition else { return }
            self.drop(to: pos)
        }

        // 動畫結束後通知（保留原有觸發）
        DispatchQueue.main.asyncAfter(deadline: .now() + dropDuration) { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default
                .post(name: .init("PutIntoContainerAnimationCompleted"),
                      object: self)
        }
    }    /// 更新 bounding box 時，同步計算框底世界座標
    override func updateBoundingBox(rect: CGRect) {
        guard let anchor = anchorEntity else { return }
        // 取得當前錨點世界座標
        var pos = anchor.transform.translation
        // 往下半個框高
        pos.y -= Float(rect.height) * scale * 0.5
        anchor.transform.translation = pos
        _containerPosition = pos
    }
}
