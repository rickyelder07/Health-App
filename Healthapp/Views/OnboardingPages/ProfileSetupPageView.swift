//
//  ProfileSetupPageView.swift
//  Netfuel
//
//  Profile setup page for onboarding
//

import SwiftUI

struct ProfileSetupPageView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case weight, height, age
    }

    init(onboardingViewModel: OnboardingViewModel, appState: AppState) {
        self.onboardingViewModel = onboardingViewModel
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(appState: appState))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)

                    Text("Set Up Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Help us calculate your daily calorie needs")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal)

                // Physical Stats Form
                VStack(spacing: 16) {
                    // Unit Toggle
                    unitToggleSection

                    // Weight Input
                    weightInputSection

                    // Height Input
                    heightInputSection

                    // Age Input
                    ageInputSection

                    // Gender Picker
                    genderPickerSection

                    // Activity Level Picker
                    activityLevelSection
                }
                .padding(.horizontal)

                // Calculated Values
                if let bmr = profileViewModel.calculatedBMR, let tdee = profileViewModel.calculatedTDEE {
                    calculatedValuesSection(bmr: bmr, tdee: tdee)
                }

                // Error or Warning Messages
                if let errorMessage = profileViewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Validation hint
                if !profileViewModel.isProfileComplete {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Please fill in all fields to continue")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            // Check if form is already complete on load
            if profileViewModel.isProfileComplete {
                onboardingViewModel.completeProfileSetup()
            }
        }
        .onChange(of: profileViewModel.isProfileComplete) { isComplete in
            print("📱 Profile completion status changed to: \(isComplete)")
            // Update onboarding status immediately when form becomes valid
            if isComplete {
                onboardingViewModel.completeProfileSetup()
                // Save profile in background
                Task {
                    await saveProfile()
                }
            } else {
                // Reset if form becomes invalid
                onboardingViewModel.isProfileSetupComplete = false
            }
        }
    }

    // MARK: - Save Profile

    private func saveProfile() async {
        await profileViewModel.createProfile()
        if let tdee = profileViewModel.calculatedTDEE {
            onboardingViewModel.userTDEE = Int(tdee)
        }
    }

    // MARK: - View Components

    private var unitToggleSection: some View {
        HStack {
            Text("Units")
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Button {
                profileViewModel.toggleUnits()
            } label: {
                HStack(spacing: 8) {
                    Text(profileViewModel.useMetric ? "Metric" : "Imperial")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private var weightInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack {
                TextField("0.0", text: $profileViewModel.weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold))
                    .focused($focusedField, equals: .weight)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .height }

                Text(profileViewModel.useMetric ? "kg" : "lbs")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private var heightInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Height")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack {
                TextField("0", text: $profileViewModel.height)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold))
                    .focused($focusedField, equals: .height)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .age }

                Text(profileViewModel.useMetric ? "cm" : "in")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private var ageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack {
                TextField("0", text: $profileViewModel.age)
                    .keyboardType(.numberPad)
                    .font(.system(size: 32, weight: .semibold))
                    .focused($focusedField, equals: .age)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }

                Text("years")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private var genderPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Picker("Gender", selection: $profileViewModel.gender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.displayName).tag(gender)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private var activityLevelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Level")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Button {
                        profileViewModel.activityLevel = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            if profileViewModel.activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(profileViewModel.activityLevel == level ? Color.blue.opacity(0.05) : Color.clear)
                    }

                    if level != ActivityLevel.allCases.last {
                        Divider()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private func calculatedValuesSection(bmr: Double, tdee: Double) -> some View {
        VStack(spacing: 16) {
            Text("Your Daily Calorie Needs")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                // BMR
                VStack(spacing: 8) {
                    Text("BMR")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("\(Int(bmr))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.blue.gradient)

                    Text("Base Calories")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // TDEE
                VStack(spacing: 8) {
                    Text("TDEE")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("\(Int(tdee))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.green.gradient)

                    Text("Total Calories")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    ProfileSetupPageView(
        onboardingViewModel: OnboardingViewModel(),
        appState: AppState()
    )
    .environmentObject(AppState())
}
