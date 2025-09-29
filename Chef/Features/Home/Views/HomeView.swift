//
//  Home.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/7.
//
// HomeView.swift

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .loading:
                loadingView
            case .error(let message):
                ErrorView(message) {
                    Task {
                        await viewModel.fetchAllDishes()
                    }
                }
            case .dataLoaded:
                mainContent
            }
        }
        .onAppear {
            if viewModel.allDishes == nil {
                Task {
                    await viewModel.fetchAllDishes()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(Strings.fetchingRecords)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 頂部導航欄
                topNavigationBar

                // 資料來源指示器
                dataSourceIndicator
                
                if let unwrappedAllDishes = viewModel.allDishes {
                    // 菜品分類
                    if !unwrappedAllDishes.categories.isEmpty {
                        categorySection(categories: unwrappedAllDishes.categories)
                    }
                    
                    // 熱門菜品
                    if !unwrappedAllDishes.populars.isEmpty {
                        popularDishesSection(dishes: unwrappedAllDishes.populars)
                    }
                    
                    // 推薦菜品
                    if !unwrappedAllDishes.specials.isEmpty {
                        recommendedDishesSection(dishes: unwrappedAllDishes.specials)
                    }
                }
                
                Spacer(minLength: 80)
            }
            .refreshable {
                viewModel.refreshDishes()
            }
        }
        .background(Color(UIColor.secondarySystemBackground).edgesIgnoringSafeArea(.all))
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            Spacer()
            Image("QuickFeatLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
            Spacer()
            Button(action: {
                viewModel.requestLogout()
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(Color.brandOrange)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Data Source Indicator
    private var dataSourceIndicator: some View {
        VStack(spacing: 8) {
            if !viewModel.dataSourceMessage.isEmpty {
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
                        viewModel.refreshDishes()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
            }

            // Debug 模式額外資訊
            #if DEBUG
            if viewModel.viewState == .dataLoaded {
                HStack {
                    Text("📱 Debug: \(viewModel.isUsingRealData ? "API 資料" : "模擬資料")")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let dishes = viewModel.allDishes {
                        Text("熱門: \(dishes.populars.count) | 推薦: \(dishes.specials.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            #endif
        }
    }

    // MARK: - Category Section
    private func categorySection(categories: [DishCategory]) -> some View {
        VStack(alignment: .leading) {
            SectionTitleView(
                title: "菜品分類",
                onSeeAllTapped: {
                    viewModel.requestShowAllRecipes(section: .all)
                }
            )
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(categories) { category in
                        CategoryView(dish: category) {
                            // TODO: 處理分類選擇
                            print("選擇分類: \(category.name)")
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 128)
        }
        .padding(.bottom)
    }
    
    // MARK: - Popular Dishes Section
    private func popularDishesSection(dishes: [Dish]) -> some View {
        VStack(alignment: .leading) {
            SectionTitleView(
                title: "熱門菜品",
                onSeeAllTapped: {
                    viewModel.requestShowAllRecipes(section: .popular)
                }
            )
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(dishes) { dish in
                        PopularDishesView(
                            dish: dish,
                            isFavorite: false, // TODO: 從 ViewModel 獲取收藏狀態
                            onTap: {
                                viewModel.didSelectDish(dish)
                            },
                            onFavoriteTapped: {
                                // TODO: 處理收藏
                                print("收藏菜品: \(dish.name)")
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
    
    // MARK: - Recommended Dishes Section
    private func recommendedDishesSection(dishes: [Dish]) -> some View {
        VStack(alignment: .leading) {
            SectionTitleView(
                title: "推薦菜品",
                onSeeAllTapped: {
                    viewModel.requestShowAllRecipes(section: .recommended)
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
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 載入中狀態
            HomeView(viewModel: {
                let vm = HomeViewModel(authViewModel: AuthViewModel())
                vm.viewState = .loading
                return vm
            }())
            .previewDisplayName("載入中")

            // 錯誤狀態
            HomeView(viewModel: {
                let vm = HomeViewModel(authViewModel: AuthViewModel())
                vm.viewState = .error(message: Strings.somethingWentWrong)
                return vm
            }())
            .previewDisplayName("錯誤狀態")
            
            // 載入完成狀態
            HomeView(viewModel: HomeViewModel.preview)
                .previewDisplayName("載入完成")
        }
    }
}

