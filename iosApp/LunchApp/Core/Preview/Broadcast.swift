//
//  Broadcast.swift
//  LunchApp
//
//  A current value plus an `AsyncStream` per subscriber, standing in for a Kotlin StateFlow in
//  the in-memory cores. Each stream replays the current value first.
//

import Foundation

final class Broadcast<Value: Sendable> {
    private(set) var value: Value
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    init(_ value: Value) {
        self.value = value
    }

    func send(_ newValue: Value) {
        value = newValue
        for continuation in continuations.values {
            continuation.yield(newValue)
        }
    }

    func stream() -> AsyncStream<Value> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(value)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.continuations[id] = nil }
            }
        }
    }
}
