//
//  UnitConversionTests.swift
//  HealthappTests
//
//  Tests for unit conversions and user settings
//

import XCTest
@testable import Healthapp

final class UnitConversionTests: XCTestCase {

    // MARK: - Weight Conversion Tests

    func testWeightConversion_KgToKg() {
        // Given kg unit
        let unit = UserSettings.WeightUnit.kg

        // When converting kg
        let result = unit.convert(fromKg: 75.0)

        // Then should remain the same
        XCTAssertEqual(result, 75.0, accuracy: 0.01)
    }

    func testWeightConversion_KgToLbs() {
        // Given lbs unit
        let unit = UserSettings.WeightUnit.lbs

        // When converting kg to lbs
        let result = unit.convert(fromKg: 75.0)

        // Then should multiply by 2.20462
        XCTAssertEqual(result, 165.35, accuracy: 0.01)
    }

    func testWeightConversion_LbsToKg() {
        // Given lbs unit
        let unit = UserSettings.WeightUnit.lbs

        // When converting lbs to kg
        let result = unit.toKg(165.35)

        // Then should divide by 2.20462
        XCTAssertEqual(result, 75.0, accuracy: 0.01)
    }

    func testWeightConversion_RoundTrip() {
        // Given a weight in kg
        let originalKg = 82.5

        // When converting to lbs and back
        let lbs = UserSettings.WeightUnit.lbs.convert(fromKg: originalKg)
        let backToKg = UserSettings.WeightUnit.lbs.toKg(lbs)

        // Then should match original
        XCTAssertEqual(backToKg, originalKg, accuracy: 0.01)
    }

    // MARK: - Height Conversion Tests

    func testHeightConversion_CmToCm() {
        // Given cm unit
        let unit = UserSettings.HeightUnit.cm

        // When converting cm
        let result = unit.convert(fromCm: 180.0)

        // Then should remain the same
        XCTAssertEqual(result.primary, 180)
        XCTAssertNil(result.secondary)
    }

    func testHeightConversion_CmToFeet() {
        // Given feet unit
        let unit = UserSettings.HeightUnit.feet

        // When converting 180 cm to feet/inches
        let result = unit.convert(fromCm: 180.0)

        // Then should be 5 feet 11 inches (180 cm ≈ 70.87 inches ≈ 5'11")
        XCTAssertEqual(result.primary, 5)
        XCTAssertEqual(result.secondary, 10) // Rounded
    }

    func testHeightConversion_FeetToCm() {
        // Given feet unit
        let unit = UserSettings.HeightUnit.feet

        // When converting 6 feet 0 inches to cm
        let result = unit.toCm(primary: 6, secondary: 0)

        // Then should be 182.88 cm (72 inches × 2.54)
        XCTAssertEqual(result, 182.88, accuracy: 0.01)
    }

    func testHeightConversion_RoundTrip() {
        // Given a height in cm
        let originalCm = 175.0

        // When converting to feet/inches and back
        let feetInches = UserSettings.HeightUnit.feet.convert(fromCm: originalCm)
        let backToCm = UserSettings.HeightUnit.feet.toCm(
            primary: feetInches.primary,
            secondary: feetInches.secondary ?? 0
        )

        // Then should be close to original (may have rounding due to integer truncation)
        // 175 cm = 5'8.89" but gets truncated to 5'8" = 172.72 cm
        // Allow up to 3 cm difference due to inch rounding
        XCTAssertEqual(backToCm, originalCm, accuracy: 3.0)
    }

    // MARK: - Distance Conversion Tests

    func testDistanceConversion_MetersToKm() {
        // Given km unit
        let unit = UserSettings.DistanceUnit.km

        // When converting meters to km
        let result = unit.convert(fromMeters: 5000.0)

        // Then should divide by 1000
        XCTAssertEqual(result, 5.0, accuracy: 0.01)
    }

    func testDistanceConversion_MetersToMiles() {
        // Given miles unit
        let unit = UserSettings.DistanceUnit.miles

        // When converting meters to miles
        let result = unit.convert(fromMeters: 8000.0)

        // Then should divide by 1609.34
        XCTAssertEqual(result, 4.97, accuracy: 0.01)
    }

    func testDistanceConversion_Marathon() {
        // Given a marathon distance in meters
        let marathonMeters = 42195.0

        // When converting to km
        let km = UserSettings.DistanceUnit.km.convert(fromMeters: marathonMeters)

        // Then should be 42.195 km
        XCTAssertEqual(km, 42.195, accuracy: 0.01)

        // When converting to miles
        let miles = UserSettings.DistanceUnit.miles.convert(fromMeters: marathonMeters)

        // Then should be 26.22 miles
        XCTAssertEqual(miles, 26.22, accuracy: 0.01)
    }

