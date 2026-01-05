//
//  AnalyticsView.swift
//  Netfuel
//
//  Main analytics view with tabs for different trend views
//

import SwiftUI

/// Tab selection for analytics
enum AnalyticsTab: String, CaseIterable {
    case weight = "Weight"
    case calories = "Calories"
    case macros = "Macros"
    case activities = "Activities"

    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .calories: return "flame.fill"
        case .macros: return "chart.pie.fill"
        case .activities: return "figure.run"
        }
    }
}

/// Main analytics view
struct AnalyticsView: View {
    let userId: UUID

    var body: some View {
        AnalyticsContentView(userId: userId)
    }
}

/// Content view with state management
private struct AnalyticsContentView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var selectedTab: AnalyticsTab = .weight

    init(userId: UUID) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date range picker
                DateRangePicker(selectedRange: $viewModel.selectedRange)
                    .padding()
                    .background(Color(.systemBackground))

                // Tab selector
                TabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                // Content
                if viewModel.isLoading {
                    LoadingView(message: "Loading analytics...")
                } else if !viewModel.dailySummaries.isEmpty || !viewModel.activities.isEmpty {
                    TabView(selection: $selectedTab) {
                        WeightTrendView(viewModel: viewModel)
                            .tag(AnalyticsTab.weight)

                        CalorieTrendView(viewModel: viewModel)
                            .tag(AnalyticsTab.calories)

                        MacroTrendView(viewModel: viewModel)
                            .tag(AnalyticsTab.macros)

                        ActivityTrendView(viewModel: viewModel)
                            .tag(AnalyticsTab.activities)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    EmptyAnalyticsView()
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: viewModel.selectedRange) { _, _ in
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
}

// MARK: - Date Range Picker

private struct DateRangePicker: View {
    @Binding var selectedRange: TimeRange

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedRange == range ? .semibold : .regular)
                        .foregroundColor(selectedRange == range ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedRange == range ?
                                AnyView(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )) :
                                AnyView(Color(.systemGray5))
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Tab Selector

private struct TabSelector: View {
    @Binding var selectedTab: AnalyticsTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ?
                                Color.blue.opacity(0.1) :
                                Color.clear
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedTab == tab ? Color.blue : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Data Available")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start logging your food, weight, and activities to see trends and analytics.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AnalyticsView(userId: UUID())
}
