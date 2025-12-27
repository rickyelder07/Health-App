//
//  DailySummary.swift
//  Health App
//
//  Model for daily calorie and macro summary
//

import Foundation

/// Daily summary of calories and macronutrients
/// Composite primary key: (user_id, date)
struct DailySummary: Codable, Identifiable {
    // Composite ID for Identifiable conformance
    var id: String { "\(userId)-\(date)" }
    
    let userId: UUID
    let date: Date
    
    // Optional weight tracking
    var weight: Double? // in kg
    
    // Calories consumed from food
    var caloriesConsumed: Int
    var proteinConsumed: Double
    var carbsConsumed: Double
    var fatConsumed: Double
    
    // Calories burned
    var caloriesBurnedBmr: Int // From BMR
    var caloriesBurnedExercise: Int // From activities
    
    // Computed fields (calculated in database but read here)
    var totalCaloriesBurned: Int? // BMR + Exercise (GENERATED column in DB)
    var netCalories: Int? // Consumed - Burned (GENERATED column in DB)
    
    // Timestamps
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case weight
        case caloriesConsumed = "calories_consumed"
        case proteinConsumed = "protein_consumed"
        case carbsConsumed = "carbs_consumed"
        case fatConsumed = "fat_consumed"
        case caloriesBurnedBmr = "calories_burned_bmr"
        case caloriesBurnedExercise = "calories_burned_exercise"
        case totalCaloriesBurned = "total_calories_burned"
        case netCalories = "net_calories"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    
    /// Calculate total calories burned (if not provided by database)
    func calculateTotalCaloriesBurned() -> Int {
        return caloriesBurnedBmr + caloriesBurnedExercise
    }
    
    /// Calculate net calories (if not provided by database)
    func calculateNetCalories() -> Int {
        let totalBurned = totalCaloriesBurned ?? calculateTotalCaloriesBurned()
        return caloriesConsumed - totalBurned
    }
    
    /// Check if user is in calorie surplus
    var isInSurplus: Bool {
        let net = netCalories ?? calculateNetCalories()
        return net > 0
    }
    
    /// Check if user is in calorie deficit
    var isInDeficit: Bool {
        let net = netCalories ?? calculateNetCalories()
        return net < 0
    }
    
    /// Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

