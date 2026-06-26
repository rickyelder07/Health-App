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

    /// Budget mode: TDEE-based (standard) or dynamic BMR + Strava exercise
    var calorieMode: CalorieMode = .tdee

    /// Fitness goal mode
    var fitnessGoal: FitnessGoal = .maintenance

    /// Daily calorie target (only used when fitnessGoal is .manual)
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

    enum CalorieMode: String, Codable {
        case tdee
        case stravaDynamic
    }

    enum FitnessGoal: String, Codable, CaseIterable {
        case maintenance
        case cutting
        case bulking
        case manual

        var displayName: String {
            switch self {
            case .maintenance: return "Maintenance"
            case .cutting: return "Cutting"
            case .bulking: return "Bulking"
            case .manual: return "Manual"
            }
        }

        var subtitle: String {
            switch self {
            case .maintenance: return "Maintain current weight"
            case .cutting: return "Lose ~1 lb/week"
            case .bulking: return "Lean muscle gain"
            case .manual: return "Set your own target"
            }
        }

        // Calorie offset from TDEE
        var calorieOffset: Int {
            switch self {
            case .maintenance: return 0
            case .cutting: return -500
            case .bulking: return 300
            case .manual: return 0
            }
        }

        // Default macro split [protein%, carbs%, fat%]
        var defaultMacros: (protein: Int, carbs: Int, fat: Int) {
            switch self {
            case .maintenance: return (30, 40, 30)
            case .cutting: return (40, 30, 30)
            case .bulking: return (30, 50, 20)
            case .manual: return (30, 40, 30)
            }
        }
    }
}

// MARK: - Calorie Target Calculation

extension UserSettings {
    /// Standard TDEE-based target. Used when calorieMode == .tdee.
    func effectiveCalorieTarget(tdee: Int) -> Int {
        switch fitnessGoal {
        case .maintenance: return tdee
        case .cutting:     return max(1200, tdee + fitnessGoal.calorieOffset)
        case .bulking:     return tdee + fitnessGoal.calorieOffset
        case .manual:      return dailyCalorieTarget ?? tdee
        }
    }

    /// Dynamic Strava target: BMR + today's exercise calories, then goal offset applied.
    /// Used when calorieMode == .stravaDynamic. Budget grows as activities sync.
    func stravaCalorieTarget(bmr: Int, exerciseCalories: Int) -> Int {
        let base = bmr + exerciseCalories
        switch fitnessGoal {
        case .maintenance: return base
        case .cutting:     return max(1200, base - 500)
        case .bulking:     return base + 300
        case .manual:      return dailyCalorieTarget ?? base
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
