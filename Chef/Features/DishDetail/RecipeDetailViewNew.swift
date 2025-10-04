//
//  RecipeDetailView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/29.
//

import SwiftUI
import Combine

struct RecipeDetailViewNew: View {
    let recipeName: String
    @StateObject private var viewModel = RecipeDetailViewModel()
    @State private var isDescriptionExpanded = false

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .idle:
                ProgressView("載入中...")
            case .loading:
                ProgressView("載入食譜詳細資料...")
            case .loaded(let recipeDetail):
                ScrollView {
                    VStack(spacing: 20) {
                        // Main Content Card
                        VStack(spacing: 20) {
                            // Title and Author Section
                            titleSection(recipeDetail)

                            // Image and Info Section
                            imageAndInfoSection(recipeDetail)

                            // Description Section
                            descriptionSection(recipeDetail)

                            // Ingredients Section
                            if let ingredients = recipeDetail.ingredients, !ingredients.isEmpty {
                                ingredientsSection(ingredients)
                            }

                            // Instructions Section
                            if let instructions = recipeDetail.instructions, !instructions.isEmpty {
                                instructionsSection(instructions)
                            }

                            // Additional Info Section
                            additionalInfoSection(recipeDetail)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                }
            case .error(let errorMessage):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("載入失敗")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("重試") {
                        viewModel.loadRecipeDetail(recipeName: recipeName)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
        }
        .navigationTitle(recipeName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadRecipeDetail(recipeName: recipeName)
        }
    }

    // MARK: - View Components

    private func titleSection(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)

            if let authorName = recipe.authorName, !authorName.isEmpty {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(.gray)
                    Text("作者：\(authorName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if recipe.displayRating > 0 {
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(recipe.displayRating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    Text(String(format: "%.1f", recipe.displayRating))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func imageAndInfoSection(_ recipe: RecipeDetail) -> some View {
        VStack(spacing: 16) {
            // Recipe Image
            if recipe.hasValidImage {
                AsyncImage(url: URL(string: recipe.displayImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            }

            // Time and Yield Info
            HStack(spacing: 16) {
                if !recipe.displayTotalTime.isEmpty && recipe.displayTotalTime != "未知" {
                    RecipeInfoTagView(
                        icon: "clock",
                        label: "總時間",
                        value: recipe.displayTotalTime,
                        color: .blue
                    )
                }

                if !recipe.displayPrepTime.isEmpty && recipe.displayPrepTime != "未知" {
                    RecipeInfoTagView(
                        icon: "timer",
                        label: "準備",
                        value: recipe.displayPrepTime,
                        color: .green
                    )
                }

                if !recipe.displayCookTime.isEmpty && recipe.displayCookTime != "未知" {
                    RecipeInfoTagView(
                        icon: "flame",
                        label: "烹飪",
                        value: recipe.displayCookTime,
                        color: .orange
                    )
                }

                if !recipe.displayYield.isEmpty && recipe.displayYield != "未知份量" {
                    RecipeInfoTagView(
                        icon: "person.2",
                        label: "份量",
                        value: recipe.displayYield,
                        color: .purple
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func descriptionSection(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.displayDescription)
                .lineLimit(isDescriptionExpanded ? nil : 4)
                .font(.body)
                .foregroundColor(.secondary)
                .animation(.easeInOut, value: isDescriptionExpanded)

            if let notes = recipe.notes, !notes.isEmpty {
                Text("備註：\(notes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            Button {
                withAnimation {
                    isDescriptionExpanded.toggle()
                }
            } label: {
                Text(isDescriptionExpanded ? "收合" : "展開")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ingredientsSection(_ ingredients: [RecipeIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("食材")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(ingredients, id: \.uniqueId) { ingredient in
                    HStack {
                        Circle()
                            .fill(Color.brandOrange)
                            .frame(width: 6, height: 6)

                        Text(ingredient.displayText)
                            .font(.body)

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func instructionsSection(_ instructions: [RecipeInstruction]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("製作步驟")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(instructions.enumerated()), id: \.element.uniqueId) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.brandOrange)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            if let title = instruction.title, !title.isEmpty {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            if let text = instruction.text, !text.isEmpty {
                                Text(text)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func additionalInfoSection(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他資訊")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                if let difficultyLevel = recipe.difficultyLevel, !difficultyLevel.isEmpty {
                    InfoRowView(
                        icon: "gauge",
                        label: "難度",
                        value: difficultyLevel
                    )
                }

                if let servings = recipe.servings {
                    InfoRowView(
                        icon: "person.2",
                        label: "建議人數",
                        value: "\(servings)人"
                    )
                }

                if let caloriesPerServing = recipe.caloriesPerServing {
                    InfoRowView(
                        icon: "flame",
                        label: "每份熱量",
                        value: "\(caloriesPerServing) 卡路里"
                    )
                }

                InfoRowView(
                    icon: "checkmark.seal.fill",
                    label: "狀態",
                    value: "已審核"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

private struct RecipeInfoTagView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(minWidth: 60)
    }
}

private struct InfoRowView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.brandOrange)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel

class RecipeDetailViewModel: ObservableObject {
    @Published var loadingState: LoadingState = .idle

    private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService()

    enum LoadingState {
        case idle
        case loading
        case loaded(RecipeDetail)
        case error(String)
    }

    func loadRecipeDetail(recipeName: String) {
        loadingState = .loading

        networkService.fetchRecipeDetail(by: recipeName)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.loadingState = .error(error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                self?.loadingState = .loaded(response.data)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Extensions

extension RecipeDetail {
    var hasValidImage: Bool {
        return imageUrl != nil && !imageUrl!.isEmpty && imageUrl != "default-recipe-image"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        RecipeDetailViewNew(recipeName: "義大利麵")
    }
}