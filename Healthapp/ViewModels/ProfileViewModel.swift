//
//  ProfileViewModel.swift
//  Health App
//
//  ViewModel for managing user profile state and operations
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for profile setup and editing
@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var weight: String = ""
    @Published var height: String = ""
    @Published var age: String = ""
    @Published var gender: Gender = .male
    @Published var activityLevel: ActivityLevel = .sedentary
    
    @Published var useMetric: Bool = true // true = kg/cm, false = lbs/inches
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Calculated values
    @Published var calculatedBMR: Double?
    @Published var calculatedTDEE: Double?
    
    private let profileService = ProfileService()
    private let appState: AppState
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        self.appState = appState
        loadCurrentProfile()
        setupCalculations()
    }
    
    // MARK: - Profile Loading
    
    /// Load current user profile into form fields
    func loadCurrentProfile() {
        guard let user = appState.currentUser else { return }
        
        // Load values
        if let userWeight = user.weight {
            weight = String(format: "%.1f", userWeight)
        }
        
        if let userHeight = user.height {
            height = String(format: "%.0f", userHeight)
        }
        
        if let userAge = user.age {
            age = "\(userAge)"
        }
        
        gender = user.gender ?? .male
        activityLevel = user.activityLevel ?? .sedentary
        
        // Calculate initial BMR/TDEE
        updateCalculations()
    }
    
    // MARK: - Calculations
    
    /// Set up real-time calculations when inputs change
    private func setupCalculations() {
        Publishers.CombineLatest4($weight, $height, $age, $gender)
            .combineLatest($activityLevel)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateCalculations()
            }
            .store(in: &cancellables)
    }
    
    /// Update BMR and TDEE calculations
    private func updateCalculations() {
        guard let weightValue = weightInKg,
              let heightValue = heightInCm,
              let ageValue = Int(age),
              !age.isEmpty else {
            calculatedBMR = nil
            calculatedTDEE = nil
            return
        }
        
        calculatedBMR = profileService.calculateBMR(
            weight: weightValue,
            height: heightValue,
            age: ageValue,
            gender: gender
        )
        
        if let bmr = calculatedBMR {
            calculatedTDEE = profileService.calculateTDEE(
                bmr: bmr,
                activityLevel: activityLevel
            )
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Unit Conversions
    
    /// Get weight in kg (converts if needed)
    var weightInKg: Double? {
        guard let value = Double(weight), value > 0 else { return nil }
        return useMetric ? value : value * 0.453592 // lbs to kg
    }
    
    /// Get height in cm (converts if needed)
    var heightInCm: Double? {
        guard let value = Double(height), value > 0 else { return nil }
        return useMetric ? value : value * 2.54 // inches to cm
    }
    
    /// Convert kg to lbs
    func kgToLbs(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    /// Convert cm to inches
    func cmToInches(_ cm: Double) -> Double {
        return cm / 2.54
    }
    
    /// Toggle between metric and imperial units
    func toggleUnits() {
        useMetric.toggle()
        
        // Convert current values
        if let weightValue = Double(weight) {
            if useMetric {
                // Was lbs, convert to kg
                weight = String(format: "%.1f", weightValue * 0.453592)
            } else {
                // Was kg, convert to lbs
                weight = String(format: "%.1f", weightValue * 2.20462)
            }
        }
        
        if let heightValue = Double(height) {
            if useMetric {
                // Was inches, convert to cm
                height = String(format: "%.0f", heightValue * 2.54)
            } else {
                // Was cm, convert to inches
                height = String(format: "%.0f", heightValue / 2.54)
            }
        }
        
        updateCalculations()
    }
    
    // MARK: - Profile Operations
    
    /// Create a new user profile (for first-time setup)
    func createProfile() async {
        guard validateInputs() else { return }
        
        guard let userId = appState.currentUser?.id,
              let weightValue = weightInKg,
              let heightValue = heightInCm,
              let ageValue = Int(age) else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await profileService.createProfile(
                userId: userId,
                weight: weightValue,
                height: heightValue,
                age: ageValue,
                gender: gender,
                activityLevel: activityLevel
            )
            
            // Update app state with new profile
            var updatedUser = user
            updatedUser.email = appState.currentUser?.email
            
            // Debug logging
            print("✅ Profile created in ViewModel")
            print("📊 Profile data:")
            print("   - Weight: \(updatedUser.weight?.description ?? "nil")")
            print("   - Height: \(updatedUser.height?.description ?? "nil")")
            print("   - Age: \(updatedUser.age?.description ?? "nil")")
            print("   - Gender: \(updatedUser.gender?.rawValue ?? "nil")")
            print("   - Activity Level: \(updatedUser.activityLevel?.rawValue ?? "nil")")
            print("   - BMR: \(updatedUser.bmr?.description ?? "nil")")
            print("   - TDEE: \(updatedUser.tdee?.description ?? "nil")")
            print("✅ User has complete profile: \(updatedUser.hasCompleteProfile)")
            
            await appState.setUser(updatedUser)
            successMessage = "Profile created successfully!"
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to create profile: \(error)")
        }
        
        isLoading = false
    }
    
    /// Update existing user profile
    func updateProfile() async {
        guard validateInputs() else { return }
        
        guard let userId = appState.currentUser?.id else {
            errorMessage = "User not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Prepare update parameters
            let weightValue = weightInKg
            let heightValue = heightInCm
            let ageValue = Int(age)
            
            let user = try await profileService.updateProfile(
                userId: userId,
                weight: weightValue,
                height: heightValue,
                age: ageValue,
                gender: gender,
                activityLevel: activityLevel
            )
            
            // Update app state with updated profile
            var updatedUser = user
            updatedUser.email = appState.currentUser?.email
            await appState.setUser(updatedUser)
            
            successMessage = "Profile updated successfully!"
            print("✅ Profile updated in ViewModel")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to update profile: \(error)")
        }
        
        isLoading = false
    }
    
    /// Quick weight update (for daily logging)
    func updateWeight() async {
        guard let userId = appState.currentUser?.id,
              let weightValue = weightInKg else {
            errorMessage = "Please enter a valid weight"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await profileService.updateWeight(userId: userId, weight: weightValue)
            
            // Update app state
            var updatedUser = user
            updatedUser.email = appState.currentUser?.email
            await appState.setUser(updatedUser)
            
            successMessage = "Weight updated successfully!"
            print("✅ Weight updated in ViewModel")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to update weight: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Validation
    
    /// Validate form inputs
    private func validateInputs() -> Bool {
        errorMessage = nil
        
        // Weight validation
        if weight.isEmpty {
            errorMessage = "Please enter your weight"
            return false
        }
        
        guard let weightValue = weightInKg, weightValue > 0, weightValue < 500 else {
            errorMessage = "Please enter a valid weight (0-500 kg / 0-1100 lbs)"
            return false
        }
        
        // Height validation
        if height.isEmpty {
            errorMessage = "Please enter your height"
            return false
        }
        
        guard let heightValue = heightInCm, heightValue > 0, heightValue < 300 else {
            errorMessage = "Please enter a valid height (0-300 cm / 0-120 inches)"
            return false
        }
        
        // Age validation
        if age.isEmpty {
            errorMessage = "Please enter your age"
            return false
        }
        
        guard let ageValue = Int(age), ageValue > 0, ageValue < 150 else {
            errorMessage = "Please enter a valid age (1-150)"
            return false
        }
        
        return true
    }
    
    /// Check if profile has all required fields
    var isProfileComplete: Bool {
        return !weight.isEmpty &&
               !height.isEmpty &&
               !age.isEmpty &&
               weightInKg != nil &&
               heightInCm != nil &&
               Int(age) != nil
    }
    
    // MARK: - Helper Methods
    
    /// Clear all form fields
    func clearForm() {
        weight = ""
        height = ""
        age = ""
        gender = .male
        activityLevel = .sedentary
        calculatedBMR = nil
        calculatedTDEE = nil
        errorMessage = nil
        successMessage = nil
    }
    
    /// Clear messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

