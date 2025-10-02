//
//  CookViewController.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/7.
//

import UIKit
import SwiftUI
import AVFoundation
import Vision

/// MARK: - 你專案中的手勢協定 / 型別（假設已存在於專案內）
/// 若你的專案型別命名不同，請把下面的引用與 switch case 對應到你的實際名稱。
protocol ARGestureDelegate: AnyObject {
    func didRecognizeGesture(_ gestureType: GestureType)
    func gestureStateDidChange(_ state: GestureState)
    func hoverProgressDidUpdate(_ progress: Float)
    func palmStateDidChange(_ palmState: PalmState)
    func gestureRecognitionDidFail(with error: GestureRecognitionError)
}

enum GestureType {
    case previousStep
    case nextStep
    var description: String {
        switch self {
        case .previousStep: return "Previous"
        case .nextStep:     return "Next"
        }
    }
}

enum GestureState {
    case idle, detecting, hovering, ready, processing, completed
    var description: String {
        switch self {
        case .idle:       return "idle"
        case .detecting:  return "detecting"
        case .hovering:   return "hovering"
        case .ready:      return "ready"
        case .processing: return "processing"
        case .completed:  return "completed"
        }
    }
}

enum PalmState { case open, closed, unknown }
struct GestureRecognitionError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// 「開始烹飪」AR 流程 —— 使用後端已附帶 arType / arParameters 的步驟模型
/// ✅ 在原本的基礎上「加入手勢辨識」與「手勢狀態 UI」
final class CookViewController: BaseCameraViewController<ARSessionAdapter>, ARGestureDelegate {

    // MARK: - Data
    private var steps: [RecipeStep]
    private var currentIndex = 0 {
        didSet {
            guard !steps.isEmpty else { return }
            // 邊界保護（避免外部觸發越界）
            currentIndex = max(0, min(currentIndex, steps.count - 1))
            updateStepLabel()

            // 重新設定 rootView 以強制 SwiftUI 更新到「新的步驟值」
            // ✅ 保留你原本以 stepModel 驅動 AR 的做法
            arContainer.rootView = CookingARView(stepModel: steps[currentIndex])
        }
    }

    // MARK: - UI（原有）
    private let stepLabel = UILabel()
    private let prevBtn   = UIButton(type: .system)
    private let nextBtn   = UIButton(type: .system)

    // MARK: - 手勢狀態 UI（新增）
    private let gestureStatusLabel = UILabel()
    private let hoverProgressView  = UIProgressView()

    private var arContainer: UIHostingController<CookingARView>!

    // MARK: - Init
    init(steps: [RecipeStep]) {
        self.steps = steps
        super.init(session: ARSessionAdapter())
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        guard !steps.isEmpty else {
            view.backgroundColor = .black
            stepLabel.text = "無步驟"
            prevBtn.isEnabled = false
            nextBtn.isEnabled = false
            return
        }

        // ✅ 初始 AR 容器：沿用「值型步驟（含 arType / arParameters）」的設計
        arContainer = UIHostingController(
            rootView: CookingARView(stepModel: steps[currentIndex])
        )
        addChild(arContainer)
        arContainer.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arContainer.view)
        NSLayoutConstraint.activate([
            arContainer.view.topAnchor.constraint(equalTo: view.topAnchor),
            arContainer.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arContainer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        arContainer.didMove(toParent: self)

        // ▲ Step Label
        stepLabel.numberOfLines = 0
        stepLabel.textColor = .white
        stepLabel.font = .preferredFont(forTextStyle: .headline)
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepLabel)

        // ▼ Prev / Next Buttons
        let hStack = UIStackView(arrangedSubviews: [prevBtn, nextBtn])
        hStack.axis = .horizontal
        hStack.spacing = 40
        hStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hStack)

