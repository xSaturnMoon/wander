//
//  LocationBlockerView.swift
//  Wander
//

import SwiftUI

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
                Button(action: {
                    showInfoAlert = true
                }) {
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
                } message: {
                    // Empty for now, as requested
                    Text("")
                }
                
                Button(action: {
                    locationManager.requestPermission()
                }) {
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

#Preview {
    LocationBlockerView()
}
