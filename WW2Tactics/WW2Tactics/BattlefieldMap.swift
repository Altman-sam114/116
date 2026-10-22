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
    let viewportHeight: CGFloat

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
        let fillScale = min(1.25, max(0.72, viewportHeight / contentHeight))
        let resolvedScale = fillScale * scaleMultiplier
        let mapTiles: [TerrainTile] = Array(game.tiles)

        ZStack(alignment: .topLeading) {
            BattlefieldTerrainRenderer(tiles: mapTiles, layout: layout, roadConnections: roadConnectionDirectionsByCoordinate)

            ForEach(mapTiles, id: \.coordinate.id) { tile in
                let point = layout.center(for: tile.coordinate)
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
                .id(tile.coordinate.id)
                .position(x: point.x, y: point.y)
                .zIndex(
                    tilePresentationLayer(
                        hasUnit: unit != nil,
                        isSelected: tileIsSelected,
                        isFocused: tileIsFocused
                    )
                )
            }

            if isAttackFocusMode,
               let attackerCoordinate = selected?.position,
               let targetCoordinate = game.focusedCoordinate {
                EngagementAxisOverlay(
                    start: layout.center(for: attackerCoordinate),
                    end: layout.center(for: targetCoordinate)
                )
                .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
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
                .allowsHitTesting(false)
                .zIndex(20)
            }
        }
        .frame(width: contentWidth, height: contentHeight)
        .scaleEffect(resolvedScale, anchor: .topLeading)
        .frame(
            width: contentWidth * resolvedScale,
            height: contentHeight * resolvedScale,
            alignment: .topLeading
        )
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

enum HexTileTopOverlayChip: String, Identifiable {
    case countermeasure
    case objectivePressure
    case situationResponse
    case enemyThreatIntent
    case fireRisk
    case latestCapture
    case guidedObjective

    var id: String { rawValue }

    /// Lower sortOrder is shown first in the top stack (higher visual priority).
    var sortOrder: Int {
        switch self {
        case .countermeasure: return 0
        case .objectivePressure: return 1
        case .situationResponse: return 2
        case .enemyThreatIntent: return 3
        case .fireRisk: return 4
        case .latestCapture: return 5
        case .guidedObjective: return 6
        }
    }
}

enum HexTileBottomOverlayChip: String, Identifiable {
    case aiPhase
    case attackPosition

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .aiPhase: return 0
        case .attackPosition: return 1
        }
    }
}

struct HexTileOverflowChip: View {
    let count: Int

