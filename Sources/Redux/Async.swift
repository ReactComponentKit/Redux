//
//  Async.swift
//  Redux
//
//  Created by burt on 2021/02/08.
//

import Foundation

// abstract async state value
public enum Async<T> {
    case uninitialized
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
}
