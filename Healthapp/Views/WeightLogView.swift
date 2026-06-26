//
//  WeightLogView.swift
//  Netfuel
//
//  Quick weight logging view
//

import SwiftUI

struct WeightLogView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    let userId: UUID

    @State private var weightInput: String = ""
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var useMetric = UserSettings.load().weightUnit == .kg

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Weight")
                            .font(.headline)

                        HStack {
                            TextField("Enter weight", text: $weightInput)
                                .keyboardType(.decimalPad)
                                .font(.title2)

                            Picker("Unit", selection: $useMetric) {
                                Text("kg").tag(true)
                                Text("lbs").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                        }
                    }
                }

                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                } header: {
                    Text("Log Date")
                } footer: {
                    Text("Select the date for this weight measurement")
                }

                if let currentWeight = appState.currentUser?.weight {
                    Section {
                        LabeledContent("Previous Weight", value: UnitFormatter.formatWeight(currentWeight))

                        if let newWeight = weightInKg, currentWeight != newWeight {
                            let change = newWeight - currentWeight
                            LabeledContent("Change", value: UnitFormatter.formatWeightChange(change))
                                .foregroundColor(change < 0 ? .green : .red)
                        }
                    } header: {
                        Text("Comparison")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveWeight()
                        }
                    }
                    .disabled(weightInput.isEmpty || isLoading)
                }
            }
        }
    }

    private var weightInKg: Double? {
        guard let value = Double(weightInput), value > 0 else { return nil }
        return useMetric ? value : value * 0.453592 // Convert lbs to kg
    }

    private func saveWeight() async {
        guard let weightKg = weightInKg else {
            errorMessage = "Please enter a valid weight"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Update user's current weight
            let updatedUser = try await ProfileService.shared.updateWeight(userId: userId, weight: weightKg)

            // Update app state
            await MainActor.run {
                appState.currentUser = updatedUser
            }

            // Update daily summary for selected date
            try await DailySummaryService.shared.updateDailyWeight(
                userId: userId,
                date: selectedDate,
                weight: weightKg
            )

            // Dismiss with success
            await MainActor.run {
                HapticFeedback.success()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save weight: \(error.localizedDescription)"
                HapticFeedback.error()
                isLoading = false
            }
        }
    }
}

#Preview {
    WeightLogView(userId: UUID())
        .environmentObject(AppState())
}
