//
//  HistoryCoordinator.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/8.
//


import UIKit
import SwiftUI

@MainActor
final class HistoryCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vm = HistoryViewModel()
        let view = HistoryView(viewModel: vm)
        let page = UIHostingController(rootView: view)
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.pushViewController(page, animated: false)
    }
}

