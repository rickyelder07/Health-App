//
//  DayDetailView.swift
//  Health App
//
//  Detailed view for a specific day's data
//

import SwiftUI

struct DayDetailView: View {
    let userId: UUID
    let date: Date
    let summary: DailySummary?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DayDetailViewModel

    init(userId: UUID, date: Date, summary: DailySummary?) {
        self.userId = userId
        self.date = date
        self.summary = summary
        _viewModel = StateObject(wrappedValue: DayDetailViewModel(userId: userId, date: date, summary: summary))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date header
                    DateHeaderView(date: date, weight: viewModel.weight)

                    // Net calories card
                    if let summary = viewModel.summary {
                        NetCaloriesCard(summary: summary)
                            .padding(.horizontal)
                    }

                    // Macro summary using existing component
                    if let summary = viewModel.summary {
                        DayMacroSummary(summary: summary)
                            .padding(.horizontal)
                    }

                    // Food logs
                    if !viewModel.foodLogs.isEmpty {
                        FoodLogsSection(foodLogs: viewModel.foodLogs)
                            .padding(.horizontal)
                    }

                    // Activities
                    if !viewModel.activities.isEmpty {
                        ActivitiesSection(activities: viewModel.activities)
                            .padding(.horizontal)
                    }

                    // Progress photo
                    if let photo = viewModel.progressPhoto {
                        ProgressPhotoSection(photo: photo)
                            .padding(.horizontal)
                    }

                    // Empty state
                    if viewModel.summary == nil && !viewModel.isLoading {
                        EmptyDayView()
                            .padding()
                    }

                    // Loading indicator
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }

                    Spacer(minLength: 80)
                }
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadDayData()
            }
        }
    }
}

// MARK: - Date Header View

private struct DateHeaderView: View {
    let date: Date
    let weight: Double?

    var body: some View {
        VStack(spacing: 8) {
            Text(date.displayString)
                .font(.title2)
                .fontWeight(.bold)

            if date.isToday {
                Text("Today")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            } else if date.isYesterday {
                Text("Yesterday")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let weight = weight {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass")
                        .font(.caption)
                    Text(String(format: "%.1f kg", weight))
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
}

// MARK: - Net Calories Card

private struct NetCaloriesCard: View {
    let summary: DailySummary

    var netCalories: Int {
        summary.netCalories ?? summary.calculateNetCalories()
    }

    var totalBurned: Int {
        summary.totalCaloriesBurned ?? summary.calculateTotalCaloriesBurned()
    }

    var isInSurplus: Bool {
        netCalories > 0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Net calories display
            VStack(spacing: 4) {
                Text("\(abs(netCalories))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(isInSurplus ? .red : .green)

                Text(isInSurplus ? "Calorie Surplus" : "Calorie Deficit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Stats breakdown
            HStack(spacing: 40) {
                StatColumn(
                    icon: "fork.knife",
                    color: .blue,
                    value: summary.caloriesConsumed,
                    label: "Consumed"
                )

                StatColumn(
                    icon: "flame.fill",
                    color: .orange,
                    value: totalBurned,
                    label: "Burned"
                )

                StatColumn(
                    icon: "figure.run",
                    color: .green,
                    value: summary.caloriesBurnedExercise,
                    label: "Exercise"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

private struct StatColumn: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Day Macro Summary (renamed to avoid conflict)

private struct DayMacroSummary: View {
    let summary: DailySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrients")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DayMacroProgressBar(
                    name: "Protein",
                    value: summary.proteinConsumed,
                    color: .red
                )

                DayMacroProgressBar(
                    name: "Carbs",
                    value: summary.carbsConsumed,
                    color: .blue
                )

                DayMacroProgressBar(
                    name: "Fat",
                    value: summary.fatConsumed,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

private struct DayMacroProgressBar: View {
    let name: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(String(format: "%.1f g", value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(color)
                        .frame(width: min(geometry.size.width * CGFloat(value / 200.0), geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Food Logs Section

private struct FoodLogsSection: View {
    let foodLogs: [FoodLog]

    var groupedLogs: [(MealType, [FoodLog])] {
        Dictionary(grouping: foodLogs) { $0.mealType ?? .snack }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Food Logs")
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(groupedLogs, id: \.0) { mealType, logs in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: mealType.icon)
                            .foregroundColor(.accentColor)
                        Text(mealType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("\(logs.reduce(0) { $0 + Int($1.totalCalories) }) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ForEach(logs) { log in
                        DayFoodLogRow(log: log)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

private struct DayFoodLogRow: View {
    let log: FoodLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let brand = log.brandName {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(log.servingDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(log.totalCalories)) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(String(format: "P: %.0fg", log.totalProtein))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Activities Section

private struct ActivitiesSection: View {
    let activities: [Activity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.orange)
                Text("Activities")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            ForEach(activities) { activity in
                DayActivityRow(activity: activity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

private struct DayActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    if let distance = activity.distance {
                        Label(String(format: "%.1f km", distance / 1000), systemImage: "location")
                            .font(.caption)
                    }

                    Label(formatDuration(activity.duration), systemImage: "timer")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(activity.calories)) cal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Progress Photo Section

private struct ProgressPhotoSection: View {
    let photo: ProgressPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera")
                    .foregroundColor(.blue)
                Text("Progress Photo")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            AsyncImage(url: URL(string: photo.photoUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 200)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                @unknown default:
                    EmptyView()
                }
            }

            if let notes = photo.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Empty Day View

private struct EmptyDayView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No data for this day")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Start tracking by logging food or activities")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    DayDetailView(
        userId: UUID(),
        date: Date(),
        summary: DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 70.0,
            caloriesConsumed: 1800,
            proteinConsumed: 150,
            carbsConsumed: 200,
            fatConsumed: 60,
            caloriesBurnedBmr: 1600,
            caloriesBurnedExercise: 400,
            totalCaloriesBurned: 2000,
            netCalories: -200,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
