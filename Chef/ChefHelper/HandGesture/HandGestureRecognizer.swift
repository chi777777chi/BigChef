//
//  HandGestureRecognizer.swift
//  Hand detection operating system
//
//  Created by AI Assistant on 2025/9/15.
//

import Foundation
import Vision
import CoreGraphics
import Combine

// MARK: - 手勢辨識引擎
class HandGestureRecognizer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentState: GestureState = .idle
    @Published var palmState: PalmState?
    @Published var hoverProgress: Float = 0.0
    @Published var lastGestureResult: GestureResult?
    @Published var isEnabled: Bool = true
    
    // 手掌離開螢幕的重置機制
    private var requiresHandReset: Bool = false
    private var lastHandDetectionTime: Date = Date()
    private var triggeredDirections: Set<MotionDirection> = []  // 防止重複觸發手勢（按方向追蹤）
    
    // MARK: - Private Properties
    weak var delegate: HandGestureDelegate?
    private let config = GestureConfig.shared
    
    // 狀態追蹤
    private var hoverState: HoverState?
    private var motionTrackingState: MotionTrackingState?
    private var lastProcessTime: Date = Date()
    private var stateHistory: [GestureState] = []
    
    // 計時器
    private var hoverTimer: Timer?
    private var cooldownTimer: Timer?
    private var isCooldown: Bool = false
    
    // 比七手勢檢測計時器
    private var sevenGestureCheckTimer: Timer?
    private var lastSevenGestureCheckTime: Date = Date()
    
    // 手勢檢測歷史
    private var positionHistory: [(CGPoint, Date)] = []
    private var palmStateHistory: [PalmState] = []
    
    // MARK: - Initialization
    init(delegate: HandGestureDelegate? = nil) {
        self.delegate = delegate
        setupInitialState()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// 處理手部檢測結果
    func processHandDetection(_ detectedHands: [HandDetectionResult]) {
        guard isEnabled && !isCooldown else { return }
        
        // 限制檢測頻率
        let now = Date()
        let timeSinceLastProcess = now.timeIntervalSince(lastProcessTime)
        let minInterval = 1.0 / config.maxDetectionFrequency
        
        guard timeSinceLastProcess >= minInterval else { return }
        lastProcessTime = now
        
        // 處理檢測結果
        if detectedHands.isEmpty {
            handleNoHandDetected(now)
        } else {
            // 更新最後檢測時間
            lastHandDetectionTime = now
            
            // 選擇信心度最高的手部，永遠進行手部處理（包括位置追蹤）
            let bestHand = detectedHands.max { $0.confidence < $1.confidence }!
            processHandGesture(bestHand)
        }
    }
    
    /// 重置手勢辨識狀態
    func reset() {
        changeState(to: .idle)
        cleanup()
        setupInitialState()
        requiresHandReset = false
    }
    
    /// 啟用/停用手勢辨識
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            reset()
        }
    }
    
    // MARK: - Private Methods - State Management
    
    private func setupInitialState() {
        currentState = .idle
        palmState = nil
        hoverProgress = 0.0
        lastGestureResult = nil
        triggeredDirections.removeAll()
        clearHistory()
    }
    
    private func changeState(to newState: GestureState) {
        guard newState != currentState else { return }
        
        let oldState = currentState
        
        // 確保在主線程更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentState = newState
            self.stateHistory.append(newState)
            
            // 保持歷史記錄在合理範圍內
            if self.stateHistory.count > 10 {
                self.stateHistory.removeFirst()
            }
            
            print("手勢狀態變更: \(oldState.description) -> \(newState.description)")
            
            // 通知委託
            self.delegate?.gestureStateDidChange(newState)
        }
        
        // 狀態變更處理（可以在後台線程執行）
        handleStateTransition(from: oldState, to: newState)
    }
    
    private func handleStateTransition(from oldState: GestureState, to newState: GestureState) {
        switch newState {
        case .idle:
            cleanup()
        case .detecting:
            break
        case .hovering:
            startHoverDetection()
        case .ready:
            startMotionTracking()
        case .processing:
            break
        case .completed:
            handleGestureCompleted()
        }
    }
    
    // MARK: - Private Methods - Hand Processing
    
    private func handleNoHandDetected(_ now: Date) {
        // 如果需要重置且檢測不到手部，表示手掌已經離開檢測範圍
        if requiresHandReset {
            print("手掌已完全離開檢測範圍，重置檢測狀態，可以重新開始檢測")
            requiresHandReset = false
            triggeredDirections.removeAll()  // 重置所有方向的觸發狀態
            changeState(to: .idle)
            return
        }
        
        // 如果在準備就緒狀態檢測不到手掌，表示手掌離開了（第三步的情況）
        if currentState == .ready {
            print("準備就緒狀態下手掌離開檢測範圍，回到空閒狀態")
            changeState(to: .idle)
            return
        }
        
        // 正常情況下，沒有手部檢測時回到空閒狀態
        if currentState != .idle {
            changeState(to: .idle)
        }
    }
    
    private func processHandGesture(_ hand: HandDetectionResult) {
        // 永遠更新位置歷史，無論在什麼狀態
        updatePositionHistory(hand)
        
        // 如果需要重置，只進行位置追蹤，不進行手勢分析
        if requiresHandReset {
            // 靜默追蹤位置，不打印調試信息
            return
        }
        
        // 正常的手勢檢測流程
        switch currentState {
        case .idle, .detecting:
            checkPalmOpen(hand)
        case .hovering:
            updateHoverProgress(hand)
            case .ready:
                // 持續輸出食指角度
                if let indexTip = hand.landmarks.first(where: { $0.jointName == .indexTip }),
                   let indexPIP = hand.landmarks.first(where: { $0.jointName == .indexPIP }) {
                    let indexVector = CGPoint(
                        x: indexTip.point.x - indexPIP.point.x,
                        y: indexTip.point.y - indexPIP.point.y
                    )
                    let angle = atan2(indexVector.y, indexVector.x)
                    let angleDegrees = angle * 180 / .pi
                    print("食指角度: \(String(format: "%.1f", angleDegrees))°")
                }
                detectMotion(hand)
        case .processing:
            continueMotionDetection(hand)
        case .completed:
            // 在完成狀態時，繼續位置追蹤但不進行新的手勢分析
            // 這個狀態應該很快轉換，因為 requiresHandReset 會被設定
            break
        }
    }
    
    private func updatePositionHistory(_ hand: HandDetectionResult) {
        let centerPoint = calculateHandCenter(hand)
        let now = Date()
        
        positionHistory.append((centerPoint, now))
        
        // 保持歷史記錄在時間窗口內
        let cutoffTime = now.addingTimeInterval(-config.motionTimeWindow)
        positionHistory.removeAll { $0.1 < cutoffTime }
    }
    
    // MARK: - Private Methods - Palm Detection
    
    private func checkPalmOpen(_ hand: HandDetectionResult) {
        let palmState = analyzePalmState(hand)
        updatePalmState(palmState)
        
        if palmState.isSevenGesture && palmState.confidence >= config.sevenGestureConfidenceThreshold {
            if currentState == .idle || currentState == .detecting {
                changeState(to: .hovering)
            }
        } else {
            if currentState == .hovering {
                changeState(to: .detecting)
            } else if currentState == .detecting {
                // 繼續檢測
            } else {
                changeState(to: .idle)
            }
        }
    }
    
    private func analyzePalmState(_ hand: HandDetectionResult) -> PalmState {
        let centerPoint = calculateHandCenter(hand)
        
        // 檢測比七手勢：食指和大拇指伸直，其餘彎曲
        let sevenGestureResult = analyzeSevenGesture(hand)
        
        // 簡化的調試信息
        if sevenGestureResult.isSevenGesture {
            print("🤚 比七手勢檢測成功 (信心度: \(String(format: "%.2f", sevenGestureResult.confidence)))")
        }
        
        let fingerExtensions = [
            sevenGestureResult.thumbExtended,
            sevenGestureResult.indexExtended,
            sevenGestureResult.middleBent,
            sevenGestureResult.ringBent,
            sevenGestureResult.littleBent
        ]
        
        return PalmState(
            isSevenGesture: sevenGestureResult.isSevenGesture,
            confidence: sevenGestureResult.confidence,
            centerPoint: centerPoint,
            fingerExtensions: fingerExtensions
        )
    }
    
    private func isHandOpenBySize(_ hand: HandDetectionResult) -> Bool {
        // 基於手部邊界框大小的簡單檢測
        let boundingBox = hand.boundingBox
        let area = boundingBox.width * boundingBox.height
        
        // 張開的手應該占據更大的區域
        let isLargeEnough = area > 0.04 // 占屏幕4%以上（提高閾值）
        
        // 檢查寬高比，張開的手通常比較寬，握拳會比較方正
        let aspectRatio = boundingBox.width / boundingBox.height
        let isWideEnough = aspectRatio > 1.2 // 寬度至少是高度的1.2倍
        
        // 檢查手部是否足夠寬（絕對尺寸）
        let isAbsolutelyWide = boundingBox.width > 0.15 // 寬度至少占屏幕15%
        
        print("   邊界框檢測: 面積=\(String(format: "%.4f", area)), 寬高比=\(String(format: "%.2f", aspectRatio))")
        print("   寬度=\(String(format: "%.3f", boundingBox.width)), 高度=\(String(format: "%.3f", boundingBox.height))")
        print("   大小足夠: \(isLargeEnough), 寬高比足夠: \(isWideEnough), 絕對寬度足夠: \(isAbsolutelyWide)")
        
        return isLargeEnough && isWideEnough && isAbsolutelyWide
    }
    
    // MARK: - 比七手勢檢測結果
    struct SevenGestureResult {
        let thumbExtended: Bool      // 拇指是否伸直
        let indexExtended: Bool      // 食指是否伸直
        let middleBent: Bool         // 中指是否彎曲
        let ringBent: Bool           // 無名指是否彎曲
        let littleBent: Bool         // 小指是否彎曲
        let middleExtended: Bool     // 中指是否伸直（為了兼容性）
        let ringExtended: Bool       // 無名指是否伸直（為了兼容性）
        let littleExtended: Bool     // 小指是否伸直（為了兼容性）
        let isSevenGesture: Bool     // 是否為比七手勢
        let confidence: Float        // 信心度
    }
    
    // MARK: - 比七手勢檢測
    private func analyzeSevenGesture(_ hand: HandDetectionResult) -> SevenGestureResult {
        // 檢測各手指的伸展狀態，使用不同的閾值
        let thumbExtended = isFingerExtendedRelaxed(.thumb, in: hand)  // 放寬判定
        let indexExtended = isFingerExtendedRelaxed(.index, in: hand)  // 放寬判定
        let middleExtended = isFingerExtendedStrict(.middle, in: hand) // 收緊判定
        let ringExtended = isFingerExtendedStrict(.ring, in: hand)     // 收緊判定
        let littleExtended = isFingerExtendedStrict(.little, in: hand) // 收緊判定
        
        // 比七手勢：食指和大拇指伸直，其餘彎曲
        let middleBent = !middleExtended
        let ringBent = !ringExtended
        let littleBent = !littleExtended
        
        // 額外的嚴格彎曲檢查：檢查指尖是否足夠靠近手掌
        let isSevenGesture = thumbExtended && indexExtended && middleBent && ringBent && littleBent
        
        // 計算信心度
        var confidence: Float = 0.0
        if isSevenGesture {
            confidence = 0.9 // 高信心度
        } else {
            // 部分匹配時給予較低信心度
            let matchCount = [thumbExtended, indexExtended, middleBent, ringBent, littleBent].filter { $0 }.count
            confidence = Float(matchCount) / 5.0 * 0.6
        }
        
        confidence *= hand.confidence // 乘以手部檢測的信心度
        
        return SevenGestureResult(
            thumbExtended: thumbExtended,
            indexExtended: indexExtended,
            middleBent: middleBent,
            ringBent: ringBent,
            littleBent: littleBent,
            middleExtended: middleExtended,
            ringExtended: ringExtended,
            littleExtended: littleExtended,
            isSevenGesture: isSevenGesture,
            confidence: confidence
        )
    }
    
    // MARK: - 額外的嚴格彎曲檢查
    
    
    
    
    private func isFingerExtended(_ finger: FingerType, in hand: HandDetectionResult) -> Bool {
        let jointNames = finger.jointNames
        let landmarks = hand.landmarks.filter { jointNames.contains($0.jointName) }
        
        guard landmarks.count >= 3 else { return false }
        
        // 使用更智能的手指伸展檢測
        return isFingerExtendedImproved(finger: finger, landmarks: landmarks)
    }
    
    // 放寬判定的手指檢測（用於食指和拇指）
    private func isFingerExtendedRelaxed(_ finger: FingerType, in hand: HandDetectionResult) -> Bool {
        let jointNames = finger.jointNames
        let landmarks = hand.landmarks.filter { jointNames.contains($0.jointName) }
        
        guard landmarks.count >= 3 else { return false }
        
        return isFingerExtendedImproved(finger: finger, landmarks: landmarks, thresholdMultiplier: 0.6) // 降低閾值
    }
    
    // 收緊判定的手指檢測（用於中指、無名指、小指）
    private func isFingerExtendedStrict(_ finger: FingerType, in hand: HandDetectionResult) -> Bool {
        let jointNames = finger.jointNames
        let landmarks = hand.landmarks.filter { jointNames.contains($0.jointName) }
        
        guard landmarks.count >= 3 else { return false }
        
        return isFingerExtendedImproved(finger: finger, landmarks: landmarks, thresholdMultiplier: 0.5) // 大幅提高閾值
    }
    
    private func isFingerExtendedImproved(finger: FingerType, landmarks: [HandLandmark], thresholdMultiplier: Float = 1.0) -> Bool {
        let jointNames = finger.jointNames
        
        // 根據不同手指使用不同的檢測策略
        switch finger {
        case .thumb:
            return isThumbExtended(landmarks: landmarks, jointNames: jointNames, thresholdMultiplier: thresholdMultiplier)
        default:
            return isRegularFingerExtended(landmarks: landmarks, jointNames: jointNames, thresholdMultiplier: thresholdMultiplier)
        }
    }
    
    private func isThumbExtended(landmarks: [HandLandmark], jointNames: [VNHumanHandPoseObservation.JointName], thresholdMultiplier: Float = 1.0) -> Bool {
        // 拇指的檢測：檢查拇指尖是否遠離手掌中心
        guard let thumbTip = landmarks.first(where: { $0.jointName == .thumbTip }),
              let thumbCMC = landmarks.first(where: { $0.jointName == .thumbCMC }) else {
            return false
        }
        
        let distance = sqrt(pow(thumbTip.point.x - thumbCMC.point.x, 2) + pow(thumbTip.point.y - thumbCMC.point.y, 2))
        let adjustedThreshold = config.fingerExtensionThreshold * 0.8 * thresholdMultiplier
        return distance > CGFloat(adjustedThreshold)
    }
    
    private func isRegularFingerExtended(landmarks: [HandLandmark], jointNames: [VNHumanHandPoseObservation.JointName], thresholdMultiplier: Float = 1.0) -> Bool {
        // 一般手指的檢測：檢查關節是否呈直線伸展
        guard jointNames.count >= 4 else { return false }
        
        let tipName = jointNames[0]     // 指尖
        let dipName = jointNames[1]     // DIP 關節
        let pipName = jointNames[2]     // PIP 關節
        let mcpName = jointNames[3]     // MCP 關節（基部）
        
        guard let tip = landmarks.first(where: { $0.jointName == tipName }),
              let dip = landmarks.first(where: { $0.jointName == dipName }),
              let pip = landmarks.first(where: { $0.jointName == pipName }),
              let mcp = landmarks.first(where: { $0.jointName == mcpName }) else {
            return false
        }
        
        // 計算指尖到基部的距離
        let totalDistance = sqrt(pow(tip.point.x - mcp.point.x, 2) + pow(tip.point.y - mcp.point.y, 2))
        
        // 計算各段的距離
        let tipToDip = sqrt(pow(tip.point.x - dip.point.x, 2) + pow(tip.point.y - dip.point.y, 2))
        let dipToPip = sqrt(pow(dip.point.x - pip.point.x, 2) + pow(dip.point.y - pip.point.y, 2))
        let pipToMcp = sqrt(pow(pip.point.x - mcp.point.x, 2) + pow(pip.point.y - mcp.point.y, 2))
        
        // 根據閾值乘數調整距離要求
        let adjustedSegmentThreshold = 0.02 * thresholdMultiplier
        let segmentDistancesGood = tipToDip > CGFloat(adjustedSegmentThreshold) && 
                                  dipToPip > CGFloat(adjustedSegmentThreshold) && 
                                  pipToMcp > CGFloat(adjustedSegmentThreshold)
        
        // 計算彎曲度
        let bendingFactor = calculateBendingFactor(tip: tip.point, middle: pip.point, base: mcp.point)
        
        // 根據閾值乘數調整彎曲度要求
        let adjustedBendingThreshold = 0.3 / thresholdMultiplier  // 降低彎曲度閾值，更嚴格
        
        // 手指伸展判斷：總距離足夠、各段距離合理、彎曲度小
        let adjustedTotalThreshold = config.fingerExtensionThreshold * thresholdMultiplier
        let isExtended = totalDistance > CGFloat(adjustedTotalThreshold) && 
                        segmentDistancesGood && 
                        bendingFactor < Float(adjustedBendingThreshold)
        
        return isExtended
    }
    
    private func calculateBendingFactor(tip: CGPoint, middle: CGPoint, base: CGPoint) -> Float {
        // 計算中間點到直線的距離比例
        let lineLength = sqrt(pow(tip.x - base.x, 2) + pow(tip.y - base.y, 2))
        guard lineLength > 0 else { return 1.0 }
        
        // 使用點到直線距離公式
        let numerator = abs((tip.y - base.y) * middle.x - (tip.x - base.x) * middle.y + tip.x * base.y - tip.y * base.x)
        let distance = numerator / lineLength
        
        return Float(distance / lineLength)
    }
    
    private func updatePalmState(_ newPalmState: PalmState) {
        // 確保在主線程更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.palmState = newPalmState
            self.palmStateHistory.append(newPalmState)
            
            // 保持歷史記錄在合理範圍內
            if self.palmStateHistory.count > 20 {
                self.palmStateHistory.removeFirst()
            }
            
            self.delegate?.palmStateDidChange(newPalmState)
        }
    }
    
    // MARK: - Private Methods - Hover Detection
    
    private func startHoverDetection() {
        guard let currentPalmState = palmState else { return }
        
        hoverState = HoverState(
            startTime: Date(),
            startPosition: currentPalmState.centerPoint,
            currentPosition: currentPalmState.centerPoint,
            isStable: true,
            duration: 0
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.hoverProgress = 0.0
        }
        startHoverTimer()
        startSevenGestureCheckTimer()
    }
    
    private func startHoverTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hoverTimer?.invalidate()
            self.hoverTimer = Timer.scheduledTimer(withTimeInterval: self.config.hoverSampleInterval, repeats: true) { [weak self] _ in
                self?.updateHoverTimer()
            }
        }
    }
    
    private func updateHoverTimer() {
        guard let hoverState = hoverState else { return }
        
        let progress = Float(hoverState.duration / config.hoverDuration)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hoverProgress = min(progress, 1.0)
            self.delegate?.hoverProgressDidUpdate(self.hoverProgress)
        }
        
        // 注意：懸停完成的檢測和狀態轉換現在在 updateHoverProgress 中進行
        // 因為那裡有手部檢測數據，可以進行最後一次比七手勢檢測
    }
    
    // MARK: - 比七手勢定期檢測
    
    private func startSevenGestureCheckTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sevenGestureCheckTimer?.invalidate()
            self.lastSevenGestureCheckTime = Date()
            
            // 每 0.5 秒檢測一次比七手勢
            self.sevenGestureCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.performSevenGestureCheck()
            }
        }
    }
    
    private func performSevenGestureCheck() {
        // 檢查當前狀態是否仍在懸停中
        guard currentState == .hovering else {
            stopSevenGestureCheckTimer()
            return
        }
        
        let now = Date()
        let timeSinceLastCheck = now.timeIntervalSince(lastSevenGestureCheckTime)
        
        print("🤚 定期比七手勢檢測: 距離上次檢測 \(String(format: "%.1f", timeSinceLastCheck))秒")
        
        // 注意：這個方法沒有手部數據，實際檢測在 performSevenGestureCheckWithHand 中進行
    }
    
    private func performSevenGestureCheckWithHand(_ hand: HandDetectionResult) {
        // 檢查當前狀態是否仍在懸停中
        guard currentState == .hovering else {
            stopSevenGestureCheckTimer()
            return
        }
        
        // 進行比七手勢檢測
        let sevenGestureResult = analyzeSevenGesture(hand)
        
        print("🤚 懸停期間比七手勢檢測:")
        print("   拇指伸直: \(sevenGestureResult.thumbExtended)")
        print("   食指伸直: \(sevenGestureResult.indexExtended)")
        print("   中指彎曲: \(sevenGestureResult.middleBent)")
        print("   無名指彎曲: \(sevenGestureResult.ringBent)")
        print("   小指彎曲: \(sevenGestureResult.littleBent)")
        print("   比七手勢: \(sevenGestureResult.isSevenGesture)")
        print("   信心度: \(String(format: "%.2f", sevenGestureResult.confidence))")
        
        // 如果不再維持比七手勢，退出懸停狀態
        if !sevenGestureResult.isSevenGesture {
            print("❌ 懸停期間比七手勢中斷，返回檢測狀態")
            changeState(to: .detecting)
            stopSevenGestureCheckTimer()
        }
    }
    
    private func stopSevenGestureCheckTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.sevenGestureCheckTimer?.invalidate()
            self?.sevenGestureCheckTimer = nil
        }
    }
    
    private func updateHoverProgress(_ hand: HandDetectionResult) {
        guard var hoverState = hoverState else { return }
        
        let currentPosition = calculateHandCenter(hand)
        let now = Date()
        
        // 更新懸停狀態
        let duration = now.timeIntervalSince(hoverState.startTime)
        let distance = sqrt(
            pow(currentPosition.x - hoverState.startPosition.x, 2) +
            pow(currentPosition.y - hoverState.startPosition.y, 2)
        )
        
        let isStable = distance <= CGFloat(config.hoverStabilityThreshold)
        
        // 改進的懸停邏輯：允許一定程度的不穩定
        let shouldRestart = !isStable && distance > CGFloat(config.hoverStabilityThreshold * 2.0)
        
        self.hoverState = HoverState(
            startTime: shouldRestart ? now : hoverState.startTime,
            startPosition: shouldRestart ? currentPosition : hoverState.startPosition,
            currentPosition: currentPosition,
            isStable: isStable,
            duration: shouldRestart ? 0 : duration
        )
        
        // 定期比七手勢檢測（每 0.5 秒）
        let timeSinceLastCheck = now.timeIntervalSince(lastSevenGestureCheckTime)
        if timeSinceLastCheck >= 0.5 {
            performSevenGestureCheckWithHand(hand)
            lastSevenGestureCheckTime = now
        }
        
        // 懸停完成前進行最後一次比七手勢檢測
        if duration >= config.hoverDuration {
            print("🤚 懸停完成前最後一次比七手勢檢測")
            performSevenGestureCheckWithHand(hand)
            
            // 如果最後一次檢測通過，轉換到準備就緒狀態
            let sevenGestureResult = analyzeSevenGesture(hand)
            if sevenGestureResult.isSevenGesture {
                print("✅ 懸停完成，進入準備就緒狀態")
                changeState(to: .ready)
            } else {
                print("❌ 懸停完成前手勢中斷，返回檢測狀態")
                changeState(to: .detecting)
                stopSevenGestureCheckTimer()
            }
            return
        }
        
        // 只有在移動距離過大時才重新開始計時
        if shouldRestart {
            print("懸停重新開始：移動距離 \(String(format: "%.3f", distance)) 超過閾值 \(config.hoverStabilityThreshold * 2.0)")
            DispatchQueue.main.async { [weak self] in
                self?.hoverProgress = 0.0
            }
        } else {
            print("懸停進行中：移動距離 \(String(format: "%.3f", distance))，持續時間 \(String(format: "%.1f", duration))秒")
        }
    }
    
    // MARK: - Private Methods - Motion Detection
    
    private func startMotionTracking() {
        guard let palmState = palmState else { return }
        
        motionTrackingState = MotionTrackingState(
            startPosition: palmState.centerPoint,
            currentPosition: palmState.centerPoint,
            velocity: CGVector.zero,
            direction: .none,
            distance: 0,
            startTime: Date()
        )
        
        print("開始動作追蹤，準備接收手勢")
    }
    
    private func detectMotion(_ hand: HandDetectionResult) {
        guard let trackingState = motionTrackingState else { return }
        
        // 檢測食指向左或向右的指向動作
        let pointingResult = detectPointingGesture(hand)
        
        if pointingResult.isPointing && !triggeredDirections.contains(pointingResult.direction) {
            print("檢測到指向動作: 方向=\(pointingResult.direction), 信心度=\(String(format: "%.2f", pointingResult.confidence))")
            changeState(to: .processing)
            triggeredDirections.insert(pointingResult.direction)  // 標記此方向已觸發
            
            switch pointingResult.direction {
            case .down:  // 向下指 = 向左指 = 上一步
                recognizeGesture(.previousStep, confidence: pointingResult.confidence, position: pointingResult.position)
            case .up:    // 向上指 = 向右指 = 下一步
                recognizeGesture(.nextStep, confidence: pointingResult.confidence, position: pointingResult.position)
            default:
                break
            }
            return
        }
        
        
        // 更新追蹤狀態
        updateMotionTrackingState(calculateHandCenter(hand))
    }
    
    // MARK: - 指向手勢檢測結果
    struct PointingGestureResult {
        let isPointing: Bool          // 是否為指向動作
        let direction: MotionDirection // 指向方向
        let confidence: Float         // 信心度
        let position: CGPoint         // 手指位置
    }
    
    // MARK: - 指向手勢檢測
    private func detectPointingGesture(_ hand: HandDetectionResult) -> PointingGestureResult {
        // 獲取食指關節點
        guard let indexTip = hand.landmarks.first(where: { $0.jointName == .indexTip }),
              let indexPIP = hand.landmarks.first(where: { $0.jointName == .indexPIP }),
              let indexMCP = hand.landmarks.first(where: { $0.jointName == .indexMCP }),
              let wrist = hand.landmarks.first(where: { $0.jointName == .wrist }) else {
            return PointingGestureResult(isPointing: false, direction: .none, confidence: 0.0, position: .zero)
        }
        
        // 檢查食指是否伸直（暫時移除嚴格檢查）
        // let indexExtended = isFingerExtended(.index, in: hand)
        // guard indexExtended else {
        //     return PointingGestureResult(isPointing: false, direction: .none, confidence: 0.0, position: .zero)
        // }
        
        // 檢查其他手指是否彎曲（除了拇指）
        let middleBent = !isFingerExtended(.middle, in: hand)
        let ringBent = !isFingerExtended(.ring, in: hand)
        let littleBent = !isFingerExtended(.little, in: hand)
        
        // 如果至少2個其他手指彎曲，則為指向動作
        let bentCount = [middleBent, ringBent, littleBent].filter { $0 }.count
        let isPointing = bentCount >= 0
        
        guard isPointing else {
            return PointingGestureResult(isPointing: false, direction: .none, confidence: 0.0, position: indexTip.point)
        }
        
        // 計算指向方向
        let indexVector = CGPoint(
            x: indexTip.point.x - indexPIP.point.x,
            y: indexTip.point.y - indexPIP.point.y
        )
        
        // 計算方向角度（相對於水平線）
        let angle = atan2(indexVector.y, indexVector.x)
        let angleDegrees = angle * 180 / .pi
        
        // 判斷指向方向（根據實際手勢映射）
        let direction: MotionDirection
        if angleDegrees >= -150 && angleDegrees <= -30 {
            // 上一步：-150° 到 -30°
            direction = .up
        } else if angleDegrees >= 30 && angleDegrees <= 150 {
            // 下一步：30° 到 150°
            direction = .down
        } else {
            // 其他角度範圍：無效手勢
            direction = .none
        }
        
        // 計算信心度
        let confidence = hand.confidence * 0.8 // 基礎信心度
        
        print("指向檢測: 食指角度=\(String(format: "%.1f", angleDegrees))°, 方向=\(direction.description)")
        
        return PointingGestureResult(
            isPointing: true,
            direction: direction,
            confidence: confidence,
            position: indexTip.point
        )
    }
    
    
    private func continueMotionDetection(_ hand: HandDetectionResult) {
        // 處理狀態超時檢查
        let elapsedTime = Date().timeIntervalSince(motionTrackingState?.startTime ?? Date())
        if elapsedTime > 1.0 {
            changeState(to: .idle)
        }
    }
    
    private func updateMotionTrackingState(_ currentPosition: CGPoint) {
        guard let oldState = motionTrackingState else { return }
        
        let deltaX = currentPosition.x - oldState.currentPosition.x
        let deltaY = currentPosition.y - oldState.currentPosition.y
        let velocity = CGVector(dx: deltaX, dy: deltaY)
        
        let totalDeltaX = currentPosition.x - oldState.startPosition.x
        let totalDeltaY = currentPosition.y - oldState.startPosition.y
        let totalDistance = Float(sqrt(totalDeltaX * totalDeltaX + totalDeltaY * totalDeltaY))
        
        let direction: MotionDirection
        if abs(totalDeltaY) > abs(totalDeltaX) {
            direction = totalDeltaY < 0 ? .up : .down
        } else if abs(totalDeltaX) > abs(totalDeltaY) {
            direction = totalDeltaX < 0 ? .left : .right
        } else {
            direction = .none
        }
        
        motionTrackingState = MotionTrackingState(
            startPosition: oldState.startPosition,
            currentPosition: currentPosition,
            velocity: velocity,
            direction: direction,
            distance: totalDistance,
            startTime: oldState.startTime
        )
    }
    
    // MARK: - Private Methods - Gesture Recognition
    
    private func recognizeGesture(_ gestureType: GestureType, confidence: Float, position: CGPoint) {
        let result = GestureResult(
            gestureType: gestureType,
            confidence: confidence,
            handPosition: position
        )
        
        print("辨識到手勢: \(gestureType.description), 信心度: \(confidence)")
        print("設定重置標誌，等待手掌離開檢測範圍")
        
        // 立即設定需要重置標誌，停止手勢分析但繼續位置追蹤
        requiresHandReset = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastGestureResult = result
            self.delegate?.didRecognizeGesture(result)
            
            // 發送通知給 CookViewController
            NotificationCenter.default.post(
                name: NSNotification.Name("GestureRecognized"),
                object: nil,
                userInfo: ["type": gestureType.description]
            )
        }
        
        changeState(to: .completed)
    }
    
    private func handleGestureCompleted() {
        // 動作完成後，直接進入等待手掌離開狀態，不需要冷卻期
        print("手勢完成，等待手掌離開螢幕")
        // 保持在完成狀態，直到手掌離開並重新進入
    }
    
    private func startCooldown() {
        isCooldown = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cooldownTimer?.invalidate()
            self.cooldownTimer = Timer.scheduledTimer(withTimeInterval: self.config.cooldownDuration, repeats: false) { [weak self] _ in
                self?.endCooldown()
            }
        }
    }
    
    private func endCooldown() {
        DispatchQueue.main.async { [weak self] in
            self?.isCooldown = false
        }
        // 不自動回到空閒狀態，等待手掌離開螢幕重置
    }
    
    // MARK: - Private Methods - Utilities
    
    private func calculateHandCenter(_ hand: HandDetectionResult) -> CGPoint {
        guard !hand.landmarks.isEmpty else { return .zero }
        
        let xSum = hand.landmarks.reduce(0) { $0 + $1.point.x }
        let ySum = hand.landmarks.reduce(0) { $0 + $1.point.y }
        let count = CGFloat(hand.landmarks.count)
        
        return CGPoint(x: xSum / count, y: ySum / count)
    }
    
    private func clearHistory() {
        positionHistory.removeAll()
        palmStateHistory.removeAll()
        stateHistory.removeAll()
    }
    
    private func cleanup() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hoverTimer?.invalidate()
            self.cooldownTimer?.invalidate()
            self.sevenGestureCheckTimer?.invalidate()
            self.hoverTimer = nil
            self.cooldownTimer = nil
            self.sevenGestureCheckTimer = nil
        }
        hoverState = nil
        motionTrackingState = nil
        clearHistory()
    }
}

// MARK: - Extensions

extension CGVector {
    static let zero = CGVector(dx: 0, dy: 0)
}
