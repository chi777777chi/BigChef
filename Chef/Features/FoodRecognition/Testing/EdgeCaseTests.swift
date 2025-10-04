//
//  EdgeCaseTests.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//  邊界條件測試
//

import Foundation
import UIKit
import SwiftUI

/// 邊界條件測試類
/// 專門測試各種異常情況和邊界條件
@MainActor
final class EdgeCaseTests: ObservableObject {

    // MARK: - Published Properties
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false

    // MARK: - Test Result
    struct TestResult: Identifiable {
        let id = UUID()
        let testName: String
        let passed: Bool
        let details: String
        let timestamp: Date = Date()

        var emoji: String {
            passed ? "✅" : "❌"
        }
    }

    // MARK: - Public Methods

    /// 執行所有邊界條件測試
    func runAllEdgeCaseTests() async {
        isRunning = true
        testResults.removeAll()

        print("🔍 開始執行邊界條件測試")

        // 執行各種邊界條件測試
        await runTest("記憶體壓力測試", test: testMemoryPressure)
        await runTest("大圖片處理測試", test: testLargeImageHandling)
        await runTest("小圖片處理測試", test: testSmallImageHandling)
        await runTest("空值處理測試", test: testNullHandling)
        await runTest("快速連續操作測試", test: testRapidOperations)
        await runTest("狀態一致性測試", test: testStateConsistency)
        await runTest("錯誤恢復測試", test: testErrorRecovery)
        await runTest("資源清理測試", test: testResourceCleanup)

        isRunning = false
        printSummary()
    }

    // MARK: - Individual Tests

    /// 記憶體壓力測試
    private func testMemoryPressure() async -> (Bool, String) {
        do {
            let viewModel = FoodRecognitionViewModel()
            var images: [UIImage] = []

            // 創建多個大圖片
            for i in 1...10 {
                let image = createLargeTestImage(size: CGSize(width: 1000, height: 1000))
                images.append(image)
                viewModel.handleImageSelection(image)

                // 檢查記憶體使用
                let memoryUsage = getCurrentMemoryUsage()
                if memoryUsage > 200.0 { // 如果記憶體超過 200MB
                    return (false, "記憶體使用過高: \(String(format: "%.1f", memoryUsage))MB")
                }

                viewModel.clearSelection()

                // 給系統時間清理
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 秒
            }

            // 清理
            images.removeAll()
            viewModel.optimizeMemoryUsage()

            return (true, "記憶體壓力測試通過")
        } catch {
            return (false, "記憶體壓力測試失敗: \(error.localizedDescription)")
        }
    }

    /// 大圖片處理測試
    private func testLargeImageHandling() async -> (Bool, String) {
        let viewModel = FoodRecognitionViewModel()

        // 創建非常大的圖片
        let hugeImage = createLargeTestImage(size: CGSize(width: 4000, height: 3000))

        let startTime = CFAbsoluteTimeGetCurrent()
        viewModel.handleImageSelection(hugeImage)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        // 檢查是否正確處理
        guard viewModel.hasSelectedImage else {
            return (false, "大圖片沒有被正確處理")
        }

        // 檢查處理時間是否合理
        if processingTime > 5.0 {
            return (false, "大圖片處理時間過長: \(String(format: "%.2f", processingTime))秒")
        }

        // 檢查記憶體使用
        let memoryUsage = getCurrentMemoryUsage()
        if memoryUsage > 150.0 {
            return (false, "大圖片處理記憶體使用過高: \(String(format: "%.1f", memoryUsage))MB")
        }

        return (true, "大圖片處理正常，處理時間: \(String(format: "%.2f", processingTime))秒")
    }

    /// 小圖片處理測試
    private func testSmallImageHandling() async -> (Bool, String) {
        let viewModel = FoodRecognitionViewModel()

        // 創建很小的圖片
        let tinyImage = createTestImage(size: CGSize(width: 10, height: 10))

        viewModel.handleImageSelection(tinyImage)

        // 檢查是否正確處理
        guard viewModel.hasSelectedImage else {
            return (false, "小圖片沒有被正確處理")
        }

        return (true, "小圖片處理正常")
    }

    /// 空值處理測試
    private func testNullHandling() async -> (Bool, String) {
        let viewModel = FoodRecognitionViewModel()

        // 測試沒有圖片時嘗試辨識
        viewModel.recognizeFood()

        // 應該不會崩潰，且狀態保持合理
        if viewModel.recognitionStatus == .loading {
            return (false, "空值情況下不應該進入載入狀態")
        }

        // 測試清除空選擇
        viewModel.clearSelection()

        return (true, "空值處理正常")
    }

    /// 快速連續操作測試
    private func testRapidOperations() async -> (Bool, String) {
        let viewModel = FoodRecognitionViewModel()
        let testImage = createTestImage(size: CGSize(width: 300, height: 300))

        let startTime = CFAbsoluteTimeGetCurrent()

        // 快速連續執行多個操作
        for _ in 1...20 {
            viewModel.selectImageSource()
            viewModel.dismissPickers()
            viewModel.handleImageSelection(testImage)
            viewModel.clearSelection()
        }

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = totalTime / 20

        // 檢查平均響應時間
        if averageTime > 0.1 {
            return (false, "快速操作響應過慢，平均時間: \(String(format: "%.3f", averageTime))秒")
        }

        return (true, "快速連續操作正常，平均響應時間: \(String(format: "%.3f", averageTime))秒")
    }

