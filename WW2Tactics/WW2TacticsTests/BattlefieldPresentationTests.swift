import SwiftUI
import XCTest
@testable import WW2Tactics

@MainActor
final class BattlefieldPresentationTests: XCTestCase {
    func testAllCampaignTileFramesFitScrollableBounds() {
        for scenario in Scenario.campaignCatalog {
            let coordinates = scenario.tiles.map(\.coordinate)
            let layout = BattlefieldMapLayout(coordinates: coordinates)
            let bounds = CGRect(origin: .zero, size: layout.size)
            for coordinate in coordinates {
                XCTAssertTrue(bounds.contains(layout.frame(for: coordinate)), "\(scenario.id): \(coordinate.id)")
            }
            let last = HexCoordinate(q: scenario.mapColumns - 1, r: scenario.mapRows - 1)
            XCTAssertTrue(bounds.contains(layout.frame(for: last)))
            XCTAssertEqual(layout.frame(for: last).maxX + BattlefieldMapLayout.margin, layout.size.width, accuracy: 0.001)
        }
    }

    func testEveryNeighborSharesExactlyOneFullHexEdge() {
        let origin = HexCoordinate(q: 7, r: 6)
        let layout = BattlefieldMapLayout(coordinates: [origin] + origin.neighbors)
        let first = BattlefieldMapLayout.vertices(in: layout.frame(for: origin))
        for neighbor in origin.neighbors {
            let second = BattlefieldMapLayout.vertices(in: layout.frame(for: neighbor))
            let shared = first.filter { point in
                second.contains { abs($0.x - point.x) < 0.001 && abs($0.y - point.y) < 0.001 }
            }
            XCTAssertEqual(shared.count, 2, "\(neighbor.id) must share a full edge, without overlap/gaps")
        }
    }

    func testProjectionAndOverlayCenterUseTheSameOrigin() {
        let coordinate = HexCoordinate(q: 21, r: 13)
        let layout = BattlefieldMapLayout(coordinates: [HexCoordinate(q: 0, r: 0), coordinate])
        let raw = BattlefieldMapLayout.rawCenter(for: coordinate)
        let center = layout.center(for: coordinate)
        XCTAssertEqual(raw.x, (21 + 13.0 / 2) * 86 + 43)
        XCTAssertEqual(raw.y, 13 * 75 + 50)
        XCTAssertEqual(center.x, raw.x + BattlefieldMapLayout.margin)
        XCTAssertEqual(center.y, raw.y + BattlefieldMapLayout.margin)
        XCTAssertEqual(layout.frame(for: coordinate).midX, center.x)
        XCTAssertEqual(layout.frame(for: coordinate).midY, center.y)
    }

    func testScaledFramesStayInsideScaledBounds() {
        let coordinates = Scenario.ardennesPrototype().tiles.map(\.coordinate)
        let layout = BattlefieldMapLayout(coordinates: coordinates)
        for scale in [CGFloat(0.72), 1, 1.25, 1.55, 4] {
            let bounds = CGRect(origin: .zero, size: layout.scaledSize(scale))
            for coordinate in coordinates {
                let frame = layout.frame(for: coordinate)
                let scaled = CGRect(x: frame.minX * scale, y: frame.minY * scale,
                                    width: frame.width * scale, height: frame.height * scale)
                XCTAssertTrue(bounds.contains(scaled))
            }
        }
    }

    func testEmptyAndNegativeCoordinateLayoutsAreFinite() {
        for coordinates in [[], [HexCoordinate(q: -9, r: -7)]] {
            let layout = BattlefieldMapLayout(coordinates: coordinates)
            XCTAssertTrue(layout.size.width.isFinite && layout.size.height.isFinite)
            XCTAssertGreaterThan(layout.size.width, 0)
            XCTAssertGreaterThan(layout.size.height, 0)
            XCTAssertEqual(layout.scaledSize(.nan), layout.size)
            XCTAssertEqual(layout.scaledSize(-1), layout.size)
            for coordinate in coordinates {
                XCTAssertTrue(CGRect(origin: .zero, size: layout.size).contains(layout.frame(for: coordinate)))
            }
        }
    }

