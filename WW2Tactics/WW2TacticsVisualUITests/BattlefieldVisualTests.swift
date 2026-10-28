import XCTest

final class BattlefieldVisualTests: XCTestCase {
    @MainActor
    func testLandscapeBattlefieldAndInspector() {
        continueAfterFailure = false
        let device = XCUIDevice.shared
        device.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ci-selected-combat-impact-steady"]
        app.launch()
        defer {
            let finalFrame = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            finalFrame.name = "battlefield-ui-final"
            finalFrame.lifetime = .keepAlways
            add(finalFrame)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "battlefield-ui-hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            app.terminate()
            device.orientation = .portrait
        }
        let endTurn = app.buttons["battlefield-end-turn"]
        XCTAssertTrue(endTurn.waitForExistence(timeout: 15))
        // Rotate the running scene; pre-launch rotation can leave XCTest's display buffer in portrait.
        device.orientation = .landscapeRight
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let pixels = XCUIScreen.main.screenshot().image.cgImage
            return app.frame.width > app.frame.height && (pixels?.width ?? 0) > (pixels?.height ?? 0)
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 15), .completed)
        XCTAssertTrue(endTurn.isHittable)
        XCTAssertTrue(app.staticTexts["M10坦克歼击营"].firstMatch.waitForExistence(timeout: 10))

        let inspector = app.buttons["battlefield-intelligence-toggle"]
        XCTAssertTrue(inspector.waitForExistence(timeout: 10))
        XCTAssertTrue(inspector.isHittable)
        inspector.tap()
        let close = app.buttons["battlefield-intelligence-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        XCTAssertTrue(close.isHittable)
        XCTAssertLessThanOrEqual(close.frame.maxX, app.frame.maxX)
        XCTAssertLessThanOrEqual(close.frame.maxY, app.frame.maxY)
        close.tap()
        XCTAssertFalse(close.exists)
        XCTAssertTrue(endTurn.isHittable)

        for index in 1...2 {
            let screenshot = XCUIScreen.main.screenshot()
            XCTAssertGreaterThan(screenshot.image.cgImage?.width ?? 0, screenshot.image.cgImage?.height ?? 0)
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "battlefield-landscape-\(index)"
            attachment.lifetime = .keepAlways
            add(attachment)
            if index == 1 { Thread.sleep(forTimeInterval: 1) }
        }

        for title in ["编队与据点定位", "战术支援"] {
            let toggle = app.buttons[title]
            XCTAssertTrue(toggle.isHittable)
            toggle.tap()
            let dismiss = app.buttons["收起地图面板"]
            XCTAssertTrue(dismiss.waitForExistence(timeout: 10))
            XCTAssertTrue(dismiss.isHittable)
            dismiss.tap()
            XCTAssertFalse(dismiss.exists)
        }

        app.buttons["下一支待命部队"].tap()
        XCTAssertTrue(app.staticTexts["第4装甲师"].firstMatch.waitForExistence(timeout: 10))
        let selected = app.descendants(matching: .any)["battlefield-selected-unit"].firstMatch
        XCTAssertTrue((selected.value as? String)?.contains("移动可用") == true)
        let beforeMove = selected.value as? String
        let objective = app.buttons["据点"]
        XCTAssertTrue(objective.isEnabled)
        objective.tap()
        let execute = app.buttons["battlefield-execute-order"]
        XCTAssertTrue(execute.waitForExistence(timeout: 10))
        XCTAssertTrue(execute.isHittable)
        execute.tap()
        let moved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (selected.value as? String)?.contains("移动已用") == true
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [moved], timeout: 10), .completed)
        XCTAssertNotEqual(selected.value as? String, beforeMove)
        let movedFrame = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        movedFrame.name = "battlefield-order-executed"
        movedFrame.lifetime = .keepAlways
        add(movedFrame)
        endTurn.tap()
        let nextTurn = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (endTurn.value as? String)?.contains("第2回合") == true
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [nextTurn], timeout: 15), .completed)
    }
}
