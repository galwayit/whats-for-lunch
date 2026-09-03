//
//  LocationPermission.swift
//  LunchApp
//
//  Wraps the when-in-use authorisation prompt in an async call for onboarding step 5.
//

import CoreLocation

final class LocationPermission: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Bool, Never>?

    var isGranted: Bool {
        [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus)
    }

    var isDetermined: Bool { manager.authorizationStatus != .notDetermined }

    /// Shows the system prompt when the status is undetermined; resolves with the final answer.
    func request() async -> Bool {
        if isDetermined { return isGranted }
        manager.delegate = self
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        Task { @MainActor in
            self.continuation?.resume(returning: [.authorizedWhenInUse, .authorizedAlways].contains(status))
            self.continuation = nil
        }
    }
}
