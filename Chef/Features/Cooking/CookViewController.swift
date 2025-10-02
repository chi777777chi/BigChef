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
/// 「開始烹飪」AR 流程 —— 加入手勢辨識
final class CookViewController: UIViewController, ARGestureDelegate {

    // MARK: - AR Session
    private let gestureSession = ARSessionAdapter()

    // MARK: - Data
    private let steps: [RecipeStep]
    private let stepViewModel = StepViewModel()
    private var currentIndex = 0 {
        didSet {
            updateStepLabel()
            stepViewModel.currentDescription = steps[currentIndex].description
            // 重新設定 rootView 以強制 SwiftUI 更新
            arContainer.rootView = CookingARView(
                stepModel: steps[currentIndex],
                sessionAdapter: gestureSession
            )
        }
    }

    // MARK: - UI
    private let stepLabel = UILabel()
    private let prevBtn   = UIButton(type: .system)
    private let nextBtn   = UIButton(type: .system)
    private let completeBtn = UIButton(type: .system)

    // 手勢狀態 UI
    private let gestureStatusLabel = UILabel()
    private let hoverProgressView  = UIProgressView()

    private var arContainer: UIHostingController<CookingARView>!
    private var stepBinding: Binding<String>!

    // 菜名（用於完成頁面）
    private var dishName: String = "料理"

    // 完成回調
    private var onComplete: (() -> Void)?

    // MARK: - Init
    init(steps: [RecipeStep], dishName: String = "料理", onComplete: (() -> Void)? = nil) {
        self.steps = steps
        self.dishName = dishName
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        stepViewModel.currentDescription = steps[currentIndex].description
        updateStepLabel()
        stepBinding = Binding<String>(
            get: { self.stepViewModel.currentDescription },
            set: { self.stepViewModel.currentDescription = $0 }
        )

        // ✅ CookingARView 使用共享的 gestureSession
        arContainer = UIHostingController(
            rootView: CookingARView(
                stepModel: steps[currentIndex],
                sessionAdapter: gestureSession
            )
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("📏 AR Container frame = \(self.arContainer.view.frame)")
        }
        // ▲ Step Label
        stepLabel.numberOfLines = 0
        stepLabel.textColor = .white
        stepLabel.font = .preferredFont(forTextStyle: .headline)
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepLabel)

        // ▼ Prev / Next / Complete Buttons
        let hStack = UIStackView(arrangedSubviews: [prevBtn, nextBtn])
        hStack.axis = .horizontal
        hStack.spacing = 40
        hStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hStack)

        prevBtn.setTitle("〈 上一步", for: .normal)
        nextBtn.setTitle("下一步 〉", for: .normal)
        prevBtn.addTarget(self, action: #selector(prevStep), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(nextStep), for: .touchUpInside)

        // 完成按鈕設置
        completeBtn.setTitle("✓ 完成", for: .normal)
        completeBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        completeBtn.backgroundColor = UIColor(named: "BrandOrange") ?? .systemOrange
        completeBtn.setTitleColor(.white, for: .normal)
        completeBtn.layer.cornerRadius = 12
        completeBtn.translatesAutoresizingMaskIntoConstraints = false
        completeBtn.addTarget(self, action: #selector(completeRecipe), for: .touchUpInside)
        completeBtn.isHidden = true
        view.addSubview(completeBtn)

        // 設定手勢狀態 UI
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
            hStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            completeBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            completeBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            completeBtn.widthAnchor.constraint(equalToConstant: 200),
            completeBtn.heightAnchor.constraint(equalToConstant: 50)
        ])

        updateStepLabel()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ✅ 先設定 delegate 和啟用，再啟動 session
        gestureSession.gestureDelegate = self
        gestureSession.setGestureEnabled(true)
        gestureSession.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📸 View Did Appear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // 停用手勢辨識
        gestureSession.setGestureEnabled(false)
        gestureSession.stop()
    }
    
    // MARK: - Helpers
    private func updateStepLabel() {
        guard !steps.isEmpty else { stepLabel.text = "無步驟"; return }
        let step = steps[currentIndex]
        stepLabel.text = "步驟 \(step.step_number)：\(step.title)\n\(step.description)"
        prevBtn.isEnabled = currentIndex > 0
        nextBtn.isEnabled = currentIndex < steps.count - 1

        // 判斷是否為最後一步
        let isLastStep = currentIndex == steps.count - 1
        completeBtn.isHidden = !isLastStep
        nextBtn.isHidden = isLastStep
    }

    @objc private func prevStep() { currentIndex -= 1 }
    @objc private func nextStep() { currentIndex += 1 }

    @objc private func completeRecipe() {
        // 顯示完成頁面
        let completionView = RecipeCompletionView(
            dishName: dishName,
            totalSteps: steps.count
        ) { [weak self] in
            guard let self = self else { return }

            // 先關閉 modal 完成頁面
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }

                // 呼叫完成回調，通知 coordinator 處理返回首頁邏輯
                self.onComplete?()
            }
        }

        let hostingController = UIHostingController(rootView: completionView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
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
