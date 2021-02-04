//
//  Middleware.swift
//  ReduxApp
//
//  Created by burt on 2021/02/04.
//

import Foundation

public typealias Middleware = (State, Action, @escaping ActionDispatcher) throws -> Swift.Void
