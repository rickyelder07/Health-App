//
//  BMRTDEECalculationTests.swift
//  HealthappTests
//
//  Tests for BMR and TDEE calculations
//

import XCTest
@testable import Healthapp

final class BMRTDEECalculationTests: XCTestCase {

    // MARK: - BMR Tests

    func testBMRCalculation_Male() {
        // Given a male user with known stats
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,  // kg
            height: 180.0, // cm
            age: 30,
            gender: .male,
            activityLevel: .moderatelyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating BMR
        let bmr = user.calculateBMR()

        // Then BMR should be calculated correctly using Mifflin-St Jeor
        // BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5
        // BMR = (10 × 80) + (6.25 × 180) - (5 × 30) + 5
        // BMR = 800 + 1125 - 150 + 5 = 1780
        XCTAssertNotNil(bmr)
        XCTAssertEqual(bmr ?? 0, 1780.0, accuracy: 0.01)
    }

    func testBMRCalculation_Female() {
        // Given a female user with known stats
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 65.0,  // kg
            height: 165.0, // cm
            age: 28,
            gender: .female,
            activityLevel: .lightlyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating BMR
        let bmr = user.calculateBMR()

        // Then BMR should be calculated correctly
        // BMR = (10 × 65) + (6.25 × 165) - (5 × 28) - 161
        // BMR = 650 + 1031.25 - 140 - 161 = 1380.25
        XCTAssertNotNil(bmr)
        XCTAssertEqual(bmr ?? 0, 1380.25, accuracy: 0.01)
    }

    func testBMRCalculation_Other() {
        // Given a user with gender "other"
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 70.0,
            height: 170.0,
            age: 25,
            gender: .other,
            activityLevel: .moderatelyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating BMR
        let bmr = user.calculateBMR()

        // Then BMR should use average offset (-78)
        // BMR = (10 × 70) + (6.25 × 170) - (5 × 25) - 78
        // BMR = 700 + 1062.5 - 125 - 78 = 1559.5
        XCTAssertNotNil(bmr)
        XCTAssertEqual(bmr ?? 0, 1559.5, accuracy: 0.01)
    }

    func testBMRCalculation_IncompleteData() {
        // Given a user with incomplete data
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: nil,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .moderatelyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating BMR
        let bmr = user.calculateBMR()

        // Then BMR should be nil
        XCTAssertNil(bmr)
    }

    // MARK: - TDEE Tests

    func testTDEECalculation_Sedentary() {
        // Given a sedentary user
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .sedentary,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating TDEE
        let tdee = user.calculateTDEE()

        // Then TDEE should be BMR × 1.2
        let expectedBMR = 1780.0
        let expectedTDEE = expectedBMR * 1.2
        XCTAssertNotNil(tdee)
        XCTAssertEqual(tdee ?? 0, expectedTDEE, accuracy: 0.01)
    }

    func testTDEECalculation_LightlyActive() {
        // Given a lightly active user
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .lightlyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating TDEE
        let tdee = user.calculateTDEE()

        // Then TDEE should be BMR × 1.375
        let expectedBMR = 1780.0
        let expectedTDEE = expectedBMR * 1.375
        XCTAssertNotNil(tdee)
        XCTAssertEqual(tdee ?? 0, expectedTDEE, accuracy: 0.01)
    }

    func testTDEECalculation_ModeratelyActive() {
        // Given a moderately active user
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .moderatelyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating TDEE
        let tdee = user.calculateTDEE()

        // Then TDEE should be BMR × 1.55
        let expectedBMR = 1780.0
        let expectedTDEE = expectedBMR * 1.55
        XCTAssertNotNil(tdee)
        XCTAssertEqual(tdee ?? 0, expectedTDEE, accuracy: 0.01)
    }

    func testTDEECalculation_VeryActive() {
        // Given a very active user
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .veryActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating TDEE
        let tdee = user.calculateTDEE()

        // Then TDEE should be BMR × 1.725
        let expectedBMR = 1780.0
        let expectedTDEE = expectedBMR * 1.725
        XCTAssertNotNil(tdee)
        XCTAssertEqual(tdee ?? 0, expectedTDEE, accuracy: 0.01)
    }

    func testTDEECalculation_ExtraActive() {
        // Given an extra active user
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .extraActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating TDEE
        let tdee = user.calculateTDEE()

        // Then TDEE should be BMR × 1.9
        let expectedBMR = 1780.0
        let expectedTDEE = expectedBMR * 1.9
        XCTAssertNotNil(tdee)
        XCTAssertEqual(tdee ?? 0, expectedTDEE, accuracy: 0.01)
    }

    func testTDEECalculation_IncompleteData() {
        // Given a user without activity level
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: nil,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When calculating TDEE
        let tdee = user.calculateTDEE()

        // Then TDEE should be nil
        XCTAssertNil(tdee)
    }

    // MARK: - Profile Completeness Tests

    func testHasCompleteProfile_Complete() {
        // Given a user with all required data
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .moderatelyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then profile should be complete
        XCTAssertTrue(user.hasCompleteProfile)
    }

    func testHasCompleteProfile_Incomplete() {
        // Given a user missing weight
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: nil,
            height: 180.0,
            age: 30,
            gender: .male,
            activityLevel: .moderatelyActive,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then profile should be incomplete
        XCTAssertFalse(user.hasCompleteProfile)
    }

    // MARK: - Edge Cases

    func testBMRCalculation_ExtremeWeight() {
        // Test with very low weight
        let lightUser = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 45.0,
            height: 160.0,
            age: 20,
            gender: .female,
            activityLevel: .sedentary,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let lightBMR = lightUser.calculateBMR()
        XCTAssertNotNil(lightBMR)
        XCTAssertGreaterThan(lightBMR ?? 0, 0)

        // Test with very high weight
        let heavyUser = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            weight: 150.0,
            height: 190.0,
            age: 35,
            gender: .male,
            activityLevel: .sedentary,
            bmr: nil,
            tdee: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let heavyBMR = heavyUser.calculateBMR()
        XCTAssertNotNil(heavyBMR)
        XCTAssertGreaterThan(heavyBMR ?? 0, lightBMR ?? 0)
    }

    func testActivityLevelMultipliers() {
        // Test all activity level multipliers
        XCTAssertEqual(ActivityLevel.sedentary.multiplier, 1.2)
        XCTAssertEqual(ActivityLevel.lightlyActive.multiplier, 1.375)
        XCTAssertEqual(ActivityLevel.moderatelyActive.multiplier, 1.55)
        XCTAssertEqual(ActivityLevel.veryActive.multiplier, 1.725)
        XCTAssertEqual(ActivityLevel.extraActive.multiplier, 1.9)
    }
}
