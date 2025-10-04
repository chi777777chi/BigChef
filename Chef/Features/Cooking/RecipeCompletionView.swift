//
//  RecipeCompletionView.swift
//  ChefHelper
//
//  Created by Claude on 2025/10/01.
//

import SwiftUI

struct RecipeCompletionView: View {
    let dishName: String
    let totalSteps: Int
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.brandOrange.opacity(0.3),
                    Color.brandOrange.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 成功圖示
                ZStack {
                    Circle()
                        .fill(Color.brandOrange.opacity(0.2))
                        .frame(width: 150, height: 150)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.brandOrange)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                // 標題
                VStack(spacing: 12) {
                    Text("🎉 恭喜完成！")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text(dishName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.brandOrange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(opacity)

                // 統計信息
                VStack(spacing: 16) {
                    CompletionStatRow(
                        icon: "list.number",
                        title: "完成步驟",
                        value: "\(totalSteps) 步"
                    )

                    CompletionStatRow(
                        icon: "clock.fill",
                        title: "烹飪模式",
                        value: "AR 輔助"
                    )

                    CompletionStatRow(
                        icon: "star.fill",
                        title: "成就解鎖",
                        value: "新手廚師"
                    )
                }
                .padding(.horizontal, 32)
                .opacity(opacity)

                Spacer()

                // 按鈕組
                VStack(spacing: 16) {
                    // 分享成果按鈕（暫時隱藏，未來功能）
                    // Button(action: {
                    //     // TODO: 實作分享功能
                    //     print("分享成果")
                    // }) {
                    //     HStack {
                    //         Image(systemName: "square.and.arrow.up")
                    //             .font(.title3)
                    //         Text("分享我的成果")
                    //             .fontWeight(.semibold)
                    //     }
                    //     .frame(maxWidth: .infinity)
                    //     .padding(.vertical, 16)
                    //     .background(Color.brandOrange)
                    //     .foregroundColor(.white)
                    //     .cornerRadius(12)
                    // }

                    // 返回首頁按鈕
                    Button(action: onDismiss) {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.title3)
                            Text("返回首頁")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brandOrange.opacity(0.15))
                        .foregroundColor(.brandOrange)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // 延遲顯示五彩紙屑效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Supporting Views

struct CompletionStatRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.brandOrange)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    RecipeCompletionView(
        dishName: "蔥爆牛肉",
        totalSteps: 8,
        onDismiss: {
            print("返回首頁")
        }
    )
}
