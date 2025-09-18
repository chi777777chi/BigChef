//
//  FoodRecognitionState.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import Foundation
import SwiftUI

// MARK: - 食物辨識狀態管理
/// 集中管理食物辨識功能的所有狀態
@MainActor
final class FoodRecognitionState: ObservableObject {

    // MARK: - Published Properties

    /// 當前的辨識狀態
    @Published var recognitionStatus: RecognitionStatus = .idle
    /// 選中的圖片
    @Published var selectedImage: UIImage?
    /// 辨識結果
    @Published var recognitionResult: FoodRecognitionResponse?
    /// 錯誤資訊
    @Published var error: FoodRecognitionError?
    /// 是否顯示圖片選擇器
    @Published var showImagePicker = false
    /// 是否顯示相機
    @Published var showCamera = false
    /// 使用者輸入的描述提示
    @Published var descriptionHint = ""

    // MARK: - Computed Properties

    /// 是否正在載入中
    var isLoading: Bool {
        recognitionStatus == .loading
    }

    /// 是否有錯誤
    var hasError: Bool {
        error != nil
    }

    /// 是否有辨識結果
    var hasResult: Bool {
        recognitionResult?.hasResults == true
    }

    /// 是否有選中的圖片
    var hasSelectedImage: Bool {
        selectedImage != nil
    }

    /// 當前狀態描述
    var statusDescription: String {
        switch recognitionStatus {
        case .idle:
            return "請選擇要辨識的食物圖片"
        case .loading:
            return "正在辨識中..."
        case .success:
            return recognitionResult?.summary ?? "辨識完成"
        case .error:
            return error?.localizedDescription ?? "辨識失敗"
        }
    }

    // MARK: - State Management Methods

    /// 設定為載入狀態
    func setLoading() {
        recognitionStatus = .loading
        error = nil
    }

    /// 設定辨識成功
    /// - Parameter result: 辨識結果
    func setSuccess(with result: FoodRecognitionResponse) {
        recognitionStatus = .success
        recognitionResult = result
        error = nil
    }

    /// 設定辨識失敗
    /// - Parameter error: 錯誤資訊
    func setError(_ error: FoodRecognitionError) {
        recognitionStatus = .error
        self.error = error
        recognitionResult = nil
    }

    /// 重置所有狀態
    func reset() {
        recognitionStatus = .idle
        selectedImage = nil
        recognitionResult = nil
        error = nil
        showImagePicker = false
        showCamera = false
        descriptionHint = ""
    }

    /// 清除錯誤狀態
    func clearError() {
        error = nil
        if recognitionStatus == .error {
            recognitionStatus = .idle
        }
    }

    /// 設定選中的圖片
    /// - Parameter image: 選中的圖片
    func setSelectedImage(_ image: UIImage) {
        selectedImage = image
        // 清除之前的結果和錯誤
        recognitionResult = nil
        error = nil
        if recognitionStatus != .loading {
            recognitionStatus = .idle
        }
    }

    // MARK: - UI Action Methods

    /// 顯示圖片選擇器
    func showPhotoLibrary() {
        showImagePicker = true
        showCamera = false
    }

    /// 顯示相機
    func showCameraView() {
        showCamera = true
        showImagePicker = false
    }

    /// 隱藏所有選擇器
    func dismissPickers() {
        showImagePicker = false
        showCamera = false
    }
}

// MARK: - Recognition Status Enum
/// 辨識狀態枚舉
enum RecognitionStatus: Equatable {
    /// 閒置狀態，等待使用者操作
    case idle
    /// 正在辨識中
    case loading
    /// 辨識成功
    case success
    /// 辨識失敗
    case error

    /// 狀態圖示
    var icon: String {
        switch self {
        case .idle:
            return "camera.viewfinder"
        case .loading:
            return "hourglass"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    /// 狀態顏色
    var color: Color {
        switch self {
        case .idle:
            return .blue
        case .loading:
            return .orange
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - Food Recognition Error
/// 食物辨識相關錯誤
enum FoodRecognitionError: LocalizedError, Equatable {
    /// 圖片處理錯誤
    case imageProcessingFailed
    /// 網路請求失敗
    case networkError(String)
    /// API 回應錯誤
    case apiError(String)
    /// 資料解析錯誤
    case decodingError
    /// 無辨識結果
    case noResults
    /// 圖片過大
    case imageTooLarge
    /// 未知錯誤
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "圖片處理失敗，請重新選擇圖片"
        case .networkError(let message):
            return "網路錯誤：\(message)"
        case .apiError(let message):
            return "服務錯誤：\(message)"
        case .decodingError:
            return "資料解析失敗，請稍後再試"
        case .noResults:
            return "無法辨識此圖片中的食物"
        case .imageTooLarge:
            return "圖片檔案過大，請選擇較小的圖片"
        case .unknown(let message):
            return "未知錯誤：\(message)"
        }
    }

    /// 錯誤類型
    var category: ErrorCategory {
        switch self {
        case .imageProcessingFailed, .imageTooLarge:
            return .client
        case .networkError:
            return .network
        case .apiError, .decodingError, .noResults:
            return .server
        case .unknown:
            return .unknown
        }
    }
}

// MARK: - Error Category
/// 錯誤分類
enum ErrorCategory {
    /// 客戶端錯誤（使用者操作或本地處理問題）
    case client
    /// 網路錯誤
    case network
    /// 伺服器錯誤
    case server
    /// 未知錯誤
    case unknown

    /// 是否可重試
    var isRetryable: Bool {
        switch self {
        case .client:
            return false // 客戶端錯誤通常需要使用者重新操作
        case .network, .server, .unknown:
            return true // 網路和伺服器錯誤可以重試
        }
    }
}