//
//  FoodRecognitionLoadingView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 食物辨識載入中狀態頁面
struct FoodRecognitionLoadingView: View {
    let selectedImage: UIImage?
    let progress: Double?
    let statusMessage: String

    @State private var animationRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    init(
        selectedImage: UIImage? = nil,
        progress: Double? = nil,
        statusMessage: String = "正在辨識中..."
    ) {
        self.selectedImage = selectedImage
        self.progress = progress
        self.statusMessage = statusMessage
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // 主要載入區域
            mainLoadingSection

            // 選中的圖片預覽
            if let image = selectedImage {
                selectedImageSection(image)
            }

            // 載入提示訊息
            loadingMessageSection

            Spacer()
        }
        .padding()
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - 子視圖

    private var mainLoadingSection: some View {
        VStack(spacing: 24) {
            // 載入動畫
            ZStack {
                // 外層旋轉圓環
                Circle()
                    .stroke(Color.brandOrange.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)

                // 內層進度圓環
                Circle()
                    .trim(from: 0, to: progress ?? 0.7)
                    .stroke(
                        Color.brandOrange,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(animationRotation))

                // 中心圖示
                ZStack {
                    Circle()
                        .fill(Color.brandOrange.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 30))
                        .foregroundColor(.brandOrange)
                        .scaleEffect(pulseScale)
                }
            }

            // 進度百分比（如果有提供）
            if let progress = progress {
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandOrange)
            }
        }
    }

    private func selectedImageSection(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            Text("正在分析此圖片")
                .font(.headline)
                .foregroundColor(.primary)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandOrange.opacity(0.3), lineWidth: 2)
                )
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var loadingMessageSection: some View {
        VStack(spacing: 16) {
            Text(statusMessage)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                loadingStep("分析圖片內容", isActive: true)
                loadingStep("識別食物種類", isActive: progress ?? 0 > 0.3)
                loadingStep("匹配食材資料", isActive: progress ?? 0 > 0.6)
                loadingStep("整理辨識結果", isActive: progress ?? 0 > 0.9)
            }
        }
    }

    // MARK: - 輔助視圖

    private func loadingStep(_ title: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            // 步驟圖示
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .font(.body)
                .foregroundColor(isActive ? .green : .gray)

            // 步驟文字
            Text(title)
                .font(.body)
                .foregroundColor(isActive ? .primary : .secondary)

            Spacer()

            // 載入指示器（僅活動步驟顯示）
            if isActive && (progress == nil || progress! < 1.0) {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandOrange))
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }

    // MARK: - 動畫

    private func startAnimations() {
        // 旋轉動畫
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationRotation = 360
        }

        // 脈衝動畫
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
    }
}

// MARK: - 帶有詳細步驟的載入視圖
struct DetailedFoodRecognitionLoadingView: View {
    let selectedImage: UIImage?
    @State private var currentStep = 0
    @State private var progress: Double = 0.0

    private let steps = [
        "準備圖片分析",
        "檢測食物物件",
        "識別食物種類",
        "分析食材組成",
        "匹配器具資料",
        "整理辨識結果"
    ]

    var body: some View {
        FoodRecognitionLoadingView(
            selectedImage: selectedImage,
            progress: progress,
            statusMessage: currentStep < steps.count ? steps[currentStep] : "完成辨識"
        )
        .onAppear {
            simulateProgress()
        }
    }

    private func simulateProgress() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                if currentStep < steps.count - 1 {
                    currentStep += 1
                    progress = Double(currentStep) / Double(steps.count - 1)
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - 預覽
#Preview {
    VStack(spacing: 20) {
        // 基本載入視圖
        FoodRecognitionLoadingView()

        Divider()

        // 帶進度的載入視圖
        FoodRecognitionLoadingView(
            progress: 0.6,
            statusMessage: "分析食材組成中..."
        )
    }
}