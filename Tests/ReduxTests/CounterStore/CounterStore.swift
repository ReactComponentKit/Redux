//
//  CounterStore.swift
//  Redux
//
//  Created by burt on 2021/02/08.
//

import Foundation

struct CounterState: State {
    var count: Int = 0
}

class CounterStore: Store<CounterState> {
}

struct IncrementAction: Action {
    let payload: Int
    var job: ActionJob {
        Job<CounterState>(keyPath: \.count, reducers: [counterReducer])
    }
}

struct DecrementAction: Action {
    let payload: Int
    var job: ActionJob {
        Job<CounterState>(reducers: [counterReducer]) { state, newState in
            state.count = newState.count
        }
    }
}


func counterReducer(state: CounterState, action: Action) -> CounterState {
    return state.copy { mutation in
        switch action {
        case let act as IncrementAction:
            mutation.count += act.payload
        case let act as DecrementAction:
            mutation.count -= act.payload
        default:
            break
        }
    }
}
