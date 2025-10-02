import Foundation
import SwiftUI
import Combine

// MARK: - Recipe Service Implementation
private struct RecipeServiceImplementation: RecipeServiceProtocol {
    func generateRecipe(using request: SuggestRecipeRequest) async throws -> SuggestRecipeResponse {
        try await RecipeService.generateRecipe(using: request)
    }
    
    func scanImageForIngredients(using request: ScanImageRequest) async throws -> ScanImageResponse {
        try await RecipeService.scanImageForIngredients(using: request)
    }
}

@MainActor
final class ScanningViewModel: ObservableObject {
    // MARK: - Dependencies
    private let state: ScanningState
    private let recipeService: RecipeServiceProtocol
    
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var isShowingImagePicker = false
    @Published private(set) var isShowingImagePreview = false
    @Published private(set) var selectedImage: UIImage?
    @Published private(set) var descriptionHint = ""
    @Published private(set) var equipment: [Equipment] = []
    @Published private(set) var ingredients: [Ingredient] = []
    
    // MARK: - Callbacks
    private var onNavigateToRecipe: ((SuggestRecipeResponse) -> Void)?
    
    // MARK: - Initialization
    init(
        state: ScanningState,
        recipeService: RecipeServiceProtocol = RecipeServiceImplementation(),
        onNavigateToRecipe: ((SuggestRecipeResponse) -> Void)? = nil
    ) {
        self.state = state
        self.recipeService = recipeService
        self.onNavigateToRecipe = onNavigateToRecipe
    }
    
    // MARK: - Public Methods
    
    func showImagePicker() {
        isShowingImagePicker = true
    }
    
    func hideImagePicker() {
        isShowingImagePicker = false
    }
    
    func handleSelectedImage(_ image: UIImage?) {
        selectedImage = image
        if image != nil {
            isShowingImagePreview = true
        }
    }
    
    func hideImagePreview() {
        isShowingImagePreview = false
        selectedImage = nil
        descriptionHint = ""
    }
    
    func updateDescriptionHint(_ hint: String) {
        descriptionHint = hint
    }
    
    // MARK: - Equipment Management
    
    func removeEquipment(_ equipment: Equipment) {
        self.equipment.removeAll { $0.id == equipment.id }
    }
    
    func upsertEquipment(_ new: Equipment) {
        if let idx = equipment.firstIndex(where: { $0.id == new.id }) {
            equipment[idx] = new
        } else {
            equipment.append(new)
        }
    }
    
    // MARK: - Ingredient Management
    
    func removeIngredient(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
    }
    
    func upsertIngredient(_ new: Ingredient) {
        if let idx = ingredients.firstIndex(where: { $0.id == new.id }) {
            ingredients[idx] = new
        } else {
            ingredients.append(new)
        }
    }
    
    // MARK: - Recipe Generation
    
    func generateRecipe() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let request = SuggestRecipeRequest(
            available_ingredients: ingredients,
            available_equipment: equipment,
            preference: state.preference
        )
        
        do {
            let response = try await recipeService.generateRecipe(using: request)
            print("✅ 成功生成食譜，菜名：\(response.dish_name)")
            onNavigateToRecipe?(response)
        } catch {
            print(error)
            print("❌ 生成食譜失敗：\(error.localizedDescription)")
            // TODO: 處理錯誤狀態
        }
    }
    
    // MARK: - Image Scanning
    
    func scanImage() async {
        guard !isLoading, let image = selectedImage else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let request = ScanImageRequest(
            image: ImageCompressor.compressToBase64(image: image) ?? "",
            description_hint: descriptionHint
        )
        
        do {
            let response = try await recipeService.scanImageForIngredients(using: request)
            print("✅ 掃描成功，摘要：\(response.summary)")
            
            // 更新食材和設備列表
            for ingredient in response.ingredients {
                upsertIngredient(ingredient)
            }
            
            for equipment in response.equipment {
                upsertEquipment(equipment)
            }
            
            // 更新狀態
            hideImagePreview()
            state.showCompletionAlert(with: response.summary)
            
        } catch {
            print("❌ 掃描失敗：\(error.localizedDescription)")
            // TODO: 處理錯誤狀態
        }
    }
    
    // MARK: - Preference Helpers
    
    var cookingMethod: String {
        get { state.preference.cooking_method }
        set { state.preference.cooking_method = newValue }
    }
    
    func updateCookingMethod(_ method: String) {
        state.preference.cooking_method = method
    }
    
    func updateDietaryRestrictions(_ restrictions: String) {
        state.preference.dietary_restrictions = restrictions
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    func updateServingSize(_ size: Int) {
        state.preference.serving_size = "\(size)人份"
    }
    
    var servingSize: Int {
        Int(state.preference.serving_size.replacingOccurrences(of: "人份", with: "")) ?? 1
    }
    
    var dietaryRestrictionsString: String {
        state.preference.dietary_restrictions.joined(separator: ", ")
    }
}

// MARK: - Protocol for Recipe Service
protocol RecipeServiceProtocol {
    func generateRecipe(using request: SuggestRecipeRequest) async throws -> SuggestRecipeResponse
    func scanImageForIngredients(using request: ScanImageRequest) async throws -> ScanImageResponse
}
