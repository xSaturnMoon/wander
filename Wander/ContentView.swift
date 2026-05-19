//
//  ContentView.swift
//  Wander
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GlobeTab()
                .tabItem {
                    Image(systemName: "globe")
                }

            MapTab()
                .tabItem {
                    Image(systemName: "map")
                }

            SettingsTab()
                .tabItem {
                    Image(systemName: "gearshape")
                }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
}
