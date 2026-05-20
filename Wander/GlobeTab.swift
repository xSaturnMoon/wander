//
//  GlobeTab.swift
//  Wander
//

import SwiftUI
import SceneKit
import CoreGraphics
import CoreLocation

// MARK: - AppStorage Helper for Array

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else { return "[]" }
        return result
    }
}

// MARK: - Globe Tab

struct GlobeTab: View {
    @StateObject private var locationManager = LocationManager.shared
    
    // Persist as a JSON array of strings
    @AppStorage("visitedCountries") private var visitedCountriesArray: [String] = []
    
    // Derived Set for O(1) lookups
    var visitedCountries: Set<String> {
        get { Set(visitedCountriesArray) }
        nonmutating set { visitedCountriesArray = Array(newValue) }
    }
    
    var body: some View {
        ScrollView {
            // Full screen 3D Globe
            GlobeSceneView(
                visitedCountries: Binding(
                    get: { self.visitedCountries },
                    set: { self.visitedCountries = $0 }
                ),
                userLocation: locationManager.userLocation
            )
            .frame(height: UIScreen.main.bounds.height * 0.4)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)
                
            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Globe Scene View (UIViewRepresentable)

struct GlobeSceneView: UIViewRepresentable {
    @Binding var visitedCountries: Set<String>
    var userLocation: CLLocationCoordinate2D?
    
    // Generates a dark globe texture by downloading Natural Earth coastline
    // GeoJSON and drawing each LineString onto a 2048×1024 equirectangular canvas.
    static func applyGlobeTexture(to material: SCNMaterial) {
        let W: CGFloat = 2048
        let H: CGFloat = 1024
        let bg = UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)
        let fg = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)

        // 1. Set dark fallback immediately (no flicker on first paint)
        material.diffuse.contents = bg

        // 2. Download GeoJSON from Natural Earth (confirmed working URL)
        let geoURL = URL(string:
            "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_admin_0_countries.geojson")!

        URLSession.shared.dataTask(with: geoURL) { data, _, _ in
            guard
                let data = data,
                let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let features = root["features"] as? [[String: Any]]
            else { return }

            // 3. Collect every Polygon / MultiPolygon border into one flat array of polylines
            var polylines: [[[Double]]] = []
            for feature in features {
                guard let geom = feature["geometry"] as? [String: Any],
                      let type = geom["type"] as? String else { continue }
                
                if type == "Polygon", let rings = geom["coordinates"] as? [[[Double]]] {
                    polylines.append(contentsOf: rings)
                } else if type == "MultiPolygon", let polygons = geom["coordinates"] as? [[[[Double]]]] {
                    for rings in polygons {
                        polylines.append(contentsOf: rings)
                    }
                }
            }

            // 4. Render to UIImage
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: W, height: H))
            let texture = renderer.image { ctx in
                let cg = ctx.cgContext
                // Background
                bg.setFill()
                cg.fill(CGRect(x: 0, y: 0, width: W, height: H))
                // Lines
                fg.setStroke()
                cg.setLineWidth(1.0)
                cg.setLineCap(.round)
                cg.setLineJoin(.round)

                for polyline in polylines {
                    guard let first = polyline.first, first.count >= 2 else { continue }
                    let startX = (first[0] + 180.0) / 360.0 * W
                    let startY = (90.0 - first[1]) / 180.0 * H
                    cg.move(to: CGPoint(x: startX, y: startY))
                    for pt in polyline.dropFirst() {
                        guard pt.count >= 2 else { continue }
                        let x = (pt[0] + 180.0) / 360.0 * W
                        let y = (90.0 - pt[1]) / 180.0 * H
                        cg.addLine(to: CGPoint(x: x, y: y))
                    }
                    cg.strokePath()
                }
            }

