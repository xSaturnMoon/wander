//
//  GlobeTab.swift
//  Wander
//

import SwiftUI
@preconcurrency import SceneKit
import CoreGraphics
import CoreLocation

// MARK: - Globe Tab

struct GlobeTab: View {
    @ObservedObject private var locationManager = LocationManager.shared

    @AppStorage("visitedCountriesData") private var visitedCountriesData: String = "[]"
    var visitedCountries: Set<String> {
        get {
            guard let data = visitedCountriesData.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return Set(arr)
        }
        nonmutating set {
            let arr = Array(newValue).sorted()
            if let data = try? JSONEncoder().encode(arr),
               let str = String(data: data, encoding: .utf8) {
                visitedCountriesData = str
            }
        }
    }

    // All available country names (populated after GeoJSON loads)
    @State private var allCountries: [String] = []

    @State private var showAddSheet = false
    @State private var showRemoveSheet = false
    @State private var searchText = ""

    // Total countries in Natural Earth 110m dataset
    private var totalCount: Int { allCountries.isEmpty ? 195 : allCountries.count }
    private var visitedCount: Int { visitedCountries.count }
    private var percentage: Double {
        totalCount > 0 ? Double(visitedCount) / Double(totalCount) * 100 : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // ── Globe ──────────────────────────────────────────────
                GlobeSceneView(
                    visitedCountries: Binding(
                        get: { visitedCountries },
                        set: { visitedCountries = $0 }
                    ),
                    userLocation: locationManager.userLocation,
                    onCountriesLoaded: { names in
                        allCountries = names.sorted()
                    }
                )
                .frame(height: UIScreen.main.bounds.height * 0.42)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

                // ── Stats Card ─────────────────────────────────────────
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Paesi visitati")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(visitedCount) / \(totalCount)")
                                .font(.title2.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Completato")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f%%", percentage))
                                .font(.title2.bold())
                        }
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(UIColor.tertiarySystemFill))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.85))
                                .frame(width: geo.size.width * CGFloat(percentage / 100), height: 8)
                                .animation(.spring(duration: 0.5), value: visitedCount)
                        }
                    }
                    .frame(height: 8)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)

                // ── Action Buttons ──────────────────────────────────────
                HStack(spacing: 12) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Aggiungi paese", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .foregroundStyle(.primary)

                    Button {
                        showRemoveSheet = true
                    } label: {
                        Label("Rimuovi", systemImage: "minus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .foregroundStyle(.red)
                    .disabled(visitedCountries.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top, 8)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        // ── Add Sheet ──────────────────────────────────────────────────
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                List {
                    ForEach(filteredCountries(all: true), id: \.self) { country in
                        Button {
                            visitedCountries.insert(country)
                            showAddSheet = false
                        } label: {
                            HStack {
                                Text(country)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if visitedCountries.contains(country) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(visitedCountries.contains(country))
                    }
                }
                .searchable(text: $searchText, prompt: "Cerca paese…")
                .navigationTitle("Aggiungi paese")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annulla") { showAddSheet = false }
                    }
                }
            }
        }
        // ── Remove Sheet ───────────────────────────────────────────────
        .sheet(isPresented: $showRemoveSheet) {
            NavigationStack {
                List {
                    ForEach(Array(visitedCountries).sorted(), id: \.self) { country in
                        Button(role: .destructive) {
                            visitedCountries.remove(country)
                            if visitedCountries.isEmpty { showRemoveSheet = false }
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(country)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .navigationTitle("Rimuovi paese")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Chiudi") { showRemoveSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func filteredCountries(all: Bool) -> [String] {
        let source = all ? allCountries : Array(visitedCountries).sorted()
        guard !searchText.isEmpty else { return source }
        return source.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Globe Scene View

struct GlobeSceneView: UIViewRepresentable {
    @Binding var visitedCountries: Set<String>
    var userLocation: CLLocationCoordinate2D?
    var onCountriesLoaded: ([String]) -> Void

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true

        let scene = SCNScene()
        scnView.scene = scene

        let globeGeometry = SCNSphere(radius: 10)
        globeGeometry.segmentCount = 64

        let globeMaterial = SCNMaterial()
        globeMaterial.diffuse.contents = UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)
        globeMaterial.lightingModel = .lambert

        globeGeometry.materials = [globeMaterial]

        let globeNode = SCNNode(geometry: globeGeometry)
        globeNode.name = "globe"
        scene.rootNode.addChildNode(globeNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 26)
        scene.rootNode.addChildNode(cameraNode)

        context.coordinator.globeNode = globeNode
        context.coordinator.globeMaterial = globeMaterial
        context.coordinator.scnView = scnView

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(pan)

        // Initial load
        context.coordinator.loadGeoJSON(visitedCountries: visitedCountries)

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        context.coordinator.onCountriesLoaded = onCountriesLoaded
        context.coordinator.refreshTexture(visitedCountries: visitedCountries)
        context.coordinator.updateUserLocation(userLocation)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(visitedCountries: $visitedCountries, onCountriesLoaded: onCountriesLoaded)
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject {
        @Binding var visitedCountries: Set<String>
        var onCountriesLoaded: ([String]) -> Void

        weak var globeNode: SCNNode?
        weak var scnView: SCNView?
        weak var globeMaterial: SCNMaterial?

        // Rotation state
        private var previousPanPoint: CGPoint = .zero
        private var displayLink: CADisplayLink?
        private var velocity: CGPoint = .zero
        private var angleX: Float = 0
        private var angleY: Float = 0

        // User dot
        private var userLocationNode: SCNNode?

        // GeoJSON cache
        private var cachedFeatures: [[String: Any]] = []
        private var lastVisited: Set<String> = []
        private var isLoading = false

        init(visitedCountries: Binding<Set<String>>, onCountriesLoaded: @escaping ([String]) -> Void) {
            self._visitedCountries = visitedCountries
            self.onCountriesLoaded = onCountriesLoaded
            super.init()
        }

        // MARK: GeoJSON Load & Render

        func loadGeoJSON(visitedCountries: Set<String>) {
            guard !isLoading else { return }
            isLoading = true

            let url = URL(string: "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_admin_0_countries.geojson")!
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self,
                      let data,
                      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let features = root["features"] as? [[String: Any]]
                else { return }

                let names = features.compactMap {
                    ($0["properties"] as? [String: Any])?["ADMIN"] as? String
                }

                Task { @MainActor in
                    self.cachedFeatures = features
                    self.isLoading = false
                    self.onCountriesLoaded(names)
                    self.renderAndApplyTexture(visitedCountries: visitedCountries)
                }
            }.resume()
        }

        func refreshTexture(visitedCountries: Set<String>) {
            guard visitedCountries != lastVisited else { return }
            lastVisited = visitedCountries
            if !cachedFeatures.isEmpty {
                renderAndApplyTexture(visitedCountries: visitedCountries)
            }
        }

        private func renderAndApplyTexture(visitedCountries: Set<String>) {
            let features = cachedFeatures
            let visited = visitedCountries

            Task {
                let image = await Task.detached(priority: .userInitiated) {
                    return Self.renderTexture(features: features, visitedCountries: visited)
                }.value
                
                self.globeMaterial?.diffuse.contents = image
            }
        }

        nonisolated private static func renderTexture(features: [[String: Any]], visitedCountries: Set<String>) -> UIImage {
            let W: CGFloat = 2048
            let H: CGFloat = 1024

            let bgColor    = UIColor(red: 44/255,  green: 44/255,  blue: 46/255,  alpha: 1)
            let borderColor = UIColor(red: 99/255,  green: 99/255,  blue: 102/255, alpha: 1)
            let visitedFill = UIColor(red: 180/255, green: 180/255, blue: 185/255, alpha: 1)

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: W, height: H))
            return renderer.image { ctx in
                let cg = ctx.cgContext

                // Background
                bgColor.setFill()
                cg.fill(CGRect(x: 0, y: 0, width: W, height: H))

                // Pass 1: Fill visited countries
                for feature in features {
                    guard let props = feature["properties"] as? [String: Any],
                          let name = props["ADMIN"] as? String,
                          visitedCountries.contains(name),
                          let geom = feature["geometry"] as? [String: Any],
                          let type = geom["type"] as? String else { continue }

                    visitedFill.setFill()
                    for polygon in extractRings(geom: geom, type: type) {
                        guard let first = polygon.first, first.count >= 2 else { continue }
                        let path = CGMutablePath()
                        path.move(to: CGPoint(x: (first[0]+180)/360*W, y: (90-first[1])/180*H))
                        for pt in polygon.dropFirst() where pt.count >= 2 {
                            path.addLine(to: CGPoint(x: (pt[0]+180)/360*W, y: (90-pt[1])/180*H))
                        }
                        path.closeSubpath()
                        cg.addPath(path)
                        cg.fillPath()
                    }
                }

                // Pass 2: Draw all borders
                borderColor.setStroke()
                cg.setLineWidth(0.8)
                cg.setLineCap(.round)
                cg.setLineJoin(.round)

                for feature in features {
                    guard let geom = feature["geometry"] as? [String: Any],
                          let type = geom["type"] as? String else { continue }

                    for polygon in extractRings(geom: geom, type: type) {
                        guard let first = polygon.first, first.count >= 2 else { continue }
                        cg.move(to: CGPoint(x: (first[0]+180)/360*W, y: (90-first[1])/180*H))
                        for pt in polygon.dropFirst() where pt.count >= 2 {
                            cg.addLine(to: CGPoint(x: (pt[0]+180)/360*W, y: (90-pt[1])/180*H))
                        }
                        cg.strokePath()
                    }
                }
            }
        }

        nonisolated private static func extractRings(geom: [String: Any], type: String) -> [[[Double]]] {
            switch type {
            case "Polygon":
                return (geom["coordinates"] as? [[[Double]]]) ?? []
            case "MultiPolygon":
                let polys = (geom["coordinates"] as? [[[[Double]]]]) ?? []
                return polys.flatMap { $0 }
            default:
                return []
            }
        }

        // MARK: Pan / Inertia

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let pt = gesture.translation(in: view)

            switch gesture.state {
            case .began:
                previousPanPoint = pt
                displayLink?.invalidate()
            case .changed:
                let delta = CGPoint(x: pt.x - previousPanPoint.x, y: pt.y - previousPanPoint.y)
                rotateGlobe(dx: delta.x, dy: delta.y)
                previousPanPoint = pt
                velocity = gesture.velocity(in: view)
            case .ended, .cancelled:
                startInertia()
            default: break
            }
        }

        private func rotateGlobe(dx: CGFloat, dy: CGFloat) {
            guard let node = globeNode else { return }
            let s: Float = 0.005
            angleX += Float(dx) * s
            angleY = max(-.pi/2, min(.pi/2, angleY + Float(dy) * s))
            node.eulerAngles = SCNVector3(angleY, angleX, 0)
        }

        private func startInertia() {
            displayLink = CADisplayLink(target: self, selector: #selector(updateInertia))
            displayLink?.add(to: .main, forMode: .common)
        }

        @objc private func updateInertia() {
            velocity.x *= 0.95
            velocity.y *= 0.95
            rotateGlobe(dx: velocity.x * 0.016, dy: velocity.y * 0.016)
            if abs(velocity.x) < 1 && abs(velocity.y) < 1 { displayLink?.invalidate() }
        }

        // MARK: User Location Dot

        func updateUserLocation(_ location: CLLocationCoordinate2D?) {
            guard let location, let globeNode else {
                userLocationNode?.removeFromParentNode()
                userLocationNode = nil
                return
            }

            let r: Float = 10.05
            let lat = Float(location.latitude) * .pi / 180
            let lon = Float(location.longitude) * .pi / 180
            let pos = SCNVector3(r * cos(lat) * sin(lon), r * sin(lat), r * cos(lat) * cos(lon))

            if let existing = userLocationNode {
                existing.runAction(.move(to: pos, duration: 1))
            } else {
                let geo = SCNSphere(radius: 0.18)
                let mat = SCNMaterial()
                mat.diffuse.contents = UIColor.white
                mat.emission.contents = UIColor.white.withAlphaComponent(0.6)
                geo.materials = [mat]

                let dot = SCNNode(geometry: geo)
                dot.position = pos
                globeNode.addChildNode(dot)
                userLocationNode = dot
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GlobeTab()
}
