//
//  LoadState.swift
//  LunchApp
//
//  Shared async state for screens that fetch, plus the error view that maps `CoreError` to the
//  offline or service-problem empty state.
//

import SwiftUI

nonisolated enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(CoreError)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

extension CoreError {
    /// Normalises anything thrown by the core to a `CoreError`.
    @MainActor static func from(_ error: Error, component: StaticString = #fileID, operation: StaticString = #function) -> CoreError {
        let failure = error as? CoreError ?? .unknown(String(describing: error))
        let native = error as NSError
        if !(error is CancellationError) && !(native.domain == NSURLErrorDomain && native.code == NSURLErrorCancelled) {
            AppDiagnostics.record(failure, component: component, operation: operation)
        }
        return failure
    }
}

/// Offline or service-problem empty state with a retry action.
struct ErrorStateView: View {
    @Environment(AppEnvironment.self) private var app
    let error: CoreError
    let retry: () -> Void

    var body: some View {
        switch error {
        case .offline:
            EmptyState.offline(action: retry)
        case .service(code: "LOCATION_PERMISSION_DENIED", message: _), .service(code: "NO_LOCATION", message: _):
            EmptyState(variant: .nothingHere, title: "Choose where to look for lunch", message: "Choose a suburb or address, or enable location access. You can use Lunch without sharing your device location.", actionTitle: "Choose search area") { app.present(.searchArea) }
        default:
            EmptyState.serviceProblem(action: retry)
        }
    }
}

/// AI failures are service availability issues, not a request to subscribe again.
struct AIErrorStateView: View {
    @Environment(AppEnvironment.self) private var app
    let error: CoreError
    let retry: () -> Void

    var body: some View {
        switch error {
        case .offline:
            EmptyState.offline(action: retry)
        case .service(code: "LOCATION_PERMISSION_DENIED", message: _), .service(code: "NO_LOCATION", message: _):
            EmptyState(variant: .nothingHere, title: "Choose a search area", message: "AI picks need an area to search. Choose a suburb or address without enabling device location.", actionTitle: "Choose search area") { app.present(.searchArea) }
        case .service(code: "NO_CANDIDATES", message: _):
            EmptyState(variant: .nothingHere, title: Copy.AI.noMatchesTitle, message: Copy.AI.noMatchesBody, actionTitle: Copy.Action.retry, action: retry)
        case .service(code: "RATE_LIMITED", message: _):
            EmptyState(variant: .serviceProblem, title: Copy.AI.busyTitle, message: Copy.AI.busyBody, actionTitle: Copy.Action.retry, action: retry)
        default:
            EmptyState(variant: .serviceProblem, title: Copy.AI.unavailableTitle, message: Copy.AI.unavailableBody, actionTitle: Copy.Action.retry, action: retry)
        }
    }
}
