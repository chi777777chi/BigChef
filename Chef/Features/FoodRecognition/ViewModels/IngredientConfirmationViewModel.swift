//
//  IngredientConfirmationViewModel.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/27.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class IngredientConfirmationViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var recognizedIngredients: [PossibleIngredient] = []
    @Published var recognizedEquipment: [PossibleEquipment] = []
    @Published var selectedIngredients: Set<String> = []
    @Published var selectedEquipment: Set<String> = []
    @Published var customIngredients: [String] = []
    @Published var customEquipment: [String] = []
    @Published var newIngredientName: String = ""
    @Published var newEquipmentName: String = ""
    @Published var isFormValid: Bool = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var totalSelectedIngredients: [String] {
        let recognized = selectedIngredients.map { $0 }
        return recognized + customIngredients
    }

    var totalSelectedEquipment: [String] {
        let recognized = selectedEquipment.map { $0 }
        return recognized + customEquipment
    }

    var canProceed: Bool {
        return !totalSelectedIngredients.isEmpty
    }

    // MARK: - Initializer
    init() {
        setupObservations()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Public Methods

    func configure(with recognitionResult: FoodRecognitionResponse) {
        print("🔄 IngredientConfirmationViewModel: 配置辨識結果")

        // 從所有辨識出的食物中提取食材和器具
        recognizedIngredients = recognitionResult.recognizedFoods.flatMap { $0.possibleIngredients }
        recognizedEquipment = recognitionResult.recognizedFoods.flatMap { $0.possibleEquipment }

        // 預設選中所有辨識到的食材和器具
        selectedIngredients = Set(recognizedIngredients.map { $0.name })
        selectedEquipment = Set(recognizedEquipment.map { $0.name })

        print("  辨識食材: \(recognizedIngredients.map { $0.name })")
        print("  辨識器具: \(recognizedEquipment.map { $0.name })")

        validateForm()
    }

    func toggleIngredientSelection(_ ingredientName: String) {
        if selectedIngredients.contains(ingredientName) {
            selectedIngredients.remove(ingredientName)
        } else {
            selectedIngredients.insert(ingredientName)
        }
        print("🥬 切換食材選擇: \(ingredientName) - 已選擇: \(selectedIngredients.contains(ingredientName))")
    }

    func toggleEquipmentSelection(_ equipmentName: String) {
        if selectedEquipment.contains(equipmentName) {
            selectedEquipment.remove(equipmentName)
        } else {
            selectedEquipment.insert(equipmentName)
        }
        print("🔧 切換器具選擇: \(equipmentName) - 已選擇: \(selectedEquipment.contains(equipmentName))")
    }

    func addCustomIngredient() {
        let trimmedName = newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // 檢查是否已存在
        guard !customIngredients.contains(trimmedName),
              !recognizedIngredients.contains(where: { $0.name == trimmedName }) else {
            print("❌ 食材已存在: \(trimmedName)")
            return
        }

        customIngredients.append(trimmedName)
        newIngredientName = ""
        print("➕ 新增自訂食材: \(trimmedName)")
    }

    func removeCustomIngredient(at index: Int) {
        guard index < customIngredients.count else { return }
        let removed = customIngredients.remove(at: index)
        print("➖ 移除自訂食材: \(removed)")
    }

    func addCustomEquipment() {
        let trimmedName = newEquipmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // 檢查是否已存在
        guard !customEquipment.contains(trimmedName),
              !recognizedEquipment.contains(where: { $0.name == trimmedName }) else {
            print("❌ 器具已存在: \(trimmedName)")
            return
        }

        customEquipment.append(trimmedName)
        newEquipmentName = ""
        print("➕ 新增自訂器具: \(trimmedName)")
    }

    func removeCustomEquipment(at index: Int) {
        guard index < customEquipment.count else { return }
        let removed = customEquipment.remove(at: index)
        print("➖ 移除自訂器具: \(removed)")
    }

    func selectAllIngredients() {
        selectedIngredients = Set(recognizedIngredients.map { $0.name })
        print("✅ 選擇所有食材")
    }

    func deselectAllIngredients() {
        selectedIngredients.removeAll()
        print("❌ 取消選擇所有食材")
    }

    func selectAllEquipment() {
        selectedEquipment = Set(recognizedEquipment.map { $0.name })
        print("✅ 選擇所有器具")
    }

    func addScannedIngredient(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // 檢查是否已存在
        guard !customIngredients.contains(trimmedName),
              !recognizedIngredients.contains(where: { $0.name == trimmedName }) else {
            print("❌ 食材已存在: \(trimmedName)")
            return
        }

        customIngredients.append(trimmedName)
        print("➕ 新增掃描食材: \(trimmedName)")
    }

    func addScannedEquipment(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // 檢查是否已存在
        guard !customEquipment.contains(trimmedName),
              !recognizedEquipment.contains(where: { $0.name == trimmedName }) else {
            print("❌ 器具已存在: \(trimmedName)")
            return
        }

        customEquipment.append(trimmedName)
        print("➕ 新增掃描器具: \(trimmedName)")
    }

    func deselectAllEquipment() {
        selectedEquipment.removeAll()
        print("❌ 取消選擇所有器具")
    }

    // MARK: - Private Methods

    private func setupObservations() {
        Publishers.CombineLatest4($selectedIngredients, $selectedEquipment, $customIngredients, $customEquipment)
            .sink { [weak self] _, _, _, _ in
                self?.validateForm()
            }
            .store(in: &cancellables)
    }

    private func validateForm() {
        isFormValid = canProceed
    }
}