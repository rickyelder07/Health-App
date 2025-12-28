//
//  CalendarView.swift
//  Health App
//
//  Calendar view for viewing daily summaries
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDayDetail = false

    var body: some View {
        NavigationView {
            Group {
                if let userId = appState.currentUser?.id {
                    CalendarContentView(userId: userId, showingDayDetail: $showingDayDetail)
                } else {
                    ProgressView("Loading...")
                }
            }
        }
    }
}

// MARK: - Calendar Content View

private struct CalendarContentView: View {
    let userId: UUID
    @Binding var showingDayDetail: Bool
    @StateObject private var viewModel: CalendarViewModel

    init(userId: UUID, showingDayDetail: Binding<Bool>) {
        self.userId = userId
        self._showingDayDetail = showingDayDetail
        _viewModel = StateObject(wrappedValue: CalendarViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month header with navigation
            MonthHeaderView(viewModel: viewModel)
                .padding()

            // Legend
            LegendView()
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Calendar grid
            if viewModel.isLoading && viewModel.daysInMonth.isEmpty {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Weekday headers
                        WeekdayHeadersView(headers: viewModel.weekdayHeaders)
                            .padding(.horizontal)

                        // Calendar grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                            spacing: 0
                        ) {
                            ForEach(viewModel.daysInMonth, id: \.self) { date in
                                CalendarDayCell(
                                    date: date,
                                    isInCurrentMonth: viewModel.isInCurrentMonth(date),
                                    isToday: viewModel.isToday(date),
                                    isSelected: viewModel.isSelected(date),
                                    indicators: viewModel.indicators(for: date)
                                )
                                .onTapGesture {
                                    viewModel.selectDate(date)
                                    showingDayDetail = true
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Error message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                        }
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDayDetail) {
            DayDetailView(
                userId: userId,
                date: viewModel.selectedDate,
                summary: viewModel.dailySummaries[viewModel.selectedDate]
            )
        }
        .task {
            await viewModel.loadMonth()
        }
    }
}

// MARK: - Month Header View

private struct MonthHeaderView: View {
    @ObservedObject var viewModel: CalendarViewModel

    var body: some View {
        HStack {
            // Previous month button
            Button(action: { viewModel.previousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }

            Spacer()

            // Month and year
            VStack(spacing: 2) {
                Text(viewModel.monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)

                if !viewModel.isToday(viewModel.currentMonth) {
                    Button(action: { viewModel.goToToday() }) {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }

            Spacer()

            // Next month button
            Button(action: { viewModel.nextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
        }
    }
}

// MARK: - Weekday Headers View

private struct WeekdayHeadersView: View {
    let headers: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(headers, id: \.self) { header in
                Text(header)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Legend View

private struct LegendView: View {
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(color: .green, text: "Deficit")
            LegendItem(color: .red, text: "Surplus")
            LegendItem(color: .blue, text: "Photo")
            LegendItem(color: .orange, text: "Activity")
        }
        .font(.caption2)
    }
}

private struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppState())
}
