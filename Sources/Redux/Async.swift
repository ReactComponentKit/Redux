//
//  Async.swift
//  Redux
//
//  Created by burt on 2021/02/08.
//

import Foundation

// abstract async state value
public enum Async<T: Equatable>: Equatable {
    case uninitialized
    case loading
    case success(value: T)
    case failed(error: Error)
    
    public var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    public var error: Error? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
    
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    public var isFail: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
    
    public static func == (lhs: Async<T>, rhs: Async<T>) -> Bool {
        switch lhs {
        case .uninitialized:
            if case .uninitialized = rhs {
                return true
            }
            return false
        case .loading:
            if case .loading = rhs {
                return true
            }
            return false
        case .failed:
            if case .failed = rhs {
                return true
            }
            return false
        case .success(value: let value):
            if case let .success(v) = rhs {
                return value == v
            }
            return false
        }
    }
}
