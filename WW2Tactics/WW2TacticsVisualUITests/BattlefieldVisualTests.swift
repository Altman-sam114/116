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
    }
}
