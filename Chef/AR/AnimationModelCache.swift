import Foundation
import RealityKit

enum AnimationModelCache {
    private static var cache = LRUCache<URL, Entity>(capacity: 10)
    private static let lock = NSLock()

    static func entity(for url: URL) throws -> Entity {
        try entity(for: url) { try Entity.load(contentsOf: url) }
    }

    static func entity(for url: URL, loader: () throws -> Entity) rethrows -> Entity {
        try lock.withLock {
            if let cached = cache[url] {
                print("✅ [AnimationModelCache] 從快取載入: \(url.lastPathComponent)")
                // ⚠️ 問題：直接返回 cached 會導致多個動畫共享同一個 Entity 實例
                // 這會造成視圖問題，因為一個 Entity 只能有一個父節點
                return cached.clone(recursive: true)
            }
            print("📥 [AnimationModelCache] 首次載入並快取: \(url.lastPathComponent)")
            let loaded = try loader()
            cache[url] = loaded
            // 返回 clone，保留原始實例在快取中
            return loaded.clone(recursive: true)
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
