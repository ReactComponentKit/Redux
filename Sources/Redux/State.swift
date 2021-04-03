//
//  State.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation

public typealias StateMutation<S: State> = (inout S, S) -> Swift.Void

public protocol State {
    init()
}

extension State {
    public func copy(_ mutate: (_ mutableState: inout Self) -> Void) -> Self {
        var mutableState = self
        mutate(&mutableState)
        return mutableState
    }
}

internal struct EmptyState: State {
}
