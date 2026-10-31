import SwiftUI
import XCTest
@testable import WW2Tactics

@MainActor
final class BattlefieldPresentationTests: XCTestCase {
    func testTacticalCameraKeepsModelsReadableInBothOrientations() {
        for size in [CGSize(width: 440, height: 900), CGSize(width: 900, height: 370),
                     CGSize(width: 1024, height: 1300), CGSize(width: 1300, height: 900)] {
            let campaign = BattlefieldMapCamera.scale(viewport: size, zoom: MapScaleMode.campaign.scaleMultiplier)
            let tactical = BattlefieldMapCamera.scale(viewport: size, zoom: MapScaleMode.tactical.scaleMultiplier)
            let detail = BattlefieldMapCamera.scale(viewport: size, zoom: MapScaleMode.detail.scaleMultiplier)
            XCTAssertLessThan(campaign, tactical)
            XCTAssertLessThan(tactical, detail)
            XCTAssertGreaterThanOrEqual(UnitKind.tank.mapPieceWidth * tactical, 75)
            XCTAssertLessThanOrEqual(tactical, 1.32)
            XCTAssertEqual(detail / tactical, 1.25, accuracy: 0.0001)
        }
        let invalid = BattlefieldMapCamera.scale(viewport: CGSize(width: CGFloat.nan, height: CGFloat.infinity), zoom: .nan)
        XCTAssertTrue(invalid.isFinite)
        XCTAssertGreaterThan(invalid, 0)
        XCTAssertLessThanOrEqual(BattlefieldMapCamera.scale(viewport: .zero, zoom: 999), 2.64)
    }

    func testInspectorAndOrderLayoutsRespectShortAndNarrowViewports() {
        for size in [CGSize(width: 320, height: 568), CGSize(width: 440, height: 900),
                     CGSize(width: 900, height: 370), CGSize(width: 1300, height: 900)] {
            let layout = BattlefieldHUDLayout(size: size)
            XCTAssertGreaterThan(layout.inspectorSize.width, 0)
            XCTAssertGreaterThan(layout.inspectorSize.height, 0)
            XCTAssertLessThanOrEqual(layout.inspectorSize.width + 24, size.width)
            XCTAssertLessThanOrEqual(layout.inspectorSize.height + 24, size.height)
            XCTAssertEqual(layout.inlineOrders, size.width >= 680 && size.width > size.height)
        }
        XCTAssertEqual(BattlefieldHUDLayout(size: .zero).inspectorSize, .zero)
        XCTAssertEqual(BattlefieldHUDLayout(size: CGSize(width: CGFloat.nan, height: CGFloat.infinity)).inspectorSize, .zero)
    }

    func testSurfacePlotsAreDeterministicAndNeverInventTerrainRules() {
        for scenario in Scenario.campaignCatalog {
            let original = scenario.tiles
            let layout = BattlefieldMapLayout(coordinates: scenario.tiles.map(\.coordinate))
            var count = 0
            for tile in scenario.tiles {
                let plot = BattlefieldFieldPlot(tile: tile, layout: layout)
                XCTAssertEqual(plot, BattlefieldFieldPlot(tile: tile, layout: layout))
                if let plot {
                    count += 1
                    XCTAssertEqual(tile.terrain, .plains)
                    XCTAssertFalse(tile.isObjective)
                    XCTAssertTrue(plot.center.x.isFinite && plot.center.y.isFinite && plot.angle.isFinite)
                    XCTAssertGreaterThan(plot.size.width, 0)
                    XCTAssertGreaterThan(plot.size.height, 0)
                }
            }
            XCTAssertGreaterThan(count, 0)
            XCTAssertEqual(scenario.tiles, original)
        }
    }

    func testPaintedFieldEdgesStayInsideTheirDeterministicPlot() throws {
        for scenario in Scenario.campaignCatalog {
            let layout = BattlefieldMapLayout(coordinates: scenario.tiles.map(\.coordinate))
            for tile in scenario.tiles {
                guard let plot = BattlefieldFieldPlot(tile: tile, layout: layout) else { continue }
                let repeated = try XCTUnwrap(BattlefieldFieldPlot(tile: tile, layout: layout))
                XCTAssertEqual(plot.corners, repeated.corners)
                XCTAssertEqual(plot.corners.count, 4)
                let bounds = CGRect(x: -plot.size.width / 2, y: -plot.size.height / 2,
                                    width: plot.size.width, height: plot.size.height)
                for corner in plot.corners {
                    XCTAssertTrue(corner.x.isFinite && corner.y.isFinite)
                    XCTAssertTrue(bounds.contains(corner))
                }
                let twiceArea = zip(plot.corners, Array(plot.corners.dropFirst()) + [plot.corners[0]])
                    .reduce(CGFloat.zero) { $0 + $1.0.x * $1.1.y - $1.1.x * $1.0.y }
                XCTAssertGreaterThan(twiceArea, plot.size.width * plot.size.height)
            }
        }
    }

