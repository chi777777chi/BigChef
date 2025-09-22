//
//  RecipeRecommendationView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct RecipeRecommendationView: View {
    @StateObject private var viewModel: RecipeRecommendationViewModel
    @EnvironmentObject private var coordinator: RecipeRecommendationCoordinator

    init(viewModel: RecipeRecommendationViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.brandOrange)

                        Text("食譜推薦")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("根據您現有的食材和器具，AI 將為您推薦最適合的食譜")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Coming Soon Section
                    VStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.brandOrange.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                            )
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.brandOrange.opacity(0.7))

                                    VStack(spacing: 8) {
                                        Text("功能建構中")
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text("我們正在為您準備智能食譜推薦功能")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            )

                        // Feature Preview Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("即將推出的功能：")
                                .font(.headline)
                                .foregroundColor(.brandOrange)

                            VStack(alignment: .leading, spacing: 8) {
                                FeatureItem(
                                    icon: "list.clipboard",
                                    title: "食材清單管理",
                                    description: "輸入您現有的食材"
                                )

                                FeatureItem(
                                    icon: "fork.knife",
                                    title: "器具選擇",
                                    description: "選擇可用的廚房器具"
                                )

                                FeatureItem(
                                    icon: "slider.horizontal.3",
                                    title: "偏好設定",
                                    description: "設定料理方式和口味偏好"
                                )

                                FeatureItem(
                                    icon: "sparkles",
                                    title: "AI 智能推薦",
                                    description: "獲得個人化的食譜建議"
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("推薦")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Feature Item Component

private struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandOrange)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    RecipeRecommendationView(viewModel: RecipeRecommendationViewModel())
}