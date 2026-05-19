//
//  WanderApp.swift
//  Wander
//

import SwiftUI

@main
struct WanderApp: App {

    /// Tracks authentication state.
    /// TODO: replace with a Firebase Auth state listener:
    /// Auth.auth().addStateDidChangeListener { _, user in isAuthenticated = user != nil }
    @State private var isAuthenticated = false

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
                    .transition(.opacity)
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
                    .transition(.opacity)
            }
        }
    }
}
