//
//  IngredientScanView.swift
//  ChefHelper
//
//  Created by Claude on 2025/10/01.
//

import SwiftUI

enum ScanMode {
    case ingredientOnly  // 只加入食材
    case equipmentOnly   // 只加入器具
    case both           // 都加入
}

struct IngredientScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = IngredientScanViewModel()

    let scanMode: ScanMode
    let onIngredientsRecognized: ([AvailableIngredient], [AvailableEquipment]) -> Void

    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var descriptionHint = ""

    init(
        scanMode: ScanMode = .both,
        onIngredientsRecognized: @escaping ([AvailableIngredient], [AvailableEquipment]) -> Void
    ) {
        self.scanMode = scanMode
        self.onIngredientsRecognized = onIngredientsRecognized
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 主要內容
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.selectedImage == nil {
                            // 初始狀態
                            initialStateView
                        } else if viewModel.isLoading {
                            // 辨識中
                            loadingStateView
                        } else if let result = viewModel.recognitionResult {
                            // 顯示結果
                            resultStateView(result)
                        } else if let error = viewModel.errorMessage {
                            // 錯誤狀態
                            errorStateView(error)
                        } else {
                            // 已選擇圖片，等待辨識
                            imageSelectedStateView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(
                    sourceType: .camera,
                    selectedImage: $viewModel.selectedImage,
                    onImageSelected: { _ in }
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    sourceType: .photoLibrary,
                    selectedImage: $viewModel.selectedImage,
                    onImageSelected: { _ in }
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        switch scanMode {
        case .ingredientOnly:
            return "掃描食材"
        case .equipmentOnly:
            return "掃描器具"
        case .both:
            return "掃描食材和器具"
        }
    }

    private var scanPromptText: String {
        switch scanMode {
        case .ingredientOnly:
            return "拍攝或選擇食材圖片"
        case .equipmentOnly:
            return "拍攝或選擇器具圖片"
        case .both:
            return "拍攝或選擇食材圖片"
        }
    }

    private var scanDescriptionText: String {
        switch scanMode {
        case .ingredientOnly:
            return "AI 將自動辨識食材"
        case .equipmentOnly:
            return "AI 將自動辨識廚房器具"
        case .both:
            return "AI 將自動辨識食材和器具"
        }
    }

    private var addButtonText: String {
        switch scanMode {
        case .ingredientOnly:
            return "加入食材列表"
        case .equipmentOnly:
            return "加入器具列表"
        case .both:
            return "加入食材和器具"
        }
    }

    // MARK: - View States

    private var initialStateView: some View {
        VStack(spacing: 32) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.brandOrange)

            Text(scanPromptText)
                .font(.title2)
                .fontWeight(.semibold)

            Text(scanDescriptionText)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 圖片選擇按鈕
            imageSelectionButtons
        }
    }

    private var imageSelectedStateView: some View {
        VStack(spacing: 24) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            }

            // 描述提示
            VStack(alignment: .leading, spacing: 12) {
                Text("描述提示（可選）")
                    .font(.headline)

                TextField("例如：蔬菜和鍋子", text: $descriptionHint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("提供描述有助於 AI 更準確地辨識")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 辨識按鈕
            Button(action: {
                viewModel.recognizeIngredients(hint: descriptionHint.isEmpty ? nil : descriptionHint)
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("開始辨識")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // 重新選擇按鈕
            Button("重新選擇圖片") {
                viewModel.selectedImage = nil
                descriptionHint = ""
            }
            .foregroundColor(.brandOrange)
        }
    }

    private var loadingStateView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .brandOrange))

            Text("AI 正在辨識中...")
                .font(.title3)
                .fontWeight(.medium)

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

    private func resultStateView(_ result: IngredientRecognitionResponse) -> some View {
        VStack(spacing: 24) {
            // 成功圖示
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("辨識完成！")
                .font(.title2)
                .fontWeight(.semibold)

            // 摘要
            Text(result.summary)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 辨識結果
            VStack(alignment: .leading, spacing: 16) {
                if !result.ingredients.isEmpty && scanMode != .equipmentOnly {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("辨識到的食材 (\(result.ingredients.count))")
                            .font(.headline)

                        ForEach(result.ingredients, id: \.name) { ingredient in
                            HStack {
                                Image(systemName: "carrot.fill")
                                    .foregroundColor(.brandOrange)
                                Text("\(ingredient.name) - \(ingredient.amount)\(ingredient.unit)")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }

                if !result.equipment.isEmpty && scanMode != .ingredientOnly {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("辨識到的器具 (\(result.equipment.count))")
                            .font(.headline)

                        ForEach(result.equipment, id: \.name) { equipment in
                            HStack {
                                Image(systemName: "frying.pan.fill")
                                    .foregroundColor(.brandOrange)
                                Text(equipment.name)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // 加入按鈕
            Button(action: {
                // 根據掃描模式決定要加入哪些項目
                let ingredients: [AvailableIngredient]
                let equipment: [AvailableEquipment]

                switch scanMode {
                case .ingredientOnly:
                    // 只加入食材
                    ingredients = result.ingredients.map { recognized in
                        AvailableIngredient(
                            name: recognized.name,
                            type: recognized.type,
                            amount: recognized.amount,
                            unit: recognized.unit,
                            preparation: recognized.preparation
                        )
                    }
                    equipment = []

                case .equipmentOnly:
                    // 只加入器具
                    ingredients = []
                    equipment = result.equipment.map { recognized in
                        AvailableEquipment(
                            name: recognized.name,
                            type: recognized.type,
                            size: recognized.size,
                            material: recognized.material,
                            powerSource: recognized.power_source
                        )
                    }

                case .both:
                    // 兩者都加入
                    ingredients = result.ingredients.map { recognized in
                        AvailableIngredient(
                            name: recognized.name,
                            type: recognized.type,
                            amount: recognized.amount,
                            unit: recognized.unit,
                            preparation: recognized.preparation
                        )
                    }
                    equipment = result.equipment.map { recognized in
                        AvailableEquipment(
                            name: recognized.name,
                            type: recognized.type,
                            size: recognized.size,
                            material: recognized.material,
                            powerSource: recognized.power_source
                        )
                    }
                }

                onIngredientsRecognized(ingredients, equipment)
                dismiss()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                    Text(addButtonText)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // 重新掃描按鈕
            Button("重新掃描") {
                viewModel.reset()
                descriptionHint = ""
            }
            .foregroundColor(.brandOrange)
        }
    }

    private func errorStateView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("辨識失敗")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("重試") {
                viewModel.reset()
            }
            .padding()
            .background(Color.brandOrange)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private var imageSelectionButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                showCamera = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("拍照")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            Button(action: {
                showImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("相簿")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange.opacity(0.15))
                .foregroundColor(.brandOrange)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class IngredientScanViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var recognitionResult: IngredientRecognitionResponse?
    @Published var errorMessage: String?

    private let service = IngredientRecognitionService.shared

    func recognizeIngredients(hint: String?) {
        guard let image = selectedImage else { return }

        isLoading = true
        errorMessage = nil
        recognitionResult = nil

        Task {
            do {
                let result = try await service.recognizeIngredients(image: image, hint: hint)
                self.recognitionResult = result
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func reset() {
        selectedImage = nil
        recognitionResult = nil
        errorMessage = nil
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    IngredientScanView { ingredients, equipment in
        print("辨識到的食材：\(ingredients)")
        print("辨識到的器具：\(equipment)")
    }
}
