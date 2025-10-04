import Foundation
import RealityKit

enum AnimationModelCache {
    private static var cache = LRUCache<URL, Entity>(capacity: 32)
    private static let lock = NSLock()

    static func entity(for url: URL) throws -> Entity {
        try entity(for: url) { try Entity.load(contentsOf: url) }
    }

    static func entity(for url: URL, loader: () throws -> Entity) rethrows -> Entity {
        try lock.withLock {
            if let cached = cache[url] {
                return cached
            }
            let loaded = try loader()
            cache[url] = loaded
            return loaded
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
