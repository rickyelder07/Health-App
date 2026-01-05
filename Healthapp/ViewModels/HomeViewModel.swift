//
//  HomeViewModel.swift
//  Netfuel
//
//  ViewModel for home dashboard
//

import Foundation
import Combine

/// ViewModel for home dashboard view
@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var dailySummary: DailySummary?
    @Published var foodEntries: [FoodEntry] = []
    @Published var activities: [Activity] = []
    @Published var recentPhoto: ProgressPhoto?
    @Published var currentWeight: Double?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userId: UUID
    private let summaryService = DailySummaryService()
    private let foodService = FoodService()
    private let stravaService = StravaService()
    private let photoService = PhotoService()

    // MARK: - Initialization

    init(userId: UUID) {
        self.userId = userId
    }

    /// Load today's summary data
    func loadTodaySummary() async {
        print("📍 HomeViewModel.loadTodaySummary() - START")
        isLoading = true
        errorMessage = nil

        do {
            print("📍 Step 1: Fetching summary for user \(userId)")
            // Load or create today's summary
            dailySummary = try await summaryService.fetchSummary(userId: userId, date: Date())
            print("📍 Step 1: COMPLETE - Summary: \(dailySummary != nil ? "FOUND" : "NIL")")

            // If no summary exists, calculate one
            if dailySummary == nil {
                print("📍 Step 2: No summary found, calculating new one...")
                dailySummary = try await summaryService.calculateAndUpdateSummary(
                    userId: userId,
                    date: Date()
                )
                print("📍 Step 2: COMPLETE - Calculated summary")
            } else {
                print("📍 Step 2: SKIPPED - Summary already exists")
            }

            // Extract weight from summary
            currentWeight = dailySummary?.weight

            print("📍 Step 3: Fetching food logs...")
            // Load today's food logs
            foodEntries = try await foodService.fetchFoodLogs(userId: userId, date: Date())
            print("📍 Step 3: COMPLETE - Found \(foodEntries.count) food entries")

            print("📍 Step 4: Fetching activities...")
            // Load today's activities
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            activities = try await stravaService.fetchActivitiesFromDatabase(
                userId: userId,
                startDate: startOfDay,
                endDate: endOfDay
            )
            print("📍 Step 4: COMPLETE - Found \(activities.count) activities")

            print("📍 Step 5: Fetching recent photo...")
            // Load most recent progress photo
            let photos = try await photoService.fetchPhotos(userId: userId)
            recentPhoto = photos.first
            print("📍 Step 5: COMPLETE - Recent photo: \(recentPhoto != nil ? "FOUND" : "NONE")")

            print("✅ HomeViewModel.loadTodaySummary() - SUCCESS")
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("❌ Error loading today's summary: \(error)")
            print("❌ Error details: \(String(describing: error))")
        }

        isLoading = false
        print("📍 HomeViewModel.loadTodaySummary() - END (isLoading=false)")
    }

    /// Refresh all data
    func refresh() async {
        await loadTodaySummary()
    }

    // MARK: - Computed Properties

    /// Total exercise calories from activities
    var totalExerciseCalories: Int {
        activities.reduce(0) { $0 + Int($1.calories) }
    }

    /// Calories consumed today - calculated directly from food logs for real-time accuracy
    var caloriesConsumed: Int {
        foodEntries.reduce(0) { $0 + Int($1.totalCalories) }
    }

    /// Total protein consumed today
    var proteinConsumed: Double {
        foodEntries.reduce(0.0) { $0 + $1.totalProtein }
    }

    /// Total carbs consumed today
    var carbsConsumed: Double {
        foodEntries.reduce(0.0) { $0 + $1.totalCarbs }
    }

    /// Total fat consumed today
    var fatConsumed: Double {
        foodEntries.reduce(0.0) { $0 + $1.totalFat }
    }

    /// Total calories burned (BMR + exercise) - uses dailySummary for BMR, calculates exercise from activities
    var caloriesBurned: Int {
        let bmr = dailySummary?.caloriesBurnedBmr ?? 0
        let exercise = totalExerciseCalories
        return bmr + exercise
    }

    /// Net calories (consumed - burned)
    var netCalories: Int {
        caloriesConsumed - caloriesBurned
    }

    /// Is user in calorie surplus?
    var isInSurplus: Bool {
        netCalories > 0
    }

    /// Calorie target - uses historical goal from summary if available
    var calorieTarget: Int {
        // IMPORTANT: Use historical goal from summary for accurate comparisons
        // Even if user changes their goal later, we show what the goal was on this day
        if let historicalGoal = dailySummary?.calorieGoal {
            return historicalGoal
        }

        // Fallback: Calculate current goal (for new summaries that don't have goal saved yet)
        let settings = UserSettings.load()
        switch settings.calorieGoalSource {
        case .bmr:
            // Would need user's BMR - fall through to TDEE for now
            fallthrough
        case .tdee:
            return dailySummary?.totalCaloriesBurned ?? dailySummary?.calculateTotalCaloriesBurned() ?? 2000
        case .custom:
            return settings.dailyCalorieTarget ?? 2000
        }
    }

    /// Macro targets from user settings
    var proteinTarget: Double {
        let settings = UserSettings.load()
        // Use user's custom target if set, otherwise use 30% of calorie target
        return settings.proteinTargetGrams ?? (Double(calorieTarget) * 0.30 / 4)
    }

    var carbsTarget: Double {
        let settings = UserSettings.load()
        // Use user's custom target if set, otherwise use 40% of calorie target
        return settings.carbsTargetGrams ?? (Double(calorieTarget) * 0.40 / 4)
    }

    var fatTarget: Double {
        let settings = UserSettings.load()
        // Use user's custom target if set, otherwise use 30% of calorie target
        return settings.fatTargetGrams ?? (Double(calorieTarget) * 0.30 / 9)
    }
}