    func testRiverSurfaceAndBankDetailsStayAttachedToRealWater() {
        for scenario in Scenario.campaignCatalog {
            let original = scenario.tiles
            let layout = BattlefieldMapLayout(coordinates: original.map(\.coordinate))
            let geometry = BattlefieldRiverGeometry(tiles: original, layout: layout)
            let reversed = BattlefieldRiverGeometry(tiles: Array(original.reversed()), layout: layout)
            XCTAssertFalse(geometry.ribbons.isEmpty)
            for (ribbon, repeated) in zip(geometry.ribbons, reversed.ribbons) {
                XCTAssertEqual(ribbon.bankDetails, repeated.bankDetails)
                XCTAssertEqual(ribbon.bankDetails.count, 12)
                for lane in [CGFloat(-0.55), 0.12, 0.56] {
                    let bounds = ribbon.outline().boundingBoxOfPath.insetBy(dx: -0.1, dy: -0.1)
                    XCTAssertTrue(bounds.contains(ribbon.surfaceTrace(lane: lane, from: 0.13, to: 0.82).boundingBoxOfPath))
                }
                for detail in ribbon.bankDetails {
                    let center = ribbon.point(at: detail.fraction)
                    let normal = ribbon.normal(at: detail.fraction)
                    let dx = detail.center.x - center.x
                    let dy = detail.center.y - center.y
                    XCTAssertEqual(hypot(dx, dy), (dx * normal.x + dy * normal.y) * detail.side, accuracy: 0.0001)
                    XCTAssertGreaterThan(hypot(dx, dy), ribbon.halfWidth(at: detail.fraction) + 2)
                    XCTAssertLessThan(hypot(dx, dy), ribbon.halfWidth(at: detail.fraction) + 5.3)
                    XCTAssertGreaterThan(detail.radius, 0)
                }
            }
            let dry = original.filter { $0.terrain == .plains }
            XCTAssertTrue(BattlefieldRiverGeometry(tiles: dry, layout: layout).ribbons.isEmpty)
            XCTAssertEqual(scenario.tiles, original)
        }
    }

    func testMapDetailsStayQuietUntilInspectedOrReplayIsExplicit() {
        for focused in [false, true] {
            for selected in [false, true] {
                XCTAssertEqual(BattlefieldActionMarkerPresentation.showsTacticalDetails(focused: focused, selected: selected), focused || selected)
                XCTAssertEqual(BattlefieldActionMarkerPresentation.showsReplay(focused: focused, explicitReplay: selected), focused || selected)
            }
        }
        XCTAssertTrue(BattlefieldArtwork.resourceNames.contains("scenery-frontline"))
        for kind in BattlefieldScenery.allCases {
            XCTAssertTrue(BattlefieldArtwork.scenery(kind) === BattlefieldArtwork.scenery(kind))
        }
    }

    func testMovementMarkerKeepsTheInspectedOrderWithoutFloodingTheMap() {
        let move = MapActionHint.move(cost: 3, controlZonePenalty: 1)
        XCTAssertFalse(BattlefieldActionMarkerPresentation.showsMarker(for: move, focused: false, routeDestination: false, attackFocus: false))
        XCTAssertTrue(BattlefieldActionMarkerPresentation.showsMarker(for: move, focused: true, routeDestination: false, attackFocus: false))
        XCTAssertTrue(BattlefieldActionMarkerPresentation.showsMarker(for: move, focused: false, routeDestination: true, attackFocus: false))
        for hint in [MapActionHint.none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange(distance: 5, range: 2)] {
            XCTAssertFalse(BattlefieldActionMarkerPresentation.showsMarker(for: hint, focused: true, routeDestination: true, attackFocus: false))
        }
    }

