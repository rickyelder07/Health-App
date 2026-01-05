//
//  ProfileSetupUITests.swift
//  HealthappUITests
//
//  UI tests for profile setup flow
//

import XCTest

final class ProfileSetupUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--new-user"]
        app.launchEnvironment = ["SHOW_PROFILE_SETUP": "true"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Complete Profile Setup Flow

    func testCompleteProfileSetup_Success() throws {
        app.launch()

        // Should start on profile setup
        XCTAssertTrue(app.navigationBars["Profile Setup"].waitForExistence(timeout: 5))

        // Enter name
        let nameField = app.textFields["Full Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("John Doe")

        // Enter age
        let ageField = app.textFields["Age"]
        ageField.tap()
        ageField.typeText("30")

        // Select gender
        let genderPicker = app.buttons["Select Gender"]
        if genderPicker.exists {
            genderPicker.tap()
            app.buttons["Male"].tap()
        } else {
            // Might be a picker wheel
            let malePicker = app.pickerWheels["Male"]
            if malePicker.exists {
                malePicker.adjust(toPickerWheelValue: "Male")
            }
        }

        // Enter weight
        let weightField = app.textFields["Weight"]
        weightField.tap()
        weightField.typeText("75")

        // Enter height
        let heightField = app.textFields["Height"]
        heightField.tap()
        heightField.typeText("180")

        // Select activity level
        let activityButton = app.buttons["Activity Level"]
        if activityButton.exists {
            activityButton.tap()
            app.buttons["Moderately Active"].tap()
        }

        // Tap Complete Setup
        let completeButton = app.buttons["Complete Setup"]
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()

        // Should navigate to home
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10), "Should navigate to home after setup")
    }

    func testProfileSetup_ValidationErrors() throws {
        app.launch()

        // Try to complete without filling required fields
        let completeButton = app.buttons["Complete Setup"]
        completeButton.tap()

        // Should show validation errors
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[cd] 'required'")).firstMatch
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 2), "Should show required field error")
    }

    func testProfileSetup_BMRTDEECalculation() throws {
        app.launch()

        // Fill in all required fields
        app.textFields["Full Name"].tap()
        app.textFields["Full Name"].typeText("Test User")

        app.textFields["Age"].tap()
        app.textFields["Age"].typeText("30")

        app.textFields["Weight"].tap()
        app.textFields["Weight"].typeText("80")

        app.textFields["Height"].tap()
        app.textFields["Height"].typeText("180")

        // Select gender and activity level
        // (Implementation depends on UI design)

        // Should display calculated BMR and TDEE
        let bmrLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'BMR'")).firstMatch
        XCTAssertTrue(bmrLabel.exists, "Should display BMR")

        let tdeeLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'TDEE'")).firstMatch
        XCTAssertTrue(tdeeLabel.exists, "Should display TDEE")
    }

    // MARK: - Unit Preference Tests

    func testProfileSetup_WeightUnitToggle() throws {
        app.launch()

        // Find unit toggle for weight
        let kgButton = app.buttons["kg"]
        let lbsButton = app.buttons["lbs"]

        if kgButton.exists && lbsButton.exists {
            // Tap lbs
            lbsButton.tap()

            // Enter weight in lbs
            let weightField = app.textFields["Weight"]
            weightField.tap()
            weightField.typeText("165")

            // Should show lbs unit
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'lbs'")).firstMatch.exists)

            // Switch back to kg
            kgButton.tap()

            // Value should convert (approximately)
            let convertedValue = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '75'")).firstMatch
            XCTAssertTrue(convertedValue.exists, "Should convert lbs to kg")
        }
    }

    func testProfileSetup_HeightUnitToggle() throws {
        app.launch()

        // Find unit toggle for height
        let cmButton = app.buttons["cm"]
        let ftButton = app.buttons["ft"]

        if cmButton.exists && ftButton.exists {
            // Tap ft
            ftButton.tap()

            // Should show feet/inches inputs
            let feetField = app.textFields["Feet"]
            let inchesField = app.textFields["Inches"]

            if feetField.exists && inchesField.exists {
                feetField.tap()
                feetField.typeText("5")

                inchesField.tap()
                inchesField.typeText("11")

                // Switch to cm
                cmButton.tap()

                // Should show converted value (≈ 180 cm)
                let heightField = app.textFields["Height"]
                let value = heightField.value as? String ?? ""
                XCTAssertTrue(value.contains("180"), "Should convert ft to cm")
            }
        }
    }

    // MARK: - Activity Level Selection

    func testProfileSetup_ActivityLevelSelection() throws {
        app.launch()

        let activityLevels = [
            "Sedentary",
            "Lightly Active",
            "Moderately Active",
            "Very Active",
            "Extra Active"
        ]

        for level in activityLevels {
            let button = app.buttons[level]
            if button.exists {
                button.tap()

                // Should be selected
                XCTAssertTrue(button.isSelected || button.value as? String == "selected")

                // TDEE should update based on activity level
                sleep(1) // Wait for calculation
                let tdeeLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'TDEE'")).firstMatch
                XCTAssertTrue(tdeeLabel.exists)
            }
        }
    }

    // MARK: - Gender Selection

    func testProfileSetup_GenderSelection() throws {
        app.launch()

        let genders = ["Male", "Female", "Other"]

        for gender in genders {
            let button = app.buttons[gender]
            if button.exists {
                button.tap()

                // Should be selected
                XCTAssertTrue(button.isSelected || button.value as? String == "selected")

                // BMR should update based on gender
                sleep(1)
                let bmrLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'BMR'")).firstMatch
                XCTAssertTrue(bmrLabel.exists)
            }
        }
    }

    // MARK: - Navigation Tests

    func testProfileSetup_CannotSkip() throws {
        app.launch()

        // Should not have skip button or back button
        let skipButton = app.buttons["Skip"]
        let backButton = app.navigationBars.buttons["Back"]

        XCTAssertFalse(skipButton.exists, "Should not be able to skip profile setup")
        XCTAssertFalse(backButton.exists, "Should not be able to go back from profile setup")
    }

    // MARK: - Keyboard Handling

    func testProfileSetup_KeyboardNavigation() throws {
        app.launch()

        // Tap first field
        let nameField = app.textFields["Full Name"]
        nameField.tap()

        // Keyboard should appear
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))

        // Tap return to move to next field
        app.keyboards.buttons["return"].tap()

        // Should move to age field
        let ageField = app.textFields["Age"]
        XCTAssertTrue(ageField.value as? String == "" || ageField.hasFocus)
    }

    func testProfileSetup_DismissKeyboard() throws {
        app.launch()

        // Show keyboard
        let weightField = app.textFields["Weight"]
        weightField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists)

        // Tap done on number pad
        let doneButton = app.toolbars.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()

            // Keyboard should dismiss
            XCTAssertFalse(app.keyboards.firstMatch.exists)
        }
    }

    // MARK: - Input Validation

    func testProfileSetup_NumericFieldValidation() throws {
        app.launch()

        // Try to enter non-numeric text in age field
        let ageField = app.textFields["Age"]
        ageField.tap()

        // Number keyboard should be shown (can't type letters)
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.exists)

        // Should only have number keys available
        let letterKey = app.keyboards.keys["A"]
        XCTAssertFalse(letterKey.exists, "Should not show letter keys on numeric field")
    }

    func testProfileSetup_ReasonableRanges() throws {
        app.launch()

        // Enter extreme age
        let ageField = app.textFields["Age"]
        ageField.tap()
        ageField.typeText("200")

        // Try to complete
        app.buttons["Complete Setup"].tap()

        // Should show validation error
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[cd] 'valid'")).firstMatch
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 2), "Should validate age range")
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    var hasFocus: Bool {
        return self.value(forKey: "hasKeyboardFocus") as? Bool ?? false
    }
}
