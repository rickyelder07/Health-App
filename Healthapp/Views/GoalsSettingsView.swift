//
//  GoalsSettingsView.swift
//  Netfuel
//
//  Goals and targets settings view
//

import SwiftUI

struct GoalsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var calorieMode: UserSettings.CalorieMode = .tdee
    @State private var fitnessGoal: UserSettings.FitnessGoal = .maintenance
    @State private var calorieTarget: String = ""
    @State private var weightGoal: String = ""
    @State private var proteinGrams: String = ""
    @State private var carbsGrams: String = ""
    @State private var fatGrams: String = ""

    private var tdee: Int { viewModel.calculatedTDEE }
    private var bmr: Int { viewModel.calculatedBMR }
    private var isStravaConnected: Bool { viewModel.stravaConnection != nil }

    /// Calorie goal used for macro % display. In Strava mode, uses BMR as baseline since exercise is dynamic.
    private var currentCalorieGoal: Int {
        if fitnessGoal == .manual { return Int(calorieTarget) ?? tdee }
        if calorieMode == .stravaDynamic {
            return max(1200, bmr + fitnessGoal.calorieOffset)
        }
        return max(1200, tdee + fitnessGoal.calorieOffset)
    }

    var body: some View {
        Form {
            // Budget Mode
            Section {
                budgetModeGrid
            } header: {
                Text("Budget Mode")
            } footer: {
                if calorieMode == .stravaDynamic {
                    Text("Your budget starts at BMR (\(bmr) cal) and grows as Strava activities sync. Best for athletes who want to eat what they earn.")
                } else {
                    Text("TDEE pre-estimates your weekly activity level into a fixed daily budget.")
                }
            }

            // Goal Mode
            Section {
                goalModeGrid
            } header: {
                Text("Fitness Goal")
            } footer: {
                if calorieMode == .stravaDynamic {
                    if bmr > 0 {
                        Text("BMR baseline of \(bmr) cal/day + today's Strava calories")
                    } else {
                        Text("Complete your profile to enable Strava Dynamic mode")
                    }
                } else {
                    if tdee > 0 {
                        Text("Based on your TDEE of \(tdee) cal/day")
                    } else {
                        Text("Complete your profile to see TDEE-based targets")
                    }
                }
            }

            // Calorie Target
            Section {
                HStack {
                    Text("Daily Target")
                        .foregroundColor(.secondary)
                    Spacer()
                    if fitnessGoal == .manual {
                        EmptyView()
                    } else if calorieMode == .stravaDynamic {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(bmr) + activity cal")
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            Text("Updates when Strava syncs")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("\(currentCalorieGoal) cal/day")
                            .fontWeight(.semibold)
                            .foregroundColor(goalColor)
                    }
                }

                if fitnessGoal == .manual {
                    HStack {
                        TextField("Calories", text: $calorieTarget)
                            .keyboardType(.numberPad)
                        Text("cal/day")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Calorie Target")
            }

            // Macro Targets
            Section {
                macroRow(label: "Protein", grams: $proteinGrams, calories: proteinCal, pct: proteinPercentage)
                macroRow(label: "Carbs",   grams: $carbsGrams,   calories: carbsCal,   pct: carbsPercentage)
                macroRow(label: "Fat",     grams: $fatGrams,     calories: fatCal,     pct: fatPercentage)

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
                Text("Percentages are based on your calorie target")
            }

            // Weight Goal
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
                Text("Optional: set a target weight to track progress")
            }

            // Quick Presets
            Section {
                presetButton("Balanced (30/40/30)", p: 30, c: 40, f: 30)
                presetButton("High Protein (40/30/30)", p: 40, c: 30, f: 30)
                presetButton("Low Carb (35/20/45)", p: 35, c: 20, f: 45)
                presetButton("Low Fat (30/50/20)", p: 30, c: 50, f: 20)
            } header: {
                Text("Quick Presets")
            }

            // Save
            Section {
                Button {
                    saveGoals()
                } label: {
                    if viewModel.isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Save Goals").frame(maxWidth: .infinity).fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .navigationTitle("Goals & Targets")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadData() }
        .onAppear { loadCurrentValues() }
        .onChange(of: fitnessGoal) { _, newGoal in
            if newGoal != .manual { applyGoalMacros(newGoal) }
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") { viewModel.successMessage = nil; dismiss() }
        } message: {
            if let msg = viewModel.successMessage { Text(msg) }
        }
    }

    // MARK: - Budget Mode Grid

    private var budgetModeGrid: some View {
        HStack(spacing: 12) {
            BudgetModeCard(
                mode: .tdee,
                isSelected: calorieMode == .tdee
            ) { calorieMode = .tdee }

            BudgetModeCard(
                mode: .stravaDynamic,
                isLocked: !isStravaConnected,
                isSelected: calorieMode == .stravaDynamic
            ) {
                if isStravaConnected { calorieMode = .stravaDynamic }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Goal Mode Grid

    private var goalModeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(UserSettings.FitnessGoal.allCases, id: \.self) { goal in
                let baseCalories: Int? = {
                    if calorieMode == .stravaDynamic {
                        guard bmr > 0 else { return nil }
                        return goal == .manual ? (Int(calorieTarget) ?? bmr) : max(1200, bmr + goal.calorieOffset)
                    } else {
                        guard tdee > 0 else { return nil }
                        return goal == .manual ? (Int(calorieTarget) ?? tdee) : max(1200, tdee + goal.calorieOffset)
                    }
                }()
                GoalModeCard(
                    goal: goal,
                    calories: baseCalories,
                    isStravaMode: calorieMode == .stravaDynamic && goal != .manual,
                    isSelected: fitnessGoal == goal
                ) {
                    fitnessGoal = goal
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var goalColor: Color {
        switch fitnessGoal {
        case .maintenance: return .blue
        case .cutting: return .green
        case .bulking: return calorieMode == .stravaDynamic ? .orange : .orange
        case .manual: return .purple
        }
    }

    private func macroRow(label: String, grams: Binding<String>, calories: Int, pct: Int) -> some View {
        HStack {
            Text(label).frame(width: 80, alignment: .leading)
            TextField("Grams", text: grams)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("g").foregroundColor(.secondary)
            Text("(\(pct)%)").font(.caption).foregroundColor(.secondary).frame(width: 50)
        }
    }

    private func presetButton(_ title: String, p: Int, c: Int, f: Int) -> some View {
        Button(title) { setMacroPreset(protein: p, carbs: c, fat: f) }
    }

    // MARK: - Macro Calculations

    private var proteinCal: Int { Int((Double(proteinGrams) ?? 0) * 4) }
    private var carbsCal:   Int { Int((Double(carbsGrams)   ?? 0) * 4) }
    private var fatCal:     Int { Int((Double(fatGrams)      ?? 0) * 9) }
    private var totalMacroCalories: Int { proteinCal + carbsCal + fatCal }

    private var proteinPercentage: Int {
        guard currentCalorieGoal > 0 else { return 0 }
        return Int(Double(proteinCal) / Double(currentCalorieGoal) * 100)
    }
    private var carbsPercentage: Int {
        guard currentCalorieGoal > 0 else { return 0 }
        return Int(Double(carbsCal) / Double(currentCalorieGoal) * 100)
    }
    private var fatPercentage: Int {
        guard currentCalorieGoal > 0 else { return 0 }
        return Int(Double(fatCal) / Double(currentCalorieGoal) * 100)
    }
    private var macrosMatchTarget: Bool { abs(totalMacroCalories - currentCalorieGoal) < 50 }

    private func setMacroPreset(protein: Int, carbs: Int, fat: Int) {
        let cal = Double(currentCalorieGoal)
        proteinGrams = String(format: "%.0f", cal * Double(protein) / 100 / 4)
        carbsGrams   = String(format: "%.0f", cal * Double(carbs)   / 100 / 4)
        fatGrams     = String(format: "%.0f", cal * Double(fat)      / 100 / 9)
    }

    private func applyGoalMacros(_ goal: UserSettings.FitnessGoal) {
        guard currentCalorieGoal > 0 else { return }
        let m = goal.defaultMacros
        setMacroPreset(protein: m.protein, carbs: m.carbs, fat: m.fat)
    }

    // MARK: - Load / Save

    private func loadCurrentValues() {
        calorieMode = viewModel.settings.calorieMode
        fitnessGoal = viewModel.settings.fitnessGoal
        if let target = viewModel.settings.dailyCalorieTarget { calorieTarget = "\(target)" }
        if let p = viewModel.settings.proteinTargetGrams { proteinGrams = String(format: "%.0f", p) }
        if let c = viewModel.settings.carbsTargetGrams   { carbsGrams   = String(format: "%.0f", c) }
        if let f = viewModel.settings.fatTargetGrams     { fatGrams     = String(format: "%.0f", f) }
        if let goalKg = viewModel.settings.weightGoal {
            let settings = UserSettings.load()
            weightGoal = String(format: "%.1f", settings.weightUnit.convert(fromKg: goalKg))
        }
    }

    private func saveGoals() {
        viewModel.settings.calorieMode = calorieMode
        viewModel.settings.fitnessGoal = fitnessGoal

        if fitnessGoal == .manual, let target = Int(calorieTarget) {
            viewModel.settings.dailyCalorieTarget = target
        } else {
            viewModel.settings.dailyCalorieTarget = nil
        }

        if let p = Double(proteinGrams), !proteinGrams.isEmpty { viewModel.settings.proteinTargetGrams = p }
        if let c = Double(carbsGrams),   !carbsGrams.isEmpty   { viewModel.settings.carbsTargetGrams   = c }
        if let f = Double(fatGrams),     !fatGrams.isEmpty     { viewModel.settings.fatTargetGrams     = f }

        if let goalInUserUnit = Double(weightGoal), !weightGoal.isEmpty {
            let settings = UserSettings.load()
            viewModel.settings.weightGoal = settings.weightUnit.toKg(goalInUserUnit)
        } else {
            viewModel.settings.weightGoal = nil
        }

        viewModel.saveSettings()
    }
}

// MARK: - Budget Mode Card

private struct BudgetModeCard: View {
    let mode: UserSettings.CalorieMode
    var isLocked: Bool = false
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : color)
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : (isLocked ? .secondary : .primary))

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? color : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        mode == .stravaDynamic && !isSelected ? Color.orange.opacity(0.5) : (isSelected ? color : Color(.systemGray4)),
                        lineWidth: mode == .stravaDynamic && !isSelected ? 1.5 : 1.5
                    )
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .black.opacity(0.04), radius: 6, x: 0, y: 2)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var color: Color {
        switch mode {
        case .tdee: return .blue
        case .stravaDynamic: return .orange
        }
    }

    private var icon: String {
        switch mode {
        case .tdee: return "chart.bar.fill"
        case .stravaDynamic: return "bolt.fill"
        }
    }

    private var title: String {
        switch mode {
        case .tdee: return "TDEE Standard"
        case .stravaDynamic: return "Strava Dynamic"
        }
    }

    private var subtitle: String {
        switch mode {
        case .tdee: return "Fixed daily budget based on estimated activity level"
        case .stravaDynamic: return isLocked
            ? "Connect Strava to unlock — earn calories as you move"
            : "Start at BMR, earn calories from each Strava activity"
        }
    }
}

// MARK: - Goal Mode Card

private struct GoalModeCard: View {
    let goal: UserSettings.FitnessGoal
    let calories: Int?
    var isStravaMode: Bool = false
    let isSelected: Bool
    let onTap: () -> Void

    private var color: Color {
        switch goal {
        case .maintenance: return .blue
        case .cutting: return .green
        case .bulking: return .orange
        case .manual: return .purple
        }
    }

    private var icon: String {
        switch goal {
        case .maintenance: return "equal.circle.fill"
        case .cutting: return "arrow.down.circle.fill"
        case .bulking: return "arrow.up.circle.fill"
        case .manual: return "slider.horizontal.3"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : color)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Text(goal.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(goal.subtitle)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(2)

                if let cal = calories, goal != .manual {
                    HStack(spacing: 2) {
                        Text("\(cal) cal")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .white : color)
                        if isStravaMode {
                            Text("+ activity")
                                .font(.caption2)
                                .foregroundColor(isSelected ? .white.opacity(0.75) : .orange)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? color : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color(.systemGray4), lineWidth: 1.5)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