    func testAttackFocusKeepsOnlyTheFocusedAttackMarker() {
        let attack = MapActionHint.attack(damage: 20, counterDamage: 8, willDestroy: false)
        let approach = MapActionHint.approachAttack(cost: 2, controlZonePenalty: 0)
        XCTAssertTrue(BattlefieldActionMarkerPresentation.showsMarker(for: attack, focused: true, routeDestination: false, attackFocus: true))
        XCTAssertFalse(BattlefieldActionMarkerPresentation.showsMarker(for: attack, focused: false, routeDestination: false, attackFocus: true))
        XCTAssertTrue(BattlefieldActionMarkerPresentation.showsMarker(for: approach, focused: false, routeDestination: false, attackFocus: false))
        XCTAssertFalse(BattlefieldActionMarkerPresentation.showsMarker(for: approach, focused: true, routeDestination: false, attackFocus: true))
        XCTAssertFalse(BattlefieldActionMarkerPresentation.showsMarker(for: .move(cost: 1, controlZonePenalty: 0), focused: true, routeDestination: true, attackFocus: true))
    }

    func testRoadCurvesPreserveEveryPairedConnectionWithoutDuplicates() {
        for scenario in Scenario.campaignCatalog {
            let layout = BattlefieldMapLayout(coordinates: scenario.tiles.map(\.coordinate))
            let canonical = RoadConnectionNetwork(tiles: scenario.tiles).directionsByCoordinate
            let plan = BattlefieldInfrastructure(tiles: scenario.tiles, roadConnections: canonical)
            let geometry = BattlefieldRoadGeometry(infrastructure: plan, layout: layout)
            let edgeCount = plan.directionsByCoordinate.values.reduce(0) { $0 + $1.count }
            XCTAssertEqual(geometry.segments.count * 2, edgeCount)
            let identities = geometry.segments.map { "\($0.first.id)/\($0.second.id)" }
            XCTAssertEqual(Set(identities).count, identities.count)
            for segment in geometry.segments {
                XCTAssertEqual(segment.start, layout.center(for: segment.first))
                XCTAssertEqual(segment.end, layout.center(for: segment.second))
                XCTAssertTrue(segment.first.neighbors.contains(segment.second))
                XCTAssertTrue(segment.firstControl.x.isFinite && segment.secondControl.y.isFinite)
                let bounds = layout.frame(for: segment.first).union(layout.frame(for: segment.second))
                XCTAssertTrue(bounds.contains(segment.firstControl))
                XCTAssertTrue(bounds.contains(segment.secondControl))
            }
            let reversed = BattlefieldInfrastructure(tiles: Array(scenario.tiles.reversed()), roadConnections: canonical)
            XCTAssertEqual(geometry.segments, BattlefieldRoadGeometry(infrastructure: reversed, layout: layout).segments)
        }
    }

    func testRoadGeometryRejectsUnpairedAndInvalidDirections() {
        let origin = HexCoordinate(q: 0, r: 0)
        let neighbor = origin.neighbors[0]
        let tiles = [origin, neighbor].map { TerrainTile(coordinate: $0, terrain: .road) }
        let layout = BattlefieldMapLayout(coordinates: tiles.map(\.coordinate))
        for connections in [[origin: [0]], [origin: [-1, 6, 999]], [:]] {
            let plan = BattlefieldInfrastructure(tiles: tiles, roadConnections: connections)
            XCTAssertTrue(BattlefieldRoadGeometry(infrastructure: plan, layout: layout).segments.isEmpty)
        }
    }

    func testTerrainRenderIdentityTracksOnlyActualMapInputs() {
        let scenario = Scenario.ardennesPrototype()
        let layout = BattlefieldMapLayout(coordinates: scenario.tiles.map(\.coordinate))
        let roads = RoadConnectionNetwork(tiles: scenario.tiles).directionsByCoordinate
        let original = BattlefieldTerrainRenderer(tiles: scenario.tiles, layout: layout, roadConnections: roads)
        let game = GameState(scenario: scenario)
        game.selectNextReadyUnitFromMap()
        game.waitSelectedUnit()
        XCTAssertEqual(original, BattlefieldTerrainRenderer(tiles: game.tiles, layout: layout, roadConnections: roads))
        XCTAssertNotEqual(original, BattlefieldTerrainRenderer(tiles: Array(game.tiles.dropLast()), layout: layout, roadConnections: roads))
        XCTAssertNotEqual(original, BattlefieldTerrainRenderer(tiles: game.tiles, layout: layout, roadConnections: [:]))
    }

