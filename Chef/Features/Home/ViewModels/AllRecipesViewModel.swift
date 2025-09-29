//
//  AllRecipesViewModel.swift
//  ChefHelper
//

import Foundation
import Combine
import SwiftUI

enum RecipeSection {
    case popular
    case recommended
    case all

    var title: String {
        switch self {
        case .popular:
            return "熱門菜品"
        case .recommended:
            return "推薦菜品"
        case .all:
            return "所有食譜"
        }
    }
}

@MainActor
final class AllRecipesViewModel: ObservableObject {
    // MARK: - Properties
    private let service: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    @Published var viewState: ViewState = .loading
    @Published var recipes: [Recipe] = []
    @Published var section: RecipeSection = .all
    @Published var isUsingRealData: Bool = false
    @Published var dataSourceMessage: String = ""
    @Published var currentPage: Int = 1
    @Published var isLoadingMore: Bool = false
    @Published var canLoadMore: Bool = true

    // Store original Recipe data for detailed display
    private var recipeMap: [String: Recipe] = [:]

    // MARK: - Coordinator Callbacks
    var onSelectRecipe: ((Recipe) -> Void)?
    var onBack: (() -> Void)?

    // MARK: - Initialization
    init(service: NetworkServiceProtocol = NetworkService(), section: RecipeSection = .all, initialRecipes: [Recipe] = []) {
        self.service = service
        self.section = section

        if !initialRecipes.isEmpty {
            // 如果有初始食譜，直接使用
            self.recipes = initialRecipes
            self.viewState = .dataLoaded
            self.isUsingRealData = true
            self.dataSourceMessage = "✅ 顯示 \(section.title) (\(initialRecipes.count) 個食譜)"

            // Store recipes in map
            for recipe in initialRecipes {
                self.recipeMap[recipe.id] = recipe
            }
        }
    }

    // MARK: - Public Methods
    func fetchAllRecipes() {
        guard currentPage == 1 else { return } // 只在第一頁顯示loading

        self.viewState = .loading
        self.dataSourceMessage = "🔄 正在載入食譜資料..."

        print("AllRecipesViewModel: 🚀 開始載入食譜資料...")
        print("AllRecipesViewModel: 🌐 使用 API 端點: http://192.168.1.125:8081/api/v1/recipes")

        fetchRecipesPage(page: currentPage, size: 20)
    }

    func loadMoreRecipes() {
        guard !isLoadingMore && canLoadMore else { return }

        isLoadingMore = true
        let nextPage = currentPage + 1

        print("AllRecipesViewModel: 📄 載入第 \(nextPage) 頁食譜...")

        fetchRecipesPage(page: nextPage, size: 20)
    }

    func refreshRecipes() {
        currentPage = 1
        canLoadMore = true
        recipes.removeAll()
        recipeMap.removeAll()
        fetchAllRecipes()
    }

    // MARK: - Private Methods
    private func fetchRecipesPage(page: Int, size: Int) {
        service.fetchRecipes(page: page, size: size)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    print("AllRecipesViewModel: ❌ API 請求失敗")
                    print("AllRecipesViewModel: 📋 錯誤詳情: \(error.localizedDescription)")

                    if page == 1 {
                        self.viewState = .error(message: "載入食譜失敗：\(error.localizedDescription)")
                    }
                    self.isLoadingMore = false
                case .finished:
                    print("AllRecipesViewModel: ✅ API 請求完成")
                    self.isLoadingMore = false
                }
            } receiveValue: { [weak self] recipesResponse in
                guard let self = self else { return }

                print("AllRecipesViewModel: 🎉 成功獲取 \(recipesResponse.data.list.count) 個食譜")
                print("AllRecipesViewModel: 📊 API 回應詳情:")
                print("  - 總數: \(recipesResponse.data.total)")
                print("  - 當前頁: \(recipesResponse.data.pageNum)")
                print("  - 每頁數量: \(recipesResponse.data.pageSize)")

                // 資料驗證和過濾
                let validRecipes = recipesResponse.data.list.compactMap { recipe -> Recipe? in
                    if !recipe.isValid {
                        print("AllRecipesViewModel: ❌ 跳過無效食譜 - ID: \(recipe.id), 名稱: \(recipe.name ?? "nil")")
                        return nil
                    }
                    return recipe
                }

                print("AllRecipesViewModel: 📊 資料過濾結果:")
                print("  - 原始食譜數: \(recipesResponse.data.list.count)")
                print("  - 有效食譜: \(validRecipes.count)")

                // Store original recipes for detailed display
                for recipe in validRecipes {
                    self.recipeMap[recipe.id] = recipe
                }

                if page == 1 {
                    // 第一頁，替換所有食譜
                    self.recipes = validRecipes
                } else {
                    // 後續頁面，追加食譜
                    self.recipes.append(contentsOf: validRecipes)
                }

                // 更新頁面狀態
                self.currentPage = recipesResponse.data.pageNum
                self.canLoadMore = recipesResponse.data.pageNum < recipesResponse.data.totalPage

                self.isUsingRealData = true
                self.dataSourceMessage = "✅ 顯示 \(self.section.title) API 資料 (第 \(self.currentPage) 頁，共 \(self.recipes.count) 個食譜)"

                if page == 1 {
                    self.viewState = .dataLoaded
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - User Actions
    func didSelectRecipe(_ recipe: Recipe) {
        // Use the stored recipe for detailed display
        if let storedRecipe = recipeMap[recipe.id] {
            onSelectRecipe?(storedRecipe)
        } else {
            onSelectRecipe?(recipe)
        }
    }

    func requestBack() {
        print("AllRecipesViewModel: 請求返回")
        onBack?()
    }
}

// MARK: - Preview Helper
extension AllRecipesViewModel {
    static var preview: AllRecipesViewModel {
        let viewModel = AllRecipesViewModel(section: .all)
        // 使用createFromDish方法創建測試Recipe
        let testDish1 = Dish(id: "1", name: "測試食譜1", description: "測試描述1", image: "https://picsum.photos/300/200?random=1", rating: 4.5)
        let testDish2 = Dish(id: "2", name: "測試食譜2", description: "測試描述2", image: "https://picsum.photos/300/200?random=2", rating: 4.2)

        viewModel.recipes = [
            Recipe.createFromDish(testDish1),
            Recipe.createFromDish(testDish2)
        ]
        viewModel.viewState = .dataLoaded
        return viewModel
    }
}