            DispatchQueue.main.async {
                material.diffuse.contents = texture
            }
        }.resume()
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false // We use custom pan gesture for inertia
        scnView.autoenablesDefaultLighting = true
        
        let scene = SCNScene()
        scnView.scene = scene
        
        // 1. Create the Globe (Sphere)
        let globeGeometry = SCNSphere(radius: 10)
        globeGeometry.segmentCount = 64
        
        let globeMaterial = SCNMaterial()
        GlobeSceneView.applyGlobeTexture(to: globeMaterial)
        globeMaterial.lightingModel = .lambert
        globeMaterial.isDoubleSided = false
        
        globeGeometry.materials = [globeMaterial]
        
        let globeNode = SCNNode(geometry: globeGeometry)
        globeNode.name = "globe"
        scene.rootNode.addChildNode(globeNode)
        
        // 2. Camera setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 26) // Step back to see the whole globe
        scene.rootNode.addChildNode(cameraNode)
        
        context.coordinator.globeNode = globeNode
        context.coordinator.scnView = scnView
        
        // 3. Setup Gestures
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        // When visited countries change, we trigger a texture update in the coordinator
        context.coordinator.updateGlobeTexture(visitedCountries: visitedCountries)
        
        // Update user location dot
        context.coordinator.updateUserLocation(userLocation)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(visitedCountries: $visitedCountries)
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject {
        @Binding var visitedCountries: Set<String>
        
        weak var globeNode: SCNNode?
        weak var scnView: SCNView?
        
        // Pan and Inertia state
        private var previousPanPoint: CGPoint = .zero
        private var displayLink: CADisplayLink?
        private var velocity: CGPoint = .zero
        
        // Track absolute angles to avoid gimbal lock
        private var angleX: Float = 0 // Rotation around Y axis (longitude)
        private var angleY: Float = 0 // Rotation around X axis (latitude)
        
        // User location
        private var userLocationNode: SCNNode?
        
        // Texture caching
        private var cachedHitMap: UIImage?
        private var cachedVisualMap: UIImage?
        
        init(visitedCountries: Binding<Set<String>>) {
            self._visitedCountries = visitedCountries
            super.init()
            self.cachedHitMap = UIImage(named: "world_hitmap")
            self.cachedVisualMap = UIImage(named: "world_visual")
        }
        
        // MARK: - Pan / Rotation
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let currentPoint = gesture.translation(in: view)
            
            switch gesture.state {
            case .began:
                previousPanPoint = currentPoint
                displayLink?.invalidate()
                
            case .changed:
                let delta = CGPoint(x: currentPoint.x - previousPanPoint.x, y: currentPoint.y - previousPanPoint.y)
                rotateGlobe(dx: delta.x, dy: delta.y)
                previousPanPoint = currentPoint
                velocity = gesture.velocity(in: view)
                
            case .ended, .cancelled:
                startInertia()
                
            default:
                break
            }
        }
        
        private func rotateGlobe(dx: CGFloat, dy: CGFloat) {
            guard let node = globeNode else { return }
            let rotationScale: Float = 0.005
            
            angleX += Float(dx) * rotationScale
            angleY += Float(dy) * rotationScale
            
            // Clamp latitude to prevent flipping upside down
            angleY = max(-.pi/2, min(.pi/2, angleY))
            
            // Apply Euler angles (X first, then Y)
            node.eulerAngles = SCNVector3(angleY, angleX, 0)
        }
        
        private func startInertia() {
            displayLink = CADisplayLink(target: self, selector: #selector(updateInertia))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        @objc private func updateInertia() {
            // Friction
            velocity.x *= 0.95
            velocity.y *= 0.95
            
            rotateGlobe(dx: velocity.x * 0.016, dy: velocity.y * 0.016)
            
            if abs(velocity.x) < 1 && abs(velocity.y) < 1 {
                displayLink?.invalidate()
            }
        }
        
        // MARK: - Tap / Hit Testing
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView, let hitMap = cachedHitMap else { return }
            
            let location = gesture.location(in: scnView)
            
            // Perform hit test on the globe sphere
            let hits = scnView.hitTest(location, options: [.boundingBoxOnly: false])
            
            if let firstHit = hits.first(where: { $0.node.name == "globe" }) {
                let texCoords = firstHit.textureCoordinates(withMappingChannel: 0)
                
                // Read the pixel color from the hitmap at the tapped UV coordinates
                if let hexColor = colorHexAt(uv: texCoords, in: hitMap) {
                    
                    // We use the hex string (e.g. "FF0000") directly as the country ID.
                    // In a full app, you'd have a dictionary mapping hex to ISO code:
                    // let isoCode = hexToIsoMapping[hexColor] ?? hexColor
                    let countryId = hexColor
                    
                    // Ignore empty sea (assuming sea is pure white or black on the hitmap)
                    if countryId == "000000" || countryId == "FFFFFF" { return }
                    
                    // Toggle visited state
                    if visitedCountries.contains(countryId) {
                        visitedCountries.remove(countryId)
                    } else {
                        visitedCountries.insert(countryId)
                    }
                }
            }
        }
        
        private func colorHexAt(uv: CGPoint, in image: UIImage) -> String? {
            guard let cgImage = image.cgImage else { return nil }
            
            let width = cgImage.width
            let height = cgImage.height
            
            let x = Int(uv.x * CGFloat(width))
            // SceneKit UV origin is bottom-left, CGImage origin is top-left
            let y = Int((1.0 - uv.y) * CGFloat(height))
            
            guard x >= 0 && x < width && y >= 0 && y < height else { return nil }
            
            // Read exactly 1 pixel
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var pixel: [UInt8] = [0, 0, 0, 0] // R, G, B, A
            guard let context = CGContext(
                data: &pixel,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }
            
            context.draw(cgImage, in: CGRect(x: -x, y: -y, width: width, height: height))
            
            return String(format: "%02X%02X%02X", pixel[0], pixel[1], pixel[2]) // Return Hex RGB
        }
        
        // MARK: - Dynamic Texture Generation
        
        func updateGlobeTexture(visitedCountries: Set<String>) {
            // Placeholder for texture updates
            print("Globe texture needs update. Visited countries: \(visitedCountries)")
        }
        
        func updateUserLocation(_ location: CLLocationCoordinate2D?) {
            guard let location = location, let globeNode = globeNode else {
                userLocationNode?.removeFromParentNode()
                userLocationNode = nil
                return
            }
            
            let radius: Float = 10.0 // Match SCNSphere radius
            
            let lat = Float(location.latitude) * .pi / 180.0
            let lon = Float(location.longitude) * .pi / 180.0
            
            let x = radius * cos(lat) * sin(lon)
            let y = radius * sin(lat)
            let z = radius * cos(lat) * cos(lon)
            let position = SCNVector3(x, y, z)
            
            if let existingNode = userLocationNode {
                let move = SCNAction.move(to: position, duration: 1.0)
                existingNode.runAction(move)
            } else {
                let dotGeometry = SCNSphere(radius: 0.15)
                let dotMaterial = SCNMaterial()
                dotMaterial.diffuse.contents = UIColor.systemBlue
                dotMaterial.emission.contents = UIColor.systemBlue
                dotGeometry.materials = [dotMaterial]
                
                let dotNode = SCNNode(geometry: dotGeometry)
                dotNode.position = position
                globeNode.addChildNode(dotNode)
                userLocationNode = dotNode
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GlobeTab()
}
