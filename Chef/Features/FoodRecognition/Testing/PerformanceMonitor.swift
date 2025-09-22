//
//  PerformanceMonitor.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//  效能監控工具
//

import Foundation
import UIKit
import SwiftUI

/// 效能監控器
/// 用於監控食物辨識功能的效能指標
class PerformanceMonitor: ObservableObject {

    // MARK: - Published Properties
    @Published var metrics: [PerformanceMetric] = []
    @Published var isMonitoring = false
    @Published var currentOperation = ""

    // MARK: - Monitoring Configuration
    private let monitoringInterval: TimeInterval = 0.5
    private var monitoringTimer: Timer?
    private var baselineMemory: Double = 0

    // MARK: - Performance Metrics
    struct PerformanceMetric: Identifiable, Equatable {
        let id = UUID()
        let operation: String
        let duration: TimeInterval
        let memoryUsage: Double
        let memoryIncrease: Double
        let timestamp: Date
        let status: MetricStatus

        enum MetricStatus {
            case excellent, good, warning, poor

            var color: Color {
                switch self {
                case .excellent: return .green
                case .good: return .blue
                case .warning: return .orange
                case .poor: return .red
                }
            }

            var emoji: String {
                switch self {
                case .excellent: return "🚀"
                case .good: return "✅"
                case .warning: return "⚠️"
                case .poor: return "🐌"
                }
            }
        }
    }

    // MARK: - Performance Thresholds
    struct Thresholds {
        static let excellentTime: TimeInterval = 0.1
        static let goodTime: TimeInterval = 0.5
        static let warningTime: TimeInterval = 1.0

        static let excellentMemory: Double = 10.0 // MB
        static let goodMemory: Double = 25.0
        static let warningMemory: Double = 50.0
    }

    // MARK: - Public Methods

    /// 開始監控
    func startMonitoring() {
        print("📊 開始效能監控")
        isMonitoring = true
        baselineMemory = getCurrentMemoryUsage()
        startPeriodicMonitoring()
    }

    /// 停止監控
    func stopMonitoring() {
        print("📊 停止效能監控")
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        currentOperation = ""
    }

    /// 測量操作效能
    @discardableResult
    func measure<T>(
        operation: String,
        action: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()

        currentOperation = operation
        print("⏱️ 開始測量: \(operation)")

        let result = try await action()

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let endMemory = getCurrentMemoryUsage()
        let memoryIncrease = endMemory - startMemory

        let metric = PerformanceMetric(
            operation: operation,
            duration: duration,
            memoryUsage: endMemory,
            memoryIncrease: memoryIncrease,
            timestamp: Date(),
            status: evaluatePerformance(duration: duration, memoryIncrease: memoryIncrease)
        )

        await MainActor.run {
            metrics.append(metric)
            currentOperation = ""
        }

        print("⏱️ 完成測量: \(operation) - \(String(format: "%.3f", duration))s, 記憶體增加: \(String(format: "%.1f", memoryIncrease))MB")

        return result
    }

    /// 測量同步操作效能
    @discardableResult
    func measureSync<T>(
        operation: String,
        action: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()

        currentOperation = operation
        print("⏱️ 開始測量: \(operation)")

        let result = try action()

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let endMemory = getCurrentMemoryUsage()
        let memoryIncrease = endMemory - startMemory

        let metric = PerformanceMetric(
            operation: operation,
            duration: duration,
            memoryUsage: endMemory,
            memoryIncrease: memoryIncrease,
            timestamp: Date(),
            status: evaluatePerformance(duration: duration, memoryIncrease: memoryIncrease)
        )

        DispatchQueue.main.async {
            self.metrics.append(metric)
            self.currentOperation = ""
        }

        print("⏱️ 完成測量: \(operation) - \(String(format: "%.3f", duration))s, 記憶體增加: \(String(format: "%.1f", memoryIncrease))MB")

        return result
    }

    /// 清除指標
    func clearMetrics() {
        metrics.removeAll()
        baselineMemory = getCurrentMemoryUsage()
    }

    /// 匯出效能報告
    func exportReport() -> String {
        let report = generatePerformanceReport()
        print("📋 效能報告已生成")
        return report
    }

    // MARK: - Private Methods

