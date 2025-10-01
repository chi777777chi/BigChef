//
//  RecommendationErrorView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct RecommendationErrorView: View {
    let error: RecipeRecommendationError
    let onRetry: () -> Void
    let onBackToConfiguration: (() -> Void)?
    let onResetConfiguration: (() -> Void)?

    var body: some View {
        VStack(spacing: 32) {
            // Error Icon and Animation
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: errorIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }

                VStack(spacing: 8) {
                    Text("推薦失敗")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(error.localizedDescription ?? "未知錯誤")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            // Error Details and Suggestions
            VStack(alignment: .leading, spacing: 16) {
                Text("可能的解決方案：")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 12) {
                    ErrorSuggestionView(
                        icon: "wifi",
                        suggestion: "檢查網路連線狀態"
                    )

                    ErrorSuggestionView(
                        icon: "checkmark.circle",
                        suggestion: "確認已新增食材資訊"
                    )

                    ErrorSuggestionView(
                        icon: "arrow.clockwise",
                        suggestion: "稍後重試"
                    )

                    if error.isRetryable {
                        ErrorSuggestionView(
                            icon: "exclamationmark.triangle",
                            suggestion: "如果問題持續，請聯繫技術支援"
                        )
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Action Buttons
            VStack(spacing: 12) {
                if error.isRetryable {
                    Button(action: onRetry) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                            Text("重試")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brandOrange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        onResetConfiguration?()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.title3)
                            Text("重新配置")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }

                // Back to configuration button
                if let onBackToConfiguration = onBackToConfiguration {
                    Button(action: onBackToConfiguration) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                            Text("返回配置")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }

                Button(action: {
                    // Show help information - could be handled by coordinator
                    print("顯示幫助信息")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                        Text("獲取幫助")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandOrange.opacity(0.1))
                    .foregroundColor(.brandOrange)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Properties

    private var errorIcon: String {
        switch error {
        case .noIngredientsProvided, .invalidIngredientData, .invalidEquipmentData:
            return "exclamationmark.triangle.fill"
        case .networkError:
            return "wifi.exclamationmark"
        case .apiError:
            return "server.rack"
        case .invalidResponse:
            return "doc.text.fill.badge.exclamationmark"
        case .validationFailed:
            return "checkmark.circle.badge.exclamationmark"
        }
    }
}

// MARK: - Error Suggestion View

private struct ErrorSuggestionView: View {
    let icon: String
    let suggestion: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.brandOrange)
                .frame(width: 20)

            Text(suggestion)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        RecommendationErrorView(
            error: .networkError("網路連線失敗"),
            onRetry: {},
            onBackToConfiguration: {},
            onResetConfiguration: {}
        )

        RecommendationErrorView(
            error: .noIngredientsProvided,
            onRetry: {},
            onBackToConfiguration: {},
            onResetConfiguration: {}
        )
    }
}