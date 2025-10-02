//
//  ScanViewController.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/7.
//


import UIKit

/// 掃描設備 / 食材畫面：
/// 目前只先顯示 AR 預覽，日後再加掃描框、Vision OCR 等功能
@MainActor
final class ScanViewController: BaseCameraViewController<ARSessionAdapter> {
    private let state = ScanningState()
    private let viewModel: ScanningViewModel

    // MARK: - Init
    init() {
        self.viewModel = ScanningViewModel(
            state: state,
            onNavigateToRecipe: { _ in }
        )
        super.init(session: ARSessionAdapter())
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // 這裡先放一個半透明提示文字，之後可換成掃描框或 Lottie 動畫
        let label = UILabel()
        label.text = "將相機對準器具或食材…"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])

        // 使用空的偏好設定初始化
        setupEmptyState()
    }

    private func setupEmptyState() {
        Task {
            _ = Preference(
                cooking_method: "",
                dietary_restrictions: [],
                serving_size: "1人份"
            )
            await viewModel.generateRecipe()
        }
    }
}
