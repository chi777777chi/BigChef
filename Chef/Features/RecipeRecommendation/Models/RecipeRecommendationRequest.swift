//
//  RecipeRecommendationRequest.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import Foundation

// MARK: - Available Ingredient Model

struct AvailableIngredient: Codable, Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let amount: String
    let unit: String
    let preparation: String

    enum CodingKeys: String, CodingKey {
        case name, type, amount, unit, preparation
    }

    init(name: String, type: String, amount: String, unit: String, preparation: String) {
        self.name = name
        self.type = type
        self.amount = amount
        self.unit = unit
        self.preparation = preparation
    }
}

// MARK: - Available Equipment Model

struct AvailableEquipment: Codable, Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let size: String
    let material: String
    let powerSource: String

    enum CodingKeys: String, CodingKey {
        case name, type, size, material
        case powerSource = "power_source"
    }

    init(name: String, type: String, size: String, material: String, powerSource: String) {
        self.name = name
        self.type = type
        self.size = size
        self.material = material
        self.powerSource = powerSource
    }
}

// MARK: - Recommendation Preference Model

struct RecommendationPreference: Codable {
    let cookingMethod: String?
    let dietaryRestrictions: [String]?
    let servingSize: String?
    let recipeDescription: String?

    enum CodingKeys: String, CodingKey {
        case cookingMethod = "cooking_method"
        case dietaryRestrictions = "dietary_restrictions"
        case servingSize = "serving_size"
        case recipeDescription = "recipe_description"
    }

    init(cookingMethod: String?, dietaryRestrictions: [String]?, servingSize: String?, recipeDescription: String? = nil) {
        self.cookingMethod = cookingMethod
        self.dietaryRestrictions = dietaryRestrictions
        self.servingSize = servingSize
        self.recipeDescription = recipeDescription
    }
}

// MARK: - Recipe Recommendation Request Model

struct RecipeRecommendationRequest: Codable {
    let availableIngredients: [AvailableIngredient]
    let availableEquipment: [AvailableEquipment]
    let preference: RecommendationPreference

    enum CodingKeys: String, CodingKey {
        case availableIngredients = "available_ingredients"
        case availableEquipment = "available_equipment"
        case preference
    }

    init(availableIngredients: [AvailableIngredient], availableEquipment: [AvailableEquipment], preference: RecommendationPreference) {
        self.availableIngredients = availableIngredients
        self.availableEquipment = availableEquipment
        self.preference = preference
    }
}

// MARK: - Extensions for convenience

extension AvailableIngredient {
    static func sample() -> AvailableIngredient {
        AvailableIngredient(
            name: "蛋",
            type: "蛋類",
            amount: "2",
            unit: "顆",
            preparation: "打散"
        )
    }
}

extension AvailableEquipment {
    static func sample() -> AvailableEquipment {
        AvailableEquipment(
            name: "平底鍋",
            type: "鍋具",
            size: "小型",
            material: "不沾",
            powerSource: "電"
        )
    }
}

extension RecommendationPreference {
    static func sample() -> RecommendationPreference {
        RecommendationPreference(
            cookingMethod: "煎",
            dietaryRestrictions: ["無麩質"],
            servingSize: "1人份",
            recipeDescription: "希望是簡單易做的家常菜"
        )
    }
}

extension RecipeRecommendationRequest {
    static func sample() -> RecipeRecommendationRequest {
        RecipeRecommendationRequest(
            availableIngredients: [.sample()],
            availableEquipment: [.sample()],
            preference: .sample()
        )
    }
}