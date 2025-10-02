//
//  FoodRecognitionView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import SwiftUI

// MARK: - 視圖狀態枚舉
enum FoodRecognitionViewState {
    case initial           // 初始狀態
    case imageSelected     // 已選擇圖片
    case recognizing      // 辨識中
    case result(FoodRecognitionResponse)  // 顯示結果
    case error(FoodRecognitionError)     // 錯誤狀態
}

struct FoodRecognitionView: View {
    @StateObject private var viewModel: FoodRecognitionViewModel
    @State private var descriptionHint = ""
    @EnvironmentObject private var coordinator: FoodRecognitionCoordinator

    // 使用 ViewModel 的計算屬性
    private var currentViewState: FoodRecognitionViewState {
        viewModel.currentViewState
    }

    init(viewModel: FoodRecognitionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 根據狀態顯示不同內容
                switch currentViewState {
                case .initial:
                    initialStateView
                case .imageSelected:
                    imageSelectedStateView
                case .recognizing:
                    recognizingStateView
                case .result(let response):
                    resultStateView(response)
                case .error(let error):
                    errorStateView(error)
                }
            }
            .padding()
        }
        .navigationTitle("食物辨識")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.hasSelectedImage || viewModel.hasResult {
                    Button("重新開始") {
                        withAnimation {
                            viewModel.clearSelection()
                            descriptionHint = ""
                        }
                    }
                    .foregroundColor(.brandOrange)
                }
            }
        }
        .imageSourcePicker(
            isPresented: $viewModel.showImageSourcePicker,
            selectedImage: $viewModel.selectedImage,
            onImageSelected: { image in
                viewModel.handleImageSelection(image)
            }
        )
    }

    // MARK: - State Views

    private var initialStateView: some View {
        VStack(spacing: 32) {
            // Header Section
            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.brandOrange)

                Text("食物圖片辨識")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("拍攝或選擇食物圖片，AI 將自動辨識並分析食材組成")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Image Upload Area
            imageUploadPlaceholder

            // Action Buttons
            imageSelectionButtons
        }
    }

    private var imageSelectedStateView: some View {
        VStack(spacing: 24) {
            // Selected Image Preview
            if let image = viewModel.selectedImage {
                VStack(spacing: 16) {
                    Text("已選擇圖片")
                        .font(.headline)
                        .foregroundColor(.brandOrange)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }
            }

            // Description Input
            descriptionInputSection

            // Recognition Button
            recognitionButton

            // Change Image Button
            Button("重新選擇圖片") {
                viewModel.selectImageSource()
            }
            .foregroundColor(.brandOrange)
            .disabled(!viewModel.canSelectNewImage)
        }
    }

    private var recognizingStateView: some View {
        VStack(spacing: 32) {
            // Loading Animation with Progress
            VStack(spacing: 24) {
                if viewModel.shouldShowProgress {
                    ProgressView(value: viewModel.recognitionProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .brandOrange))
                        .scaleEffect(1.2)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .brandOrange))
                }

                Text(viewModel.progressDescription)
                    .font(.title3)
                    .fontWeight(.medium)

                if viewModel.isRetrying {
                    Text("正在重試辨識，請稍候...")
                        .font(.body)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                } else {
                    Text("AI 正在分析您的食物圖片，請稍候")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // 顯示進度百分比
                if viewModel.shouldShowProgress {
                    Text("\(Int(viewModel.recognitionProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.brandOrange)
                        .fontWeight(.semibold)
                }
            }

            // Selected Image (smaller)
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .opacity(0.7)
            }
        }
        .padding()
    }

    private func resultStateView(_ response: FoodRecognitionResponse) -> some View {
        FoodRecognitionResultView(
            result: response,
            selectedImage: viewModel.selectedImage,
            onRetry: {
                viewModel.retryRecognition()
            },
            onGenerateRecipe: {
                // 直接導航到食譜推薦頁面，跳過食材器具確認步驟
                handleDirectRecipeGeneration(from: response)
            }
        )
    }

    // MARK: - Helper Methods

    /// 處理直接生成食譜功能（跳過食材器具確認步驟）
    private func handleDirectRecipeGeneration(from response: FoodRecognitionResponse) {
        print("🚀 直接生成食譜按鈕被點擊，跳過食材器具確認步驟")
        print("辨識出的食物：\(response.recognizedFoods.map { $0.name }.joined(separator: ", "))")

        // 提取所有辨識出的食材和器具名稱
        let allIngredients = response.allIngredients.map { $0.name }
        let allEquipment = response.allEquipment.map { $0.name }

        // 獲取主要辨識食物的名稱
        let recognizedFoodName = response.recognizedFoods.first?.name

        print("📋 準備使用食材：\(allIngredients)")
        print("🔧 準備使用器具：\(allEquipment)")
        print("🍽️ 主要食物：\(recognizedFoodName ?? "未知")")

        // 直接導航到食譜推薦頁面，跳過食材確認
        coordinator.navigateToRecipeGenerationWithFoodName(
            ingredients: allIngredients,
            equipment: allEquipment,
            recognizedFoodName: recognizedFoodName
        )
    }


    private func errorStateView(_ error: FoodRecognitionError) -> some View {
        FoodRecognitionErrorView(
            error: error,
            selectedImage: viewModel.selectedImage,
            isRetryable: viewModel.isErrorRetryable,
            onRetry: {
                viewModel.retryRecognition()
            },
            onSelectNewImage: {
                viewModel.selectImageSource()
            }
        )
    }

    // MARK: - UI Components

    private var imageUploadPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                Color.brandOrange.opacity(0.3),
                style: StrokeStyle(lineWidth: 2, dash: [10, 5])
            )
            .frame(height: 200)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.brandOrange.opacity(0.7))

                    VStack(spacing: 8) {
                        Text("點擊選擇食物圖片")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("支援拍照或從相簿選擇")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectImageSource()
            }
    }

    private var imageSelectionButtons: some View {
        HStack(spacing: 16) {
            // Camera Button
            Button(action: {
                viewModel.showCameraAction()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text("拍照")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canSelectNewImage)

            // Photo Library Button
            Button(action: {
                viewModel.showPhotoLibraryAction()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                    Text("相簿")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange.opacity(0.15))
                .foregroundColor(.brandOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canSelectNewImage)
        }
    }

    private var descriptionInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("描述提示（可選）")
                .font(.headline)
                .foregroundColor(.primary)

            TextField("描述這道菜（可選）", text: $descriptionHint)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    viewModel.updateDescriptionHint(descriptionHint)
                }

            Text("提供描述有助於 AI 更準確地辨識食物")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var recognitionButton: some View {
        Button(action: {
            viewModel.updateDescriptionHint(descriptionHint)
            viewModel.recognizeFood()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                Text("開始辨識")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.canStartRecognition ? Color.brandOrange : Color.gray
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!viewModel.canStartRecognition)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canStartRecognition)
    }
}

// MARK: - Preview

#Preview {
    FoodRecognitionView(viewModel: FoodRecognitionViewModel())
}