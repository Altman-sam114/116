import XCTest
import UIKit

final class BattlefieldVisualTests: XCTestCase {
    @MainActor
    func testLandscapeBattlefieldAndInspector() {
        continueAfterFailure = false
        let device = XCUIDevice.shared
        device.orientation = .landscapeRight
        let app = XCUIApplication()
        app.launchArguments = []
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
            device.orientation = .landscapeRight
        }
        app.launch()
        XCTAssertTrue(app.buttons["battlefield-end-turn"].waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 2)
        for index in 1...2 {
            let frame = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            frame.name = "battlefield-default-landscape-\(index)"
            frame.lifetime = .keepAlways
            add(frame)
            if index == 1 { Thread.sleep(forTimeInterval: 1) }
        }
        app.terminate()
        app.launchArguments = ["--ci-selected-combat-impact-steady"]
        app.launch()
        let endTurn = app.buttons["battlefield-end-turn"]
        XCTAssertTrue(endTurn.waitForExistence(timeout: 15))
        // Verify that both the app and captured display are landscape.
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

        // Reopen a real post-move attack preview in landscape and exercise the same
        // action strip rather than inferring that its attack control is reachable.
        app.terminate()
        device.orientation = .landscapeRight
        app.launchArguments = ["--ci-selected-attack-preview"]
        app.launch()
        let attackLandscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let display = self.displaySize(of: XCUIScreen.main.screenshot())
            return app.frame.width > app.frame.height && display.width > display.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [attackLandscape], timeout: 15), .completed)
        let attackSelection = app.descendants(matching: .any)["battlefield-selected-unit"].firstMatch
        XCTAssertTrue(attackSelection.waitForExistence(timeout: 15))
        XCTAssertTrue((attackSelection.value as? String)?.contains("攻击可用") == true)
        let attack = app.buttons["攻击"]
        XCTAssertTrue(attack.isHittable)
        XCTAssertTrue(attack.isEnabled)
        attack.tap()
        let executeAttack = app.buttons["battlefield-execute-order"]
        XCTAssertTrue(executeAttack.waitForExistence(timeout: 10))
        XCTAssertTrue(executeAttack.isHittable)
        let combatMessage = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "M10坦克歼击营 攻击 ", "伤害"
        )).firstMatch
        XCTAssertFalse(combatMessage.exists)
        executeAttack.tap()
        XCTAssertTrue(combatMessage.waitForExistence(timeout: 10))
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