        prevBtn.setTitle("〈 上一步", for: .normal)
        nextBtn.setTitle("下一步 〉", for: .normal)
        prevBtn.addTarget(self, action: #selector(prevStep), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(nextStep), for: .touchUpInside)

        // ✅ 手勢狀態 UI
        setupGestureStatusUI()

        NSLayoutConstraint.activate([
            stepLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stepLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stepLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            gestureStatusLabel.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 8),
            gestureStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            gestureStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            gestureStatusLabel.heightAnchor.constraint(equalToConstant: 30),

            hoverProgressView.topAnchor.constraint(equalTo: gestureStatusLabel.bottomAnchor, constant: 4),
            hoverProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hoverProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            hoverProgressView.heightAnchor.constraint(equalToConstant: 4),

            hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // 初次顯示
        updateStepLabel()

        // ✅ 指派手勢委託（你的 ARSessionAdapter 需對外暴露 gestureDelegate）
        session.gestureDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📸 View Did Appear | steps = \(steps.count)")

        // ✅ 啟用手勢辨識（你的 ARSessionAdapter 需提供 setGestureEnabled）
        session.setGestureEnabled(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // ✅ 停用手勢辨識
        session.setGestureEnabled(false)
    }

    // MARK: - Helpers
    private func updateStepLabel() {
        guard !steps.isEmpty else {
            stepLabel.text = "無步驟"
            prevBtn.isEnabled = false
            nextBtn.isEnabled = false
            return
        }
        let step = steps[currentIndex]
        stepLabel.text = "步驟 \(step.step_number)：\(step.title)\n\(step.description)"
        prevBtn.isEnabled = currentIndex > 0
        nextBtn.isEnabled = currentIndex < steps.count - 1
    }

    @objc private func prevStep() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    @objc private func nextStep() {
        guard currentIndex < steps.count - 1 else { return }
        currentIndex += 1
    }

    // MARK: - 手勢狀態 UI
    private func setupGestureStatusUI() {
        gestureStatusLabel.text = "手勢辨識：準備中"
        gestureStatusLabel.textColor = .white
        gestureStatusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        gestureStatusLabel.textAlignment = .center
        gestureStatusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        gestureStatusLabel.layer.cornerRadius = 8
        gestureStatusLabel.clipsToBounds = true
        gestureStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gestureStatusLabel)

        hoverProgressView.progressTintColor = .systemBlue
        hoverProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.25)
        hoverProgressView.progress = 0.0
        hoverProgressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hoverProgressView)
    }

    private func updateGestureStatusUI(_ state: GestureState) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let (text, color): (String, UIColor) = {
                switch state {
                case .idle:       return ("手勢辨識：等待手部", .systemGray)
                case .detecting:  return ("手勢辨識：偵測中", .systemYellow)
                case .hovering:   return ("手勢辨識：懸停中…", .systemOrange)
                case .ready:      return ("手勢辨識：準備完成", .systemGreen)
                case .processing: return ("手勢辨識：處理中", .systemBlue)
                case .completed:  return ("手勢辨識：完成", .systemGreen)
                }
            }()
            self.gestureStatusLabel.text = text
            self.gestureStatusLabel.backgroundColor = color.withAlphaComponent(0.6)
        }
    }

    private func updateHoverProgressUI(_ progress: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.hoverProgressView.progress = max(0, min(progress, 1))
        }
    }
}

// MARK: - ARGestureDelegate
extension CookViewController {
    func didRecognizeGesture(_ gestureType: GestureType) {
        print("🎯 [CookViewController] 接收到手勢: \(gestureType.description)")
        DispatchQueue.main.async { [weak self] in
            switch gestureType {
            case .previousStep: self?.prevStep()
            case .nextStep:     self?.nextStep()
            }
        }
    }

    func gestureStateDidChange(_ state: GestureState) {
        print("🎯 [CookViewController] 手勢狀態變更: \(state.description)")
        updateGestureStatusUI(state)
    }

    func hoverProgressDidUpdate(_ progress: Float) {
        updateHoverProgressUI(progress)
    }

    func palmStateDidChange(_ palmState: PalmState) {
        // 目前僅示意；若需要可在這裡更新額外 UI 或紀錄
        // print("✋ palm state: \(palmState)")
    }

    func gestureRecognitionDidFail(with error: GestureRecognitionError) {
        print("❌ [CookViewController] 手勢辨識錯誤: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.gestureStatusLabel.text = "手勢辨識錯誤：\(error.localizedDescription)"
            self?.gestureStatusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.6)
        }
    }
}

// MARK: - 便於佔位（僅在你真的需要佔位時使用）
private extension RecipeStep {
    static func placeholder() -> RecipeStep {
        // ⚠️ 這裡的初始化參數要「完全」符合你的 RecipeStep 結構（含可選 arType / arParameters）
        return RecipeStep(
            step_number: 1,
            title: "無",
            description: "無",
            actions: [],
            estimated_total_time: "未知",
            temperature: "未知",
            warnings: "無",
            notes: "無",
            arType: nil,
            arParameters: nil
        )
    }
}
