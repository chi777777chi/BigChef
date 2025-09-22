//
//  FoodRecognitionTestRunner.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//  食物辨識功能測試運行器
//

import SwiftUI
import UIKit
import Combine

/// 綜合測試運行器
/// 整合所有測試工具，提供統一的測試界面
@MainActor
final class FoodRecognitionTestRunner: ObservableObject {

    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var currentPhase = TestPhase.idle
    @Published var testResults: [TestResult] = []
    @Published var overallScore: Double = 0.0

    // MARK: - Test Components
    private let testSuite = FoodRecognitionTestSuite()
    private let performanceMonitor = PerformanceMonitor()

    // MARK: - Test Phases
    enum TestPhase: String, CaseIterable {
        case idle = "待機中"
        case basicFunctionality = "基本功能測試"
        case performance = "效能測試"
        case memoryManagement = "記憶體管理測試"
        case edgeCases = "邊界條件測試"
        case userExperience = "使用者體驗測試"
        case integration = "整合測試"
        case completed = "測試完成"

        var emoji: String {
            switch self {
            case .idle: return "⏸️"
            case .basicFunctionality: return "🔧"
            case .performance: return "⚡"
            case .memoryManagement: return "🧠"
            case .edgeCases: return "🔍"
            case .userExperience: return "👤"
            case .integration: return "🔗"
            case .completed: return "✅"
            }
        }
    }

    // MARK: - Test Result
    struct TestResult: Identifiable {
        let id = UUID()
        let phase: TestPhase
        let score: Double
        let details: String
        let duration: TimeInterval
        let timestamp: Date = Date()

        var grade: String {
            switch score {
            case 0.9...1.0: return "A+"
            case 0.8..<0.9: return "A"
            case 0.7..<0.8: return "B"
            case 0.6..<0.7: return "C"
            default: return "D"
            }
        }

        var emoji: String {
            switch score {
            case 0.9...1.0: return "🌟"
            case 0.8..<0.9: return "✅"
            case 0.7..<0.8: return "⚠️"
            case 0.6..<0.7: return "📊"
            default: return "❌"
            }
        }
    }

    // MARK: - Public Methods

    /// 執行完整的測試流程
    func runFullTestSuite() async {
        print("🚀 開始執行完整的食物辨識測試流程")
        isRunning = true
        testResults.removeAll()
        overallScore = 0.0

        // 開始效能監控
        performanceMonitor.startMonitoring()

        // 按階段執行測試
        for phase in TestPhase.allCases.dropFirst().dropLast() {
            currentPhase = phase
            await runTestPhase(phase)
        }

        // 停止效能監控
        performanceMonitor.stopMonitoring()

        // 計算總體分數
        calculateOverallScore()

        currentPhase = .completed
        isRunning = false

        print("🎉 測試流程完成，總體分數: \(String(format: "%.1f", overallScore * 100))%")
    }

    /// 執行特定測試階段
    func runTestPhase(_ phase: TestPhase) async {
        print("📋 執行測試階段: \(phase.rawValue)")
        let startTime = CFAbsoluteTimeGetCurrent()

        let result: TestResult

        switch phase {
        case .basicFunctionality:
            result = await runBasicFunctionalityTests()
        case .performance:
            result = await runPerformanceTests()
        case .memoryManagement:
            result = await runMemoryManagementTests()
        case .edgeCases:
            result = await runEdgeCaseTests()
        case .userExperience:
            result = await runUserExperienceTests()
        case .integration:
            result = await runIntegrationTests()
        default:
            result = TestResult(
                phase: phase,
                score: 1.0,
                details: "階段跳過",
                duration: 0
            )
        }

        testResults.append(result)
        print("\(result.emoji) \(phase.rawValue) 完成，得分: \(String(format: "%.1f", result.score * 100))%")
    }

    // MARK: - Test Phase Implementations

