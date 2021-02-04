//
//  Store.swift
//  ReduxApp
//
//  Created by burt on 2021/02/04.
//

import Foundation
import Combine

open class Store<S: State>: ObservableObject {
    private var cancellable: Set<AnyCancellable> = Set()
    
    @Published
    public private(set) var state: S
        
    public init(state: S = S()) {
        self.state = state
    }
    
    public func dispatch(action: Action) {
        action.middlewares.publisher
            .subscribe(on: DispatchQueue.global())
            .tryReduce(state, { [weak self] s, m in
                guard let strongSelf = self else {
                    return s
                }
                try m(s, action, strongSelf.dispatch)
                return s
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.state.error = (error, action)
                }
            }, receiveValue: { [weak self] _ in
                self?.state.error = nil
                self?.processReducers(action: action)
            })
            .store(in: &cancellable)
    }
    
    private func processReducers(action: Action) {
        action.reducers.publisher
            .subscribe(on: DispatchQueue.global())
            .reduce(state, { newState, reducer in
                return reducer(newState, action) as? S ?? newState
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                self?.state = state
            })
            .store(in: &cancellable)
    }
}
