//
//  AllRecipesView.swift
//  ChefHelper
//

import SwiftUI

struct AllRecipesView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: AllRecipesViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body
    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .loading:
                loadingView
            case .error(let message):
                errorView(message: message)
            case .dataLoaded:
                mainContent
            }
        }
        .onAppear {
            if viewModel.recipes.isEmpty {
                viewModel.fetchAllRecipes()
            }
        }
        .navigationTitle(viewModel.section.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    viewModel.requestBack()
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在載入食譜...")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                viewModel.refreshRecipes()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重新載入")
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 44)
                .background(Color.brandOrange)
                .cornerRadius(10)
            }
        }
        .padding()
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Data source indicator
                dataSourceIndicator

                // Recipe grid (2 columns)
                if !viewModel.recipes.isEmpty {
                    recipeGridSection
                } else {
                    emptyView
                }

                // Load more indicator
                if viewModel.canLoadMore {
                    loadMoreSection
                }
            }
            .padding(.bottom, 100) // Add padding for tab bar
        }
        .refreshable {
            viewModel.refreshRecipes()
        }
    }

    // MARK: - Data Source Indicator
    private var dataSourceIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.dataSourceMessage)
                    .font(.caption)
                    .foregroundColor(viewModel.isUsingRealData ? .green : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.isUsingRealData ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    )

                Spacer()

                // 重新整理按鈕
                Button(action: {
                    viewModel.refreshRecipes()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Debug 模式額外資訊
            #if DEBUG
            HStack {
                Text("📱 Debug: \(viewModel.isUsingRealData ? "API 資料" : "模擬資料")")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("共 \(viewModel.recipes.count) 個食譜")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            #endif
        }
    }

    // MARK: - Recipe Grid Section
    private var recipeGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            ForEach(viewModel.recipes) { recipe in
                RecipeCardView(
                    recipe: recipe,
                    isFavorite: recipe.isFavorited ?? false,
                    onTap: {
                        viewModel.didSelectRecipe(recipe)
                    },
                    onFavoriteTapped: {
                        // TODO: 處理收藏功能
                        print("收藏食譜: \(recipe.displayName)")
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 16)

            VStack(spacing: 12) {
                Text("暫無食譜")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("請稍後再試或重新載入")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Load More Section
    private var loadMoreSection: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingMore {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("載入更多...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                Button(action: {
                    viewModel.loadMoreRecipes()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("載入更多")
                    }
                    .foregroundColor(.brandOrange)
                    .font(.callout)
                    .padding()
                }
            }
        }
    }
}

// MARK: - Recipe Card View
struct RecipeCardView: View {
    let recipe: Recipe
    let onTap: () -> Void
    let isFavorite: Bool
    let onFavoriteTapped: (() -> Void)?

    init(
        recipe: Recipe,
        isFavorite: Bool = false,
        onTap: @escaping () -> Void,
        onFavoriteTapped: (() -> Void)? = nil
    ) {
        self.recipe = recipe
        self.isFavorite = isFavorite
        self.onTap = onTap
        self.onFavoriteTapped = onFavoriteTapped
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 圖片和收藏按鈕
                ZStack(alignment: .topLeading) {
                    // Recipe Image
                    CachedAsyncImage(
                        url: URL(string: recipe.imageUrl ?? ""),
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        },
                        placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                )
                        }
                    )
                    .frame(height: 110)
                    .clipped()
                    .cornerRadius(12)

                    // 收藏按鈕
                    if let onFavoriteTapped = onFavoriteTapped {
                        Button(action: onFavoriteTapped) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .pink : .white)
                                .font(.title3)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(8)
                    }
                }

                // Recipe Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let description = recipe.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    HStack(spacing: 8) {
                        // 評分顯示 (使用統一的星星樣式)
                        if let rating = recipe.rating, rating > 0 {
                            HStack(spacing: 2) {
                                let fullStars = Int(rating)
                                let hasHalfStar = rating.truncatingRemainder(dividingBy: 1) >= 0.5

                                // 滿星
                                ForEach(0..<fullStars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption2)
                                }

                                // 半星
                                if hasHalfStar && fullStars < 5 {
                                    Image(systemName: "star.leadinghalf.filled")
                                        .foregroundColor(.yellow)
                                        .font(.caption2)
                                }

                                // 空星
                                let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
                                ForEach(0..<emptyStars, id: \.self) { _ in
                                    Image(systemName: "star")
                                        .foregroundColor(.gray.opacity(0.3))
                                        .font(.caption2)
                                }
                            }

                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // 烹飪時間
                        if let cookTime = recipe.cookTime {
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                    .font(.caption2)
                                Text(cookTime)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
            .padding(12)
            .frame(minHeight: 200)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
struct AllRecipesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 載入中狀態
            NavigationView {
                AllRecipesView(viewModel: {
                    let vm = AllRecipesViewModel(section: .all)
                    vm.viewState = .loading
                    return vm
                }())
            }
            .previewDisplayName("載入中")

            // 載入完成狀態
            NavigationView {
                AllRecipesView(viewModel: AllRecipesViewModel.preview)
            }
            .previewDisplayName("載入完成")

            // 錯誤狀態
            NavigationView {
                AllRecipesView(viewModel: {
                    let vm = AllRecipesViewModel(section: .all)
                    vm.viewState = .error(message: "網路連線異常，請檢查網路設定")
                    return vm
                }())
            }
            .previewDisplayName("錯誤狀態")
        }
    }
}