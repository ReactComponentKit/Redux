//
//  ActionDispatcher.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation
import Combine

public typealias ActionDispatcher = (Action) -> Swift.Void
public typealias SideEffect = () -> (ActionDispatcher, StoreContext)
public protocol StoreContext: class {
}