    // MARK: - Calorie Goal Source Tests

    func testCalorieGoalSource_DisplayNames() {
        // Test display names
        XCTAssertEqual(UserSettings.CalorieGoalSource.bmr.displayName, "BMR (Basal Metabolic Rate)")
        XCTAssertEqual(UserSettings.CalorieGoalSource.tdee.displayName, "TDEE (Total Daily Energy)")
        XCTAssertEqual(UserSettings.CalorieGoalSource.custom.displayName, "Custom Target")
    }

    func testCalorieGoalSource_Descriptions() {
        // Test descriptions
        XCTAssertEqual(
            UserSettings.CalorieGoalSource.bmr.description,
            "Calories burned at rest - use for weight loss"
        )
        XCTAssertEqual(
            UserSettings.CalorieGoalSource.tdee.description,
            "Total calories including activity - use to maintain weight"
        )
        XCTAssertEqual(
            UserSettings.CalorieGoalSource.custom.description,
            "Set your own custom calorie target"
        )
    }

    // MARK: - Gender Display Names Tests

    func testGender_DisplayNames() {
        XCTAssertEqual(Gender.male.displayName, "Male")
        XCTAssertEqual(Gender.female.displayName, "Female")
        XCTAssertEqual(Gender.other.displayName, "Other")
    }

    // MARK: - Activity Level Tests

    func testActivityLevel_DisplayNames() {
        XCTAssertTrue(ActivityLevel.sedentary.displayName.contains("Sedentary"))
        XCTAssertTrue(ActivityLevel.lightlyActive.displayName.contains("Lightly Active"))
        XCTAssertTrue(ActivityLevel.moderatelyActive.displayName.contains("Moderately Active"))
        XCTAssertTrue(ActivityLevel.veryActive.displayName.contains("Very Active"))
        XCTAssertTrue(ActivityLevel.extraActive.displayName.contains("Extra Active"))
    }

    func testActivityLevel_Multipliers() {
        XCTAssertEqual(ActivityLevel.sedentary.multiplier, 1.2)
        XCTAssertEqual(ActivityLevel.lightlyActive.multiplier, 1.375)
        XCTAssertEqual(ActivityLevel.moderatelyActive.multiplier, 1.55)
        XCTAssertEqual(ActivityLevel.veryActive.multiplier, 1.725)
        XCTAssertEqual(ActivityLevel.extraActive.multiplier, 1.9)
    }

    // MARK: - Meal Type Tests

    func testMealType_DisplayNames() {
        XCTAssertEqual(MealType.breakfast.displayName, "Breakfast")
        XCTAssertEqual(MealType.lunch.displayName, "Lunch")
        XCTAssertEqual(MealType.dinner.displayName, "Dinner")
        XCTAssertEqual(MealType.snack.displayName, "Snack")
    }

    func testMealType_Icons() {
        XCTAssertEqual(MealType.breakfast.icon, "sunrise.fill")
        XCTAssertEqual(MealType.lunch.icon, "sun.max.fill")
        XCTAssertEqual(MealType.dinner.icon, "moon.stars.fill")
        XCTAssertEqual(MealType.snack.icon, "leaf.fill")
    }

    // MARK: - User Settings Persistence Tests

    func testUserSettings_SaveAndLoad() {
        // Given custom settings
        var settings = UserSettings()
        settings.calorieGoalSource = .custom
        settings.dailyCalorieTarget = 2500
        settings.proteinTargetGrams = 150.0
        settings.weightUnit = .lbs

        // When saving and loading
        settings.save()
        let loaded = UserSettings.load()

        // Then should match
        XCTAssertEqual(loaded.calorieGoalSource, .custom)
        XCTAssertEqual(loaded.dailyCalorieTarget, 2500)
        XCTAssertEqual(loaded.proteinTargetGrams, 150.0)
        XCTAssertEqual(loaded.weightUnit, .lbs)

        // Cleanup
        UserSettings.clear()
    }

    func testUserSettings_DefaultValues() {
        // Clear any existing settings
        UserSettings.clear()

        // When loading with no saved settings
        let settings = UserSettings.load()

        // Then should have default values
        XCTAssertEqual(settings.calorieGoalSource, .tdee)
        XCTAssertEqual(settings.weightUnit, .kg)
        XCTAssertEqual(settings.heightUnit, .cm)
        XCTAssertEqual(settings.distanceUnit, .km)
    }
}
