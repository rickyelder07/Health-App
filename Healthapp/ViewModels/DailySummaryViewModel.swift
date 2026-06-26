//
//  DailySummaryViewModel.swift
//  Netfuel
//
//  ViewModel for managing daily summary state and calculations
//

import Foundation
import Combine

/// ViewModel for daily summary management
@MainActor
class DailySummaryViewModel: ObservableObject {
    @Published var currentSummary: DailySummary?
    @Published var summaries: [DailySummary] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let summaryService = DailySummaryService.shared
    private let userId: UUID

    init(userId: UUID) {
        self.userId = userId
    }

    // MARK: - Fetch Operations

    /// Load today's summary
    func loadTodaySummary() async {
        await loadSummary(for: Date())
    }

    /// Load summary for a specific date
    func loadSummary(for date: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            currentSummary = try await summaryService.fetchSummary(userId: userId, date: date)

            // If no summary exists, create one with zeros
            if currentSummary == nil {
                currentSummary = try await summaryService.calculateAndUpdateSummary(
                    userId: userId,
                    date: date
                )
            }
        } catch {
            errorMessage = "Failed to load daily summary: \(error.localizedDescription)"
            print("❌ Error loading summary: \(error)")
        }

        isLoading = false
    }

    /// Load summaries for a date range
    func loadSummaries(startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            summaries = try await summaryService.fetchSummaries(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            errorMessage = "Failed to load summaries: \(error.localizedDescription)"
            print("❌ Error loading summaries: \(error)")
        }

        isLoading = false
    }

    /// Load current week's summaries
    func loadWeekSummaries() async {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return
        }

        await loadSummaries(startDate: weekStart, endDate: weekEnd)
    }

    /// Load current month's summaries
    func loadMonthSummaries() async {
        let calendar = Calendar.current
        let today = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return
        }

        await loadSummaries(startDate: monthStart, endDate: monthEnd)
    }

    // MARK: - Recalculation Triggers

    /// Recalculate summary after food log change
    /// This is called when user logs food or deletes food
    func recalculateAfterFoodChange(date: Date = Date()) async {
        isLoading = true
        errorMessage = nil

        do {
            try await summaryService.updateFoodConsumption(userId: userId, date: date)

            // Refresh current summary if it's for the same date
            if calendar.isDate(date, inSameDayAs: currentSummary?.date ?? Date.distantPast) {
                currentSummary = try await summaryService.fetchSummary(userId: userId, date: date)
            }
        } catch {
            errorMessage = "Failed to update summary: \(error.localizedDescription)"
            print("❌ Error recalculating after food change: \(error)")
        }

        isLoading = false
    }

    /// Recalculate summary after activity sync
    /// This is called when Strava activities are synced
    func recalculateAfterActivitySync(dates: [Date]) async {
        isLoading = true
        errorMessage = nil

        do {
            // Update summaries for all affected dates
            for date in dates {
                try await summaryService.updateExerciseCalories(userId: userId, date: date)
            }

            // Refresh current summary if it's in the affected dates
            if let current = currentSummary,
               dates.contains(where: { calendar.isDate($0, inSameDayAs: current.date) }) {
                currentSummary = try await summaryService.fetchSummary(userId: userId, date: current.date)
            }
        } catch {
            errorMessage = "Failed to update summary: \(error.localizedDescription)"
            print("❌ Error recalculating after activity sync: \(error)")
        }

        isLoading = false
    }

    /// Recalculate summary after profile update (BMR/TDEE changed)
    /// This should recalculate all recent summaries with new BMR
    func recalculateAfterProfileUpdate(newBMR: Double, newTDEE: Double) async {
        isLoading = true
        errorMessage = nil

        do {
            // Recalculate last 30 days of summaries
            let calendar = Calendar.current
            let today = Date()
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
                return
            }

            // Get all dates with existing summaries
            let existingSummaries = try await summaryService.fetchSummaries(
                userId: userId,
                startDate: thirtyDaysAgo,
                endDate: today
            )

            // Recalculate each one
            for summary in existingSummaries {
                try await summaryService.calculateAndUpdateSummary(
                    userId: userId,
                    date: summary.date,
                    userBMR: newBMR,
                    userTDEE: newTDEE
                )
            }

            // Refresh current summary
            if let current = currentSummary {
                currentSummary = try await summaryService.fetchSummary(userId: userId, date: current.date)
            }
        } catch {
            errorMessage = "Failed to recalculate summaries: \(error.localizedDescription)"
            print("❌ Error recalculating after profile update: \(error)")
        }

        isLoading = false
    }

    /// Force full recalculation of a specific date
    /// This recalculates everything from scratch
    func forceRecalculate(date: Date = Date()) async {
        isLoading = true
        errorMessage = nil

        do {
            currentSummary = try await summaryService.calculateAndUpdateSummary(
                userId: userId,
                date: date
            )
        } catch {
            errorMessage = "Failed to recalculate summary: \(error.localizedDescription)"
            print("❌ Error force recalculating: \(error)")
        }

        isLoading = false
    }

    // MARK: - Refresh

    /// Refresh current summary
    func refresh() async {
        if let current = currentSummary {
            await loadSummary(for: current.date)
        } else {
            await loadTodaySummary()
        }
    }

    // MARK: - Helpers

    private var calendar: Calendar {
        return Calendar.current
    }
}

