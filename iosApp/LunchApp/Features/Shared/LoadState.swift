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
    static func from(_ error: Error) -> CoreError {
        error as? CoreError ?? .unknown(String(describing: error))
    }
}

/// Offline or service-problem empty state with a retry action.
struct ErrorStateView: View {
    let error: CoreError
    let retry: () -> Void

    var body: some View {
        switch error {
        case .offline:
            EmptyState.offline(action: retry)
        default:
            EmptyState.serviceProblem(action: retry)
        }
    }
}
