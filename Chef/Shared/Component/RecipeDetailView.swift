//
//  RecipeDetailView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/23.
//

import SwiftUI

struct RecipeDetailView: View {
    let dishName: String
    let dishDescription: String
    let ingredients: [Ingredient]
    let equipment: [Equipment]
    let recipeSteps: [RecipeStep]
    let showARButton: Bool
    let showNavigationBar: Bool
    let onStartCooking: () -> Void
    let onBack: (() -> Void)?
    let onFavorite: (() -> Void)?

    init(
        dishName: String,
        dishDescription: String,
        ingredients: [Ingredient],
        equipment: [Equipment],
        recipeSteps: [RecipeStep],
        showARButton: Bool = true,
        showNavigationBar: Bool = true,
        onStartCooking: @escaping () -> Void,
        onBack: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil
    ) {
        self.dishName = dishName
        self.dishDescription = dishDescription
        self.ingredients = ingredients
        self.equipment = equipment
        self.recipeSteps = recipeSteps
        self.showARButton = showARButton
        self.showNavigationBar = showNavigationBar
        self.onStartCooking = onStartCooking
        self.onBack = onBack
        self.onFavorite = onFavorite
    }

    var body: some View {
        VStack(spacing: 0) {
            if showNavigationBar {
                customNavigationBar
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Recipe Header Section
                    recipeHeaderSection

                    // Ingredients Section
                    if !ingredients.isEmpty {
                        ingredientsSection
                    }

                    // Equipment Section
                    if !equipment.isEmpty {
                        equipmentSection
                    }

                    // Recipe Steps Section
                    recipeStepsSection
                }
                .padding()
            }

            if showARButton {
                // AR Cooking Button
                CookingActionButton(
                    title: "開始烹飪",
                    action: onStartCooking
                )
                .padding()
            }
        }
    }

    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            // Back Button
            if let onBack = onBack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                }
            } else {
                // Placeholder for layout balance
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 80, height: 36)
            }

            Spacer()

            // Recipe Title
            Text("食譜詳情")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // Favorite Button
            if let onFavorite = onFavorite {
                Button(action: onFavorite) {
                    Image(systemName: "heart")
                        .font(.system(size: 20))
                        .foregroundColor(.pink)
                        .padding(8)
                }
            } else {
                // Placeholder for layout balance
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }

    // MARK: - Recipe Header Section
    private var recipeHeaderSection: some View {
        VStack(spacing: 16) {
            // Recipe Icon
            Image(systemName: "leaf")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.brandOrange, lineWidth: 2))
                .foregroundColor(.brandOrange)

            Text("食譜")
                .font(.headline)
                .foregroundColor(.brandOrange)

            Text(dishName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(dishDescription)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }

    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "carrot.fill")
                    .foregroundColor(.brandOrange)
                Text("食材")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(ingredients.count)種")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(ingredients, id: \.id) { ingredient in
                    RecipeIngredientItemView(ingredient: ingredient)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Equipment Section
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "frying.pan.fill")
                    .foregroundColor(.brandOrange)
                Text("器具")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(equipment.count)種")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(equipment, id: \.id) { equipment in
                    RecipeEquipmentItemView(equipment: equipment)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Recipe Steps Section
    private var recipeStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("烹飪步驟")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)

            let maxTextWidth = UIScreen.main.bounds.width * 0.9

            VStack(alignment: .leading, spacing: 16) {
                ForEach(recipeSteps.indices, id: \.self) { index in
                    RecipeStepCard(
                        step: recipeSteps[index],
                        maxWidth: maxTextWidth
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct RecipeIngredientItemView: View {
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

struct RecipeEquipmentItemView: View {
    let equipment: Equipment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(.brandOrange)

            Text(equipment.name)
                .font(.body)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct RecipeStepCard: View {
    let step: RecipeStep
    let maxWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("步驟 \(step.step_number)：\(step.title)")
                .font(.headline)
                .foregroundColor(.black)

            Text(step.description)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Additional step information
            if !step.estimated_total_time.isEmpty {
                Label(step.estimated_total_time, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !step.notes.isEmpty {
                Text("💡 \(step.notes)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(width: maxWidth, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CookingActionButton: View {
    let title: String
    let action: () -> Void
    @State private var isLoading = false

    var body: some View {
        Button(action: {
            isLoading = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoading = false
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arkit")
                        .font(.title3)
                }

                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brandOrange)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - Convenience Initializers

extension RecipeDetailView {
    // For recommendation results
    init(
        recommendationResult: RecipeRecommendationResponse,
        showARButton: Bool = true,
        showNavigationBar: Bool = true,
        onStartCooking: @escaping () -> Void,
        onBack: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil
    ) {
        self.init(
            dishName: recommendationResult.dishName,
            dishDescription: recommendationResult.dishDescription,
            ingredients: recommendationResult.ingredients,
            equipment: recommendationResult.equipment,
            recipeSteps: recommendationResult.recipe,
            showARButton: showARButton,
            showNavigationBar: showNavigationBar,
            onStartCooking: onStartCooking,
            onBack: onBack,
            onFavorite: onFavorite
        )
    }

    // For regular recipe results
    init(
        recipeResponse: SuggestRecipeResponse,
        showARButton: Bool = true,
        showNavigationBar: Bool = true,
        onStartCooking: @escaping () -> Void,
        onBack: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil
    ) {
        self.init(
            dishName: recipeResponse.dish_name,
            dishDescription: recipeResponse.dish_description,
            ingredients: recipeResponse.ingredients,
            equipment: recipeResponse.equipment,
            recipeSteps: recipeResponse.recipe,
            showARButton: showARButton,
            showNavigationBar: showNavigationBar,
            onStartCooking: onStartCooking,
            onBack: onBack,
            onFavorite: onFavorite
        )
    }
}

// MARK: - Preview

#Preview {
    let sampleResponse = RecipeRecommendationResponse.sample()

    RecipeDetailView(
        recommendationResult: sampleResponse,
        onStartCooking: {
            print("Start cooking AR view")
        },
        onBack: {
            print("Go back")
        },
        onFavorite: {
            print("Toggle favorite")
        }
    )
}