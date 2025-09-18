//
//  MainTabCoordinator.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/3.
//

import UIKit
import SwiftUICore
import SwiftUI

@MainActor
final class MainTabCoordinator: Coordinator, ObservableObject {

    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    /// 提供給 AppCoordinator 當 rootViewController

    var navigationController: UINavigationController
    weak var parentCoordinator: AppCoordinator?
    
    init(navigationController: UINavigationController, parentCoordinator: AppCoordinator? = nil) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
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
                Label("掃描", systemImage: "camera.fill")
            }

            // Food Recognition Tab
            NavigationStack {
                FoodRecognitionTabView(coordinator: self)
            }
            .tabItem {
                Label("辨識", systemImage: "camera.viewfinder")
            }

            // Settings Tab
            NavigationStack {
                SettingsView()
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
                            parentCoordinator: coordinator
                        )
                        coordinator.addChildCoordinator(newHomeCoordinator)
                        self.homeCoordinator = newHomeCoordinator
                        
                        // 然後創建 ViewModel 並設置回調
                        let newViewModel = HomeViewModel()
                        newViewModel.onSelectDish = { [weak newHomeCoordinator] dish in
                            newHomeCoordinator?.showDishDetail(dish)
                        }
                        newViewModel.onRequestLogout = { [weak newHomeCoordinator] in
                            newHomeCoordinator?.handleLogout()
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
            if let viewModel = viewModel {
                FoodRecognitionView(viewModel: viewModel)
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
