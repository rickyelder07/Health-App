//
//  EditProfileView.swift
//  Health App
//
//  View for editing user profile and physical stats
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case weight, height, age
    }
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(appState: appState))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Unit Toggle
                unitToggleSection
                    .padding(.horizontal)
                    .padding(.top)
                
                // Physical Stats Form
                VStack(spacing: 16) {
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
                if let bmr = viewModel.calculatedBMR, let tdee = viewModel.calculatedTDEE {
                    calculatedValuesSection(bmr: bmr, tdee: tdee)
                        .padding(.horizontal)
                }
                
                // Error or Success Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    focusedField = nil
                    Task {
                        await viewModel.updateProfile()
                        if viewModel.successMessage != nil {
                            // Wait a moment to show success, then dismiss
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            dismiss()
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.isLoading || !viewModel.isProfileComplete)
            }
        }
        .onTapGesture {
            focusedField = nil
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
                viewModel.toggleUnits()
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.useMetric ? "Metric" : "Imperial")
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
                TextField("0.0", text: $viewModel.weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 28, weight: .semibold))
                    .focused($focusedField, equals: .weight)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .height }
                
                Text(viewModel.useMetric ? "kg" : "lbs")
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
                TextField("0", text: $viewModel.height)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 28, weight: .semibold))
                    .focused($focusedField, equals: .height)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .age }
                
                Text(viewModel.useMetric ? "cm" : "in")
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
                TextField("0", text: $viewModel.age)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .semibold))
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
            
            Picker("Gender", selection: $viewModel.gender) {
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
                        viewModel.activityLevel = level
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
                            
                            if viewModel.activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(viewModel.activityLevel == level ? Color.blue.opacity(0.05) : Color.clear)
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
            
            HStack(spacing: 16) {
                // BMR
                VStack(spacing: 8) {
                    Text("BMR")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(bmr))")
                        .font(.system(size: 28, weight: .bold))
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
                        .font(.system(size: 28, weight: .bold))
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
    }
}

#Preview {
    NavigationView {
        EditProfileView(appState: AppState())
            .environmentObject(AppState())
    }
}

