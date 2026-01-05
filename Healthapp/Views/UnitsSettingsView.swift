//
//  UnitsSettingsView.swift
//  Netfuel
//
//  Units and preferences settings view
//

import SwiftUI

/// Units settings view
struct UnitsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedWeightUnit: UserSettings.WeightUnit = .kg
    @State private var selectedHeightUnit: UserSettings.HeightUnit = .cm
    @State private var selectedDistanceUnit: UserSettings.DistanceUnit = .km

    var body: some View {
        Form {
            // Weight Unit
            Section {
                Picker("Weight Unit", selection: $selectedWeightUnit) {
                    ForEach(UserSettings.WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.inline)

                if let weight = viewModel.user?.weight {
                    HStack {
                        Text("Example")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f %@",
                                  selectedWeightUnit.convert(fromKg: weight),
                                  selectedWeightUnit.abbreviation))
                            .fontWeight(.medium)
                    }
                }
            } header: {
                Text("Weight")
            } footer: {
                Text("Choose how weight is displayed throughout the app.")
            }

            // Height Unit
            Section {
                Picker("Height Unit", selection: $selectedHeightUnit) {
                    ForEach(UserSettings.HeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.inline)

                if let height = viewModel.user?.height {
                    HStack {
                        Text("Example")
                            .foregroundColor(.secondary)
                        Spacer()
                        let converted = selectedHeightUnit.convert(fromCm: height)
                        if selectedHeightUnit == .cm {
                            Text("\(converted.primary) cm")
                                .fontWeight(.medium)
                        } else {
                            Text("\(converted.primary)' \(converted.secondary ?? 0)\"")
                                .fontWeight(.medium)
                        }
                    }
                }
            } header: {
                Text("Height")
            } footer: {
                Text("Choose how height is displayed throughout the app.")
            }

            // Distance Unit
            Section {
                Picker("Distance Unit", selection: $selectedDistanceUnit) {
                    ForEach(UserSettings.DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.inline)

                HStack {
                    Text("Example")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f %@",
                              selectedDistanceUnit.convert(fromMeters: 5000),
                              selectedDistanceUnit.abbreviation))
                        .fontWeight(.medium)
                }
            } header: {
                Text("Distance")
            } footer: {
                Text("Choose how distance is displayed for activities.")
            }

            // Save Button
            Section {
                Button {
                    saveUnits()
                } label: {
                    Text("Save Preferences")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle("Units & Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentValues()
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

    private func loadCurrentValues() {
        selectedWeightUnit = viewModel.settings.weightUnit
        selectedHeightUnit = viewModel.settings.heightUnit
        selectedDistanceUnit = viewModel.settings.distanceUnit
    }

    private func saveUnits() {
        viewModel.settings.weightUnit = selectedWeightUnit
        viewModel.settings.heightUnit = selectedHeightUnit
        viewModel.settings.distanceUnit = selectedDistanceUnit

        viewModel.saveSettings()
    }
}
