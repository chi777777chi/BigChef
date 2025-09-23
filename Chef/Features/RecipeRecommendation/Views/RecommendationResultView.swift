//
//  RecommendationResultView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI
import ARKit
import AVFoundation

struct RecommendationResultView: View {
    let result: RecipeRecommendationResponse
    @ObservedObject var viewModel: RecipeRecommendationViewModel
    let coordinator: RecipeRecommendationCoordinator

    // AR 載入狀態
    @State private var isStartingAR = false
    @State private var showingARError = false
    @State private var arError: ARError?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Recipe Header
                recipeHeaderSection

                // Ingredients Section
                ingredientsSection

                // Equipment Section
                equipmentSection

                // Recipe Steps Section
                recipeStepsSection

                // Action Buttons
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("推薦結果")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("重新配置") {
                    viewModel.resetToConfiguring()
                }
                .foregroundColor(.brandOrange)
            }
        }
        .alert("AR 功能錯誤", isPresented: $showingARError) {
            Button("確定") {
                showingARError = false
            }
            if let error = arError, error.showSettingsButton {
                Button("前往設定") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
        } message: {
            VStack {
                if let error = arError {
                    Text(error.localizedDescription ?? "發生未知錯誤")
                    if let recovery = error.recoveryMessage {
                        Text(recovery)
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var recipeHeaderSection: some View {
        VStack(spacing: 16) {
            // Recipe Icon
            Image(systemName: "chef.hat.fill")
                .font(.system(size: 60))
                .foregroundColor(.brandOrange)

            // Recipe Title and Description
            VStack(spacing: 8) {
                Text(result.dishName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(result.dishDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Recipe Info
            HStack(spacing: 20) {
                RecipeInfoItem(
                    icon: "clock",
                    title: "總時間",
                    value: result.totalEstimatedTime
                )

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)

                RecipeInfoItem(
                    icon: "list.number",
                    title: "步驟",
                    value: "\(result.totalSteps)個"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "carrot.fill")
                    .foregroundColor(.brandOrange)

                Text("使用食材")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(result.ingredients.count)種")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(result.ingredients, id: \.name) { ingredient in
                    ResultIngredientItemView(ingredient: ingredient)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "frying.pan.fill")
                    .foregroundColor(.brandOrange)

                Text("使用器具")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(result.equipment.count)種")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(result.equipment, id: \.name) { equipment in
                    ResultEquipmentItemView(equipment: equipment)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var recipeStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.brandOrange)

                Text("製作步驟")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            VStack(spacing: 16) {
                ForEach(Array(result.recipe.enumerated()), id: \.element.step_number) { index, step in
                    RecipeStepView(step: step, stepIndex: index + 1)
                }
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Retry Button
            Button(action: {
                Task {
                    await viewModel.startRecommendation()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                    Text("重新推薦")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Start Cooking Button
            Button(action: startCooking) {
                HStack(spacing: 8) {
                    if isStartingAR {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arkit")
                            .font(.title3)
                    }
                    Text("開始烹飪")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isStartingAR)
        }
    }

    // MARK: - Action Methods

    /// 開始烹飪方法
    private func startCooking() {
        print("🍳 準備啟動 AR 烹飪模式")
        print("📋 食譜名稱: \(result.dishName)")
        print("📝 步驟數量: \(result.recipe.count)")

        isStartingAR = true

        Task {
            do {
                // 檢查 AR 支援（真實設備上才檢查）
                #if !targetEnvironment(simulator)
                guard ARWorldTrackingConfiguration.isSupported else {
                    await showARError(.deviceNotSupported)
                    return
                }

                // 檢查相機權限
                let hasPermission = await requestCameraPermission()
                guard hasPermission else {
                    await showARError(.cameraPermissionDenied)
                    return
                }
                #endif

                print("✅ AR 前置檢查完成，啟動 AR 烹飪模式")
                await launchARCooking()

            } catch {
                await showARError(.unknown(error.localizedDescription))
            }
        }
    }

    private func requestCameraPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                continuation.resume(returning: true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            case .denied, .restricted:
                continuation.resume(returning: false)
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }

    @MainActor
    private func launchARCooking() {
        isStartingAR = false
        coordinator.startARCooking(with: result.recipe)
    }

    @MainActor
    private func showARError(_ error: ARError) {
        arError = error
        showingARError = true
        isStartingAR = false
        print("❌ AR 錯誤: \(error.localizedDescription ?? "未知錯誤")")
    }
}

// MARK: - Supporting Views

private struct RecipeInfoItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandOrange)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

private struct ResultIngredientItemView: View {
    let ingredient: Ingredient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(.brandOrange)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(ingredient.name)
                        .font(.body)
                        .fontWeight(.medium)

                    Text("(\(ingredient.type))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(ingredient.amount) \(ingredient.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !ingredient.preparation.isEmpty {
                    Text(ingredient.preparation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ResultEquipmentItemView: View {
    let equipment: Equipment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(.brandOrange)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(equipment.name)
                        .font(.body)
                        .fontWeight(.medium)

                    Text("(\(equipment.type))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                HStack(spacing: 8) {
                    if !equipment.size.isEmpty {
                        Text(equipment.size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.material.isEmpty {
                        Text("• \(equipment.material)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !equipment.power_source.isEmpty && equipment.power_source != "無" {
                        Text("• \(equipment.power_source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Preview

#Preview {
    let sampleResponse = RecipeRecommendationResponse.sample()
    let viewModel = RecipeRecommendationViewModel()
    let coordinator = RecipeRecommendationCoordinator(navigationController: UINavigationController())

    RecommendationResultView(result: sampleResponse, viewModel: viewModel, coordinator: coordinator)
}