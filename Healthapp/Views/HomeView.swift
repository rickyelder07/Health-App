//
//  HomeView.swift
//  Health App
//
//  Home dashboard displaying today's summary and quick actions
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingStravaSync = false
    @State private var showingAddFood = false
    @State private var showingAddPhoto = false

    var body: some View {
        NavigationView {
            Group {
                if let userId = appState.currentUser?.id {
                    HomeContentView(
                        userId: userId,
                        showingAddFood: $showingAddFood,
                        showingAddPhoto: $showingAddPhoto,
                        showingStravaSync: $showingStravaSync
                    )
                } else {
                    ProgressView("Loading user...")
                }
            }
        }
    }
}

// MARK: - Home Content View

private struct HomeContentView: View {
    let userId: UUID
    @Binding var showingAddFood: Bool
    @Binding var showingAddPhoto: Bool
    @Binding var showingStravaSync: Bool

    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject var appState: AppState

    init(
        userId: UUID,
        showingAddFood: Binding<Bool>,
        showingAddPhoto: Binding<Bool>,
        showingStravaSync: Binding<Bool>
    ) {
        self.userId = userId
        self._showingAddFood = showingAddFood
        self._showingAddPhoto = showingAddPhoto
        self._showingStravaSync = showingStravaSync
        _viewModel = StateObject(wrappedValue: HomeViewModel(userId: userId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome header
                WelcomeHeader(
                    userName: appState.currentUser?.email?.components(separatedBy: "@").first?.capitalized,
                    weight: viewModel.currentWeight
                )
                .padding(.horizontal)
                .padding(.top)

                // Net calories card
                if let summary = viewModel.dailySummary {
                    NetCaloriesDashboardCard(
                        netCalories: viewModel.netCalories,
                        isInSurplus: viewModel.isInSurplus,
                        caloriesConsumed: viewModel.caloriesConsumed,
                        caloriesBurned: viewModel.caloriesBurned
                    )
                    .padding(.horizontal)
                }

                // Calories progress (circular)
                if let summary = viewModel.dailySummary {
                    CaloriesProgressCard(
                        current: viewModel.caloriesConsumed,
                        target: viewModel.calorieTarget,
                        burned: viewModel.caloriesBurned
                    )
                    .padding(.horizontal)
                }

                // Macros progress
                if let summary = viewModel.dailySummary {
                    MacrosSection(
                        proteinCurrent: summary.proteinConsumed,
                        proteinTarget: viewModel.proteinTarget,
                        carbsCurrent: summary.carbsConsumed,
                        carbsTarget: viewModel.carbsTarget,
                        fatCurrent: summary.fatConsumed,
                        fatTarget: viewModel.fatTarget
                    )
                    .padding(.horizontal)
                }

                // Activity summary
                if !viewModel.activities.isEmpty {
                    ActivitySummarySection(
                        activities: viewModel.activities,
                        totalCalories: viewModel.totalExerciseCalories
                    )
                    .padding(.horizontal)
                }

                // Recent progress photo
                if let photo = viewModel.recentPhoto {
                    RecentPhotoCard(photo: photo)
                        .padding(.horizontal)
                }

                // Quick actions
                QuickActionsSection(
                    onLogFood: { showingAddFood = true },
                    onAddPhoto: { showingAddPhoto = true },
                    onSyncStrava: { showingStravaSync = true }
                )
                .padding(.horizontal)

                // Recent food entries
                if !viewModel.foodEntries.isEmpty {
                    RecentFoodSection(entries: viewModel.foodEntries)
                        .padding(.horizontal)
                }

                // Empty state
                if viewModel.dailySummary == nil && !viewModel.isLoading {
                    EmptyDashboardView()
                        .padding()
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadTodaySummary()
        }
        .sheet(isPresented: $showingStravaSync) {
            StravaConnectionView(userId: userId)
        }
    }
}

// MARK: - Welcome Header

private struct WelcomeHeader: View {
    let userName: String?
    let weight: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hello, \(userName ?? "User")!")
                .font(.title)
                .fontWeight(.bold)

            HStack {
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let weight = weight {
                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                            .font(.caption)
                        Text(String(format: "%.1f kg", weight))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Net Calories Dashboard Card

private struct NetCaloriesDashboardCard: View {
    let netCalories: Int
    let isInSurplus: Bool
    let caloriesConsumed: Int
    let caloriesBurned: Int

    var body: some View {
        VStack(spacing: 16) {
            // Net calories
            VStack(spacing: 4) {
                Text("\(abs(netCalories))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(isInSurplus ? .red : .green)

                Text(isInSurplus ? "Calorie Surplus" : "Calorie Deficit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Stats row
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(caloriesConsumed)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Consumed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(caloriesBurned)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Burned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    (isInSurplus ? Color.red : Color.green).opacity(0.1),
                    (isInSurplus ? Color.red : Color.green).opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Calories Progress Card

private struct CaloriesProgressCard: View {
    let current: Int
    let target: Int
    let burned: Int

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Calorie Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.easeInOut(duration: 0.5), value: progress)

                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(current)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.blue)
                        Text("Consumed:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(current) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.purple)
                        Text("Target:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(target) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Burned:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(burned) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Macros Section

private struct MacrosSection: View {
    let proteinCurrent: Double
    let proteinTarget: Double
    let carbsCurrent: Double
    let carbsTarget: Double
    let fatCurrent: Double
    let fatTarget: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrients")
                .font(.headline)

            VStack(spacing: 12) {
                MacroProgressCard(
                    name: "Protein",
                    current: proteinCurrent,
                    target: max(proteinTarget, 1),
                    color: .red,
                    icon: "flame.fill"
                )

                MacroProgressCard(
                    name: "Carbs",
                    current: carbsCurrent,
                    target: max(carbsTarget, 1),
                    color: .blue,
                    icon: "leaf.fill"
                )

                MacroProgressCard(
                    name: "Fat",
                    current: fatCurrent,
                    target: max(fatTarget, 1),
                    color: .purple,
                    icon: "drop.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Activity Summary Section

private struct ActivitySummarySection: View {
    let activities: [Activity]
    let totalCalories: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.orange)
                Text("Today's Activities")
                    .font(.headline)

                Spacer()

                Text("\(totalCalories) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }

            ForEach(activities.prefix(3)) { activity in
                ActivityRowCompact(activity: activity)
            }

            if activities.count > 3 {
                Text("+ \(activities.count - 3) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

private struct ActivityRowCompact: View {
    let activity: Activity

    var body: some View {
        HStack {
            Image(systemName: "figure.run")
                .font(.caption)
                .foregroundColor(.orange)

            Text(activity.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            if let distance = activity.distance {
                Text(String(format: "%.1f km", distance / 1000))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("\(Int(activity.calories)) cal")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recent Photo Card

private struct RecentPhotoCard: View {
    let photo: ProgressPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                Text("Latest Progress Photo")
                    .font(.headline)

                Spacer()

                Text(photo.takenAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            AsyncImage(url: URL(string: photo.photoUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 150)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .frame(height: 150)
                @unknown default:
                    EmptyView()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quick Actions Section

private struct QuickActionsSection: View {
    let onLogFood: () -> Void
    let onAddPhoto: () -> Void
    let onSyncStrava: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Log Food",
                    color: .blue,
                    action: onLogFood
                )

                QuickActionButton(
                    icon: "camera.fill",
                    title: "Add Photo",
                    color: .purple,
                    action: onAddPhoto
                )

                QuickActionButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Sync Strava",
                    color: .orange,
                    action: onSyncStrava
                )
            }
        }
    }
}

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Recent Food Section

private struct RecentFoodSection: View {
    let entries: [FoodEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.headline)

            ForEach(entries.prefix(5)) { entry in
                FoodEntryRowCompact(entry: entry)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

private struct FoodEntryRowCompact: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            Image(systemName: entry.mealType?.icon ?? "fork.knife")
                .font(.caption)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(String(format: "%.1f serving", entry.servings))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(entry.totalCalories)) cal")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Dashboard View

private struct EmptyDashboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Start Your Day")
                .font(.headline)

            Text("Log your first meal or sync activities to see your dashboard")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
