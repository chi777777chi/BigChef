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

    private let container: Container
    private let model: Entity
    private weak var arViewRef: ARView?
    private var completionObserver: NSObjectProtocol?

    /// 最後一次更新的容器底部位置
    private var _containerPosition: SIMD3<Float>?
    var containerPosition: SIMD3<Float>? { _containerPosition }

    /// 掉落持續時間
    private let dropDuration: TimeInterval = 2

    init(ingredientName: String,
         container: Container,
         scale: Float = 1.0,
         isRepeat: Bool = false) {
        self.container = container
        self.model = PutIntoContainerAnimation.resolveModel(
            ingredientName: ingredientName,
            scale: scale
        )
        super.init(type: .putIntoContainer, scale: scale, isRepeat: isRepeat)
    }

    private static func resolveModel(ingredientName: String, scale: Float) -> Entity {
        if let url = Bundle.main.url(forResource: ingredientName, withExtension: "usdz") {
            do {
                return try AnimationModelCache.entity(for: url)
            } catch {
                print("⚠️ 載入 \(ingredientName).usdz 失敗：\(error)，改用預設")
            }
        }
        return makeFallbackModel(ingredientName: ingredientName, scale: scale)
    }

    private static func makeFallbackModel(ingredientName: String, scale: Float) -> Entity {
        if let fallbackURL = Bundle.main.url(forResource: "ingredient", withExtension: "usdz"),
           let template = try? AnimationModelCache.entity(for: fallbackURL) {
            let base = template.clone(recursive: true)
            let bounds = base.visualBounds(relativeTo: base)
            let bottomY = bounds.min.y

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
            textEntity.position = SIMD3<Float>(-0.5, bottomY + 2, 0)
            textEntity.scale = SIMD3<Float>(repeating: scale)
            base.addChild(textEntity)
            return base
        }

        let textMesh = MeshResource.generateText(
            ingredientName,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 20),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let mat = SimpleMaterial(color: .white, isMetallic: false)
        let entity = ModelEntity(mesh: textMesh, materials: [mat])
        entity.scale = SIMD3<Float>(repeating: scale)
        return entity
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

        // ✅ 創建相機錨點，讓模型跟隨相機移動
        let cameraAnchor: AnchorEntity
        if let existing = arView.scene.findEntity(named: "PutIntoContainerCameraAnchor") as? AnchorEntity {
            cameraAnchor = existing
        } else {
            let ca = AnchorEntity(.camera)
            ca.name = "PutIntoContainerCameraAnchor"
            arView.scene.addAnchor(ca)
            cameraAnchor = ca
        }

        // 將原本的 anchor 設為相機錨點的子物件
        anchor.setParent(cameraAnchor)

        let entity = model.clone(recursive: true)
        entity.scale = SIMD3<Float>(repeating: scale)

        // ✅ 添加 Billboard 組件讓模型始終面對相機
        entity.components.set(BillboardComponent())

        // 如果有文字子實體，也讓它面對相機
        for child in entity.children {
            child.components.set(BillboardComponent())
        }

        anchor.addChild(entity)

        // 設置初始位置（相機前方偏上）
        var start = SIMD3<Float>(0, 0.2, -0.5) // 相機前方 0.5 公尺，向上 0.2 公尺
        entity.position = start

        if let rawEnd = containerPosition {
            var endPos = rawEnd
            // 手動微調 endPos
            endPos.y -= 50
            drop(to: endPos)
        }

        // 完成後再度呼叫 drop(to:) 重播掉落
        if let observer = completionObserver {
            NotificationCenter.default.removeObserver(observer)
            completionObserver = nil
        }
        completionObserver = NotificationCenter.default.addObserver(
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

    deinit {
        if let observer = completionObserver {
            NotificationCenter.default.removeObserver(observer)
            completionObserver = nil
        }
    }
}