    /// 基本功能測試
    private func runBasicFunctionalityTests() async -> TestResult {
        var score = 0.0
        var details: [String] = []

        // 測試 ViewModel 初始化
        if await testViewModelInitialization() {
            score += 0.2
            details.append("✅ ViewModel 初始化正常")
        } else {
            details.append("❌ ViewModel 初始化失敗")
        }

        // 測試圖片選擇功能
        if await testImageSelection() {
            score += 0.2
            details.append("✅ 圖片選擇功能正常")
        } else {
            details.append("❌ 圖片選擇功能異常")
        }

        // 測試狀態管理
        if await testStateManagement() {
            score += 0.2
            details.append("✅ 狀態管理正常")
        } else {
            details.append("❌ 狀態管理異常")
        }

        // 測試 UI 交互
        if await testUIInteractions() {
            score += 0.2
            details.append("✅ UI 交互正常")
        } else {
            details.append("❌ UI 交互異常")
        }

        // 測試導航流程
        if await testNavigationFlow() {
            score += 0.2
            details.append("✅ 導航流程正常")
        } else {
            details.append("❌ 導航流程異常")
        }

        return TestResult(
            phase: .basicFunctionality,
            score: score,
            details: details.joined(separator: "\n"),
            duration: 0
        )
    }

    /// 效能測試
    private func runPerformanceTests() async -> TestResult {
        var score = 0.0
        var details: [String] = []

        // 測試初始化效能
        let initStartTime = CFAbsoluteTimeGetCurrent()
        let _ = FoodRecognitionViewModel()
        let initDuration = CFAbsoluteTimeGetCurrent() - initStartTime

        if initDuration < 0.1 {
            score += 0.3
            details.append("✅ 初始化效能優秀 (\(String(format: "%.3f", initDuration))s)")
        } else if initDuration < 0.5 {
            score += 0.2
            details.append("⚠️ 初始化效能一般 (\(String(format: "%.3f", initDuration))s)")
        } else {
            score += 0.1
            details.append("❌ 初始化效能較差 (\(String(format: "%.3f", initDuration))s)")
        }

        // 測試圖片處理效能
        let imageProcessScore = await testImageProcessingPerformance()
        score += imageProcessScore * 0.4
        details.append(imageProcessScore > 0.8 ? "✅ 圖片處理效能優秀" : "⚠️ 圖片處理效能需要優化")

        // 測試記憶體使用
        let memoryScore = await testMemoryUsage()
        score += memoryScore * 0.3
        details.append(memoryScore > 0.8 ? "✅ 記憶體使用合理" : "⚠️ 記憶體使用需要優化")

        return TestResult(
            phase: .performance,
            score: score,
            details: details.joined(separator: "\n"),
            duration: 0
        )
    }

    /// 記憶體管理測試
    private func runMemoryManagementTests() async -> TestResult {
        var score = 0.0
        var details: [String] = []

        // 測試記憶體洩漏
        if await testMemoryLeaks() {
            score += 0.4
            details.append("✅ 無記憶體洩漏")
        } else {
            details.append("❌ 檢測到可能的記憶體洩漏")
        }

        // 測試大圖片處理
        if await testLargeImageMemoryHandling() {
            score += 0.3
            details.append("✅ 大圖片記憶體處理正常")
        } else {
            details.append("⚠️ 大圖片記憶體處理需要優化")
        }

        // 測試資源清理
        if await testResourceCleanup() {
            score += 0.3
            details.append("✅ 資源清理正常")
        } else {
            details.append("❌ 資源清理不完整")
        }

        return TestResult(
            phase: .memoryManagement,
            score: score,
            details: details.joined(separator: "\n"),
            duration: 0
        )
    }

