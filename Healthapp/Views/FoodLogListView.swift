//
//  FoodLogListView.swift
//  Netfuel
//
//  View for displaying today's food logs with macro tracking
//

import SwiftUI

/// Main food logging view with today's logs and macro progress
struct FoodLogListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FoodViewModel()

    @State private var activeSheet: FoodLogSheet?
    @State private var showingDatePicker = false
    @State private var showSuccessToast = false
    @State private var showErrorToast = false
    @State private var toastMessage = ""

    enum FoodLogSheet: Identifiable {
        case addFood, myMeals, createFood, createMeal
        var id: Self { self }
    }

    // Load goals from user settings
    private var settings: UserSettings {
        UserSettings.load()
    }

    private var caloriesTarget: Int {
        if settings.calorieMode == .stravaDynamic {
            let bmr = Int(appState.currentUser?.bmr ?? appState.currentUser?.calculateBMR() ?? 0)
            return settings.stravaCalorieTarget(bmr: bmr, exerciseCalories: viewModel.todayExerciseCalories)
        }
        let tdee = Int(appState.currentUser?.tdee ?? appState.currentUser?.calculateTDEE() ?? 0)
        return settings.effectiveCalorieTarget(tdee: tdee)
    }

    private var proteinTarget: Double {
        // Use user's custom target if set, otherwise use 30% of calorie target
        return settings.proteinTargetGrams ?? (Double(caloriesTarget) * 0.30 / 4)
    }

    private var carbsTarget: Double {
        // Use user's custom target if set, otherwise use 40% of calorie target
        return settings.carbsTargetGrams ?? (Double(caloriesTarget) * 0.40 / 4)
    }

    private var fatTarget: Double {
        // Use user's custom target if set, otherwise use 30% of calorie target
        return settings.fatTargetGrams ?? (Double(caloriesTarget) * 0.30 / 9)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    // Loading skeleton
                    VStack(spacing: 20) {
                        SkeletonCard()
                            .frame(height: 80)
                        SkeletonCard()
                            .frame(height: 200)
                        FoodLogSkeleton()
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        // Date Selector
                        DateSelectorView(
                            selectedDate: $viewModel.selectedDate,
                            onDateChange: {
                                HapticFeedback.selection()
                                Task {
                                    await viewModel.refreshTodayLogs()
                                }
                            }
                        )
                        .padding(.horizontal)
                        .cardAppearance(delay: 0.0)

                        // Macro Progress Summary
                        MacroSummaryCard(
                            calories: viewModel.todayTotalCalories,
                            caloriesTarget: caloriesTarget,
                            protein: viewModel.todayTotalProtein,
                            proteinTarget: proteinTarget,
                            carbs: viewModel.todayTotalCarbs,
                            carbsTarget: carbsTarget,
                            fat: viewModel.todayTotalFat,
                            fatTarget: fatTarget
                        )
                        .padding(.horizontal)
                        .cardAppearance(delay: 0.1)
                        .accessibleCard(
                            label: "Daily macros: \(viewModel.todayTotalCalories) of \(caloriesTarget) calories",
                            hint: "Shows daily nutrition progress"
                        )

                        // Saved Meals Quick-Add
                        SavedMealsButton(viewModel: viewModel) {
                            HapticFeedback.light()
                            activeSheet = .myMeals
                        }
                        .padding(.horizontal)
                        .cardAppearance(delay: 0.15)

                        // Food Logs by Meal Type
                        if viewModel.todayFoodLogs.isEmpty {
                            NoFoodLogsEmptyState {
                                HapticFeedback.light()
                                activeSheet = .addFood
                            }
                            .padding()
                            .cardAppearance(delay: 0.2)
                        } else {
                            FoodLogsByMealView(
                                viewModel: viewModel,
                                onDelete: { log in
                                    HapticFeedback.medium()
                                    Task {
                                        await viewModel.deleteFoodLog(log)
                                        if viewModel.successMessage != nil {
                                            HapticFeedback.success()
                                            toastMessage = "Food deleted"
                                            showSuccessToast = true
                                        } else if let error = viewModel.errorMessage {
                                            HapticFeedback.error()
                                            toastMessage = error
                                            showErrorToast = true
                                        }
                                        viewModel.clearMessages()
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .cardAppearance(delay: 0.2)
                        }

                        // Quick-Add Buttons
                        QuickAddButtonsSection(
                            viewModel: viewModel,
                            userId: appState.currentUser?.id,
                            onSuccess: {
                                HapticFeedback.success()
                                toastMessage = "Food logged successfully!"
                                showSuccessToast = true
                            },
                            onError: { error in
                                HapticFeedback.error()
                                toastMessage = error
                                showErrorToast = true
                            }
                        )
                        .padding(.horizontal)
                        .cardAppearance(delay: 0.3)

                        // Quick Add Section (Recently Logged)
                        if !viewModel.recentFoods.isEmpty {
                            QuickAddSection(
                                recentFoods: viewModel.recentFoods,
                                onSelect: { log in
                                    HapticFeedback.light()
                                    // Quick log recent food
                                    Task {
                                        _ = await viewModel.logFood(
                                            foodName: log.foodName,
                                            brandName: log.brandName,
                                            servingSize: log.servingSize,
                                            servingUnit: log.servingUnit,
                                            calories: log.calories,
                                            protein: log.protein,
                                            carbs: log.carbs,
                                            fat: log.fat,
                                            fiber: log.fiber,
                                            sugar: log.sugar,
                                            sodium: log.sodium,
                                            servings: log.servings,
                                            mealType: log.mealType
                                        )
                                        if viewModel.successMessage != nil {
                                            HapticFeedback.success()
                                            toastMessage = "Food logged!"
                                            showSuccessToast = true
                                        }
                                        viewModel.clearMessages()
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .cardAppearance(delay: 0.4)
                            .accessibleCard(
                                label: "Recently logged foods",
                                hint: "Quick-add foods you've logged recently"
                            )
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Food Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            HapticFeedback.light()
                            activeSheet = .addFood
                        } label: {
                            Label("Add Food", systemImage: "magnifyingglass")
                        }
                        Divider()
                        Button {
                            HapticFeedback.light()
                            activeSheet = .createFood
                        } label: {
                            Label("New Custom Food", systemImage: "plus.circle")
                        }
                        Button {
                            HapticFeedback.light()
                            activeSheet = .createMeal
                        } label: {
                            Label("New Custom Meal", systemImage: "fork.knife.circle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibleButton(label: "Add food or create meal", hint: "Log food or create a custom food or meal")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addFood:
                    FoodSearchView(foodViewModel: viewModel)
                case .myMeals:
                    QuickMealPickerView(viewModel: viewModel)
                case .createFood:
                    CreateCustomFoodView(viewModel: viewModel)
                case .createMeal:
                    CreateCustomMealView(viewModel: viewModel)
                }
            }
            .refreshable {
                HapticFeedback.light()
                await viewModel.refreshTodayLogs()
                if viewModel.errorMessage != nil {
                    HapticFeedback.error()
                } else {
                    HapticFeedback.success()
                }
            }
            .task {
                if let userId = appState.currentUser?.id {
                    viewModel.setUser(userId: userId)
                }
            }
            .toast(message: toastMessage, isShowing: $showSuccessToast, type: .success)
            .toast(message: toastMessage, isShowing: $showErrorToast, type: .error)
            .dismissKeyboardOnTap()
            .onChange(of: viewModel.successMessage) { message in
                if let msg = message {
                    toastMessage = msg
                    showSuccessToast = true
                    viewModel.clearMessages()
                }
            }
            .onChange(of: viewModel.errorMessage) { message in
                if let msg = message {
                    toastMessage = msg
                    showErrorToast = true
                    viewModel.clearMessages()
                }
            }
        }
    }
}

// MARK: - Date Selector

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    let onDateChange: () -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        HStack {
            Button {
                HapticFeedback.selection()
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                onDateChange()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .accessibleButton(label: "Previous day", hint: "Go to previous day")

            Spacer()

            VStack(spacing: 4) {
                Text(formattedDate)
                    .font(.headline)

                if isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .accessible(label: isToday ? "Today, \(formattedDate)" : formattedDate, traits: .isHeader)

            Spacer()

            Button {
                HapticFeedback.selection()
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                onDateChange()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .disabled(isToday)
            .accessibleButton(label: "Next day", hint: "Go to next day")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Food Logs by Meal

struct FoodLogsByMealView: View {
    @ObservedObject var viewModel: FoodViewModel
    let onDelete: (FoodLog) -> Void

    private var logsByMeal: [MealType: [FoodLog]] {
        viewModel.foodLogsByMealType()
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(MealType.allCases, id: \.self) { mealType in
                if let logs = logsByMeal[mealType], !logs.isEmpty {
                    MealSection(
                        mealType: mealType,
                        logs: logs,
                        onDelete: onDelete
                    )
                } else {
                    EmptyMealSection(mealType: mealType)
                }
            }
        }
    }
}

// MARK: - Meal Section

struct MealSection: View {
    let mealType: MealType
    let logs: [FoodLog]
    let onDelete: (FoodLog) -> Void

    private var totalCalories: Int {
        logs.reduce(0) { $0 + Int($1.totalCalories) }
    }

    private var totalProtein: Double {
        logs.reduce(0.0) { $0 + $1.totalProtein }
    }

    private var totalCarbs: Double {
        logs.reduce(0.0) { $0 + $1.totalCarbs }
    }

    private var totalFat: Double {
        logs.reduce(0.0) { $0 + $1.totalFat }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: mealType.icon)
                        .foregroundColor(.accentColor)
                    Text(mealType.displayName)
                        .font(.headline)
                }

                Spacer()

                Text("\(totalCalories) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            // Food logs
            VStack(spacing: 8) {
                ForEach(logs) { log in
                    FoodLogRow(log: log, onDelete: {
                        onDelete(log)
                    })
                }
            }

            // Meal totals
            HStack(spacing: 16) {
                MacroBadge(icon: "p.circle.fill", value: String(format: "%.0f", totalProtein), unit: "g", color: .red)
                MacroBadge(icon: "c.circle.fill", value: String(format: "%.0f", totalCarbs), unit: "g", color: .blue)
                MacroBadge(icon: "f.circle.fill", value: String(format: "%.0f", totalFat), unit: "g", color: .purple)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Empty Meal Section

struct EmptyMealSection: View {
    let mealType: MealType

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: mealType.icon)
                    .foregroundColor(.secondary)
                Text(mealType.displayName)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("No foods logged")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Food Log Row

struct FoodLogRow: View {
    let log: FoodLog
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(log.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let brand = log.brandName {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(log.servingDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                InlineMacroView(
                    calories: Int(log.totalCalories),
                    protein: log.totalProtein,
                    carbs: log.totalCarbs,
                    fat: log.totalFat
                )
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Quick Add Section

struct QuickAddSection: View {
    let recentFoods: [FoodLog]
    let onSelect: (FoodLog) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Logged")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentFoods.prefix(5)) { log in
                        QuickAddCard(log: log, onTap: {
                            onSelect(log)
                        })
                    }
                }
            }
        }
    }
}

// MARK: - Quick Add Card

struct QuickAddCard: View {
    let log: FoodLog
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(log.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(log.calories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("Quick Add")
                        .font(.caption2)
                }
                .foregroundColor(.accentColor)
            }
            .frame(width: 140)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibleButton(label: "Quick add \(log.foodName)", hint: "Quickly log this food again")
    }
}

// MARK: - Quick-Add Buttons Section

struct QuickAddButtonsSection: View {
    @ObservedObject var viewModel: FoodViewModel
    var userId: UUID? = nil
    var onSuccess: (() -> Void)? = nil
    var onError: ((String) -> Void)? = nil

    @State private var settings = QuickAddSettings()
    @State private var isLogging = false
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if settings.buttons.isEmpty {
                Button {
                    showingSettings = true
                } label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Set Up Quick-Add Buttons")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text("Tap to configure shortcuts for your frequent meals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .sheet(isPresented: $showingSettings, onDismiss: {
                    settings = QuickAddSettings.load(userId: userId)
                }) {
                    QuickAddSettingsView(userId: userId)
                }
            } else {
                Text("Quick-Add")
                    .font(.headline)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(settings.buttons) { button in
                        QuickAddButtonView(
                            button: button,
                            isLogging: isLogging,
                            onTap: {
                                Task {
                                    await logQuickAddFood(button)
                                }
                            }
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
        .onAppear {
            settings = QuickAddSettings.load(userId: userId)
        }
    }

    private func logQuickAddFood(_ button: QuickAddFoodButton) async {
        isLogging = true
        var success = false

        // Find the food based on the button configuration
        if let customFoodId = button.customFoodId {
            // Log custom food
            if let customFood = viewModel.customFoods.first(where: { $0.id == customFoodId }) {
                success = await viewModel.logFood(
                    foodName: customFood.name,
                    brandName: customFood.brand,
                    servingSize: customFood.servingSize,
                    servingUnit: customFood.servingUnit,
                    calories: customFood.calories,
                    protein: customFood.protein,
                    carbs: customFood.carbs,
                    fat: customFood.fat,
                    fiber: customFood.fiber,
                    sugar: customFood.sugar,
                    sodium: customFood.sodium,
                    servings: button.servings,
                    mealType: button.mealType,
                    logDate: viewModel.selectedDate,
                    customFoodId: customFood.id
                )
            }
        } else if let customMealId = button.customMealId {
            // Log custom meal
            if let customMeal = viewModel.customMeals.first(where: { $0.id == customMealId }) {
                success = await viewModel.logFood(
                    foodName: customMeal.name,
                    brandName: nil,
                    servingSize: "1",
                    servingUnit: "meal",
                    calories: customMeal.totalCalories,
                    protein: customMeal.totalProtein,
                    carbs: customMeal.totalCarbs,
                    fat: customMeal.totalFat,
                    fiber: nil,
                    sugar: nil,
                    sodium: nil,
                    servings: button.servings,
                    mealType: button.mealType,
                    logDate: viewModel.selectedDate,
                    customMealId: customMeal.id
                )
            }
        }

        isLogging = false

        if success {
            onSuccess?()
        } else if let error = viewModel.errorMessage {
            onError?(error)
            viewModel.clearMessages()
        }
    }
}

struct QuickAddButtonView: View {
    let button: QuickAddFoodButton
    let isLogging: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            onTap()
        }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: button.mealType.icon)
                        .font(.title3)
                    Spacer()
                    if button.servings != 1.0 {
                        Text("\(String(format: "%.1f", button.servings))×")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(button.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(button.foodName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isLogging)
        .buttonStyle(.plain)
        .accessibleButton(
            label: button.label,
            hint: "Quick-add \(button.foodName) to \(button.mealType.displayName)"
        )
    }
}

// MARK: - Saved Meals Button

struct SavedMealsButton: View {
    @ObservedObject var viewModel: FoodViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add a Saved Meal")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(viewModel.customMeals.isEmpty
                        ? "No saved meals yet — tap + to create one"
                        : "\(viewModel.customMeals.count) saved meal\(viewModel.customMeals.count == 1 ? "" : "s") available")
                        .font(.caption).foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.customMeals.isEmpty)
    }
}

// MARK: - Quick Meal Picker

struct QuickMealPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FoodViewModel
    @State private var searchText = ""
    @State private var selectedMeal: CustomMeal?

    private var filteredMeals: [CustomMeal] {
        guard !searchText.isEmpty else { return viewModel.customMeals }
        return viewModel.customMeals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    private var favoriteMeals: [CustomMeal] { filteredMeals.filter { $0.isFavorite } }
    private var otherMeals: [CustomMeal]    { filteredMeals.filter { !$0.isFavorite } }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.customMeals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50)).foregroundColor(.secondary)
                        Text("No Saved Meals")
                            .font(.title3).fontWeight(.medium)
                        Text("Use the + menu on the Food Log page to create a custom meal.")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if !favoriteMeals.isEmpty {
                            Section("Favorites") {
                                ForEach(favoriteMeals) { meal in
                                    mealRow(meal)
                                }
                            }
                        }
                        Section(favoriteMeals.isEmpty ? "All Meals" : "Other Meals") {
                            ForEach(otherMeals) { meal in
                                mealRow(meal)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search saved meals")
                }
            }
            .navigationTitle("Add Saved Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(
                foodViewModel: viewModel,
                meal: meal,
                onLogCallback: { dismiss() }
            )
        }
    }

    @ViewBuilder
    private func mealRow(_ meal: CustomMeal) -> some View {
        Button { selectedMeal = meal } label: {
            CustomMealRow(meal: meal, viewModel: viewModel)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FoodLogListView()
        .environmentObject(AppState())
}

