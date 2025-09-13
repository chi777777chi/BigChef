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
    
    // MARK: - Coordinator Callbacks
    var onSelectDish: ((Dish) -> Void)?
    var onRequestLogout: (() -> Void)?
    
    // MARK: - Initialization
    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }
    
    // MARK: - Public Methods
    func fetchAllDishes() {
        self.viewState = .loading
        
        service.request(url: "https://yummie.glitch.me/dish-categories", decodeType: APIResponse.self)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    print("HomeViewModel: 獲取菜品失敗 - \(error.localizedDescription)")
                    
                    // 當任何 API 錯誤發生時，都載入模擬資料
                    print("HomeViewModel: API 無法使用，載入模擬資料")
                    self.loadMockData()
                case .finished:
                    print("HomeViewModel: 獲取菜品完成")
                }
            } receiveValue: { [weak self] responseData in
                guard let self = self else { return }
                
                guard var dishes = responseData.data else{
                    self.viewState = .error(message: Strings.somethingWentWrong)
                    return
                    
                }
                if
                    let idx2 = dishes.populars.firstIndex(where: { $0.id == "pop2" }),
                    let idx5 = dishes.populars.firstIndex(where: { $0.id == "pop5" })
                {
                    dishes.populars.swapAt(idx2,idx5 )
                }
                DispatchQueue.main.async {
                    self.allDishes = dishes
                    self.viewState = .dataLoaded
                }
                
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mock Data Helper
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
                    Dish(id: "pop1", name: "紅燒牛肉麵", description: "香醇濃郁的台式牛肉麵", image: "https://picsum.photos/300/200?random=11", calories: 520),
                    Dish(id: "pop2", name: "宮保雞丁", description: "經典川菜，辣中帶甜", image: "https://picsum.photos/300/200?random=12", calories: 380),
                    Dish(id: "pop3", name: "蒜泥白肉", description: "清爽開胃的涼菜", image: "https://picsum.photos/300/200?random=13", calories: 290),
                    Dish(id: "pop4", name: "糖醋里肌", description: "酸甜可口的家常菜", image: "https://picsum.photos/300/200?random=14", calories: 450)
                ],
                specials: [
                    Dish(id: "spe1", name: "蒸蛋", description: "滑嫩的蒸蛋", image: "https://picsum.photos/300/200?random=21", calories: 180),
                    Dish(id: "spe2", name: "麻婆豆腐", description: "麻辣鮮香的四川名菜", image: "https://picsum.photos/300/200?random=22", calories: 280),
                    Dish(id: "spe3", name: "回鍋肉", description: "四川家常菜經典", image: "https://picsum.photos/300/200?random=23", calories: 420)
                ]
            )
            self.viewState = .dataLoaded
        }
    }
    
    // MARK: - User Actions
    func didSelectDish(_ dish: Dish) {
        onSelectDish?(dish)
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
