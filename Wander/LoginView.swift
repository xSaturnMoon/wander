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
    case firstName, lastName, email, password, confirmPassword
}

// MARK: - Login View

struct LoginView: View {

    @Binding var isAuthenticated: Bool

    @AppStorage("userEmail")     private var userEmail: String = ""
    @AppStorage("userFirstName") private var userFirstName: String = ""
    @AppStorage("userLastName")  private var userLastName: String = ""

    @State private var authMode:        AuthMode = .login
    @State private var firstName:       String   = ""
    @State private var lastName:        String   = ""
    @State private var email:           String   = ""
    @State private var password:        String   = ""
    @State private var confirmPassword: String   = ""

    @FocusState private var focusedField: Field?

    // MARK: Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 28) {
                    headerView
                    pickerView
                    credentialsSection
                    continueButton
                    if authMode == .login { forgotButton }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 48)
            }
            // Natural keyboard avoidance — system shrinks the scroll view,
            // then scrollTo() brings the focused field into view.
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onChange(of: focusedField) { _, newField in
                guard let newField else { return }
                withAnimation(.spring(duration: 0.4)) {
                    proxy.scrollTo(newField, anchor: .center)
                }
            }
        }
        .animation(.spring(duration: 0.3), value: authMode)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 10) {
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
        .padding(.vertical, 8)
    }

    // MARK: - Picker

    private var pickerView: some View {
        Picker("Auth Mode", selection: $authMode) {
            ForEach(AuthMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Credentials Section
    //
    // AutoFill contract:
    //  • .username     — tells iOS this is the account identifier; Keychain pairs it
    //                    with the adjacent password field so FaceID/TouchID autofill works.
    //  • .password     — (Login) triggers QuickType bar with saved credentials.
    //  • .newPassword  — (Register) triggers iOS strong-password generator and
    //                    offers to save to iCloud Keychain after successful sign-up.
    //
    // Each row also gets its own .id() so ScrollViewReader can scroll
    // precisely to whichever field is focused.


    private var credentialsSection: some View {
        VStack(spacing: 0) {

            // First Name & Last Name — Register only
            if authMode == .register {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .lastName }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .id(Field.firstName)
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal:   .push(from: .bottom).combined(with: .opacity)
                        )
                    )

                Divider().padding(.leading, 16)

                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .id(Field.lastName)
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal:   .push(from: .bottom).combined(with: .opacity)
                        )
                    )

                Divider().padding(.leading, 16)
            }

            // Email row
            // .username (not .emailAddress) is the correct type here:
            // iOS needs .username to link email+password as a Keychain credential pair.
            // .keyboardType(.emailAddress) still shows the email keyboard.
            TextField("Email", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .id(Field.email)

            Divider().padding(.leading, 16)

            // Password row
            // Login  → .password    : QuickType bar shows saved credentials + FaceID unlock
            // Register → .newPassword : iOS offers to generate + save a strong password
            //            textContentType(.newPassword) alone triggers the strong-password
            //            generator — no extra passwordRules API needed in SwiftUI.
            SecureField("Password", text: $password)
                .textContentType(authMode == .login ? .password : .newPassword)
                .focused($focusedField, equals: .password)
                .submitLabel(authMode == .login ? .done : .next)
                .onSubmit {
                    if authMode == .login { focusedField = nil }
                    else { focusedField = .confirmPassword }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .id(Field.password)

            // Confirm password row — Register only
            // Also .newPassword so iOS knows both fields belong to the same
            // new-account flow and won't try to autofill from Keychain here.
            if authMode == .register {
                Divider().padding(.leading, 16)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .id(Field.confirmPassword)
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal:   .push(from: .bottom).combined(with: .opacity)
                        )
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: handleAuth) {
            Text("Continue")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    // MARK: - Forgot Password

    private var forgotButton: some View {
        Button("Forgot password?") {
            // TODO: connect to Firebase — Auth.auth().sendPasswordReset(withEmail: email)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
    }

    // MARK: - Auth Handler

    private func handleAuth() {
        focusedField = nil

        switch authMode {
        case .login:
            // TODO: connect to Firebase
            // Auth.auth().signIn(withEmail: email, password: password) { result, error in
            //     if error == nil { userEmail = email; isAuthenticated = true }
            // }
            userEmail = email
            isAuthenticated = true

        case .register:
            // TODO: connect to Firebase
            // Auth.auth().createUser(withEmail: email, password: password) { result, error in
            //     if error == nil { userEmail = email; isAuthenticated = true }
            // }
            guard password == confirmPassword else { return }
            userEmail = email
            userFirstName = firstName
            userLastName = lastName
            isAuthenticated = true
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView(isAuthenticated: .constant(false))
}
