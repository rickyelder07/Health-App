//
//  FoodDetailView.swift
//  Netfuel
//
//  View for displaying food details and logging
//

import SwiftUI

/// Detail view for foods (USDA or Custom) with logging functionality
struct FoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var foodViewModel: FoodViewModel

    // Food sources (only one will be set)
    let usdaFood: USDAFood?
    let customFood: CustomFood?

    // Logging parameters
    @State private var servings: Double = 1.0
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedDate: Date = Date()
    @State private var isLogging = false
    @State private var showingEditFood = false

    init(usdaFood: USDAFood, foodViewModel: FoodViewModel, onLog: @escaping () -> Void) {
        self.usdaFood = usdaFood
        self.customFood = nil
        self.foodViewModel = foodViewModel
        self.onLogCallback = onLog
    }

    init(customFood: CustomFood, foodViewModel: FoodViewModel, onLog: @escaping () -> Void) {
        self.usdaFood = nil
        self.customFood = customFood
        self.foodViewModel = foodViewModel
        self.onLogCallback = onLog
    }

    let onLogCallback: () -> Void

    // Computed properties
    private var foodName: String {
        usdaFood?.description ?? customFood?.name ?? ""
    }

    private var brandName: String? {
        usdaFood?.brandName ?? customFood?.brand
    }

    private var baseServingSize: String {
        if let usda = usdaFood {
            return usda.servingSize.map { String(format: "%.0f", $0) } ?? "100"
        }
        return customFood?.servingSize ?? "100"
    }

    private var servingUnit: String {
        usdaFood?.servingSizeUnit ?? customFood?.servingUnit ?? "g"
    }

    private var baseCalories: Int {
        Int(usdaFood?.calories ?? Double(customFood?.calories ?? 0))
    }

    private var baseProtein: Double {
        usdaFood?.protein ?? customFood?.protein ?? 0
    }

    private var baseCarbs: Double {
        usdaFood?.carbohydrates ?? customFood?.carbs ?? 0
    }

    private var baseFat: Double {
        usdaFood?.fat ?? customFood?.fat ?? 0
    }

    private var baseFiber: Double? {
        usdaFood?.getNutrient(name: "fiber") ?? customFood?.fiber
    }

    private var baseSugar: Double? {
        usdaFood?.getNutrient(name: "sugar") ?? customFood?.sugar
    }

    private var baseSodium: Double? {
        usdaFood?.getNutrient(name: "sodium") ?? customFood?.sodium
    }

    // Calculated totals based on servings
    private var totalCalories: Int {
        Int(Double(baseCalories) * servings)
    }

    private var totalProtein: Double {
        baseProtein * servings
    }

    private var totalCarbs: Double {
        baseCarbs * servings
    }

    private var totalFat: Double {
        baseFat * servings
    }

    private var totalFiber: Double? {
        baseFiber.map { $0 * servings }
    }

    private var totalSugar: Double? {
        baseSugar.map { $0 * servings }
    }

    private var totalSodium: Double? {
        baseSodium.map { $0 * servings }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(foodName)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let brand = brandName {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 4) {
                            if usdaFood != nil {
                                Label("USDA Database", systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("Custom Food", systemImage: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    // Serving Size Adjuster
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Serving Size")
                            .font(.headline)

                        HStack {
                            Button {
                                if servings > 0.25 {
                                    servings -= 0.25
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }

                            Spacer()

                            VStack(spacing: 4) {
                                Text(String(format: "%.2f", servings))
                                    .font(.title)
                                    .fontWeight(.bold)

                                Text("× \(baseServingSize) \(servingUnit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                servings += 0.25
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                        }

                        Slider(value: $servings, in: 0.25...10, step: 0.25)
                            .tint(.accentColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Nutrition Facts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Facts")
                            .font(.headline)

                        VStack(spacing: 0) {
                            // Calories (large)
                            HStack {
                                Text("Calories")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(totalCalories)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color(.systemBackground))

                            Divider()

                            // Macros
                            NutritionRow(
                                label: "Protein",
                                value: String(format: "%.1f g", totalProtein),
                                icon: "flame.fill",
                                color: .red
                            )

                            Divider()

                            NutritionRow(
                                label: "Carbohydrates",
                                value: String(format: "%.1f g", totalCarbs),
                                icon: "leaf.fill",
                                color: .blue
                            )

                            Divider()

                            NutritionRow(
                                label: "Fat",
                                value: String(format: "%.1f g", totalFat),
                                icon: "drop.fill",
                                color: .purple
                            )

                            // Optional nutrients
                            if let fiber = totalFiber {
                                Divider()
                                NutritionRow(
                                    label: "Fiber",
                                    value: String(format: "%.1f g", fiber),
                                    icon: "leaf",
                                    color: .green
                                )
                            }

                            if let sugar = totalSugar {
                                Divider()
                                NutritionRow(
                                    label: "Sugar",
                                    value: String(format: "%.1f g", sugar),
                                    icon: "cube.fill",
                                    color: .pink
                                )
                            }

                            if let sodium = totalSodium {
                                Divider()
                                NutritionRow(
                                    label: "Sodium",
                                    value: String(format: "%.0f mg", sodium),
                                    icon: "drop.triangle.fill",
                                    color: .orange
                                )
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)

                    // Date Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date")
                            .font(.headline)

                        DatePicker(
                            "Log Date",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Meal Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal Type")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(MealType.allCases, id: \.self) { mealType in
                                MealTypeButton(
                                    mealType: mealType,
                                    isSelected: selectedMealType == mealType,
                                    action: {
                                        selectedMealType = mealType
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Log Button
                    Button {
                        logFood()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Food")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLogging)
                    .padding(.horizontal)

                    // Additional actions for custom foods
                    if customFood != nil {
                        HStack(spacing: 12) {
                            Button {
                                showingEditFood = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }

                            Button {
                                // Toggle favorite
                                if let food = customFood {
                                    Task {
                                        await foodViewModel.toggleCustomFoodFavorite(food)
                                    }
                                }
                            } label: {
                                Label("Favorite", systemImage: customFood?.isFavorite == true ? "star.fill" : "star")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // USDA Copy Button
                    if usdaFood != nil {
                        Button {
                            if let food = usdaFood {
                                Task {
                                    _ = await foodViewModel.createCustomFoodFromUSDA(food)
                                }
                            }
                        } label: {
                            Label("Copy to My Foods", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditFood) {
                if let food = customFood {
                    CreateCustomFoodView(viewModel: foodViewModel, editingFood: food)
                }
            }
        }
    }

    // MARK: - Actions

    private func logFood() {
        isLogging = true

        Task {
            let success = await foodViewModel.logFood(
                foodName: foodName,
                brandName: brandName,
                servingSize: baseServingSize,
                servingUnit: servingUnit,
                calories: baseCalories,
                protein: baseProtein,
                carbs: baseCarbs,
                fat: baseFat,
                fiber: baseFiber,
                sugar: baseSugar,
                sodium: baseSodium,
                servings: servings,
                mealType: selectedMealType,
                logDate: selectedDate,
                usdaFdcId: usdaFood.map { String($0.fdcId) },
                customFoodId: customFood?.id
            )

            isLogging = false

            if success {
                onLogCallback()
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct NutritionRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(label)
            }

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

struct MealTypeButton: View {
    let mealType: MealType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mealType.icon)
                    .font(.title3)
                Text(mealType.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
    }
}

// Meal Detail View for custom meals
struct MealDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var foodViewModel: FoodViewModel

    let meal: CustomMeal
    let onLogCallback: () -> Void

    @State private var multiplier: Double = 1.0
    @State private var selectedMealType: MealType = .lunch
    @State private var selectedDate: Date = Date()
    @State private var isLogging = false
    @State private var mealFoods: [CustomMealFood] = []

    private var totalCalories: Int {
        Int(Double(meal.totalCalories) * multiplier)
    }

    private var totalProtein: Double {
        meal.totalProtein * multiplier
    }

    private var totalCarbs: Double {
        meal.totalCarbs * multiplier
    }

    private var totalFat: Double {
        meal.totalFat * multiplier
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            if meal.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(meal.name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        if let description = meal.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Label("Custom Meal", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    // Multiplier
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Servings")
                            .font(.headline)

                        HStack {
                            Button {
                                if multiplier > 0.25 {
                                    multiplier -= 0.25
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }

                            Spacer()

                            Text(String(format: "%.2f×", multiplier))
                                .font(.title)
                                .fontWeight(.bold)

                            Spacer()

                            Button {
                                multiplier += 0.25
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                        }

                        Slider(value: $multiplier, in: 0.25...5, step: 0.25)
                            .tint(.accentColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Foods in Meal
                    if !mealFoods.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Foods in This Meal")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(mealFoods) { food in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(food.displayName)
                                                .font(.subheadline)
                                            Text(food.servingDescription)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text("\(food.calories) cal")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Total Nutrition
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Total Nutrition")
                            .font(.headline)

                        MacroSummaryCard(
                            calories: totalCalories,
                            caloriesTarget: totalCalories,
                            protein: totalProtein,
                            proteinTarget: totalProtein,
                            carbs: totalCarbs,
                            carbsTarget: totalCarbs,
                            fat: totalFat,
                            fatTarget: totalFat
                        )
                    }
                    .padding(.horizontal)

                    // Date Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date")
                            .font(.headline)

                        DatePicker(
                            "Log Date",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Meal Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal Type")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(MealType.allCases, id: \.self) { mealType in
                                MealTypeButton(
                                    mealType: mealType,
                                    isSelected: selectedMealType == mealType,
                                    action: {
                                        selectedMealType = mealType
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Log Button
                    Button {
                        logMeal()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Meal")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLogging)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadMealFoods()
            }
        }
    }

    private func loadMealFoods() async {
        await foodViewModel.loadMealFoods(mealId: meal.id)
        mealFoods = foodViewModel.selectedMealFoods
    }

    private func logMeal() {
        isLogging = true

        Task {
            let success = await foodViewModel.logFood(
                foodName: meal.name,
                brandName: nil,
                servingSize: "1",
                servingUnit: "meal",
                calories: meal.totalCalories,
                protein: meal.totalProtein,
                carbs: meal.totalCarbs,
                fat: meal.totalFat,
                fiber: nil,
                sugar: nil,
                sodium: nil,
                servings: multiplier,
                mealType: selectedMealType,
                logDate: selectedDate,
                customMealId: meal.id
            )

            isLogging = false

            if success {
                onLogCallback()
                dismiss()
            }
        }
    }
}

#Preview("USDA Food") {
    FoodDetailView(
        usdaFood: USDAFood(
            fdcId: 123,
            description: "Chicken Breast",
            brandOwner: nil,
            brandName: nil,
            ingredients: nil,
            servingSize: 100,
            servingSizeUnit: "g",
            foodNutrients: []
        ),
        foodViewModel: FoodViewModel(),
        onLog: {}
    )
}

