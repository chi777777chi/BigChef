import Foundation
import simd
import RealityKit

class CountdownAnimation: Animation {
    /// 預先載入的倒數 USDZ 實體
    private let countdownUsdzEntity: Entity

    // 需要容器偵測
    override var requiresContainerDetection: Bool { true }
    override var containerType: Container? { container }

    private let timeValue: Float
    private let container: Container
    private let modelEntity: Entity

    init(timeValue: Float,
         container: Container,
         scale: Float = 0.1,
         isRepeat: Bool = false) {
        self.timeValue = timeValue
        self.container = container

        // 建構倒數文字的 3D 模型 - 顯示時間和單位
        let displayText: String
        if timeValue >= 60 {
            // 如果時間大於等於 60 秒，顯示為分鐘
            let minutes = Int(timeValue / 60)
            displayText = "\(minutes)分鐘"
        } else {
            // 小於 60 秒，顯示為秒
            let seconds = Int(timeValue)
            displayText = "\(seconds)秒"
        }

        let textMesh = MeshResource.generateText(
            displayText,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.3),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        var material = SimpleMaterial()
        material.color = .init(tint: .orange)
        self.modelEntity = ModelEntity(mesh: textMesh, materials: [material])

        // 預先載入倒數動畫模型
        guard let url = Bundle.main.url(forResource: "countdown", withExtension: "usdz") else {
            fatalError("❌ 找不到 countdown.usdz")
        }
        do {
            countdownUsdzEntity = try Entity.load(contentsOf: url)
        } catch {
            fatalError("❌ 無法載入 countdown.usdz：\(error)")
        }

        // 傳遞 type, scale, isRepeat 給父類
        super.init(type: .countdown, scale: scale, isRepeat: isRepeat)
    }

    // 在 Anchor 上加入文字模型並運行動畫
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        let entity = modelEntity.clone(recursive: true)
        entity.scale = SIMD3(repeating: scale)
        entity.position.y += 0.05
        anchor.addChild(entity)

        let usdzEntityClone = countdownUsdzEntity.clone(recursive: true)
        usdzEntityClone.scale = SIMD3(repeating: scale)
        anchor.addChild(usdzEntityClone)
        if let animationResource = usdzEntityClone.availableAnimations.first {
            usdzEntityClone.playAnimation(animationResource, transitionDuration: 0.0, startsPaused: false)
        }
    }

    // 根據邊界框更新世界座標
    override func updateBoundingBox(rect: CGRect) {
        let worldPos = worldPosition(from: rect,
                                     offsetY: Float(rect.height / 2 + 0.05))
        anchorEntity?.transform.translation = worldPos
    }

    
    /// 將 2D 匡轉為 3D 世界座標 (暫時使用 anchorEntity 位置加 Y 偏移)
    private func worldPosition(from rect: CGRect, offsetY: Float = 0) -> SIMD3<Float> {
        // 如果已有 anchorEntity，則在其基礎上位移，否則回傳原點偏移
        let base = anchorEntity?.transform.translation ?? SIMD3<Float>(0, 0, 0)
        return SIMD3<Float>(base.x,
                             base.y + offsetY,
                             base.z )
    }
}