    func testVehicleVariantsMatchHistoricalNamesWithoutChangingArchetypes() throws {
        let scenario = Scenario.ardennesPrototype()
        let originals = scenario.units
        let cases: [(String, BattlefieldVehicleVariant, UnitKind)] = [
            ("M10坦克歼击营", .tankDestroyer, .recon), ("M7牧师炮兵", .priest, .artillery),
            ("虎式重装连", .tiger, .tank), ("豹式预备营", .panther, .tank)
        ]
        for (name, expected, kind) in cases {
            let unit = try XCTUnwrap(scenario.units.first { $0.name == name })
            XCTAssertEqual(BattlefieldVehicleVariant.matching(unit), expected)
            XCTAssertEqual(unit.kind, kind)
            var spent = unit
            spent.hasMoved = true
            spent.hasAttacked = true
            XCTAssertEqual(BattlefieldVehicleVariant.matching(spent), expected)
        }
        XCTAssertEqual(scenario.units, originals)
    }

    func testVehicleVariantsRejectWrongFactionAndKind() {
        let coordinate = HexCoordinate(q: 0, r: 0)
        for unit in [BattleUnit(name: "M10", kind: .recon, faction: .axis, position: coordinate, hp: 30),
                     BattleUnit(name: "M7", kind: .infantry, faction: .allies, position: coordinate, hp: 30),
                     BattleUnit(name: "虎式", kind: .tank, faction: .allies, position: coordinate, hp: 30),
                     BattleUnit(name: "豹式", kind: .recon, faction: .axis, position: coordinate, hp: 30),
                     BattleUnit(name: "装甲侦察营", kind: .recon, faction: .axis, position: coordinate, hp: 30)] {
            XCTAssertNil(BattlefieldVehicleVariant.matching(unit))
        }
    }

    func testTownRiverContinuationsRequireOppositeWaterNeighbors() {
        let center = HexCoordinate(q: 0, r: 0)
        let river = [center.neighbors[2], center.neighbors[5]].map { TerrainTile(coordinate: $0, terrain: .river) }
        for terrain in [TerrainKind.city, .road, .plains, .mountain] {
            let tiles = river + [TerrainTile(coordinate: center, terrain: terrain)]
            let layout = BattlefieldMapLayout(coordinates: tiles.map(\.coordinate))
            let geometry = BattlefieldRiverGeometry(tiles: tiles, layout: layout)
            XCTAssertEqual(geometry.townContinuations.contains(center), terrain == .city || terrain == .road)
        }
        let elbow = [TerrainTile(coordinate: center, terrain: .city),
                     TerrainTile(coordinate: center.neighbors[0], terrain: .river),
                     TerrainTile(coordinate: center.neighbors[1], terrain: .river)]
        let layout = BattlefieldMapLayout(coordinates: elbow.map(\.coordinate))
        XCTAssertTrue(BattlefieldRiverGeometry(tiles: elbow, layout: layout).townContinuations.isEmpty)
        let campaign = Scenario.ardennesPrototype()
        let campaignLayout = BattlefieldMapLayout(coordinates: campaign.tiles.map(\.coordinate))
        XCTAssertTrue(BattlefieldRiverGeometry(tiles: campaign.tiles, layout: campaignLayout).townContinuations.contains(HexCoordinate(q: 6, r: 9)))
    }

    func testBridgeRequiresOpposingRealRoadsAndPreservesTerrain() {
        let center = HexCoordinate(q: 0, r: 0)
        let tiles = [TerrainTile(coordinate: center, terrain: .river),
                     TerrainTile(coordinate: center.neighbors[0], terrain: .road),
                     TerrainTile(coordinate: center.neighbors[3], terrain: .city)]
        let before = tiles
        let first = BattlefieldInfrastructure(tiles: tiles, roadConnections: [:])
        XCTAssertEqual(first.bridges, [BattlefieldBridge(coordinate: center, direction: 0)])
        XCTAssertEqual(first.directionsByCoordinate[center], [0, 3])
        XCTAssertEqual(first.directionsByCoordinate[center.neighbors[0]], [3])
        XCTAssertEqual(first.directionsByCoordinate[center.neighbors[3]], [0])
        XCTAssertEqual(tiles, before)
        for partial in [Array(tiles.prefix(2)), [tiles[0], tiles[1], TerrainTile(coordinate: center.neighbors[1], terrain: .road)]] {
            XCTAssertTrue(BattlefieldInfrastructure(tiles: partial, roadConnections: [:]).bridges.isEmpty)
        }
        let reversed = BattlefieldInfrastructure(tiles: Array(tiles.reversed()), roadConnections: [:])
        XCTAssertEqual(first.bridges, reversed.bridges)
        XCTAssertEqual(first.directionsByCoordinate, reversed.directionsByCoordinate)
    }

