//
//  PreviewData.swift
//  Netfuel
//
//  Mock data for SwiftUI previews and testing
//

import Foundation

/// Mock data for previews and testing
struct PreviewData {

    // MARK: - Users

    static let sampleUser = User(
        id: UUID(),
        email: "test@example.com",
        name: "John Doe",
        weight: 75.0, // kg
        height: 175.0, // cm
        age: 30,
        gender: .male,
        activityLevel: .moderatelyActive,
        bmr: 1750.0,
        tdee: 2713.0,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date()
    )

    static let femaleUser = User(
        id: UUID(),
        email: "jane@example.com",
        name: "Jane Smith",
        weight: 62.0,
        height: 165.0,
        age: 28,
        gender: .female,
        activityLevel: .lightlyActive,
        bmr: 1400.0,
        tdee: 1925.0,
        createdAt: Date().addingTimeInterval(-86400 * 60),
        updatedAt: Date()
    )

    static let incompleteUser = User(
        id: UUID(),
        email: "incomplete@example.com",
        name: "New User",
        weight: nil,
        height: nil,
        age: nil,
        gender: nil,
        activityLevel: nil,
        bmr: nil,
        tdee: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    // MARK: - Food Logs

    static let breakfastLog = FoodLog(
        id: UUID(),
        userId: sampleUser.id,
        foodName: "Oatmeal with Banana",
        brandName: nil,
        servingSize: "1",
        servingUnit: "cup",
        calories: 300,
        protein: 10.0,
        carbs: 54.0,
        fat: 6.0,
        fiber: 8.0,
        sugar: 12.0,
        sodium: 150.0,
        servings: 1.0,
        mealType: .breakfast,
        usdaFdcId: nil,
        loggedAt: Date().addingTimeInterval(-3600 * 4), // 4 hours ago
        createdAt: Date().addingTimeInterval(-3600 * 4)
    )

    static let lunchLog = FoodLog(
        id: UUID(),
        userId: sampleUser.id,
        foodName: "Grilled Chicken Salad",
        brandName: "Subway",
        servingSize: "1",
        servingUnit: "serving",
        calories: 450,
        protein: 35.0,
        carbs: 25.0,
        fat: 18.0,
        fiber: 5.0,
        sugar: 5.0,
        sodium: 800.0,
        servings: 1.0,
        mealType: .lunch,
        usdaFdcId: nil,
        loggedAt: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
        createdAt: Date().addingTimeInterval(-3600 * 2)
    )

    static let dinnerLog = FoodLog(
        id: UUID(),
        userId: sampleUser.id,
        foodName: "Salmon with Rice and Vegetables",
        brandName: nil,
        servingSize: "300",
        servingUnit: "g",
        calories: 550,
        protein: 42.0,
        carbs: 48.0,
        fat: 16.0,
        fiber: 6.0,
        sugar: 4.0,
        sodium: 450.0,
        servings: 1.0,
        mealType: .dinner,
        usdaFdcId: nil,
        loggedAt: Date().addingTimeInterval(-1800), // 30 min ago
        createdAt: Date().addingTimeInterval(-1800)
    )

    static let snackLog = FoodLog(
        id: UUID(),
        userId: sampleUser.id,
        foodName: "Greek Yogurt",
        brandName: "Chobani",
        servingSize: "170",
        servingUnit: "g",
        calories: 100,
        protein: 17.0,
        carbs: 6.0,
        fat: 0.0,
        fiber: 0.0,
        sugar: 4.0,
        sodium: 65.0,
        servings: 1.0,
        mealType: .snack,
        usdaFdcId: "123456",
        loggedAt: Date().addingTimeInterval(-3600 * 6), // 6 hours ago
        createdAt: Date().addingTimeInterval(-3600 * 6)
    )

    static let allFoodLogs: [FoodLog] = [
        breakfastLog,
        snackLog,
        lunchLog,
        dinnerLog
    ]

    // MARK: - Activities

    static let morningRun = Activity(
        id: UUID(),
        userId: sampleUser.id,
        stravaId: 123456789,
        name: "Morning Run",
        type: "Run",
        startDate: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
        duration: 2400, // 40 minutes
        distance: 8000, // 8 km
        calories: 450,
        averageSpeed: 3.33, // m/s (8 min/km)
        maxSpeed: 4.5,
        averageHeartrate: 145.0,
        maxHeartrate: 165,
        elevationGain: 50.0,
        createdAt: Date().addingTimeInterval(-3600 * 5)
    )

    static let eveningCycle = Activity(
        id: UUID(),
        userId: sampleUser.id,
        stravaId: 987654321,
        name: "Evening Bike Ride",
        type: "Ride",
        startDate: Date().addingTimeInterval(-3600 * 1), // 1 hour ago
        duration: 3600, // 60 minutes
        distance: 25000, // 25 km
        calories: 550,
        averageSpeed: 6.94, // m/s (25 km/h)
        maxSpeed: 10.0,
        averageHeartrate: 130.0,
        maxHeartrate: 155,
        elevationGain: 150.0,
        createdAt: Date().addingTimeInterval(-3600 * 1)
    )

    static let gymWorkout = Activity(
        id: UUID(),
        userId: sampleUser.id,
        stravaId: 555555555,
        name: "Strength Training",
        type: "WeightTraining",
        startDate: Date().addingTimeInterval(-86400), // Yesterday
        duration: 2700, // 45 minutes
        distance: nil,
        calories: 300,
        averageSpeed: nil,
        maxSpeed: nil,
        averageHeartrate: 120.0,
        maxHeartrate: 145,
        elevationGain: nil,
        createdAt: Date().addingTimeInterval(-86400)
    )

    static let allActivities: [Activity] = [
        morningRun,
        eveningCycle,
        gymWorkout
    ]

    // MARK: - Daily Summaries

    static let todaySummary = DailySummary(
        userId: sampleUser.id,
        date: Calendar.current.startOfDay(for: Date()),
        weight: 75.0,
        calorieGoal: 2700,
        caloriesConsumed: 1400,
        proteinConsumed: 104.0,
        carbsConsumed: 133.0,
        fatConsumed: 40.0,
        caloriesBurnedBmr: 1750,
        caloriesBurnedExercise: 1000,
        totalCaloriesBurned: 2750,
        netCalories: -1350,
        createdAt: Date().addingTimeInterval(-3600 * 6),
        updatedAt: Date()
    )

    static let yesterdaySummary = DailySummary(
        userId: sampleUser.id,
        date: Calendar.current.startOfDay(for: Date().addingTimeInterval(-86400)),
        weight: 75.2,
        calorieGoal: 2700,
        caloriesConsumed: 2800,
        proteinConsumed: 145.0,
        carbsConsumed: 280.0,
        fatConsumed: 85.0,
        caloriesBurnedBmr: 1750,
        caloriesBurnedExercise: 300,
        totalCaloriesBurned: 2050,
        netCalories: 750,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-86400)
    )

