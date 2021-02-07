//
//  Job.swift
//  Bloket
//
//  Created by sungcheol.kim on 2021/02/07.
//

import Foundation

public typealias StateMutation<S: State> = (inout S, S) -> Swift.Void

public struct Job<S: State> {
    var middlewares: [Middleware<S>]
    var reducers: [Reducer<S>]
    var onNewState: StateMutation<S>?

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
