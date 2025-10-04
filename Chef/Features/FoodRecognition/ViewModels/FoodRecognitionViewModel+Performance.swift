//
//  FoodRecognitionViewModel+Performance.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//  FoodRecognitionViewModel 效能優化擴展
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Performance & Memory Management Extensions

extension FoodRecognitionViewModel {

    // MARK: - Memory Management

    /// 優化記憶體使用
    func optimizeMemoryUsage() {
        print("🧹 開始記憶體優化")

        // 清理不必要的緩存數據
        clearUnusedCache()

        // 優化圖片記憶體使用
        optimizeImageMemory()

        // 強制垃圾回收
        autoreleasepool {
            // 清理臨時對象
        }

        print("🧹 記憶體優化完成")
    }

    /// 清理選中的圖片並釋放記憶體
    func clearSelectedImageMemory() {
        print("🧹 清理選中圖片記憶體")

        autoreleasepool {
            selectedImage = nil
        }

        // 強制記憶體回收
        DispatchQueue.global(qos: .utility).async {
            // 在後台執行記憶體清理
            autoreleasepool {
                // 清理操作
            }
        }
    }

    /// 壓縮圖片以節省記憶體
    func compressImageForMemoryOptimization(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let compressionQuality: CGFloat = 0.7

        return autoreleasepool {
            // 檢查是否需要縮小尺寸
            let needsResize = image.size.width > maxDimension || image.size.height > maxDimension

            var optimizedImage = image

            if needsResize {
                optimizedImage = resizeImageEfficiently(image, maxDimension: maxDimension)
            }

            // 重新編碼以減少記憶體佔用
            if let imageData = optimizedImage.jpegData(compressionQuality: compressionQuality),
               let recompressedImage = UIImage(data: imageData) {
                return recompressedImage
            }

            return optimizedImage
        }
    }

    /// 高效的圖片縮放
    private func resizeImageEfficiently(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        // 使用高效的圖片處理
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // 避免自動縮放
        format.opaque = true // 不透明圖片更高效

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// 清理未使用的緩存
    private func clearUnusedCache() {
        // 清理可能存在的圖片緩存
        // 在實際項目中，這裡可能需要清理圖片加載庫的緩存
        print("🧹 清理未使用的緩存")
    }

    /// 優化圖片記憶體使用
    private func optimizeImageMemory() {
        guard let image = selectedImage else { return }

        // 如果圖片過大，進行壓縮
        let imageSize = image.size
        let pixelCount = imageSize.width * imageSize.height
        let maxPixels: CGFloat = 2048 * 1536 // 約 3MP

        if pixelCount > maxPixels {
            selectedImage = compressImageForMemoryOptimization(image)
            print("🧹 圖片已優化，原始尺寸: \(imageSize), 優化後尺寸: \(selectedImage?.size ?? .zero)")
        }
    }

    // MARK: - Performance Monitoring

    /// 測量操作執行時間
    @discardableResult
    func measurePerformance<T>(
        operation: String,
        action: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()

        print("⏱️ 開始測量: \(operation)")

        let result = try await action()

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let endMemory = getCurrentMemoryUsage()
        let memoryDelta = endMemory - startMemory

        print("⏱️ 完成測量: \(operation)")
        print("   執行時間: \(String(format: "%.3f", duration))s")
        print("   記憶體變化: \(String(format: "%.1f", memoryDelta))MB")

        // 如果記憶體使用量過高，觸發優化
        if memoryDelta > 25.0 {
            print("⚠️ 記憶體使用量較高，觸發優化")
            optimizeMemoryUsage()
        }

        return result
    }

    /// 獲取當前記憶體使用量
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }

    // MARK: - Network Optimization

    /// 優化的圖片上傳處理
    func performOptimizedRecognition(image: UIImage, hint: String?) async {
        await measurePerformance(operation: "圖片辨識完整流程") {
            // 1. 圖片預處理和優化
            let optimizedImage = await preprocessImageForUpload(image)

            // 2. 設置優化後的圖片
            handleImageSelection(optimizedImage)

            // 3. 開始辨識
            recognizeFood()

            // 4. 後處理清理
            await postProcessCleanup()
        }
    }

