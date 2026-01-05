//
//  EditProfileSettingsView.swift
//  Netfuel
//
//  Edit profile settings view
//

import SwiftUI

/// Edit profile settings view
struct EditProfileSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender = .other
    @State private var selectedActivityLevel: ActivityLevel = .sedentary

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Weight")
                        .frame(width: 100, alignment: .leading)
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("kg")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Height")
                        .frame(width: 100, alignment: .leading)
                    TextField("Height", text: $height)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Age")
                        .frame(width: 100, alignment: .leading)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("years")
                        .foregroundColor(.secondary)
                }

                Picker("Gender", selection: $selectedGender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }

                Picker("Activity Level", selection: $selectedActivityLevel) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            } header: {
                Text("Physical Stats")
            } footer: {
                Text("This information is used to calculate your BMR and TDEE.")
                    .font(.caption)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // BMR
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("BMR (Basal Metabolic Rate)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(viewModel.calculatedBMR) cal/day")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        Text("Calories your body burns at rest to maintain vital functions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Divider()

                    // TDEE
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("TDEE (Total Daily Energy Expenditure)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(viewModel.calculatedTDEE) cal/day")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }

                        Text("Total calories burned including activity (BMR × \(activityMultiplierText))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Calculated Values")
            } footer: {
                Text("Use BMR for weight loss or TDEE to maintain current weight. Both are automatically calculated based on your stats.")
                    .font(.caption)
            }

            Section {
                Button {
                    saveProfile()
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.isSaving || !isValid)
            }
        }
        .navigationTitle("Edit Profile")
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
        guard let user = viewModel.user else { return }

        if let w = user.weight {
            weight = String(format: "%.1f", w)
        }
        if let h = user.height {
            height = String(format: "%.1f", h)
        }
        if let a = user.age {
            age = "\(a)"
        }
        if let g = user.gender {
            selectedGender = g
        }
        if let al = user.activityLevel {
            selectedActivityLevel = al
        }
    }

    private var isValid: Bool {
        !weight.isEmpty && !height.isEmpty && !age.isEmpty
    }

    private var activityMultiplierText: String {
        String(format: "%.2f", selectedActivityLevel.multiplier)
    }

    private func saveProfile() {
        guard let w = Double(weight),
              let h = Double(height),
              let a = Int(age) else { return }

        Task {
            await viewModel.updateProfile(
                weight: w,
                height: h,
                age: a,
                gender: selectedGender,
                activityLevel: selectedActivityLevel
            )
        }
    }
}
