//
//  MainTabCoordinator.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/3.
//

import UIKit
//import SwiftUICore
import SwiftUI

@MainActor
final class MainTabCoordinator: Coordinator, ObservableObject {

    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    /// 提供給 AppCoordinator 當 rootViewController

    var navigationController: UINavigationController
    weak var parentCoordinator: AppCoordinator?
    let authViewModel: AuthViewModel

    init(navigationController: UINavigationController, parentCoordinator: AppCoordinator? = nil, authViewModel: AuthViewModel) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
        self.authViewModel = authViewModel
    }
    
    // MARK: - Public
    func start() {
        
        let tabView = TabView {
            // Home Tab
            NavigationStack {
                HomeTabView(coordinator: self)
            }
            .tabItem {
                Label("首頁", systemImage: "house.fill")
            }

            // Scanning Tab
            NavigationStack {
                ScanningTabView(coordinator: self)
            }
            .tabItem {
                Label("食譜", systemImage: "camera.fill")
            }

            // Food Recognition Tab
            NavigationStack {
                FoodRecognitionTabView(coordinator: self)
            }
            .tabItem {
                Label("辨識", systemImage: "camera.viewfinder")
            }

            // Recipe Recommendation Tab
            NavigationStack {
                RecipeRecommendationTabView(coordinator: self)
            }
            .tabItem {
                Label("推薦", systemImage: "lightbulb.fill")
            }

            // Favorites Tab
            NavigationStack {
                FavoritesTabView(coordinator: self)
            }
            .tabItem {
                Label("收藏", systemImage: "heart.fill")
            }

            // Settings Tab
            NavigationStack {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("設定", systemImage: "gear")
            }
        }
        
        let hostingController = UIHostingController(rootView: tabView)
        navigationController.setViewControllers([hostingController], animated: false)
    }
    
    // MARK: - Navigation Methods
    
    func showRecipeDetail(_ recipe: SuggestRecipeResponse) {
        let coordinator = RecipeCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.showRecipeDetail(recipe)
    }

    func showRecipeDetail(_ recipe: Recipe) {
        let coordinator = RecipeCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.showRecipeDetail(recipe)
    }
    
    func showScanning() {
        let coordinator = ScanningCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }
    
    func showCamera() {
        let coordinator = CameraCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }
    
    func handleLogout() {
        print("MainTabCoordinator: 開始處理登出")
        
        // 清除所有子協調器
        print("MainTabCoordinator: 清除子協調器")
        childCoordinators.removeAll()
        
        // 通知父協調器處理登出
        if let parentCoordinator = parentCoordinator {
            print("MainTabCoordinator: 找到父協調器，通知處理登出")
            parentCoordinator.handleLogout()
        } else {
            print("MainTabCoordinator: 錯誤 - 父協調器為空")
        }
    }
}

// MARK: - Tab Views

private struct HomeTabView: View {
    @ObservedObject var coordinator: MainTabCoordinator
    @State private var homeCoordinator: HomeCoordinator?
    @State private var viewModel: HomeViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                HomeView(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        // 先創建 HomeCoordinator
                        let newHomeCoordinator = HomeCoordinator(
                            navigationController: coordinator.navigationController,
                            parentCoordinator: coordinator,
                            authViewModel: coordinator.authViewModel
                        )
                        coordinator.addChildCoordinator(newHomeCoordinator)
                        self.homeCoordinator = newHomeCoordinator
                        
                        // 然後創建 ViewModel 並設置回調
                        let newViewModel = HomeViewModel(authViewModel: coordinator.authViewModel)
                        newViewModel.onSelectDish = { [weak newHomeCoordinator] dish in
                            newHomeCoordinator?.showDishDetail(dish)
                        }
                        newViewModel.onSelectRecipe = { [weak newHomeCoordinator] recipe in
                            newHomeCoordinator?.showRecipeDetail(recipe)
                        }
                        newViewModel.onRequestLogout = { [weak newHomeCoordinator] in
                            newHomeCoordinator?.handleLogout()
                        }
                        newViewModel.onShowAllRecipes = { [weak newHomeCoordinator] section, recipes in
                            newHomeCoordinator?.showAllRecipes(section: section, initialRecipes: recipes)
                        }
                        self.viewModel = newViewModel
                    }
            }
        }
    }
}

