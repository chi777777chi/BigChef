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

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
            context.coordinator.useSceneDepth = true
        } else {
            context.coordinator.useSceneDepth = false
        }
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        let overlay = UIView(frame: arView.bounds)
        overlay.backgroundColor = .clear
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(overlay)

        context.coordinator.arView  = arView
        context.coordinator.overlay = overlay

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

        ObjectDetector.shared.configure(overlay: overlay)
        return arView
    }

    @MainActor
    func updateUIView(_ uiView: ARView, context: Context) {
        // 1) arType / arParameters 必須存在才啟動動畫
        guard let apiType   = stepModel.arType,
              let apiParams = stepModel.arParameters
        else { return }

        // 2) 同一步驟避免重建（用 step_number: Int）
        if context.coordinator.lastStepNumber == stepModel.step_number {
            return
        }

        // 3) 清場
        context.coordinator.lastStepNumber = stepModel.step_number
        context.coordinator.lastAnimation  = nil
        context.coordinator.resetDetectionState()
        ObjectDetector.shared.clear()
        uiView.scene.anchors.removeAll()

        // 4) 後端枚舉字串 → 前端 AnimationType（rawValue 必須一致）
        guard let animType = AnimationType(rawValue: apiType.rawValue) else { return }

        // 5) container 映射（若命名不同可在此做 mapping）
        let containerEnum: Container? = apiParams.container.flatMap { Container(rawValue: $0) }

        // 6) 參數轉換（Double → Float，Array<Double> → [Float]）
        let params = AnimationParams(
            coordinate:  apiParams.coordinate?.map { Float($0) },
            container:   containerEnum,
            ingredient:  apiParams.ingredient,
            color:       apiParams.color,
            time:        apiParams.time.map { Float($0) },
            temperature: apiParams.temperature.map { Float($0) },
            flameLevel:  apiParams.flameLevel
        )

        // 7) 建立與播放動畫（不再呼叫 AnimationManager）
        let animation = AnimationFactory.make(type: animType, params: params)
        context.coordinator.lastAnimation = animation

        context.coordinator.isDetectionActive = !animation.requiresContainerDetection ? true : context.coordinator.isDetectionActive
        context.coordinator.playAnimationLoop()
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, ARSessionDelegate {
        var useSceneDepth: Bool = false

        private var parent: CookingARView?
        weak var arView: ARView?
        weak var overlay: UIView?

        var lastStepNumber: Int?
        var lastAnimation: Animation?

        var isDetectionActive = false
        private var isAnimationPlaying = false
        var lastSmoothedPosition: SIMD3<Float>?

        private var playbackSubscription: Cancellable?
        private var staticRemovalWorkItem: DispatchWorkItem?
        var renderSubscription: Cancellable?

        init(_ parent: CookingARView) { self.parent = parent }

        func resetDetectionState() {
            isDetectionActive   = false
            isAnimationPlaying  = false
            playbackSubscription?.cancel()
            playbackSubscription    = nil
            staticRemovalWorkItem?.cancel()
            staticRemovalWorkItem   = nil
            lastSmoothedPosition    = nil
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard
                let animation = lastAnimation,
                animation.requiresContainerDetection,
                let container = animation.containerType,
                let arView    = arView
            else { return }

            ObjectDetector.shared.clear()

            ObjectDetector.shared.detectContainer(
                target: container,
                in: frame.capturedImage
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case let (rect, _, confidence)? where confidence > 0.7:
                        self.isDetectionActive = true

                        let center2D = CGPoint(x: rect.midX, y: rect.midY)

                        if self.useSceneDepth, let sceneDepth = frame.smoothedSceneDepth {
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

                            let intr = frame.camera.intrinsics
                            let fx = intr[0,0], fy = intr[1,1]
                            let cx = intr[2,0], cy = intr[2,1]
                            let xCam = (Float(center2D.x) - cx) * depth / fx
                            let yCam = (Float(center2D.y) - cy) * depth / fy
                            let camPos = SIMD4<Float>(xCam, yCam, depth, 1)
                            let world4 = frame.camera.transform * camPos
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
            guard
                !isAnimationPlaying,
                let arView    = arView,
                let animation = lastAnimation
            else { return }

            if !animation.requiresContainerDetection {
                isDetectionActive = true
            }
            guard isDetectionActive else { return }

            isAnimationPlaying = true
            playbackSubscription?.cancel()
            staticRemovalWorkItem?.cancel()

            let reuse = animation.requiresContainerDetection
            animation.play(on: arView, reuseAnchor: reuse)

            guard let anchor = animation.anchorEntity else { return }
            let modelEntity = anchor.children.first

            if let model = modelEntity, !model.availableAnimations.isEmpty {
                if animation.type == .putIntoContainer {
                    NotificationCenter.default.addObserver(
                        forName: Notification.Name("PutIntoContainerAnimationCompleted"),
                        object: nil, queue: .main
                    ) { [weak self] _ in
                        guard let self = self else { return }
                        self.isAnimationPlaying = false
                        if self.isDetectionActive { self.playAnimationLoop() }
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
    }
}

// 需要容器偵測的類型（沿用你的定義）
extension AnimationType {
    var requiresContainerDetection: Bool {
        switch self {
        case .putIntoContainer, .stir, .pourLiquid, .flipPan,
             .flip, .countdown, /*.temperature,*/ .flame,
             .sprinkle: /* .beatEgg:*/
            return true
        default:
            return false
        }
    }
}
