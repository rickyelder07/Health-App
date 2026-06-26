//
//  GoalsSetupPageView.swift
//  Netfuel
//
//  Goals setup page during onboarding
//

import SwiftUI

struct GoalsSetupPageView: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel

    @State private var fitnessGoal: UserSettings.FitnessGoal = .maintenance
    @State private var calorieTarget: String = ""
    @State private var proteinGrams: String = ""
    @State private var carbsGrams: String = ""
    @State private var fatGrams: String = ""

    private var tdee: Int { onboardingViewModel.userTDEE }

    private var currentCalorieGoal: Int {
        if fitnessGoal == .manual { return Int(calorieTarget) ?? tdee }
        return tdee > 0 ? max(1200, tdee + fitnessGoal.calorieOffset) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange.gradient)

                    Text("Set Your Goals")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose your fitness goal and we'll calculate your macro targets")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal)

                // TDEE display
                if tdee > 0 {
                    tdeeCard
                }

                // Goal Mode Cards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fitness Goal")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(UserSettings.FitnessGoal.allCases, id: \.self) { goal in
                            OnboardingGoalCard(
                                goal: goal,
                                calories: tdee > 0 && goal != .manual
                                    ? max(1200, tdee + goal.calorieOffset)
                                    : nil,
                                isSelected: fitnessGoal == goal
                            ) {
                                fitnessGoal = goal
                                if goal != .manual { applyDefaultMacros(goal) }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Manual calorie input
                if fitnessGoal == .manual {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Calorie Target")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack {
                            TextField("e.g. 2000", text: $calorieTarget)
                                .keyboardType(.numberPad)
                                .font(.system(size: 28, weight: .semibold))
                            Text("cal/day")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        .padding(.horizontal)
                    }
                    .onChange(of: calorieTarget) { _, _ in
                        applyDefaultMacros(.manual)
                    }
                }

                // Macro Targets
                if currentCalorieGoal > 0 {
                    macroSection
                }

                // Quick Presets
                presetSection

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            loadExistingSettings()
        }
    }

    // MARK: - TDEE Card

    private var tdeeCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Your TDEE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(tdee)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.green.gradient)
                Text("cal/day")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Text("Your Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(currentCalorieGoal > 0 ? "\(currentCalorieGoal)" : "--")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(goalColor.gradient)
                Text("cal/day")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Macro Section

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Targets")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                macroField(label: "Protein", icon: "p.circle.fill", color: .red,  grams: $proteinGrams)
                macroField(label: "Carbs",   icon: "c.circle.fill", color: .blue, grams: $carbsGrams)
                macroField(label: "Fat",     icon: "f.circle.fill", color: .purple, grams: $fatGrams)
            }
            .padding(.horizontal)
        }
    }

    private func macroField(label: String, icon: String, color: Color, grams: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 28)

            Text(label)
                .font(.body)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)

            TextField("g", text: grams)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.body.weight(.semibold))

            Text("g")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Presets Section

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach([
                    ("Balanced (30/40/30)", 30, 40, 30),
                    ("High Protein (40/30/30)", 40, 30, 30),
                    ("Low Carb (35/20/45)", 35, 20, 45),
                    ("Low Fat (30/50/20)", 30, 50, 20)
                ], id: \.0) { preset in
                    Button {
                        applyPreset(p: preset.1, c: preset.2, f: preset.3)
                    } label: {
                        HStack {
                            Text(preset.0)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                    }
                }
            }
            .padding(.horizontal)
        }
        // Save whenever user changes anything
        .onChange(of: fitnessGoal)   { _, _ in saveToSettings() }
        .onChange(of: proteinGrams)  { _, _ in saveToSettings() }
        .onChange(of: carbsGrams)    { _, _ in saveToSettings() }
        .onChange(of: fatGrams)      { _, _ in saveToSettings() }
        .onChange(of: calorieTarget) { _, _ in saveToSettings() }
    }

    // MARK: - Helpers

    private var goalColor: Color {
        switch fitnessGoal {
        case .maintenance: return .blue
        case .cutting: return .green
        case .bulking: return .orange
        case .manual: return .purple
        }
    }

    private func applyDefaultMacros(_ goal: UserSettings.FitnessGoal) {
        guard currentCalorieGoal > 0 else { return }
        let m = goal.defaultMacros
        applyPreset(p: m.protein, c: m.carbs, f: m.fat)
    }

    private func applyPreset(p: Int, c: Int, f: Int) {
        let cal = Double(currentCalorieGoal)
        guard cal > 0 else { return }
        proteinGrams = String(format: "%.0f", cal * Double(p) / 100 / 4)
        carbsGrams   = String(format: "%.0f", cal * Double(c) / 100 / 4)
        fatGrams     = String(format: "%.0f", cal * Double(f) / 100 / 9)
    }

    private func loadExistingSettings() {
        let settings = UserSettings.load()
        fitnessGoal = settings.fitnessGoal
        if let t = settings.dailyCalorieTarget { calorieTarget = "\(t)" }
        if let p = settings.proteinTargetGrams { proteinGrams = String(format: "%.0f", p) }
        if let c = settings.carbsTargetGrams   { carbsGrams   = String(format: "%.0f", c) }
        if let f = settings.fatTargetGrams     { fatGrams     = String(format: "%.0f", f) }

        // If no macros saved yet, apply defaults for current goal
        if proteinGrams.isEmpty { applyDefaultMacros(fitnessGoal) }
    }

    private func saveToSettings() {
        var settings = UserSettings.load()
        settings.fitnessGoal = fitnessGoal
        if fitnessGoal == .manual, let t = Int(calorieTarget) {
            settings.dailyCalorieTarget = t
        } else {
            settings.dailyCalorieTarget = nil
        }
        if let p = Double(proteinGrams), !proteinGrams.isEmpty { settings.proteinTargetGrams = p }
        if let c = Double(carbsGrams),   !carbsGrams.isEmpty   { settings.carbsTargetGrams   = c }
        if let f = Double(fatGrams),     !fatGrams.isEmpty     { settings.fatTargetGrams     = f }
        settings.save()
    }
}

// MARK: - Goal Card (onboarding variant)

private struct OnboardingGoalCard: View {
    let goal: UserSettings.FitnessGoal
    let calories: Int?
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
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(goal.subtitle)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(2)
                if let cal = calories {
                    Text("\(cal) cal")
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : color)
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

#Preview {
    GoalsSetupPageView(onboardingViewModel: OnboardingViewModel())
}
