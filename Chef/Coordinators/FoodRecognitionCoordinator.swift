//
//  FoodRecognitionCoordinator.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/18.
//

import UIKit
import SwiftUI

@MainActor
final class FoodRecognitionCoordinator: Coordinator, ObservableObject {

    // MARK: - Protocol Requirements
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: MainTabCoordinator?

    // MARK: - Init
    init(navigationController: UINavigationController, parentCoordinator: MainTabCoordinator? = nil) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
    }

    // MARK: - Public Methods
    func start() {
        let viewModel = FoodRecognitionViewModel()
        let view = FoodRecognitionView(viewModel: viewModel)
            .environmentObject(self)
        let hostingController = UIHostingController(rootView: view)
        navigationController.pushViewController(hostingController, animated: true)
    }

    // MARK: - Navigation Methods
    func showCamera() {
        let coordinator = CameraCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }

    func showRecipeDetail(_ recipe: SuggestRecipeResponse) {
        let coordinator = RecipeCoordinator(navigationController: navigationController)
        addChildCoordinator(coordinator)
        coordinator.showRecipeDetail(recipe)
    }

    func handleLogout() {
        print("FoodRecognitionCoordinator: 開始處理登出")

        // 清除所有子協調器
        print("FoodRecognitionCoordinator: 清除子協調器")
        childCoordinators.removeAll()

        // 通知父協調器處理登出
        if let parentCoordinator = parentCoordinator {
            print("FoodRecognitionCoordinator: 找到父協調器，通知處理登出")
            parentCoordinator.handleLogout()
        } else {
            print("FoodRecognitionCoordinator: 錯誤 - 父協調器為空")
        }
    }
}