    func testTownStreetsKeepCanonicalRoadsAndPairedConnections() {
        for scenario in Scenario.campaignCatalog {
            let canonical = RoadConnectionNetwork(tiles: scenario.tiles).directionsByCoordinate
            let plan = BattlefieldInfrastructure(tiles: scenario.tiles, roadConnections: canonical)
            for (coordinate, directions) in canonical {
                XCTAssertTrue(Set(directions).isSubset(of: Set(plan.directionsByCoordinate[coordinate] ?? [])))
            }
            for (coordinate, directions) in plan.directionsByCoordinate {
                for direction in directions {
                    let neighbor = coordinate.neighbors[direction]
                    XCTAssertTrue(plan.directionsByCoordinate[neighbor]?.contains((direction + 3) % 6) == true)
                    XCTAssertTrue(scenario.tiles.contains { $0.coordinate == neighbor })
                }
            }
            let reversed = BattlefieldInfrastructure(tiles: Array(scenario.tiles.reversed()), roadConnections: canonical)
            XCTAssertEqual(plan.directionsByCoordinate, reversed.directionsByCoordinate)
            XCTAssertEqual(plan.bridges, reversed.bridges)
        }
    }

    func testSceneryPlacementsAreDeterministicAndVaried() throws {
        let scenario = Scenario.ardennesPrototype()
        let tiles = scenario.tiles
        let layout = BattlefieldMapLayout(coordinates: tiles.map(\.coordinate))
        var forestVariants = Set<Int>()
        for tile in tiles {
            let first = BattlefieldSceneryPlacement(tile: tile, layout: layout)
            XCTAssertEqual(first, BattlefieldSceneryPlacement(tile: tile, layout: layout))
            if let first {
                XCTAssertTrue(first.rect.contains(layout.center(for: tile.coordinate)))
                XCTAssertTrue(first.rect.minX.isFinite && first.rect.minY.isFinite)
                XCTAssertGreaterThan(first.rect.width, 0)
                if tile.terrain == .forest { forestVariants.insert(first.kind.rawValue) }
            } else {
                XCTAssertFalse(tile.terrain == .forest || tile.terrain == .city || tile.terrain == .mountain)
            }
        }
        XCTAssertEqual(forestVariants.count, 3)
        XCTAssertEqual(scenario.tiles, tiles)
    }

    func testViewportSeparatesWideShortPhonesFromTablets() {
        let phonePortrait = BattlefieldViewport(size: CGSize(width: 440, height: 900))
        XCTAssertTrue(phonePortrait.compactControls)
        XCTAssertFalse(phonePortrait.isShallow)
        XCTAssertFalse(phonePortrait.showsOverviewByDefault)
        let phoneLandscape = BattlefieldViewport(size: CGSize(width: 900, height: 370))
        XCTAssertTrue(phoneLandscape.compactControls)
        XCTAssertTrue(phoneLandscape.isShallow)
        XCTAssertFalse(phoneLandscape.showsOverviewByDefault)
        XCTAssertEqual(phoneLandscape.commandBarHeight, 44)
        for size in [CGSize(width: 1024, height: 1300), CGSize(width: 1300, height: 900)] {
            let tablet = BattlefieldViewport(size: size)
            XCTAssertFalse(tablet.compactControls)
            XCTAssertFalse(tablet.isShallow)
            XCTAssertTrue(tablet.showsOverviewByDefault)
            XCTAssertEqual(tablet.commandBarHeight, 54)
        }
        XCTAssertFalse(BattlefieldViewport(size: CGSize(width: CGFloat.infinity, height: CGFloat.nan)).showsOverviewByDefault)
    }