    private func startPeriodicMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { _ in
            self.recordCurrentState()
        }
    }

    private func recordCurrentState() {
        guard isMonitoring else { return }

        let currentMemory = getCurrentMemoryUsage()
        let memoryFromBaseline = currentMemory - baselineMemory

        // 只在有顯著變化時記錄
        if memoryFromBaseline > 5.0 || !currentOperation.isEmpty {
            let metric = PerformanceMetric(
                operation: currentOperation.isEmpty ? "系統監控" : currentOperation,
                duration: 0,
                memoryUsage: currentMemory,
                memoryIncrease: memoryFromBaseline,
                timestamp: Date(),
                status: evaluateMemoryStatus(memoryFromBaseline)
            )

            DispatchQueue.main.async {
                // 避免重複記錄相同的系統監控數據
                if !self.metrics.contains(where: { $0.operation == "系統監控" && abs($0.timestamp.timeIntervalSince(metric.timestamp)) < 1.0 }) {
                    self.metrics.append(metric)
                }
            }
        }
    }

    private func evaluatePerformance(duration: TimeInterval, memoryIncrease: Double) -> PerformanceMetric.MetricStatus {
        let timeStatus = evaluateTimeStatus(duration)
        let memoryStatus = evaluateMemoryStatus(memoryIncrease)

        // 取較差的狀態
        switch (timeStatus, memoryStatus) {
        case (.poor, _), (_, .poor):
            return .poor
        case (.warning, _), (_, .warning):
            return .warning
        case (.good, _), (_, .good):
            return .good
        case (.excellent, .excellent):
            return .excellent
        }
    }

    private func evaluateTimeStatus(_ duration: TimeInterval) -> PerformanceMetric.MetricStatus {
        switch duration {
        case ..<Thresholds.excellentTime:
            return .excellent
        case ..<Thresholds.goodTime:
            return .good
        case ..<Thresholds.warningTime:
            return .warning
        default:
            return .poor
        }
    }

    private func evaluateMemoryStatus(_ memoryIncrease: Double) -> PerformanceMetric.MetricStatus {
        switch memoryIncrease {
        case ..<Thresholds.excellentMemory:
            return .excellent
        case ..<Thresholds.goodMemory:
            return .good
        case ..<Thresholds.warningMemory:
            return .warning
        default:
            return .poor
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

    private func generatePerformanceReport() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var report = "# 食物辨識功能效能報告\n\n"
        report += "生成時間: \(formatter.string(from: Date()))\n"
        report += "總指標數量: \(metrics.count)\n\n"

        // 統計分析
        let excellentCount = metrics.filter { $0.status == .excellent }.count
        let goodCount = metrics.filter { $0.status == .good }.count
        let warningCount = metrics.filter { $0.status == .warning }.count
        let poorCount = metrics.filter { $0.status == .poor }.count

        report += "## 效能統計\n"
        report += "- 優秀 🚀: \(excellentCount)\n"
        report += "- 良好 ✅: \(goodCount)\n"
        report += "- 警告 ⚠️: \(warningCount)\n"
        report += "- 較差 🐌: \(poorCount)\n\n"

        // 平均指標
        let avgDuration = metrics.map { $0.duration }.reduce(0, +) / Double(metrics.count)
        let avgMemoryIncrease = metrics.map { $0.memoryIncrease }.reduce(0, +) / Double(metrics.count)
        let maxMemoryUsage = metrics.map { $0.memoryUsage }.max() ?? 0

        report += "## 平均指標\n"
        report += "- 平均執行時間: \(String(format: "%.3f", avgDuration))s\n"
        report += "- 平均記憶體增加: \(String(format: "%.1f", avgMemoryIncrease))MB\n"
        report += "- 最大記憶體使用: \(String(format: "%.1f", maxMemoryUsage))MB\n\n"

        // 詳細記錄
        report += "## 詳細記錄\n"
        for metric in metrics.sorted(by: { $0.timestamp > $1.timestamp }) {
            report += "### \(metric.operation) \(metric.status.emoji)\n"
            report += "- 時間: \(formatter.string(from: metric.timestamp))\n"
            report += "- 執行時間: \(String(format: "%.3f", metric.duration))s\n"
            report += "- 記憶體使用: \(String(format: "%.1f", metric.memoryUsage))MB\n"
            report += "- 記憶體增加: \(String(format: "%.1f", metric.memoryIncrease))MB\n\n"
        }

        return report
    }
}

// MARK: - Performance Monitor View

struct PerformanceMonitorView: View {
    @StateObject private var monitor = PerformanceMonitor()
    @State private var showingReport = false
    @State private var reportContent = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(monitor.isMonitoring ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)

                        Text(monitor.isMonitoring ? "監控中" : "未監控")
                            .font(.headline)
                    }

                    if monitor.isMonitoring && !monitor.currentOperation.isEmpty {
                        Text("當前操作: \(monitor.currentOperation)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                // Metrics List
                List(monitor.metrics.reversed()) { metric in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(metric.status.emoji)
                                .font(.title3)

                            Text(metric.operation)
                                .font(.headline)
                                .lineLimit(1)

                            Spacer()

                            Text(DateFormatter.time.string(from: metric.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("執行時間")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.3fs", metric.duration))
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("記憶體增加")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1fMB", metric.memoryIncrease))
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(metric.status.color)
                            }

                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Controls
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button(monitor.isMonitoring ? "停止監控" : "開始監控") {
                            if monitor.isMonitoring {
                                monitor.stopMonitoring()
                            } else {
                                monitor.startMonitoring()
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("清除記錄") {
                            monitor.clearMetrics()
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("生成報告") {
                        reportContent = monitor.exportReport()
                        showingReport = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(monitor.metrics.isEmpty)
                }
                .padding()
            }
            .navigationTitle("效能監控")
        }
        .sheet(isPresented: $showingReport) {
            NavigationView {
                ScrollView {
                    Text(reportContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .navigationTitle("效能報告")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            showingReport = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    PerformanceMonitorView()
}