//
//  User.swift
//  Netfuel
//
//  User profile model with physical stats and calorie calculations
//

import Foundation

/// User profile with physical stats and preferences
/// Extends auth.users with additional profile information
struct User: Codable, Identifiable {
    let id: UUID
    var email: String?
    var name: String? // User's first name

    // Physical stats
    var weight: Double? // in kg
    var height: Double? // in cm
    var age: Int?
    var gender: Gender?
    var activityLevel: ActivityLevel?
    
    // Calculated values (stored in DB but also computable)
    var bmr: Double?
    var tdee: Double?
    
    // Timestamps (optional for backward compatibility with existing rows)
    let createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case weight
        case height
        case age
        case gender
        case activityLevel = "activity_level"
        case bmr
        case tdee
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    
    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
    /// This matches the database function `calculate_bmr()`
    func calculateBMR() -> Double? {
        guard let weight = weight,
              let height = height,
              let age = age,
              let gender = gender else {
            return nil
        }
        
        let baseBMR = (10 * weight) + (6.25 * height) - (5 * Double(age))
        
        switch gender {
        case .male:
            return baseBMR + 5
        case .female:
            return baseBMR - 161
        case .other:
            return baseBMR - 78 // Average of male and female
        }
    }
    
    /// Calculate Total Daily Energy Expenditure
    /// This matches the database function `calculate_tdee()`
    func calculateTDEE() -> Double? {
        guard let calculatedBMR = calculateBMR(),
              let activityLevel = activityLevel else {
            return nil
        }
        
        return calculatedBMR * activityLevel.multiplier
    }
    
    /// Check if user has complete profile for BMR/TDEE calculation
    var hasCompleteProfile: Bool {
        return weight != nil && height != nil && age != nil && gender != nil && activityLevel != nil
    }
}

/// User gender options
enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case other
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

/// User activity level for TDEE calculation
enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case lightlyActive = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive = "very_active"
    case extraActive = "extra_active"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary (little or no exercise)"
        case .lightlyActive: return "Lightly Active (1-3 days/week)"
        case .moderatelyActive: return "Moderately Active (3-5 days/week)"
        case .veryActive: return "Very Active (6-7 days/week)"
        case .extraActive: return "Extra Active (physical job + exercise)"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extraActive: return 1.9
        }
    }
}