    var body: some View {
        Text("+\(count)")
            .font(.system(size: 7, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.62), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct HexTileView: View {
    let tile: TerrainTile
    let supplyLineConnectionDirections: [Int]
    let unit: BattleUnit?
    let isSelected: Bool
    let isFocused: Bool
    let isAttackFocusMode: Bool
    let actionHint: MapActionHint
    let isMovementRoute: Bool
    let isRouteDestination: Bool
    let routeStepPreview: RouteStepPreview?
    let isSupplyLine: Bool
    let isAttackCoverage: Bool
    let isPostMoveAttackTarget: Bool
    let isAttackPosition: Bool
    let isEnemyControlZone: Bool
    let isThreatenedMoveTile: Bool
    let fireExposurePreview: PostMoveFireExposurePreview?
    let isGuidedObjective: Bool
    let isLatestObjectiveCapture: Bool
    let isEnemyThreatIntentTarget: Bool
    let enemyThreatCountermeasureMarkers: [EnemyThreatCountermeasureMapMarker]
    let objectivePressureMarkers: [BattlefieldSituationObjectivePressureMapMarker]
    let aiPhaseMapMarkers: [AIPhaseMapMarker]
    let focusedAIPhaseMapMarkers: [AIPhaseMapMarker]
    let battlefieldSituationResponseMarker: BattlefieldSituationResponseMapMarker?

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color.clear)
                .overlay(Hexagon().stroke(borderColor, lineWidth: borderWidth))

            if let owner = tile.owner {
                Hexagon()
                    .fill(owner.accentColor.opacity(tile.isObjective ? 0.10 : 0.035))
                    .overlay(
                        Hexagon()
                            .stroke(owner.accentColor.opacity(0.10), lineWidth: 0.8)
                    )
            }

            // GoG3-style soft range tinting: threatened / control-zone tiles
            // read as a translucent wash instead of hard red outlines.
            if !isAttackFocusMode {
                if isThreatenedMoveTile {
                    Hexagon().fill(Color.red.opacity(0.10))
                } else if isEnemyControlZone {
                    Hexagon().fill(Color.red.opacity(0.06))
                }
                if actionHint.isMove {
                    Hexagon().fill(Color.cyan.opacity(0.10))
                }
            }

            if isSupplyLine && !isAttackFocusMode {
                SupplyLineMarker(connectionDirections: supplyLineConnectionDirections)
            }

            if isMovementRoute && !isAttackFocusMode {
                MovementRouteMarker(step: routeStepPreview, isDestination: isRouteDestination)
            }

            // Unified top stack: focus / situation chips with overflow collapse.
            if !isAttackFocusMode && (!visibleTopOverlayChips.isEmpty || topOverlayOverflowCount > 0) {
                VStack(spacing: 2) {
                    ForEach(visibleTopOverlayChips) { chip in
                        topOverlayChipView(chip)
                    }
                    if topOverlayOverflowCount > 0 {
                        HexTileOverflowChip(count: topOverlayOverflowCount)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 4)
                .padding(.horizontal, 4)
            }

            // Unified bottom stack: AI replay / attack position with overflow collapse.
            if !isAttackFocusMode && (!visibleBottomOverlayChips.isEmpty || bottomOverlayOverflowCount > 0) {
                VStack(spacing: 2) {
                    if bottomOverlayOverflowCount > 0 {
                        HexTileOverflowChip(count: bottomOverlayOverflowCount)
                    }
                    ForEach(visibleBottomOverlayChips) { chip in
                        bottomOverlayChipView(chip)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 5)
                .padding(.horizontal, 4)
            }

            // Attack coverage reads from the soft orange border alone; the
            // per-tile scope chip repeated the same signal on every enemy hex.

            if isPostMoveAttackTarget && !isAttackFocusMode {
                PostMoveAttackMarker()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }

            // Threatened / control-zone tiles rely on the red hex wash alone —
            // per-tile "!" and triangle chips doubled the same signal.

            if shouldShowActionMarker {
                ActionMarker(actionHint: actionHint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 5)
                    .padding(.trailing, 8)
            }

            if shouldShowUnavailableTargetMarker {
                UnavailableTargetMarker(actionHint: actionHint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 5)
                    .padding(.trailing, 8)
            }

            if isSelected && unit != nil {
                SelectedUnitGroundHalo()
                    .frame(width: 58, height: 24)
                    .offset(y: 13)
            }

            VStack(spacing: 3) {
                HStack(alignment: .top, spacing: 3) {
                    if tile.isObjective {
                        ObjectiveFlagMarker(owner: tile.owner)
                        if let objectiveName = tile.objectiveName, unit != nil {
                            ObjectiveNamePlate(
                                name: objectiveName,
                                owner: tile.owner,
                                compact: true
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 1)
                        }
                    } else if isFocused && unit == nil {
                        TerrainCodeBadge(code: tile.terrain.code)
                    }
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                if let unit {
                    UnitCounter(unit: unit)
                        .offset(y: isSelected ? -3 : 0)
                        .shadow(
                            color: isSelected ? BattlefieldTheme.selectedPiece.opacity(0.34) : .clear,
                            radius: isSelected ? 4 : 0,
                            y: isSelected ? 4 : 0
                        )
                } else if let objectiveName = tile.objectiveName {
                    ObjectiveNamePlate(name: objectiveName, owner: tile.owner)
                } else {
                    Spacer(minLength: 32)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            if let reticleColor {
                TacticalCornerReticle(color: reticleColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Hexagon())
        .accessibilityLabel(accessibilityLabel)
    }

    private var borderColor: Color {
        if isAttackFocusMode {
            if isSelected { return BattlefieldTheme.selectedPiece }
            if isFocused && actionHint.isAttack { return .red }
            return .clear
        }
        if isSelected { return BattlefieldTheme.selectedPiece }
        if actionHint.isAttack { return .red }
        if actionHint.isApproachAttack { return .orange.opacity(0.92) }
        if actionHint.isMove { return .cyan }
        if isPostMoveAttackTarget { return .orange.opacity(0.9) }
        if isAttackPosition { return .orange.opacity(0.78) }
        if let fireExposurePreview { return fireExposurePreview.riskLevel.accentColor.opacity(0.95) }
        if isLatestObjectiveCapture { return .yellow.opacity(0.96) }
        if isGuidedObjective { return .green.opacity(0.96) }
        if !enemyThreatCountermeasureMarkers.isEmpty { return .mint.opacity(0.96) }
        if !objectivePressureMarkers.isEmpty { return .pink.opacity(0.96) }
        if !focusedAIPhaseMapMarkers.isEmpty { return .white.opacity(0.96) }
        if let battlefieldSituationResponseMarker { return battlefieldSituationResponseColor(for: battlefieldSituationResponseMarker.kind).opacity(0.96) }
        if isEnemyThreatIntentTarget { return .pink.opacity(0.92) }
        if isMovementRoute { return .cyan.opacity(0.88) }
        if isAttackCoverage { return .orange.opacity(0.40) }
        if isFocused { return .white.opacity(0.9) }
        if !aiPhaseMapMarkers.isEmpty { return .indigo.opacity(0.86) }
        return .clear
    }

    private var borderWidth: CGFloat {
        if isAttackFocusMode {
            if isSelected { return 1.5 }
            if isFocused && actionHint.isAttack { return 3 }
            return 0.45
        }
        if isSelected { return 1.5 }
        if actionHint.isAttack || actionHint.isApproachAttack || actionHint.isMove { return 3 }
        if isPostMoveAttackTarget { return 3 }
        if isAttackPosition { return 3 }
        if fireExposurePreview?.riskLevel.sortRank ?? 0 >= FireRiskLevel.high.sortRank { return 3 }
        if isLatestObjectiveCapture { return 3 }
        if isGuidedObjective { return 3 }
        if !enemyThreatCountermeasureMarkers.isEmpty { return 3 }
        if !objectivePressureMarkers.isEmpty { return 3 }
        if !focusedAIPhaseMapMarkers.isEmpty { return 3 }
        if battlefieldSituationResponseMarker != nil { return 3 }
        if isEnemyThreatIntentTarget { return 2 }
        if isMovementRoute { return 2 }
        if isAttackCoverage { return 1 }
        if isFocused { return 2 }
        if !aiPhaseMapMarkers.isEmpty { return 2 }
        return 0.45
    }

    private var reticleColor: Color? {
        if isSelected { return BattlefieldTheme.selectedPiece }
        guard isFocused else { return nil }
        if actionHint.isAttack { return .red }
        if actionHint.isApproachAttack { return .orange }
        return nil
    }

    private var shouldShowActionMarker: Bool {
        guard actionHint.isCommandable else { return false }
        return !isAttackFocusMode || (isFocused && actionHint.isAttack)
    }

    private var shouldShowUnavailableTargetMarker: Bool {
        if isAttackFocusMode { return false }
        // Only explain out-of-range/unavailable on the tile the player is
        // actually inspecting — ambient "7>1" chips on every enemy read as
        // noise (GoG3 keeps the field clean until you ask).
        guard isFocused else { return false }
        switch actionHint {
        case .enemyOutOfRange, .enemyUnavailable:
            return true
        case .none, .selectedUnit, .selectableUnit, .move, .attack, .approachAttack, .friendlyOccupied:
            return false
        }
    }

    private static let maxStackChips = 2

    private var topOverlayChips: [HexTileTopOverlayChip] {
        var chips: [HexTileTopOverlayChip] = []
        if !enemyThreatCountermeasureMarkers.isEmpty {
            chips.append(.countermeasure)
        }
        if !objectivePressureMarkers.isEmpty {
            chips.append(.objectivePressure)
        }
        if battlefieldSituationResponseMarker != nil {
            chips.append(.situationResponse)
        }
        if isEnemyThreatIntentTarget {
            chips.append(.enemyThreatIntent)
        }
        if fireExposurePreview != nil {
            chips.append(.fireRisk)
        }
        if isLatestObjectiveCapture {
            chips.append(.latestCapture)
        }
        if isGuidedObjective {
            chips.append(.guidedObjective)
        }
        return chips.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleTopOverlayChips: [HexTileTopOverlayChip] {
        Array(topOverlayChips.prefix(Self.maxStackChips))
    }

    private var topOverlayOverflowCount: Int {
        max(0, topOverlayChips.count - Self.maxStackChips)
    }

    private var bottomOverlayChips: [HexTileBottomOverlayChip] {
        var chips: [HexTileBottomOverlayChip] = []
        if !aiPhaseMapMarkers.isEmpty {
            chips.append(.aiPhase)
        }
        if isAttackPosition {
            chips.append(.attackPosition)
        }
        return chips.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleBottomOverlayChips: [HexTileBottomOverlayChip] {
        Array(bottomOverlayChips.prefix(Self.maxStackChips))
    }

    private var bottomOverlayOverflowCount: Int {
        max(0, bottomOverlayChips.count - Self.maxStackChips)
    }

    @ViewBuilder
    private func topOverlayChipView(_ chip: HexTileTopOverlayChip) -> some View {
        switch chip {
        case .countermeasure:
            EnemyThreatCountermeasureFocusMarker(markers: enemyThreatCountermeasureMarkers)
        case .objectivePressure:
            BattlefieldSituationObjectivePressureMapMarkerView(markers: objectivePressureMarkers)
        case .situationResponse:
            if let battlefieldSituationResponseMarker {
                BattlefieldSituationResponseMapMarkerView(marker: battlefieldSituationResponseMarker)
            }
        case .enemyThreatIntent:
            EnemyThreatIntentMarker()
        case .fireRisk:
            if let fireExposurePreview {
                FireRiskMarker(preview: fireExposurePreview)
            }
        case .latestCapture:
            ObjectiveCaptureMarker()
        case .guidedObjective:
            GuidedObjectiveMarker()
        }
    }

    @ViewBuilder
    private func bottomOverlayChipView(_ chip: HexTileBottomOverlayChip) -> some View {
        switch chip {
        case .aiPhase:
            AIPhaseMapReplayMarker(
                markers: focusedAIPhaseMapMarkers.isEmpty ? aiPhaseMapMarkers : focusedAIPhaseMapMarkers,
                isFocused: !focusedAIPhaseMapMarkers.isEmpty
            )
        case .attackPosition:
            AttackPositionMarker()
        }
    }

    private var accessibilityLabel: String {
        let unitText = unit.map { "\($0.faction.title)\($0.kind.title)\($0.name)" } ?? "空地"
        let objectiveText = tile.objectiveName.map { "据点\($0)" } ?? ""
        let controlZoneText = isEnemyControlZone ? "敌方控制区" : ""
        let threatText = isThreatenedMoveTile ? "敌方火力覆盖" : ""
        let attackCoverageText = isAttackCoverage ? "射程覆盖" : ""
        let postMoveAttackText = isPostMoveAttackTarget ? "移动后可攻击" : ""
        let attackPositionText = isAttackPosition ? "可进入攻击位" : ""
        let guidedObjectiveText = isGuidedObjective ? "当前目标据点" : ""
        let latestCaptureText = isLatestObjectiveCapture ? "最新占领据点" : ""
        let enemyThreatIntentText = isEnemyThreatIntentTarget ? "敌方意图目标" : ""
        let countermeasureText = enemyThreatCountermeasureMarkers.isEmpty
            ? ""
            : enemyThreatCountermeasureMarkers
                .sorted { $0.role.sortOrder < $1.role.sortOrder }
                .map(\.role.title)
                .joined(separator: "，")
        let battlefieldSituationResponseText = battlefieldSituationResponseMarker.map {
            "态势响应，\($0.shortTitle)，\($0.summary)"
        } ?? ""
        let objectivePressureText = objectivePressureMarkers.isEmpty
            ? ""
            : objectivePressureMarkers
                .sorted { $0.role.sortOrder < $1.role.sortOrder }
                .map { "据点压力，\($0.summary)" }
                .joined(separator: "，")
        let aiPhaseMapText = aiPhaseMapAccessibilityText
        let fireRiskText = fireExposurePreview.map { preview in
            let sourceText = preview.sources.prefix(2).map(\.sourceName).joined(separator: "、")
            let sourceSummary = sourceText.isEmpty ? "无敌火来源" : "来源\(sourceText)"
            return "\(preview.riskLevel.title)，潜在伤害\(preview.totalPotentialDamage)，预计剩余\(preview.projectedHPAfterExposure)，\(sourceSummary)"
        } ?? ""
        return "\(tile.terrain.title) \(objectiveText) \(controlZoneText) \(threatText) \(routeAccessibilityText) \(attackCoverageText) \(postMoveAttackText) \(attackPositionText) \(guidedObjectiveText) \(latestCaptureText) \(enemyThreatIntentText) \(countermeasureText) \(objectivePressureText) \(battlefieldSituationResponseText) \(aiPhaseMapText) \(fireRiskText) \(unitText) \(actionAccessibilityText)"
    }

    private func battlefieldSituationResponseColor(
        for kind: BattlefieldSituationResponseKind
    ) -> Color {
        switch kind {
        case .countermeasureFollowUp:
            return Color.blue
        case .countermeasure:
            return Color.mint
        case .objectiveCapture:
            return Color.yellow
        case .combat:
            return Color.orange
        case .tacticalCommand:
            return Color.purple
        case .deployment:
            return Color.green
        case .reinforcement:
            return Color.cyan
        }
    }

    private var aiPhaseMapAccessibilityText: String {
        guard !aiPhaseMapMarkers.isEmpty else { return "" }
        let markers = aiPhaseMapMarkers.sorted { left, right in
            let leftFocused = focusedAIPhaseMapMarkers.contains { $0.id == left.id }
            let rightFocused = focusedAIPhaseMapMarkers.contains { $0.id == right.id }
            if leftFocused != rightFocused {
                return leftFocused
            }
            if left.eventOrder != right.eventOrder {
                return left.eventOrder < right.eventOrder
            }
            return left.role.sortOrder < right.role.sortOrder
        }
        let visibleText = markers.prefix(2).map { marker in
            let focusedText = focusedAIPhaseMapMarkers.contains { $0.id == marker.id } ? "当前" : ""
            return "\(focusedText)AI复盘第\(marker.eventOrder)步，\(marker.eventKind.title)，\(marker.role.title)，\(marker.summary)"
        }.joined(separator: "；")
        let hiddenCount = markers.count - min(markers.count, 2)
        let hiddenText = hiddenCount > 0 ? "；另有\(hiddenCount)条AI复盘标记" : ""
        return "\(visibleText)\(hiddenText)"
    }

    private var routeAccessibilityText: String {
        guard let routeStepPreview else { return "" }
        let destinationText = routeStepPreview.isDestination ? "，终点" : ""
        let controlZoneText = routeStepPreview.controlZonePenalty > 0 ? "，控制区+\(routeStepPreview.controlZonePenalty)" : ""
        let threatText = routeStepPreview.threatCount > 0 ? "，受\(routeStepPreview.threatNames.joined(separator: "、"))火力威胁" : ""
        return "路线第\(routeStepPreview.stepIndex)步，消耗\(routeStepPreview.movementCost)\(controlZoneText)\(threatText)\(destinationText)"
    }

    private var actionAccessibilityText: String {
        switch actionHint {
        case .none:
            return ""
        case .selectedUnit:
            return "当前选中"
        case .selectableUnit:
            return "可左键选择"
        case let .move(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "可右键移动，消耗\(cost)，含敌方控制区+\(controlZonePenalty)" : "可右键移动，消耗\(cost)"
        case let .attack(damage, counterDamage, willDestroy):
            let destroyText = willDestroy ? "，预计击毁" : ""
            return "可右键攻击，伤害\(damage)，反击\(counterDamage)\(destroyText)"
        case let .approachAttack(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "可右键接敌移动，消耗\(cost)，含敌方控制区+\(controlZonePenalty)" : "可右键接敌移动，消耗\(cost)"
        case .friendlyOccupied:
            return "友军占据"
        case let .enemyOutOfRange(distance, range):
            return "敌军距离\(distance)，超过射程\(range)"
        case .enemyUnavailable:
            return "敌军当前不可攻击"
        }
    }
}

struct ObjectiveFlagMarker: View {
    @ScaledMetric(relativeTo: .caption) private var ownerFontSize: CGFloat = 5.5

    let owner: Faction?

    var body: some View {
        // GoG3-style banner on a pole instead of a pill chip.
        ZStack(alignment: .topLeading) {
            // Pole.
            RoundedRectangle(cornerRadius: 0.75)
                .fill(Color(red: 0.35, green: 0.30, blue: 0.24))
                .frame(width: 1.8, height: 21)
                .offset(x: 1, y: 0)

            // Waving banner.
            WavingFlagShape()
                .fill(
                    LinearGradient(
                        colors: [
                            (owner?.accentColor ?? Color(white: 0.55)),
                            (owner?.accentColor ?? Color(white: 0.55)).opacity(0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    WavingFlagShape()
                        .stroke(Color.black.opacity(0.30), lineWidth: 0.7)
                )
                .frame(width: 15, height: 10)
                .offset(x: 2.6, y: 1)

            Text(owner?.shortTitle ?? "NEU")
                .font(.system(size: ownerFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 0.5)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.52)
                .offset(x: 4.6, y: 3)
        }
        .frame(width: 18, height: 22, alignment: .topLeading)
        .shadow(color: .black.opacity(0.35), radius: 1, x: 0.5, y: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A small banner with a gently waving fly edge.
struct WavingFlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12),
            control1: CGPoint(x: rect.width * 0.4, y: rect.minY - rect.height * 0.18),
            control2: CGPoint(x: rect.width * 0.7, y: rect.minY + rect.height * 0.24)
        )
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY - rect.height * 0.10))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.62, y: rect.maxY + rect.height * 0.14),
            control2: CGPoint(x: rect.width * 0.34, y: rect.maxY - rect.height * 0.26)
        )
        path.closeSubpath()
        return path
    }
}

/// Two stacked triangles forming a stylized conifer silhouette.
struct TerrainCodeBadge: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(BattlefieldTheme.commandDeckDeep.opacity(0.72))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.22), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.16), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ObjectiveNamePlate: View {
    @ScaledMetric(relativeTo: .caption) private var nameFontSize: CGFloat = 8

    let name: String
    let owner: Faction?
    var compact = false

    var body: some View {
        // Parchment nameplate under objective settlements, GoG3 city-label style.
        Text(name)
            .font(.system(size: nameFontSize, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 0.24, green: 0.20, blue: 0.13))
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(compact ? 0.46 : 0.52)
            .padding(.horizontal, compact ? 3 : 5)
            .padding(.vertical, compact ? 1.5 : 2.5)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.89, blue: 0.76),
                        Color(red: 0.85, green: 0.78, blue: 0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke((owner?.accentColor ?? BattlefieldTheme.brass).opacity(0.78), lineWidth: 1)
            )
            .shadow(color: .black.opacity(compact ? 0.20 : 0.28), radius: compact ? 1 : 2, x: 0, y: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ControlZoneMarker: View {
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .padding(4)
            .background(Color.red.opacity(0.88), in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct SupplyLineMarker: View {
    let connectionDirections: [Int]

    var body: some View {
        GeometryReader { proxy in
            let path = connectionPath(in: proxy.size)
            ZStack {
                path
                    .stroke(
                        Color.black.opacity(0.10),
                        style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
                    )
                path
                    .stroke(
                        BattlefieldTheme.supplyLine.opacity(0.48),
                        style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func connectionPath(in size: CGSize) -> Path {
        Path { path in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            if connectionDirections.isEmpty {
                path.move(to: CGPoint(x: size.width * 0.43, y: center.y))
                path.addLine(to: CGPoint(x: size.width * 0.57, y: center.y))
                return
            }

            for direction in connectionDirections {
                path.move(to: center)
                path.addLine(to: endpoint(for: direction, in: size))
            }
        }
    }

    private func endpoint(for direction: Int, in size: CGSize) -> CGPoint {
        switch direction {
        case 0: CGPoint(x: size.width, y: size.height * 0.5)
        case 1: CGPoint(x: size.width * 0.75, y: size.height * 0.125)
        case 2: CGPoint(x: size.width * 0.25, y: size.height * 0.125)
        case 3: CGPoint(x: 0, y: size.height * 0.5)
        case 4: CGPoint(x: size.width * 0.25, y: size.height * 0.875)
        default: CGPoint(x: size.width * 0.75, y: size.height * 0.875)
        }
    }
}

struct AttackCoverageMarker: View {
    var body: some View {
        Image(systemName: "scope")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.9))
            .padding(4)
            .background(Color.orange.opacity(0.72), in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct PostMoveAttackMarker: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 7, weight: .black))
            Text("NEXT")
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.86), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct AttackPositionMarker: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "scope")
                .font(.system(size: 7, weight: .black))
            Text("POS")
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.76), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ThreatenedMoveMarker: View {
    var body: some View {
        HStack(spacing: 1) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 7, weight: .black))
            Text("!")
                .font(.system(size: 6, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(Color.red.opacity(0.78), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.30), lineWidth: 0.8)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct FireRiskMarker: View {
    let preview: PostMoveFireExposurePreview

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: preview.riskLevel.systemImage)
                .font(.system(size: 7, weight: .black))
            Text(preview.riskLevel.shortTitle)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(preview.riskLevel.accentColor.opacity(0.86), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.36), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct GuidedObjectiveMarker: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 8, weight: .black))
            Text("OBJ")
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.green.opacity(0.82), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ObjectiveCaptureMarker: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flag.fill")
                .font(.system(size: 8, weight: .black))
            Text("CAP")
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(.black.opacity(0.82))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.yellow.opacity(0.88), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct EnemyThreatIntentMarker: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                .font(.system(size: 7, weight: .black))
            Text("INT")
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.pink.opacity(0.86), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.36), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct EnemyThreatCountermeasureFocusMarker: View {
    let markers: [EnemyThreatCountermeasureMapMarker]

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "scope")
                .font(.system(size: 7, weight: .black))
            Text(displayText)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.black.opacity(0.84))
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.mint.opacity(0.9), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var displayText: String {
        let roles = uniqueRoles
        if roles.count == 1 {
            return roles[0].shortTitle
        }
        return roles.map(\.compactTitle).joined(separator: "+")
    }

    private var uniqueRoles: [EnemyThreatCountermeasureMapMarkerRole] {
        var seen: Set<EnemyThreatCountermeasureMapMarkerRole> = []
        return markers
            .map(\.role)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { role in
                if seen.contains(role) { return false }
                seen.insert(role)
                return true
            }
    }
}

struct BattlefieldSituationResponseMapMarkerView: View {
    let marker: BattlefieldSituationResponseMapMarker

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: marker.iconName)
                .font(.system(size: 7, weight: .black))
            Text(marker.shortTitle)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(markerColor.opacity(0.9), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var markerColor: Color {
        switch marker.kind {
        case .countermeasureFollowUp:
            return Color.blue
        case .countermeasure:
            return Color.mint
        case .objectiveCapture:
            return Color.yellow
        case .combat:
            return Color.orange
        case .tacticalCommand:
            return Color.purple
        case .deployment:
            return Color.green
        case .reinforcement:
            return Color.cyan
        }
    }

    private var foregroundColor: Color {
        switch marker.kind {
        case .countermeasure, .objectiveCapture, .deployment, .reinforcement:
            return Color.black.opacity(0.84)
        case .countermeasureFollowUp, .combat, .tacticalCommand:
            return Color.white
        }
    }
}

struct BattlefieldSituationObjectivePressureMapMarkerView: View {
    let markers: [BattlefieldSituationObjectivePressureMapMarker]

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 7, weight: .black))
            Text(displayText)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.pink.opacity(0.9), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var displayText: String {
        let roles = uniqueRoles
        if roles.count == 1 {
            return roles[0].shortTitle
        }
        return roles.map(\.compactTitle).joined(separator: "+")
    }

    private var uniqueRoles: [BattlefieldSituationObjectivePressureMapMarkerRole] {
        var seen: Set<BattlefieldSituationObjectivePressureMapMarkerRole> = []
        return markers
            .map(\.role)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { role in
                if seen.contains(role) { return false }
                seen.insert(role)
                return true
            }
    }
}

struct AIPhaseMapReplayMarker: View {
    let markers: [AIPhaseMapMarker]
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isFocused ? "scope" : "clock.arrow.circlepath")
                .font(.system(size: 7, weight: .black))
            Text(displayText)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(isFocused ? .black : .white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background((isFocused ? Color.yellow.opacity(0.88) : Color.indigo.opacity(0.88)), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(isFocused ? 0.72 : 0.36), lineWidth: isFocused ? 1.5 : 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var displayText: String {
        let orderedMarkers = markers.sorted {
            if $0.eventOrder != $1.eventOrder {
                return $0.eventOrder < $1.eventOrder
            }
            if $0.role.sortOrder != $1.role.sortOrder {
                return $0.role.sortOrder < $1.role.sortOrder
            }
            return $0.coordinate.id < $1.coordinate.id
        }
        guard let firstMarker = orderedMarkers.first else { return "AI" }
        if orderedMarkers.count == 1 {
            return "\(isFocused ? "SEL " : "")\(firstMarker.shortCode)-\(firstMarker.role.shortTitle)"
        }
        let roleText = orderedMarkers.prefix(2).map(\.role.compactTitle).joined(separator: "+")
        return "\(isFocused ? "SEL " : "")\(firstMarker.shortCode)+\(roleText)"
    }
}

struct MovementRouteMarker: View {
    let step: RouteStepPreview?
    let isDestination: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(markerFill)
                .frame(width: 62, height: 14)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isDestination ? 0.46 : 0.28), lineWidth: 1)
                )
                .rotationEffect(.degrees(-18))

            if let step {
                HStack(spacing: 2) {
                    if step.isThreatened {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 7, weight: .black))
                    }
                    Text("\(step.stepIndex):\(step.movementCost)")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(markerBadgeFill, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.38), lineWidth: 1)
                )
            } else if isDestination {
                RouteDestinationIcon()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var markerFill: Color {
        guard step?.isThreatened == true else {
            return Color.cyan.opacity(isDestination ? 0.28 : 0.20)
        }
        return Color.red.opacity(isDestination ? 0.26 : 0.20)
    }

    private var markerBadgeFill: Color {
        guard step?.isThreatened == true else {
            return Color.cyan.opacity(isDestination ? 0.92 : 0.78)
        }
        return Color.red.opacity(isDestination ? 0.94 : 0.82)
    }
}

struct RouteDestinationIcon: View {
    var body: some View {
        Image(systemName: "location.fill")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .padding(4)
            .background(Color.cyan.opacity(0.88), in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.38), lineWidth: 1)
            )
    }
}

