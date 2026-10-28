import SwiftUI
import UIKit

private struct CombatResolutionSteadyStateKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var combatResolutionSteadyState: Bool {
        get { self[CombatResolutionSteadyStateKey.self] }
        set { self[CombatResolutionSteadyStateKey.self] = newValue }
    }
}

struct HexMapView: View {
    @EnvironmentObject private var game: GameState
    let scaleMultiplier: CGFloat
    let viewportSize: CGSize

    private let tileWidth = BattlefieldMapLayout.tileSize.width
    private let tileHeight = BattlefieldMapLayout.tileSize.height

    var body: some View {
        let selected = game.selectedUnit
        let actionHints = game.mapActionHints()
        let supplyLine = selected.map { game.supplyLineTiles(for: $0) } ?? []
        let enemyControlZones = selected.map { game.enemyControlZoneTiles(for: $0.faction) } ?? []
        let threatenedReachableTiles = selected.map { game.threatenedReachableTiles(for: $0) } ?? []
        let attackCoverage = selected.map { game.attackCoverageTiles(for: $0) } ?? []
        let postMoveAttackTargets = Set(game.focusedPostMoveAttackOpportunities.map(\.position))
        let attackPositions = Set(game.focusedAttackPositionRoutes.map(\.destination))
        let focusedRoute = game.focusedMovementRoute ?? game.focusedAttackPositionRoute
        let focusedRouteCoordinates = Set(focusedRoute?.coordinates ?? [])
        let focusedRouteSteps = Dictionary(uniqueKeysWithValues: game.focusedRouteStepPreviews.map { ($0.coordinate, $0) })
        let focusedFireExposure = game.focusedFireExposurePreview
        let guidedObjectiveCoordinate = game.guidedObjectiveCoordinate
        let latestCaptureCoordinate = game.latestObjectiveCaptureResult?.coordinate
        let enemyIntentTargets = Set(game.visibleEnemyThreatIntentPreviews.map(\.targetCoordinate))
        let countermeasureMarkersByCoordinate = Dictionary(
            grouping: game.focusedEnemyThreatCountermeasureMapMarkers,
            by: \.coordinate
        )
        let objectivePressureMarkersByCoordinate = Dictionary(
            grouping: game.focusedBattlefieldSituationObjectivePressureMapMarkers,
            by: \.coordinate
        )
        let aiPhaseMarkersByCoordinate = Dictionary(
            grouping: game.latestAIPhaseMapMarkers,
            by: \.coordinate
        )
        let focusedAIPhaseMarkersByCoordinate = Dictionary(
            grouping: game.focusedAIPhaseMapMarkers,
            by: \.coordinate
        )
        let battlefieldSituationResponseMarker = game.battlefieldSituationResponseMapMarker
        let roadConnectionDirectionsByCoordinate = RoadConnectionNetwork(tiles: game.tiles).directionsByCoordinate
        let layout = BattlefieldMapLayout(coordinates: game.tiles.map(\.coordinate))
        let contentWidth = layout.size.width
        let contentHeight = layout.size.height
        let resolvedScale = BattlefieldMapCamera.scale(viewport: viewportSize, zoom: scaleMultiplier)
        let scaledSize = layout.scaledSize(resolvedScale)
        let mapTiles: [TerrainTile] = Array(game.tiles)

        ZStack(alignment: .topLeading) {
            BattlefieldTerrainRenderer(tiles: mapTiles, layout: layout, roadConnections: roadConnectionDirectionsByCoordinate)
                .equatable()
                .scaleEffect(resolvedScale, anchor: .topLeading)
                .frame(width: scaledSize.width, height: scaledSize.height, alignment: .topLeading)

            BattlefieldPositionedLayout(size: scaledSize) {
                Color.clear
                    .frame(width: 1, height: 1)
                    .layoutValue(key: BattlefieldPositionKey.self, value: layout.frontlineFocusPoint(
                        units: game.units, fallback: game.scenario.initialFocus, scale: resolvedScale
                    ))
                    .id("battlefield-frontline")
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                ForEach(mapTiles, id: \.coordinate.id) { tile in
                    let unit = game.unit(at: tile.coordinate)
                    let tileIsSelected = selected?.position == tile.coordinate
                    let tileIsFocused = game.focusedCoordinate == tile.coordinate
                    let supplyLineConnectionDirections = supplyLine.contains(tile.coordinate)
                        ? tile.coordinate.neighbors.enumerated().compactMap { index, coordinate in
                            supplyLine.contains(coordinate) ? index : nil
                        }
                        : []
                    HexTileView(
                        tile: tile,
                        supplyLineConnectionDirections: supplyLineConnectionDirections,
                        unit: unit,
                        isSelected: tileIsSelected,
                        isFocused: tileIsFocused,
                        isAttackFocusMode: isAttackFocusMode,
                        actionHint: actionHints[tile.coordinate] ?? .none,
                        isMovementRoute: focusedRouteCoordinates.contains(tile.coordinate),
                        isRouteDestination: focusedRoute?.destination == tile.coordinate,
                        routeStepPreview: focusedRouteSteps[tile.coordinate],
                        isSupplyLine: supplyLine.contains(tile.coordinate),
                        isAttackCoverage: attackCoverage.contains(tile.coordinate),
                        isPostMoveAttackTarget: postMoveAttackTargets.contains(tile.coordinate),
                        isAttackPosition: attackPositions.contains(tile.coordinate),
                        isEnemyControlZone: enemyControlZones.contains(tile.coordinate),
                        isThreatenedMoveTile: threatenedReachableTiles.contains(tile.coordinate),
                        fireExposurePreview: focusedFireExposure?.coordinate == tile.coordinate ? focusedFireExposure : nil,
                        isGuidedObjective: guidedObjectiveCoordinate == tile.coordinate,
                        isLatestObjectiveCapture: latestCaptureCoordinate == tile.coordinate,
                        isEnemyThreatIntentTarget: enemyIntentTargets.contains(tile.coordinate),
                        enemyThreatCountermeasureMarkers: countermeasureMarkersByCoordinate[tile.coordinate] ?? [],
                        objectivePressureMarkers: objectivePressureMarkersByCoordinate[tile.coordinate] ?? [],
                        aiPhaseMapMarkers: aiPhaseMarkersByCoordinate[tile.coordinate] ?? [],
                        focusedAIPhaseMapMarkers: focusedAIPhaseMarkersByCoordinate[tile.coordinate] ?? [],
                        battlefieldSituationResponseMarker: battlefieldSituationResponseMarker?.coordinate == tile.coordinate ? battlefieldSituationResponseMarker : nil
                    )
                    .frame(width: tileWidth, height: tileHeight)
                    .overlay(
                        HexInputReader(
                            hitShape: Hexagon().path(in: CGRect(origin: .zero, size: CGSize(width: tileWidth, height: tileHeight))),
                            directTouchAction: {
                                game.handleTap(on: tile.coordinate)
                            },
                            primaryAction: {
                                game.handlePrimaryAction(on: tile.coordinate)
                            },
                            secondaryAction: {
                                game.handleSecondaryAction(on: tile.coordinate)
                            }
                        )
                    )
                    .scaleEffect(resolvedScale)
                    .frame(width: tileWidth * resolvedScale, height: tileHeight * resolvedScale)
                    .layoutValue(key: BattlefieldPositionKey.self, value: layout.scaledCenter(for: tile.coordinate, scale: resolvedScale))
                    .id(tile.coordinate.id)
                    .zIndex(
                        tilePresentationLayer(
                            hasUnit: unit != nil,
                            isSelected: tileIsSelected,
                            isFocused: tileIsFocused
                        )
                    )
                }

                if let result = game.latestCombatResult {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .layoutValue(key: BattlefieldPositionKey.self, value: layout.combatFocusPoint(
                            attacker: result.attackerCoordinate, defender: result.defenderCoordinate, scale: resolvedScale
                        ))
                        .id("combat-\(result.id)")
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }

            if isAttackFocusMode,
               let attackerCoordinate = selected?.position,
               let targetCoordinate = game.focusedCoordinate {
                EngagementAxisOverlay(
                    start: layout.center(for: attackerCoordinate),
                    end: layout.center(for: targetCoordinate)
                )
                .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
                .scaleEffect(resolvedScale, anchor: .topLeading)
                .frame(width: scaledSize.width, height: scaledSize.height, alignment: .topLeading)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .zIndex(10)
            }

            if let combatResult = game.latestCombatResult {
                CombatResolutionOverlay(
                    summary: combatResult,
                    attackerPoint: layout.center(for: combatResult.attackerCoordinate),
                    defenderPoint: layout.center(for: combatResult.defenderCoordinate)
                )
                .id(combatResult.id)
                .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
                .scaleEffect(resolvedScale, anchor: .topLeading)
                .frame(width: scaledSize.width, height: scaledSize.height, alignment: .topLeading)
                .allowsHitTesting(false)
                .zIndex(20)
            }
        }
        .frame(width: scaledSize.width, height: scaledSize.height, alignment: .topLeading)
    }

    private func tilePresentationLayer(
        hasUnit: Bool,
        isSelected: Bool,
        isFocused: Bool
    ) -> Double {
        if isSelected { return 3 }
        if hasUnit && isFocused { return 2.5 }
        if hasUnit { return 2 }
        if isFocused { return 1 }
        return 0
    }

    private var isAttackFocusMode: Bool {
        guard let preview = game.focusedCommandPreview else { return false }
        if case .attack = preview { return true }
        return false
    }
}

private struct BattlefieldPositionKey: LayoutValueKey {
    static let defaultValue = CGPoint.zero
}

/// Real child frames let ScrollViewReader resolve both axes without a full-map position wrapper.
private struct BattlefieldPositionedLayout: Layout {
    let size: CGSize

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize { size }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let point = subview[BattlefieldPositionKey.self]
            let childSize = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                          anchor: .center, proposal: ProposedViewSize(childSize))
        }
    }
}
