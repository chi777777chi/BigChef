//
//  FavoritesView.swift
//  ChefHelper
//

import SwiftUI

struct FavoritesView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: FavoritesViewModel
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
            if viewModel.allDishes == nil {
                Task {
                    await viewModel.fetchFavorites()
                }
            }
        }
        .navigationTitle("我的收藏")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在載入收藏...")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if message.contains("登入") {
                Button(action: {
                    viewModel.requestLogin()
                }) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("前往登入")
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(Color.brandOrange)
                    .cornerRadius(10)
                }
            } else {
                Button(action: {
                    Task {
                        await viewModel.fetchFavorites()
                    }
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
        }
        .padding()
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Data source indicator
                HStack {
                    Text(viewModel.dataSourceMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                if let allDishes = viewModel.allDishes {
                    if allDishes.populars.isEmpty && allDishes.specials.isEmpty {
                        emptyFavoritesView
                    } else {
                        VStack(spacing: 0) {
                            // Categories section
                            if !allDishes.categories.isEmpty {
                                categorySection(categories: allDishes.categories)
                            }

                            // Popular favorites section
                            if !allDishes.populars.isEmpty {
                                popularFavoritesSection(dishes: allDishes.populars)
                            }

                            // All favorites section
                            if !allDishes.specials.isEmpty {
                                allFavoritesSection(dishes: allDishes.specials)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100) // Add padding for tab bar
        }
        .refreshable {
            Task {
                await viewModel.refreshFavorites()
            }
        }
    }

    // MARK: - Empty Favorites View
    private var emptyFavoritesView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 16)

            VStack(spacing: 12) {
                Text("還沒有收藏的食譜")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("快去首頁收藏一些喜愛的食譜吧！")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Category Section
    private func categorySection(categories: [DishCategory]) -> some View {
        VStack(alignment: .leading) {
            SectionTitleView(
                title: "收藏分類",
                onSeeAllTapped: {
                    print("查看全部收藏分類")
                }
            )
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(categories) { category in
                        CategoryView(dish: category) {
                            print("選擇收藏分類: \(category.name)")
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 128)
        }
        .padding(.bottom)
    }

    // MARK: - Popular Favorites Section
    private func popularFavoritesSection(dishes: [Dish]) -> some View {
        VStack(alignment: .leading) {
            SectionTitleView(
                title: "熱門收藏",
                onSeeAllTapped: {
                    print("查看全部熱門收藏")
                }
            )
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(dishes) { dish in
                        PopularDishesView(
                            dish: dish,
                            isFavorite: true, // 收藏頁面中都是已收藏的
                            onTap: {
                                viewModel.didSelectDish(dish)
                            },
                            onFavoriteTapped: {
                                // TODO: 處理取消收藏
                                print("取消收藏菜品: \(dish.name)")
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 250)
        }
        .padding(.bottom)
    }

    // MARK: - All Favorites Section
    private func allFavoritesSection(dishes: [Dish]) -> some View {
        VStack(alignment: .leading) {
            SectionTitleView(
                title: "全部收藏",
                onSeeAllTapped: {
                    print("查看全部收藏")
                }
            )
            LazyVStack(spacing: 15) {
                ForEach(dishes) { dish in
                    RecommendedView(
                        dish: dish,
                        onTap: {
                            viewModel.didSelectDish(dish)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 載入中狀態
            FavoritesView(viewModel: {
                let vm = FavoritesViewModel(authViewModel: AuthViewModel())
                vm.viewState = .loading
                return vm
            }())
            .previewDisplayName("載入中")

            // 未登入狀態
            FavoritesView(viewModel: {
                let vm = FavoritesViewModel(authViewModel: AuthViewModel())
                vm.viewState = .error(message: "請先登入以查看收藏的食譜")
                return vm
            }())
            .previewDisplayName("未登入")

            // 載入完成狀態
            FavoritesView(viewModel: FavoritesViewModel.preview)
                .previewDisplayName("載入完成")
        }
    }
}