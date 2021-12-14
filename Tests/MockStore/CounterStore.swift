//
//  CounterStore.swift
//  ReduxTests
//
//  Created by sungcheol.kim on 2021/11/06.
//  email: skyfe79@gmail.com
//  github: https://github.com/skyfe79
//  github: https://github.com/ReactComponentKit
//

import Foundation
import Redux

struct Counter: State {
    var count = 0
}

class CounterStore: Store<Counter> {
    init() {
        super.init(state: Counter())
    }
    
    // computed
    @Published
    var count = 0
    
    override func computed(new: Counter, old: Counter) {
        self.count = new.count
    }
    
    // mutation
    private func increment(counter: inout Counter, payload: Int) {
        counter.count += payload
    }
    
    private func decrement(counter: inout Counter, payload: Int) {
        counter.count -= payload
    }
    
    // actions
    func incrementAction(payload: Int) {
        self.commit(mutation: increment, payload: payload)
    }
    
    func decrementAction(payload: Int) {
        self.commit(mutation: decrement, payload: payload)
    }
    
    func asyncIncrementAction(payload: Int) async {
        await Task.sleep(1 * 1_000_000_000)
        self.commit(mutation: increment, payload: payload)
    }
    
    func asyncDecrementAction(payload: Int) async {
        await Task.sleep(1 * 1_000_000_000)
        self.commit(mutation: decrement, payload: payload)
    }
}
