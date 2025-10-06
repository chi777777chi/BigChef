import SwiftUI
import RealityKit
import ARKit
import UIKit
import simd
import Combine
import CoreVideo

struct CookingARView: UIViewRepresentable {
    /// 直接吃當前步驟（含 arType / arParameters）
    let stepModel: RecipeStep
    /// 共享的 ARSessionAdapter（用於手勢辨識）
    let sessionAdapter: ARSessionAdapter?

    func makeCoordinator() -> Coordinator {
        print("🆕 [CookingARView] makeCoordinator 被調用")
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> ARView {
        print("🆕 [CookingARView.makeUIView] 被調用 - stepModel.step_number=\(stepModel.step_number)")
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        if let adapter = sessionAdapter {
            // ✅ 使用共享的 ARSession
            arView.session = adapter.arSession
            context.coordinator.useSceneDepth = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)

            context.coordinator.sessionAdapter = adapter
            context.coordinator.ownsARSession = false

            // ✅ 註冊 Coordinator 到 MulticastDelegate
            adapter.addSessionDelegate(context.coordinator)
            // ✅ 註冊為手勢 delegate 以接收手勢狀態更新
            adapter.addGestureDelegate(context.coordinator)
        } else {
            // ⚠️ 備用方案：創建獨立 ARSession
            let config = ARWorldTrackingConfiguration()
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                config.frameSemantics.insert(.sceneDepth)
                context.coordinator.useSceneDepth = true
            } else {
                context.coordinator.useSceneDepth = false
            }
            arView.session.run(config)
            arView.session.delegate = context.coordinator
            context.coordinator.sessionAdapter = nil
            context.coordinator.ownsARSession = true
        }

        let overlay = UIView(frame: arView.bounds)
        overlay.backgroundColor = .clear
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(overlay)

        context.coordinator.arView  = arView
        context.coordinator.overlay = overlay

