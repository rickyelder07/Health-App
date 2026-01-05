//
//  DailySummaryService.swift
//  Netfuel
//
//  Service for calculating and managing daily summaries
//

import Foundation
import Supabase

/// Service for managing daily calorie and macro summaries
class DailySummaryService {
    private let supabase = SupabaseClient.shared.client
    
    // Custom date decoder that handles multiple formats
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try date-only format first (YYYY-MM-DD) - common for DATE columns in PostgreSQL
            if dateString.count == 10 && dateString.contains("-") {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // Try ISO8601 with fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Try standard date formatter with milliseconds
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try without milliseconds
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
        return decoder
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch daily summary for a specific date
    /// - Parameters:
    ///   - userId: User ID
    ///   - date: Date to fetch summary for
    /// - Returns: Daily summary if exists, nil otherwise
    func fetchSummary(userId: UUID, date: Date) async throws -> DailySummary? {
        print("🔍 DailySummaryService.fetchSummary() - START")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        print("🔍 Querying for user: \(userId), date: \(startOfDay.ISO8601Format())")

        let response = try await supabase
            .from("daily_summaries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: startOfDay.ISO8601Format())
            .execute()

        print("🔍 Response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")

        let summaries = try decoder.decode([DailySummary].self, from: response.data)
        print("🔍 Decoded \(summaries.count) summaries")

        return summaries.first
    }
    
    /// Fetch daily summaries for a date range
    /// - Parameters:
    ///   - userId: User ID
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of daily summaries
    func fetchSummaries(userId: UUID, startDate: Date, endDate: Date) async throws -> [DailySummary] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        let response = try await supabase
            .from("daily_summaries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: start.ISO8601Format())
            .lte("date", value: end.ISO8601Format())
            .order("date", ascending: false)
            .execute()
        
        return try decoder.decode([DailySummary].self, from: response.data)
    }
    
    // MARK: - Calculate and Update
    
    /// Calculate and update daily summary for a specific date
    /// This is the main method that recalculates everything
    /// - Parameters:
    ///   - userId: User ID
    ///   - date: Date to calculate summary for
    ///   - userBMR: User's BMR (if available, otherwise fetched)
    ///   - userTDEE: User's TDEE (if available, otherwise fetched)
    /// - Returns: Updated daily summary
    @discardableResult
    func calculateAndUpdateSummary(
        userId: UUID,
        date: Date,
        userBMR: Double? = nil,
        userTDEE: Double? = nil
    ) async throws -> DailySummary {
        print("🔍 calculateAndUpdateSummary() - START")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // 1. Fetch user profile if BMR/TDEE not provided
        var bmr = userBMR
        var tdee = userTDEE

        if bmr == nil || tdee == nil {
            print("🔍 Step 1a: Fetching user profile...")
            let user = try await fetchUserProfile(userId: userId)
            bmr = user.bmr ?? user.calculateBMR()
            tdee = user.tdee ?? user.calculateTDEE()
            print("🔍 Step 1a: COMPLETE - BMR: \(bmr ?? 0), TDEE: \(tdee ?? 0)")
        }

        // 2. Calculate daily baseline burn from TDEE
        print("🔍 Step 2: Calculating daily baseline burn...")
        let dailyBaselineBurn = calculateDailyBaselineBurn(tdee: tdee)
        print("🔍 Step 2: COMPLETE - Daily burn: \(dailyBaselineBurn)")

        // 3. Fetch and sum food logs for the day
        print("🔍 Step 3: Calculating food totals...")
        let foodTotals = try await calculateFoodTotals(userId: userId, date: date)
        print("🔍 Step 3: COMPLETE - Calories: \(foodTotals.calories), Protein: \(foodTotals.protein)g")

        // 4. Fetch and sum activities for the day
        print("🔍 Step 4: Calculating exercise calories...")
        let exerciseCalories = try await calculateExerciseCalories(userId: userId, date: date)
        print("🔍 Step 4: COMPLETE - Exercise: \(exerciseCalories)")

        // 4.5. Calculate current calorie goal for historical tracking
        print("🔍 Step 4.5: Calculating calorie goal...")
        let calorieGoal = calculateCurrentCalorieGoal(bmr: bmr, tdee: tdee)
        print("🔍 Step 4.5: COMPLETE - Goal: \(calorieGoal ?? 0)")

        // 5. Upsert daily summary
        print("🔍 Step 5: Upserting summary...")
        let result = try await upsertSummary(
            userId: userId,
            date: startOfDay,
            caloriesConsumed: foodTotals.calories,
            proteinConsumed: foodTotals.protein,
            carbsConsumed: foodTotals.carbs,
            fatConsumed: foodTotals.fat,
            caloriesBurnedBmr: dailyBaselineBurn,
            caloriesBurnedExercise: exerciseCalories,
            calorieGoal: calorieGoal
        )
        print("🔍 Step 5: COMPLETE")
        print("✅ calculateAndUpdateSummary() - SUCCESS")
        return result
    }
    
    /// Quick update for food consumption only (keeps existing burn values)
    /// Use this when you know only food logs changed
    func updateFoodConsumption(userId: UUID, date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Fetch food totals
        let foodTotals = try await calculateFoodTotals(userId: userId, date: date)
        
        // Check if summary exists
        let existing = try await fetchSummary(userId: userId, date: date)
        
        if let existing = existing {
            // Update existing summary (keep burn values)
            try await updateSummaryConsumption(
                userId: userId,
                date: startOfDay,
                caloriesConsumed: foodTotals.calories,
                proteinConsumed: foodTotals.protein,
                carbsConsumed: foodTotals.carbs,
                fatConsumed: foodTotals.fat
            )
        } else {
            // No existing summary, do full calculation
            try await calculateAndUpdateSummary(userId: userId, date: date)
        }
    }
    
    /// Quick update for exercise calories only (keeps existing consumption values)
    /// Use this when you know only activities changed
    func updateExerciseCalories(userId: UUID, date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Fetch exercise totals
        let exerciseCalories = try await calculateExerciseCalories(userId: userId, date: date)

        // Check if summary exists
        let existing = try await fetchSummary(userId: userId, date: date)

        if let existing = existing {
            // Update existing summary (keep consumption values)
            try await updateSummaryExercise(
                userId: userId,
                date: startOfDay,
                caloriesBurnedExercise: exerciseCalories
            )
        } else {
            // No existing summary, do full calculation
            try await calculateAndUpdateSummary(userId: userId, date: date)
        }
    }

    /// Update weight for a specific date
    /// Use this when logging weight separately from other data
    /// - Parameters:
    ///   - userId: User ID
    ///   - date: Date to log weight for
    ///   - weight: Weight in kg
    func updateDailyWeight(userId: UUID, date: Date, weight: Double) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check if summary exists for this date
        let existing = try await fetchSummary(userId: userId, date: date)

        if let existing = existing {
            // Update existing summary with weight
            try await updateSummaryWeight(
                userId: userId,
                date: startOfDay,
                weight: weight
            )
        } else {
            // Create new summary with weight only
            // Will trigger full calculation which will set other fields to 0
            try await calculateAndUpdateSummary(userId: userId, date: date)
            // Then update with weight
            try await updateSummaryWeight(
                userId: userId,
                date: startOfDay,
                weight: weight
            )
        }
    }

    // MARK: - Calculation Helpers
    
    /// Calculate daily baseline burn from TDEE
    /// Formula: TDEE / 7 (since TDEE is typically weekly)
    /// OR just use daily TDEE if that's what's stored
    private func calculateDailyBaselineBurn(tdee: Double?) -> Int {
        guard let tdee = tdee else {
            print("⚠️ No TDEE available, using default 2000 cal/day")
            return 2000
        }

        // TDEE is already daily, so just return it as integer
        return Int(tdee)
    }

    /// Calculate current calorie goal based on user settings
    /// - Parameters:
    ///   - bmr: User's BMR
    ///   - tdee: User's TDEE
    /// - Returns: Current calorie goal as Int, or nil if cannot be determined
    private func calculateCurrentCalorieGoal(bmr: Double?, tdee: Double?) -> Int? {
        let settings = UserSettings.load()

        switch settings.calorieGoalSource {
        case .bmr:
            guard let bmr = bmr else { return nil }
            return Int(bmr)
        case .tdee:
            guard let tdee = tdee else { return nil }
            return Int(tdee)
        case .custom:
            return settings.dailyCalorieTarget
        }
    }

    /// Calculate food totals for a specific date
    private func calculateFoodTotals(userId: UUID, date: Date) async throws -> (calories: Int, protein: Double, carbs: Double, fat: Double) {
        print("  🥗 calculateFoodTotals() - START")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        print("  🥗 Date range: \(startOfDay.ISO8601Format()) to \(endOfDay.ISO8601Format())")

        let response = try await supabase
            .from("food_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: startOfDay.ISO8601Format())
            .lt("logged_at", value: endOfDay.ISO8601Format())
            .execute()

        print("  🥗 Food logs response: \(String(data: response.data, encoding: .utf8) ?? "nil")")

        let foodLogs = try decoder.decode([FoodLog].self, from: response.data)
        print("  🥗 Decoded \(foodLogs.count) food logs")

        let totalCalories = foodLogs.reduce(0) { $0 + Int($1.totalCalories) }
        let totalProtein = foodLogs.reduce(0.0) { $0 + $1.totalProtein }
        let totalCarbs = foodLogs.reduce(0.0) { $0 + $1.totalCarbs }
        let totalFat = foodLogs.reduce(0.0) { $0 + $1.totalFat }

        return (totalCalories, totalProtein, totalCarbs, totalFat)
    }
    
    /// Calculate exercise calories for a specific date
    private func calculateExerciseCalories(userId: UUID, date: Date) async throws -> Int {
        print("  🏃 calculateExerciseCalories() - START")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        print("  🏃 Date range: \(startOfDay.ISO8601Format()) to \(endOfDay.ISO8601Format())")

        let response = try await supabase
            .from("activities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("start_date", value: startOfDay.ISO8601Format())
            .lt("start_date", value: endOfDay.ISO8601Format())
            .execute()

        print("  🏃 Activities response: \(String(data: response.data, encoding: .utf8) ?? "nil")")

        let activities = try decoder.decode([Activity].self, from: response.data)
        print("  🏃 Decoded \(activities.count) activities")

        let totalExerciseCalories = activities.reduce(into: 0) { total, activity in
            total += Int(activity.calories)
        }

        return totalExerciseCalories
    }
    
    /// Fetch user profile
    private func fetchUserProfile(userId: UUID) async throws -> User {
        print("🔍 Fetching user profile for ID: \(userId)")
        
        let response = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
        
        print("📥 User query response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
        
        let users = try decoder.decode([User].self, from: response.data)
        
        print("✅ Decoded \(users.count) user(s)")
        
        guard let user = users.first else {
            print("❌ No user found with ID: \(userId)")
            throw DailySummaryError.userProfileNotFound
        }
        
        print("✅ User profile found: BMR=\(user.bmr ?? 0), TDEE=\(user.tdee ?? 0)")
        return user
    }
    
    // MARK: - Database Operations
    
    /// Upsert daily summary (insert or update)
    private func upsertSummary(
        userId: UUID,
        date: Date,
        caloriesConsumed: Int,
        proteinConsumed: Double,
        carbsConsumed: Double,
        fatConsumed: Double,
        caloriesBurnedBmr: Int,
        caloriesBurnedExercise: Int,
        calorieGoal: Int?
    ) async throws -> DailySummary {
        // Check if summary exists
        let existing = try await fetchSummary(userId: userId, date: date)

        if existing != nil {
            // Update existing
            let updateRequest = DailySummaryFullUpdateRequest(
                caloriesConsumed: caloriesConsumed,
                proteinConsumed: proteinConsumed,
                carbsConsumed: carbsConsumed,
                fatConsumed: fatConsumed,
                caloriesBurnedBmr: caloriesBurnedBmr,
                caloriesBurnedExercise: caloriesBurnedExercise,
                calorieGoal: calorieGoal
            )
            
            let response = try await supabase
                .from("daily_summaries")
                .update(updateRequest)
                .eq("user_id", value: userId.uuidString)
                .eq("date", value: date.ISO8601Format())
                .select()
                .execute()
            
            let summaries = try decoder.decode([DailySummary].self, from: response.data)
            
            guard let updated = summaries.first else {
                throw DailySummaryError.updateFailed
            }
            
            return updated
        } else {
            // Insert new
            let newSummary = CreateDailySummaryRequest(
                userId: userId,
                date: date,
                caloriesConsumed: caloriesConsumed,
                proteinConsumed: proteinConsumed,
                carbsConsumed: carbsConsumed,
                fatConsumed: fatConsumed,
                caloriesBurnedBmr: caloriesBurnedBmr,
                caloriesBurnedExercise: caloriesBurnedExercise,
                calorieGoal: calorieGoal
            )
            
            let response = try await supabase
                .from("daily_summaries")
                .insert(newSummary)
                .select()
                .execute()
            
            let summaries = try decoder.decode([DailySummary].self, from: response.data)
            
            guard let created = summaries.first else {
                throw DailySummaryError.createFailed
            }
            
            return created
        }
    }
    
    /// Update only consumption values
    private func updateSummaryConsumption(
        userId: UUID,
        date: Date,
        caloriesConsumed: Int,
        proteinConsumed: Double,
        carbsConsumed: Double,
        fatConsumed: Double
    ) async throws {
        let updateRequest = DailySummaryConsumptionUpdateRequest(
            caloriesConsumed: caloriesConsumed,
            proteinConsumed: proteinConsumed,
            carbsConsumed: carbsConsumed,
            fatConsumed: fatConsumed
        )
        
        _ = try await supabase
            .from("daily_summaries")
            .update(updateRequest)
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date.ISO8601Format())
            .execute()
    }
    
    /// Update only exercise calories
    private func updateSummaryExercise(
        userId: UUID,
        date: Date,
        caloriesBurnedExercise: Int
    ) async throws {
        let updateRequest = DailySummaryExerciseUpdateRequest(
            caloriesBurnedExercise: caloriesBurnedExercise
        )

        _ = try await supabase
            .from("daily_summaries")
            .update(updateRequest)
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date.ISO8601Format())
            .execute()
    }

    /// Update only weight
    private func updateSummaryWeight(
        userId: UUID,
        date: Date,
        weight: Double
    ) async throws {
        let updateRequest = DailySummaryWeightUpdateRequest(
            weight: weight
        )

        _ = try await supabase
            .from("daily_summaries")
            .update(updateRequest)
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date.ISO8601Format())
            .execute()
    }
}

// MARK: - Supporting Models

/// Request model for creating a new daily summary
struct CreateDailySummaryRequest: Codable {
    let userId: UUID
    let date: Date
    let caloriesConsumed: Int
    let proteinConsumed: Double
    let carbsConsumed: Double
    let fatConsumed: Double
    let caloriesBurnedBmr: Int
    let caloriesBurnedExercise: Int
    let calorieGoal: Int?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case caloriesConsumed = "calories_consumed"
        case proteinConsumed = "protein_consumed"
        case carbsConsumed = "carbs_consumed"
        case fatConsumed = "fat_consumed"
        case caloriesBurnedBmr = "calories_burned_bmr"
        case caloriesBurnedExercise = "calories_burned_exercise"
        case calorieGoal = "calorie_goal"
    }
}

