//
//  TimeStopUITests.swift
//  TimeStopUITests
//
//  Created by SamueL on 2025/3/27.
//

import XCTest

final class TimeStopUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunchAndWelcomeScreen() throws {
        // UI tests must launch the application that they test
        let app = XCUIApplication()
        app.launch()
        
        // Verify welcome screen appears
        XCTAssertTrue(app.staticTexts["欢迎使用TimeStop"].exists || app.staticTexts["Welcome to TimeStop"].exists,
                      "Welcome screen should appear on app launch")
        
        // Try to dismiss welcome screen if there's a button for that
        if app.buttons["开始使用"].exists {
            app.buttons["开始使用"].tap()
        } else if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Take screenshot of app state after welcome screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Post Welcome Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testAuthenticationFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Skip welcome screen if present
        if app.buttons["开始使用"].exists {
            app.buttons["开始使用"].tap()
        } else if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Check if login inputs exist
        let usernameField = app.textFields["Username"]
        let passwordField = app.secureTextFields["Password"]
        
        if usernameField.exists && passwordField.exists {
            // Test login with test credentials
            usernameField.tap()
            usernameField.typeText("testuser")
            
            passwordField.tap()
            passwordField.typeText("password123")
            
            // Try to find login button by various identifiers
            if app.buttons["登录"].exists {
                app.buttons["登录"].tap()
            } else if app.buttons["Login"].exists {
                app.buttons["Login"].tap()
            } else if app.buttons["Sign In"].exists {
                app.buttons["Sign In"].tap()
            }
            
            // Verify we've successfully logged in by checking for main UI elements
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", "task")
            XCTAssertTrue(app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 3),
                          "Should show main screen after login")
        }
        
        // Take screenshot after authentication flow
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Post Authentication"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testTaskCreation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Complete welcome and login flow if needed
        completeInitialFlowIfNeeded(app)
        
        // Test task creation
        // First check if we're on home tab, if not navigate to it
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons.firstMatch.tap() // Home tab is typically first
        }
        
        // Look for task title field and input text
        let taskTitleField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS[c] 'task'")).firstMatch
        if taskTitleField.exists {
            taskTitleField.tap()
            taskTitleField.typeText("UI Test Task")
            
            // Try to set duration if duration field exists
            if let durationField = app.textFields.allElementsBoundByIndex.last {
                durationField.tap()
                durationField.typeText("25")
            }
            
            // Try to find and tap task creation button
            let createTaskButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'start' OR label CONTAINS[c] 'create'")).firstMatch
            
            if createTaskButton.exists {
                createTaskButton.tap()
                
                // Verify task is created and timer is shown
                XCTAssertTrue(app.progressIndicators.firstMatch.waitForExistence(timeout: 2),
                              "Timer screen should appear after creating a task")
            }
        }
        
        // Take screenshot of task creation result
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Task Creation"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Complete welcome and login flow if needed
        completeInitialFlowIfNeeded(app)
        
        // Test tab navigation
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            // Test all tabs - usually there are 4 tabs
            let tabCount = tabBar.buttons.count
            for i in 0..<min(tabCount, 4) {
                tabBar.buttons.element(boundBy: i).tap()
                
                // Verify some content appears when tab is selected
                XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 1) || 
                             app.otherElements.firstMatch.waitForExistence(timeout: 1),
                             "Content should be visible after tab selection")
                
                // Take screenshot of each tab
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Tab \(i+1)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
    
    private func completeInitialFlowIfNeeded(_ app: XCUIApplication) {
        // Skip welcome screen if present
        if app.buttons["开始使用"].exists {
            app.buttons["开始使用"].tap()
        } else if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Check if login screen is present and login if needed
        let usernameField = app.textFields["Username"]
        if usernameField.exists {
            usernameField.tap()
            usernameField.typeText("testuser")
            
            let passwordField = app.secureTextFields["Password"]
            if passwordField.exists {
                passwordField.tap()
                passwordField.typeText("password123")
                
                // Try to find login button by various identifiers
                if app.buttons["登录"].exists {
                    app.buttons["登录"].tap()
                } else if app.buttons["Login"].exists {
                    app.buttons["Login"].tap()
                } else if app.buttons["Sign In"].exists {
                    app.buttons["Sign In"].tap()
                }
                
                // Wait for main UI to appear
                _ = app.buttons.firstMatch.waitForExistence(timeout: 3)
            }
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
