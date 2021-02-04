//
//  State.swift
//  ReduxApp
//
//  Created by burt on 2021/02/04.
//

import Foundation

public protocol State {
    var error: (Error, Action)? { get set }
    init()
}

extension State {
    public func copy(_ mutate: (_ mutableState: inout Self) -> Void) -> Self {
        var mutableState = self
        mutate(&mutableState)
        return mutableState
    }
}
