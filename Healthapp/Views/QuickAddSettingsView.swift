//
//  QuickAddSettingsView.swift
//  Netfuel
//
//  Configuration view for quick-add food buttons
//

import SwiftUI

/// Quick-add buttons configuration view
struct QuickAddSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var foodViewModel = FoodViewModel()
    @EnvironmentObject var appState: AppState

    @State private var settings: QuickAddSettings
    @State private var numberOfButtons: Int
    @State private var editingButton: QuickAddFoodButton?
    @State private var showingButtonEditor = false

    private let userId: UUID?

    init(userId: UUID? = nil) {
        self.userId = userId
        let loadedSettings = QuickAddSettings.load(userId: userId)
        _settings = State(initialValue: loadedSettings)
        _numberOfButtons = State(initialValue: max(1, min(6, loadedSettings.buttons.count)))
    }

    var body: some View {
        NavigationView {
            Form {
                // Number of buttons
                Section {
                    Stepper("Number of Buttons: \(numberOfButtons)", value: $numberOfButtons, in: 1...6)
                        .onChange(of: numberOfButtons) { newValue in
                            adjustButtonCount(to: newValue)
                        }
                } header: {
                    Text("Quick-Add Buttons")
                } footer: {
                    Text("Choose between 1-6 quick-add buttons to appear on the Food tab.")
                }

                // Configure each button
                Section {
                    ForEach(Array(settings.buttons.enumerated()), id: \.element.id) { index, button in
                        Button {
                            editingButton = button
                            showingButtonEditor = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(button.label)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(button.foodName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 8) {
                                        Text(button.foodSource.displayName)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)

                                        Text("\(String(format: "%.1f", button.servings))× servings")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)

                                        Text(button.mealType.displayName)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Button Configuration")
                } footer: {
                    Text("Tap a button to edit its configuration.")
                }

                // Save button
                Section {
                    Button {
                        print("📱 Save Configuration button tapped")
                        print("📱 Current settings: \(settings.buttons.count) buttons")
                        for (index, button) in settings.buttons.enumerated() {
                            print("📱 Button \(index + 1): \(button.label) - \(button.foodName)")
                        }
                        settings.save(userId: userId ?? appState.currentUser?.id)
                        dismiss()
                    } label: {
                        Text("Save Configuration")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Quick-Add Buttons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingButtonEditor) {
                if let button = editingButton,
                   let index = settings.buttons.firstIndex(where: { $0.id == button.id }) {
                    QuickAddButtonEditorView(
                        button: $settings.buttons[index],
                        foodViewModel: foodViewModel
                    )
                }
            }
            .task {
                if let userId = appState.currentUser?.id {
                    foodViewModel.setUser(userId: userId)
                }
            }
        }
    }

    private func adjustButtonCount(to count: Int) {
        if count > settings.buttons.count {
            // Add new buttons
            let toAdd = count - settings.buttons.count
            for i in 0..<toAdd {
                let newButton = QuickAddFoodButton(
                    label: "Button \(settings.buttons.count + i + 1)",
                    foodSource: .customFood,
                    servings: 1.0,
                    mealType: .breakfast,
                    foodName: "Not configured"
                )
                settings.buttons.append(newButton)
            }
        } else if count < settings.buttons.count {
            // Remove excess buttons
            settings.buttons = Array(settings.buttons.prefix(count))
        }
    }
}

// MARK: - Button Editor View

struct QuickAddButtonEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var button: QuickAddFoodButton
    @ObservedObject var foodViewModel: FoodViewModel

    @State private var label: String
    @State private var foodSource: QuickAddFoodSource
    @State private var servings: String
    @State private var mealType: MealType
    @State private var selectedFood: Any?
    @State private var searchText: String = ""

    init(button: Binding<QuickAddFoodButton>, foodViewModel: FoodViewModel) {
        self._button = button
        self.foodViewModel = foodViewModel
        _label = State(initialValue: button.wrappedValue.label)
        _foodSource = State(initialValue: button.wrappedValue.foodSource)
        _servings = State(initialValue: String(format: "%.1f", button.wrappedValue.servings))
        _mealType = State(initialValue: button.wrappedValue.mealType)
    }

    var body: some View {
        NavigationView {
            Form {
                // Label
                Section {
                    TextField("Button Label", text: $label)
                } header: {
                    Text("Button Label")
                } footer: {
                    Text("Short name for the quick-add button (e.g., 'Breakfast', 'Protein Shake')")
                }

                // Food source
                Section {
                    Picker("Food Source", selection: $foodSource) {
                        ForEach(QuickAddFoodSource.allCases, id: \.self) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Food Source")
                }

                // Food selection
                Section {
                    FoodSelectionSection(
                        foodSource: foodSource,
                        foodViewModel: foodViewModel,
                        searchText: $searchText,
                        selectedFood: $selectedFood,
                        button: $button
                    )
                } header: {
                    Text("Select Food/Meal")
                }

                // Servings
                Section {
                    HStack {
                        Text("Servings")
                        Spacer()
                        TextField("1.0", text: $servings)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Serving Size")
                }

                // Meal type
                Section {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                } header: {
                    Text("Meal Type")
                }

                // Save button
                Section {
                    Button {
                        saveButton()
                    } label: {
                        Text("Save Button")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Edit Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                // Pre-populate selectedFood when editing an existing button
                if selectedFood == nil {
                    if let customFoodId = button.customFoodId {
                        selectedFood = foodViewModel.customFoods.first(where: { $0.id == customFoodId })
                    } else if let customMealId = button.customMealId {
                        selectedFood = foodViewModel.customMeals.first(where: { $0.id == customMealId })
                    }
                    // Note: USDA foods are not supported in quick config, so we don't need to handle usdaFdcId
                }
            }
        }
    }

    private var isValid: Bool {
        !label.isEmpty && selectedFood != nil && Double(servings) != nil
    }

    private func saveButton() {
        guard let servingsValue = Double(servings) else {
            print("❌ Invalid servings value: \(servings)")
            return
        }

        print("📱 Saving button configuration...")
        print("📱 Label: \(label)")
        print("📱 Food Source: \(foodSource.displayName)")
        print("📱 Servings: \(servingsValue)")
        print("📱 Meal Type: \(mealType.displayName)")

        button.label = label
        button.foodSource = foodSource
        button.servings = servingsValue
        button.mealType = mealType

        // Update food reference based on selectedFood
        if let customFood = selectedFood as? CustomFood {
            button.customFoodId = customFood.id
            button.usdaFdcId = nil
            button.customMealId = nil
            button.foodName = customFood.name
            print("📱 Set custom food: \(customFood.name) (ID: \(customFood.id))")
        } else if let customMeal = selectedFood as? CustomMeal {
            button.customMealId = customMeal.id
            button.usdaFdcId = nil
            button.customFoodId = nil
            button.foodName = customMeal.name
            print("📱 Set custom meal: \(customMeal.name) (ID: \(customMeal.id))")
        } else if let usdaFood = selectedFood as? USDAFood {
            button.usdaFdcId = usdaFood.fdcId
            button.customFoodId = nil
            button.customMealId = nil
            button.foodName = usdaFood.description
            print("📱 Set USDA food: \(usdaFood.description) (FDC ID: \(usdaFood.fdcId))")
        }

        print("✅ Button configuration saved to binding")
        dismiss()
    }
}

// MARK: - Food Selection Section

struct FoodSelectionSection: View {
    let foodSource: QuickAddFoodSource
    @ObservedObject var foodViewModel: FoodViewModel
    @Binding var searchText: String
    @Binding var selectedFood: Any?
    @Binding var button: QuickAddFoodButton

    var body: some View {
        Group {
            switch foodSource {
            case .customFood:
                CustomFoodPicker(
                    foods: foodViewModel.customFoods,
                    searchText: $searchText,
                    selectedFood: $selectedFood,
                    button: $button
                )

            case .customMeal:
                CustomMealPicker(
                    meals: foodViewModel.customMeals,
                    searchText: $searchText,
                    selectedFood: $selectedFood,
                    button: $button
                )

            case .usda:
                Text("USDA search not available in quick configuration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Please use My Foods or My Meals")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Custom Food Picker

struct CustomFoodPicker: View {
    let foods: [CustomFood]
    @Binding var searchText: String
    @Binding var selectedFood: Any?
    @Binding var button: QuickAddFoodButton

    private var filteredFoods: [CustomFood] {
        if searchText.isEmpty {
            return foods
        }
        return foods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if filteredFoods.isEmpty {
                Text("No custom foods found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredFoods.prefix(10)) { food in
                    Button {
                        selectedFood = food
                        button.foodName = food.name
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Text("\(food.calories) cal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let selected = selectedFood as? CustomFood, selected.id == food.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Custom Meal Picker

struct CustomMealPicker: View {
    let meals: [CustomMeal]
    @Binding var searchText: String
    @Binding var selectedFood: Any?
    @Binding var button: QuickAddFoodButton

    private var filteredMeals: [CustomMeal] {
        if searchText.isEmpty {
            return meals
        }
        return meals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search meals...", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if filteredMeals.isEmpty {
                Text("No custom meals found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredMeals.prefix(10)) { meal in
                    Button {
                        selectedFood = meal
                        button.foodName = meal.name
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Text("\(meal.totalCalories) cal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let selected = selectedFood as? CustomMeal, selected.id == meal.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

#Preview {
    QuickAddSettingsView()
        .environmentObject(AppState())
}
