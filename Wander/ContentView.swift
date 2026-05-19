//
//  ContentView.swift
//  Wander
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab(value: 0, role: nil) {
                GlobeTab()
            } label: {
                Image(systemName: "globe")
            }

            Tab(value: 1, role: nil) {
                MapTab()
            } label: {
                Image(systemName: "map")
            }

            Tab(value: 2, role: nil) {
                SettingsTab()
            } label: {
                Image(systemName: "gearshape")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
}
