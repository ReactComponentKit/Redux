//
//  Action.swift
//  ReduxApp
//
//  Created by burt on 2021/02/04.
//

import Foundation

public protocol Action {
    var middlewares: [Middleware] { get }
    var reducers: [Reducer] { get }
}

extension Action {
    public var middlewares: [Middleware] {
        return []
    }
    public var reducers: [Reducer] {
        return []
    }
}
