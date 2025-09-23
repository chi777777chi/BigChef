//
//  SimulatedARView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/23.
//

import SwiftUI
import Combine

struct SimulatedARView: View {
    let recipe: ARRecipe
    let onDismiss: () -> Void

    @State private var currentStepIndex = 0
    @State private var showingStepDetail = false
    @State private var isPlaying = false
    @State private var simulatedTime = 0
    @State private var timer: Timer?

    var currentStep: ARCookingStep? {
        guard currentStepIndex < recipe.steps.count else { return nil }
        return recipe.steps[currentStepIndex]
    }

    var body: some View {
        ZStack {
            // 模擬相機背景
            simulatedCameraBackground

            // AR UI 覆層
            VStack {
                // 頂部控制欄
                topControlBar

                Spacer()

                // 中央步驟顯示
                if let step = currentStep {
                    stepDisplayCard(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                Spacer()

                // 底部控制
                bottomControlBar
            }
            .padding()
        }
        .onAppear {
            startSimulation()
        }
        .onDisappear {
            stopSimulation()
        }
        .preferredColorScheme(.dark)
    }

    private var simulatedCameraBackground: some View {
        // 模擬廚房背景
        ZStack {
            // 基礎漸層背景
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.1),
                    Color(red: 0.3, green: 0.25, blue: 0.2),
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 模擬廚房元素
            VStack {
                Spacer()

                // 模擬工作台面
                HStack {
                    Spacer()

                    VStack(spacing: 20) {
                        // 模擬鍋具
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text("🍳")
                                    .font(.system(size: 40))
                            )
                            .scaleEffect(isPlaying ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPlaying)

                        // 工作台面
                        Rectangle()
                            .fill(Color.brown.opacity(0.3))
                            .frame(height: 80)
                            .cornerRadius(8)
                            .overlay(
                                HStack {
                                    Text("工作台面")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)
                                    Spacer()
                                    if isPlaying {
                                        Text("⏱️ \(formatTime(simulatedTime))")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal)
                            )
                    }

                    Spacer()
                }
                .padding(.bottom, 120)
            }

            // 模擬 AR 網格效果
            if isPlaying {
                gridOverlay
            }
        }
        .ignoresSafeArea()
    }

    private var gridOverlay: some View {
        VStack(spacing: 30) {
            ForEach(0..<8, id: \.self) { _ in
                HStack(spacing: 30) {
                    ForEach(0..<6, id: \.self) { _ in
                        Circle()
                            .fill(Color.cyan.opacity(0.3))
                            .frame(width: 2, height: 2)
                    }
                }
            }
        }
        .opacity(0.5)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isPlaying)
    }

    private var topControlBar: some View {
        HStack {
            Button(action: onDismiss) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                    Text("結束")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("模擬器模式")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
                Text("🖥️ Simulator")
                    .font(.caption2)
                    .foregroundColor(.yellow.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)

            Spacer()

            Text("\(currentStepIndex + 1)/\(recipe.steps.count)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
        }
    }

    private func stepDisplayCard(_ step: ARCookingStep) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 步驟標題
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("步驟 \(step.stepNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Text(step.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let time = step.estimatedTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.cyan)
                    }

                    if let temp = step.temperature, temp != "常溫" {
                        Label(temp, systemImage: "thermometer")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            // 步驟描述
            Text(step.description)
                .font(.body)
                .lineLimit(nil)
                .foregroundColor(.white.opacity(0.9))

            // 動作指示
            if let actions = step.actions, !actions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("動作指示")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)

                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        HStack(spacing: 8) {
                            Image(systemName: getActionIcon(action.type))
                                .foregroundColor(.cyan)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.type)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                if let instructions = action.instructions {
                                    Text(instructions)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }

                            Spacer()

                            if action.duration > 0 {
                                Text("\(action.duration)min")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }

            // 警告
            if let warnings = step.warnings, !warnings.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(warnings)
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
            }

            // 注意事項
            if let notes = step.notes, !notes.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.blue)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var bottomControlBar: some View {
        HStack(spacing: 20) {
            Button(action: previousStep) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(currentStepIndex == 0 ? .gray : .white)
            }
            .disabled(currentStepIndex == 0)

            Button(action: togglePlayPause) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.orange)
            }

            Button(action: nextStep) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(currentStepIndex >= recipe.steps.count - 1 ? .gray : .white)
            }
            .disabled(currentStepIndex >= recipe.steps.count - 1)

            Spacer()

            Button("詳細") {
                showingStepDetail = true
            }
            .foregroundColor(.cyan)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.cyan.opacity(0.2))
            .cornerRadius(20)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(25)
        .sheet(isPresented: $showingStepDetail) {
            if let step = currentStep {
                StepDetailView(step: step)
            }
        }
    }


    private func getActionIcon(_ actionType: String) -> String {
        switch actionType.lowercased() {
        case "切", "切塊", "切片":
            return "scissors"
        case "炒", "翻炒":
            return "flame.fill"
        case "煎":
            return "circle.grid.cross.fill"
        case "煮", "燉煮":
            return "drop.fill"
        case "攪拌", "打散":
            return "tornado"
        case "撒", "灑":
            return "sparkles"
        case "倒入":
            return "arrow.down.circle"
        case "剝皮":
            return "hand.raised.fill"
        case "放入":
            return "tray.and.arrow.down"
        default:
            return "hand.raised"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func startSimulation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isPlaying {
                simulatedTime += 1
            }
        }
    }

    private func stopSimulation() {
        timer?.invalidate()
        timer = nil
    }

    private func previousStep() {
        if currentStepIndex > 0 {
            withAnimation(.easeInOut) {
                currentStepIndex -= 1
            }
        }
    }

    private func nextStep() {
        if currentStepIndex < recipe.steps.count - 1 {
            withAnimation(.easeInOut) {
                currentStepIndex += 1
            }
        }
    }

    private func togglePlayPause() {
        withAnimation(.easeInOut) {
            isPlaying.toggle()
        }
    }
}

