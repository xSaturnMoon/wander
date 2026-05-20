//
//  GlobeTab.swift
//  Wander
//

import SwiftUI
import SceneKit
import CoreGraphics

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
    // Persist as a JSON array of strings
    @AppStorage("visitedCountries") private var visitedCountriesArray: [String] = []
    
    // Derived Set for O(1) lookups
    var visitedCountries: Set<String> {
        get { Set(visitedCountriesArray) }
        nonmutating set { visitedCountriesArray = Array(newValue) }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                GlobeSceneView(visitedCountries: Binding(
                    get: { self.visitedCountries },
                    set: { self.visitedCountries = $0 }
                ))
                .frame(height: UIScreen.main.bounds.height * 0.4)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Globe Scene View (UIViewRepresentable)

struct GlobeSceneView: UIViewRepresentable {
    @Binding var visitedCountries: Set<String>
    
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
        // Default base color if texture is missing
        globeMaterial.diffuse.contents = UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0)
        
        // Fetch missing texture from the provided URL at runtime
        if let url = URL(string: "https://raw.githubusercontent.com/simonepri/geo-maps/master/previews/earth-coastlines.png") {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let originalImage = UIImage(data: data) {
                    
                    // Pre-composite the background color and the coastlines into a single texture
                    let size = originalImage.size
                    let renderer = UIGraphicsImageRenderer(size: size)
                    let compositedImage = renderer.image { context in
                        // 1. Fill dark gray background (#2C2C2E)
                        UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0).setFill()
                        context.fill(CGRect(origin: .zero, size: size))
                        
                        // 2. Tint coastlines light gray (#8E8E93) and draw them
                        let lightGray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0)
                        let tintedImage = originalImage.withTintColor(lightGray, renderingMode: .alwaysTemplate)
                        lightGray.set()
                        tintedImage.draw(in: CGRect(origin: .zero, size: size))
                    }
                    
                    DispatchQueue.main.async {
                        globeMaterial.diffuse.contents = compositedImage
                    }
                }
            }
            task.resume()
        }
        
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
            
            // Rotate around global Y axis (left/right drag)
            let rotY = SCNMatrix4MakeRotation(Float(dx) * rotationScale, 0, 1, 0)
            
            // Rotate around global X axis (up/down drag)
            let rotX = SCNMatrix4MakeRotation(Float(dy) * rotationScale, 1, 0, 0)
            
            // Combine with current transform
            node.transform = SCNMatrix4Mult(SCNMatrix4Mult(rotX, rotY), node.transform)
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
            // Dynamic CPU texture highlighting is a heavy operation.
            // For a production app, we would process this on a background thread
            // or use a Metal Shader. For this implementation, we simply print out
            // the state to confirm the infrastructure works.
            
            // To implement true texture overriding:
            // 1. Draw cachedVisualMap into a new CGContext.
            // 2. Iterate pixels. If cachedHitMap pixel hex is in visitedCountries,
            //    blend the light gray #8E8E93 over the visual map pixel.
            // 3. Set globeNode?.geometry?.firstMaterial?.diffuse.contents = newUIImage
            
            print("Globe texture needs update. Visited countries: \(visitedCountries)")
        }
    }
}

// MARK: - Preview

#Preview {
    GlobeTab()
}