    func testFrontlineFocusUsesClosestLivingPairDeterministically() {
        for scenario in Scenario.campaignCatalog {
            let layout = BattlefieldMapLayout(coordinates: scenario.tiles.map(\.coordinate))
            let units = scenario.units
            let point = layout.frontlineFocusPoint(units: units, fallback: scenario.initialFocus, scale: 1)
            XCTAssertEqual(point, layout.frontlineFocusPoint(units: Array(units.reversed()), fallback: scenario.initialFocus, scale: 1))
            var candidates: [(distance: Int, point: CGPoint)] = []
            for allied in units where allied.faction == .allies && !allied.isDestroyed {
                for axis in units where axis.faction == .axis && !axis.isDestroyed {
                    candidates.append((allied.position.distance(to: axis.position), layout.combatFocusPoint(
                        attacker: allied.position, defender: axis.position, scale: 1
                    )))
                }
            }
            let minimum = candidates.map(\.distance).min()
            XCTAssertTrue(candidates.contains { $0.distance == minimum && $0.point == point })
            XCTAssertTrue(CGRect(origin: .zero, size: layout.size).contains(point))
            XCTAssertEqual(scenario.units, units)
        }
    }

    func testFrontlineFocusIgnoresDestroyedUnitsAndFallsBackSafely() {
        let allied = BattleUnit(name: "A", kind: .tank, faction: .allies, position: HexCoordinate(q: 0, r: 0), hp: 40)
        let destroyed = BattleUnit(name: "X", kind: .tank, faction: .axis, position: HexCoordinate(q: 1, r: 0), hp: 0)
        let enemy = BattleUnit(name: "B", kind: .tank, faction: .axis, position: HexCoordinate(q: 4, r: 0), hp: 40)
        let fallback = HexCoordinate(q: 2, r: 0)
        let layout = BattlefieldMapLayout(coordinates: [allied.position, destroyed.position, enemy.position, fallback])
        XCTAssertEqual(layout.frontlineFocusPoint(units: [allied, destroyed, enemy], fallback: fallback, scale: 1.25),
                       layout.combatFocusPoint(attacker: allied.position, defender: enemy.position, scale: 1.25))
        for units in [[], [allied], [enemy], [allied, destroyed]] {
            XCTAssertEqual(layout.frontlineFocusPoint(units: units, fallback: fallback, scale: .nan), layout.center(for: fallback))
        }
    }

    func testOpeningCameraIdentitySurvivesSelectionButChangesOnCampaignReload() throws {
        let game = GameState()
        let openingID = try XCTUnwrap(game.scenario.units.first?.id)
        let allied = try XCTUnwrap(game.units.first { $0.faction == .allies })
        game.select(unitID: allied.id)
        game.focus(coordinate: HexCoordinate(q: 9, r: 6))
        XCTAssertEqual(game.scenario.units.first?.id, openingID)
        let scenarioID = game.scenario.id
        game.restart()
        XCTAssertEqual(game.scenario.id, scenarioID)
        XCTAssertNotEqual(game.scenario.units.first?.id, openingID)
        XCTAssertNil(game.selectedUnitID)
        XCTAssertEqual(game.focusedCoordinate, game.scenario.initialFocus)
        XCTAssertNil(game.latestCombatResult)
    }

    func testOverviewProjectionRoundTripsEveryCampaignAndNegativeCoordinate() {
        let sets = Scenario.campaignCatalog.map { $0.tiles.map(\.coordinate) } + [[HexCoordinate(q: -9, r: -7), HexCoordinate(q: 2, r: 4)]]
        for coordinates in sets {
            for size in [CGSize(width: 170, height: 74), CGSize(width: 96, height: 50)] {
                let projection = BattlefieldOverviewProjection(coordinates: coordinates, size: size)
                XCTAssertGreaterThan(projection.scale, 0)
                XCTAssertTrue(CGRect(origin: .zero, size: size).contains(projection.contentRect))
                for coordinate in coordinates {
                    let point = projection.point(for: coordinate)
                    XCTAssertEqual(projection.coordinate(at: point), coordinate)
                }
            }
        }
    }

