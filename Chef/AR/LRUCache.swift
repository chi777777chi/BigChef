
final class LRUCache<K: Hashable, V> {
    private let capacity: Int
    private var dict: [K : V] = [:]
    private var keys: [K] = []

    init(capacity: Int) { self.capacity = capacity }

    subscript(key: K) -> V? {
        get {
            if let idx = keys.firstIndex(of: key) { keys.remove(at: idx); keys.insert(key, at: 0) }
            return dict[key]
        }
        set {
            dict[key] = newValue
            keys.removeAll { $0 == key }
            keys.insert(key, at: 0)
            if keys.count > capacity, let last = keys.popLast() { dict.removeValue(forKey: last) }
        }
    }
}
