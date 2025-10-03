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
        print("🔥 [TorchAnimation] 初始化 TorchAnimation")
        print("🔥 [TorchAnimation] 參數：ingredient=\(ingredient ?? "nil"), scale=\(scale), distance=\(distance)")

        self.ingredient = ingredient
        self.distance = distance

        // 載入 torch.usdz
        print("🔥 [TorchAnimation] 嘗試載入 torch.usdz")
        guard let url = Bundle.main.url(forResource: "torch", withExtension: "usdz") else {
            print("❌ [TorchAnimation] 找不到 torch.usdz 檔案")
            fatalError("❌ 找不到 torch.usdz")
        }
        print("✅ [TorchAnimation] 找到 torch.usdz：\(url.path)")

        do {
            self.torchModel = try Entity.load(contentsOf: url)
            print("✅ [TorchAnimation] torch.usdz 載入成功")
        } catch {
            print("❌ [TorchAnimation] 無法載入 torch.usdz：\(error)")
            fatalError("❌ 無法載入 torch.usdz：\(error)")
        }

        super.init(type: .torch, scale: scale, isRepeat: isRepeat)
        print("✅ [TorchAnimation] 初始化完成")
    }

    /// 加入 Anchor 並播放動畫（固定放在鏡頭前方）
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        print("🔥 [TorchAnimation] applyAnimation 開始")
        print("🔥 [TorchAnimation] ARView scene anchors 數量：\(arView.scene.anchors.count)")

        let model = torchModel.clone(recursive: true)
        model.scale = SIMD3<Float>(repeating: scale)
        anchor.position = SIMD3<Float>(0, -0.5, -distance)
        anchor.addChild(model)
        print("🔥 [TorchAnimation] 模型已添加到 anchor，scale=\(scale), initial position=\(anchor.position)")

        // 以相機為基準的錨點，確保距離可控；重用同一個 camera anchor，避免多重父層造成位置看似不變
        let cameraAnchor: AnchorEntity
        if let existing = arView.scene.findEntity(named: "TorchCameraAnchor") as? AnchorEntity {
            print("🔥 [TorchAnimation] 重用現有的 TorchCameraAnchor")
            cameraAnchor = existing
        } else {
            print("🔥 [TorchAnimation] 創建新的 TorchCameraAnchor")
            let ca = AnchorEntity(.camera)
            ca.name = "TorchCameraAnchor"
            arView.scene.addAnchor(ca)
            cameraAnchor = ca
        }
        anchor.setParent(cameraAnchor)
        anchor.position = SIMD3<Float>(0, 0, -distance)
        print("🔥 [TorchAnimation] anchor 已設置為相機子物件，最終 position=\(anchor.position), distance=\(distance)")

        // 播放動畫
        print("🔥 [TorchAnimation] 檢查可用動畫數量：\(model.availableAnimations.count)")
        if let clip = model.availableAnimations.first {
            print("🔥 [TorchAnimation] 找到動畫 clip，開始播放（isRepeat=\(isRepeat)）")
            let resource = isRepeat ? clip.repeat(duration: .infinity) : clip
            model.playAnimation(resource, transitionDuration: 0.1, startsPaused: false)
            print("✅ [TorchAnimation] 動畫播放指令已發送")
        } else {
            print("⚠️ [TorchAnimation] USDZ 無可用動畫：torch")
        }

        print("✅ [TorchAnimation] applyAnimation 完成")
    }

    override func updateBoundingBox(rect: CGRect) {
        // no-op
    }
}
