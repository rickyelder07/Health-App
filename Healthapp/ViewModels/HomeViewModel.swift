//
//  HomeViewModel.swift
//  Health App
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

    /// Calories consumed today
    var caloriesConsumed: Int {
        dailySummary?.caloriesConsumed ?? 0
    }

    /// Total calories burned (BMR + exercise)
    var caloriesBurned: Int {
        dailySummary?.totalCaloriesBurned ?? dailySummary?.calculateTotalCaloriesBurned() ?? 0
    }

    /// Net calories (consumed - burned)
    var netCalories: Int {
        dailySummary?.netCalories ?? dailySummary?.calculateNetCalories() ?? 0
    }

    /// Is user in calorie surplus?
    var isInSurplus: Bool {
        netCalories > 0
    }

    /// Calorie target (TDEE)
    var calorieTarget: Int {
        // In a real app, this would come from user profile
        // For now, use BMR as a rough estimate
        dailySummary?.caloriesBurnedBmr ?? 2000
    }

    /// Macro targets (rough estimates based on consumed calories)
    var proteinTarget: Double {
        Double(caloriesConsumed) * 0.30 / 4 // 30% of calories, 4 cal/g
    }

    var carbsTarget: Double {
        Double(caloriesConsumed) * 0.40 / 4 // 40% of calories, 4 cal/g
    }

    var fatTarget: Double {
        Double(caloriesConsumed) * 0.30 / 9 // 30% of calories, 9 cal/g
    }
}
