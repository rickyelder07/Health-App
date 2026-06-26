//
//  MacroTrendView.swift
//  Netfuel
//
//  Macro trend view with line/stacked charts and statistics
//

import SwiftUI
import Charts

/// Macro trend view
struct MacroTrendView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var showExportSheet = false
    @State private var selectedChartType: MacroChartType = .line

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.macroDataPoints.isEmpty {
                    EmptyMacroView()
                } else {
                    // Statistics cards
                    MacroStatsGrid(viewModel: viewModel)
                        .padding(.horizontal)

                    // Chart type picker
                    ChartTypePicker(selectedType: $selectedChartType)
                        .padding(.horizontal)

                    // Chart
                    if selectedChartType == .line {
                        MacroLineChart(dataPoints: viewModel.macroDataPoints)
                            .padding(.horizontal)
                    } else {
                        MacroStackedChart(dataPoints: viewModel.macroDataPoints)
                            .padding(.horizontal)
                    }

                    // Export button
                    ExportButton(title: "Export Macro Data") {
                        showExportSheet = true
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showExportSheet) {
            MacroExportSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Chart Type

enum MacroChartType: String, CaseIterable {
    case line = "Line Chart"
    case stacked = "Stacked Chart"
}

// MARK: - Chart Type Picker

private struct ChartTypePicker: View {
    @Binding var selectedType: MacroChartType

    var body: some View {
        HStack(spacing: 12) {
            ForEach(MacroChartType.allCases, id: \.self) { type in
                Button {
                    selectedType = type
                } label: {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedType == type ? .semibold : .regular)
                        .foregroundColor(selectedType == type ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedType == type ?
                                Color.blue :
                                Color(.systemGray5)
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Macro Stats Grid

private struct MacroStatsGrid: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Avg Protein",
                    value: String(format: "%.1f g", viewModel.averageDailyProtein),
                    icon: "flame.fill",
                    color: .red
                )

                StatCard(
                    title: "Avg Carbs",
                    value: String(format: "%.1f g", viewModel.averageDailyCarbs),
                    icon: "leaf.fill",
                    color: .blue
                )

                StatCard(
                    title: "Avg Fat",
                    value: String(format: "%.1f g", viewModel.averageDailyFat),
                    icon: "drop.fill",
                    color: .purple
                )
            }

            // Macro ratio card
            MacroRatioCard(viewModel: viewModel)
        }
    }
}

// MARK: - Macro Ratio Card

private struct MacroRatioCard: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    private var totalMacroGrams: Double {
        viewModel.averageDailyProtein + viewModel.averageDailyCarbs + viewModel.averageDailyFat
    }

    private var proteinPercentage: Double {
        guard totalMacroGrams > 0 else { return 0 }
        return (viewModel.averageDailyProtein / totalMacroGrams) * 100
    }

    private var carbsPercentage: Double {
        guard totalMacroGrams > 0 else { return 0 }
        return (viewModel.averageDailyCarbs / totalMacroGrams) * 100
    }

    private var fatPercentage: Double {
        guard totalMacroGrams > 0 else { return 0 }
        return (viewModel.averageDailyFat / totalMacroGrams) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Macro Distribution")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Visual bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * (proteinPercentage / 100))

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * (carbsPercentage / 100))

                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * (fatPercentage / 100))
                }
                .cornerRadius(4)
            }
            .frame(height: 12)

            // Percentages
            HStack {
                MacroPercentageLabel(name: "Protein", percentage: proteinPercentage, color: .red)
                Spacer()
                MacroPercentageLabel(name: "Carbs", percentage: carbsPercentage, color: .blue)
                Spacer()
                MacroPercentageLabel(name: "Fat", percentage: fatPercentage, color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

private struct MacroPercentageLabel: View {
    let name: String
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f%%", percentage))
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Macro Line Chart

private struct MacroLineChart: View {
    let dataPoints: [(date: Date, protein: Double, carbs: Double, fat: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macros Over Time")
                .font(.headline)
                .fontWeight(.semibold)

            Chart {
                // Protein line
                ForEach(dataPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Grams", point.protein)
                    )
                    .foregroundStyle(.red)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                }
                .foregroundStyle(by: .value("Macro", "Protein"))

                // Carbs line
                ForEach(dataPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Grams", point.carbs)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.square)
                    .interpolationMethod(.catmullRom)
                }
                .foregroundStyle(by: .value("Macro", "Carbs"))

                // Fat line
                ForEach(dataPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Grams", point.fat)
                    )
                    .foregroundStyle(.purple)
                    .symbol(.triangle)
                    .interpolationMethod(.catmullRom)
                }
                .foregroundStyle(by: .value("Macro", "Fat"))
            }
            .chartForegroundStyleScale([
                "Protein": .red,
                "Carbs": .blue,
                "Fat": .purple
            ])
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
                        if let grams = value.as(Double.self) {
                            Text("\(Int(grams))g")
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

// MARK: - Macro Stacked Chart

private struct MacroStackedChart: View {
    let dataPoints: [(date: Date, protein: Double, carbs: Double, fat: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macros Stacked")
                .font(.headline)
                .fontWeight(.semibold)

            Chart {
                ForEach(dataPoints, id: \.date) { point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Grams", point.protein)
                    )
                    .foregroundStyle(.red)
                    .position(by: .value("Macro", "Protein"))

                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Grams", point.carbs)
                    )
                    .foregroundStyle(.blue)
                    .position(by: .value("Macro", "Carbs"))

                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Grams", point.fat)
                    )
                    .foregroundStyle(.purple)
                    .position(by: .value("Macro", "Fat"))
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
                        if let grams = value.as(Double.self) {
                            Text("\(Int(grams))g")
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

// MARK: - Stat Card (reuse)

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

// MARK: - Macro Export Sheet

private struct MacroExportSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Export Macro Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Copy the CSV data below or share it to another app.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView {
                    Text(viewModel.exportMacrosCSV())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
                .padding(.horizontal)

                Button {
                    UIPasteboard.general.string = viewModel.exportMacrosCSV()
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

                ShareLink(item: viewModel.exportMacrosCSV()) {
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

private struct EmptyMacroView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Macro Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start logging your food to see macro trends and distribution.")
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
    MacroTrendView(viewModel: AnalyticsViewModel(userId: UUID()))
}
