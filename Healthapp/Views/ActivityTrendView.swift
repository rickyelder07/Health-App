//
//  ActivityTrendView.swift
//  Health App
//
//  Activity trend view with statistics and charts
//

import SwiftUI
import Charts

/// Activity trend view
struct ActivityTrendView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var showExportSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.activities.isEmpty {
                    EmptyActivityView()
                } else {
                    // Statistics cards
                    ActivityStatsGrid(viewModel: viewModel)
                        .padding(.horizontal)

                    // Activity type distribution
                    ActivityTypeChart(viewModel: viewModel)
                        .padding(.horizontal)

                    // Calories by type
                    CaloriesByTypeChart(viewModel: viewModel)
                        .padding(.horizontal)

                    // Activity frequency
                    ActivityFrequencySection(viewModel: viewModel)
                        .padding(.horizontal)

                    // Export button
                    ExportButton(title: "Export Activity Data") {
                        showExportSheet = true
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showExportSheet) {
            ActivityExportSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Activity Stats Grid

private struct ActivityStatsGrid: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Total Activities",
                value: "\(viewModel.totalActivitiesCount)",
                icon: "figure.run",
                color: .orange
            )

            StatCard(
                title: "Total Calories",
                value: "\(viewModel.totalExerciseCalories)",
                icon: "flame.fill",
                color: .red
            )

            StatCard(
                title: "Avg Frequency",
                value: String(format: "%.1f/day", viewModel.activityFrequency),
                icon: "calendar",
                color: .blue
            )

            if let mostActive = viewModel.mostActiveDay {
                StatCard(
                    title: "Most Active Day",
                    value: mostActive.date.displayString,
                    subtitle: "\(mostActive.count) activities",
                    icon: "star.fill",
                    color: .yellow
                )
            } else {
                StatCard(
                    title: "Most Active Day",
                    value: "--",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }
}

// MARK: - Activity Type Chart

private struct ActivityTypeChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities by Type")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.activitiesByType.isEmpty {
                Text("No activities to display")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                HStack(alignment: .top, spacing: 20) {
                    // Pie chart
                    Chart(viewModel.activitiesByType, id: \.type) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Type", item.type))
                        .cornerRadius(5)
                    }
                    .frame(width: 150, height: 150)

                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.activitiesByType.prefix(5), id: \.type) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForActivityType(item.type))
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.type)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("\(item.count) activities")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func colorForActivityType(_ type: String) -> Color {
        // Simple hash-based color assignment for consistency
        let colors: [Color] = [.orange, .blue, .green, .purple, .red, .pink, .cyan, .indigo]
        let index = abs(type.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Calories by Type Chart

private struct CaloriesByTypeChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calories by Activity Type")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.caloriesByType.isEmpty {
                Text("No calorie data to display")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Chart(viewModel.caloriesByType, id: \.type) { item in
                    BarMark(
                        x: .value("Calories", item.calories),
                        y: .value("Type", item.type)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let calories = value.as(Int.self) {
                                Text("\(calories)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: max(CGFloat(viewModel.caloriesByType.count) * 40, 150))
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Activity Frequency Section

private struct ActivityFrequencySection: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    private var dailyActivityCounts: [(date: String, count: Int)] {
        let grouped = Dictionary(grouping: viewModel.activities) {
            Calendar.current.startOfDay(for: $0.startDate)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return grouped
            .map { (date: formatter.string(from: $0.key), count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Frequency")
                .font(.headline)
                .fontWeight(.semibold)

            if dailyActivityCounts.isEmpty {
                Text("No frequency data to display")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Chart(dailyActivityCounts, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let count = value.as(Int.self) {
                                Text("\(count)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Export Button (reuse)

private struct ExportButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Activity Export Sheet

private struct ActivityExportSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Export Activity Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Copy the CSV data below or share it to another app.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView {
                    Text(viewModel.exportActivitiesCSV())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
                .padding(.horizontal)

                Button {
                    UIPasteboard.general.string = viewModel.exportActivitiesCSV()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy to Clipboard")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                ShareLink(item: viewModel.exportActivitiesCSV()) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share CSV")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Activity Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Sync your Strava activities to see trends and statistics.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    ActivityTrendView(viewModel: AnalyticsViewModel(userId: UUID()))
}
