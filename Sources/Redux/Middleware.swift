//
//  Middleware.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation

// Job before reducers
public typealias Middleware = (State, Action, @escaping ActionDispatcher) throws -> Swift.Void