struct TerrainSymbol: View {
    let tile: TerrainTile

    var body: some View {
        VStack(spacing: 2) {
            Text(tile.terrain.mapSymbol)
                .font(.system(size: tile.isObjective ? 18 : 22, weight: .black, design: .rounded))
                .foregroundStyle(tile.terrain.symbolColor)
                .shadow(color: .black.opacity(tile.terrain == .snow ? 0.0 : 0.18), radius: 1, x: 0, y: 1)
            Spacer(minLength: 0)
        }
        .padding(.top, tile.isObjective ? 24 : 19)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ActionMarker: View {
    let actionHint: MapActionHint

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .black))
            Text(label)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(backgroundColor, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.30), lineWidth: 0.8)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var icon: String {
        switch actionHint {
        case .move:
            return "arrow.turn.up.right"
        case .attack:
            return "target"
        case .approachAttack:
            return "scope"
        case .none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable:
            return "circle"
        }
    }

    private var label: String {
        switch actionHint {
        case let .move(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "\(cost)+" : "\(cost)"
        case let .attack(damage, counterDamage, willDestroy):
            let counterText = counterDamage > 0 ? "/C\(counterDamage)" : ""
            return willDestroy ? "K" : "\(damage)\(counterText)"
        case let .approachAttack(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "P\(cost)+" : "P\(cost)"
        case .none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable:
            return ""
        }
    }

    private var backgroundColor: Color {
        switch actionHint {
        case .move:
            return Color.cyan.opacity(0.86)
        case .attack(_, _, let willDestroy):
            return willDestroy ? Color.orange.opacity(0.94) : Color.red.opacity(0.92)
        case .approachAttack:
            return Color.orange.opacity(0.88)
        case .none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable:
            return Color.white.opacity(0.3)
        }
    }
}

struct UnavailableTargetMarker: View {
    let actionHint: MapActionHint

    var body: some View {
        Text(label)
            .font(.system(size: 7, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.46), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.red.opacity(0.38), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var label: String {
        switch actionHint {
        case let .enemyOutOfRange(distance, range):
            return "\(distance)>\(range)"
        case .enemyUnavailable:
            return "NO"
        case .none, .selectedUnit, .selectableUnit, .move, .attack, .approachAttack, .friendlyOccupied:
            return ""
        }
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let vertices = BattlefieldMapLayout.vertices(in: rect)
        return Path { path in
            path.move(to: vertices[0])
            for vertex in vertices.dropFirst() { path.addLine(to: vertex) }
            path.closeSubpath()
        }
    }
}

struct HexInputReader: UIViewRepresentable {
    let hitShape: Path
    let directTouchAction: () -> Void
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            directTouchAction: directTouchAction,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )
    }

    func makeUIView(context: Context) -> HexInputView {
        let view = HexInputView(hitShape: hitShape)
        let directTouchRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDirectTouchTap(_:))
        )
        directTouchRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        directTouchRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(directTouchRecognizer)

        let primaryRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePrimaryTap)
        )
        primaryRecognizer.buttonMaskRequired = .primary
        primaryRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(primaryRecognizer)

        let secondaryRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSecondaryTap)
        )
        secondaryRecognizer.buttonMaskRequired = .secondary
        secondaryRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(secondaryRecognizer)

        return view
    }

    func updateUIView(_ uiView: HexInputView, context: Context) {
        uiView.hitShape = hitShape
        context.coordinator.directTouchAction = directTouchAction
        context.coordinator.primaryAction = primaryAction
        context.coordinator.secondaryAction = secondaryAction
    }

    final class Coordinator: NSObject {
        var directTouchAction: () -> Void
        var primaryAction: () -> Void
        var secondaryAction: () -> Void

        init(
            directTouchAction: @escaping () -> Void,
            primaryAction: @escaping () -> Void,
            secondaryAction: @escaping () -> Void
        ) {
            self.directTouchAction = directTouchAction
            self.primaryAction = primaryAction
            self.secondaryAction = secondaryAction
        }

        @objc func handleDirectTouchTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            directTouchAction()
        }

        @objc func handlePrimaryTap() {
            primaryAction()
        }

        @objc func handleSecondaryTap() {
            secondaryAction()
        }
    }
}

