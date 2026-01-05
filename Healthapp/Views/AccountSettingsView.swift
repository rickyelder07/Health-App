//
//  AccountSettingsView.swift
//  Netfuel
//
//  Account and security settings view
//

import SwiftUI

/// Account settings view
struct AccountSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var showingPasswordChange = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationText = ""

    var body: some View {
        Form {
            // Change Password Section
            Section {
                Button {
                    showingPasswordChange = true
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                        Text("Change Password")
                            .foregroundColor(.primary)
                    }
                }
            } header: {
                Text("Security")
            }

            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Account")
                    }
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Deleting your account will permanently remove all your data. This action cannot be undone.")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Account & Security")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPasswordChange) {
            ChangePasswordSheet(viewModel: viewModel)
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            TextField("Type DELETE to confirm", text: $deleteConfirmationText)
            Button("Cancel", role: .cancel) {
                deleteConfirmationText = ""
            }
            Button("Delete Forever", role: .destructive) {
                deleteAccount()
            }
            .disabled(deleteConfirmationText != "DELETE")
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.\n\nType DELETE to confirm.")
        }
    }

    private func deleteAccount() {
        Task {
            do {
                try await viewModel.deleteAccount()
                // Account deleted, sign out handled in ViewModel
                appState.currentUser = nil
            } catch {
                // Error handled in ViewModel
            }
        }
    }
}

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case newPassword, confirmPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New Password", text: $newPassword)
                        .focused($focusedField, equals: .newPassword)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                } header: {
                    Text("New Password")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        PasswordRequirement(
                            met: newPassword.count >= 8,
                            text: "At least 8 characters"
                        )
                        PasswordRequirement(
                            met: passwordsMatch,
                            text: "Passwords match"
                        )
                    }
                }

                Section {
                    Button {
                        changePassword()
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Change Password")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || viewModel.isSaving)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                focusedField = .newPassword
            }
            .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.successMessage = nil
                    dismiss()
                }
            } message: {
                if let success = viewModel.successMessage {
                    Text(success)
                }
            }
        }
    }

    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    private var isValid: Bool {
        newPassword.count >= 8 && passwordsMatch
    }

    private func changePassword() {
        Task {
            await viewModel.changePassword(newPassword: newPassword)
        }
    }
}

// MARK: - Password Requirement

private struct PasswordRequirement: View {
    let met: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(met ? .green : .secondary)

            Text(text)
                .font(.caption)
                .foregroundColor(met ? .green : .secondary)
        }
    }
}

#Preview {
    AccountSettingsView(viewModel: SettingsViewModel(userId: UUID()))
        .environmentObject(AppState())
}
