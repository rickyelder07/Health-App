//
//  AuthenticationUITests.swift
//  HealthappUITests
//
//  UI tests for authentication flow
//
//  ⚠️ IMPORTANT: These tests are TEMPLATES and need to be customized
//  for your specific authentication screen.
//
//  To customize:
//  1. Run your app manually and note the exact text/labels of UI elements
//  2. Update the button/field identifiers below to match your app
//  3. Remove the XCTSkip() calls once customized
//

import XCTest

final class AuthenticationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--logout"]
        app.launchEnvironment = [
            "RESET_APP_STATE": "true",
            "FORCE_LOGOUT": "true"
        ]

        // Reset authorization status for notifications
        resetAuthorizationStatus(for: .userNotifications)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Sign Up Flow Tests

    func testSignUpFlow_Success() throws {
        throw XCTSkip("UI test needs to be customized for your authentication screen")

        // Given the app is launched
        app.launch()

        // When user taps Sign Up
        let signUpButton = app.buttons["Sign Up"]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 5))
        signUpButton.tap()

        // And enters email
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.exists)
        emailField.tap()
        emailField.typeText("test@example.com")

        // And enters password
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("TestPassword123!")

        // And enters name
        let nameField = app.textFields["Full Name"]
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Test User")
        }

        // And taps create account
        let createButton = app.buttons["Create Account"]
        XCTAssertTrue(createButton.exists)
        createButton.tap()

        // Then should navigate to profile setup or home
        let profileSetupExists = app.navigationBars["Profile Setup"].waitForExistence(timeout: 10)
        let homeExists = app.tabBars.buttons["Home"].waitForExistence(timeout: 10)

        XCTAssertTrue(profileSetupExists || homeExists, "Should navigate after successful sign up")
    }

    func testSignUpFlow_ValidationErrors() throws {
        app.launch()

        // Navigate to sign up
        app.buttons["Sign Up"].tap()

        // Try to submit without filling fields
        let createButton = app.buttons["Create Account"]
        createButton.tap()

        // Should show validation errors
        let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[cd] 'required'")).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 2), "Should show validation error")
    }

    func testSignUpFlow_InvalidEmail() throws {
        app.launch()

        app.buttons["Sign Up"].tap()

        // Enter invalid email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("notanemail")

        // Enter password
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("TestPassword123!")

        // Try to create account
        app.buttons["Create Account"].tap()

        // Should show email format error
        let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[cd] 'email'")).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 2), "Should show email format error")
    }

    // MARK: - Sign In Flow Tests

    func testSignInFlow_Success() throws {
        app.launch()

        // When user enters credentials
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("existing@example.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("ExistingPassword123!")

        // And taps sign in
        let signInButton = app.buttons["Sign In"]
        signInButton.tap()

        // Then should navigate to home (for existing user)
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10), "Should navigate to home after sign in")
    }

    func testSignInFlow_InvalidCredentials() throws {
        app.launch()

        // Enter invalid credentials
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("wrong@example.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("WrongPassword123!")

        // Try to sign in
        app.buttons["Sign In"].tap()

        // Should show error
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5), "Should show error alert")
    }

    func testSignInFlow_TogglePasswordVisibility() throws {
        app.launch()

        // Enter password
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("TestPassword")

        // Toggle visibility
        let toggleButton = app.buttons["Show Password"]
        if toggleButton.exists {
            toggleButton.tap()

            // Password should now be visible in text field
            let visiblePasswordField = app.textFields["Password"]
            XCTAssertTrue(visiblePasswordField.exists, "Password should be visible")
        }
    }

    // MARK: - Navigation Tests

    func testNavigation_SwitchBetweenSignInAndSignUp() throws {
        app.launch()

        // Should start on sign in
        XCTAssertTrue(app.buttons["Sign In"].exists)

        // Navigate to sign up
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.buttons["Create Account"].exists)

        // Navigate back to sign in
        let backButton = app.buttons["Back"] // or navigation back button
        if backButton.exists {
            backButton.tap()
            XCTAssertTrue(app.buttons["Sign In"].exists)
        }
    }

    // MARK: - Keyboard Handling Tests

    func testKeyboardHandling_DismissOnReturn() throws {
        app.launch()

        // Tap email field to show keyboard
        let emailField = app.textFields["Email"]
        emailField.tap()

        // Keyboard should be visible
        XCTAssertTrue(app.keyboards.firstMatch.exists)

        // Press return
        app.keyboards.buttons["return"].tap()

        // Focus should move to next field or keyboard should dismiss
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists)
    }

    func testKeyboardHandling_DismissOnTapOutside() throws {
        app.launch()

        // Show keyboard
        let emailField = app.textFields["Email"]
        emailField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists)

        // Tap outside (on background)
        let background = app.otherElements["AuthenticationView"] // May need adjustment
        if background.exists {
            background.tap()

            // Keyboard should dismiss
            XCTAssertFalse(app.keyboards.firstMatch.exists)
        }
    }
}
