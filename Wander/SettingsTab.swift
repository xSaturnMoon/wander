//
//  SettingsTab.swift
//  Wander
//

import SwiftUI

// MARK: - Settings Tab

struct SettingsTab: View {

    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("userEmail")       private var userEmail: String = ""
    @AppStorage("theme")           private var theme: String = "System"

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
    // Displayed as a Form section with transparent background so it
    // blends into the grouped background — mirrors the Apple ID header
    // at the top of iOS Settings.

    private var profileSection: some View {
        Section {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )

                    Text(userEmail.prefix(1).uppercased())
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Text(userEmail.isEmpty ? "—" : userEmail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .listRowBackground(Color(.systemGroupedBackground))
        .listRowSeparator(.hidden)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {

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
