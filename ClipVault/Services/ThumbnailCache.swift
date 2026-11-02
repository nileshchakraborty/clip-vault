import AppKit

public final class ThumbnailCache {
    public static let shared = ThumbnailCache()

    private let cache = NSCache<NSUUID, NSImage>()

    private init() {
        cache.countLimit = 60 // Cap to match max 50 items + headroom
    }

    public func image(for id: UUID, data: Data?) -> NSImage? {
        if let cached = cache.object(forKey: id as NSUUID) {
            return cached
        }
        guard let data = data, let img = NSImage(data: data) else { return nil }
        cache.setObject(img, forKey: id as NSUUID)
        return img
    }

    public func remove(for id: UUID) {
        cache.removeObject(forKey: id as NSUUID)
    }

    public func clearAll() {
        cache.removeAllObjects()
    }
}
