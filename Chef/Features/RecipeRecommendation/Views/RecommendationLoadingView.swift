//
//  RecommendationLoadingView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct RecommendationLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var currentMessageIndex = 0
    @State private var messageOpacity: Double = 1.0

    private let loadingMessages = [
        "🧠 AI 正在分析您的食材...",
        "🍳 尋找最適合的烹飪方式...",
        "📋 生成詳細的製作步驟...",
        "✨ 即將完成推薦..."
    ]

    var body: some View {
        VStack(spacing: 40) {
            // Loading Animation
            VStack(spacing: 24) {
                ZStack {
                    // Outer rotating circle
                    Circle()
                        .stroke(Color.brandOrange.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)

                    // Inner rotating element
                    Circle()
                        .fill(Color.brandOrange)
                        .frame(width: 12, height: 12)
                        .offset(y: -34)
                        .rotationEffect(.degrees(rotationAngle))

                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.brandOrange)
                }
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }

                // Loading progress (visual only)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandOrange))
                    .scaleEffect(1.2)
            }

            // Loading Messages
            VStack(spacing: 16) {
                Text("正在推薦食譜")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(loadingMessages[currentMessageIndex])
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(messageOpacity)
                    .animation(.easeInOut(duration: 0.5), value: messageOpacity)

                Text("這可能需要幾秒鐘時間")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Loading Steps Indicator
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index <= currentMessageIndex ? Color.brandOrange : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            startMessageRotation()
        }
    }

    // MARK: - Private Methods

    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                messageOpacity = 0.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentMessageIndex = (currentMessageIndex + 1) % loadingMessages.count

                withAnimation(.easeInOut(duration: 0.3)) {
                    messageOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RecommendationLoadingView()
}