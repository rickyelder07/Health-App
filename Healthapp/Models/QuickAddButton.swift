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

/// Quick-add buttons settings (stored in UserDefaults, scoped per user)
struct QuickAddSettings: Codable {
    var buttons: [QuickAddFoodButton]

    init(buttons: [QuickAddFoodButton] = []) {
        self.buttons = buttons
    }

    private static func storageKey(userId: UUID?) -> String {
        guard let userId else { return "quick_add_settings" }
        return "quick_add_settings_\(userId.uuidString)"
    }

    static func load(userId: UUID? = nil) -> QuickAddSettings {
        let key = storageKey(userId: userId)
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return QuickAddSettings()
        }
        return (try? JSONDecoder().decode(QuickAddSettings.self, from: data)) ?? QuickAddSettings()
    }

    func save(userId: UUID? = nil) {
        let key = QuickAddSettings.storageKey(userId: userId)
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
