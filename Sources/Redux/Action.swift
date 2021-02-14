//
//  Action.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation

public protocol Action {
    var name: String { get }
    var job: ActionJob { get }
}

extension Action {
    public var name: String {
        return "\(type(of: self))"
    }
}

extension Action {
    public func get<T>() -> T? {
        guard let act = self as? TemporalAction<T> else { return nil }
        return act.payload
    }
    
    public func getOr<T>(_ value: T) -> T {
        guard let act = self as? TemporalAction<T> else { return value }
        return act.payload
    }
}

// Return this action in beforePrcessingAction function
// if you need to cancel the current action.
public struct CancelAction: Action {
    public var job: ActionJob {
        Job<EmptyState>()
    }
}

struct TemporalAction<T>: Action {
    var payload: T
    var name: String
    var job: ActionJob = Job<EmptyState>()
}
