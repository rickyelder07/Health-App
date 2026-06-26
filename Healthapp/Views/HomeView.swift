//
//  HomeView.swift
//  Netfuel
//
//  Home dashboard displaying today's summary and quick actions
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingStravaSync = false
    @State private var showingAddFood = false
    @State private var showingAddPhoto = false
    @State private var showingLogWeight = false

    var body: some View {
        NavigationView {
            Group {
                if let userId = appState.currentUser?.id {
                    HomeContentView(
                        userId: userId,
                        showingAddFood: $showingAddFood,
                        showingAddPhoto: $showingAddPhoto,
                        showingStravaSync: $showingStravaSync,
                        showingLogWeight: $showingLogWeight
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
    @Binding var showingLogWeight: Bool

    @StateObject private var viewModel: HomeViewModel
    @StateObject private var foodViewModel = FoodViewModel()
    @StateObject private var photoViewModel = ProgressPhotoViewModel()
    @EnvironmentObject var appState: AppState

    init(
        userId: UUID,
        showingAddFood: Binding<Bool>,
        showingAddPhoto: Binding<Bool>,
        showingStravaSync: Binding<Bool>,
        showingLogWeight: Binding<Bool>
    ) {
        self.userId = userId
        self._showingAddFood = showingAddFood
        self._showingAddPhoto = showingAddPhoto
        self._showingStravaSync = showingStravaSync
        self._showingLogWeight = showingLogWeight
        _viewModel = StateObject(wrappedValue: HomeViewModel(userId: userId))
    }

    @State private var showErrorToast = false
    @State private var showSuccessToast = false
    @State private var toastMessage = ""
    @State private var dismissedMealPrompts: Set<String> = []

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                // Loading skeleton
                VStack(spacing: 20) {
                    SkeletonCard()
                        .frame(height: 200)
                    SkeletonCard()
                        .frame(height: 150)
                    SkeletonCard()
                        .frame(height: 200)
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    // Sync status banner (shows when offline or syncing)
                    SyncStatusBanner()
                        .animation(.spring(), value: viewModel.isLoading)

                    mealBannerSection

                    // Welcome header
                    WelcomeHeader(
                        userName: {
                            // Use name if available, otherwise derive from email
                            if let name = appState.currentUser?.name, !name.isEmpty {
                                return name
                            }
                            return appState.currentUser?.email?.components(separatedBy: "@").first?.capitalized
                        }(),
                        weight: viewModel.currentWeight
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    .cardAppearance(delay: 0.0)
                    .accessibleHeader(label: "Welcome header")

                    // Net calories card
                    if let summary = viewModel.dailySummary {
                        NetCaloriesDashboardCard(
                            netCalories: viewModel.netCalories,
                            isInSurplus: viewModel.isInSurplus,
                            caloriesConsumed: viewModel.caloriesConsumed,
                            caloriesBurned: viewModel.caloriesBurned,
                            calorieTarget: viewModel.calorieTarget,
                            isStravaDynamic: viewModel.isStravaDynamicMode
                        )
                        .padding(.horizontal)
                        .cardAppearance(delay: 0.1)
                        .accessibleCard(
                            label: "\(viewModel.isInSurplus ? "Surplus" : "Deficit") of \(abs(viewModel.netCalories)) calories. \(viewModel.caloriesConsumed) consumed, \(viewModel.caloriesBurned) burned",
                            hint: "Shows your net calorie balance for today"
                        )
                    }

                    // Calories progress (circular)
                    if let summary = viewModel.dailySummary {
                        CaloriesProgressCard(
                            current: viewModel.caloriesConsumed,
                            target: viewModel.calorieTarget,
                            burned: viewModel.caloriesBurned,
                            isStravaDynamic: viewModel.isStravaDynamicMode,
                            bmr: viewModel.bmrCalories,
                            exerciseCalories: viewModel.totalExerciseCalories
                        )
                        .padding(.horizontal)
                        .cardAppearance(delay: 0.2)
                        .accessibleCard(
                            label: "Calorie progress: \(viewModel.caloriesConsumed) of \(viewModel.calorieTarget) calories",
                            hint: "Shows progress toward daily calorie target"
                        )
                    }

                    // Macros progress - using real-time calculated values
                    MacrosSection(
                        proteinCurrent: viewModel.proteinConsumed,
                        proteinTarget: viewModel.proteinTarget,
                        carbsCurrent: viewModel.carbsConsumed,
                        carbsTarget: viewModel.carbsTarget,
                        fatCurrent: viewModel.fatConsumed,
                        fatTarget: viewModel.fatTarget
                    )
                    .padding(.horizontal)
                    .cardAppearance(delay: 0.3)
                    .accessibleCard(
                        label: "Macronutrients: Protein \(Int(viewModel.proteinConsumed)) of \(Int(viewModel.proteinTarget)), Carbs \(Int(viewModel.carbsConsumed)) of \(Int(viewModel.carbsTarget)), Fat \(Int(viewModel.fatConsumed)) of \(Int(viewModel.fatTarget))",
                        hint: "Shows macronutrient progress"
                    )

                    // Activity summary
                    if !viewModel.activities.isEmpty {
                        ActivitySummarySection(
                            activities: viewModel.activities,
                            totalCalories: viewModel.totalExerciseCalories
                        )
                        .padding(.horizontal)
                        .cardAppearance(delay: 0.4)
                        .accessibleCard(
                            label: "Today's activities: \(viewModel.totalExerciseCalories) calories burned",
                            hint: "Shows exercise activities for today"
                        )
                    }

                    // Quick actions
                    QuickActionsSection(
                        onLogFood: {
                            HapticFeedback.light()
                            showingAddFood = true
                        },
                        onAddPhoto: {
                            HapticFeedback.light()
                            showingAddPhoto = true
                        },
                        onSyncStrava: {
                            HapticFeedback.light()
                            showingStravaSync = true
                        },
                        onLogWeight: {
                            HapticFeedback.light()
                            showingLogWeight = true
                        }
                    )
                    .padding(.horizontal)
                    .cardAppearance(delay: 0.5)

                    // Recent food entries
                    if !viewModel.foodEntries.isEmpty {
                        RecentFoodSection(entries: viewModel.foodEntries)
                            .padding(.horizontal)
                            .cardAppearance(delay: 0.6)
                            .accessibleCard(
                                label: "Recent food entries: \(viewModel.foodEntries.count) items",
                                hint: "Shows recently logged food"
                            )
                    }

                    // Recent progress photo
                    if let photo = viewModel.recentPhoto {
                        RecentPhotoCard(photo: photo)
                            .padding(.horizontal)
                            .cardAppearance(delay: 0.7)
                            .accessibleCard(
                                label: "Latest progress photo from \(photo.takenAt.formatted(date: .abbreviated, time: .omitted))",
                                hint: "Shows your most recent progress photo"
                            )
                    }

                    // Empty state
                    if viewModel.dailySummary == nil && !viewModel.isLoading {
                        EmptyDashboardView()
                            .padding()
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
            if let freshUser = viewModel.user { appState.setUser(freshUser) }
            if viewModel.errorMessage != nil {
                HapticFeedback.error()
                toastMessage = viewModel.errorMessage ?? "Failed to refresh"
                showErrorToast = true
            } else {
                HapticFeedback.success()
            }
        }
        .task {
            viewModel.user = appState.currentUser  // seed so calorieTarget never falls back to 0
            await viewModel.loadTodaySummary()
            if let freshUser = viewModel.user {
                appState.setUser(freshUser)  // keep FoodLogListView in sync with same TDEE
            }
            foodViewModel.setUser(userId: userId)
            photoViewModel.setUser(userId: userId)

            if let error = viewModel.errorMessage {
                toastMessage = error
                showErrorToast = true
            }
        }
        .toast(message: toastMessage, isShowing: $showErrorToast, type: .error)
        .toast(message: toastMessage, isShowing: $showSuccessToast, type: .success)
        .dismissKeyboardOnTap()
        .sheet(isPresented: $showingAddFood) {
            FoodSearchView(foodViewModel: foodViewModel)
        }
        .sheet(isPresented: $showingAddPhoto) {
            AddProgressPhotoView(viewModel: photoViewModel)
        }
        .sheet(isPresented: $showingStravaSync) {
            StravaConnectionView(userId: userId)
        }
        .sheet(isPresented: $showingLogWeight) {
            WeightLogView(userId: userId)
        }
        .accessibilityElement(children: .contain)
        .accessible(label: "Dashboard", hint: "View your daily nutrition and activity summary")
    }

    @ViewBuilder private var mealBannerSection: some View {
        if let meal = activeMealPrompt {
            if !dismissedMealPrompts.contains(meal.rawValue) {
                MealPromptBanner(
                    meal: meal,
                    onLog: { showingAddFood = true },
                    onDismiss: {
                        withAnimation(.spring(response: 0.4)) {
                            _ = dismissedMealPrompts.insert(meal.rawValue)
                        }
                    }
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var activeMealPrompt: MealType? {
        guard !viewModel.isLoading else { return nil }
        let prefs = NotificationManager.shared.preferences
        let now = Date()
        let cal = Calendar.current
        let logged = Set(viewModel.foodEntries.compactMap { $0.mealType })
        let meals: [(MealType, Bool, Date)] = [
            (.breakfast, prefs.breakfastReminderEnabled, prefs.breakfastTime),
            (.lunch,     prefs.lunchReminderEnabled,     prefs.lunchTime),
            (.dinner,    prefs.dinnerReminderEnabled,    prefs.dinnerTime),
        ]
        for (meal, enabled, mealTime) in meals {
            guard enabled, !logged.contains(meal) else { continue }
            let h = cal.component(.hour, from: mealTime)
            let m = cal.component(.minute, from: mealTime)
            guard let fireDate = cal.date(bySettingHour: h, minute: m, second: 0, of: now),
                  let windowEnd = cal.date(byAdding: .hour, value: 2, to: fireDate),
                  now >= fireDate, now <= windowEnd else { continue }
            return meal
        }
        return nil
    }
}

// MARK: - Meal Prompt Banner

private struct MealPromptBanner: View {
    let meal: MealType
    let onLog: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: meal.icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Color.red)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Have you logged \(meal.displayName.lowercased())?")
                    .font(.subheadline).fontWeight(.semibold)
                Text("Tap to log and stay on track 💪")
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(6)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onLog)
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
                        Text(UnitFormatter.formatWeight(weight))
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
    let calorieTarget: Int
    let isStravaDynamic: Bool

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(abs(netCalories))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(isInSurplus ? .red : .green)

                Text(isInSurplus ? "Calorie Surplus" : "Calorie Deficit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // In TDEE mode: Consumed vs Goal.
            // In Strava Dynamic: Consumed vs Burned (burned = goal).
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(caloriesConsumed)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Consumed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 40)

                VStack(spacing: 4) {
                    Text(isStravaDynamic ? "\(caloriesBurned)" : "\(calorieTarget)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(isStravaDynamic ? "Burned" : "Goal")
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
    var isStravaDynamic: Bool = false
    var bmr: Int = 0
    var exerciseCalories: Int = 0

    private var remaining: Int { max(0, target - current) }

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Calorie Progress")
                    .font(.headline)
                if isStravaDynamic {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                        Text("Strava Dynamic")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                Spacer()
            }

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
                        Text("Goal:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(target) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    // Only show Burned in Strava Dynamic mode — in TDEE mode it's
                    // already accounted for in the goal, displaying it separately is misleading
                    if isStravaDynamic {
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

                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.green)
                        Text("Remaining:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(remaining) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(remaining == 0 ? .red : .green)
                    }
                }
            }

            // Strava Dynamic goal breakdown
            if isStravaDynamic {
                Divider()

                HStack(spacing: 0) {
                    goalBreakdownPill(label: "BMR", value: bmr, color: .blue)
                    Text("+")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                    goalBreakdownPill(label: "Exercise", value: exerciseCalories, color: .orange)
                    Text("=")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                    goalBreakdownPill(label: "Goal", value: target, color: .purple)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func goalBreakdownPill(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
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
                Text(UnitFormatter.formatDistance(distance))
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
    let onLogWeight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            VStack(spacing: 12) {
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
                }

                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Sync Strava",
                        color: .orange,
                        action: onSyncStrava
                    )

                    QuickActionButton(
                        icon: "scalemass.fill",
                        title: "Log Weight",
                        color: .green,
                        action: onLogWeight
                    )
                }
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
        .accessibleButton(label: title, hint: "Quick action to \(title.lowercased())")
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