        if sessionAdapter == nil {
            context.coordinator.renderSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
                guard let currentFrame = context.coordinator.arView?.session.currentFrame else { return }
                let coor = context.coordinator
                coor.session(coor.arView!.session, didUpdate: currentFrame)

                if let anim = coor.lastAnimation,
                   anim.requiresContainerDetection,
                   let smoothed = coor.lastSmoothedPosition,
                   let anchor = anim.anchorEntity {
                    anchor.position = smoothed
                }
            }
        } else {
            context.coordinator.renderSubscription = nil
        }

        ObjectDetector.shared.configure(overlay: overlay)
        return arView
    }

    @MainActor
    func updateUIView(_ uiView: ARView, context: Context) {
        let stepNumber = stepModel.step_number
        print("📱 [CookingARView.updateUIView] 被調用 - stepModel.step_number=\(stepNumber), lastStepNumber=\(context.coordinator.lastStepNumber ?? -1)")

        // 1) arType / arParameters 必須存在才啟動動畫
        guard let apiType   = stepModel.arType,
              let apiParams = stepModel.arParameters
        else {
            print("⚠️ [CookingARView] 步驟 \(stepNumber) 無 AR 動畫資料")
            return
        }

        // 2) 同一步驟避免重建（用 step_number: Int）
        print("🔍 [CookingARView.updateUIView] 檢查是否需要更新")
        if let lastStep = context.coordinator.lastStepNumber, lastStep == stepNumber {
            print("⏭️ [CookingARView.updateUIView] 步驟相同（\(stepNumber)），跳過更新")
            return
        }
        print("🔄 [CookingARView.updateUIView] 步驟改變: \(context.coordinator.lastStepNumber ?? -1) -> \(stepNumber)")

        // 4) 後端枚舉字串 → 前端 AnimationType（rawValue 必須一致）
        guard let animType = AnimationType(rawValue: apiType.rawValue) else {
            print("❌ [CookingARView] 不支援的動畫類型：\(apiType.rawValue)")
            return
        }

        func buildEntry(from source: ARAnimationParams) -> (AnimationParams, String, String) {
            let containerEnum: Container? = source.container.flatMap { Container(rawValue: $0) }
            let converted = AnimationParams(
                coordinate:  source.coordinate?.map { Float($0) },
                container:   containerEnum,
                ingredient:  source.ingredient,
                color:       source.color,
                time:        source.time.map { Float($0) },
                temperature: source.temperature.map { Float($0) },
                flameLevel:  source.flameLevel
            )

            var details: [String] = []
            details.append("container=\(source.container ?? "nil")")
            details.append("ingredient=\(source.ingredient ?? "nil")")
            if let coordinate = source.coordinate {
                let coords = coordinate.map { String(format: "%.2f", $0) }.joined(separator: ",")
                details.append("coordinate=[\(coords)]")
            }
            if let color = source.color { details.append("color=\(color)") }
            if let time = source.time { details.append("time=\(String(format: "%.1f", time))") }
            if let temperature = source.temperature { details.append("temperature=\(String(format: "%.1f", temperature))") }
            if let flame = source.flameLevel { details.append("flame=\(flame)") }
            let summary = details.joined(separator: ", ")

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let paramsJSON = (try? encoder.encode(source)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

            return (converted, summary, paramsJSON)
        }

        let entry: (params: AnimationParams, summary: String, json: String)
        if let cached = context.coordinator.paramsCache[stepNumber] {
            entry = cached
        } else {
            let built = buildEntry(from: apiParams)
            context.coordinator.paramsCache[stepNumber] = built
            entry = built
        }

        print("🔁 [CookingARView] Step \(stepNumber) arType=\(apiType.rawValue), arParameters=\(entry.json)")
        print("▶️ [CookingARView] 步驟 \(stepNumber) → \(animType.rawValue) (\(entry.summary))")

        // 3) 清場
        print("🧹 [CookingARView.updateUIView] 開始清理舊動畫...")
        context.coordinator.lastStepNumber = stepNumber
        context.coordinator.cleanupCurrentAnimation()
        context.coordinator.lastAnimation  = nil
        context.coordinator.resetDetectionState()
        ObjectDetector.shared.clear()
        print("✅ [CookingARView.updateUIView] 清理完成")

        // 7) 建立與播放動畫（不再呼叫 AnimationManager）
        print("🎬 [CookingARView.updateUIView] 創建新動畫: \(animType.rawValue)")
        let animation = AnimationFactory.make(type: animType, params: entry.params)
        context.coordinator.lastAnimation = animation
        print("📦 [CookingARView.updateUIView] animation.requiresContainerDetection=\(animation.requiresContainerDetection)")

        // ✅ 修正：對於不需要容器偵測的動畫，直接設為 true；需要容器偵測的，也設為 true 讓偵測流程啟動
        context.coordinator.isDetectionActive = true
        print("🔓 [CookingARView.updateUIView] isDetectionActive 設為 true")

        print("▶️ [CookingARView.updateUIView] 呼叫 playAnimationLoop()")
        context.coordinator.playAnimationLoop()
        print("✅ [CookingARView.updateUIView] updateUIView 完成")
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        print("🗑️ [CookingARView.dismantleUIView] 開始清理 - step=\(coordinator.lastStepNumber ?? -1)")

        if let adapter = coordinator.sessionAdapter {
            adapter.removeSessionDelegate(coordinator)
            adapter.removeGestureDelegate(coordinator)
            coordinator.sessionAdapter = nil
        } else if coordinator.ownsARSession {
            uiView.session.pause()
            uiView.session.delegate = nil
        }

        ObjectDetector.shared.clear()
        coordinator.teardown()
        coordinator.ownsARSession = false

        print("✅ [CookingARView.dismantleUIView] 清理完成")
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, ARSessionDelegate, ARGestureDelegate {
        var useSceneDepth: Bool = false

        weak var arView: ARView?
        weak var overlay: UIView?
        weak var sessionAdapter: ARSessionAdapter?
        var ownsARSession = false

        var lastStepNumber: Int?
        var lastAnimation: Animation?

        var isDetectionActive = false
        private var isAnimationPlaying = false
        var lastSmoothedPosition: SIMD3<Float>?

        private var playbackSubscription: Cancellable?
        private var staticRemovalWorkItem: DispatchWorkItem?
        var renderSubscription: Cancellable?
        private var containerCompletionObserver: NSObjectProtocol?
        var paramsCache: [Int: (params: AnimationParams, summary: String, json: String)] = [:]

        init(_ parent: CookingARView) {
            super.init()
        }

        func resetDetectionState() {
            isDetectionActive   = false
            isAnimationPlaying  = false
            playbackSubscription?.cancel()
            playbackSubscription    = nil
            staticRemovalWorkItem?.cancel()
            staticRemovalWorkItem   = nil
            lastSmoothedPosition    = nil
            if let observer = containerCompletionObserver {
                NotificationCenter.default.removeObserver(observer)
                containerCompletionObserver = nil
            }
        }

        func teardown() {
            print("🧹 [Coordinator.teardown] 開始...")
            resetDetectionState()
            renderSubscription?.cancel()
            renderSubscription = nil
            cleanupCurrentAnimation()
            overlay?.removeFromSuperview()
            arView = nil
            overlay = nil
            lastAnimation = nil
            paramsCache.removeAll()
            print("✅ [Coordinator.teardown] 完成")
        }

        func cleanupCurrentAnimation() {
            if let animation = lastAnimation {
                print("🛑 [Coordinator.cleanupCurrentAnimation] 停止動畫: \(animation.type.rawValue)")
                Task { @MainActor in animation.stop() }
            }
            lastAnimation = nil
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // 每 60 幀打印一次診斷
            let frameID = Int(frame.timestamp * 60) % 60
            if frameID == 0 {
                print("📸 [Coordinator.session] didUpdate frame - lastAnimation=\(lastAnimation != nil), requiresContainerDetection=\(lastAnimation?.requiresContainerDetection ?? false)")
            }

            guard
                let animation = lastAnimation,
                animation.requiresContainerDetection,
                let container = animation.containerType,
                let arView    = arView
            else {
                if frameID == 0 && lastAnimation != nil && !(lastAnimation?.requiresContainerDetection ?? true) {
                    print("⏭️ [Coordinator.session] 動畫不需要容器偵測，跳過")
                }
                return
            }

            ObjectDetector.shared.clear()

            // ✅ 提取需要的數據，避免在閉包中保留 frame
            let capturedImage = frame.capturedImage
            let cameraTransform = frame.camera.transform
            let cameraIntrinsics = frame.camera.intrinsics
            let smoothedSceneDepth = frame.smoothedSceneDepth
            let useDepth = self.useSceneDepth

            ObjectDetector.shared.detectContainer(
                target: container,
                in: capturedImage
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case let (rect, _, confidence)? where confidence > 0.7:
                        self.isDetectionActive = true

                        let center2D = CGPoint(x: rect.midX, y: rect.midY)

                        if useDepth, let sceneDepth = smoothedSceneDepth {
                            let depthMap = sceneDepth.depthMap
                            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
                            let width = CVPixelBufferGetWidth(depthMap)
                            let height = CVPixelBufferGetHeight(depthMap)
                            let x = min(max(Int(center2D.x), 0), width - 1)
                            let y = min(max(Int(center2D.y), 0), height - 1)
                            let rowBytes = CVPixelBufferGetBytesPerRow(depthMap)
                            let base = CVPixelBufferGetBaseAddress(depthMap)!
                            let ptr = base.advanced(by: y * rowBytes).assumingMemoryBound(to: Float32.self)
                            let depth = ptr[x]
                            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)

                            let fx = cameraIntrinsics[0,0], fy = cameraIntrinsics[1,1]
                            let cx = cameraIntrinsics[2,0], cy = cameraIntrinsics[2,1]
                            let xCam = (Float(center2D.x) - cx) * depth / fx
                            let yCam = (Float(center2D.y) - cy) * depth / fy
                            let camPos = SIMD4<Float>(xCam, yCam, depth, 1)
                            let world4 = cameraTransform * camPos
                            let rawPos = SIMD3<Float>(world4.x, world4.y, world4.z)
                            let smoothedPos: SIMD3<Float> = {
                                if let last = self.lastSmoothedPosition {
                                    return simd_mix(last, rawPos, SIMD3<Float>(repeating: 0.2))
                                } else {
                                    return rawPos
                                }
                            }()
                            self.lastSmoothedPosition = smoothedPos
                            animation.updatePosition(smoothedPos)
                            if let anchor = animation.anchorEntity { anchor.position = smoothedPos }
                        } else {
                            let offsets: [CGPoint] = [
                                .zero,
                                CGPoint(x: +10, y: 0), CGPoint(x: -10, y: 0),
                                CGPoint(x: 0, y: +10), CGPoint(x: 0, y: -10),
                                CGPoint(x: +10, y: +10), CGPoint(x: +10, y: -10),
                                CGPoint(x: -10, y: +10), CGPoint(x: -10, y: -10)
                            ]
                            var samples = [SIMD3<Float>]()
                            for off in offsets {
                                let p = CGPoint(x: center2D.x + off.x, y: center2D.y + off.y)
                                if let hit = arView.hitTest(p, types: [.featurePoint]).first {
                                    let c = hit.worldTransform.columns.3
                                    samples.append(SIMD3<Float>(c.x, c.y, c.z))
                                }
                            }
                            guard !samples.isEmpty else { break }
                            let sum = samples.reduce(SIMD3<Float>(repeating: 0), +)
                            let avgPos = sum / Float(samples.count)

                            let maxDelta: Float = 0.2
                            let newPos: SIMD3<Float>
                            if let last = self.lastSmoothedPosition, simd_distance(last, avgPos) > maxDelta {
                                newPos = last
                            } else {
                                newPos = avgPos
                            }
                            let smoothed = self.lastSmoothedPosition.map { last in
                                simd_mix(last, newPos, SIMD3<Float>(repeating: 0.2))
                            } ?? newPos
                            self.lastSmoothedPosition = smoothed
                            animation.updatePosition(smoothed)
                            if let anchor = animation.anchorEntity { anchor.position = smoothed }
                        }

                        if !self.isAnimationPlaying { self.playAnimationLoop() }

                    default:
                        self.isDetectionActive = false
                    }
                }
            }
        }

        @MainActor
        func playAnimationLoop() {
            print("🎮 [Coordinator.playAnimationLoop] 被調用")
            print("   - isAnimationPlaying: \(isAnimationPlaying)")
            print("   - arView: \(arView != nil)")
            print("   - lastAnimation: \(lastAnimation != nil)")
            print("   - isDetectionActive: \(isDetectionActive)")

            guard
                !isAnimationPlaying,
                let arView    = arView,
                let animation = lastAnimation
            else {
                print("❌ [Coordinator.playAnimationLoop] Guard 失敗，無法播放")
                return
            }

            if !animation.requiresContainerDetection {
                isDetectionActive = true
                print("✅ [Coordinator.playAnimationLoop] 不需容器偵測，isDetectionActive 設為 true")
            }

            guard isDetectionActive else {
                print("⚠️ [Coordinator.playAnimationLoop] isDetectionActive=false，等待偵測...")
                return
            }

            print("▶️ [Coordinator.playAnimationLoop] 開始播放動畫")
            isAnimationPlaying = true
            playbackSubscription?.cancel()
            staticRemovalWorkItem?.cancel()

            let reuse = animation.requiresContainerDetection
            print("🎬 [Coordinator.playAnimationLoop] animation.play(reuseAnchor: \(reuse))")
            animation.play(on: arView, reuseAnchor: reuse)
            print("✅ [Coordinator.playAnimationLoop] animation.play 完成")

            guard let anchor = animation.anchorEntity else { return }
            let modelEntity = anchor.children.first

            if let model = modelEntity, !model.availableAnimations.isEmpty {
                if animation.type == .putIntoContainer {
                    if let observer = containerCompletionObserver {
                        NotificationCenter.default.removeObserver(observer)
                        containerCompletionObserver = nil
                    }
                    containerCompletionObserver = NotificationCenter.default.addObserver(
                        forName: Notification.Name("PutIntoContainerAnimationCompleted"),
                        object: nil, queue: .main
                    ) { [weak self] _ in
                        guard let self = self else { return }
                        self.isAnimationPlaying = false
                        if self.isDetectionActive { self.playAnimationLoop() }
                        if let observer = self.containerCompletionObserver {
                            NotificationCenter.default.removeObserver(observer)
                            self.containerCompletionObserver = nil
                        }
                    }
                    return
                }

                playbackSubscription = arView.scene
                    .subscribe(to: AnimationEvents.PlaybackCompleted.self) { [weak self] event in
                        guard let self = self else { return }
                        if event.playbackController.entity == model {
                            self.isAnimationPlaying = false
                            if self.isDetectionActive { self.playAnimationLoop() }
                            self.playbackSubscription?.cancel()
                            self.playbackSubscription = nil
                        }
                    }
            } else {
                let work = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    self.isAnimationPlaying = false
                    if self.isDetectionActive { self.playAnimationLoop() }
                }
                staticRemovalWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
            }
        }

        // MARK: - ARGestureDelegate Implementation
        func didRecognizeGesture(_ gestureType: GestureType) {
        }

        func gestureStateDidChange(_ state: GestureState) {
        }

        func hoverProgressDidUpdate(_ progress: Float) {
            // 進度更新由 CookViewController 的 UI 處理
        }

        func palmStateDidChange(_ palmState: PalmState) {
            // 手掌狀態變化的處理
        }

        func gestureRecognitionDidFail(with error: GestureRecognitionError) {
            print("❌ [CookingARView.Coordinator] 手勢辨識錯誤: \(error.localizedDescription)")
        }
    }
}

// 需要容器偵測的類型（沿用你的定義）
extension AnimationType {
    var requiresContainerDetection: Bool {
        switch self {
        case .putIntoContainer,
             .stir,
             .pourLiquid,
             .flipPan,
             .flip,
             .countdown,
             .temperature,
             .flame,
             .sprinkle,
             .beatEgg:
            return true
        default:
            return false
        }
    }
}
