//
//  CreateCustomMealView.swift
//  Netfuel
//

import SwiftUI

// MARK: - Meal Ingredient (local model)

struct MealIngredient: Identifiable {
    let id = UUID()
    let foodItem: FoodItem      // nutrition at 1× serving
    var quantity: Double        // serving multiplier

    var displayName: String {
        if let brand = foodItem.brand, !brand.isEmpty {
            return "\(foodItem.name) · \(brand)"
        }
        return foodItem.name
    }
    var servingInfo: String { "\(foodItem.servingSize) \(foodItem.servingUnit)" }

    var calories: Int   { Int(Double(foodItem.calories) * quantity) }
    var protein: Double { foodItem.protein * quantity }
    var carbs: Double   { foodItem.carbs * quantity }
    var fat: Double     { foodItem.fat * quantity }
}

// MARK: - Create Custom Meal View

struct CreateCustomMealView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FoodViewModel
    let editingMeal: CustomMeal?

    @State private var mealName = ""
    @State private var isFavorite = false
    @State private var ingredients: [MealIngredient] = []
    @State private var mealId: UUID?

    // Inline search
    @State private var searchText = ""
    @State private var searchSource: SearchSource = .myFoods
    @StateObject private var usdaViewModel = FoodSearchViewModel()
    @FocusState private var searchFocused: Bool

    @State private var showingError = false
    @State private var errorMessage = ""

    enum SearchSource: String, CaseIterable {
        case myFoods = "My Foods"
        case usda = "USDA"
    }

    init(viewModel: FoodViewModel, editingMeal: CustomMeal? = nil) {
        self.viewModel = viewModel
        self.editingMeal = editingMeal
        if let meal = editingMeal {
            _mealName = State(initialValue: meal.name)
            _isFavorite = State(initialValue: meal.isFavorite)
            _mealId = State(initialValue: meal.id)
        }
    }

    // MARK: - Computed

    private var totalCalories: Int   { ingredients.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { ingredients.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double   { ingredients.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double     { ingredients.reduce(0) { $0 + $1.fat } }
    private var isSearchActive: Bool { !searchText.isEmpty || searchFocused }

    private var filteredCustomFoods: [CustomFood] {
        guard !searchText.isEmpty else { return viewModel.customFoods }
        return viewModel.customFoods.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameSection
                    searchSection
                    if isSearchActive {
                        searchResultsSection
                    } else if ingredients.isEmpty {
                        emptyHint
                    } else {
                        ingredientsSection
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom) { liveTotalsFooter }
            .navigationTitle(editingMeal == nil ? "New Meal" : "Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isLoading {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button("Save") { saveMeal() }
                            .fontWeight(.semibold)
                            .disabled(
                                mealName.trimmingCharacters(in: .whitespaces).isEmpty ||
                                ingredients.isEmpty
                            )
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                if let mealId { await loadExistingIngredients(mealId: mealId) }
            }
        }
    }

    // MARK: - Name Section

    @ViewBuilder
    private var nameSection: some View {
        HStack(spacing: 12) {
            TextField("Meal name", text: $mealName)
                .font(.title3).fontWeight(.semibold)
                .autocorrectionDisabled()
                .submitLabel(.done)

            Button {
                isFavorite.toggle()
                HapticFeedback.selection()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .secondary)
                    .font(.title3)
                    .animation(.spring(response: 0.3), value: isFavorite)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Search Section

    @ViewBuilder
    private var searchSection: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(searchFocused ? .accentColor : .secondary)

                TextField("Add an ingredient...", text: $searchText)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { text in
                        if searchSource == .usda {
                            usdaViewModel.searchText = text
                            usdaViewModel.performSearch()
                        }
                    }
                    .submitLabel(.search)

                if !searchText.isEmpty || searchFocused {
                    Button {
                        searchText = ""
                        searchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            if isSearchActive {
                Picker("Source", selection: $searchSource) {
                    ForEach(SearchSource.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: searchSource) { _ in
                    if searchSource == .usda, !searchText.isEmpty {
                        usdaViewModel.searchText = searchText
                        usdaViewModel.performSearch()
                    }
                }
            }
        }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch searchSource {
            case .myFoods:
                if filteredCustomFoods.isEmpty {
                    searchEmptyState(
                        searchText.isEmpty
                            ? "No saved foods yet. Switch to USDA to search."
                            : "No saved foods matching \"\(searchText)\""
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(filteredCustomFoods.prefix(8)) { food in
                            FoodSearchResultRow(
                                name: food.displayName,
                                subtitle: food.servingDescription,
                                calories: food.calories,
                                protein: food.protein,
                                carbs: food.carbs,
                                fat: food.fat,
                                onAdd: { addCustomFood(food) }
                            )
                        }
                    }
                }

            case .usda:
                if usdaViewModel.isSearching {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.8)
                        Text("Searching USDA...")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if searchText.isEmpty {
                    searchEmptyState("Type to search the USDA FoodData Central database")
                } else if usdaViewModel.searchResults.isEmpty {
                    searchEmptyState("No results for \"\(searchText)\"")
                } else {
                    VStack(spacing: 8) {
                        ForEach(usdaViewModel.searchResults.prefix(8)) { food in
                            FoodSearchResultRow(
                                name: food.description,
                                subtitle: food.brandName,
                                calories: Int(food.calories ?? 0),
                                protein: food.protein ?? 0,
                                carbs: food.carbohydrates ?? 0,
                                fat: food.fat ?? 0,
                                onAdd: { addUSDAFood(food) }
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func searchEmptyState(_ message: String) -> some View {
        Text(message)
            .font(.subheadline).foregroundColor(.secondary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty Hint

    @ViewBuilder
    private var emptyHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.up.to.line")
                .font(.system(size: 32)).foregroundColor(.secondary)
            Text("Search above to add ingredients")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    // MARK: - Ingredients Section

    @ViewBuilder
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ingredients (\(ingredients.count))")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(ingredients) { ingredient in
                    IngredientCard(
                        ingredient: ingredient,
                        onIncrease: { adjustQuantity(id: ingredient.id, delta: 0.25) },
                        onDecrease: { adjustQuantity(id: ingredient.id, delta: -0.25) },
                        onRemove:   { removeIngredient(id: ingredient.id) }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal:   .scale(scale: 0.96).combined(with: .opacity)
                    ))
                }
            }
        }
        .animation(.spring(response: 0.35), value: ingredients.map { $0.id })
    }

    // MARK: - Live Totals Footer

    @ViewBuilder
    private var liveTotalsFooter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(ingredients.isEmpty ? "–" : "\(totalCalories)")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(ingredients.isEmpty ? .secondary : .primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: totalCalories)
                    Text("cal")
                        .font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Color.secondary.opacity(0.25).frame(width: 0.5, height: 32)

                MealMacroColumn(label: "Protein", value: totalProtein, color: .red,    isEmpty: ingredients.isEmpty)
                MealMacroColumn(label: "Carbs",   value: totalCarbs,   color: .blue,   isEmpty: ingredients.isEmpty)
                MealMacroColumn(label: "Fat",     value: totalFat,     color: .purple, isEmpty: ingredients.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    // MARK: - Actions

    private func addCustomFood(_ food: CustomFood) {
        let item = FoodItem(
            customFoodId: food.id, usdaFdcId: nil,
            name: food.name, brand: food.brand,
            servingSize: food.servingSize, servingUnit: food.servingUnit,
            calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat
        )
        withAnimation { ingredients.append(MealIngredient(foodItem: item, quantity: 1.0)) }
        searchText = ""; searchFocused = false
        HapticFeedback.light()
    }

    private func addUSDAFood(_ food: USDAFood) {
        let item = FoodItem(
            customFoodId: nil, usdaFdcId: String(food.fdcId),
            name: food.description, brand: food.brandName,
            servingSize: food.servingSize.map { String(format: "%.0f", $0) } ?? "100",
            servingUnit: food.servingSizeUnit ?? "g",
            calories: Int(food.calories ?? 0),
            protein: food.protein ?? 0, carbs: food.carbohydrates ?? 0, fat: food.fat ?? 0
        )
        withAnimation { ingredients.append(MealIngredient(foodItem: item, quantity: 1.0)) }
        searchText = ""; searchFocused = false
        HapticFeedback.light()
    }

    private func adjustQuantity(id: UUID, delta: Double) {
        guard let i = ingredients.firstIndex(where: { $0.id == id }) else { return }
        let newQty = max(0.25, (ingredients[i].quantity + delta * 4).rounded() / 4)
        ingredients[i].quantity = newQty
        HapticFeedback.selection()
    }

    private func removeIngredient(id: UUID) {
        withAnimation { ingredients.removeAll { $0.id == id } }
        HapticFeedback.medium()
    }

    private func loadExistingIngredients(mealId: UUID) async {
        await viewModel.loadMealFoods(mealId: mealId)
        ingredients = viewModel.selectedMealFoods.map { mf in
            let base = mf.quantity > 0 ? mf.quantity : 1.0
            let item = FoodItem(
                customFoodId: mf.customFoodId, usdaFdcId: mf.usdaFdcId,
                name: mf.foodName, brand: mf.brandName,
                servingSize: mf.servingSize, servingUnit: mf.servingUnit,
                calories: Int(Double(mf.calories) / base),
                protein: mf.protein / base, carbs: mf.carbs / base, fat: mf.fat / base
            )
            return MealIngredient(foodItem: item, quantity: mf.quantity)
        }
    }

    private func saveMeal() {
        let name = mealName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !ingredients.isEmpty else { return }

        Task {
            if let editingMeal {
                let ok = await viewModel.updateCustomMeal(
                    mealId: editingMeal.id, name: name, description: nil, isFavorite: isFavorite
                )
                if ok { dismiss() }
            } else {
                guard let newMeal = await viewModel.createCustomMeal(
                    name: name, description: nil, isFavorite: isFavorite
                ) else {
                    errorMessage = viewModel.errorMessage ?? "Failed to save meal"
                    showingError = true
                    viewModel.clearMessages()
                    return
                }
                for ing in ingredients {
                    let req = AddFoodToMealRequest(
                        mealId: newMeal.id,
                        customFoodId: ing.foodItem.customFoodId,
                        usdaFdcId: ing.foodItem.usdaFdcId,
                        foodName: ing.foodItem.name,
                        brandName: ing.foodItem.brand,
                        quantity: ing.quantity,
                        servingSize: ing.foodItem.servingSize,
                        servingUnit: ing.foodItem.servingUnit,
                        calories: ing.calories,
                        protein: ing.protein,
                        carbs: ing.carbs,
                        fat: ing.fat
                    )
                    _ = try? await viewModel.addFoodToMeal(request: req)
                }
                dismiss()
            }
        }
    }
}

// MARK: - Ingredient Card

struct IngredientCard: View {
    let ingredient: MealIngredient
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.displayName)
                        .font(.subheadline).fontWeight(.medium)
                    Text(ingredient.servingInfo)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.systemGray3))
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }

            // Quantity stepper
            HStack(spacing: 0) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(ingredient.quantity <= 0.25 ? Color(.systemGray4) : .accentColor)
                }
                .buttonStyle(.borderless)
                .disabled(ingredient.quantity <= 0.25)

                Spacer()

                VStack(spacing: 1) {
                    Text(formattedQty(ingredient.quantity))
                        .font(.headline).fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: ingredient.quantity)
                    Text(ingredient.quantity == 1.0 ? "serving" : "servings")
                        .font(.caption2).foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onIncrease) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 4)

            // Scaled nutrition
            HStack(spacing: 12) {
                Text("\(ingredient.calories) cal")
                    .font(.caption).fontWeight(.semibold)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: ingredient.calories)
                Spacer()
                MealMacroTag(letter: "P", value: ingredient.protein, color: .red)
                MealMacroTag(letter: "C", value: ingredient.carbs,   color: .blue)
                MealMacroTag(letter: "F", value: ingredient.fat,     color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func formattedQty(_ q: Double) -> String {
        let quarters = Int((q * 4).rounded())
        let whole = quarters / 4
        let rem = quarters % 4
        let fracs = ["", "¼", "½", "¾"]
        if whole == 0 { return fracs[rem] }
        if rem == 0   { return "\(whole)" }
        return "\(whole)\(fracs[rem])"
    }
}

// MARK: - Food Search Result Row

struct FoodSearchResultRow: View {
    let name: String
    let subtitle: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(2)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Text("\(calories) cal").font(.caption2).foregroundColor(.secondary)
                    MealMacroTag(letter: "P", value: protein, color: .red)
                    MealMacroTag(letter: "C", value: carbs,   color: .blue)
                    MealMacroTag(letter: "F", value: fat,     color: .purple)
                }
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Macro Helpers

struct MealMacroTag: View {
    let letter: String
    let value: Double
    let color: Color

    var body: some View {
        Text("\(letter): \(String(format: "%.0f", value))g")
            .font(.caption2).foregroundColor(color)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.15), value: value)
    }
}

struct MealMacroColumn: View {
    let label: String
    let value: Double
    let color: Color
    let isEmpty: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(isEmpty ? "–" : String(format: "%.0f", value))
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(isEmpty ? .secondary : color)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: value)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Legacy support (FoodItem + MealFoodSearchView kept for FoodSearchView compatibility)

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

#Preview {
    CreateCustomMealView(viewModel: FoodViewModel())
}