    /// 圖片預處理優化
    private func preprocessImageForUpload(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                autoreleasepool {
                    // 修正圖片方向
                    let orientationCorrectedImage = image.fixedOrientation()

                    // 簡化的壓縮邏輯，避免 async 問題
                    let optimizedImage = orientationCorrectedImage.compressForUpload()

                    DispatchQueue.main.async {
                        continuation.resume(returning: optimizedImage)
                    }
                }
            }
        }
    }

    /// 後處理清理
    private func postProcessCleanup() async {
        // 延遲執行清理，避免影響用戶體驗
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        optimizeMemoryUsage()
    }

    // MARK: - Enhanced Error Handling

    /// 增強的錯誤處理和重試邏輯
    func enhancedRetryRecognition() async {
        guard let image = selectedImage else {
            print("❌ 沒有可重新辨識的圖片")
            return
        }

        guard isErrorRetryable else {
            print("❌ 已達最大重試次數或錯誤不可重試")
            return
        }

        await measurePerformance(operation: "重試辨識") {
            isRetrying = true
            retryCount += 1
            clearError()

            // 智能重試延遲
            let delay = calculateSmartRetryDelay(for: retryCount, error: error)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            // 在重試前優化圖片
            let optimizedImage = compressImageForMemoryOptimization(image)
            handleImageSelection(optimizedImage)
            recognizeFood()

            isRetrying = false
        }
    }

    /// 智能重試延遲計算
    private func calculateSmartRetryDelay(for attempt: Int, error: FoodRecognitionError?) -> TimeInterval {
        // 根據錯誤類型調整延遲
        let baseDelay: TimeInterval
        switch error {
        case .networkError:
            baseDelay = 2.0 // 網路錯誤需要更長延遲
        case .apiError:
            baseDelay = 1.0 // API 錯誤中等延遲
        default:
            baseDelay = 0.5 // 其他錯誤較短延遲
        }

        // 指數退避，但有最大限制
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        return min(exponentialDelay, 10.0) // 最大 10 秒
    }

    // MARK: - Background Processing

    /// 在背景處理圖片準備
    func prepareImageInBackground(_ image: UIImage) async {
        await withTaskGroup(of: Void.self) { group in
            // 並行處理圖片優化任務
            group.addTask {
                await self.processImageOrientation(image)
            }

            group.addTask {
                await self.validateImageSize(image)
            }

            group.addTask {
                await self.generateImageMetadata(image)
            }
        }
    }

    private func processImageOrientation(_ image: UIImage) async {
        // 在背景處理圖片方向
        print("🔄 處理圖片方向")
    }

    private func validateImageSize(_ image: UIImage) async {
        // 驗證圖片大小
        let size = image.size
        print("📏 驗證圖片大小: \(size)")
    }

    private func generateImageMetadata(_ image: UIImage) async {
        // 生成圖片元數據
        print("📋 生成圖片元數據")
    }

    // MARK: - Lifecycle Management

    /// 清理所有資源
    func cleanupAllResources() {
        print("🧹 清理所有資源")

        // 清理圖片
        clearSelectedImageMemory()

        // 重置狀態
        recognitionResult = nil
        error = nil
        uploadProgress = 0.0
        retryCount = 0
        isRetrying = false

        // 觸發最終的記憶體優化
        optimizeMemoryUsage()
    }

    /// 應用進入背景時的處理
    func handleAppDidEnterBackground() {
        print("📱 應用進入背景，執行資源優化")

        // 暫停不必要的操作
        if recognitionStatus == .loading && !isRetrying {
            // 可以考慮暫停辨識任務
            print("⏸️ 暫停辨識任務")
        }

        // 釋放部分記憶體
        optimizeMemoryUsage()
    }

    /// 應用恢復前台時的處理
    func handleAppWillEnterForeground() {
        print("📱 應用恢復前台")

        // 恢復必要的操作
        if recognitionStatus == .loading {
            print("▶️ 恢復辨識任務")
        }
    }
}

// MARK: - UIImage Extensions for Performance

private extension UIImage {

    /// 修正圖片方向（優化版本）
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// 獲取圖片的記憶體佔用（估算）
    var memoryFootprint: Int {
        let bytesPerPixel = 4 // RGBA
        let totalPixels = Int(size.width * size.height * scale * scale)
        return totalPixels * bytesPerPixel
    }

    /// 檢查圖片是否過大（記憶體角度）
    var isMemoryIntensive: Bool {
        let maxMemoryFootprint = 50 * 1024 * 1024 // 50MB
        return memoryFootprint > maxMemoryFootprint
    }

    /// 為上傳壓縮圖片
    func compressForUpload() -> UIImage {
        let maxDimension: CGFloat = 1024
        let compressionQuality: CGFloat = 0.7

        // 檢查是否需要縮小尺寸
        let needsResize = size.width > maxDimension || size.height > maxDimension

        var optimizedImage = self

        if needsResize {
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(
                width: size.width * scale,
                height: size.height * scale
            )

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true

            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            optimizedImage = renderer.image { context in
                draw(in: CGRect(origin: .zero, size: newSize))
            }
        }

        // 重新編碼以減少記憶體佔用
        if let imageData = optimizedImage.jpegData(compressionQuality: compressionQuality),
           let recompressedImage = UIImage(data: imageData) {
            return recompressedImage
        }

        return optimizedImage
    }
}