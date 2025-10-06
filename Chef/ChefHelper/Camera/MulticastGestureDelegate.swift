//
//  MulticastGestureDelegate.swift
//  ChefHelper
//
//  Created by AI Assistant on 2025/10/3.
//

import Foundation

/// 手勢 delegate 的多重廣播器，允許多個對象同時接收手勢事件
final class MulticastGestureDelegate: ARGestureDelegate {
    private var delegates: [Weak<AnyObject>] = []

    // MARK: - Delegate 管理
    func addDelegate(_ delegate: ARGestureDelegate) {
        // 避免重複添加
        removeDelegate(delegate)
        delegates.append(Weak(value: delegate as AnyObject))
    }

    func removeDelegate(_ delegate: ARGestureDelegate) {
        delegates.removeAll { weak in
            guard let obj = weak.value else { return true }
            return obj === (delegate as AnyObject)
        }
        cleanupDeallocatedDelegates()
    }

    func removeAllDelegates() {
        delegates.removeAll()
    }

    private func cleanupDeallocatedDelegates() {
        delegates.removeAll { $0.value == nil }
    }

    // MARK: - ARGestureDelegate Implementation
    func didRecognizeGesture(_ gestureType: GestureType) {
        cleanupDeallocatedDelegates()
        delegates.forEach { weak in
            (weak.value as? ARGestureDelegate)?.didRecognizeGesture(gestureType)
        }
    }

    func gestureStateDidChange(_ state: GestureState) {
        cleanupDeallocatedDelegates()
        delegates.forEach { weak in
            (weak.value as? ARGestureDelegate)?.gestureStateDidChange(state)
        }
    }

    func hoverProgressDidUpdate(_ progress: Float) {
        cleanupDeallocatedDelegates()
        delegates.forEach { weak in
            (weak.value as? ARGestureDelegate)?.hoverProgressDidUpdate(progress)
        }
    }

    func palmStateDidChange(_ palmState: PalmState) {
        cleanupDeallocatedDelegates()
        delegates.forEach { weak in
            (weak.value as? ARGestureDelegate)?.palmStateDidChange(palmState)
        }
    }

    func gestureRecognitionDidFail(with error: GestureRecognitionError) {
        cleanupDeallocatedDelegates()
        delegates.forEach { weak in
            (weak.value as? ARGestureDelegate)?.gestureRecognitionDidFail(with: error)
        }
    }
}

// MARK: - Weak Reference Wrapper
private struct Weak<T: AnyObject> {
    weak var value: T?
}