    func testOverviewProjectionRejectsPaddingEmptyAndInvalidInput() {
        let coordinates = Scenario.ardennesPrototype().tiles.map(\.coordinate)
        let projection = BattlefieldOverviewProjection(coordinates: coordinates, size: CGSize(width: 170, height: 74))
        XCTAssertNil(projection.coordinate(at: .zero))
        XCTAssertNil(projection.coordinate(at: CGPoint(x: -1, y: 20)))
        XCTAssertNil(projection.coordinate(at: CGPoint(x: CGFloat.nan, y: 20)))
        XCTAssertNil(BattlefieldOverviewProjection(coordinates: [], size: CGSize(width: 170, height: 74)).coordinate(at: CGPoint(x: 40, y: 30)))
        for size in [CGSize.zero, CGSize(width: -1, height: 20), CGSize(width: CGFloat.nan, height: 20),
                     CGSize(width: 100, height: CGFloat.infinity)] {
            let invalid = BattlefieldOverviewProjection(coordinates: coordinates, size: size)
            XCTAssertEqual(invalid.scale, 0)
            XCTAssertNil(invalid.coordinate(at: CGPoint(x: 10, y: 10)))
        }
    }

    func testOverviewRejectsEmptyHexCornersAndSparseMapGaps() {
        let first = HexCoordinate(q: -2, r: -3)
        let last = HexCoordinate(q: 4, r: 5)
        let projection = BattlefieldOverviewProjection(coordinates: [first, last, first], size: CGSize(width: 170, height: 74))
        XCTAssertEqual(projection.coordinates.count, 2)
        let frame = projection.layout.frame(for: first)
        let emptyCorner = CGPoint(x: projection.contentRect.minX + (frame.minX + 1) * projection.scale,
                                  y: projection.contentRect.minY + (frame.minY + 1) * projection.scale)
        XCTAssertTrue(projection.contentRect.contains(emptyCorner))
        XCTAssertNil(projection.coordinate(at: emptyCorner))
        XCTAssertNil(projection.coordinate(at: CGPoint(x: projection.contentRect.midX, y: projection.contentRect.midY)))
        XCTAssertEqual(projection.coordinate(at: projection.point(for: first)), first)
        XCTAssertEqual(projection.coordinate(at: projection.point(for: last)), last)
    }

    func testRiverNeighborsShareExactJunctionWidthAndTangent() {
        for scenario in Scenario.campaignCatalog {
            let layout = BattlefieldMapLayout(coordinates: scenario.tiles.map(\.coordinate))
            let coordinates = Set(scenario.tiles.filter { $0.terrain == .river }.map(\.coordinate))
            let geometry = BattlefieldRiverGeometry(tiles: scenario.tiles, layout: layout)
            for coordinate in coordinates {
                for neighbor in coordinate.neighbors where coordinates.contains(neighbor) {
                    let junction = BattlefieldRiverGeometry.junction(from: coordinate, to: neighbor, layout: layout)
                    XCTAssertEqual(junction, BattlefieldRiverGeometry.junction(from: neighbor, to: coordinate, layout: layout))
                    XCTAssertGreaterThan(junction.halfWidth, 0)
                    var normals: [CGPoint] = []
                    for ribbon in geometry.ribbons {
                        if ribbon.start == junction.point {
                            normals.append(ribbon.normal(at: 0))
                            XCTAssertEqual(ribbon.startHalfWidth, junction.halfWidth)
                        }
                        if ribbon.end == junction.point {
                            normals.append(ribbon.normal(at: 1))
                            XCTAssertEqual(ribbon.endHalfWidth, junction.halfWidth)
                        }
                    }
                    XCTAssertEqual(normals.count, 2, "\(coordinate.id) / \(neighbor.id)")
                    if normals.count == 2 {
                        XCTAssertEqual(abs(normals[0].x * normals[1].x + normals[0].y * normals[1].y), 1, accuracy: 0.0001)
                    }
                }
            }
        }
    }

