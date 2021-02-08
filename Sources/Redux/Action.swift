//
//  Action.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation

public protocol Action {
    static var job: ActionJob { get }
}

// Return this action in beforePrcessingAction function
// if you need to cancel the current action.
public struct CancelAction: Action {
    public static var job: ActionJob {
        Job<EmptyState>()
    }
}
