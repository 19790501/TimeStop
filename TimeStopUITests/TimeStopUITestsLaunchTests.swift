//
//  TimeStopUITestsLaunchTests.swift
//  TimeStopUITests
//
//  Created by SamueL on 2025/3/27.
//

import XCTest

final class TimeStopUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Add error handling for more robust testing
        XCTContext.runActivity(named: "Verify app launches successfully") { _ in
            XCTAssertTrue(app.exists, "App should exist after launch")
            
            // Wait for initial UI elements to appear (welcome screen or login)
            let welcomeScreenExists = app.staticTexts["欢迎使用TimeStop"].waitForExistence(timeout: 5) || 
                                       app.staticTexts["Welcome to TimeStop"].waitForExistence(timeout: 1)
            
            if !welcomeScreenExists {
                // If welcome screen isn't found, check for login screen
                let loginExists = app.textFields["Username"].waitForExistence(timeout: 2) ||
                                  app.buttons["登录"].waitForExistence(timeout: 1) ||
                                  app.buttons["Login"].waitForExistence(timeout: 1)
                
                XCTAssertTrue(welcomeScreenExists || loginExists, 
                             "Either welcome screen or login screen should appear after launch")
            }
        }
        
        // Take multiple screenshots with better naming
        let launchAttachment = XCTAttachment(screenshot: app.screenshot())
        launchAttachment.name = "Initial Launch Screen"
        launchAttachment.lifetime = .keepAlways
        add(launchAttachment)
        
        // Try to dismiss welcome screen if present and take post-welcome screenshot
        if app.buttons["开始使用"].exists {
            app.buttons["开始使用"].tap()
            
            let postWelcomeAttachment = XCTAttachment(screenshot: app.screenshot())
            postWelcomeAttachment.name = "Post Welcome Screen"
            postWelcomeAttachment.lifetime = .keepAlways
            add(postWelcomeAttachment)
        } else if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
            
            let postWelcomeAttachment = XCTAttachment(screenshot: app.screenshot())
            postWelcomeAttachment.name = "Post Welcome Screen"
            postWelcomeAttachment.lifetime = .keepAlways
            add(postWelcomeAttachment)
        }
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    @MainActor
    func testAccessibilityElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test for accessibility labels on key UI elements
        XCTContext.runActivity(named: "Verify accessibility elements") { _ in
            // Collect all key interactive elements
            let buttons = app.buttons.allElementsBoundByIndex
            let textFields = app.textFields.allElementsBoundByIndex
            
            // Check buttons for accessibility labels
            for i in 0..<min(buttons.count, 5) { // Check first 5 buttons max
                let button = buttons[i]
                if button.isHittable {
                    XCTAssertFalse(button.label.isEmpty, "Button should have accessibility label")
                }
            }
            
            // Check text fields for accessibility labels
            for i in 0..<min(textFields.count, 3) { // Check first 3 text fields max
                let textField = textFields[i]
                if textField.isHittable {
                    XCTAssertFalse(textField.placeholderValue == nil && textField.label.isEmpty, 
                                  "Text field should have accessibility label or placeholder")
                }
            }
        }
        
        let accessibilityAttachment = XCTAttachment(screenshot: app.screenshot())
        accessibilityAttachment.name = "Accessibility Testing Screen"
        accessibilityAttachment.lifetime = .keepAlways
        add(accessibilityAttachment)
    }
}