    func testRiverRibbonsAreFiniteStableAndCoverBranchesEndpointsAndIsolatedTiles() {
        let branch = [HexCoordinate(q: 0, r: 0), HexCoordinate(q: 1, r: 0), HexCoordinate(q: 0, r: 1),
                      HexCoordinate(q: -1, r: 0), HexCoordinate(q: 8, r: 8)].map { TerrainTile(coordinate: $0, terrain: .river) }
        let sets = Scenario.campaignCatalog.map(\.tiles) + [branch, []]
        for tiles in sets {
            let layout = BattlefieldMapLayout(coordinates: tiles.map(\.coordinate))
            let first = BattlefieldRiverGeometry(tiles: tiles, layout: layout)
            let second = BattlefieldRiverGeometry(tiles: Array(tiles.reversed()), layout: layout)
            XCTAssertEqual(first.ribbons.count, second.ribbons.count)
            for (left, right) in zip(first.ribbons, second.ribbons) {
                XCTAssertEqual(left.start, right.start)
                XCTAssertEqual(left.end, right.end)
                let outline = left.outline().boundingBoxOfPath
                XCTAssertFalse(outline.isEmpty)
                XCTAssertTrue(outline.minX.isFinite && outline.minY.isFinite && outline.maxX.isFinite && outline.maxY.isFinite)
                XCTAssertTrue(left.outline(expansion: 5).boundingBoxOfPath.contains(outline))
                for fraction in [CGFloat(0), 0.2, 0.5, 0.8, 1] {
                    let point = left.point(at: fraction)
                    XCTAssertTrue(point.x.isFinite && point.y.isFinite)
                    XCTAssertGreaterThan(left.halfWidth(at: fraction), 0)
                    let normal = left.normal(at: fraction)
                    XCTAssertEqual(hypot(normal.x, normal.y), 1, accuracy: 0.0001)
                }
            }
        }
    }

    func testOverviewNavigationOnlyFocusesWithoutExecutingCommands() throws {
        let game = GameState()
        let allied = try XCTUnwrap(game.units.first { $0.faction == .allies })
        game.select(unitID: allied.id)
        let units = game.scenario.units
        let tiles = game.tiles
        let points = game.commandPoints
        let log = game.battleLog
        let turn = game.turn
        let faction = game.activeFaction
        let projection = BattlefieldOverviewProjection(coordinates: tiles.map(\.coordinate), size: CGSize(width: 170, height: 74))
        for tile in [tiles.first, tiles.last, game.tile(at: HexCoordinate(q: 9, r: 6))].compactMap({ $0 }) {
            let coordinate = try XCTUnwrap(projection.coordinate(at: projection.point(for: tile.coordinate)))
            game.focus(coordinate: coordinate)
            XCTAssertEqual(game.focusedCoordinate, tile.coordinate)
            XCTAssertEqual(game.selectedUnitID, allied.id)
            XCTAssertEqual(game.scenario.units, units)
            XCTAssertEqual(game.tiles, tiles)
            XCTAssertEqual(game.commandPoints, points)
            XCTAssertEqual(game.battleLog, log)
            XCTAssertEqual(game.turn, turn)
            XCTAssertEqual(game.activeFaction, faction)
            XCTAssertNil(game.latestCombatResult)
        }
    }

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
        XCTAssertEqual(BattlefieldArtwork.groundResourceName, "ground-frontline")
        XCTAssertTrue(ground === BattlefieldArtwork.ground)
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
        for variant in BattlefieldVehicleVariant.allCases {
            let first = try XCTUnwrap(BattlefieldArtwork.vehicle(variant))
            XCTAssertTrue(first === BattlefieldArtwork.vehicle(variant))
            images.append(first)
        }
        XCTAssertEqual(images.count, 20)
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
                XCTAssertEqual(value.moveTitle, hasMoved ? "已移动" : "可移动")
                XCTAssertEqual(value.attackTitle, hasAttacked ? "已攻击" : "可攻击")
            }
        }
    }

    func testEdgeToolsKeepFullAccessibilityNamesAndShortCaptions() {
        // VisualUITests tap these exact labels; captions are display-only.
        XCTAssertEqual(BattlefieldEdgeTool.allCases.map(\.title),
                       ["编队与据点定位", "战术支援", "返回交战前线", "下一支待命部队"])
        XCTAssertEqual(Set(BattlefieldEdgeTool.allCases.map(\.caption)).count, BattlefieldEdgeTool.allCases.count)
        XCTAssertEqual(Set(BattlefieldEdgeTool.allCases.map(\.icon)).count, BattlefieldEdgeTool.allCases.count)
        for tool in BattlefieldEdgeTool.allCases {
            XCTAssertFalse(tool.caption.isEmpty)
            XCTAssertLessThanOrEqual(tool.caption.count, 3)
            XCTAssertNotEqual(tool.caption, tool.title)
        }
        XCTAssertEqual(BattlefieldEdgeTool.roster.drawer, .roster)
        XCTAssertEqual(BattlefieldEdgeTool.support.drawer, .support)
        XCTAssertNil(BattlefieldEdgeTool.frontline.drawer)
        XCTAssertNil(BattlefieldEdgeTool.nextReady.drawer)
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
