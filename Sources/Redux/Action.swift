//
//  Action.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation

public protocol Action {
}

// Return this action in beforePrcessingAction function
// if you need to cancel the current action.
public struct CancelAction: Action {
}