/// Request model for full update of daily summary
struct DailySummaryFullUpdateRequest: Codable {
    let caloriesConsumed: Int
    let proteinConsumed: Double
    let carbsConsumed: Double
    let fatConsumed: Double
    let caloriesBurnedBmr: Int
    let caloriesBurnedExercise: Int
    let calorieGoal: Int?

    enum CodingKeys: String, CodingKey {
        case caloriesConsumed = "calories_consumed"
        case proteinConsumed = "protein_consumed"
        case carbsConsumed = "carbs_consumed"
        case fatConsumed = "fat_consumed"
        case caloriesBurnedBmr = "calories_burned_bmr"
        case caloriesBurnedExercise = "calories_burned_exercise"
        case calorieGoal = "calorie_goal"
    }
}

/// Request model for updating consumption only
struct DailySummaryConsumptionUpdateRequest: Codable {
    let caloriesConsumed: Int
    let proteinConsumed: Double
    let carbsConsumed: Double
    let fatConsumed: Double
    
    enum CodingKeys: String, CodingKey {
        case caloriesConsumed = "calories_consumed"
        case proteinConsumed = "protein_consumed"
        case carbsConsumed = "carbs_consumed"
        case fatConsumed = "fat_consumed"
    }
}

/// Request model for updating exercise only
struct DailySummaryExerciseUpdateRequest: Codable {
    let caloriesBurnedExercise: Int

    enum CodingKeys: String, CodingKey {
        case caloriesBurnedExercise = "calories_burned_exercise"
    }
}

/// Request model for updating weight only
struct DailySummaryWeightUpdateRequest: Codable {
    let weight: Double

    enum CodingKeys: String, CodingKey {
        case weight
    }
}

/// Errors that can occur in daily summary operations
enum DailySummaryError: LocalizedError {
    case updateFailed
    case createFailed
    case userProfileNotFound
    case invalidDate
    
    var errorDescription: String? {
        switch self {
        case .updateFailed:
            return "Failed to update daily summary"
        case .createFailed:
            return "Failed to create daily summary"
        case .userProfileNotFound:
            return "User profile not found for BMR/TDEE calculation"
        case .invalidDate:
            return "Invalid date provided"
        }
    }
}

// Note: FoodLog model is defined in Models/FoodEntry.swift
// No need to redefine it here