final class HexInputView: UIView {
    var hitShape: Path

    init(hitShape: Path) {
        self.hitShape = hitShape
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return hitShape.contains(point)
    }
}

extension TerrainKind {
    var showsMapConnections: Bool {
        switch self {
        case .river, .road, .forest:
            true
        case .plains, .city, .mountain, .snow:
            false
        }
    }

    var connectionColor: Color {
        switch self {
        case .river:
            Color(red: 0.26, green: 0.50, blue: 0.68).opacity(0.90)
        case .road:
            // Dirt-tan road band; slimmer + softer so clustered road hexes
            // read as winding paths instead of a heavy triangle lattice.
            Color(red: 0.55, green: 0.46, blue: 0.30).opacity(0.64)
        case .forest:
            Color(red: 0.30, green: 0.44, blue: 0.26).opacity(0.20)
        case .city:
            Color.black.opacity(0.10)
        case .mountain:
            Color.white.opacity(0.08)
        case .snow:
            Color.white.opacity(0.12)
        case .plains:
            Color.yellow.opacity(0.06)
        }
    }

    var connectionWidth: CGFloat {
        switch self {
        case .river: 11
        case .road: 4.5
        case .forest: 8
        case .city: 12
        case .mountain, .snow, .plains: 7
        }
    }

