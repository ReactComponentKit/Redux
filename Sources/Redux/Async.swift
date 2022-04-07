//
//  Async.swift
//  Redux
//
//  Created by burt on 2022/04/07.
//  email: skyfe79@gmail.com
//  github: https://github.com/skyfe79
//  github: https://github.com/ReactComponentKit
//

import Foundation

/**
 * Async<T>
 *
 * - Define Async<T> type for async state value.
 * - An async state value could be in multiple states for example, ilde, loading, value or error.
 * - If we define the state one by one, store's state will become very verbose.
 * - So we abstract async state to Async<T> type.
 * - @see AsyncEnumTypeTests.swift
 */
public enum Async<T: Equatable> {
    case idle
    case loading
    case value(value: T)
    case error(value: Error?)
}

// swiftlint:disable pattern_matching_keywords
extension Async: Equatable {
    public static func == (lhs: Async<T>, rhs: Async<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.value(let lhsValue), .value(let rhsValue)):
            return lhsValue == rhsValue
        case (.error(let lhsValue), .error(let rhsValue)):
            guard type(of: lhsValue) == type(of: rhsValue) else { return false }
            if lhsValue == nil && rhsValue == nil {
                return true
            }
            if let lhsError = lhsValue as? NSError, let rhsError = rhsValue as? NSError {
                return lhsError.domain == rhsError.domain
                && lhsError.code == rhsError.code
                && "\(lhsError)" == "\(rhsError)"
            }
            return false
        default:
            return false
        }
    }
    
    public static func == <R>(lhs: Async<T>, rhs: Async<R>) -> Bool {
        return false
    }
    
    public static func != <R>(lhs: Async<T>, rhs: Async<R>) -> Bool {
        return true
    }
}
// swiftlint:enable pattern_matching_keywords
