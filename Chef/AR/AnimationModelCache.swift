import Foundation
import RealityKit

enum AnimationModelCache {
    private static var cache = LRUCache<URL, Entity>(capacity: 20)  // 增加容量以支援兩份食譜
    private static let lock = NSLock()

    // 追蹤每個食譜使用的動畫 URL
    private static var recipeAnimations: [String: Set<URL>] = [:]  // recipeID -> URLs

    static func entity(for url: URL) throws -> Entity {
        try entity(for: url) { try Entity.load(contentsOf: url) }
    }

    static func entity(for url: URL, loader: () throws -> Entity) rethrows -> Entity {
        try lock.withLock {
            if let cached = cache[url] {
                print("✅ [AnimationModelCache] 從快取載入: \(url.lastPathComponent)")
                return cached.clone(recursive: true)
            }
            print("📥 [AnimationModelCache] 首次載入並快取: \(url.lastPathComponent)")
            let loaded = try loader()
            cache[url] = loaded
            return loaded.clone(recursive: true)
        }
    }

    /// 註冊食譜使用的動畫 URL（用於追蹤）
    static func registerAnimation(url: URL, forRecipe recipeID: String) {
        lock.withLock {
            if recipeAnimations[recipeID] == nil {
                recipeAnimations[recipeID] = Set<URL>()
            }
            recipeAnimations[recipeID]?.insert(url)
            print("📌 [AnimationModelCache] 註冊動畫 \(url.lastPathComponent) 給食譜 \(recipeID)")
        }
    }

    /// 清除特定食譜的所有動畫快取
    static func clearAnimations(forRecipe recipeID: String) {
        lock.withLock {
            guard let urls = recipeAnimations[recipeID] else {
                print("ℹ️ [AnimationModelCache] 食譜 \(recipeID) 沒有註冊的動畫")
                return
            }

            print("🗑️ [AnimationModelCache] 清除食譜 \(recipeID) 的 \(urls.count) 個動畫快取")
            for url in urls {
                cache[url] = nil
                print("   - 清除: \(url.lastPathComponent)")
            }

            // 移除追蹤記錄
            recipeAnimations.removeValue(forKey: recipeID)
        }
    }

    /// 清除所有快取的 AR 動畫資源（保留以防萬一需要）
    static func clearAll() {
        lock.withLock {
            print("🗑️ [AnimationModelCache] 清除所有 AR 快取資源")
            cache = LRUCache<URL, Entity>(capacity: 20)
            recipeAnimations.removeAll()
        }
    }

    /// 清除特定 URL 的快取
    static func clear(for url: URL) {
        lock.withLock {
            print("🗑️ [AnimationModelCache] 清除快取: \(url.lastPathComponent)")
            cache[url] = nil
        }
    }

    /// 獲取當前快取統計
    static func getCacheStats() -> (recipeCount: Int, capacity: Int) {
        lock.withLock {
            return (recipeCount: recipeAnimations.count, capacity: 20)
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
