//
//  CalorieTrendView.swift
//  Netfuel
//
//  Calorie trend view with bar chart and statistics
//

import SwiftUI
import Charts

/// Calorie trend view
struct CalorieTrendView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var showExportSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.netCalorieDataPoints.isEmpty {
                    EmptyCalorieView()
                } else {
                    // Statistics cards
                    CalorieStatsGrid(viewModel: viewModel)
                        .padding(.horizontal)

                    // Bar chart
                    NetCalorieChart(dataPoints: viewModel.netCalorieDataPoints)
                        .padding(.horizontal)

                    // Weekly summary
                    WeeklySummary(viewModel: viewModel)
                        .padding(.horizontal)

                    // Export button
                    ExportButton(title: "Export Calorie Data") {
                        showExportSheet = true
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showExportSheet) {
            CalorieExportSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Calorie Stats Grid

private struct CalorieStatsGrid: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Avg Daily Net",
                value: String(format: "%+d cal", viewModel.averageDailyNetCalories),
                icon: "flame.fill",
                color: viewModel.averageDailyNetCalories < 0 ? .green : .red
            )

            StatCard(
                title: "Total Net",
                value: String(format: "%+d cal", viewModel.totalNetCalories),
                icon: "sum",
                color: viewModel.totalNetCalories < 0 ? .green : .red
            )

            StatCard(
                title: "Days in Deficit",
                value: "\(viewModel.daysInDeficit)",
                icon: "arrow.down.circle.fill",
                color: .green
            )

            StatCard(
                title: "Days in Surplus",
                value: "\(viewModel.daysInSurplus)",
                icon: "arrow.up.circle.fill",
                color: .red
            )
        }
    }
}

// MARK: - Net Calorie Chart

private struct NetCalorieChart: View {
    let dataPoints: [(date: Date, netCalories: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Net Calories by Day")
                .font(.headline)
                .fontWeight(.semibold)

            Chart {
                ForEach(dataPoints, id: \.date) { point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Net Calories", point.netCalories)
                    )
                    .foregroundStyle(point.netCalories < 0 ? Color.green : Color.red)
                    .cornerRadius(4)
                }

                // Zero line
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
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
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Weekly Summary

private struct WeeklySummary: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    private var weeklyData: [(week: String, avgNet: Int)] {
        // Group data by week
        let grouped = Dictionary(grouping: viewModel.netCalorieDataPoints) { point in
            Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: point.date)
        }

        return grouped.map { key, points in
            let avg = points.reduce(0) { $0 + $1.netCalories } / points.count
            let weekStart = Calendar.current.date(from: key) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return (week: formatter.string(from: weekStart), avgNet: avg)
        }
        .sorted { $0.week < $1.week }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Average")
                .font(.headline)
                .fontWeight(.semibold)

            if weeklyData.isEmpty {
                Text("Need more data for weekly analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Chart {
                    ForEach(weeklyData, id: \.week) { data in
                        BarMark(
                            x: .value("Week", data.week),
                            y: .value("Avg Net", data.avgNet)
                        )
                        .foregroundStyle(data.avgNet < 0 ? Color.green.gradient : Color.red.gradient)
                        .cornerRadius(6)
                    }

                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartYAxis {
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

// MARK: - Stat Card (reuse from WeightTrendView)

private struct StatCard: View {
    let title: String
    let value: String
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

// MARK: - Calorie Export Sheet

private struct CalorieExportSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Export Calorie Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Copy the CSV data below or share it to another app.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView {
                    Text(viewModel.exportCaloriesCSV())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
                .padding(.horizontal)

                Button {
                    UIPasteboard.general.string = viewModel.exportCaloriesCSV()
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

                ShareLink(item: viewModel.exportCaloriesCSV()) {
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

private struct EmptyCalorieView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Calorie Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start logging your food and activities to see calorie trends.")
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
    CalorieTrendView(viewModel: AnalyticsViewModel(userId: UUID()))
}