    /// 狀態一致性測試
    private func testStateConsistency() async -> (Bool, String) {
        let viewModel = FoodRecognitionViewModel()
        let testImage = createTestImage(size: CGSize(width: 300, height: 300))

        // 測試狀態轉換的一致性
        var inconsistencies: [String] = []

        // 初始狀態檢查
        if viewModel.hasSelectedImage && viewModel.selectedImage == nil {
            inconsistencies.append("hasSelectedImage 與 selectedImage 不一致")
        }

        // 選擇圖片後的狀態檢查
        viewModel.handleImageSelection(testImage)
        if !viewModel.hasSelectedImage || viewModel.selectedImage == nil {
            inconsistencies.append("選擇圖片後狀態不一致")
        }

        // 清除後的狀態檢查
        viewModel.clearSelection()
        if viewModel.hasSelectedImage || viewModel.selectedImage != nil {
            inconsistencies.append("清除後狀態不一致")
        }

        if !inconsistencies.isEmpty {
            return (false, "狀態一致性問題: \(inconsistencies.joined(separator: ", "))")
        }

        return (true, "狀態一致性正常")
    }

    /// 錯誤恢復測試
    private func testErrorRecovery() async -> (Bool, String) {
        let viewModel = FoodRecognitionViewModel()

        // 初始狀態應該沒有錯誤
        if viewModel.hasError {
            return (false, "初始狀態不應該有錯誤")
        }

        // 測試錯誤清除功能（即使沒有錯誤也應該能正常調用）
        viewModel.clearError()

        // 測試 resetAll 功能
        viewModel.resetAll()

        if viewModel.hasError {
            return (false, "重置後仍有錯誤")
        }

        return (true, "錯誤恢復機制正常")
    }

    /// 資源清理測試
    private func testResourceCleanup() async -> (Bool, String) {
        let viewModel = FoodRecognitionViewModel()
        let testImage = createTestImage(size: CGSize(width: 500, height: 500))

        // 設置一些狀態
        viewModel.handleImageSelection(testImage)
        viewModel.updateDescriptionHint("測試描述")

        // 執行資源清理
        viewModel.cleanupAllResources()

        // 檢查清理結果
        var failures: [String] = []

        if viewModel.selectedImage != nil {
            failures.append("圖片未清理")
        }

        if viewModel.recognitionResult != nil {
            failures.append("辨識結果未清理")
        }

        if viewModel.error != nil {
            failures.append("錯誤狀態未清理")
        }

        if viewModel.uploadProgress != 0.0 {
            failures.append("上傳進度未重置")
        }

        if !failures.isEmpty {
            return (false, "資源清理不完整: \(failures.joined(separator: ", "))")
        }

        return (true, "資源清理正常")
    }

    // MARK: - Helper Methods

    private func runTest(_ name: String, test: () async -> (Bool, String)) async {
        print("🧪 執行測試: \(name)")
        let (passed, details) = await test()

        let result = TestResult(
            testName: name,
            passed: passed,
            details: details
        )

        testResults.append(result)
        print("\(result.emoji) \(name): \(details)")
    }

    private func printSummary() {
        let total = testResults.count
        let passed = testResults.filter { $0.passed }.count
        let failed = total - passed

        print("\n📊 邊界條件測試總結:")
        print("   總計: \(total)")
        print("   通過: \(passed) ✅")
        print("   失敗: \(failed) ❌")

        if failed == 0 {
            print("🎉 所有邊界條件測試通過！")
        } else {
            print("⚠️ 發現 \(failed) 個問題需要修復")
        }
    }

    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // 添加一些內容使其更真實
            UIColor.white.setFill()
            let centerRect = CGRect(
                x: size.width * 0.25,
                y: size.height * 0.25,
                width: size.width * 0.5,
                height: size.height * 0.5
            )
            context.fill(centerRect)
        }
    }

    private func createLargeTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 創建漸變背景使圖片更大
            for i in 0..<Int(size.width) {
                let color = UIColor(
                    hue: CGFloat(i) / size.width,
                    saturation: 0.5,
                    brightness: 0.8,
                    alpha: 1.0
                )
                color.setFill()
                context.fill(CGRect(x: CGFloat(i), y: 0, width: 1, height: size.height))
            }
        }
    }

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
}

// MARK: - Edge Case Test View

struct EdgeCaseTestView: View {
    @StateObject private var edgeTests = EdgeCaseTests()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("邊界條件測試")
                        .font(.title2)
                        .fontWeight(.bold)

                    if edgeTests.isRunning {
                        ProgressView("執行測試中...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }

                // Test Results
                List(edgeTests.testResults) { result in
                    HStack {
                        Text(result.emoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.testName)
                                .font(.headline)

                            Text(result.details)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                // Controls
                VStack(spacing: 12) {
                    Button("執行邊界條件測試") {
                        Task {
                            await edgeTests.runAllEdgeCaseTests()
                        }
                    }
                    .disabled(edgeTests.isRunning)
                    .buttonStyle(.borderedProminent)

                    if !edgeTests.testResults.isEmpty {
                        let passedCount = edgeTests.testResults.filter { $0.passed }.count
                        let totalCount = edgeTests.testResults.count

                        Text("通過率: \(passedCount)/\(totalCount) (\(Int(Double(passedCount)/Double(totalCount)*100))%)")
                            .font(.headline)
                            .foregroundColor(passedCount == totalCount ? .green : .orange)
                    }
                }
                .padding()
            }
            .navigationTitle("邊界測試")
        }
    }
}

#Preview {
    EdgeCaseTestView()
}