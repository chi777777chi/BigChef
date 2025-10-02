//
//  UIKitRouter.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/17.
//

import UIKit
import QuartzCore // 為了 CATransaction

class UIKitRouter: NSObject, Router, UINavigationControllerDelegate {
    var navigationController: UINavigationController
    // 用於存儲當特定 ViewController 被 pop 時應執行的回調
    // Key: UIViewController 的記憶體位址字串
    private var onPopCompletions: [String: () -> Void] = [:]

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        self.navigationController.delegate = self // 設定 delegate 為自己
    }

    // MARK: - Router Protocol Methods

    // 覆寫 push 方法，以便儲存 onPopCompletion 回調供 Coordinator 使用
    // 這個 completion 參數的意圖是當這個特定的 ViewController 被 pop 時呼叫。
    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // CATransaction 的 setCompletionBlock 是針對 push 動畫本身，
        // 而不是當 ViewController 之後被 pop 時。
        // 如果 'completion' 參數是用於 push 動畫完成，它會在這裡設定。
        // 但考慮到 coordinator 希望知道其流程 (ViewController) 何時結束，
        // 我們將其與 onPop 關聯起來。
        CATransaction.begin()
        // CATransaction.setCompletionBlock(somePushAnimationCompletion) // 如果 completion 是給 push 動畫的

        // 如果提供了 onPopCallback，則儲存它
        if let onPopCallback = completion {
            let address = String(format: "%p", unsafeBitCast(viewController, to: Int.self))
            onPopCompletions[address] = onPopCallback
            print("Router: Stored onPop callback for VC at \(address)")
        }

        navigationController.pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }
    
    // pop 方法不再需要 'override' 關鍵字，因為它是對 Router 協定方法的實作，
    // 而 Router 協定的 pop 方法在 extension 中有預設實作。
    func pop(animated: Bool, completion: (() -> Void)? = nil) {
        navigationController.popViewController(animated: animated)

        // 處理外部傳入的 pop 動畫完成回調 (如果有的話)
        if let externalCompletion = completion {
            if !animated {
                externalCompletion()
            } else {
                // 動畫完成後執行
                DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.35 : 0.0)) {
                    externalCompletion()
                }
            }
        }
    }

    func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        navigationController.setViewControllers([viewController], animated: animated)
    }

    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        navigationController.present(viewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        navigationController.dismiss(animated: animated, completion: completion)
    }

    // MARK: - UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // 偵測是否有 view controller 被 pop
        guard let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
              !navigationController.viewControllers.contains(fromViewController) else {
            // 不是 pop 操作，或者沒有 transition coordinator (例如非動畫，或初始設定)
            return
        }

        // 這是一個 pop 操作，`fromViewController` 被 pop 了。
        let address = String(format: "%p", unsafeBitCast(fromViewController, to: Int.self))
        if let callback = onPopCompletions[address] {
            print("Router (Delegate): VC at \(address) was popped, triggering coordinator callback.")
            callback()
            onPopCompletions.removeValue(forKey: address) // 執行後移除回調
        }
    }

    func popViewController(animated: Bool = true) {
        let _ = navigationController.popViewController(animated: animated)
    }
}
