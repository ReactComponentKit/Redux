//
//  UserStore.swift
//  ReduxTests
//
//  Created by sungcheol.kim on 2021/11/06.
//  email: skyfe79@gmail.com
//  github: https://github.com/skyfe79
//  github: https://github.com/ReactComponentKit
//

import Foundation
import Redux

struct User: Equatable, Codable {
    let id: Int
    var name: String
}

struct UserState: State {
    var users: [User] = []
}

class UserStore: Store<UserState> {
    
    init() {
        super.init(state: UserState())
    }
    
    // mutations
    private func SET_USERS(userState: inout UserState, payload: [User]) {
        userState.users = payload
    }
    
    private func SET_USER(userState: inout UserState, payload: User) {
        let index = userState.users.firstIndex { it in
            it.id == payload.id
        }
        
        if let index = index {
            userState.users[index] = payload
        }
    }
    
    private func fetchData(from url: URL) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: data)
            }.resume()
        }
    }
    
    private func fetchData(for request: URLRequest) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: data)
            }.resume()
        }
    }
    
    // actions
    func loadUsers() async {
        do {
            if let data = try await fetchData(from: URL(string: "https://jsonplaceholder.typicode.com/users/")!) {
                let users = try JSONDecoder().decode([User].self, from: data)
                commit(mutation: SET_USERS, payload: users)
            } else {
                commit(mutation: SET_USERS, payload: [])
            }
        } catch {
            print(#function, error)
            commit(mutation: SET_USERS, payload: [])
        }
    }
    
    func update(user: User) async throws {
        let params = try JSONEncoder().encode(user)
        var request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/users/\(user.id)")!)
        request.httpMethod = "PUT"
        request.httpBody = params
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let data = try await fetchData(for: request) {
            let user = try JSONDecoder().decode(User.self, from: data)
            commit(mutation: SET_USER, payload: user)
        }
    }
}
