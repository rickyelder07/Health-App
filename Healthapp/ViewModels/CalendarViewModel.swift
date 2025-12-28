//
//  CalendarViewModel.swift
//  Health App
//
//  ViewModel for calendar view and day navigation
//

import Foundation
import Combine

/// Day indicators for calendar display
struct DayIndicators {
    let date: Date
    var hasDeficit: Bool = false
    var hasSurplus: Bool = false
    var hasProgressPhoto: Bool = false
    var hasActivity: Bool = false
    var dailySummary: DailySummary?

    var hasAnyData: Bool {
        return hasDeficit || hasSurplus || hasProgressPhoto || hasActivity
    }
}

/// ViewModel for calendar navigation and daily summaries
@MainActor
class CalendarViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()
    @Published var dailySummaries: [Date: DailySummary] = [:]
    @Published var dayIndicators: [Date: DayIndicators] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userId: UUID
    private let summaryService = DailySummaryService()
    private let calendar = Calendar.current

    // MARK: - Computed Properties

    /// Days to display in the current month view (including padding)
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let monthStart = monthInterval.start
        let monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!

        // Get first day of week for the month
        let firstWeekday = calendar.component(.weekday, from: monthStart)

        // Calculate padding days at start (Sunday = 1, so we need firstWeekday - 1 days)
        let paddingDays = firstWeekday - 1

        // Get all days in month
        let daysInMonth = calendar.component(.day, from: monthEnd)

        // Calculate total days including padding
        var days: [Date] = []

        // Add padding days from previous month
        for dayOffset in (1...paddingDays).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: monthStart) {
                days.append(date)
            }
        }

        // Add all days in current month
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: monthStart) {
                days.append(date)
            }
        }

        // Add padding days from next month to complete the grid (42 days = 6 weeks)
        let remainingDays = 42 - days.count
        for day in 1...remainingDays {
            if let date = calendar.date(byAdding: .day, value: day, to: monthEnd) {
                days.append(date)
            }
        }

        return days
    }

    /// Month name and year for display
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    /// Weekday headers (Sun, Mon, Tue, etc.)
    var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }

    // MARK: - Initialization

    init(userId: UUID) {
        self.userId = userId
    }

    // MARK: - Public Methods

    /// Load data for current month
    func loadMonth() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get month date range
            guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
                throw CalendarError.invalidDate
            }

            // Fetch summaries for the month
            let summaries = try await summaryService.fetchSummaries(
                userId: userId,
                startDate: monthInterval.start,
                endDate: monthInterval.end
            )

            // Store summaries by date
            dailySummaries = Dictionary(
                uniqueKeysWithValues: summaries.map { (calendar.startOfDay(for: $0.date), $0) }
            )

            // Fetch progress photos for the month
            let photoService = PhotoService()
            let photos = try await photoService.fetchPhotos(
                userId: userId,
                startDate: monthInterval.start,
                endDate: monthInterval.end
            )

            // Fetch activities for the month (if any)
            let stravaService = StravaService()
            let activities = try await stravaService.fetchActivitiesFromDatabase(
                userId: userId,
                startDate: monthInterval.start,
                endDate: monthInterval.end
            )

            // Build day indicators
            buildDayIndicators(summaries: summaries, photos: photos, activities: activities)

        } catch {
            errorMessage = "Failed to load month data: \(error.localizedDescription)"
            print("❌ Error loading month: \(error)")
        }

        isLoading = false
    }

    /// Navigate to previous month
    func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
            return
        }
        currentMonth = newMonth
        Task {
            await loadMonth()
        }
    }

    /// Navigate to next month
    func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return
        }
        currentMonth = newMonth
        Task {
            await loadMonth()
        }
    }

    /// Jump to today
    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
        Task {
            await loadMonth()
        }
    }

    /// Select a specific date
    func selectDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
    }

    /// Get indicators for a specific date
    func indicators(for date: Date) -> DayIndicators? {
        let normalizedDate = calendar.startOfDay(for: date)
        return dayIndicators[normalizedDate]
    }

    /// Check if date is in current month
    func isInCurrentMonth(_ date: Date) -> Bool {
        return calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    /// Check if date is selected
    func isSelected(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }

    /// Check if date is today
    func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }

    // MARK: - Private Methods

    /// Build day indicators from data
    private func buildDayIndicators(
        summaries: [DailySummary],
        photos: [ProgressPhoto],
        activities: [Activity]
    ) {
        var indicators: [Date: DayIndicators] = [:]

        // Process summaries
        for summary in summaries {
            let date = calendar.startOfDay(for: summary.date)
            var indicator = indicators[date] ?? DayIndicators(date: date)

            indicator.dailySummary = summary

            // Check for surplus/deficit
            let netCalories = summary.netCalories ?? summary.calculateNetCalories()
            if netCalories > 0 {
                indicator.hasSurplus = true
            } else if netCalories < 0 {
                indicator.hasDeficit = true
            }

            indicators[date] = indicator
        }

        // Process photos
        for photo in photos {
            let date = calendar.startOfDay(for: photo.takenAt)
            var indicator = indicators[date] ?? DayIndicators(date: date)
            indicator.hasProgressPhoto = true
            indicators[date] = indicator
        }

        // Process activities
        for activity in activities {
            let date = calendar.startOfDay(for: activity.startDate)
            var indicator = indicators[date] ?? DayIndicators(date: date)
            indicator.hasActivity = true
            indicators[date] = indicator
        }

        self.dayIndicators = indicators
    }
}

// MARK: - Calendar Error

enum CalendarError: LocalizedError {
    case invalidDate
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Invalid date provided"
        case .loadFailed:
            return "Failed to load calendar data"
        }
    }
}