    static let lastWeekSummary = DailySummary(
        userId: sampleUser.id,
        date: Calendar.current.startOfDay(for: Date().addingTimeInterval(-86400 * 7)),
        weight: 76.0,
        calorieGoal: 2700,
        caloriesConsumed: 2600,
        proteinConsumed: 150.0,
        carbsConsumed: 260.0,
        fatConsumed: 75.0,
        caloriesBurnedBmr: 1750,
        caloriesBurnedExercise: 450,
        totalCaloriesBurned: 2200,
        netCalories: 400,
        createdAt: Date().addingTimeInterval(-86400 * 7),
        updatedAt: Date().addingTimeInterval(-86400 * 7)
    )

    static let allSummaries: [DailySummary] = [
        todaySummary,
        yesterdaySummary,
        lastWeekSummary
    ]

    // MARK: - Progress Photos

    static let recentPhoto = ProgressPhoto(
        id: UUID(),
        userId: sampleUser.id,
        photoUrl: "https://via.placeholder.com/600x800",
        thumbnailUrl: "https://via.placeholder.com/150x200",
        weight: 75.0,
        notes: "Feeling great after a month of training!",
        takenAt: Date().addingTimeInterval(-86400 * 3),
        createdAt: Date().addingTimeInterval(-86400 * 3),
        updatedAt: Date().addingTimeInterval(-86400 * 3)
    )

    static let monthOldPhoto = ProgressPhoto(
        id: UUID(),
        userId: sampleUser.id,
        photoUrl: "https://via.placeholder.com/600x800",
        thumbnailUrl: "https://via.placeholder.com/150x200",
        weight: 78.0,
        notes: "Starting my fitness journey",
        takenAt: Date().addingTimeInterval(-86400 * 30),
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date().addingTimeInterval(-86400 * 30)
    )

    static let allPhotos: [ProgressPhoto] = [
        recentPhoto,
        monthOldPhoto
    ]

    // MARK: - User Settings

    static let defaultSettings = UserSettings(
        fitnessGoal: .maintenance,
        dailyCalorieTarget: nil,
        proteinTargetGrams: 150.0,
        carbsTargetGrams: 250.0,
        fatTargetGrams: 70.0,
        proteinTargetPercentage: nil,
        carbsTargetPercentage: nil,
        fatTargetPercentage: nil,
        weightGoal: 72.0,
        weightUnit: .kg,
        heightUnit: .cm,
        distanceUnit: .km
    )

