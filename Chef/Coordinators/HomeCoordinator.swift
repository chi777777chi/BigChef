//
 //  HomeCoordinator.swift
 //  ChefHelper
 //
 //  Created by 陳泓齊 on 2025/5/3.
 //

import UIKit
import SwiftUI

@MainActor
final class HomeCoordinator: Coordinator {
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: MainTabCoordinator?
    private let authViewModel: AuthViewModel?

    // MARK: - Initialization
    init(navigationController: UINavigationController, parentCoordinator: MainTabCoordinator? = nil, authViewModel: AuthViewModel? = nil) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
        self.authViewModel = authViewModel
    }
    
    // MARK: - Public Methods
    func start() {
        let viewModel = HomeViewModel(authViewModel: authViewModel ?? AuthViewModel())
        viewModel.onSelectDish = { [weak self] dish in
            self?.showDishDetail(dish)
        }
        viewModel.onSelectRecipe = { [weak self] recipe in
            self?.showRecipeDetail(recipe)
        }
        viewModel.onRequestLogout = { [weak self] in
            self?.handleLogout()
        }
        
        let homeView = HomeView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: homeView)
        navigationController.setViewControllers([hostingController], animated: false)
    }
    
    // MARK: - Navigation Methods
    func showDishDetail(_ dish: Dish) {
        let detailView = DishDetailView(recipe: Recipe.createFromDish(dish))
        let hostingController = UIHostingController(rootView: detailView)
        navigationController.pushViewController(hostingController, animated: true)
        print("顯示菜品詳情: \(dish.name)")
    }

    func showRecipeDetail(_ recipe: Recipe) {
        // 使用新的RecipeDetailView，通過食物名稱來獲取詳細資料
        let detailView = RecipeDetailViewNew(recipeName: recipe.displayName)
        let hostingController = UIHostingController(rootView: detailView)
        navigationController.pushViewController(hostingController, animated: true)
        print("顯示食譜詳情: \(recipe.displayName)")
    }

    func showAllRecipes(section: RecipeSection, initialRecipes: [Recipe] = []) {
        let viewModel = AllRecipesViewModel(section: section, initialRecipes: initialRecipes)
        viewModel.onSelectRecipe = { [weak self] recipe in
            self?.showRecipeDetail(recipe)
        }
        viewModel.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }

        let allRecipesView = AllRecipesView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: allRecipesView)
        navigationController.pushViewController(hostingController, animated: true)
        print("顯示全部食譜: \(section.title)")
    }
    
    func handleLogout() {
        print("HomeCoordinator: 開始處理登出")
        
        // 清除用戶數據
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.synchronize()
        
        // 通知父協調器處理登出
        if let parentCoordinator = parentCoordinator {
            print("HomeCoordinator: 通知父協調器處理登出")
            parentCoordinator.handleLogout()
        } else {
            print("HomeCoordinator: 錯誤 - 父協調器為空")
        }
    }
//    func showDishDetail(dish: Dish, animated: Bool) {
//             // let detailViewModel = DishDetailViewModel(dish: dish) // 假設有 DishDetailViewModel
//             let detailView = DishDetailView(dish: dish) // 假設 DishDetailView 已存在
//             let hostingController = UIHostingController(rootView: detailView)
//             hostingController.title = dish.name // 設定導航欄標題
//
//             // 使用 router 推送新的 ViewController
//             // push 的 completion 回調會在 DishDetailView 被 pop 時觸發
//             router.push(hostingController, animated: animated) { [weak self] in
//                 print("HomeCoordinator: DishDetailView 被 pop")
//                 // 通常，子畫面的 pop 不會結束 HomeCoordinator 本身
//             }
//         }
}

// MARK: - Preview Helper
extension HomeCoordinator {
    static var preview: HomeCoordinator {
        HomeCoordinator(navigationController: UINavigationController())
    }
}
