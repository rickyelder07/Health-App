//
//  AnalyticsViewModel.swift
//  Health App
//
//  ViewModel for analytics and trends
//

import Foundation
import Combine
import Supabase

/// Time range for analytics data
enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }

    var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

/// ViewModel for analytics view
@MainActor
class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedRange: TimeRange = .month
    @Published var dailySummaries: [DailySummary] = []
    @Published var foodLogs: [FoodEntry] = []
    @Published var activities: [Activity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userId: UUID
    private let summaryService = DailySummaryService()
    private let foodService = FoodService()
    private let stravaService = StravaService()

    // MARK: - Initialization

    init(userId: UUID) {
        self.userId = userId
    }

    // MARK: - Data Loading

    /// Load all analytics data for selected range
    func loadData() async {
        print("📊 AnalyticsViewModel.loadData() - START for range: \(selectedRange.rawValue)")
        isLoading = true
        errorMessage = nil

        let startDate = selectedRange.startDate
        let endDate = Date()

        do {
            print("📊 Fetching data from \(startDate.dateOnlyString) to \(endDate.dateOnlyString)")

            // Fetch all data in parallel
            async let summariesTask = fetchDailySummaries(startDate: startDate, endDate: endDate)
            async let foodLogsTask = fetchFoodLogs(startDate: startDate, endDate: endDate)
            async let activitiesTask = fetchActivities(startDate: startDate, endDate: endDate)

            let (summaries, logs, acts) = try await (summariesTask, foodLogsTask, activitiesTask)

            dailySummaries = summaries
            foodLogs = logs
            activities = acts

            print("✅ Loaded \(dailySummaries.count) summaries, \(foodLogs.count) food logs, \(activities.count) activities")
        } catch {
            errorMessage = "Failed to load analytics data: \(error.localizedDescription)"
            print("❌ Error loading analytics: \(error)")
        }

        isLoading = false
    }

    /// Refresh data for current range
    func refresh() async {
        await loadData()
    }

    // MARK: - Private Fetch Methods

    private func fetchDailySummaries(startDate: Date, endDate: Date) async throws -> [DailySummary] {
        let response = try await SupabaseClient.shared.client
            .from("daily_summaries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startDate.ISO8601Format())
            .lte("date", value: endDate.ISO8601Format())
            .order("date", ascending: true)
            .execute()

        return try DateFormatters.supabaseDecoder.decode([DailySummary].self, from: response.data)
    }

    private func fetchFoodLogs(startDate: Date, endDate: Date) async throws -> [FoodEntry] {
        let response = try await SupabaseClient.shared.client
            .from("food_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: startDate.ISO8601Format())
            .lte("logged_at", value: endDate.ISO8601Format())
            .order("logged_at", ascending: true)
            .execute()

        return try DateFormatters.supabaseDecoder.decode([FoodEntry].self, from: response.data)
    }

    private func fetchActivities(startDate: Date, endDate: Date) async throws -> [Activity] {
        let response = try await SupabaseClient.shared.client
            .from("activities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("start_date", value: startDate.ISO8601Format())
            .lte("start_date", value: endDate.ISO8601Format())
            .order("start_date", ascending: true)
            .execute()

        return try DateFormatters.supabaseDecoder.decode([Activity].self, from: response.data)
    }

    // MARK: - Weight Statistics

    /// Weight data points for chart
    var weightDataPoints: [(date: Date, weight: Double)] {
        dailySummaries
            .compactMap { summary -> (Date, Double)? in
                guard let weight = summary.weight else { return nil }
                return (summary.date, weight)
            }
            .sorted { $0.date < $1.date }
    }

    /// Starting weight in range
    var startingWeight: Double? {
        weightDataPoints.first?.weight
    }

    /// Current weight (most recent)
    var currentWeight: Double? {
        weightDataPoints.last?.weight
    }

    /// Total weight change
    var weightChange: Double? {
        guard let start = startingWeight, let current = currentWeight else { return nil }
        return current - start
    }

    /// Average weekly weight change
    var averageWeeklyChange: Double? {
        guard let change = weightChange else { return nil }
        let weeks = Double(selectedRange.days) / 7.0
        return change / weeks
    }

    // MARK: - Calorie Statistics

    /// Net calorie data points for chart (only days with tracked calories)
    var netCalorieDataPoints: [(date: Date, netCalories: Int)] {
        dailySummaries
            .filter { ($0.caloriesConsumed ?? 0) > 0 } // Only include days where food was logged
            .map { summary in
                (summary.date, summary.netCalories ?? summary.calculateNetCalories() ?? 0)
            }
            .sorted { $0.date < $1.date }
    }

    /// Average daily net calories (only for days with tracked calories)
    var averageDailyNetCalories: Int {
        guard !netCalorieDataPoints.isEmpty else { return 0 }
        let total = netCalorieDataPoints.reduce(0) { $0 + $1.netCalories }
        return total / netCalorieDataPoints.count // Use tracked days count, not all days
    }

    /// Total deficit/surplus (only for days with tracked calories)
    var totalNetCalories: Int {
        netCalorieDataPoints.reduce(0) { $0 + $1.netCalories }
    }

    /// Days in deficit (only counted for days with tracked calories)
    var daysInDeficit: Int {
        netCalorieDataPoints.filter { $0.netCalories < 0 }.count
    }

    /// Days in surplus (only counted for days with tracked calories)
    var daysInSurplus: Int {
        netCalorieDataPoints.filter { $0.netCalories > 0 }.count
    }

    // MARK: - Macro Statistics

    /// Daily macro data points (only days with tracked food)
    var macroDataPoints: [(date: Date, protein: Double, carbs: Double, fat: Double)] {
        dailySummaries
            .filter { ($0.caloriesConsumed ?? 0) > 0 } // Only include days where food was logged
            .map { summary in
                (
                    summary.date,
                    summary.proteinConsumed ?? 0,
                    summary.carbsConsumed ?? 0,
                    summary.fatConsumed ?? 0
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Average daily protein (only for days with tracked food)
    var averageDailyProtein: Double {
        guard !macroDataPoints.isEmpty else { return 0 }
        let total = macroDataPoints.reduce(0.0) { $0 + $1.protein }
        return total / Double(macroDataPoints.count)
    }

    /// Average daily carbs (only for days with tracked food)
    var averageDailyCarbs: Double {
        guard !macroDataPoints.isEmpty else { return 0 }
        let total = macroDataPoints.reduce(0.0) { $0 + $1.carbs }
        return total / Double(macroDataPoints.count)
    }

    /// Average daily fat (only for days with tracked food)
    var averageDailyFat: Double {
        guard !macroDataPoints.isEmpty else { return 0 }
        let total = macroDataPoints.reduce(0.0) { $0 + $1.fat }
        return total / Double(macroDataPoints.count)
    }

    // MARK: - Activity Statistics

    /// Total activities count
    var totalActivitiesCount: Int {
        activities.count
    }

    /// Total exercise calories burned
    var totalExerciseCalories: Int {
        activities.reduce(0) { $0 + $1.calories }
    }

    /// Activities by type
    var activitiesByType: [(type: String, count: Int)] {
        let grouped = Dictionary(grouping: activities) { $0.type }
        return grouped.map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Calories by activity type
    var caloriesByType: [(type: String, calories: Int)] {
        let grouped = Dictionary(grouping: activities) { $0.type }
        return grouped.map { (type: $0.key, calories: $0.value.reduce(0) { $0 + $1.calories }) }
            .sorted { $0.calories > $1.calories }
    }

    /// Most active day
    var mostActiveDay: (date: Date, count: Int)? {
        let grouped = Dictionary(grouping: activities) { Calendar.current.startOfDay(for: $0.startDate) }
        return grouped
            .map { (date: $0.key, count: $0.value.count) }
            .max { $0.count < $1.count }
    }

    /// Activity frequency (activities per day)
    var activityFrequency: Double {
        guard !dailySummaries.isEmpty else { return 0 }
        return Double(activities.count) / Double(selectedRange.days)
    }

    // MARK: - CSV Export

    /// Generate CSV data for weight
    func exportWeightCSV() -> String {
        var csv = "Date,Weight (kg)\n"
        for point in weightDataPoints {
            csv += "\(point.date.dateOnlyString),\(String(format: "%.2f", point.weight))\n"
        }
        return csv
    }

    /// Generate CSV data for calories
    func exportCaloriesCSV() -> String {
        var csv = "Date,Net Calories,Consumed,Burned\n"
        for summary in dailySummaries {
            let net = summary.netCalories ?? summary.calculateNetCalories() ?? 0
            let consumed = summary.caloriesConsumed ?? 0
            let burned = summary.totalCaloriesBurned ?? summary.calculateTotalCaloriesBurned() ?? 0
            csv += "\(summary.date.dateOnlyString),\(net),\(consumed),\(burned)\n"
        }
        return csv
    }

    /// Generate CSV data for macros
    func exportMacrosCSV() -> String {
        var csv = "Date,Protein (g),Carbs (g),Fat (g)\n"
        for summary in dailySummaries {
            let protein = summary.proteinConsumed ?? 0
            let carbs = summary.carbsConsumed ?? 0
            let fat = summary.fatConsumed ?? 0
            csv += "\(summary.date.dateOnlyString),\(String(format: "%.1f", protein)),\(String(format: "%.1f", carbs)),\(String(format: "%.1f", fat))\n"
        }
        return csv
    }

    /// Generate CSV data for activities
    func exportActivitiesCSV() -> String {
        var csv = "Date,Type,Name,Duration (min),Distance (km),Calories\n"
        for activity in activities {
            let duration = activity.duration / 60
            let distance = activity.distance != nil ? String(format: "%.2f", activity.distance! / 1000) : ""
            csv += "\(activity.startDate.dateOnlyString),\(activity.type),\(activity.name),\(duration),\(distance),\(activity.calories)\n"
        }
        return csv
    }
}
