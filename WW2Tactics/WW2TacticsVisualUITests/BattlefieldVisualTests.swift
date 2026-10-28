import XCTest

final class BattlefieldVisualTests: XCTestCase {
    @MainActor
    func testLandscapeBattlefieldAndInspector() {
        continueAfterFailure = false
        let device = XCUIDevice.shared
        device.orientation = .landscapeRight
        let app = XCUIApplication()
        app.launchArguments = ["--ci-selected-combat-impact-steady"]
        app.launch()
        defer {
            app.terminate()
            device.orientation = .portrait
        }
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 15), .completed)
        let endTurn = app.buttons["battlefield-end-turn"]
        XCTAssertTrue(endTurn.waitForExistence(timeout: 15))
        XCTAssertTrue(endTurn.isHittable)
        XCTAssertTrue(app.staticTexts["M10坦克歼击营"].firstMatch.waitForExistence(timeout: 10))

        let inspector = app.buttons["战场情报"]
        XCTAssertTrue(inspector.waitForExistence(timeout: 10))
        inspector.tap()
        let close = app.buttons["收起战场情报"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        close.tap()
        XCTAssertFalse(close.exists)
        XCTAssertTrue(endTurn.isHittable)

        for index in 1...2 {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "battlefield-landscape-\(index)"
            attachment.lifetime = .keepAlways
            add(attachment)
            if index == 1 { Thread.sleep(forTimeInterval: 1) }
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
        let movedFrame = XCTAttachment(screenshot: app.screenshot())
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
