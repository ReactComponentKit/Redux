//
//  Store.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation
import Combine

open class Store<S: State>: ObservableObject {
    private var cancellable: Set<AnyCancellable> = Set()
    
    @Published
    public private(set) var state: S
    
    private var actions = PassthroughSubject<Action, Never>()
    private var actionQueue: [Action] = []
    let actionQueueMutex = DispatchSemaphore(value: 1)
    public init(state: S = S()) {
        self.state = state
        self.processActions()
    }
    
    public func dispatch(action: Action) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.actions.send(action)
        }
    }
    
    open func beforeProcessingAction(state: S, action: Action) -> Action {
        // Override this function if need some job before processing action.
        return action
    }
    
    open func afterProcessingAction(state: S, action: Action) {
        // Override this function if need some job after processing action.
    }
    
    private func enqueueAction(action: Action) {
        actionQueueMutex.wait()
        defer { actionQueueMutex.signal() }
        actionQueue.append(action)
    }
    
    private func processActions() {
        actions
            .sink { [weak self] (action) in
                guard let strongSelf = self else { return }
                let currentAction = strongSelf.beforeProcessingAction(state: strongSelf.state, action: action)
                if type(of: currentAction) != CancelAction.self {
                    strongSelf.processMiddlewares(action: action)
                }
            }
            .store(in: &cancellable)
    }
    
    public func processMiddlewares(action: Action) {
        action.middlewares.publisher
            .subscribe(on: DispatchQueue.global())
            .tryReduce(state, { [weak self] s, m in
                guard let strongSelf = self else { return s }
                try m(s, action, strongSelf.enqueueAction)
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
                guard let strongSelf = self else { return }
                // update state
                strongSelf.state = state
                
                // do job after procesing action
                strongSelf.afterProcessingAction(state: state, action: action)

                // queueing actions
                strongSelf.actionQueueMutex.wait()
                defer { strongSelf.actionQueueMutex.signal() }
                if !strongSelf.actionQueue.isEmpty {
                    strongSelf.actionQueue.forEach {
                        strongSelf.actions.send($0)
                    }
                }
                strongSelf.actionQueue = []
            })
            .store(in: &cancellable)
    }
}
