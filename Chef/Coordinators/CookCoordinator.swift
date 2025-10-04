////
////  CookCoordinator.swift
////  ChefHelper
////
////  Created by 陳泓齊 on 2025/5/7.
////
//
//
//import UIKit
//
//final class CookCoordinator: Coordinator {
//    var childCoordinators: [any Coordinator] = []
//
//    func start() {
//        // This coordinator must be started with recipe steps.
//        // Calling the parameterless start() is a programmer error.
//        assertionFailure("CookCoordinator.start() called without steps – use start(with:) instead.")
//    }
//
//    private let nav: UINavigationController
//    init(nav: UINavigationController) { self.nav = nav }
//
//    func start(with steps: [RecipeStep]) {
//        let vc = CookViewController(steps: steps)
//        nav.pushViewController(vc, animated: true)
//    }
//}

import UIKit

@MainActor
final class CookCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: Coordinator?
    var onComplete: (() -> Void)?

    init(navigationController: UINavigationController, parentCoordinator: Coordinator? = nil) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
    }

    func start() {
        // This coordinator must be started with recipe steps.
        // Calling the parameterless start() is a programmer error.
        assertionFailure("CookCoordinator.start() called without steps – use start(with:) instead.")
    }

    func start(with steps: [RecipeStep], dishName: String = "料理") {
        let loadingVC = CookLoadingViewController(steps: steps, dishName: dishName)
        loadingVC.hidesBottomBarWhenPushed = true
        loadingVC.onReady = { [weak self] preparedSteps in
            self?.showCookView(steps: preparedSteps, dishName: dishName)
        }
        loadingVC.onFailed = { [weak self] _ in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(loadingVC, animated: true)
    }

    private func showCookView(steps: [RecipeStep], dishName: String) {
        let vc = CookViewController(
            steps: steps,
            dishName: dishName,
            onComplete: { [weak self] in
                self?.handleCompletion()
            }
        )
        vc.hidesBottomBarWhenPushed = true

        var stack = navigationController.viewControllers
        if stack.isEmpty {
            navigationController.setViewControllers([vc], animated: true)
        } else {
            stack[stack.count - 1] = vc
            navigationController.setViewControllers(stack, animated: true)
        }
    }

    private func handleCompletion() {
        print("🏁 CookCoordinator: 烹飪完成，開始清理")

        // 先 pop AR 烹飪頁面
        navigationController.popViewController(animated: true) { [weak self] in
            guard let self = self else { return }

            print("🏁 CookCoordinator: AR 頁面已 pop，清理 coordinator")

            // 呼叫完成回調（返回首頁）
            self.onComplete?()

            // 從父 coordinator 移除自己
            if let parent = self.parentCoordinator {
                parent.removeChildCoordinator(self)
            }
        }
    }
}
