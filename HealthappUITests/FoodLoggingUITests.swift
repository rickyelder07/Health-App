//
//  FoodLoggingUITests.swift
//  HealthappUITests
//
//  UI tests for food logging flow
//

import XCTest

final class FoodLoggingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--authenticated"]
        app.launchEnvironment = ["TEST_USER_ID": "test-user-123"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    private func navigateToFoodTab() {
        let foodTab = app.tabBars.buttons["Food"]
        XCTAssertTrue(foodTab.waitForExistence(timeout: 5))
        foodTab.tap()
    }

    private func tapAddFoodButton() {
        let addButton = app.buttons["Add Food"]
        XCTAssertTrue(addButton.exists, "Add Food button should exist")
        addButton.tap()
    }

    // MARK: - Custom Food Entry Tests

    func testAddCustomFood_Success() throws {
        app.launch()
        navigateToFoodTab()
        tapAddFoodButton()

        // Should open Add Food view
        XCTAssertTrue(app.navigationBars["Add Food"].waitForExistence(timeout: 3))

        // Enter food name
        let nameField = app.textFields["Food Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Grilled Chicken")

        // Enter calories
        let caloriesField = app.textFields["Calories"]
        caloriesField.tap()
        caloriesField.typeText("165")

        // Enter protein
        let proteinField = app.textFields["Protein"]
        proteinField.tap()
        proteinField.typeText("31")

        // Enter carbs
        let carbsField = app.textFields["Carbs"]
        carbsField.tap()
        carbsField.typeText("0")

        // Enter fat
        let fatField = app.textFields["Fat"]
        fatField.tap()
        fatField.typeText("3.6")

        // Select meal type
        let mealTypePicker = app.buttons["Meal Type"]
        if mealTypePicker.exists {
            mealTypePicker.tap()
            app.buttons["Lunch"].tap()
        }

        // Tap Log Food
        let logButton = app.buttons["Log Food"]
        XCTAssertTrue(logButton.exists)
        logButton.tap()

        // Should navigate back and show new food log
        XCTAssertTrue(app.staticTexts["Grilled Chicken"].waitForExistence(timeout: 5))
    }

    func testAddCustomFood_ValidationErrors() throws {
        app.launch()
        navigateToFoodTab()
        tapAddFoodButton()

        // Try to submit without required fields
        let logButton = app.buttons["Log Food"]
        logButton.tap()

        // Should show validation error
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[cd] 'required'")).firstMatch
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 2))
    }

    func testAddCustomFood_ServingsMultiplier() throws {
        app.launch()
        navigateToFoodTab()
        tapAddFoodButton()

        // Fill in food details
        app.textFields["Food Name"].tap()
        app.textFields["Food Name"].typeText("Banana")

        app.textFields["Calories"].tap()
        app.textFields["Calories"].typeText("105")

        app.textFields["Protein"].tap()
        app.textFields["Protein"].typeText("1.3")

        // Change servings to 2
        let servingsField = app.textFields["Servings"]
        if servingsField.exists {
            servingsField.tap()
            servingsField.clearText()
            servingsField.typeText("2")

            // Total calories should update (105 × 2 = 210)
            let totalCaloriesLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '210'")).firstMatch
            XCTAssertTrue(totalCaloriesLabel.exists, "Total calories should be calculated")
        }

        app.buttons["Log Food"].tap()

        // Verify entry appears
        XCTAssertTrue(app.staticTexts["Banana"].waitForExistence(timeout: 5))
    }

    // MARK: - USDA Food Search Tests

    func testUSDAFoodSearch_SearchAndSelect() throws {
        app.launch()
        navigateToFoodTab()
        tapAddFoodButton()

        // Tap Search USDA button
        let searchButton = app.buttons["Search USDA"]
        if searchButton.exists {
            searchButton.tap()

            // Enter search term
            let searchField = app.searchFields.firstMatch
            XCTAssertTrue(searchField.waitForExistence(timeout: 3))
            searchField.tap()
            searchField.typeText("chicken breast")

            // Wait for results
            sleep(2) // Wait for network request

            // Tap first result
            let firstResult = app.tables.cells.firstMatch
            if firstResult.waitForExistence(timeout: 5) {
                firstResult.tap()

                // Should populate fields
                let nameField = app.textFields["Food Name"]
                XCTAssertFalse(nameField.value as? String ?? "" == "", "Name should be populated")
            }
        }
    }

    func testUSDAFoodSearch_NoResults() throws {
        app.launch()
        navigateToFoodTab()
        tapAddFoodButton()

        let searchButton = app.buttons["Search USDA"]
        if searchButton.exists {
            searchButton.tap()

            // Search for nonsense
            let searchField = app.searchFields.firstMatch
            searchField.tap()
            searchField.typeText("xyznonexistentfood123")

            // Wait for results
            sleep(2)

            // Should show no results message
            let noResultsText = app.staticTexts["No results found"]
            XCTAssertTrue(noResultsText.waitForExistence(timeout: 3))
        }
    }

    // MARK: - Meal Type Selection Tests

    func testMealTypeSelection_AllTypes() throws {
        app.launch()
        navigateToFoodTab()

        // Test each meal type filter/section
        let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

        for mealType in mealTypes {
            let button = app.buttons[mealType]
            if button.exists {
                button.tap()
                // Should filter or navigate to that meal type
                XCTAssertTrue(app.staticTexts[mealType].exists)
            }
        }
    }

    // MARK: - Edit Food Log Tests

    func testEditFoodLog() throws {
        app.launch()
        navigateToFoodTab()

        // Assume there's at least one food log
        let firstFoodCell = app.tables.cells.firstMatch
        if firstFoodCell.waitForExistence(timeout: 5) {
            // Long press or swipe for edit options
            firstFoodCell.swipeLeft()

            // Tap edit button
            let editButton = app.buttons["Edit"]
            if editButton.exists {
                editButton.tap()

                // Should open edit view
                XCTAssertTrue(app.navigationBars["Edit Food"].waitForExistence(timeout: 3))

                // Modify calories
                let caloriesField = app.textFields["Calories"]
                caloriesField.tap()
                caloriesField.clearText()
                caloriesField.typeText("200")

                // Save changes
                app.buttons["Save"].tap()

                // Should navigate back
                XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 3))
            }
        }
    }

    // MARK: - Delete Food Log Tests

    func testDeleteFoodLog() throws {
        app.launch()
        navigateToFoodTab()

        // Swipe to delete
        let firstFoodCell = app.tables.cells.firstMatch
        if firstFoodCell.waitForExistence(timeout: 5) {
            let foodName = firstFoodCell.staticTexts.firstMatch.label

            firstFoodCell.swipeLeft()

            // Tap delete button
            let deleteButton = app.buttons["Delete"]
            XCTAssertTrue(deleteButton.exists)
            deleteButton.tap()

            // Confirm deletion if alert appears
            let confirmButton = app.alerts.buttons["Delete"]
            if confirmButton.waitForExistence(timeout: 2) {
                confirmButton.tap()
            }

            // Food should be removed
            sleep(1)
            let deletedCell = app.staticTexts[foodName]
            XCTAssertFalse(deletedCell.exists, "Deleted food should not appear")
        }
    }

    // MARK: - Daily Summary Tests

    func testDailySummaryDisplay() throws {
        app.launch()
        navigateToFoodTab()

        // Should display daily totals
        let caloriesLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Calories'")).firstMatch
        XCTAssertTrue(caloriesLabel.exists, "Should show calories total")

        let proteinLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Protein'")).firstMatch
        XCTAssertTrue(proteinLabel.exists, "Should show protein total")

        let carbsLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Carbs'")).firstMatch
        XCTAssertTrue(carbsLabel.exists, "Should show carbs total")

        let fatLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Fat'")).firstMatch
        XCTAssertTrue(fatLabel.exists, "Should show fat total")
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefresh() throws {
        app.launch()
        navigateToFoodTab()

        // Pull down to refresh
        let foodList = app.tables.firstMatch
        if foodList.exists {
            let start = foodList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            let end = foodList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))

            start.press(forDuration: 0.1, thenDragTo: end)

            // Should show loading indicator briefly
            sleep(1)

            // List should still be visible after refresh
            XCTAssertTrue(foodList.exists)
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
