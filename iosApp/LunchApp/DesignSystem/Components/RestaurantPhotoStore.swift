import Foundation
import ImageIO
import UIKit

/// Transient rendering assets only. Never persists Google photo bytes or names to disk.
/// Full fresh photo URLs are the identity: a replacement photo must never inherit an old image.
@MainActor
final class RestaurantPhotoStore {
    static let shared = RestaurantPhotoStore()
    typealias Fetch = @Sendable (URL) async throws -> Data

    private final class Entry {
        let photo: DecodedRestaurantPhoto
        let expiresAt: Date
        init(_ photo: DecodedRestaurantPhoto, expiresAt: Date) {
            self.photo = photo
            self.expiresAt = expiresAt
        }
    }

    private let images = NSCache<NSURL, Entry>()
    private var requests: [URL: (id: UUID, task: Task<DecodedRestaurantPhoto?, Never>)] = [:]
    private let fetch: Fetch
    private let timeToLive: TimeInterval
    private var generation = 0
    private var observers: [NSObjectProtocol] = []

    init(timeToLive: TimeInterval = 300, fetch: Fetch? = nil) {
        self.timeToLive = timeToLive
        if let fetch { self.fetch = fetch } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            configuration.httpMaximumConnectionsPerHost = 4
            configuration.timeoutIntervalForRequest = 20
            let session = URLSession(configuration: configuration)
            self.fetch = { url in
                let (data, response) = try await session.data(from: url)
                guard let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode),
                      response.mimeType?.hasPrefix("image/") == true,
                      data.count <= 8 * 1024 * 1024 else { throw URLError(.badServerResponse) }
                return data
            }
        }
        images.totalCostLimit = 32 * 1024 * 1024
        images.countLimit = 40
        for name in [UIApplication.didReceiveMemoryWarningNotification, UIApplication.didEnterBackgroundNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.removeAll() }
            })
        }
    }

    isolated deinit { observers.forEach(NotificationCenter.default.removeObserver) }

    func cachedImage(for url: URL) -> UIImage? {
        guard let entry = images.object(forKey: url as NSURL) else { return nil }
        guard entry.expiresAt > Date() else {
            images.removeObject(forKey: url as NSURL)
            return nil
        }
        return entry.photo.image
    }

    func image(for url: URL) async -> UIImage? {
        if let image = cachedImage(for: url) { return image }
        let revision = generation
        if let request = requests[url] {
            let photo = await request.task.value
            return generation == revision ? photo?.image : nil
        }
        let id = UUID()
        let task = Task { [fetch] () -> DecodedRestaurantPhoto? in
            do {
                let data = try await fetch(url)
                try Task.checkCancellation()
                return await Task.detached(priority: .userInitiated) {
                    DecodedRestaurantPhoto.decode(data)
                }.value
            } catch { return nil }
        }
        requests[url] = (id, task)
        let photo = await task.value
        guard generation == revision, requests[url]?.id == id else { return nil }
        requests.removeValue(forKey: url)
        if let photo {
            images.setObject(Entry(photo, expiresAt: Date().addingTimeInterval(timeToLive)), forKey: url as NSURL, cost: photo.byteCost)
        }
        return photo?.image
    }

    func removeAll() {
        generation += 1
        requests.values.forEach { $0.task.cancel() }
        requests.removeAll()
        images.removeAllObjects()
    }
}

/// Immutable decoded bitmap; construction happens off the main actor, display on it.
nonisolated private final class DecodedRestaurantPhoto: @unchecked Sendable {
    let image: UIImage
    let byteCost: Int
    private init(_ bitmap: CGImage) {
        image = UIImage(cgImage: bitmap)
        byteCost = bitmap.bytesPerRow * bitmap.height
    }

    static func decode(_ data: Data) -> DecodedRestaurantPhoto? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let bitmap = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
              ] as CFDictionary) else { return nil }
        return DecodedRestaurantPhoto(bitmap)
    }
}
