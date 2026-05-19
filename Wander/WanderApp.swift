//
//  WanderApp.swift
//  Wander
//

import SwiftUI

@main
struct WanderApp: App {

    /// Persisted across launches — LoginView sets this true, SettingsTab sets it false.
    /// TODO: replace with a Firebase Auth state listener:
    /// Auth.auth().addStateDidChangeListener { _, user in isAuthenticated = user != nil }
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    /// Persisted theme selection set in SettingsTab.
    /// "System" → nil (follow device), "Light" → .light, "Dark" → .dark
    @AppStorage("theme") private var theme: String = "System"

    private var preferredColorScheme: ColorScheme? {
        switch theme {
        case "Light": return .light
        case "Dark":  return .dark
        default:      return nil   // "System" — honour the device setting
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    ContentView()
                } else {
                    LoginView(isAuthenticated: $isAuthenticated)
                }
            }
            // Apply theme globally so it covers TabView, sheets, and NavigationStacks.
            .preferredColorScheme(preferredColorScheme)
            .animation(.easeInOut(duration: 0.25), value: isAuthenticated)
        }
    }
}
