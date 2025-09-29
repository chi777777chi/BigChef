//
//  FavoritesViewModel.swift
//  ChefHelper
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class FavoritesViewModel: ObservableObject {
    // MARK: - Properties
    private let service: NetworkServiceProtocol
    private let authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()

    @Published var viewState: ViewState = .loading
    @Published var allDishes: AllDishes?
    @Published var isUsingRealData: Bool = false
    @Published var dataSourceMessage: String = ""

    // Store original Recipe data for detailed display
    private var recipeMap: [String: Recipe] = [:]

    // MARK: - Coordinator Callbacks
    var onSelectDish: ((Dish) -> Void)?
    var onSelectRecipe: ((Recipe) -> Void)?
    var onRequestLogin: (() -> Void)?

    // MARK: - Initialization
    init(service: NetworkServiceProtocol = NetworkService(), authViewModel: AuthViewModel) {
        self.service = service
        self.authViewModel = authViewModel
    }

    // MARK: - Public Methods
    func fetchFavorites() {
        self.viewState = .loading
        self.dataSourceMessage = "🔄 正在載入收藏資料..."

        print("FavoritesViewModel: 🚀 開始載入收藏菜品資料...")

        // 檢查登入狀態
        guard authViewModel.isLoggedInWithAPI else {
            print("FavoritesViewModel: ⚠️ 用戶未登入，顯示登入提示")
            showLoginPrompt()
            return
        }

        print("FavoritesViewModel: 🔐 用戶已登入，載入收藏資料")
        print("FavoritesViewModel: 🌐 使用 API 端點: \(ConfigManager.shared.fullAPIBaseURL)/favorites")

        service.fetchFavorites(page: 1, size: 20)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    print("FavoritesViewModel: ❌ 收藏 API 請求失敗")
                    print("FavoritesViewModel: 📋 錯誤詳情: \(error.localizedDescription)")

                    // 如果是401錯誤，提示重新登入
                    if error.localizedDescription.contains("401") || error.localizedDescription.contains("未授權") {
                        self.showLoginPrompt()
                    } else {
                        self.viewState = .error(message: "載入收藏失敗：\(error.localizedDescription)")
                    }
                case .finished:
                    print("FavoritesViewModel: ✅ 收藏 API 請求完成")
                }
            } receiveValue: { [weak self] recipesResponse in
                guard let self = self else { return }

                print("FavoritesViewModel: 🎉 成功獲取 \(recipesResponse.data.list.count) 個收藏菜品")
                print("FavoritesViewModel: 📊 API 回應詳情:")
                print("  - 總數: \(recipesResponse.data.total)")
                print("  - 當前頁: \(recipesResponse.data.pageNum)")
                print("  - 每頁數量: \(recipesResponse.data.pageSize)")

                // 資料驗證和過濾
                print("FavoritesViewModel: 🔍 開始驗證收藏食譜資料...")

                let validRecipes = recipesResponse.data.list.compactMap { recipe -> Recipe? in
                    if !recipe.isValid {
                        print("FavoritesViewModel: ❌ 跳過無效食譜 - ID: \(recipe.id), 名稱: \(recipe.name ?? "nil")")
                        return nil
                    }
                    return recipe
                }

                print("FavoritesViewModel: 📊 收藏資料過濾結果:")
                print("  - 原始食譜數: \(recipesResponse.data.list.count)")
                print("  - 有效收藏: \(validRecipes.count)")

                if validRecipes.isEmpty {
                    print("FavoritesViewModel: ⚠️ 沒有收藏的菜品")
                    self.showEmptyState()
                    return
                }

                // Store original recipes for detailed display
                for recipe in validRecipes {
                    self.recipeMap[recipe.id] = recipe
                }

                // Convert recipes to dishes for existing UI
                let allRecipeDishes = validRecipes.map { Dish(from: $0) }

                // 收藏頁面顯示：全部作為推薦，部分作為熱門
                let popularDishes = Array(allRecipeDishes.prefix(4))
                let specialDishes = allRecipeDishes

                print("FavoritesViewModel: 🏷️ 收藏資料分組結果:")
                print("  - 熱門收藏: \(popularDishes.count) 個")
                print("  - 全部收藏: \(specialDishes.count) 個")

                // Create mock categories for consistency
                let mockCategories = [
                    DishCategory(id: "fav1", name: "我的最愛", image: "https://picsum.photos/200/200?random=11"),
                    DishCategory(id: "fav2", name: "最近收藏", image: "https://picsum.photos/200/200?random=12"),
                    DishCategory(id: "fav3", name: "常煮食譜", image: "https://picsum.photos/200/200?random=13")
                ]

                DispatchQueue.main.async {
                    self.allDishes = AllDishes(
                        categories: mockCategories,
                        populars: popularDishes,
                        specials: specialDishes
                    )
                    self.isUsingRealData = true
                    self.dataSourceMessage = "✅ 顯示收藏 API 資料 (\(validRecipes.count) 個收藏)"
                    print("FavoritesViewModel: 🌐 使用收藏 API 資料，共 \(validRecipes.count) 個收藏菜品")
                    self.viewState = .dataLoaded
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Refresh Method
    func refreshFavorites() {
        fetchFavorites()
    }

    // MARK: - Private Methods
    private func showLoginPrompt() {
        DispatchQueue.main.async {
            self.viewState = .error(message: "請先登入以查看收藏的食譜")
            self.dataSourceMessage = "⚠️ 需要登入才能查看收藏"
        }
    }

    private func showEmptyState() {
        DispatchQueue.main.async {
            self.allDishes = AllDishes(
                categories: [],
                populars: [],
                specials: []
            )
            self.isUsingRealData = false
            self.dataSourceMessage = "📭 您還沒有收藏任何食譜"
            self.viewState = .dataLoaded
        }
    }

    // MARK: - User Actions
    func didSelectDish(_ dish: Dish) {
        // Try to find original Recipe for detailed display
        if let recipe = recipeMap[dish.id] {
            onSelectRecipe?(recipe)
        } else {
            // Fallback to old behavior if no Recipe found
            onSelectDish?(dish)
        }
    }

    func requestLogin() {
        print("FavoritesViewModel: 用戶請求登入")
        onRequestLogin?()
    }
}

// MARK: - Preview Helper
extension FavoritesViewModel {
    static var preview: FavoritesViewModel {
        let viewModel = FavoritesViewModel(authViewModel: AuthViewModel())
        viewModel.allDishes = AllDishes.preview
        viewModel.viewState = .dataLoaded
        return viewModel
    }
}