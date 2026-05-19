//
//  LoginView.swift
//  Wander
//

import SwiftUI

// MARK: - Auth Mode

enum AuthMode: String, CaseIterable {
    case login    = "Login"
    case register = "Register"
}

// MARK: - Login View

struct LoginView: View {

    @Binding var isAuthenticated: Bool

    @State private var authMode: AuthMode     = .login
    @State private var email: String          = ""
    @State private var password: String       = ""
    @State private var confirmPassword: String = ""

    // Globe animation state
    @State private var globeScale: CGFloat    = 1.0
    @State private var globeRotation: Double  = 0.0

    // MARK: Body

    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
        }
        .colorScheme(.dark)
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: startGlobeAnimation)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Ambient glow – top left
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.18, blue: 0.90).opacity(0.55),
                            Color(red: 0.18, green: 0.38, blue: 0.95).opacity(0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -100, y: -240)
                .ignoresSafeArea()

            // Ambient glow – bottom right
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.55, blue: 0.90).opacity(0.35),
                            Color(red: 0.40, green: 0.18, blue: 0.85).opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: 120, y: 260)
                .ignoresSafeArea()

            // Subtle material veil
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.25)
                .ignoresSafeArea()
        }
    }

    // MARK: - Content

    private var contentLayer: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 36) {

                Spacer(minLength: 70)

                heroSection
                authCard

                Spacer(minLength: 48)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 0.55, green: 0.75, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(globeScale)
                .rotationEffect(.degrees(globeRotation))
                .shadow(color: Color.blue.opacity(0.45), radius: 24, x: 0, y: 8)

            Text("Wander")
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .tracking(1.5)

            Text("Explore the world, trace your path")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.50))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Auth Card

    private var authCard: some View {
        VStack(spacing: 22) {
            // Login / Register toggle
            Picker("Auth Mode", selection: $authMode) {
                ForEach(AuthMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: authMode) {
                withAnimation(.spring(duration: 0.35)) { }
            }

            // Input fields
            VStack(spacing: 14) {
                inputField(
                    label: "Email",
                    icon: "envelope",
                    placeholder: "you@example.com",
                    text: $email,
                    isSecure: false
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)

                inputField(
                    label: "Password",
                    icon: "lock",
                    placeholder: "••••••••",
                    text: $password,
                    isSecure: true
                )

                if authMode == .register {
                    inputField(
                        label: "Confirm Password",
                        icon: "lock.badge.checkmark",
                        placeholder: "••••••••",
                        text: $confirmPassword,
                        isSecure: true
                    )
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal:   .push(from: .bottom).combined(with: .opacity)
                        )
                    )
                }
            }
            .animation(.spring(duration: 0.38), value: authMode)

            // Continue button
            continueButton

            // Forgot password link
            if authMode == .login {
                Button("Forgot password?") {
                    // TODO: connect to Firebase — Auth.auth().sendPasswordReset(withEmail: email)
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.50))
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 12)
        .padding(.horizontal, 24)
        .animation(.spring(duration: 0.35), value: authMode)
    }

    // MARK: - Input Field Builder

    @ViewBuilder
    private func inputField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.58))

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .textFieldStyle(.plain)
            .foregroundStyle(.white)
            .tint(Color(red: 0.55, green: 0.65, blue: 1.0))
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.13), lineWidth: 1)
            )
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            handleAuth()
        } label: {
            Text("Continue")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.42, green: 0.20, blue: 0.92),
                            Color(red: 0.20, green: 0.48, blue: 1.00)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(red: 0.35, green: 0.25, blue: 0.90).opacity(0.55), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(1)
        .animation(.spring(duration: 0.2), value: authMode)
    }

    // MARK: - Globe Animation

    private func startGlobeAnimation() {
        // Pulse
        withAnimation(
            .easeInOut(duration: 2.4)
            .repeatForever(autoreverses: true)
        ) {
            globeScale = 1.07
        }

        // Slow rotation
        withAnimation(
            .linear(duration: 22)
            .repeatForever(autoreverses: false)
        ) {
            globeRotation = 360
        }
    }

    // MARK: - Auth Handler

    private func handleAuth() {
        switch authMode {
        case .login:
            // TODO: connect to Firebase
            // Auth.auth().signIn(withEmail: email, password: password) { result, error in … }
            isAuthenticated = true

        case .register:
            // TODO: connect to Firebase
            // Auth.auth().createUser(withEmail: email, password: password) { result, error in … }
            guard password == confirmPassword else { return }
            isAuthenticated = true
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView(isAuthenticated: .constant(false))
}
