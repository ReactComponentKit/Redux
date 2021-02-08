//
//  Job.swift
//  Bloket
//
//  Created by sungcheol.kim on 2021/02/07.
//

import Foundation

public protocol ActionJob {
}

public struct Job<S: State>: ActionJob {
    internal var middlewares: [Middleware<S>]
    internal var reducers: [Reducer<S>]
    internal var onNewState: StateMutation<S>?

    public init(middlewares: [Middleware<S>] = [], reducers: [Reducer<S>] = [], onNewState: StateMutation<S>? = nil) {
        self.middlewares = middlewares
        self.reducers = reducers
        self.onNewState = onNewState
    }
    
    public init(middleware: [Middleware<S>]) {
        self.init(middlewares: middleware, reducers: [], onNewState: nil)
    }
    
    public init(reducers: [Reducer<S>], onNewState: @escaping StateMutation<S>) {
        self.init(middlewares: [], reducers: reducers, onNewState: onNewState)
    }
}
