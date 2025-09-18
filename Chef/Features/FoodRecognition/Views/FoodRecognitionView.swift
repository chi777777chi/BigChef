//
//  FoodRecognitionView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

struct FoodRecognitionView: View {
    @StateObject private var viewModel: FoodRecognitionViewModel

    init(viewModel: FoodRecognitionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                headerView

                // Main Content
                mainContentView

                Spacer()
            }
            .padding()
            .navigationTitle("食物辨識")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("食物圖片辨識")
                .font(.title2)
                .fontWeight(.semibold)

            Text("上傳食物圖片，AI 將自動辨識並建議食譜")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var mainContentView: some View {
        VStack(spacing: 24) {
            // Image Upload Area
            imageUploadArea

            // Action Buttons
            actionButtonsView

            // Results Area (will be implemented later)
            if viewModel.isLoading {
                ProgressView("正在辨識中...")
                    .padding()
            } else {
                placeholderResultsView
            }
        }
    }

    private var imageUploadArea: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
            .frame(height: 200)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("點擊上傳食物圖片")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            )
            .onTapGesture {
                // TODO: Implement image picker
                print("Image upload tapped")
            }
    }

    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            Button(action: {
                // TODO: Implement camera action
                print("Camera tapped")
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("拍照")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .rounded()
            }

            Button(action: {
                // TODO: Implement photo library action
                print("Photo library tapped")
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("相簿")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .rounded()
            }
        }
    }

    private var placeholderResultsView: some View {
        VStack(spacing: 16) {
            Text("🚧 功能建構中")
                .font(.title3)
                .fontWeight(.medium)

            Text("辨識結果將顯示在這裡")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .rounded()
    }
}

// MARK: - Extensions

private extension View {
    func rounded() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    FoodRecognitionView(viewModel: FoodRecognitionViewModel())
}