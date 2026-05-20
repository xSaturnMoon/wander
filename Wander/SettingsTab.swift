//
//  SettingsTab.swift
//  Wander
//

import SwiftUI

// MARK: - Settings Tab

struct SettingsTab: View {

    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("userEmail")       private var userEmail: String = ""
    @AppStorage("userFirstName")   private var userFirstName: String = ""
    @AppStorage("userLastName")    private var userLastName: String = ""
    @AppStorage("theme")           private var theme: String = "System"

    @State private var showChangeUserInfo = false
    @State private var showChangePassword = false
    @State private var showLogoutAlert    = false

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                accountSection
                appSection
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showChangeUserInfo) {
            ChangeUserInfoSheet()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) {
                // TODO: connect to Firebase — try? Auth.auth().signOut()
                isAuthenticated = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out of Wander?")
        }
    }

    // MARK: - Profile Section
    //
    // Displayed as a standard Form section so it gets the same rounded
    // background as all other sections.

    private var initials: String {
        let first = userFirstName.prefix(1).uppercased()
        let last = userLastName.prefix(1).uppercased()
        return first + last
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Avatar circle with initials
                ZStack {
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                    
                    Text(initials)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                // Name + email
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(userFirstName) \(userLastName)")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(userEmail.isEmpty ? "—" : userEmail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {

            // Change User Info
            Button {
                showChangeUserInfo = true
            } label: {
                HStack {
                    Text("Change User Info")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            // Change Password — sheet-based navigation, chevron added manually
            // (only NavigationLink renders chevrons automatically)
            Button {
                showChangePassword = true
            } label: {
                HStack {
                    Text("Change Password")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            // Logout — red, triggers confirmation alert
            Button("Log Out") {
                showLogoutAlert = true
            }
            .foregroundStyle(.red)
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        Section("App") {

            // App Icon — placeholder destination
            NavigationLink {
                Text("Coming soon")
                    .foregroundStyle(.secondary)
                    .navigationTitle("App Icon")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text("App Icon")
            }

            // Theme — persisted via @AppStorage, applied at root in WanderApp.
            // Default Form picker style shows current value on trailing side
            // and navigates to a pick list on tap — native iOS Settings behaviour.
            Picker("Theme", selection: $theme) {
                Text("System").tag("System")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }

            // App Version — read-only, no chevron, no tap target
            HStack {
                Text("App Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Change User Info Sheet

private struct ChangeUserInfoSheet: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("userFirstName") private var userFirstName: String = ""
    @AppStorage("userLastName")  private var userLastName: String = ""

    @State private var firstName: String = ""
    @State private var lastName:  String = ""

    @FocusState private var focusedField: Bool

    private var canSave: Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .focused($focusedField)
                        .submitLabel(.next)

                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .submitLabel(.done)
                        .onSubmit { if canSave { saveInfo() } }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Change User Info")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                firstName = userFirstName
                lastName = userLastName
                focusedField = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveInfo)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveInfo() {
        userFirstName = firstName
        userLastName = lastName
        dismiss()
    }
}

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var newPassword:     String = ""
    @State private var confirmPassword: String = ""

    @FocusState private var focusedField: Bool

    private var canSave: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField)
                        .submitLabel(.next)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .submitLabel(.done)
                        .onSubmit { if canSave { savePassword() } }
                } footer: {
                    Text("Minimum 12 characters including uppercase, lowercase, and a digit.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { focusedField = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: savePassword)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func savePassword() {
        // TODO: connect to Firebase
        // Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
        //     if let error { print(error.localizedDescription); return }
        //     dismiss()
        // }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    SettingsTab()
}
