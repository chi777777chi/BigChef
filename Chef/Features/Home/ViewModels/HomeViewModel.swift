//
//  HomeViewModel.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//

// HomeViewModel.swift
// 路徑: ntut-multimodal-ai-ar-cooking-app/bigchef/BigChef-main/Chef/Features/Home/ViewModels/HomeViewModel.swift
import Foundation
import Combine
import SwiftUI

// MARK: - View State
enum ViewState: Equatable {
    case loading
    case error(message: String)
    case dataLoaded
    
    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.dataLoaded, .dataLoaded):
            return true
        default:
            return false
        }
    }
}

// MARK: - Localized Strings
enum Strings {
    static let somethingWentWrong = "發生錯誤，請稍後再試"
    static let requestTimeout = "請求超時，請重試"
    static let fetchingRecords = "正在載入菜品資料..."
    static let fetchingMoreRecords = "正在載入更多資料..."
    static let noInternet = "網路連線異常，請檢查網路設定"
    static let noCharactersFound = "找不到相關菜品"
}

// MARK: - Home View Model
final class HomeViewModel: ObservableObject {
    // MARK: - Properties
    private let service: NetworkServiceProtocol
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
    var onRequestLogout: (() -> Void)?
    
    // MARK: - Initialization
    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }
    
    // MARK: - Public Methods
    func fetchAllDishes() {
        self.viewState = .loading
        self.dataSourceMessage = "🔄 正在載入資料..."

        print("HomeViewModel: 🚀 開始載入菜品資料...")
        print("HomeViewModel: 🌐 嘗試連接 API: http://172.20.10.5:8081/api/v1/recipes")

        // First, try to fetch real recipes from API
        service.fetchRecipes(page: 1, size: 20)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    print("HomeViewModel: ❌ API 請求失敗")
                    print("HomeViewModel: 📋 錯誤詳情: \(error.localizedDescription)")

                    // 簡化錯誤日誌，避免命名衝突
                    print("HomeViewModel: 🔧 錯誤類型: \(type(of: error))")

                    // If API fails, load mock data as fallback
                    print("HomeViewModel: 🔄 切換到模擬資料作為後備方案")
                    self.loadMockData()
                case .finished:
                    print("HomeViewModel: ✅ API 請求完成")
                }
            } receiveValue: { [weak self] recipesResponse in
                guard let self = self else { return }

                print("HomeViewModel: 🎉 成功獲取 \(recipesResponse.data.records.count) 個菜品")
                print("HomeViewModel: 📊 API 回應詳情:")
                print("  - 總數: \(recipesResponse.data.total)")
                print("  - 當前頁: \(recipesResponse.data.current)")
                print("  - 每頁數量: \(recipesResponse.data.size)")

                // 資料驗證和過濾
                print("HomeViewModel: 🔍 開始驗證食譜資料...")

                // 先列印前幾個食譜的調試資訊
                for (index, recipe) in recipesResponse.data.records.prefix(3).enumerated() {
                    print("HomeViewModel: 📋 食譜 \(index + 1) 調試資訊:")
                    print(recipe.debugInfo)
                }

                // 過濾有效且已批准的食譜
                let validRecipes = recipesResponse.data.records.compactMap { recipe -> Recipe? in
                    if !recipe.isValid {
                        print("HomeViewModel: ❌ 跳過無效食譜 - ID: \(recipe.id), 名稱: \(recipe.name ?? "nil")")
                        return nil
                    }
                    if !recipe.isApproved {
                        print("HomeViewModel: ⚠️ 跳過未批准食譜 - ID: \(recipe.id), 狀態: \(recipe.approvalStatus ?? "nil")")
                        return nil
                    }
                    return recipe
                }

                print("HomeViewModel: 📊 資料過濾結果:")
                print("  - 原始食譜數: \(recipesResponse.data.records.count)")
                print("  - 有效且已批准: \(validRecipes.count)")

                if validRecipes.isEmpty {
                    print("HomeViewModel: ⚠️ 沒有有效的已批准菜品，切換到模擬資料")
                    self.loadMockData()
                    return
                }

                // Store original recipes for detailed display
                for recipe in validRecipes {
                    self.recipeMap[recipe.id] = recipe
                }

                // Convert recipes to dishes for existing UI
                let allRecipeDishes = validRecipes.map { Dish(from: $0) }

                // Group recipes: first 4 as popular, rest as specials
                let popularDishes = Array(allRecipeDishes.prefix(4))
                let specialDishes = Array(allRecipeDishes.dropFirst(4))

                print("HomeViewModel: 🏷️ 資料分組結果:")
                print("  - 熱門菜品: \(popularDishes.count) 個")
                print("  - 推薦菜品: \(specialDishes.count) 個")

                // 顯示菜品名稱
                print("HomeViewModel: 📝 熱門菜品列表:")
                for (index, dish) in popularDishes.enumerated() {
                    print("  \(index + 1). \(dish.name)")
                }

                if !specialDishes.isEmpty {
                    print("HomeViewModel: 📝 推薦菜品列表:")
                    for (index, dish) in specialDishes.prefix(3).enumerated() {
                        print("  \(index + 1). \(dish.name)")
                    }
                }

                // Create mock categories (since API doesn't provide them)
                let mockCategories = [
                    DishCategory(id: "1", name: "中式料理", image: "https://picsum.photos/200/200?random=1"),
                    DishCategory(id: "2", name: "西式料理", image: "https://picsum.photos/200/200?random=2"),
                    DishCategory(id: "3", name: "日式料理", image: "https://picsum.photos/200/200?random=3")
                ]

                DispatchQueue.main.async {
                    self.allDishes = AllDishes(
                        categories: mockCategories,
                        populars: popularDishes,
                        specials: specialDishes
                    )
                    self.isUsingRealData = true
                    self.dataSourceMessage = "✅ 顯示真實 API 資料 (\(validRecipes.count) 個菜品)"
                    print("HomeViewModel: 🌐 使用真實 API 資料，共 \(validRecipes.count) 個有效已批准菜品")
                    self.viewState = .dataLoaded
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Refresh Method
    func refreshDishes() {
        fetchAllDishes()
    }
    
    // MARK: - Mock Data Helper (Fallback when API fails)
    private func loadMockData() {
        DispatchQueue.main.async {
            self.allDishes = AllDishes(
                categories: [
                    DishCategory(id: "1", name: "中式料理", image: "https://picsum.photos/200/200?random=1"),
                    DishCategory(id: "2", name: "西式料理", image: "https://picsum.photos/200/200?random=2"),
                    DishCategory(id: "3", name: "日式料理", image: "https://picsum.photos/200/200?random=3"),
                    DishCategory(id: "4", name: "素食料理", image: "https://picsum.photos/200/200?random=4")
                ],
                populars: [
                    Dish(id: "pop1", name: "香煎雞腿排", description: "嫩滑多汁的香煎雞腿排", image: "https://picsum.photos/300/200?random=11", rating: 4.5),
                    Dish(id: "pop2", name: "蒜蓉炒時蔬", description: "清爽健康的綠色蔬菜", image: "https://picsum.photos/300/200?random=12", rating: 4.2),
                    Dish(id: "pop3", name: "蒸蛋", description: "滑嫩的蒸蛋，營養豐富", image: "https://picsum.photos/300/200?random=13", rating: 4.0),
                    Dish(id: "pop4", name: "番茄炒蛋", description: "經典家常菜，酸甜可口", image: "https://picsum.photos/300/200?random=14", rating: 4.3)
                ],
                specials: [
                    Dish(id: "spe1", name: "蒸魚", description: "新鮮魚類，清蒸保持原味", image: "https://picsum.photos/300/200?random=21", rating: 4.7),
                    Dish(id: "spe2", name: "麻婆豆腐", description: "四川經典，麻辣鮮香", image: "https://picsum.photos/300/200?random=22", rating: 4.4),
                    Dish(id: "spe3", name: "清炒高麗菜", description: "簡單清爽的蔬菜料理", image: "https://picsum.photos/300/200?random=23", rating: 4.1)
                ]
            )
            self.isUsingRealData = false
            self.dataSourceMessage = "⚠️ 顯示模擬資料 (API 無法連接)"
            print("HomeViewModel: 📱 使用模擬資料 (API 失敗後的後備方案)")
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
    
    func requestLogout() {
        print("HomeViewModel: 用戶請求登出")
        onRequestLogout?()
    }
}

// MARK: - Preview Helper
extension HomeViewModel {
    static var preview: HomeViewModel {
        let viewModel = HomeViewModel()
        viewModel.allDishes = AllDishes.preview
        viewModel.viewState = .dataLoaded
        return viewModel
    }
}
