//
//  Middleware.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation

// Job before reducers
public typealias Middleware<S: State> = (S, Action, @escaping ActionDispatcher) throws -> Swift.Void
