//
//  Reducer.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation

// pure function. mutate state.
public typealias Reducer = (State, Action) -> State