// MARK: - Step Detail View

struct StepDetailView: View {
    let step: ARCookingStep
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 步驟標題
                    VStack(alignment: .leading, spacing: 8) {
                        Text("步驟 \(step.stepNumber)")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text(step.title)
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Divider()

                    // 基本資訊
                    VStack(alignment: .leading, spacing: 12) {
                        Text("說明")
                            .font(.headline)

                        Text(step.description)
                            .font(.body)

                        HStack(spacing: 20) {
                            if let time = step.estimatedTime {
                                Label(time, systemImage: "clock")
                                    .foregroundColor(.blue)
                            }

                            if let temp = step.temperature, temp != "常溫" {
                                Label(temp, systemImage: "thermometer")
                                    .foregroundColor(.red)
                            }
                        }
                        .font(.caption)
                    }

                    // 詳細動作
                    if let actions = step.actions, !actions.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("詳細動作")
                                .font(.headline)

                            ForEach(actions.indices, id: \.self) { index in
                                let action = actions[index]
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: getActionIcon(action.type))
                                            .foregroundColor(.orange)
                                        Text(action.type)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        if action.duration > 0 {
                                            Text("\(action.duration) 分鐘")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }

                                    if let instructions = action.instructions {
                                        Text(instructions)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }

                                    if let tool = action.tool {
                                        Label(tool, systemImage: "wrench.and.screwdriver")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }

                                    if let materials = action.materials, !materials.isEmpty {
                                        HStack {
                                            Image(systemName: "list.bullet")
                                                .foregroundColor(.green)
                                            Text(materials.joined(separator: ", "))
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // 警告和注意事項
                    if let warnings = step.warnings, !warnings.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Label("注意事項", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.orange)

                            Text(warnings)
                                .font(.body)
                                .foregroundColor(.orange)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    if let notes = step.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("小貼士", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundColor(.blue)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("步驟詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getActionIcon(_ actionType: String) -> String {
        switch actionType.lowercased() {
        case "切", "切塊", "切片":
            return "scissors"
        case "炒", "翻炒":
            return "flame.fill"
        case "煎":
            return "circle.grid.cross.fill"
        case "煮", "燉煮":
            return "drop.fill"
        case "攪拌", "打散":
            return "tornado"
        case "撒", "灑":
            return "sparkles"
        case "倒入":
            return "arrow.down.circle"
        case "剝皮":
            return "hand.raised.fill"
        case "放入":
            return "tray.and.arrow.down"
        default:
            return "hand.raised"
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleActions = [
        ARAction(
            type: "切",
            tool: "菜刀",
            materials: ["洋蔥"],
            duration: 3,
            instructions: "將洋蔥切成細絲",
            temperature: nil
        )
    ]

    let sampleStep = ARCookingStep(
        stepNumber: 1,
        title: "準備食材",
        description: "將洋蔥切成細絲，準備開始烹飪。注意切的時候要小心手指。",
        actions: sampleActions,
        estimatedTime: "3分鐘",
        temperature: "常溫",
        warnings: "小心使用刀具",
        notes: "切得越細越容易入味"
    )

    let sampleRecipe = ARRecipe(
        id: "sample",
        name: "洋蔥炒蛋",
        description: "簡單美味的家常菜",
        steps: [sampleStep],
        ingredients: [],
        equipment: []
    )

    SimulatedARView(recipe: sampleRecipe) {
        print("AR 模擬結束")
    }
}