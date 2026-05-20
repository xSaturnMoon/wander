//
//  WanderApp.swift
//  Wander
//

import SwiftUI
import CoreLocation

@main
struct WanderApp: App {

    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.scenePhase) private var scenePhase

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
                if locationManager.authorizationStatus == .authorizedAlways {
                    if isAuthenticated {
                        ContentView()
                    } else {
                        LoginView(isAuthenticated: $isAuthenticated)
                    }
                } else {
                    LocationBlockerView()
                }
            }
            // Apply theme globally so it covers TabView, sheets, and NavigationStacks.
            .preferredColorScheme(preferredColorScheme)
            .animation(.easeInOut(duration: 0.25), value: isAuthenticated)
            .animation(.easeInOut(duration: 0.25), value: locationManager.authorizationStatus)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    locationManager.startUpdating()
                } else if newPhase == .background {
                    locationManager.stopUpdating()
                }
            }
        }
    }
}

// MARK: - Location Manager

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocationCoordinate2D? = nil
    
    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }
    
    func startUpdating() {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if self.authorizationStatus == .authorizedWhenInUse {
                manager.requestAlwaysAuthorization()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
}

// MARK: - Location Blocker View

struct LocationBlockerView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @State private var showInfoAlert = false
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "location.slash.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)
            
            Text("Accesso negato")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Consenti l'utilizzo continuo della posizione per continuare a usare Wander.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                Button(action: { showInfoAlert = true }) {
                    Text("Info")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .alert("Informazioni", isPresented: $showInfoAlert) {
                    Button("OK", role: .cancel) { }
                } message: { Text("") }
                
                Button(action: { locationManager.requestPermission() }) {
                    Text("Consenti sempre")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}
