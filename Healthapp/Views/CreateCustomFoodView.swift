//
//  CreateCustomFoodView.swift
//  Netfuel
//
//  View for creating/editing custom foods
//

import SwiftUI

/// View for creating or editing a custom food
struct CreateCustomFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FoodViewModel
    
    // Edit mode
    let editingFood: CustomFood?
    
    // Form fields
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var servingSize: String = ""
    @State private var servingUnit: String = "g"
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var fiber: String = ""
    @State private var sugar: String = ""
    @State private var sodium: String = ""
    @State private var isFavorite: Bool = false
    
    // UI State
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    // Serving units
    private let servingUnits = ["g", "oz", "cup", "tbsp", "tsp", "ml", "serving", "piece", "slice"]
    
    init(viewModel: FoodViewModel, editingFood: CustomFood? = nil) {
        self.viewModel = viewModel
        self.editingFood = editingFood
        
        // Pre-fill fields if editing
        if let food = editingFood {
            _name = State(initialValue: food.name)
            _brand = State(initialValue: food.brand ?? "")
            _servingSize = State(initialValue: food.servingSize)
            _servingUnit = State(initialValue: food.servingUnit)
            _calories = State(initialValue: "\(food.calories)")
            _protein = State(initialValue: String(format: "%.1f", food.protein))
            _carbs = State(initialValue: String(format: "%.1f", food.carbs))
            _fat = State(initialValue: String(format: "%.1f", food.fat))
            _fiber = State(initialValue: food.fiber.map { String(format: "%.1f", $0) } ?? "")
            _sugar = State(initialValue: food.sugar.map { String(format: "%.1f", $0) } ?? "")
            _sodium = State(initialValue: food.sodium.map { String(format: "%.0f", $0) } ?? "")
            _isFavorite = State(initialValue: food.isFavorite)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Basic Information") {
                    TextField("Food Name *", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Brand (optional)", text: $brand)
                        .autocorrectionDisabled()
                }
                
                // Serving Information
                Section("Serving Size") {
                    HStack {
                        TextField("Amount *", text: $servingSize)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: .infinity)
                        
                        Picker("Unit", selection: $servingUnit) {
                            ForEach(servingUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                }
                
                // Nutrition Information (Required)
                Section("Nutrition Facts (per serving) *") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cal")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                            Text("Protein")
                        }
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.blue)
                            Text("Carbs")
                        }
                        Spacer()
                        TextField("0", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.purple)
                            Text("Fat")
                        }
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Optional Nutrition
                Section("Additional Nutrition (optional)") {
                    HStack {
                        Text("Fiber")
                        Spacer()
                        TextField("0", text: $fiber)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sugar")
                        Spacer()
                        TextField("0", text: $sugar)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sodium")
                        Spacer()
                        TextField("0", text: $sodium)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mg")
                            .foregroundColor(.secondary)
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
            .navigationTitle(editingFood == nil ? "Create Food" : "Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingFood == nil ? "Save" : "Update") {
                        saveFood()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveFood() {
        // Validate required fields
        guard validateFields() else { return }
        
        Task {
            let success: Bool
            
            if let editingFood = editingFood {
                // Update existing food
                success = await viewModel.updateCustomFood(
                    foodId: editingFood.id,
                    name: name.isEmpty ? nil : name,
                    brand: brand.isEmpty ? nil : brand,
                    calories: Int(calories),
                    protein: Double(protein),
                    carbs: Double(carbs),
                    fat: Double(fat),
                    fiber: fiber.isEmpty ? nil : Double(fiber),
                    sugar: sugar.isEmpty ? nil : Double(sugar),
                    sodium: sodium.isEmpty ? nil : Double(sodium),
                    servingSize: servingSize.isEmpty ? nil : servingSize,
                    servingUnit: servingUnit,
                    isFavorite: isFavorite
                )
            } else {
                // Create new food
                success = await viewModel.createCustomFood(
                    name: name,
                    brand: brand.isEmpty ? nil : brand,
                    calories: Int(calories) ?? 0,
                    protein: Double(protein) ?? 0,
                    carbs: Double(carbs) ?? 0,
                    fat: Double(fat) ?? 0,
                    fiber: fiber.isEmpty ? nil : Double(fiber),
                    sugar: sugar.isEmpty ? nil : Double(sugar),
                    sodium: sodium.isEmpty ? nil : Double(sodium),
                    servingSize: servingSize,
                    servingUnit: servingUnit,
                    isFavorite: isFavorite
                )
            }
            
            if success {
                dismiss()
            }
        }
    }
    
    private func validateFields() -> Bool {
        // Check required fields
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a food name"
            showingValidationError = true
            return false
        }
        
        if servingSize.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a serving size"
            showingValidationError = true
            return false
        }
        
        if calories.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter calories"
            showingValidationError = true
            return false
        }
        
        if protein.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter protein amount"
            showingValidationError = true
            return false
        }
        
        if carbs.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter carbs amount"
            showingValidationError = true
            return false
        }
        
        if fat.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter fat amount"
            showingValidationError = true
            return false
        }
        
        // Validate numeric fields
        guard Int(calories) != nil else {
            validationMessage = "Calories must be a valid number"
            showingValidationError = true
            return false
        }
        
        guard Double(protein) != nil else {
            validationMessage = "Protein must be a valid number"
            showingValidationError = true
            return false
        }
        
        guard Double(carbs) != nil else {
            validationMessage = "Carbs must be a valid number"
            showingValidationError = true
            return false
        }
        
        guard Double(fat) != nil else {
            validationMessage = "Fat must be a valid number"
            showingValidationError = true
            return false
        }
        
        return true
    }
}

#Preview {
    CreateCustomFoodView(viewModel: FoodViewModel())
}

