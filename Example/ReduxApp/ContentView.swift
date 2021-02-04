//
//  ContentView.swift
//  ReduxApp
//
//  Created by burt on 2021/02/04.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject
    private var store: AppStore
    
    var body: some View {
        
        VStack {
            Text("\(store.state.count)")
                .font(.title)
                .bold()
                .padding()
            if store.state.error != nil {
                Text("Error!")
            }
            HStack {
                Button(action: { store.dispatch(action: DecrementAction()) }) {
                    Text(" - ")
                        .font(.title)
                        .bold()
                }
                
                Spacer()
                
                Button(action: { store.dispatch(action: IncrementAction()) }) {
                    Text(" + ")
                        .font(.title)
                        .bold()
                }
                
                Spacer()
                
                Button(action: { store.dispatch(action: AsyncIncrementAction()) }) {
                    Text("Async +")
                        .bold()
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button(action: { store.dispatch(action: TestAsyncErrorAction()) }) {
                    Text(" Async with Error ")
                        .bold()
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 100)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