    var mapGradient: LinearGradient {
        LinearGradient(
            colors: [
                mapHighlightColor,
                mapColor,
                mapShadowColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // EasyTech GoG3-style continuous ground: neighbours share one pale
    // field tone so the battlefield reads as a single painted landscape,
    // with terrain identity carried mostly by the painted texture layer.
    var mapColor: Color {
        switch self {
        case .plains:
            Color(red: 0.66, green: 0.68, blue: 0.50)
        case .forest:
            Color(red: 0.58, green: 0.65, blue: 0.46)
        case .city:
            Color(red: 0.67, green: 0.67, blue: 0.57)
        case .mountain:
            Color(red: 0.64, green: 0.64, blue: 0.55)
        case .snow:
            Color(red: 0.90, green: 0.92, blue: 0.92)
        case .river:
            // Land-toned fill: the winding blue connection band carries the
            // water so rivers read as a channel, not a solid blue hex.
            Color(red: 0.62, green: 0.68, blue: 0.56)
        case .road:
            Color(red: 0.67, green: 0.68, blue: 0.50)
        }
    }

    private var mapHighlightColor: Color {
        switch self {
        case .plains:
            Color(red: 0.70, green: 0.72, blue: 0.54)
        case .forest:
            Color(red: 0.63, green: 0.70, blue: 0.50)
        case .city:
            Color(red: 0.71, green: 0.72, blue: 0.62)
        case .mountain:
            Color(red: 0.68, green: 0.68, blue: 0.59)
        case .snow:
            Color(red: 0.94, green: 0.96, blue: 0.96)
        case .river:
            Color(red: 0.67, green: 0.72, blue: 0.61)
        case .road:
            Color(red: 0.71, green: 0.72, blue: 0.54)
        }
    }

    private var mapShadowColor: Color {
        switch self {
        case .plains:
            Color(red: 0.61, green: 0.64, blue: 0.46)
        case .forest:
            Color(red: 0.53, green: 0.60, blue: 0.42)
        case .city:
            Color(red: 0.62, green: 0.63, blue: 0.52)
        case .mountain:
            Color(red: 0.59, green: 0.60, blue: 0.50)
        case .snow:
            Color(red: 0.87, green: 0.89, blue: 0.89)
        case .river:
            Color(red: 0.58, green: 0.64, blue: 0.52)
        case .road:
            Color(red: 0.62, green: 0.63, blue: 0.46)
        }
    }

    var mapSymbol: String {
        switch self {
        case .plains:
            "·"
        case .forest:
            "♣"
        case .city:
            "▦"
        case .mountain:
            "△"
        case .snow:
            "*"
        case .river:
            "≈"
        case .road:
            "="
        }
    }

    var symbolColor: Color {
        switch self {
        case .forest, .mountain, .river:
            Color.white.opacity(0.38)
        case .snow:
            Color.black.opacity(0.32)
        default:
            Color.black.opacity(0.28)
        }
    }
}
