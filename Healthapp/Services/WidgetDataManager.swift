import Foundation
import WidgetKit

struct WidgetData: Codable {
    var caloriesConsumed: Int
    var calorieGoal: Int
    var proteinConsumed: Double
    var proteinGoal: Double
    var carbsConsumed: Double
    var carbsGoal: Double
    var fatConsumed: Double
    var fatGoal: Double
    var lastUpdated: Date
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let suiteName = "group.rickyelder.Healthapp"
    private let key = "netfuel.widgetData"
    private init() {}

    func write(
        caloriesConsumed: Int, calorieGoal: Int,
        proteinConsumed: Double, proteinGoal: Double,
        carbsConsumed: Double, carbsGoal: Double,
        fatConsumed: Double, fatGoal: Double
    ) {
        // Skip write + widget reload if nothing changed — prevents hammering the
        // widget extension with reloadAllTimelines() on every home view refresh
        if let existing = read(),
           existing.caloriesConsumed == caloriesConsumed,
           existing.calorieGoal == calorieGoal,
           existing.proteinConsumed == proteinConsumed,
           existing.carbsConsumed == carbsConsumed,
           existing.fatConsumed == fatConsumed {
            return
        }

        let data = WidgetData(
            caloriesConsumed: caloriesConsumed, calorieGoal: calorieGoal,
            proteinConsumed: proteinConsumed, proteinGoal: proteinGoal,
            carbsConsumed: carbsConsumed, carbsGoal: carbsGoal,
            fatConsumed: fatConsumed, fatGoal: fatGoal,
            lastUpdated: Date()
        )
        guard let defaults = UserDefaults(suiteName: suiteName),
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func read() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let raw = defaults.data(forKey: key),
              let data = try? JSONDecoder().decode(WidgetData.self, from: raw) else { return nil }
        return data
    }
}
