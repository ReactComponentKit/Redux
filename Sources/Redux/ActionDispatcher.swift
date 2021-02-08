//
//  ActionDispatcher.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation
import Combine

public typealias ActionDispatcher = (Action) -> Swift.Void
public typealias SideEffect = () -> (ActionDispatcher, Cancellables)
public protocol Cancellables: class {
    var bag: Set<AnyCancellable> { get set }
}
