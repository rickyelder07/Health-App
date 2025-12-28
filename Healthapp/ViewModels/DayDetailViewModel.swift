//
//  DayDetailViewModel.swift
//  Health App
//
//  ViewModel for day detail view
//

import Foundation
import Combine

/// ViewModel for detailed day view
@MainActor
class DayDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var summary: DailySummary?
    @Published var foodLogs: [FoodLog] = []
    @Published var activities: [Activity] = []
    @Published var progressPhoto: ProgressPhoto?
    @Published var weight: Double?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userId: UUID
    private let date: Date
    private let summaryService = DailySummaryService()
    private let foodService = FoodService()
    private let stravaService = StravaService()
    private let photoService = PhotoService()

    // MARK: - Initialization

    init(userId: UUID, date: Date, summary: DailySummary?) {
        self.userId = userId
        self.date = date
        self.summary = summary
        self.weight = summary?.weight
    }

    // MARK: - Public Methods

    /// Load all data for the day
    func loadDayData() async {
        isLoading = true
        errorMessage = nil

        async let summaryTask = loadSummary()
        async let foodTask = loadFoodLogs()
        async let activitiesTask = loadActivities()
        async let photoTask = loadProgressPhoto()

        // Wait for all tasks to complete
        _ = await (summaryTask, foodTask, activitiesTask, photoTask)

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await loadDayData()
    }

    // MARK: - Private Methods

    /// Load daily summary if not provided
    private func loadSummary() async {
        guard summary == nil else { return }

        do {
            summary = try await summaryService.fetchSummary(userId: userId, date: date)

            // If still no summary, try to calculate it
            if summary == nil {
                summary = try await summaryService.calculateAndUpdateSummary(userId: userId, date: date)
            }

            weight = summary?.weight
        } catch {
            print("❌ Error loading summary: \(error)")
            // Don't set error message for missing summary - it's normal for future dates
        }
    }

    /// Load food logs for the day
    private func loadFoodLogs() async {
        do {
            foodLogs = try await foodService.fetchFoodLogs(userId: userId, date: date)
            print("✅ Loaded \(foodLogs.count) food logs for day")
        } catch {
            print("❌ Error loading food logs: \(error)")
            errorMessage = "Failed to load food logs"
        }
    }

    /// Load activities for the day
    private func loadActivities() async {
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            activities = try await stravaService.fetchActivitiesFromDatabase(
                userId: userId,
                startDate: startOfDay,
                endDate: endOfDay
            )
            print("✅ Loaded \(activities.count) activities for day")
        } catch {
            print("❌ Error loading activities: \(error)")
            // Don't show error - activities are optional
        }
    }

    /// Load progress photo for the day
    private func loadProgressPhoto() async {
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let photos = try await photoService.fetchPhotos(
                userId: userId,
                startDate: startOfDay,
                endDate: endOfDay
            )

            progressPhoto = photos.first
            print("✅ Loaded progress photo: \(progressPhoto != nil)")
        } catch {
            print("❌ Error loading progress photo: \(error)")
            // Don't show error - photos are optional
        }
    }
}