private struct ScanningTabView: View {
    @ObservedObject var coordinator: MainTabCoordinator
    @State private var scanningCoordinator: ScanningCoordinator?

    var body: some View {
        Group {
            if let scanningCoordinator = scanningCoordinator {
                let state = ScanningState()
                let viewModel = ScanningViewModel(
                    state: state,
                    onNavigateToRecipe: { recipe in
                        coordinator.showRecipeDetail(recipe)
                    }
                )
                ScanningView(
                    state: state,
                    viewModel: viewModel,
                    coordinator: scanningCoordinator
                )
            } else {
                ProgressView()
                    .onAppear {
                        scanningCoordinator = ScanningCoordinator(navigationController: coordinator.navigationController)
                        coordinator.addChildCoordinator(scanningCoordinator!)
                    }
            }
        }
    }
}

private struct FoodRecognitionTabView: View {
    @ObservedObject var coordinator: MainTabCoordinator
    @State private var foodRecognitionCoordinator: FoodRecognitionCoordinator?
    @State private var viewModel: FoodRecognitionViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel, let coordinator = foodRecognitionCoordinator {
                FoodRecognitionView(viewModel: viewModel)
                    .environmentObject(coordinator)
            } else {
                ProgressView()
                    .onAppear {
                        let newFoodRecognitionCoordinator = FoodRecognitionCoordinator(
                            navigationController: coordinator.navigationController,
                            parentCoordinator: coordinator
                        )
                        coordinator.addChildCoordinator(newFoodRecognitionCoordinator)
                        self.foodRecognitionCoordinator = newFoodRecognitionCoordinator

                        let newViewModel = FoodRecognitionViewModel()
                        self.viewModel = newViewModel
                    }
            }
        }
    }
}

private struct RecipeRecommendationTabView: View {
    @ObservedObject var coordinator: MainTabCoordinator
    @State private var recipeRecommendationCoordinator: RecipeRecommendationCoordinator?
    @State private var viewModel: RecipeRecommendationViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel, let coordinator = recipeRecommendationCoordinator {
                RecipeRecommendationView(viewModel: viewModel, coordinator: coordinator)
            } else {
                ProgressView()
                    .onAppear {
                        let newRecipeRecommendationCoordinator = RecipeRecommendationCoordinator(
                            navigationController: coordinator.navigationController,
                            parentCoordinator: coordinator
                        )
                        coordinator.addChildCoordinator(newRecipeRecommendationCoordinator)
                        self.recipeRecommendationCoordinator = newRecipeRecommendationCoordinator

                        let newViewModel = RecipeRecommendationViewModel()
                        self.viewModel = newViewModel
                    }
            }
        }
    }
}


private struct FavoritesTabView: View {
    @ObservedObject var coordinator: MainTabCoordinator
    @State private var viewModel: FavoritesViewModel?

    var body: some View {
        VStack {
            if let viewModel = viewModel {
                FavoritesView(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        let newViewModel = FavoritesViewModel(authViewModel: coordinator.authViewModel)
                        newViewModel.onSelectDish = { dish in
                            // Convert Dish to Recipe for navigation
                            let recipe = Recipe.createFromDish(dish)
                            coordinator.showRecipeDetail(recipe)
                        }
                        newViewModel.onSelectRecipe = { recipe in
                            coordinator.showRecipeDetail(recipe)
                        }
                        newViewModel.onRequestLogin = {
                            // TODO: Navigate to login screen
                            print("FavoritesTabView: 請求導航到登入頁面")
                        }
                        self.viewModel = newViewModel
                    }
            }
        }
    }
}
