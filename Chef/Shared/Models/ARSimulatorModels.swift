//
//  ARSimulatorModels.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/23.
//

import Foundation

// MARK: - AR Recipe Models for Simulator

struct ARRecipe {
    let id: String
    let name: String
    let description: String
    let steps: [ARCookingStep]
    let ingredients: [ARIngredient]
    let equipment: [AREquipment]
}

struct ARCookingStep {
    let stepNumber: Int
    let title: String
    let description: String
    let actions: [ARAction]?
    let estimatedTime: String?
    let temperature: String?
    let warnings: String?
    let notes: String?
}

struct ARAction {
    let type: String
    let tool: String?
    let materials: [String]?
    let duration: Int
    let instructions: String?
    let temperature: String?
}

struct ARIngredient {
    let name: String
    let type: String
    let amount: String
    let unit: String
    let preparation: String?
}

struct AREquipment {
    let name: String
    let type: String
    let size: String?
    let material: String?
    let powerSource: String?
}

// MARK: - Extensions for Conversion

extension RecipeRecommendationResponse {
    func toARRecipe() -> ARRecipe {
        return ARRecipe(
            id: UUID().uuidString,
            name: dishName,
            description: dishDescription,
            steps: recipe.map { step in
                ARCookingStep(
                    stepNumber: step.step_number,
                    title: step.title,
                    description: step.description,
                    actions: step.actions.map { action in
                        ARAction(
                            type: action.action,
                            tool: action.tool_required,
                            materials: action.material_required,
                            duration: action.time_minutes,
                            instructions: action.instruction_detail,
                            temperature: step.temperature
                        )
                    },
                    estimatedTime: step.estimated_total_time,
                    temperature: step.temperature,
                    warnings: step.warnings,
                    notes: step.notes
                )
            },
            ingredients: ingredients.map { ingredient in
                ARIngredient(
                    name: ingredient.name,
                    type: ingredient.type,
                    amount: ingredient.amount,
                    unit: ingredient.unit,
                    preparation: ingredient.preparation
                )
            },
            equipment: equipment.map { equipment in
                AREquipment(
                    name: equipment.name,
                    type: equipment.type,
                    size: equipment.size,
                    material: equipment.material,
                    powerSource: equipment.power_source
                )
            }
        )
    }
}