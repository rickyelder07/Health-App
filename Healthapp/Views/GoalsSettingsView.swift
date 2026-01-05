//
//  GoalsSettingsView.swift
//  Netfuel
//
//  Goals and targets settings view
//

import SwiftUI

/// Goals settings view
struct GoalsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var calorieGoalSource: UserSettings.CalorieGoalSource = .tdee
    @State private var calorieTarget: String = ""
    @State private var weightGoal: String = ""

    @State private var proteinGrams: String = ""
    @State private var carbsGrams: String = ""
    @State private var fatGrams: String = ""

    var body: some View {
        Form {
            // Calorie Target Section
            Section {
                Picker("Goal Source", selection: $calorieGoalSource) {
                    ForEach(UserSettings.CalorieGoalSource.allCases, id: \.self) { source in
                        VStack(alignment: .leading) {
                            Text(source.displayName)
                            Text(source.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(source)
                    }
                }
                .pickerStyle(.inline)

                // Show current value based on source
                HStack {
                    Text("Daily Goal")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(currentCalorieGoal) cal/day")
                        .fontWeight(.semibold)
                        .foregroundColor(calorieGoalSource == .bmr ? .blue : calorieGoalSource == .tdee ? .green : .orange)
                }

                // Custom target input (only show when custom is selected)
                if calorieGoalSource == .custom {
                    HStack {
                        Text("Custom Target")
                            .frame(width: 120, alignment: .leading)
                        TextField("Calories", text: $calorieTarget)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("cal")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Daily Calorie Goal")
            } footer: {
                Text(calorieGoalSource.description)
            }

            // Macro Targets Section
            Section {
                HStack {
                    Text("Protein")
                        .frame(width: 80, alignment: .leading)
                    TextField("Grams", text: $proteinGrams)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundColor(.secondary)

                    Text("(\(proteinPercentage)%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                }

                HStack {
                    Text("Carbs")
                        .frame(width: 80, alignment: .leading)
                    TextField("Grams", text: $carbsGrams)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundColor(.secondary)

                    Text("(\(carbsPercentage)%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                }

                HStack {
                    Text("Fat")
                        .frame(width: 80, alignment: .leading)
                    TextField("Grams", text: $fatGrams)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundColor(.secondary)

                    Text("(\(fatPercentage)%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                }

                // Total calories from macros
                HStack {
                    Text("Total from macros")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(totalMacroCalories) cal")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(macrosMatchTarget ? .green : .orange)
                }
            } header: {
                Text("Macro Targets")
            } footer: {
                Text("Set your daily macro targets in grams. Percentages are calculated based on your calorie target.")
            }

            // Weight Goal Section
            Section {
                HStack {
                    Text("Goal Weight")
                        .frame(width: 120, alignment: .leading)
                    TextField("Optional", text: $weightGoal)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text(UnitFormatter.weightUnit)
                        .foregroundColor(.secondary)
                }

                if let current = viewModel.user?.weight,
                   let goalInUserUnit = Double(weightGoal), !weightGoal.isEmpty {
                    // Convert goal from user's unit to kg for comparison
                    let settings = UserSettings.load()
                    let goalInKg = settings.weightUnit.toKg(goalInUserUnit)
                    HStack {
                        Text("Difference")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(UnitFormatter.formatWeightChange(goalInKg - current))
                            .fontWeight(.medium)
                            .foregroundColor(goalInKg < current ? .green : .red)
                    }
                }
            } header: {
                Text("Weight Goal")
            } footer: {
                Text("Optional: Set a target weight to track your progress.")
            }

            // Quick Presets
            Section {
                Button("Balanced (30/40/30)") {
                    setMacroPreset(protein: 30, carbs: 40, fat: 30)
                }

                Button("High Protein (40/30/30)") {
                    setMacroPreset(protein: 40, carbs: 30, fat: 30)
                }

                Button("Low Carb (35/20/45)") {
                    setMacroPreset(protein: 35, carbs: 20, fat: 45)
                }

                Button("Low Fat (30/50/20)") {
                    setMacroPreset(protein: 30, carbs: 50, fat: 20)
                }
            } header: {
                Text("Quick Presets")
            }

            // Save Button
            Section {
                Button {
                    saveGoals()
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Goals")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .navigationTitle("Goals & Targets")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .onAppear {
            loadCurrentValues()
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.successMessage = nil
                dismiss()
            }
        } message: {
            if let success = viewModel.successMessage {
                Text(success)
            }
        }
    }

    private var currentCalorieGoal: Int {
        switch calorieGoalSource {
        case .bmr:
            return viewModel.calculatedBMR
        case .tdee:
            return viewModel.calculatedTDEE
        case .custom:
            return Int(calorieTarget) ?? viewModel.calculatedTDEE
        }
    }

    private func loadCurrentValues() {
        calorieGoalSource = viewModel.settings.calorieGoalSource

        if let target = viewModel.settings.dailyCalorieTarget {
            calorieTarget = "\(target)"
        }

        if let protein = viewModel.settings.proteinTargetGrams {
            proteinGrams = String(format: "%.0f", protein)
        }

        if let carbs = viewModel.settings.carbsTargetGrams {
            carbsGrams = String(format: "%.0f", carbs)
        }

        if let fat = viewModel.settings.fatTargetGrams {
            fatGrams = String(format: "%.0f", fat)
        }

        if let goalKg = viewModel.settings.weightGoal {
            // Convert from kg (storage) to user's preferred unit (display)
            let settings = UserSettings.load()
            let goalInUserUnit = settings.weightUnit.convert(fromKg: goalKg)
            weightGoal = String(format: "%.1f", goalInUserUnit)
        }
    }

    private var targetCalories: Int {
        currentCalorieGoal
    }

    private var proteinCal: Int {
        Int((Double(proteinGrams) ?? 0) * 4)
    }

    private var carbsCal: Int {
        Int((Double(carbsGrams) ?? 0) * 4)
    }

    private var fatCal: Int {
        Int((Double(fatGrams) ?? 0) * 9)
    }

    private var totalMacroCalories: Int {
        proteinCal + carbsCal + fatCal
    }

    private var proteinPercentage: Int {
        guard targetCalories > 0 else { return 0 }
        return Int((Double(proteinCal) / Double(targetCalories)) * 100)
    }

    private var carbsPercentage: Int {
        guard targetCalories > 0 else { return 0 }
        return Int((Double(carbsCal) / Double(targetCalories)) * 100)
    }

    private var fatPercentage: Int {
        guard targetCalories > 0 else { return 0 }
        return Int((Double(fatCal) / Double(targetCalories)) * 100)
    }

    private var macrosMatchTarget: Bool {
        abs(totalMacroCalories - targetCalories) < 50
    }

    private func setMacroPreset(protein: Int, carbs: Int, fat: Int) {
        let calories = Double(targetCalories)

        proteinGrams = String(format: "%.0f", (calories * Double(protein) / 100) / 4)
        carbsGrams = String(format: "%.0f", (calories * Double(carbs) / 100) / 4)
        fatGrams = String(format: "%.0f", (calories * Double(fat) / 100) / 9)
    }

    private func saveGoals() {
        viewModel.settings.calorieGoalSource = calorieGoalSource

        if calorieGoalSource == .custom, let target = Int(calorieTarget) {
            viewModel.settings.dailyCalorieTarget = target
        } else {
            viewModel.settings.dailyCalorieTarget = nil
        }

        if let protein = Double(proteinGrams), !proteinGrams.isEmpty {
            viewModel.settings.proteinTargetGrams = protein
        }

        if let carbs = Double(carbsGrams), !carbsGrams.isEmpty {
            viewModel.settings.carbsTargetGrams = carbs
        }

        if let fat = Double(fatGrams), !fatGrams.isEmpty {
            viewModel.settings.fatTargetGrams = fat
        }

        if let goalInUserUnit = Double(weightGoal), !weightGoal.isEmpty {
            // Convert from user's preferred unit (input) to kg (storage)
            let settings = UserSettings.load()
            let goalInKg = settings.weightUnit.toKg(goalInUserUnit)
            viewModel.settings.weightGoal = goalInKg
        } else {
            viewModel.settings.weightGoal = nil
        }

        viewModel.saveSettings()
    }
}