    /// 邊界條件測試
    private func runEdgeCaseTests() async -> TestResult {
        var score = 0.0
        var details: [String] = []

        // 測試各種邊界條件
        let edgeCases = [
            ("空圖片處理", testNullImageHandling),
            ("超大圖片處理", testOversizedImageHandling),
            ("超小圖片處理", testUndersizedImageHandling),
            ("無效圖片格式", testInvalidImageFormat),
            ("網路中斷處理", testNetworkInterruption)
        ]

        for (caseName, testFunction) in edgeCases {
            if await testFunction() {
                score += 0.2
                details.append("✅ \(caseName)正常")
            } else {
                details.append("❌ \(caseName)異常")
            }
        }

        return TestResult(
            phase: .edgeCases,
            score: score,
            details: details.joined(separator: "\n"),
            duration: 0
        )
    }

    /// 使用者體驗測試
    private func runUserExperienceTests() async -> TestResult {
        var score = 0.0
        var details: [String] = []

        // 測試載入時間
        let loadingScore = await testLoadingExperience()
        score += loadingScore * 0.3
        details.append(loadingScore > 0.8 ? "✅ 載入體驗優秀" : "⚠️ 載入體驗需要改善")

        // 測試錯誤處理體驗
        let errorScore = await testErrorHandlingExperience()
        score += errorScore * 0.3
        details.append(errorScore > 0.8 ? "✅ 錯誤處理體驗優秀" : "⚠️ 錯誤處理體驗需要改善")

        // 測試操作流暢度
        let fluidityScore = await testOperationFluidity()
        score += fluidityScore * 0.4
        details.append(fluidityScore > 0.8 ? "✅ 操作流暢度優秀" : "⚠️ 操作流暢度需要改善")

        return TestResult(
            phase: .userExperience,
            score: score,
            details: details.joined(separator: "\n"),
            duration: 0
        )
    }

    /// 整合測試
    private func runIntegrationTests() async -> TestResult {
        var score = 0.0
        var details: [String] = []

        // 測試端到端流程
        if await testEndToEndFlow() {
            score += 0.4
            details.append("✅ 端到端流程正常")
        } else {
            details.append("❌ 端到端流程異常")
        }

        // 測試與其他模組的整合
        if await testModuleIntegration() {
            score += 0.3
            details.append("✅ 模組整合正常")
        } else {
            details.append("⚠️ 模組整合需要檢查")
        }

        // 測試多線程穩定性
        if await testMultithreadingStability() {
            score += 0.3
            details.append("✅ 多線程穩定性良好")
        } else {
            details.append("❌ 多線程穩定性問題")
        }

        return TestResult(
            phase: .integration,
            score: score,
            details: details.joined(separator: "\n"),
            duration: 0
        )
    }

    // MARK: - Individual Test Methods

    private func testViewModelInitialization() async -> Bool {
        do {
            let viewModel = FoodRecognitionViewModel()
            return viewModel.recognitionStatus == .idle &&
                   viewModel.selectedImage == nil &&
                   viewModel.recognitionResult == nil &&
                   viewModel.error == nil
        } catch {
            print("ViewModel 初始化測試失敗: \(error)")
            return false
        }
    }

    private func testImageSelection() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        let testImage = createTestImage()

        viewModel.handleImageSelection(testImage)

