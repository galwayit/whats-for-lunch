//
//  DeviceLocationProvider.swift
//  LunchApp
//
//  Real CoreLocation fix for demo builds, so the in-memory core shows places around
//  wherever the phone actually is instead of the fixed sample anchor.
//
//  @file DeviceLocationProvider.swift
//  @description `LocationProvider` backed by CoreLocation, with a fixed fallback.
//  @author AI Assistant
//  @date 2026-09-23
//

import CoreLocation
import Foundation

/// Asks CoreLocation for a single fix, and falls back to `fallback` when permission is
/// refused, the fix times out, or the device has location services switched off.
///
/// The preview core normally uses `PreviewLocationProvider`, which always answers with the
/// sample anchor so screenshots and tests stay deterministic. Demo builds use this instead
/// so the phone reports where it really is.
final class DeviceLocationProvider: NSObject, LocationProvider, CLLocationManagerDelegate {
    private let fallback: Location
    private let timeout: Duration
    private let manager = CLLocationManager()

    /// Continuations waiting on the current request. CoreLocation calls the delegate on the
    /// main queue, and every access below is hopped onto the main actor, so this needs no
    /// further locking.
    private var waiting: [CheckedContinuation<Location, Never>] = []
    private var cached: Location?

    init(fallback: Location, timeout: Duration = .seconds(8)) {
        self.fallback = fallback
        self.timeout = timeout
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.delegate = self
    }

    func current() async throws -> Location {
        if let cached { return cached }
        return await withTaskGroup(of: Location.self) { group in
            group.addTask { await self.requestFix() }
            group.addTask {
                try? await Task.sleep(for: self.timeout)
                return self.fallback
            }
            let first = await group.next() ?? fallback
            group.cancelAll()
            return first
        }
    }

    func hasPermission() async -> Bool {
        await MainActor.run {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: return true
            default: return false
            }
        }
    }

    private func requestFix() async -> Location {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                switch self.manager.authorizationStatus {
                case .denied, .restricted:
                    continuation.resume(returning: self.fallback)
                case .notDetermined:
                    self.waiting.append(continuation)
                    self.manager.requestWhenInUseAuthorization()
                default:
                    self.waiting.append(continuation)
                    self.manager.requestLocation()
                }
            }
        }
    }

    @MainActor
    private func finish(with location: Location) {
        cached = location
        let pending = waiting
        waiting.removeAll()
        for continuation in pending { continuation.resume(returning: location) }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                finish(with: fallback)
            default:
                break // Still .notDetermined: the prompt is on screen.
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let fix = locations.last else { return }
        MainActor.assumeIsolated {
            finish(with: Location(
                latitude: fix.coordinate.latitude,
                longitude: fix.coordinate.longitude,
                accuracyMetres: fix.horizontalAccuracy >= 0 ? fix.horizontalAccuracy : nil
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated { finish(with: fallback) }
    }
}
