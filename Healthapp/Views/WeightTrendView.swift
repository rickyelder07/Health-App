//
//  WeightTrendView.swift
//  Netfuel
//
//  Weight trend view with line chart and statistics
//

import SwiftUI
import Charts

/// Weight trend view
struct WeightTrendView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var showExportSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.weightDataPoints.isEmpty {
                    EmptyWeightView()
                } else {
                    // Statistics cards
                    WeightStatsGrid(viewModel: viewModel)
                        .padding(.horizontal)

                    // Line chart
                    WeightChart(dataPoints: viewModel.weightDataPoints)
                        .padding(.horizontal)

                    // Export button
                    ExportButton(title: "Export Weight Data") {
                        showExportSheet = true
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(
                title: "Weight Data",
                csvData: viewModel.exportWeightCSV(),
                filename: "weight_data.csv"
            )
        }
    }
}

// MARK: - Weight Stats Grid

private struct WeightStatsGrid: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Starting Weight",
                value: viewModel.startingWeight != nil ? UnitFormatter.formatWeight(viewModel.startingWeight!) : "--",
                icon: "arrow.left.circle.fill",
                color: .blue
            )

            StatCard(
                title: "Current Weight",
                value: viewModel.currentWeight != nil ? UnitFormatter.formatWeight(viewModel.currentWeight!) : "--",
                icon: "scalemass.fill",
                color: .green
            )

            StatCard(
                title: "Total Change",
                value: viewModel.weightChange != nil ? UnitFormatter.formatWeightChange(viewModel.weightChange!) : "--",
                icon: viewModel.weightChange ?? 0 < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill",
                color: viewModel.weightChange ?? 0 < 0 ? .green : .red
            )

            StatCard(
                title: "Weekly Avg",
                value: viewModel.averageWeeklyChange != nil ? UnitFormatter.formatWeightChange(viewModel.averageWeeklyChange!, decimals: 2) + "/week" : "--",
                icon: "calendar",
                color: .orange
            )
        }
    }
}

// MARK: - Weight Chart

private struct WeightChart: View {
    let dataPoints: [(date: Date, weight: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Trend")
                .font(.headline)
                .fontWeight(.semibold)

            Chart {
                ForEach(dataPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
            }
            .chartXAxis {
                AxisMarks(values: dataPoints.map(\.date)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text(UnitFormatter.formatWeight(weight))
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

// MARK: - Stat Card

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

// MARK: - Export Button

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

// MARK: - Export Sheet

private struct ExportSheet: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let csvData: String
    let filename: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Export \(title)")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Copy the CSV data below or share it to another app.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView {
                    Text(csvData)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
                .padding(.horizontal)

                Button {
                    UIPasteboard.general.string = csvData
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

                ShareLink(item: csvData) {
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

private struct EmptyWeightView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Weight Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start logging your daily weight to see trends and progress.")
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
    WeightTrendView(viewModel: AnalyticsViewModel(userId: UUID()))
}
