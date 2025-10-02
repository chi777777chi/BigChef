//
//  Router.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/17.
//

import UIKit
import QuartzCore // 為了 CATransaction

// MARK: - Router Protocol
protocol Router: AnyObject { // 確保它是 class-bound，如果其他地方需要 weak 引用
    var navigationController: UINavigationController { get set }

    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    func pop(animated: Bool, completion: (() -> Void)?)
    // 根據需要添加其他導航方法 (例如 present, dismiss, setRoot)
    func setRootViewController(_ viewController: UIViewController, animated: Bool)
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

// MARK: - 常見 Router 方法的預設實作
extension Router {
    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion) // 這個 completion 是 push 動畫完成時的回調
        navigationController.pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }

    func pop(animated: Bool, completion: (() -> Void)? = nil) {
        // 預設的 popViewController 沒有像 push 那樣直接的 completion block。
        // CATransaction 在這裡對於動畫完成的可靠性不高。
        // 對於更複雜的 pop completion，需要 UINavigationControllerDelegate。
        // 目前，如果提供了 completion，我們會立即呼叫它，或者稍作延遲。
        navigationController.popViewController(animated: animated)
        if let completion = completion {
            // 這個 pop 的 completion 有點棘手。如果 'animated' 是 true，
            // ViewController 不會立即被 pop。
            // 一個穩健的方法需要 UINavigationControllerDelegate。
            // 為了簡化，或者如果動畫是 false：
            if !animated {
                completion()
            } else {
                // 近似處理，或如下面討論的使用 delegate。
                // 0.3 秒是動畫時間的猜測值
                DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.3 : 0.0)) {
                    completion()
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
}
