//
//  MacroCalculationTests.swift
//  HealthappTests
//
//  Tests for macro and calorie calculations
//

import XCTest
@testable import Healthapp

final class MacroCalculationTests: XCTestCase {

    // MARK: - Food Log Calculation Tests

    func testTotalCalories_SingleServing() {
        // Given a food log with 1 serving
        let foodLog = FoodLog(
            id: UUID(),
            userId: UUID(),
            foodName: "Chicken Breast",
            brandName: nil,
            servingSize: "100",
            servingUnit: "g",
            calories: 165,
            protein: 31.0,
            carbs: 0.0,
            fat: 3.6,
            fiber: nil,
            sugar: nil,
            sodium: nil,
            servings: 1.0,
            mealType: .lunch,
            usdaFdcId: nil,
            loggedAt: Date(),
            createdAt: Date()
        )

        // When calculating totals
        let totalCal = foodLog.totalCalories
        let totalProtein = foodLog.totalProtein
        let totalCarbs = foodLog.totalCarbs
        let totalFat = foodLog.totalFat

        // Then totals should equal base values
        XCTAssertEqual(totalCal, 165.0)
        XCTAssertEqual(totalProtein, 31.0)
        XCTAssertEqual(totalCarbs, 0.0)
        XCTAssertEqual(totalFat, 3.6)
    }

    func testTotalCalories_MultipleServings() {
        // Given a food log with 2.5 servings
        let foodLog = FoodLog(
            id: UUID(),
            userId: UUID(),
            foodName: "Oatmeal",
            brandName: nil,
            servingSize: "40",
            servingUnit: "g",
            calories: 150,
            protein: 5.0,
            carbs: 27.0,
            fat: 3.0,
            fiber: 4.0,
            sugar: 1.0,
            sodium: 0.0,
            servings: 2.5,
            mealType: .breakfast,
            usdaFdcId: nil,
            loggedAt: Date(),
            createdAt: Date()
        )

        // When calculating totals
        let totalCal = foodLog.totalCalories
        let totalProtein = foodLog.totalProtein
        let totalCarbs = foodLog.totalCarbs
        let totalFat = foodLog.totalFat

        // Then totals should be multiplied by servings
        XCTAssertEqual(totalCal, 375.0, accuracy: 0.01) // 150 × 2.5
        XCTAssertEqual(totalProtein, 12.5, accuracy: 0.01) // 5.0 × 2.5
        XCTAssertEqual(totalCarbs, 67.5, accuracy: 0.01) // 27.0 × 2.5
        XCTAssertEqual(totalFat, 7.5, accuracy: 0.01) // 3.0 × 2.5
    }

    func testServingDescription_SingleServing() {
        // Given a food log with 1 serving
        let foodLog = FoodLog(
            id: UUID(),
            userId: UUID(),
            foodName: "Test Food",
            brandName: nil,
            servingSize: "100",
            servingUnit: "g",
            calories: 100,
            protein: 10.0,
            carbs: 10.0,
            fat: 5.0,
            fiber: nil,
            sugar: nil,
            sodium: nil,
            servings: 1.0,
            mealType: .lunch,
            usdaFdcId: nil,
            loggedAt: Date(),
            createdAt: Date()
        )

        // When getting serving description
        let description = foodLog.servingDescription

        // Then it should show just the size and unit
        XCTAssertEqual(description, "100 g")
    }

    func testServingDescription_MultipleServings() {
        // Given a food log with 2.5 servings
        let foodLog = FoodLog(
            id: UUID(),
            userId: UUID(),
            foodName: "Test Food",
            brandName: nil,
            servingSize: "100",
            servingUnit: "g",
            calories: 100,
            protein: 10.0,
            carbs: 10.0,
            fat: 5.0,
            fiber: nil,
            sugar: nil,
            sodium: nil,
            servings: 2.5,
            mealType: .lunch,
            usdaFdcId: nil,
            loggedAt: Date(),
            createdAt: Date()
        )

        // When getting serving description
        let description = foodLog.servingDescription

        // Then it should show the multiplier
        XCTAssertEqual(description, "2.5 × 100 g")
    }

    // MARK: - Daily Summary Calculation Tests

    func testDailySummary_TotalCaloriesBurned() {
        // Given a daily summary
        let summary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: 2500,
            caloriesConsumed: 2000,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil, // Test calculation
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating total calories burned
        let total = summary.calculateTotalCaloriesBurned()

        // Then it should be BMR + Exercise
        XCTAssertEqual(total, 2250) // 1750 + 500
    }

    func testDailySummary_NetCalories() {
        // Given a daily summary
        let summary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: 2500,
            caloriesConsumed: 2000,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil,
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating net calories
        let net = summary.calculateNetCalories()

        // Then it should be Consumed - Burned
        XCTAssertEqual(net, -250) // 2000 - 2250
    }

