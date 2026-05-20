//
//  MapTab.swift
//  Wander
//

import SwiftUI
import MapKit

struct MapTab: View {
    var body: some View {
        Map()
            .mapStyle(.standard)
            .ignoresSafeArea()
    }
}

#Preview {
    MapTab()
}