    static let customSettings = UserSettings(
        fitnessGoal: .manual,
        dailyCalorieTarget: 2500,
        proteinTargetGrams: 180.0,
        carbsTargetGrams: 200.0,
        fatTargetGrams: 80.0,
        proteinTargetPercentage: nil,
        carbsTargetPercentage: nil,
        fatTargetPercentage: nil,
        weightGoal: 70.0,
        weightUnit: .lbs,
        heightUnit: .feet,
        distanceUnit: .miles
    )

    // MARK: - Helper Methods

    /// Generate multiple food logs for testing
    static func generateFoodLogs(count: Int, for userId: UUID) -> [FoodLog] {
        let foods = [
            ("Banana", 105, 1.3, 27.0, 0.4),
            ("Chicken Breast", 165, 31.0, 0.0, 3.6),
            ("Brown Rice", 215, 5.0, 45.0, 1.8),
            ("Broccoli", 55, 3.7, 11.0, 0.6),
            ("Protein Shake", 120, 24.0, 3.0, 1.5),
            ("Eggs", 155, 13.0, 1.1, 11.0),
            ("Avocado", 240, 3.0, 13.0, 22.0),
            ("Sweet Potato", 180, 4.0, 41.0, 0.3)
        ]

        var logs: [FoodLog] = []
        for i in 0..<count {
            let (name, cal, protein, carbs, fat) = foods[i % foods.count]
            let mealType = MealType.allCases[i % MealType.allCases.count]

            logs.append(FoodLog(
                id: UUID(),
                userId: userId,
                foodName: name,
                brandName: nil,
                servingSize: "100",
                servingUnit: "g",
                calories: cal,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: nil,
                sugar: nil,
                sodium: nil,
                servings: 1.0,
                mealType: mealType,
                usdaFdcId: nil,
                loggedAt: Date().addingTimeInterval(-Double(i) * 3600),
                createdAt: Date().addingTimeInterval(-Double(i) * 3600)
            ))
        }
        return logs
    }

    /// Generate multiple activities for testing
    static func generateActivities(count: Int, for userId: UUID) -> [Activity] {
        let types = ["Run", "Ride", "Swim", "Walk", "WeightTraining", "Yoga"]
        let names = [
            "Morning Run", "Evening Ride", "Pool Swim", "Lunch Walk",
            "Gym Session", "Yoga Class"
        ]

        var activities: [Activity] = []
        for i in 0..<count {
            let type = types[i % types.count]
            let name = names[i % names.count]

            activities.append(Activity(
                id: UUID(),
                userId: userId,
                stravaId: Int64(100000 + i),
                name: name,
                type: type,
                startDate: Date().addingTimeInterval(-Double(i) * 86400),
                duration: Int.random(in: 1800...5400),
                distance: type == "WeightTraining" || type == "Yoga" ? nil : Double.random(in: 5000...20000),
                calories: Int.random(in: 200...600),
                averageSpeed: type == "WeightTraining" || type == "Yoga" ? nil : Double.random(in: 2.5...7.5),
                maxSpeed: type == "WeightTraining" || type == "Yoga" ? nil : Double.random(in: 5.0...12.0),
                averageHeartrate: Double.random(in: 120...160),
                maxHeartrate: Int.random(in: 150...185),
                elevationGain: Double.random(in: 0...300),
                createdAt: Date().addingTimeInterval(-Double(i) * 86400)
            ))
        }
        return activities
    }

    /// Generate daily summaries for a date range
    static func generateDailySummaries(days: Int, for userId: UUID) -> [DailySummary] {
        var summaries: [DailySummary] = []

        for i in 0..<days {
            let date = Calendar.current.startOfDay(for: Date().addingTimeInterval(-Double(i) * 86400))
            summaries.append(DailySummary(
                userId: userId,
                date: date,
                weight: 75.0 + Double.random(in: -1.0...1.0),
                calorieGoal: 2700,
                caloriesConsumed: Int.random(in: 1800...3200),
                proteinConsumed: Double.random(in: 100...180),
                carbsConsumed: Double.random(in: 180...320),
                fatConsumed: Double.random(in: 50...100),
                caloriesBurnedBmr: 1750,
                caloriesBurnedExercise: Int.random(in: 200...800),
                totalCaloriesBurned: 1750 + Int.random(in: 200...800),
                netCalories: Int.random(in: -500...800),
                createdAt: date,
                updatedAt: date
            ))
        }

        return summaries
    }
}