    func testDailySummary_IsInSurplus() {
        // Given a summary with surplus
        let surplusSummary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: 2500,
            caloriesConsumed: 3000,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil,
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then should be in surplus
        XCTAssertTrue(surplusSummary.isInSurplus)
        XCTAssertFalse(surplusSummary.isInDeficit)
    }

    func testDailySummary_IsInDeficit() {
        // Given a summary with deficit
        let deficitSummary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: 2500,
            caloriesConsumed: 1800,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil,
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then should be in deficit
        XCTAssertTrue(deficitSummary.isInDeficit)
        XCTAssertFalse(deficitSummary.isInSurplus)
    }

    func testDailySummary_CaloriesVsGoal() {
        // Given a summary with a goal
        let summary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: 2500,
            caloriesConsumed: 2650,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil,
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When comparing to goal
        let vsGoal = summary.caloriesVsGoal()

        // Then should show difference
        XCTAssertEqual(vsGoal, 150) // 2650 - 2500
    }

    func testDailySummary_MetCalorieGoal_Within50() {
        // Given a summary within 50 calories of goal
        let summary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: 2500,
            caloriesConsumed: 2525,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil,
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then should have met goal
        XCTAssertEqual(summary.metCalorieGoal(), true)
    }

    func testDailySummary_MetCalorieGoal_Over50() {
        // Given a summary over 50 calories from goal
        let summary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: 2500,
            caloriesConsumed: 2600,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil,
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then should not have met goal
        XCTAssertEqual(summary.metCalorieGoal(), false)
    }

    func testDailySummary_NoGoal() {
        // Given a summary without a goal
        let summary = DailySummary(
            userId: UUID(),
            date: Date(),
            weight: 75.0,
            calorieGoal: nil,
            caloriesConsumed: 2500,
            proteinConsumed: 150.0,
            carbsConsumed: 200.0,
            fatConsumed: 70.0,
            caloriesBurnedBmr: 1750,
            caloriesBurnedExercise: 500,
            totalCaloriesBurned: nil,
            netCalories: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then goal comparisons should return nil
        XCTAssertNil(summary.caloriesVsGoal())
        XCTAssertNil(summary.metCalorieGoal())
    }

    // MARK: - Activity Calculation Tests

    func testActivity_FormattedDuration_WithHours() {
        // Given an activity over 1 hour
        let activity = Activity(
            id: UUID(),
            userId: UUID(),
            stravaId: 12345,
            name: "Long Run",
            type: "Run",
            startDate: Date(),
            duration: 5400, // 90 minutes = 1:30:00
            distance: 15000,
            calories: 800,
            averageSpeed: nil,
            maxSpeed: nil,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            createdAt: Date()
        )

        // When formatting duration
        let formatted = activity.formattedDuration

        // Then should show HH:MM:SS
        XCTAssertEqual(formatted, "01:30:00")
    }

    func testActivity_FormattedDuration_UnderOneHour() {
        // Given an activity under 1 hour
        let activity = Activity(
            id: UUID(),
            userId: UUID(),
            stravaId: 12345,
            name: "Quick Run",
            type: "Run",
            startDate: Date(),
            duration: 1800, // 30 minutes
            distance: 5000,
            calories: 300,
            averageSpeed: nil,
            maxSpeed: nil,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            createdAt: Date()
        )

        // When formatting duration
        let formatted = activity.formattedDuration

        // Then should show MM:SS
        XCTAssertEqual(formatted, "30:00")
    }

    func testActivity_FormattedDistance() {
        // Given an activity with distance
        let activity = Activity(
            id: UUID(),
            userId: UUID(),
            stravaId: 12345,
            name: "Run",
            type: "Run",
            startDate: Date(),
            duration: 2400,
            distance: 8000, // 8 km
            calories: 450,
            averageSpeed: nil,
            maxSpeed: nil,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            createdAt: Date()
        )

        // When formatting distance
        let formatted = activity.formattedDistance

        // Then should show km with 2 decimals
        XCTAssertEqual(formatted, "8.00 km")
    }

    func testActivity_FormattedPace() {
        // Given an activity with distance and duration
        let activity = Activity(
            id: UUID(),
            userId: UUID(),
            stravaId: 12345,
            name: "Run",
            type: "Run",
            startDate: Date(),
            duration: 2400, // 40 minutes
            distance: 5000, // 5 km
            calories: 350,
            averageSpeed: nil,
            maxSpeed: nil,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            createdAt: Date()
        )

        // When formatting pace
        let formatted = activity.formattedPace

        // Then should show min/km (40 min / 5 km = 8 min/km)
        XCTAssertEqual(formatted, "8:00 /km")
    }
}
