import SwiftUI
import RealityKit
import ARKit
import UIKit
import simd
import Combine
import CoreVideo

struct CookingARView: UIViewRepresentable {
    @Binding var step: String
    private let manager = AnimationManager()
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        
        // 啟動 AR Session
        let config = ARWorldTrackingConfiguration()
        // 判斷是否支援 LiDAR 深度圖
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
            context.coordinator.useSceneDepth = true
        } else {
            context.coordinator.useSceneDepth = false
        }
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        // 加 overlay 用來畫 2D bounding box
        let overlay = UIView(frame: arView.bounds)
        overlay.backgroundColor = .clear
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(overlay)
        
        context.coordinator.arView  = arView
        context.coordinator.overlay = overlay
        
        // 訂閱每幀渲染事件，使用當前 ARFrame 觸發物件偵測與更新位置
        context.coordinator.renderSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            guard let currentFrame = context.coordinator.arView?.session.currentFrame else { return }
            let coor = context.coordinator
            // 直接調用已有的 session(_:didUpdate:) 以復用偵測與定位邏輯
            coor.session(coor.arView!.session, didUpdate: currentFrame)
            // 只在需要容器偵測的動畫時，才用偵測結果覆寫 Anchor 位置
            if let anim = coor.lastAnimation, anim.requiresContainerDetection,
               let smoothed = coor.lastSmoothedPosition,
               let anchor = anim.anchorEntity {
                anchor.position = smoothed
            }
        }
        
        ObjectDetector.shared.configure(overlay: overlay)
        
        // 新增：將重用 boxLayer 加到 overlay
        // context.coordinator.overlay?.layer.addSublayer(context.coordinator.boxLayer)
        
        return arView
    }
    
    @MainActor
    func updateUIView(_ uiView: ARView, context: Context) {
        // 1. step 為空時不處理
        guard !step.isEmpty else { return }
        
        // 2. 同一步驟：避免取消正在進行的參數請求，直接略過重複更新
        if context.coordinator.lastStep == step {
            return
        }
        
        // 3. 新步驟：清場並重置(僅狀態，不取消每幀訂閱)
        context.coordinator.lastStep      = step
        context.coordinator.lastAnimation = nil
        context.coordinator.resetDetectionState()
        ObjectDetector.shared.clear()
        uiView.scene.anchors.removeAll()

        // 取消前一個尚未完成的參數請求
        context.coordinator.paramFetchTask?.cancel()

        // 取一份當下步驟快照，避免之後變動造成混淆
        let requestedStep = step

        context.coordinator.paramFetchTask = Task.detached(priority: .background) {
            // 後台執行 Gemini 參數取得
            guard let (type, params) = await self.manager.selectTypeAndParameters(
                for: requestedStep,
                from: uiView
            ) else { return }
            
            // 任務可能在期間被取消
            guard !Task.isCancelled else { return }

            // 切回主執行緒更新 UI（再次確認步驟一致）
            await MainActor.run {
                // 若在等待參數期間 step 已變更，或 lastStep 與我們要處理的步驟不同，直接丟棄本次結果
                guard context.coordinator.lastStep == requestedStep,
                      requestedStep == self.step else { return }
                
                let animation = AnimationFactory.make(type: type, params: params)

                context.coordinator.lastAnimation = animation
                // 立即顯示動畫物件，不用等物件偵測
                context.coordinator.isDetectionActive = true
                context.coordinator.playAnimationLoop()
                // 之後每幀透過物件偵測更新位置
                context.coordinator.paramFetchTask = nil
            }
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, ARSessionDelegate {
        /// 標記是否支援 LiDAR 深度圖
        var useSceneDepth: Bool = false
        
        private var parent: CookingARView?
        weak var arView: ARView?
        weak var overlay: UIView?
        
        var lastStep: String?
        var lastAnimation: Animation?
        
        /// 單一重用的 2D 偵測框 layer
        fileprivate let boxLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.systemRed.cgColor
            layer.fillColor   = UIColor.clear.cgColor
            layer.lineWidth   = 2
            layer.isHidden    = true
            return layer
        }()
        
        /// 目标持续在画面里的状态
        var isDetectionActive = false
        /// 是否正在播放動畫
        private var isAnimationPlaying = false
        /// 上一幀平滑後的位置
        var lastSmoothedPosition: SIMD3<Float>?
        
        /// 内建动画播放完成订阅
        private var playbackSubscription: Cancellable?
        /// 静态模型 1s 后移除任务
        private var staticRemovalWorkItem: DispatchWorkItem?
        /// 每帧渲染循环订阅
        var renderSubscription: Cancellable?
        /// Gemini 參數請求任務
        var paramFetchTask: Task<Void, Never>?
        
        init(_ parent: CookingARView) {
            self.parent = parent
        }
        
        /// 重置狀態：停止循環、取消動畫監聽與暫時性工作；保留每幀訂閱與網路任務
        func resetDetectionState() {
            isDetectionActive   = false
            isAnimationPlaying  = false
            playbackSubscription?.cancel()
            playbackSubscription    = nil
            staticRemovalWorkItem?.cancel()
            staticRemovalWorkItem   = nil
            // 保持場景更新訂閱常駐；避免在此取消，否則之後無法持續偵測/更新
            lastSmoothedPosition = nil
        }
        
        /// ARSession 每帧回调
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard
                let animation = lastAnimation,
                animation.requiresContainerDetection,
                let container = animation.containerType,
                //let overlay   = overlay,
                let arView    = arView
            else { return }
            
            // 清除舊的 2D 偵測框顯示
            ObjectDetector.shared.clear()
            // boxLayer.isHidden = true
            
            // 跑 2D 物件偵測
            ObjectDetector.shared.detectContainer(
                target: container,
                in: frame.capturedImage
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    // 只有置信度 > 0.7 才认为检测到
                    case let (rect, _, confidence)? where confidence > 0.7:
                        self.isDetectionActive = true
                        
                        // 更新重用的偵測框
                        // self.boxLayer.frame = overlay.bounds
                        // self.boxLayer.path  = UIBezierPath(rect: rect).cgPath
                        // self.boxLayer.isHidden = false
                        // 2. 将 2D 中心点发射 raycast，定位 3D 点
                        let center2D = CGPoint(x: rect.midX, y: rect.midY)
                        if self.useSceneDepth, let sceneDepth = frame.smoothedSceneDepth {
                            // 使用 LiDAR 深度圖反投影
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
                            // 反投影到相機座標系
                            let intr = frame.camera.intrinsics
                            let fx = intr[0,0], fy = intr[1,1]
                            let cx = intr[2,0], cy = intr[2,1]
                            let xCam = (Float(center2D.x) - cx) * depth / fx
                            let yCam = (Float(center2D.y) - cy) * depth / fy
                            let camPos = SIMD4<Float>(xCam, yCam, depth, 1)
                            let world4 = frame.camera.transform * camPos
                            let rawPos = SIMD3<Float>(world4.x, world4.y, world4.z)
                            let smoothedPos: SIMD3<Float>
                            if let last = self.lastSmoothedPosition {
                                smoothedPos = simd_mix(last, rawPos, SIMD3<Float>(repeating: 0.2))
                            } else {
                                smoothedPos = rawPos
                            }
                            self.lastSmoothedPosition = smoothedPos
                            animation.updatePosition(smoothedPos)
                            if let anchor = animation.anchorEntity {
                                anchor.position = smoothedPos
                            }
                        // 若要可简化，可使用 RealityKit 1.6+ 的 AnchorEntity(raycast:) API 直接创建锚点
                        } else {
                            // 使用多點採樣＋空間平均＋距離閾值過濾
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
                            // 计算平均位置
                            let sum = samples.reduce(SIMD3<Float>(repeating: 0), +)
                            let avgPos = sum / Float(samples.count)
                            // 距离阈值判断 (若跳变过大，则保留上一帧位置)
                            let maxDelta: Float = 0.2
                            let newPos: SIMD3<Float>
                            if let last = self.lastSmoothedPosition, simd_distance(last, avgPos) > maxDelta {
                                newPos = last
                            } else {
                                newPos = avgPos
                            }
                            // 时间维度滤波（线性内差）
                            let smoothed = self.lastSmoothedPosition.map { last in
                                simd_mix(last, newPos, SIMD3<Float>(repeating: 0.2))
                            } ?? newPos
                            self.lastSmoothedPosition = smoothed
                            animation.updatePosition(smoothed)
                            if let anchor = animation.anchorEntity {
                                anchor.position = smoothed
                            }
                        }
                        
                        // 确保 Anchor 随每帧新的 smoothedPosition 更新
                        if let smoothed = self.lastSmoothedPosition, let anchor = animation.anchorEntity {
                            anchor.position = smoothed
                        }
                        
                        // 3. 如果尚未播放，就启动循环播放
                        if !self.isAnimationPlaying {
                            self.playAnimationLoop()
                        }
                        
                    default:
                        // 无检测到或置信度低：停止继续检测，但等待当前播放完毕后再移除 Anchor
                        self.isDetectionActive = false
                        // self.boxLayer.isHidden = true
                    }
                }
            }
        }
        
        /// 檢測到後，循環播放：播放完 → 若偵測仍在 → 再播
        @MainActor
        func playAnimationLoop() {
            guard
                !isAnimationPlaying,
                let arView    = arView,
                let animation = lastAnimation
            else { return }
            // 若此動畫不需容器偵測，直接設為已啟用狀態
            if !animation.requiresContainerDetection {
                isDetectionActive = true
            }

            // 沒有偵測也不啟動
            guard isDetectionActive else { return }
            
            isAnimationPlaying = true
            playbackSubscription?.cancel()
            staticRemovalWorkItem?.cancel()
            
            // 播放／掛載 Anchor
            let reuse = animation.requiresContainerDetection
            animation.play(on: arView, reuseAnchor: reuse)
            
            guard let anchor = animation.anchorEntity else { return }
            let modelEntity = anchor.children.first
            
            if let model = modelEntity, !model.availableAnimations.isEmpty {
                if animation.type == .putIntoContainer {
                    NotificationCenter.default.addObserver(forName: Notification.Name("PutIntoContainerAnimationCompleted"), object: nil, queue: .main) { [weak self] _ in
                        guard let self = self else { return }
                        self.isAnimationPlaying = false
                        if self.isDetectionActive {
                            self.playAnimationLoop()
                        }
                    }
                    return
                }
                // 內建動畫：監聽 PlaybackCompleted
                playbackSubscription = arView.scene
                    .subscribe(to: AnimationEvents.PlaybackCompleted.self) { [weak self] event in
                        guard let self = self else { return }
                        if event.playbackController.entity == model {
                            self.isAnimationPlaying = false
                            if self.isDetectionActive {
                                self.playAnimationLoop()
                            }
                            self.playbackSubscription?.cancel()
                            self.playbackSubscription = nil
                        }
                    }
            } else {
                // 無內建動畫：顯示 1 秒後進入下一輪
                let work = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    self.isAnimationPlaying = false
                    if self.isDetectionActive {
                        self.playAnimationLoop()
                    }
                }
                staticRemovalWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
            }
        }
    }
}

// MARK: - 需要檢測容器的動畫類型
extension AnimationType {
    var requiresContainerDetection: Bool {
        switch self {
            case .putIntoContainer, .stir, .pourLiquid, .flipPan,
                 .flip, .countdown, /*.temperature,*/ .flame,
                 .sprinkle:/* .beatEgg:*/
                return true
            default:
                return false
        }
    }
}
