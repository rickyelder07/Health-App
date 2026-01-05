//
//  QuickAddButton.swift
//  Netfuel
//
//  Model for quick-add food buttons
//

import Foundation

/// Food source type for quick-add buttons
enum QuickAddFoodSource: String, Codable, CaseIterable {
    case usda = "USDA"
    case customFood = "My Foods"
    case customMeal = "My Meals"

    var displayName: String {
        self.rawValue
    }
}

/// Quick-add button configuration
struct QuickAddFoodButton: Codable, Identifiable {
    let id: UUID
    var label: String
    var foodSource: QuickAddFoodSource

    // Food identifiers (only one will be set based on foodSource)
    var usdaFdcId: Int?
    var customFoodId: UUID?
    var customMealId: UUID?

    // Logging details
    var servings: Double
    var mealType: MealType

    // Display name for the food
    var foodName: String

    init(
        id: UUID = UUID(),
        label: String,
        foodSource: QuickAddFoodSource,
        usdaFdcId: Int? = nil,
        customFoodId: UUID? = nil,
        customMealId: UUID? = nil,
        servings: Double,
        mealType: MealType,
        foodName: String
    ) {
        self.id = id
        self.label = label
        self.foodSource = foodSource
        self.usdaFdcId = usdaFdcId
        self.customFoodId = customFoodId
        self.customMealId = customMealId
        self.servings = servings
        self.mealType = mealType
        self.foodName = foodName
    }
}

/// Quick-add buttons settings (stored in UserDefaults)
struct QuickAddSettings: Codable {
    var buttons: [QuickAddFoodButton]

    private static let key = "quick_add_settings"

    init(buttons: [QuickAddFoodButton] = []) {
        self.buttons = buttons
    }

    /// Load settings from UserDefaults
    static func load() -> QuickAddSettings {
        print("📱 Loading quick-add settings from UserDefaults...")
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("📱 No saved settings found, returning empty settings")
            return QuickAddSettings()
        }

        do {
            let settings = try JSONDecoder().decode(QuickAddSettings.self, from: data)
            print("📱 Successfully loaded \(settings.buttons.count) buttons")
            return settings
        } catch {
            print("❌ Failed to decode settings: \(error)")
            return QuickAddSettings()
        }
    }

    /// Save settings to UserDefaults
    func save() {
        print("📱 Saving quick-add settings (\(buttons.count) buttons)...")
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: QuickAddSettings.key)
            UserDefaults.standard.synchronize()
            print("✅ Successfully saved quick-add settings")
        } catch {
            print("❌ Failed to encode settings: \(error)")
        }
    }
}
