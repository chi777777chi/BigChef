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
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // This coordinator must be started with recipe steps.
        // Calling the parameterless start() is a programmer error.
        assertionFailure("CookCoordinator.start() called without steps – use start(with:) instead.")
    }
    
    func start(with steps: [RecipeStep]) {
        let vc = CookViewController(steps: steps)
        vc.hidesBottomBarWhenPushed = true  // AR 模式隱藏 tab bar
        navigationController.pushViewController(vc, animated: true)
    }
}
