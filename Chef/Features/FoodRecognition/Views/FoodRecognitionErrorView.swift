//
//  FoodRecognitionErrorView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 食物辨識錯誤狀態頁面
struct FoodRecognitionErrorView: View {
    let error: FoodRecognitionError
    let selectedImage: UIImage?
    let isRetryable: Bool
    let onRetry: () -> Void
    let onSelectNewImage: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 錯誤圖示和主訊息
            errorHeaderSection

            // 錯誤詳細資訊
            errorDetailSection

            // 失敗的圖片預覽（如果有）
            if let image = selectedImage {
                failedImageSection(image)
            }

            // 解決方案建議
            solutionSuggestionsSection

            // 動作按鈕
            actionButtonsSection

            Spacer()
        }
        .padding()
    }

    // MARK: - 子視圖

    private var errorHeaderSection: some View {
        VStack(spacing: 16) {
            // 錯誤圖示
            Image(systemName: errorIcon)
                .font(.system(size: 60))
                .foregroundColor(errorColor)

            VStack(spacing: 8) {
                Text("辨識失敗")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(error.localizedDescription ?? "發生未知錯誤")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private var errorDetailSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("錯誤詳情")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                errorDetailRow("錯誤類型", value: errorTypeDescription)
                errorDetailRow("錯誤代碼", value: errorCodeDescription)
                errorDetailRow("可重試", value: isRetryable ? "是" : "否")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func failedImageSection(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            Text("處理失敗的圖片")
                .font(.headline)
                .foregroundColor(.secondary)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                )
                .overlay(
                    // 錯誤覆蓋層
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        )
                )
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var solutionSuggestionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("建議解決方案")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { suggestion in
                    suggestionRow(suggestion)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if isRetryable {
                ActionButtonView.primary(
                    title: "重新辨識",
                    icon: "arrow.clockwise",
                    action: onRetry
                )
            }

            ActionButtonView.secondary(
                title: "選擇新圖片",
                icon: "photo.on.rectangle",
                action: onSelectNewImage
            )

            if !isRetryable {
                Button("回到首頁") {
                    // TODO: 實作回到首頁功能
                    print("回到首頁")
                }
                .foregroundColor(.brandOrange)
            }
        }
    }

    // MARK: - 輔助視圖

    private func errorDetailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    private func suggestionRow(_ suggestion: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 2)

            Text(suggestion)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - 計算屬性

    private var errorIcon: String {
        switch error {
        case .imageProcessingFailed, .imageTooLarge:
            return "photo.badge.exclamationmark"
        case .networkError:
            return "wifi.exclamationmark"
        case .apiError, .decodingError:
            return "server.rack"
        case .noResults:
            return "questionmark.circle"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }

    private var errorColor: Color {
        switch error.category {
        case .client:
            return .orange
        case .network:
            return .red
        case .server:
            return .purple
        case .unknown:
            return .gray
        }
    }

    private var errorTypeDescription: String {
        switch error.category {
        case .client:
            return "用戶端錯誤"
        case .network:
            return "網路錯誤"
        case .server:
            return "伺服器錯誤"
        case .unknown:
            return "未知錯誤"
        }
    }

    private var errorCodeDescription: String {
        switch error {
        case .imageProcessingFailed:
            return "IMAGE_PROCESS_FAILED"
        case .networkError:
            return "NETWORK_ERROR"
        case .apiError:
            return "API_ERROR"
        case .decodingError:
            return "DECODE_ERROR"
        case .noResults:
            return "NO_RESULTS"
        case .imageTooLarge:
            return "IMAGE_TOO_LARGE"
        case .unknown:
            return "UNKNOWN_ERROR"
        }
    }

    private var suggestions: [String] {
        switch error {
        case .imageProcessingFailed:
            return [
                "確保圖片格式正確（JPEG 或 PNG）",
                "嘗試選擇更清晰的圖片",
                "檢查圖片是否損壞"
            ]
        case .networkError:
            return [
                "檢查網路連線是否正常",
                "稍後再試",
                "切換到更穩定的網路環境"
            ]
        case .apiError:
            return [
                "伺服器暫時無法處理請求",
                "稍後再試",
                "聯絡技術支援"
            ]
        case .decodingError:
            return [
                "伺服器回傳資料格式錯誤",
                "重新嘗試辨識",
                "如果問題持續，請聯絡支援"
            ]
        case .noResults:
            return [
                "嘗試選擇更清晰的食物圖片",
                "確保圖片中有明顯的食物",
                "調整拍攝角度和光線"
            ]
        case .imageTooLarge:
            return [
                "選擇較小的圖片檔案",
                "應用會自動壓縮圖片",
                "確保網路連線穩定"
            ]
        case .unknown:
            return [
                "重新啟動應用程式",
                "檢查應用程式更新",
                "聯絡技術支援"
            ]
        }
    }
}

// MARK: - 預覽
#Preview {
    VStack(spacing: 20) {
        FoodRecognitionErrorView(
            error: .noResults,
            selectedImage: nil,
            isRetryable: true,
            onRetry: {
                print("重新辨識")
            },
            onSelectNewImage: {
                print("選擇新圖片")
            }
        )

        Divider()

        FoodRecognitionErrorView(
            error: .networkError("網路連線逾時"),
            selectedImage: nil,
            isRetryable: false,
            onRetry: {},
            onSelectNewImage: {
                print("選擇新圖片")
            }
        )
    }
}