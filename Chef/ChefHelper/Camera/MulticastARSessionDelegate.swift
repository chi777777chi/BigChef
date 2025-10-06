//
//  MulticastARSessionDelegate.swift
//  ChefHelper
//
//  Created by AI Assistant on 2025/10/1.
//

import ARKit

/// 多重廣播 ARSessionDelegate，讓多個模組都能接收 ARSession 事件
final class MulticastARSessionDelegate: NSObject, ARSessionDelegate {
    
    private var delegates: [Weak<ARSessionDelegate>] = []
    
    /// 添加 delegate
    func addDelegate(_ delegate: ARSessionDelegate) {
        // 避免重複添加
        if !delegates.contains(where: { $0.value === delegate }) {
            delegates.append(Weak(value: delegate))
        }
    }
    
    /// 移除 delegate
    func removeDelegate(_ delegate: ARSessionDelegate) {
        delegates.removeAll { $0.value === delegate || $0.value == nil }
    }

    /// 移除所有 delegates
    func removeAllDelegates() {
        delegates.removeAll()
    }

    /// 清理已釋放的 delegate
    private func cleanup() {
        delegates.removeAll { $0.value == nil }
    }
    
    // MARK: - ARSessionDelegate 方法轉發
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        cleanup()
        delegates.forEach { $0.value?.session?(session, didUpdate: frame) }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        cleanup()
        delegates.forEach { $0.value?.session?(session, didAdd: anchors) }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        cleanup()
        delegates.forEach { $0.value?.session?(session, didUpdate: anchors) }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        cleanup()
        delegates.forEach { $0.value?.session?(session, didRemove: anchors) }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        cleanup()
        delegates.forEach { $0.value?.session?(session, didFailWithError: error) }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        cleanup()
        delegates.forEach { $0.value?.sessionWasInterrupted?(session) }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        cleanup()
        delegates.forEach { $0.value?.sessionInterruptionEnded?(session) }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        cleanup()
        delegates.forEach { $0.value?.session?(session, cameraDidChangeTrackingState: camera) }
    }
}

// MARK: - 弱引用包裝器
private class Weak<T: AnyObject> {
    weak var value: T?
    init(value: T) {
        self.value = value
    }
}
