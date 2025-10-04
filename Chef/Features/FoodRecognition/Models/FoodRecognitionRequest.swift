//
//  FoodRecognitionRequest.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import Foundation
import UIKit

// MARK: - 食物辨識請求模型
/// 符合 API 規格的食物辨識請求結構
struct FoodRecognitionRequest: Codable {
    /// base64 編碼的圖片資料
    let image: String
    /// 可選的描述提示，幫助 AI 更準確辨識
    let descriptionHint: String

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case image
        case descriptionHint = "description_hint"
    }

    // MARK: - Initializers

    /// 使用 base64 字串初始化
    /// - Parameters:
    ///   - image: base64 編碼的圖片字串
    ///   - descriptionHint: 描述提示，預設為空字串
    init(image: String, descriptionHint: String = "") {
        self.image = image
        self.descriptionHint = descriptionHint
    }

    /// 使用 UIImage 初始化（會自動轉換為 base64）
    /// - Parameters:
    ///   - uiImage: UIImage 實例
    ///   - descriptionHint: 描述提示，預設為空字串
    ///   - compressionQuality: JPEG 壓縮品質（0.0-1.0），預設 0.7
    init?(uiImage: UIImage, descriptionHint: String = "", compressionQuality: CGFloat = 0.7) {
        guard let base64String = Self.convertImageToBase64(uiImage, compressionQuality: compressionQuality) else {
            return nil
        }
        self.image = base64String
        self.descriptionHint = descriptionHint
    }
}

// MARK: - Image Processing Extensions
extension FoodRecognitionRequest {

    /// 將 UIImage 轉換為 base64 編碼字串
    /// - Parameters:
    ///   - image: 要轉換的圖片
    ///   - compressionQuality: JPEG 壓縮品質
    /// - Returns: base64 編碼的字串，包含 data URI 前綴
    private static func convertImageToBase64(_ image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        // 先壓縮圖片以減少記憶體使用和傳輸時間
        let compressedImage = compressImage(image)

        // 轉換為 JPEG 資料
        guard let imageData = compressedImage.jpegData(compressionQuality: compressionQuality) else {
            print("❌ 無法將圖片轉換為 JPEG 資料")
            return nil
        }

        // 檢查圖片大小
        let imageSizeInMB = Double(imageData.count) / (1024 * 1024)
        print("📸 圖片大小：\(String(format: "%.2f", imageSizeInMB)) MB")

        if imageSizeInMB > 2.0 {
            print("⚠️ 警告：圖片大小超過 2MB，可能影響上傳速度")
        }

        // 轉換為 base64 並加上 data URI 前綴
        let base64String = imageData.base64EncodedString()
        return "data:image/jpeg;base64,\(base64String)"
    }

    /// 壓縮圖片到合理大小
    /// - Parameter image: 原始圖片
    /// - Returns: 壓縮後的圖片
    private static func compressImage(_ image: UIImage) -> UIImage {
        let maxSize: CGFloat = 1024 // 最大邊長

        // 如果圖片已經夠小，直接返回
        if image.size.width <= maxSize && image.size.height <= maxSize {
            return image
        }

        // 計算縮放比例
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        // 創建新的壓縮圖片
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let compressedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        print("📐 圖片壓縮：\(image.size) → \(compressedImage.size)")
        return compressedImage
    }
}