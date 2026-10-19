import Foundation
import Testing
import UIKit
@testable import LunchApp

private actor PhotoFetchProbe {
    private(set) var calls = 0
    let data: Data
    let failFirst: Bool
    init(data: Data, failFirst: Bool = false) { self.data = data; self.failFirst = failFirst }
    func fetch(_ url: URL) async throws -> Data {
        calls += 1
        if failFirst, calls == 1 { throw URLError(.networkConnectionLost) }
        try await Task.sleep(for: .milliseconds(25))
        return data
    }
}

@MainActor
struct RestaurantPhotoStoreTests {
    private let url = URL(string: "https://photos.example.test/fresh-photo?maxWidth=800")!

    private func probe(failFirst: Bool = false) -> PhotoFetchProbe {
        let data = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).pngData { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return PhotoFetchProbe(data: data, failFirst: failFirst)
    }

    @Test func concurrent_cards_and_return_visit_share_one_download_and_bitmap() async throws {
        let probe = probe()
        let store = RestaurantPhotoStore(fetch: { try await probe.fetch($0) })
        let first = Task { await store.image(for: url) }
        let second = Task { await store.image(for: url) }
        let a = try #require(await first.value)
        let b = try #require(await second.value)
        let again = try #require(await store.image(for: url))
        #expect(a === b)
        #expect(a === again)
        #expect(await probe.calls == 1)
    }

    @Test func replacement_photo_url_does_not_reuse_the_previous_photo() async {
        let probe = probe()
        let store = RestaurantPhotoStore(fetch: { try await probe.fetch($0) })
        _ = await store.image(for: url)
        let other = URL(string: "https://photos.example.test/replacement-photo?maxWidth=800")!
        #expect(store.cachedImage(for: other) == nil)
        _ = await store.image(for: other)
        #expect(await probe.calls == 2)
    }

    @Test func failures_are_not_cached_and_can_retry() async {
        let probe = probe(failFirst: true)
        let store = RestaurantPhotoStore(fetch: { try await probe.fetch($0) })
        #expect(await store.image(for: url) == nil)
        #expect(await store.image(for: url) != nil)
        #expect(await probe.calls == 2)
    }

    @Test func expired_rendering_asset_is_loaded_again() async {
        let probe = probe()
        let store = RestaurantPhotoStore(timeToLive: 0, fetch: { try await probe.fetch($0) })
        _ = await store.image(for: url)
        #expect(store.cachedImage(for: url) == nil)
        _ = await store.image(for: url)
        #expect(await probe.calls == 2)
    }

    @Test func background_or_memory_pressure_purge_releases_retained_images() async {
        let probe = probe()
        let store = RestaurantPhotoStore(fetch: { try await probe.fetch($0) })
        _ = await store.image(for: url)
        store.removeAll()
        #expect(store.cachedImage(for: url) == nil)
        _ = await store.image(for: url)
        #expect(await probe.calls == 2)
    }

    @Test func purging_during_download_cannot_repopulate_old_session() async {
        let probe = probe()
        let store = RestaurantPhotoStore(fetch: { try await probe.fetch($0) })
        let request = Task { await store.image(for: url) }
        while await probe.calls == 0 { await Task.yield() }
        store.removeAll()
        #expect(await request.value == nil)
        #expect(store.cachedImage(for: url) == nil)
        #expect(await store.image(for: url) != nil)
        #expect(await probe.calls == 2)
    }
}
