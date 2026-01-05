//
//  UserSettings.swift
//  Netfuel
//
//  User preferences and settings stored in UserDefaults
//

import Foundation

/// User preference settings
struct UserSettings: Codable {
    // MARK: - Goals

    /// Calorie goal source (BMR, TDEE, or Custom)
    var calorieGoalSource: CalorieGoalSource = .tdee

    /// Daily calorie target (only used when calorieGoalSource is .custom)
    var dailyCalorieTarget: Int?

    /// Protein target in grams
    var proteinTargetGrams: Double?

    /// Carbs target in grams
    var carbsTargetGrams: Double?

    /// Fat target in grams
    var fatTargetGrams: Double?

    /// Or use percentage-based targets
    var proteinTargetPercentage: Int? // 0-100
    var carbsTargetPercentage: Int? // 0-100
    var fatTargetPercentage: Int? // 0-100

    /// Weight goal in kg (optional)
    var weightGoal: Double?

    // MARK: - Units

    /// Weight unit preference
    var weightUnit: WeightUnit = .kg

    /// Height unit preference
    var heightUnit: HeightUnit = .cm

    /// Distance unit preference
    var distanceUnit: DistanceUnit = .km

    // MARK: - Enums

    enum WeightUnit: String, Codable, CaseIterable {
        case kg = "Kilograms"
        case lbs = "Pounds"

        var abbreviation: String {
            switch self {
            case .kg: return "kg"
            case .lbs: return "lbs"
            }
        }

        /// Convert kg to this unit
        func convert(fromKg kg: Double) -> Double {
            switch self {
            case .kg: return kg
            case .lbs: return kg * 2.20462
            }
        }

        /// Convert this unit to kg
        func toKg(_ value: Double) -> Double {
            switch self {
            case .kg: return value
            case .lbs: return value / 2.20462
            }
        }
    }

    enum HeightUnit: String, Codable, CaseIterable {
        case cm = "Centimeters"
        case feet = "Feet & Inches"

        var abbreviation: String {
            switch self {
            case .cm: return "cm"
            case .feet: return "ft"
            }
        }

        /// Convert cm to this unit (returns tuple for feet/inches)
        func convert(fromCm cm: Double) -> (primary: Int, secondary: Int?) {
            switch self {
            case .cm:
                return (Int(cm), nil)
            case .feet:
                let totalInches = cm / 2.54
                let feet = Int(totalInches / 12)
                let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
                return (feet, inches)
            }
        }

        /// Convert this unit to cm
        func toCm(primary: Int, secondary: Int? = nil) -> Double {
            switch self {
            case .cm:
                return Double(primary)
            case .feet:
                let inches = (primary * 12) + (secondary ?? 0)
                return Double(inches) * 2.54
            }
        }
    }

    enum DistanceUnit: String, Codable, CaseIterable {
        case km = "Kilometers"
        case miles = "Miles"

        var abbreviation: String {
            switch self {
            case .km: return "km"
            case .miles: return "mi"
            }
        }

        /// Convert meters to this unit
        func convert(fromMeters meters: Double) -> Double {
            switch self {
            case .km: return meters / 1000
            case .miles: return meters / 1609.34
            }
        }
    }

    enum CalorieGoalSource: String, Codable, CaseIterable {
        case bmr = "BMR"
        case tdee = "TDEE"
        case custom = "Custom"

        var displayName: String {
            switch self {
            case .bmr: return "BMR (Basal Metabolic Rate)"
            case .tdee: return "TDEE (Total Daily Energy)"
            case .custom: return "Custom Target"
            }
        }

        var description: String {
            switch self {
            case .bmr: return "Calories burned at rest - use for weight loss"
            case .tdee: return "Total calories including activity - use to maintain weight"
            case .custom: return "Set your own custom calorie target"
            }
        }
    }
}

// MARK: - UserDefaults Storage

extension UserSettings {
    private static let key = "com.netfuel.userSettings"

    /// Load settings from UserDefaults
    static func load() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings() // Return default settings
        }
        return settings
    }

    /// Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserSettings.key)
        }
    }

    /// Clear all settings
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
