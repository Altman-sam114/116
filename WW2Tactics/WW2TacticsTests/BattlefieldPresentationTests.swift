import SwiftUI
import XCTest
@testable import WW2Tactics

@MainActor
final class BattlefieldPresentationTests: XCTestCase {
    func testOriginalArtworkResourcesAreBundledWithinBudget() throws {
        var totalBytes = 0
        for name in BattlefieldArtwork.resourceNames {
            let url = try XCTUnwrap(BattlefieldArtwork.resourceURL(name), "Missing bundled art: \(name)")
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            totalBytes += try XCTUnwrap(values.fileSize)
        }
        XCTAssertGreaterThan(totalBytes, 1_000_000)
        XCTAssertLessThanOrEqual(totalBytes, 24_000_000)
        let ground = try XCTUnwrap(BattlefieldArtwork.ground)
        XCTAssertGreaterThanOrEqual(ground.width, 512)
        XCTAssertEqual(ground.width, ground.height)
    }

    func testEveryUnitAndScenerySpriteHasTransparencyAndVisibleArtwork() throws {
        var images: [CGImage] = []
        for faction in Faction.allCases {
            for kind in UnitKind.allCases {
                let first = try XCTUnwrap(BattlefieldArtwork.unit(kind, faction: faction))
                let second = try XCTUnwrap(BattlefieldArtwork.unit(kind, faction: faction))
                XCTAssertTrue(first === second, "Sprites must reuse their decoded image")
                images.append(first)
            }
        }
        for kind in BattlefieldScenery.allCases {
            images.append(try XCTUnwrap(BattlefieldArtwork.scenery(kind)))
        }
        XCTAssertEqual(images.count, 12)
        for image in images {
            XCTAssertEqual(image.width, 768)
            XCTAssertEqual(image.height, 512)
            var pixels = [UInt8](repeating: 0, count: 64 * 64 * 4)
            try pixels.withUnsafeMutableBytes { buffer in
                let context = try XCTUnwrap(CGContext(
                    data: buffer.baseAddress, width: 64, height: 64, bitsPerComponent: 8,
                    bytesPerRow: 64 * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ))
                context.draw(image, in: CGRect(x: 0, y: 0, width: 64, height: 64))
            }
            let alpha = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
            XCTAssertGreaterThan(alpha.filter { $0 < 8 }.count, 4096 / 8, "No opaque atlas backdrop")
            XCTAssertGreaterThan(alpha.filter { $0 > 180 }.count, 4096 / 8, "No empty/transparent sprite")
        }
    }

    func testAtlasCellsPartitionTheOriginalSheetWithoutOverlap() {
        let cells = (0..<4).map {
            BattlefieldArtwork.cellRect(column: $0 % 2, row: $0 / 2, width: 1536, height: 1024)
        }
        XCTAssertEqual(cells.reduce(CGRect.null) { $0.union($1) }, CGRect(x: 0, y: 0, width: 1536, height: 1024))
        for index in cells.indices {
            XCTAssertEqual(cells[index].size, CGSize(width: 768, height: 512))
            for other in cells.indices where index != other {
                XCTAssertFalse(cells[index].intersects(cells[other]))
            }
        }
    }

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

    func testScaledScrollAnchorsAndCombatMidpointMatchVisibleGeometry() {
        let attacker = HexCoordinate(q: 7, r: 6)
        let defender = HexCoordinate(q: 9, r: 6)
        let layout = BattlefieldMapLayout(coordinates: Scenario.ardennesPrototype().tiles.map(\.coordinate))
        for scale in [CGFloat(0.72), 1, 1.25, 1.55] {
            let start = layout.scaledCenter(for: attacker, scale: scale)
            let end = layout.scaledCenter(for: defender, scale: scale)
            let focus = layout.combatFocusPoint(attacker: attacker, defender: defender, scale: scale)
            XCTAssertEqual(start.x, layout.center(for: attacker).x * scale)
            XCTAssertEqual(start.y, layout.center(for: attacker).y * scale)
            XCTAssertEqual(focus.x, (start.x + end.x) / 2)
            XCTAssertEqual(focus.y, (start.y + end.y) / 2)
            XCTAssertEqual(focus, layout.combatFocusPoint(attacker: defender, defender: attacker, scale: scale))
        }
        XCTAssertEqual(layout.scaledCenter(for: attacker, scale: .nan), layout.center(for: attacker))
    }

    func testCombatPlateFramesStayInsideMapAtEveryCorner() {
        let bounds = CGSize(width: 600, height: 480)
        for start in [CGPoint(x: 2, y: 2), CGPoint(x: 598, y: 2),
                      CGPoint(x: 2, y: 478), CGPoint(x: 598, y: 478)] {
            for end in [CGPoint(x: start.x + 86, y: start.y), start] {
                let layout = CombatResolutionLayout(attackerPoint: start, defenderPoint: end, bounds: bounds)
                for point in [layout.hitPlatePoint, layout.retPlatePoint] {
                    XCTAssertGreaterThanOrEqual(point.x - CombatResolutionLayout.damagePlateWidth / 2, 0)
                    XCTAssertLessThanOrEqual(point.x + CombatResolutionLayout.damagePlateWidth / 2, bounds.width)
                    XCTAssertGreaterThanOrEqual(point.y, 16)
                    XCTAssertLessThanOrEqual(point.y, bounds.height - 16)
                }
                XCTAssertGreaterThanOrEqual(layout.conclusionPoint.x - CombatResolutionLayout.conclusionWidth / 2, 0)
                XCTAssertLessThanOrEqual(layout.conclusionPoint.x + CombatResolutionLayout.conclusionWidth / 2, bounds.width)
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
