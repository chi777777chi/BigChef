//
//  IngredientConfirmationView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/27.
//

import SwiftUI

struct IngredientConfirmationView: View {
    @StateObject private var viewModel = IngredientConfirmationViewModel()
    @EnvironmentObject private var coordinator: FoodRecognitionCoordinator

    let recognitionResult: FoodRecognitionResponse
    let onConfirm: ([String], [String]) -> Void
    let onCancel: () -> Void

    @State private var showingAddIngredientOptions = false
    @State private var showingAddEquipmentOptions = false
    @State private var showingIngredientScan = false
    @State private var showingEquipmentScan = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                ingredientsSection
                equipmentSection
                actionButtons
            }
            .padding()
        }
        .navigationTitle("確認食材器具")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    onCancel()
                }
            }
        }
        .onAppear {
            viewModel.configure(with: recognitionResult)
        }
        .sheet(isPresented: $showingIngredientScan) {
            IngredientScanView(scanMode: .ingredientOnly) { ingredients, equipment in
                // 只加入食材
                for ingredient in ingredients {
                    viewModel.addScannedIngredient(ingredient.name)
                }
            }
        }
        .sheet(isPresented: $showingEquipmentScan) {
            IngredientScanView(scanMode: .equipmentOnly) { ingredients, equipment in
                // 只加入器具
                for equip in equipment {
                    viewModel.addScannedEquipment(equip.name)
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("辨識完成")
                .font(.title2)
                .fontWeight(.bold)

            // 顯示辨識出的食物名稱
            if let primaryFood = recognitionResult.recognizedFoods.first {
                RecognizedFoodNameSection(
                    foodName: primaryFood.name,
                    description: primaryFood.description
                )
            }

            Text("請確認下方的食材和器具，您可以調整選擇或新增項目")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("食材")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Menu {
                    Button("全選") {
                        viewModel.selectAllIngredients()
                    }
                    Button("全不選") {
                        viewModel.deselectAllIngredients()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }

            if !viewModel.recognizedIngredients.isEmpty {
                Text("辨識到的食材")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.recognizedIngredients, id: \.id) { ingredient in
                        IngredientCard(
                            name: ingredient.name,
                            type: ingredient.type,
                            confidence: 0.8, // PossibleIngredient doesn't have confidence, use default
                            isSelected: viewModel.selectedIngredients.contains(ingredient.name)
                        ) {
                            viewModel.toggleIngredientSelection(ingredient.name)
                        }
                    }
                }
            }

            if !viewModel.customIngredients.isEmpty {
                Text("自訂食材")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(Array(viewModel.customIngredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack {
                        Text(ingredient)
                            .font(.body)
                        Spacer()
                        Button(action: {
                            viewModel.removeCustomIngredient(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }

            addIngredientField
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var addIngredientField: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("手動輸入食材", text: $viewModel.newIngredientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        viewModel.addCustomIngredient()
                    }

                Button(action: {
                    viewModel.addCustomIngredient()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button(action: {
                showingIngredientScan = true
            }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("掃描新增食材")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brandOrange.opacity(0.1))
                .foregroundColor(.brandOrange)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Equipment Section
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("器具")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Menu {
                    Button("全選") {
                        viewModel.selectAllEquipment()
                    }
                    Button("全不選") {
                        viewModel.deselectAllEquipment()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }

            if !viewModel.recognizedEquipment.isEmpty {
                Text("辨識到的器具")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.recognizedEquipment, id: \.id) { equipment in
                        EquipmentCard(
                            name: equipment.name,
                            type: equipment.type,
                            confidence: 0.8, // PossibleEquipment doesn't have confidence, use default
                            isSelected: viewModel.selectedEquipment.contains(equipment.name)
                        ) {
                            viewModel.toggleEquipmentSelection(equipment.name)
                        }
                    }
                }
            }

            if !viewModel.customEquipment.isEmpty {
                Text("自訂器具")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(Array(viewModel.customEquipment.enumerated()), id: \.offset) { index, equipment in
                    HStack {
                        Text(equipment)
                            .font(.body)
                        Spacer()
                        Button(action: {
                            viewModel.removeCustomEquipment(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }

            addEquipmentField
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var addEquipmentField: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("手動輸入器具", text: $viewModel.newEquipmentName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        viewModel.addCustomEquipment()
                    }

                Button(action: {
                    viewModel.addCustomEquipment()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.newEquipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button(action: {
                showingEquipmentScan = true
            }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("掃描新增器具")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brandOrange.opacity(0.1))
                .foregroundColor(.brandOrange)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                onConfirm(viewModel.totalSelectedIngredients, viewModel.totalSelectedEquipment)
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("確認並生成食譜")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canProceed ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canProceed)

            Text("已選擇 \(viewModel.totalSelectedIngredients.count) 項食材，\(viewModel.totalSelectedEquipment.count) 項器具")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Views

struct IngredientCard: View {
    let name: String
    let type: String
    let confidence: Double
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }

                Text(type)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("信心度")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(confidence > 0.8 ? .green : confidence > 0.6 ? .orange : .red)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EquipmentCard: View {
    let name: String
    let type: String
    let confidence: Double
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }

                Text(type)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("信心度")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(confidence > 0.8 ? .green : confidence > 0.6 ? .orange : .red)
                }
            }
            .padding(12)
            .background(isSelected ? Color.orange.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct RecognizedFoodNameSection: View {
    let foodName: String
    let description: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "camera.viewfinder")
                    .foregroundColor(.blue)
                Text("辨識結果")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            VStack(spacing: 4) {
                HStack {
                    Text("我們辨識出這是：")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Text(foodName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("我們將為您生成 \(foodName) 的製作食譜")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    IngredientConfirmationView(
        recognitionResult: FoodRecognitionResponse(
            recognizedFoods: [
                RecognizedFood(
                    name: "番茄炒蛋",
                    description: "一道經典的家常菜",
                    possibleIngredients: [
                        PossibleIngredient(name: "番茄", type: "蔬菜"),
                        PossibleIngredient(name: "雞蛋", type: "蛋類")
                    ],
                    possibleEquipment: [
                        PossibleEquipment(name: "平底鍋", type: "鍋具")
                    ]
                )
            ]
        ),
        onConfirm: { _, _ in },
        onCancel: { }
    )
    .environmentObject(FoodRecognitionCoordinator(navigationController: UINavigationController()))
}