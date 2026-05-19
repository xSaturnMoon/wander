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

    @State private var authMode:        AuthMode = .login
    @State private var email:           String   = ""
    @State private var password:        String   = ""
    @State private var confirmPassword: String   = ""

    // MARK: Body

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            List {
                headerSection
                pickerSection
                fieldsSection
                actionSection

                if authMode == .login {
                    forgotSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .colorScheme(.light)
        .ignoresSafeArea(.keyboard)
        .animation(.spring(duration: 0.3), value: authMode)
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(spacing: 10) {
                // App icon — rounded square, exactly like an iOS home screen icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.blue.opacity(0.10))
                        .frame(width: 76, height: 76)

                    Image(systemName: "globe")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.blue)
                }

                Text("Wander")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Explore the world, trace your path")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .listRowBackground(Color(UIColor.systemGroupedBackground))
        }
        .listRowSeparator(.hidden)
    }

    // MARK: - Picker

    private var pickerSection: some View {
        Section {
            Picker("Auth Mode", selection: $authMode) {
                ForEach(AuthMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color(UIColor.systemGroupedBackground))
        }
        .listRowSeparator(.hidden)
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        Section {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField("Password", text: $password)
                .textContentType(authMode == .login ? .password : .newPassword)

            if authMode == .register {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal:   .push(from: .bottom).combined(with: .opacity)
                        )
                    )
            }
        }
    }

    // MARK: - Continue Button

    private var actionSection: some View {
        Section {
            Button(action: handleAuth) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .listRowBackground(Color.clear)
        }
        .listRowSeparator(.hidden)
    }

    // MARK: - Forgot Password

    private var forgotSection: some View {
        Section {
            Button("Forgot password?") {
                // TODO: connect to Firebase — Auth.auth().sendPasswordReset(withEmail: email)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
        .listRowSeparator(.hidden)
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
