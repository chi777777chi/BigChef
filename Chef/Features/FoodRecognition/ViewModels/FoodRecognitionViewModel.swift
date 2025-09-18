//
//  FoodRecognitionViewModel.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FoodRecognitionViewModel: ObservableObject {

    // MARK: - Dependencies
    private let foodRecognitionService: FoodRecognitionServiceProtocol
    private let state: FoodRecognitionState

    // MARK: - Published Properties (從 State 導出)
    @Published var recognitionStatus: RecognitionStatus = .idle
    @Published var selectedImage: UIImage?
    @Published var recognitionResult: FoodRecognitionResponse?
    @Published var error: FoodRecognitionError?
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var descriptionHint = ""

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var isLoading: Bool {
        recognitionStatus == .loading
    }

    var hasError: Bool {
        error != nil
    }

    var hasResult: Bool {
        recognitionResult?.hasResults == true
    }

    var hasSelectedImage: Bool {
        selectedImage != nil
    }

    var statusDescription: String {
        switch recognitionStatus {
        case .idle:
            return hasSelectedImage ? "點擊辨識按鈕開始辨識" : "請選擇要辨識的食物圖片"
        case .loading:
            return "正在辨識中..."
        case .success:
            return recognitionResult?.summary ?? "辨識完成"
        case .error:
            return error?.localizedDescription ?? "辨識失敗"
        }
    }

    /// 取得主要辨識結果
    var primaryResult: RecognizedFood? {
        recognitionResult?.primaryFood
    }

    /// 檢查錯誤是否可重試
    var isErrorRetryable: Bool {
        error?.category.isRetryable == true
    }

    // MARK: - Initialization

    init(
        foodRecognitionService: FoodRecognitionServiceProtocol = FoodRecognitionService.shared,
        state: FoodRecognitionState? = nil
    ) {
        self.foodRecognitionService = foodRecognitionService
        self.state = state ?? FoodRecognitionState()
        setupBindings()
    }

    // MARK: - Private Setup

    private func setupBindings() {
        // 綁定 state 的變化到 published 屬性
        state.$recognitionStatus
            .assign(to: \.recognitionStatus, on: self)
            .store(in: &cancellables)

        state.$selectedImage
            .assign(to: \.selectedImage, on: self)
            .store(in: &cancellables)

        state.$recognitionResult
            .assign(to: \.recognitionResult, on: self)
            .store(in: &cancellables)

        state.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)

        state.$showImagePicker
            .assign(to: \.showImagePicker, on: self)
            .store(in: &cancellables)

        state.$showCamera
            .assign(to: \.showCamera, on: self)
            .store(in: &cancellables)

        state.$descriptionHint
            .assign(to: \.descriptionHint, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// 處理圖片選擇
    /// - Parameter image: 選中的圖片
    func handleImageSelection(_ image: UIImage) {
        print("📸 使用者選擇了圖片")
        state.setSelectedImage(image)
    }

    /// 開始辨識食物
    func recognizeFood() {
        guard let image = selectedImage else {
            print("❌ 沒有選中的圖片")
            return
        }

        Task {
            await performRecognition(image: image, hint: descriptionHint.isEmpty ? nil : descriptionHint)
        }
    }

    /// 重新辨識
    func retryRecognition() {
        guard let image = selectedImage else {
            print("❌ 沒有可重新辨識的圖片")
            return
        }

        clearError()
        Task {
            await performRecognition(image: image, hint: descriptionHint.isEmpty ? nil : descriptionHint)
        }
    }

    /// 顯示相機
    func showCameraAction() {
        state.showCameraView()
    }

    /// 顯示相簿
    func showPhotoLibraryAction() {
        state.showPhotoLibrary()
    }

    /// 清除選擇的圖片和結果
    func clearSelection() {
        state.reset()
    }

    /// 清除錯誤狀態
    func clearError() {
        state.clearError()
    }

    /// 更新描述提示
    /// - Parameter hint: 新的描述提示
    func updateDescriptionHint(_ hint: String) {
        state.descriptionHint = hint
    }

    /// 隱藏選擇器
    func dismissPickers() {
        state.dismissPickers()
    }

    // MARK: - Private Methods

    /// 執行辨識流程
    /// - Parameters:
    ///   - image: 要辨識的圖片
    ///   - hint: 描述提示
    private func performRecognition(image: UIImage, hint: String?) async {
        print("🚀 開始執行食物辨識")
        state.setLoading()

        do {
            let result = try await foodRecognitionService.recognizeFood(image: image, hint: hint)
            print("✅ 辨識成功")
            state.setSuccess(with: result)

            // 記錄辨識結果以供分析
            logRecognitionResult(result)

        } catch let error as FoodRecognitionError {
            print("❌ 辨識失敗：\(error)")
            state.setError(error)
        } catch {
            print("❌ 未知錯誤：\(error)")
            let recognitionError = FoodRecognitionError.unknown(error.localizedDescription)
            state.setError(recognitionError)
        }
    }

    /// 記錄辨識結果（用於除錯和分析）
    /// - Parameter result: 辨識結果
    private func logRecognitionResult(_ result: FoodRecognitionResponse) {
        print("📊 辨識結果統計：")
        print("   - 食物數量：\(result.recognizedFoods.count)")
        print("   - 總食材數量：\(result.allIngredients.count)")
        print("   - 總設備數量：\(result.allEquipment.count)")

        if let primary = result.primaryFood {
            print("   - 主要食物：\(primary.name)")
            print("   - 主要食材：\(primary.mainIngredients.count) 個")
            print("   - 調料：\(primary.seasonings.count) 個")
            print("   - 必需設備：\(primary.essentialEquipment.count) 個")
        }
    }
}

// MARK: - Convenience Methods
extension FoodRecognitionViewModel {

    /// 取得所有辨識出的食材
    var allIngredients: [Ingredient] {
        recognitionResult?.allIngredients ?? []
    }

    /// 取得所有辨識出的設備
    var allEquipment: [Equipment] {
        recognitionResult?.allEquipment ?? []
    }

    /// 取得食物名稱列表
    var foodNames: [String] {
        recognitionResult?.foodNames ?? []
    }

    /// 檢查是否可以開始辨識
    var canStartRecognition: Bool {
        hasSelectedImage && !isLoading
    }

    /// 檢查是否應該顯示結果
    var shouldShowResults: Bool {
        hasResult && recognitionStatus == .success
    }

    /// 檢查是否應該顯示錯誤
    var shouldShowError: Bool {
        hasError && recognitionStatus == .error
    }
}