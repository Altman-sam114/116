import XCTest
import UIKit

final class BattlefieldVisualTests: XCTestCase {
    @MainActor
    func testLandscapeBattlefieldAndInspector() {
        continueAfterFailure = false
        let device = XCUIDevice.shared
        device.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ci-selected-combat-impact-steady"]
        addTeardownBlock { @MainActor () async throws in
            let screen = XCUIScreen.main.screenshot()
            let finalFrame = XCTAttachment(screenshot: screen)
            finalFrame.name = "battlefield-ui-final"
            finalFrame.lifetime = .keepAlways
            self.add(finalFrame)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "battlefield-ui-hierarchy"
            hierarchy.lifetime = .keepAlways
            self.add(hierarchy)
            let metadata = XCTAttachment(string: "appFrame=\(app.frame)\nuiImageSize=\(screen.image.size)\nuiImageOrientation=\(screen.image.imageOrientation.rawValue)\npixelWidth=\(screen.image.cgImage?.width ?? 0)\npixelHeight=\(screen.image.cgImage?.height ?? 0)")
            metadata.name = "battlefield-display-metadata"
            metadata.lifetime = .keepAlways
            self.add(metadata)
            app.terminate()
            device.orientation = .portrait
        }
        app.launch()
        let endTurn = app.buttons["battlefield-end-turn"]
        XCTAssertTrue(endTurn.waitForExistence(timeout: 15))
        // Rotate the running scene; pre-launch rotation can leave XCTest's display buffer in portrait.
        device.orientation = .landscapeRight
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let display = self.displaySize(of: XCUIScreen.main.screenshot())
            return app.frame.width > app.frame.height && display.width > display.height
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
            let display = displaySize(of: screenshot)
            XCTAssertGreaterThan(display.width, display.height)
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

    private func displaySize(of screenshot: XCUIScreenshot) -> CGSize {
        let image = screenshot.image
        guard let pixels = image.cgImage else { return .zero }
        switch image.imageOrientation {
        case .left, .right, .leftMirrored, .rightMirrored:
            return CGSize(width: pixels.height, height: pixels.width)
        default:
            return CGSize(width: pixels.width, height: pixels.height)
        }
    }
}
