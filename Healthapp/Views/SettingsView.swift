//
//  SettingsView.swift
//  Netfuel
//
//  Comprehensive settings screen
//

import SwiftUI

/// Main settings view
struct SettingsView: View {
    let userId: UUID
    @Environment(\.dismiss) var dismiss

    var body: some View {
        SettingsContentView(userId: userId)
    }
}

/// Content view with state management
private struct SettingsContentView: View {
    let userId: UUID
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingProfileEdit = false
    @State private var showingGoalsEdit = false
    @State private var showingUnitsEdit = false
    @State private var showingAccountActions = false
    @State private var showingExportSheet = false

    init(userId: UUID) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: SettingsViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section {
                    NavigationLink {
                        EditProfileSettingsView(viewModel: viewModel)
                    } label: {
                        SettingRow(
                            icon: "person.circle.fill",
                            iconColor: .blue,
                            title: "Edit Profile",
                            subtitle: profileSubtitle
                        )
                    }

                    if let user = viewModel.user {
                        HStack {
                            Text("BMR")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.calculatedBMR) cal/day")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("TDEE")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.calculatedTDEE) cal/day")
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("Profile")
                }

                // Units Section
                Section {
                    NavigationLink {
                        UnitsSettingsView(viewModel: viewModel)
                    } label: {
                        SettingRow(
                            icon: "ruler",
                            iconColor: .orange,
                            title: "Units & Preferences",
                            subtitle: unitsSubtitle
                        )
                    }
                } header: {
                    Text("Units")
                }

                // Integrations Section
                Section {
                    StravaIntegrationRow(userId: userId, viewModel: viewModel)
                } header: {
                    Text("Integrations")
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.primary)
                    }

                    Link(destination: URL(string: "https://rickhelder07.github.io/NetFuel/privacy-policy.html")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "mailto:ricky.elder07@gmail.com")!) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "envelope")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }

                // Account Section
                Section {
                    NavigationLink {
                        AccountSettingsView(viewModel: viewModel)
                    } label: {
                        SettingRow(
                            icon: "person.badge.key.fill",
                            iconColor: .purple,
                            title: "Account & Security",
                            subtitle: nil
                        )
                    }

                    Button {
                        showingExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Data")
                                .foregroundColor(.primary)
                        }
                    }

                    Button {
                        Task {
                            await viewModel.logOut()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Account")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingExportSheet) {
                DataExportSheet(csvData: viewModel.exportData())
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var profileSubtitle: String {
        guard let user = viewModel.user else { return "Loading..." }
        var parts: [String] = []
        if let weight = user.weight {
            parts.append(UnitFormatter.formatWeight(weight))
        }
        if let age = user.age {
            parts.append("\(age) years")
        }
        return parts.joined(separator: " • ")
    }

    private var unitsSubtitle: String {
        "\(viewModel.settings.weightUnit.abbreviation) • \(viewModel.settings.heightUnit.abbreviation) • \(viewModel.settings.distanceUnit.abbreviation)"
    }
}

// MARK: - Setting Row

private struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Strava Integration Row

private struct StravaIntegrationRow: View {
    let userId: UUID
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingDisconnectAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text("Strava")
                    .font(.headline)

                Spacer()

                if viewModel.stravaConnection != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            if let connection = viewModel.stravaConnection {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Connected as")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(connection.athleteFullName ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Last sync")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formattedLastSync)
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await viewModel.syncStravaActivities()
                            }
                        } label: {
                            HStack {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Sync Now")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isSaving)

                        Button {
                            showingDisconnectAlert = true
                        } label: {
                            Text("Disconnect")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text("Not connected")
                    .font(.caption)
                    .foregroundColor(.secondary)

                NavigationLink {
                    StravaConnectionView(userId: userId)
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect Strava")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Disconnect Strava?", isPresented: $showingDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                Task {
                    await viewModel.disconnectStrava()
                }
            }
        } message: {
            Text("Your activities will remain in the app, but new activities won't be synced.")
        }
    }
}

// MARK: - Data Export Sheet

private struct DataExportSheet: View {
    @Environment(\.dismiss) var dismiss
    let csvData: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Copy or share your complete health data export.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView {
                    Text(csvData)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
                .padding(.horizontal)

                Button {
                    UIPasteboard.general.string = csvData
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy to Clipboard")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                ShareLink(item: csvData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Data")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(userId: UUID())
}
