//
//  FoodRecognitionService.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import Foundation
import UIKit

// MARK: - 食物辨識服務協議
/// 定義食物辨識服務的公開介面
protocol FoodRecognitionServiceProtocol {
    /// 辨識食物圖片
    /// - Parameters:
    ///   - image: 要辨識的圖片
    ///   - hint: 可選的描述提示
    /// - Returns: 辨識結果
    func recognizeFood(image: UIImage, hint: String?) async throws -> FoodRecognitionResponse
}

// MARK: - 食物辨識服務實作
/// 封裝食物辨識的完整流程，提供簡潔的公開介面
final class FoodRecognitionService: FoodRecognitionServiceProtocol {

    // MARK: - Singleton
    static let shared = FoodRecognitionService()
    private init() {}

    // MARK: - Public Methods

    /// 辨識食物圖片的主要方法
    /// - Parameters:
    ///   - image: 要辨識的 UIImage
    ///   - hint: 可選的描述提示，幫助 AI 更準確辨識
    /// - Returns: 辨識結果
    /// - Throws: FoodRecognitionError 相關錯誤
    func recognizeFood(image: UIImage, hint: String? = nil) async throws -> FoodRecognitionResponse {
        print("🚀 開始食物辨識流程")

        do {
            // 1. 圖片預處理和壓縮
            let processedImage = preprocessImage(image)

            // 2. 建立請求物件
            guard let request = FoodRecognitionRequest(
                uiImage: processedImage,
                descriptionHint: hint ?? "",
                compressionQuality: 0.7
            ) else {
                print("❌ 無法建立食物辨識請求")
                throw FoodRecognitionError.imageProcessingFailed
            }

            // 3. 檢查圖片大小
            try validateImageSize(request.image)

            // 4. 發送 API 請求
            let response = try await RecipeService.recognizeFood(using: request)

            // 5. 驗證回應
            try validateResponse(response)

            print("✅ 食物辨識成功完成")
            return response

        } catch let error as NetworkError {
            print("❌ 網路錯誤：\(error)")
            throw mapNetworkError(error)
        } catch let error as FoodRecognitionError {
            print("❌ 食物辨識錯誤：\(error)")
            throw error
        } catch {
            print("❌ 未知錯誤：\(error)")
            throw FoodRecognitionError.unknown(error.localizedDescription)
        }
    }

    /// 批次辨識多張圖片
    /// - Parameters:
    ///   - images: 要辨識的圖片陣列
    ///   - hint: 統一的描述提示
    /// - Returns: 辨識結果陣列
    func recognizeMultipleFood(images: [UIImage], hint: String? = nil) async throws -> [FoodRecognitionResponse] {
        print("🚀 開始批次食物辨識，共 \(images.count) 張圖片")

        var results: [FoodRecognitionResponse] = []
        var errors: [Error] = []

        for (index, image) in images.enumerated() {
            do {
                print("📸 處理第 \(index + 1) 張圖片")
                let result = try await recognizeFood(image: image, hint: hint)
                results.append(result)
            } catch {
                print("❌ 第 \(index + 1) 張圖片辨識失敗：\(error)")
                errors.append(error)
            }
        }

        if results.isEmpty && !errors.isEmpty {
            // 如果所有圖片都失敗，拋出第一個錯誤
            throw errors.first!
        }

        print("✅ 批次辨識完成，成功 \(results.count) 張，失敗 \(errors.count) 張")
        return results
    }
}

// MARK: - Private Helper Methods
private extension FoodRecognitionService {

    /// 圖片預處理
    /// - Parameter image: 原始圖片
    /// - Returns: 處理後的圖片
    func preprocessImage(_ image: UIImage) -> UIImage {
        // 確保圖片方向正確
        let orientationCorrectedImage = image.fixOrientation()

        // 壓縮圖片尺寸（如果需要）
        let compressedImage = compressImageIfNeeded(orientationCorrectedImage)

        return compressedImage
    }

    /// 如果圖片過大則進行壓縮
    /// - Parameter image: 原始圖片
    /// - Returns: 壓縮後的圖片
    func compressImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let maxFileSize: Int = 2 * 1024 * 1024 // 2MB

        // 檢查尺寸
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }

            print("📐 圖片尺寸壓縮：\(image.size) → \(resizedImage.size)")
            return resizedImage
        }

        return image
    }

    /// 驗證圖片大小
    /// - Parameter base64String: base64 編碼的圖片字串
    /// - Throws: 如果圖片過大則拋出錯誤
    func validateImageSize(_ base64String: String) throws {
        let sizeInBytes = base64String.count
        let sizeInMB = Double(sizeInBytes) / (1024 * 1024)

        print("📏 Base64 圖片大小：\(String(format: "%.2f", sizeInMB)) MB")

        if sizeInMB > 5.0 { // 限制 5MB
            throw FoodRecognitionError.imageTooLarge
        }
    }

    /// 驗證 API 回應
    /// - Parameter response: API 回應
    /// - Throws: 如果回應無效則拋出錯誤
    func validateResponse(_ response: FoodRecognitionResponse) throws {
        if response.recognizedFoods.isEmpty {
            throw FoodRecognitionError.noResults
        }

        // 檢查是否有有效的食物名稱
        let validFoods = response.recognizedFoods.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if validFoods.isEmpty {
            throw FoodRecognitionError.noResults
        }
    }

    /// 將 NetworkError 映射為 FoodRecognitionError
    /// - Parameter networkError: 網路錯誤
    /// - Returns: 對應的食物辨識錯誤
    func mapNetworkError(_ networkError: NetworkError) -> FoodRecognitionError {
        switch networkError {
        case .invalidURL:
            return .apiError("無效的 API 地址")
        case .invalidResponse:
            return .apiError("無效的伺服器回應")
        case .httpError(let code):
            switch code {
            case 400:
                return .apiError("請求格式錯誤")
            case 401:
                return .apiError("未授權")
            case 413:
                return .imageTooLarge
            case 429:
                return .apiError("請求過於頻繁，請稍後再試")
            case 500...599:
                return .apiError("伺服器內部錯誤")
            default:
                return .apiError("HTTP 錯誤：\(code)")
            }
        case .noData:
            return .apiError("伺服器未回傳資料")
        case .unknown(let message):
            return .networkError(message)
        }
    }
}

// MARK: - UIImage Extensions
private extension UIImage {

    /// 修正圖片方向
    /// - Returns: 方向正確的圖片
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}