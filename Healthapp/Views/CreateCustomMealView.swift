//
//  CreateCustomMealView.swift
//  Netfuel
//
//  View for creating/editing custom meals
//

import SwiftUI

/// View for creating or editing a custom meal
struct CreateCustomMealView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FoodViewModel

    // Edit mode
    let editingMeal: CustomMeal?

    // Form fields
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isFavorite: Bool = false

    // Meal composition
    @State private var mealFoods: [CustomMealFood] = []
    @State private var mealId: UUID?

    // UI State
    @State private var showingFoodSearch = false
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var isEditingQuantity: CustomMealFood?
    @State private var editingQuantityValue: String = ""

    init(viewModel: FoodViewModel, editingMeal: CustomMeal? = nil) {
        self.viewModel = viewModel
        self.editingMeal = editingMeal

        if let meal = editingMeal {
            _name = State(initialValue: meal.name)
            _description = State(initialValue: meal.description ?? "")
            _isFavorite = State(initialValue: meal.isFavorite)
            _mealId = State(initialValue: meal.id)
        }
    }

    // Computed totals
    private var totalCalories: Int {
        mealFoods.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        mealFoods.reduce(0.0) { $0 + $1.protein }
    }

    private var totalCarbs: Double {
        mealFoods.reduce(0.0) { $0 + $1.carbs }
    }

    private var totalFat: Double {
        mealFoods.reduce(0.0) { $0 + $1.fat }
    }

    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Meal Information") {
                    TextField("Meal Name *", text: $name)
                        .autocorrectionDisabled()

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                        .autocorrectionDisabled()
                }

                // Foods in Meal
                Section {
                    if mealFoods.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)

                            Text("No foods added yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button {
                                showingFoodSearch = true
                            } label: {
                                Label("Add Food", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(mealFoods) { food in
                            MealFoodRow(
                                food: food,
                                onEdit: {
                                    isEditingQuantity = food
                                    editingQuantityValue = String(format: "%.1f", food.quantity)
                                },
                                onDelete: {
                                    removeFoodFromMeal(food)
                                }
                            )
                        }

                        Button {
                            showingFoodSearch = true
                        } label: {
                            Label("Add Food", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Foods (\(mealFoods.count))")
                }

                // Total Nutrition
                if !mealFoods.isEmpty {
                    Section("Total Nutrition") {
                        HStack {
                            Text("Calories")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(totalCalories) cal")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.red)
                                Text("Protein")
                            }
                            Spacer()
                            Text(String(format: "%.1f g", totalProtein))
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.blue)
                                Text("Carbs")
                            }
                            Spacer()
                            Text(String(format: "%.1f g", totalCarbs))
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.purple)
                                Text("Fat")
                            }
                            Spacer()
                            Text(String(format: "%.1f g", totalFat))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Favorite Toggle
                Section {
                    Toggle(isOn: $isFavorite) {
                        HStack(spacing: 8) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                            Text("Mark as Favorite")
                        }
                    }
                }

                // Help Text
                Section {
                    Text("* Required fields")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(editingMeal == nil ? "Create Meal" : "Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(editingMeal == nil ? "Save" : "Update") {
                        saveMeal()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                MealFoodSearchView(
                    viewModel: viewModel,
                    onSelect: { selectedFood in
                        addFoodToMeal(selectedFood)
                    }
                )
            }
            .alert("Edit Quantity", isPresented: Binding(
                get: { isEditingQuantity != nil },
                set: { if !$0 { isEditingQuantity = nil } }
            )) {
                TextField("Quantity", text: $editingQuantityValue)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) {
                    isEditingQuantity = nil
                }
                Button("Save") {
                    if let food = isEditingQuantity,
                       let newQuantity = Double(editingQuantityValue),
                       newQuantity > 0 {
                        updateFoodQuantity(food, newQuantity: newQuantity)
                    }
                    isEditingQuantity = nil
                }
            } message: {
                if let food = isEditingQuantity {
                    Text("Enter quantity for \(food.foodName)")
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .task {
                if let mealId = mealId {
                    await loadMealFoods(mealId: mealId)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadMealFoods(mealId: UUID) async {
        await viewModel.loadMealFoods(mealId: mealId)
        mealFoods = viewModel.selectedMealFoods
    }

    private func addFoodToMeal(_ food: FoodItem) {
        let newMealFood = CustomMealFood(
            id: UUID(),
            mealId: mealId ?? UUID(),
            customFoodId: food.customFoodId,
            usdaFdcId: food.usdaFdcId,
            foodName: food.name,
            brandName: food.brand,
            quantity: 1.0,
            servingSize: food.servingSize,
            servingUnit: food.servingUnit,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            createdAt: Date()
        )

        mealFoods.append(newMealFood)
    }

    private func removeFoodFromMeal(_ food: CustomMealFood) {
        mealFoods.removeAll { $0.id == food.id }
    }

    private func updateFoodQuantity(_ food: CustomMealFood, newQuantity: Double) {
        if let index = mealFoods.firstIndex(where: { $0.id == food.id }) {
            let baseFood = food
            let multiplier = newQuantity / food.quantity

            mealFoods[index] = CustomMealFood(
                id: baseFood.id,
                mealId: baseFood.mealId,
                customFoodId: baseFood.customFoodId,
                usdaFdcId: baseFood.usdaFdcId,
                foodName: baseFood.foodName,
                brandName: baseFood.brandName,
                quantity: newQuantity,
                servingSize: baseFood.servingSize,
                servingUnit: baseFood.servingUnit,
                calories: Int(Double(baseFood.calories) * multiplier),
                protein: baseFood.protein * multiplier,
                carbs: baseFood.carbs * multiplier,
                fat: baseFood.fat * multiplier,
                createdAt: baseFood.createdAt
            )
        }
    }

    private func saveMeal() {
        // Validate
        guard validateFields() else { return }

        Task {
            if let editingMeal = editingMeal {
                // Update existing meal
                let success = await viewModel.updateCustomMeal(
                    mealId: editingMeal.id,
                    name: name,
                    description: description.isEmpty ? nil : description,
                    isFavorite: isFavorite
                )

                if success {
                    // Update meal foods if needed
                    // (In production, implement full sync logic here)
                    dismiss()
                }
            } else {
                // Create new meal
                if let newMeal = await viewModel.createCustomMeal(
                    name: name,
                    description: description.isEmpty ? nil : description,
                    isFavorite: isFavorite
                ) {
                    // Persist each food to the meal
                    for food in mealFoods {
                        let request = AddFoodToMealRequest(
                            mealId: newMeal.id,
                            customFoodId: food.customFoodId,
                            usdaFdcId: food.usdaFdcId,
                            foodName: food.foodName,
                            brandName: food.brandName,
                            quantity: food.quantity,
                            servingSize: food.servingSize,
                            servingUnit: food.servingUnit,
                            calories: food.calories,
                            protein: food.protein,
                            carbs: food.carbs,
                            fat: food.fat
                        )
                        _ = try? await viewModel.addFoodToMeal(request: request)
                    }
                    dismiss()
                }
            }
        }
    }

    private func validateFields() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a meal name"
            showingValidationError = true
            return false
        }

        if mealFoods.isEmpty {
            validationMessage = "Please add at least one food to the meal"
            showingValidationError = true
            return false
        }

        return true
    }
}

// MARK: - Meal Food Row

struct MealFoodRow: View {
    let food: CustomMealFood
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(food.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(food.servingDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Text("\(food.calories) cal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("P: \(String(format: "%.1f", food.protein))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("C: \(String(format: "%.1f", food.carbs))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("F: \(String(format: "%.1f", food.fat))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash.circle")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Food Item Model

struct FoodItem: Identifiable {
    let id = UUID()
    let customFoodId: UUID?
    let usdaFdcId: String?
    let name: String
    let brand: String?
    let servingSize: String
    let servingUnit: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

// MARK: - Meal Food Search View

struct MealFoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FoodViewModel
    @StateObject private var usdaViewModel = FoodSearchViewModel()

    @State private var selectedTab: Int = 0
    @State private var searchText: String = ""

    let onSelect: (FoodItem) -> Void

    var body: some View {
        NavigationView {
            VStack {
                Picker("Source", selection: $selectedTab) {
                    Text("USDA").tag(0)
                    Text("My Foods").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _ in
                            if selectedTab == 0 {
                                usdaViewModel.searchText = searchText
                                usdaViewModel.performSearch()
                            }
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Results
                if selectedTab == 0 {
                    // USDA Foods
                    if !usdaViewModel.searchResults.isEmpty {
                        List(usdaViewModel.searchResults) { food in
                            Button {
                                let foodItem = FoodItem(
                                    customFoodId: nil,
                                    usdaFdcId: String(food.fdcId),
                                    name: food.description,
                                    brand: food.brandName,
                                    servingSize: food.servingSize.map { String(format: "%.0f", $0) } ?? "100",
                                    servingUnit: food.servingSizeUnit ?? "g",
                                    calories: Int(food.calories ?? 0),
                                    protein: food.protein ?? 0,
                                    carbs: food.carbohydrates ?? 0,
                                    fat: food.fat ?? 0
                                )
                                onSelect(foodItem)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(food.description)
                                        .font(.subheadline)
                                    InlineMacroView(
                                        calories: Int(food.calories ?? 0),
                                        protein: food.protein ?? 0,
                                        carbs: food.carbohydrates ?? 0,
                                        fat: food.fat ?? 0
                                    )
                                }
                            }
                        }
                    }
                } else {
                    // Custom Foods
                    let filteredFoods = searchText.isEmpty ? viewModel.customFoods : viewModel.customFoods.filter {
                        $0.name.localizedCaseInsensitiveContains(searchText)
                    }

                    List(filteredFoods) { food in
                        Button {
                            let foodItem = FoodItem(
                                customFoodId: food.id,
                                usdaFdcId: nil,
                                name: food.name,
                                brand: food.brand,
                                servingSize: food.servingSize,
                                servingUnit: food.servingUnit,
                                calories: food.calories,
                                protein: food.protein,
                                carbs: food.carbs,
                                fat: food.fat
                            )
                            onSelect(foodItem)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(food.displayName)
                                    .font(.subheadline)
                                InlineMacroView(
                                    calories: food.calories,
                                    protein: food.protein,
                                    carbs: food.carbs,
                                    fat: food.fat
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Food to Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateCustomMealView(viewModel: FoodViewModel())
}