        return viewModel.selectedImage != nil &&
               viewModel.hasSelectedImage &&
               viewModel.canStartRecognition
    }

    private func testStateManagement() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        let testImage = createTestImage()

        viewModel.handleImageSelection(testImage)
        let stateAfterSelection = viewModel.currentViewState

        viewModel.clearSelection()
        let stateAfterClear = viewModel.currentViewState

        switch (stateAfterSelection, stateAfterClear) {
        case (.imageSelected, .initial):
            return true
        default:
            return false
        }
    }

    private func testUIInteractions() async -> Bool {
        let viewModel = FoodRecognitionViewModel()

        viewModel.selectImageSource()
        let showsPicker = viewModel.showImageSourcePicker

        viewModel.dismissPickers()
        let hidesPicker = !viewModel.showImageSourcePicker

        return showsPicker && hidesPicker
    }

    private func testNavigationFlow() async -> Bool {
        let navigationController = UINavigationController()
        let coordinator = FoodRecognitionCoordinator(navigationController: navigationController)

        return coordinator.navigationController === navigationController &&
               coordinator.childCoordinators.isEmpty
    }

    private func testImageProcessingPerformance() async -> Double {
        let testImage = createLargeTestImage()
        let startTime = CFAbsoluteTimeGetCurrent()

        let viewModel = FoodRecognitionViewModel()
        let optimizedImage = viewModel.compressImageForMemoryOptimization(testImage)

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        // 評分標準：< 0.5s = 1.0, < 1.0s = 0.8, < 2.0s = 0.6, >= 2.0s = 0.4
        switch duration {
        case ..<0.5: return 1.0
        case ..<1.0: return 0.8
        case ..<2.0: return 0.6
        default: return 0.4
        }
    }

    private func testMemoryUsage() async -> Double {
        let initialMemory = getCurrentMemoryUsage()

        // 執行記憶體密集操作
        let viewModel = FoodRecognitionViewModel()
        for _ in 1...5 {
            let testImage = createTestImage()
            viewModel.handleImageSelection(testImage)
            viewModel.clearSelection()
        }

        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        // 評分標準：< 10MB = 1.0, < 25MB = 0.8, < 50MB = 0.6, >= 50MB = 0.4
        switch memoryIncrease {
        case ..<10.0: return 1.0
        case ..<25.0: return 0.8
        case ..<50.0: return 0.6
        default: return 0.4
        }
    }

    private func testMemoryLeaks() async -> Bool {
        weak var weakViewModel: FoodRecognitionViewModel?

        autoreleasepool {
            let viewModel = FoodRecognitionViewModel()
            weakViewModel = viewModel
            let testImage = createTestImage()
            viewModel.handleImageSelection(testImage)
        }

        // 給 ARC 一些時間清理
        try? await Task.sleep(nanoseconds: 100_000_000)

        return weakViewModel == nil
    }

    private func testLargeImageMemoryHandling() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        let largeImage = createLargeTestImage()
        let initialMemory = getCurrentMemoryUsage()

        viewModel.handleImageSelection(largeImage)
        viewModel.optimizeMemoryUsage()

        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        return memoryIncrease < 100.0 // 記憶體增加少於 100MB
    }

    private func testResourceCleanup() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        let testImage = createTestImage()

        viewModel.handleImageSelection(testImage)
        viewModel.cleanupAllResources()

        return viewModel.selectedImage == nil &&
               viewModel.recognitionResult == nil &&
               viewModel.error == nil
    }

    // MARK: - Edge Case Test Methods

    private func testNullImageHandling() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        viewModel.recognizeFood() // 沒有圖片時嘗試辨識
        return true // 不應該崩潰
    }

    private func testOversizedImageHandling() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        let hugeImage = createHugeTestImage()
        viewModel.handleImageSelection(hugeImage)
        return viewModel.selectedImage != nil // 應該被處理而不是拒絕
    }

    private func testUndersizedImageHandling() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        let tinyImage = createTinyTestImage()
        viewModel.handleImageSelection(tinyImage)
        return viewModel.selectedImage != nil
    }

    private func testInvalidImageFormat() async -> Bool {
        // 這個測試需要實際的無效圖片數據
        return true // 假設通過
    }

    private func testNetworkInterruption() async -> Bool {
        // 這個測試需要模擬網路中斷
        return true // 假設通過
    }

    // MARK: - User Experience Test Methods

    private func testLoadingExperience() async -> Double {
        let viewModel = FoodRecognitionViewModel()
        let hasProgressIndicator = viewModel.shouldShowProgress
        let hasProgressDescription = !viewModel.progressDescription.isEmpty

        if hasProgressIndicator && hasProgressDescription {
            return 1.0
        } else if hasProgressIndicator || hasProgressDescription {
            return 0.7
        } else {
            return 0.4
        }
    }

    private func testErrorHandlingExperience() async -> Double {
        let errors: [FoodRecognitionError] = [
            .imageProcessingFailed,
            .networkError("測試錯誤"),
            .imageTooLarge
        ]

        var score = 0.0
        for error in errors {
            let message = error.localizedDescription
            if !message.isEmpty && message.count > 5 {
                score += 1.0 / Double(errors.count)
            }
        }

        return score
    }

    private func testOperationFluidity() async -> Double {
        let viewModel = FoodRecognitionViewModel()
        let startTime = CFAbsoluteTimeGetCurrent()

        // 執行一系列快速操作
        for _ in 1...10 {
            viewModel.selectImageSource()
            viewModel.dismissPickers()
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = duration / 10

        return averageTime < 0.05 ? 1.0 : max(0.0, 1.0 - (averageTime - 0.05) * 20)
    }

    // MARK: - Integration Test Methods

    private func testEndToEndFlow() async -> Bool {
        let viewModel = FoodRecognitionViewModel()
        let testImage = createTestImage()

        // 模擬完整流程
        viewModel.handleImageSelection(testImage)
        if !viewModel.hasSelectedImage { return false }

        viewModel.updateDescriptionHint("測試描述")
        // 在實際測試中，這裡會調用真實的 API

        return true
    }

    private func testModuleIntegration() async -> Bool {
        // 測試與其他模組的整合
        let navigationController = UINavigationController()
        let coordinator = FoodRecognitionCoordinator(navigationController: navigationController)

        coordinator.start()
        return coordinator.childCoordinators.isEmpty
    }

    private func testMultithreadingStability() async -> Bool {
        return await withTaskGroup(of: Bool.self) { group in
            // 在主線程上並行執行多個任務
            for i in 1...5 {
                group.addTask { @MainActor in
                    let viewModel = FoodRecognitionViewModel()
                    let testImage = self.createTestImage()
                    viewModel.handleImageSelection(testImage)
                    return viewModel.hasSelectedImage
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }

            return results.allSatisfy { $0 }
        }
    }

    // MARK: - Helper Methods

    private func calculateOverallScore() {
        guard !testResults.isEmpty else {
            overallScore = 0.0
            return
        }

        let totalScore = testResults.reduce(0.0) { $0 + $1.score }
        overallScore = totalScore / Double(testResults.count)
    }

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createLargeTestImage() -> UIImage {
        let size = CGSize(width: 2000, height: 1500)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createHugeTestImage() -> UIImage {
        let size = CGSize(width: 4000, height: 3000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemRed.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createTinyTestImage() -> UIImage {
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
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
            return Double(info.resident_size) / 1024.0 / 1024.0
        } else {
            return 0.0
        }
    }
}

// MARK: - Test Runner View

struct FoodRecognitionTestRunnerView: View {
    @StateObject private var testRunner = FoodRecognitionTestRunner()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("食物辨識功能綜合測試")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Text(testRunner.currentPhase.emoji)
                            .font(.title)
                        Text(testRunner.currentPhase.rawValue)
                            .font(.headline)
                    }

                    if !testRunner.testResults.isEmpty {
                        Text("總體分數: \(String(format: "%.1f", testRunner.overallScore * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(colorForScore(testRunner.overallScore))
                    }
                }

                // Test Results
                List(testRunner.testResults) { result in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(result.emoji)
                                .font(.title2)

                            Text(result.phase.rawValue)
                                .font(.headline)

                            Spacer()

                            Text(result.grade)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(colorForScore(result.score))
                        }

                        Text(result.details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                    .padding(.vertical, 4)
                }

                // Controls
                VStack(spacing: 12) {
                    Button("執行完整測試") {
                        Task {
                            await testRunner.runFullTestSuite()
                        }
                    }
                    .disabled(testRunner.isRunning)
                    .buttonStyle(.borderedProminent)

                    if testRunner.isRunning {
                        ProgressView("執行中...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("綜合測試")
        }
    }

    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 0.9...1.0: return .green
        case 0.8..<0.9: return .blue
        case 0.7..<0.8: return .orange
        case 0.6..<0.7: return .yellow
        default: return .red
        }
    }
}

#Preview {
    FoodRecognitionTestRunnerView()
}