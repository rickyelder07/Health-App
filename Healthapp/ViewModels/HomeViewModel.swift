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
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userId: UUID
    private let summaryService = DailySummaryService.shared
    private let foodService = FoodService()
    private let stravaService = StravaService()
    private let photoService = PhotoService()
    private let profileService = ProfileService.shared

    // MARK: - Initialization

    init(userId: UUID) {
        self.userId = userId
    }

    /// Load today's summary data
    func loadTodaySummary() async {
        print("📍 HomeViewModel.loadTodaySummary() - START")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let fetchedUser = profileService.fetchProfile(userId: userId)
            async let fetchedSummary = summaryService.fetchSummary(userId: userId, date: Date())

            if let freshUser = try? await fetchedUser { user = freshUser }

            print("📍 Step 1: Fetching summary for user \(userId)")
            dailySummary = try await fetchedSummary
            print("📍 Step 1: COMPLETE - Summary: \(dailySummary != nil ? "FOUND" : "NIL")")

            if dailySummary == nil {
                print("📍 Step 2: No summary found, calculating new one...")
                dailySummary = try await summaryService.calculateAndUpdateSummary(userId: userId, date: Date())
                print("📍 Step 2: COMPLETE - Calculated summary")
            } else {
                print("📍 Step 2: SKIPPED - Summary already exists")
            }

            currentWeight = dailySummary?.weight

            print("📍 Step 3: Fetching food logs...")
            foodEntries = try await foodService.fetchFoodLogs(userId: userId, date: Date())
            print("📍 Step 3: COMPLETE - Found \(foodEntries.count) food entries")

            print("📍 Step 4: Fetching activities...")
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
            let photos = try await photoService.fetchPhotos(userId: userId)
            recentPhoto = photos.first
            print("📍 Step 5: COMPLETE - Recent photo: \(recentPhoto != nil ? "FOUND" : "NONE")")

            WidgetDataManager.shared.write(
                caloriesConsumed: caloriesConsumed, calorieGoal: calorieTarget,
                proteinConsumed: proteinConsumed,   proteinGoal: proteinTarget,
                carbsConsumed: carbsConsumed,       carbsGoal: carbsTarget,
                fatConsumed: fatConsumed,           fatGoal: fatTarget
            )

            print("✅ HomeViewModel.loadTodaySummary() - SUCCESS")
        } catch is CancellationError {
            // ponytail: .task cancels in-flight work when view disappears — not an error
            print("📍 HomeViewModel.loadTodaySummary() - CANCELLED")
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession throws this (NSURLErrorDomain -999) when the Swift task is cancelled
            print("📍 HomeViewModel.loadTodaySummary() - CANCELLED (URLSession)")
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("❌ Error loading today's summary: \(error)")
        }

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

    /// Total calories burned — mirrors calorieTarget until burned tracking is rebuilt
    var caloriesBurned: Int {
        calorieTarget
    }

    /// Net calories relative to the active budget mode:
    /// - TDEE mode:  consumed - calorieTarget (how far above/below the goal)
    /// - Strava Dynamic: consumed - caloriesBurned (ate back what you burned)
    var netCalories: Int {
        if UserSettings.load().calorieMode == .stravaDynamic {
            return caloriesConsumed - caloriesBurned
        }
        return caloriesConsumed - calorieTarget
    }

    /// Is user in calorie surplus?
    var isInSurplus: Bool {
        netCalories > 0
    }

    var isStravaDynamicMode: Bool {
        UserSettings.load().calorieMode == .stravaDynamic
    }

    // ponytail: daily summary's caloriesBurnedBmr is a historical snapshot — use live user.bmr for goal calc
    var bmrCalories: Int {
        Int(user?.bmr ?? user?.calculateBMR() ?? 0)
    }

    /// Calorie target derived from the user's fitness goal and budget mode
    var calorieTarget: Int {
        let settings = UserSettings.load()
        if settings.calorieMode == .stravaDynamic {
            return settings.stravaCalorieTarget(bmr: bmrCalories, exerciseCalories: totalExerciseCalories)
        }
        let tdee = Int(user?.tdee ?? user?.calculateTDEE() ?? 0)
        return settings.effectiveCalorieTarget(tdee: tdee)
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
