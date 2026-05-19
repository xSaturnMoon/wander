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

// MARK: - Focus Field

private enum Field: Hashable {
    case email, password, confirmPassword
}

// MARK: - Login View

struct LoginView: View {

    @Binding var isAuthenticated: Bool

    @State private var authMode:        AuthMode = .login
    @State private var email:           String   = ""
    @State private var password:        String   = ""
    @State private var confirmPassword: String   = ""

    @FocusState private var focusedField: Field?

    // MARK: Body

    var body: some View {
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
        // Keyboard interaction
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // Done button above keyboard
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
        .animation(.spring(duration: 0.3), value: authMode)
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(spacing: 10) {
                // Rounded-square icon — like an iOS home screen app icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.blue.opacity(0.12))
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
        }
        .listRowBackground(Color(.systemGroupedBackground))
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
        }
        .listRowBackground(Color(.systemGroupedBackground))
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
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

            SecureField("Password", text: $password)
                .textContentType(authMode == .login ? .password : .newPassword)
                .focused($focusedField, equals: .password)
                .submitLabel(authMode == .login ? .done : .next)
                .onSubmit {
                    if authMode == .login { focusedField = nil }
                    else { focusedField = .confirmPassword }
                }

            if authMode == .register {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
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
        }
        .listRowBackground(Color.clear)
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
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - Auth Handler

    private func handleAuth() {
        focusedField = nil

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