    func testReadinessDistinguishesAllFourMoveAttackCombinations() {
        for hasMoved in [false, true] {
            for hasAttacked in [false, true] {
                let value = UnitReadinessPresentation(hasMoved: hasMoved, hasAttacked: hasAttacked)
                XCTAssertEqual(value.canMove, !hasMoved)
                XCTAssertEqual(value.canAttack, !hasAttacked)
                XCTAssertEqual(value.isSpent, hasMoved && hasAttacked)
                XCTAssertEqual(value.moveSymbol == "checkmark", hasMoved)
                XCTAssertEqual(value.attackSymbol == "checkmark", hasAttacked)
            }
        }
    }

    func testHexPathHonorsNonzeroDrawingRectAndHitCenter() {
        let rect = CGRect(x: 197, y: 311, width: 86, height: 100)
        let path = Hexagon().path(in: rect)
        XCTAssertEqual(path.boundingRect, rect)
        XCTAssertTrue(path.contains(CGPoint(x: rect.midX, y: rect.midY)))
        XCTAssertFalse(path.contains(CGPoint(x: rect.minX + 1, y: rect.minY + 1)))
    }

    func testNewRenderingDoesNotChangeCampaignCoordinatesOrCombatEvidence() throws {
        let game = GameState()
        let before = game.tiles.map(\.coordinate)
        _ = BattlefieldMapLayout(coordinates: before)
        XCTAssertEqual(game.tiles.map(\.coordinate), before)
        game.handleTap(on: HexCoordinate(q: 7, r: 6))
        game.handleSecondaryAction(on: HexCoordinate(q: 9, r: 6))
        let preview = try XCTUnwrap(game.combatPreviewAgainstFocusedTarget())
        game.executeFocusedCommand()
        let result = try XCTUnwrap(game.latestCombatResult)
        XCTAssertEqual(result.damage, preview.damage)
        XCTAssertEqual(result.counterDamage, preview.counterDamage)
        XCTAssertEqual(result.defenderCoordinate, HexCoordinate(q: 9, r: 6))
    }

    func testBatchHintsMatchIndividualHintsForEveryCampaignAndUnitKind() {
        for scenario in Scenario.campaignCatalog {
            let game = GameState(scenario: scenario)
            for kind in UnitKind.allCases {
                guard let unit = game.units.first(where: { $0.faction == .allies && $0.kind == kind }) else {
                    XCTFail("Missing initial unit kind \(kind)")
                    continue
                }
                game.select(unitID: unit.id)
                let hints = game.mapActionHints()
                XCTAssertEqual(hints.count, game.tiles.count)
                for tile in game.tiles {
                    XCTAssertEqual(hints[tile.coordinate], game.mapActionHint(for: tile.coordinate))
                }
            }
        }
    }

    func testBatchHintsAreReadOnlyAndMatchIdleSpentAndVictoryStates() {
        let game = GameState()
        for stage in 0..<4 {
            if stage == 1 { game.handleTap(on: HexCoordinate(q: 7, r: 6)) }
            if stage == 2 { game.waitSelectedUnit() }
            if stage == 3 { game.winner = .allies }
            let units = game.scenario.units
            let points = game.commandPoints
            let log = game.battleLog
            let selected = game.selectedUnitID
            let hints = game.mapActionHints()
            for tile in game.tiles {
                XCTAssertEqual(hints[tile.coordinate], game.mapActionHint(for: tile.coordinate))
            }
            XCTAssertEqual(game.scenario.units, units)
            XCTAssertEqual(game.commandPoints, points)
            XCTAssertEqual(game.battleLog, log)
            XCTAssertEqual(game.selectedUnitID, selected)
        }
    }
}
