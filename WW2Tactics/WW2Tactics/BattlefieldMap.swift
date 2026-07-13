import SwiftUI
import UIKit

struct HexMapView: View {
    @EnvironmentObject private var game: GameState
    let tileScale: CGFloat

    private let tileWidth: CGFloat = 86
    private let tileHeight: CGFloat = 74

    var body: some View {
        let selected = game.selectedUnit
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
        let terrainByCoordinate = Dictionary(uniqueKeysWithValues: game.tiles.map { ($0.coordinate, $0.terrain) })
        let contentWidth = CGFloat(game.scenario.mapColumns) * tileWidth * 0.78 + tileWidth
        let contentHeight = CGFloat(game.scenario.mapRows) * tileHeight * 0.78 + tileHeight

        ZStack(alignment: .topLeading) {
            MapGridBackdrop(width: contentWidth, height: contentHeight)

            ForEach(0..<game.scenario.mapColumns, id: \.self) { q in
                CoordinateLabel(text: "\(q)")
                    .position(
                        x: position(for: HexCoordinate(q: q, r: 0)).x,
                        y: 12
                    )
            }

            ForEach(0..<game.scenario.mapRows, id: \.self) { r in
                CoordinateLabel(text: "\(r)")
                    .position(
                        x: max(12, position(for: HexCoordinate(q: 0, r: r)).x - tileWidth * 0.46),
                        y: position(for: HexCoordinate(q: 0, r: r)).y
                    )
            }

            ForEach(game.tiles) { tile in
                let point = position(for: tile.coordinate)
                let terrainConnectionDirections = tile.coordinate.neighbors.enumerated().compactMap { index, coordinate in
                    terrainByCoordinate[coordinate] == tile.terrain ? index : nil
                }
                HexTileView(
                    tile: tile,
                    terrainConnectionDirections: terrainConnectionDirections,
                    unit: game.unit(at: tile.coordinate),
                    isSelected: selected?.position == tile.coordinate,
                    isFocused: game.focusedCoordinate == tile.coordinate,
                    actionHint: game.mapActionHint(for: tile.coordinate),
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
                .position(x: point.x, y: point.y)
                .id(tile.coordinate.id)
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
            }
        }
        .frame(width: contentWidth, height: contentHeight)
        .scaleEffect(tileScale, anchor: .topLeading)
        .frame(
            width: contentWidth * tileScale,
            height: contentHeight * tileScale,
            alignment: .topLeading
        )
    }

    private func position(for coordinate: HexCoordinate) -> CGPoint {
        let x = CGFloat(coordinate.q) * tileWidth * 0.78 + CGFloat(coordinate.r) * tileWidth * 0.39 + tileWidth / 2
        let y = CGFloat(coordinate.r) * tileHeight * 0.76 + tileHeight / 2
        return CGPoint(x: x, y: y)
    }
}

struct MapGridBackdrop: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.27, green: 0.28, blue: 0.22),
                            Color(red: 0.16, green: 0.17, blue: 0.14),
                            Color(red: 0.10, green: 0.11, blue: 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Path { path in
                let spacing: CGFloat = 48
                var x: CGFloat = 0
                while x <= width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += spacing
                }

                var y: CGFloat = 0
                while y <= height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += spacing
                }
            }
            .stroke(Color.black.opacity(0.045), lineWidth: 1)

            Path { path in
                var x: CGFloat = 18
                while x < width {
                    let y = (x * 1.73).truncatingRemainder(dividingBy: max(height, 1))
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: min(width, x + 16), y: min(height, y + 5)))
                    x += 37
                }
            }
            .stroke(Color.white.opacity(0.045), lineWidth: 0.7)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.16)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct CoordinateLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.36))
            .frame(width: 22, height: 16)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 4))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
    let terrainConnectionDirections: [Int]
    let unit: BattleUnit?
    let isSelected: Bool
    let isFocused: Bool
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
                .fill(tile.terrain.mapGradient)
                .overlay(
                    Hexagon()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear,
                                    Color.black.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Hexagon()
                        .stroke(Color.black.opacity(tile.isObjective ? 0.12 : 0.08), lineWidth: 0.6)
                )
                .overlay(
                    Hexagon()
                        .stroke(borderColor, lineWidth: borderWidth)
                )

            if let owner = tile.owner {
                Hexagon()
                    .fill(owner.accentColor.opacity(tile.isObjective ? 0.10 : 0.035))
                    .overlay(
                        Hexagon()
                            .stroke(owner.accentColor.opacity(tile.isObjective ? 0.38 : 0.10), lineWidth: 0.8)
                    )
            }

            TerrainTexture(tile: tile, connectionDirections: terrainConnectionDirections)

            if isSupplyLine {
                SupplyLineMarker()
            }

            if isMovementRoute {
                MovementRouteMarker(step: routeStepPreview, isDestination: isRouteDestination)
            }

            // Unified top stack: focus / situation chips with overflow collapse.
            if !visibleTopOverlayChips.isEmpty || topOverlayOverflowCount > 0 {
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
            if !visibleBottomOverlayChips.isEmpty || bottomOverlayOverflowCount > 0 {
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

            if isAttackCoverage {
                AttackCoverageMarker()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.bottom, 6)
                    .padding(.leading, 9)
            }

            if isPostMoveAttackTarget {
                PostMoveAttackMarker()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }

            if isEnemyControlZone {
                ControlZoneMarker()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom, 6)
                    .padding(.trailing, 9)
            }

            if isThreatenedMoveTile {
                ThreatenedMoveMarker()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, 9)
            }

            if actionHint.isCommandable {
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

            VStack(spacing: 3) {
                HStack {
                    if tile.isObjective {
                        ObjectiveFlagMarker(owner: tile.owner)
                    } else {
                        TerrainCodeBadge(code: tile.terrain.code)
                    }
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                if let unit {
                    UnitCounter(unit: unit)
                    UnitStatusPlate(unit: unit)
                } else if let objectiveName = tile.objectiveName {
                    ObjectiveNamePlate(name: objectiveName, owner: tile.owner)
                } else {
                    Spacer(minLength: 32)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .contentShape(Hexagon())
        .accessibilityLabel(accessibilityLabel)
    }

    private var borderColor: Color {
        if isSelected { return .yellow }
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
        if isAttackCoverage { return .orange.opacity(0.58) }
        if isSupplyLine { return .green.opacity(0.9) }
        if isThreatenedMoveTile { return .red.opacity(0.76) }
        if isEnemyControlZone { return .red.opacity(0.62) }
        if isFocused { return .white.opacity(0.9) }
        if tile.isObjective { return (tile.owner?.accentColor ?? .yellow).opacity(0.9) }
        if !aiPhaseMapMarkers.isEmpty { return .indigo.opacity(0.86) }
        return .black.opacity(0.28)
    }

    private var borderWidth: CGFloat {
        if isSelected || actionHint.isAttack || actionHint.isApproachAttack || actionHint.isMove { return 3 }
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
        if isAttackCoverage { return 2 }
        if isSupplyLine { return 2 }
        if isThreatenedMoveTile { return 2 }
        if isEnemyControlZone { return 2 }
        if isFocused { return 2 }
        if tile.isObjective { return 2 }
        if !aiPhaseMapMarkers.isEmpty { return 2 }
        return 1
    }

    private var shouldShowUnavailableTargetMarker: Bool {
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

struct TerrainTexture: View {
    let tile: TerrainTile
    let connectionDirections: [Int]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                connectionLayer(in: size)

                switch tile.terrain {
                case .plains:
                    fieldLines(in: size)
                case .forest:
                    forestClusters(in: size)
                case .city:
                    cityBlocks(in: size)
                case .mountain:
                    mountainRidges(in: size)
                case .snow:
                    snowDrifts(in: size)
                case .river:
                    waterHighlight(in: size)
                case .road:
                    roadHighlight(in: size)
                }
            }
        }
        .clipShape(Hexagon())
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func connectionLayer(in size: CGSize) -> some View {
        Path { path in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for direction in connectionDirections {
                path.move(to: center)
                path.addLine(to: endpoint(for: direction, in: size))
            }
        }
        .stroke(
            tile.terrain.connectionColor,
            style: StrokeStyle(lineWidth: tile.terrain.connectionWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func fieldLines(in size: CGSize) -> some View {
        Path { path in
            for offset in stride(from: -size.height * 0.2, through: size.height, by: 11) {
                path.move(to: CGPoint(x: 0, y: offset))
                path.addLine(to: CGPoint(x: size.width, y: offset + size.height * 0.34))
            }
        }
        .stroke(Color.yellow.opacity(0.13), lineWidth: 1)
    }

    private func forestClusters(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                let x = size.width * (0.18 + CGFloat((index * 37) % 67) / 100)
                let y = size.height * (0.18 + CGFloat((index * 23) % 61) / 100)
                Image(systemName: "tree.fill")
                    .font(.system(size: index.isMultiple(of: 3) ? 13 : 10, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.28))
                    .position(x: x, y: y)
            }
        }
    }

    private func cityBlocks(in size: CGSize) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * 0.62))
                path.addLine(to: CGPoint(x: size.width, y: size.height * 0.38))
                path.move(to: CGPoint(x: size.width * 0.46, y: 0))
                path.addLine(to: CGPoint(x: size.width * 0.56, y: size.height))
            }
            .stroke(Color.black.opacity(0.20), lineWidth: 5)
            ForEach(0..<5, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: index.isMultiple(of: 2) ? 13 : 9, height: index.isMultiple(of: 2) ? 9 : 13)
                    .position(
                        x: size.width * (0.22 + CGFloat((index * 31) % 57) / 100),
                        y: size.height * (0.20 + CGFloat((index * 19) % 58) / 100)
                    )
            }
        }
    }

    private func mountainRidges(in size: CGSize) -> some View {
        Path { path in
            path.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.76))
            path.addLine(to: CGPoint(x: size.width * 0.32, y: size.height * 0.26))
            path.addLine(to: CGPoint(x: size.width * 0.48, y: size.height * 0.58))
            path.addLine(to: CGPoint(x: size.width * 0.66, y: size.height * 0.20))
            path.addLine(to: CGPoint(x: size.width * 0.92, y: size.height * 0.72))
        }
        .stroke(Color.white.opacity(0.28), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    private func snowDrifts(in size: CGSize) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size.height * 0.58))
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.42),
                control1: CGPoint(x: size.width * 0.28, y: size.height * 0.28),
                control2: CGPoint(x: size.width * 0.68, y: size.height * 0.78)
            )
        }
        .stroke(Color.white.opacity(0.42), lineWidth: 2)
    }

    private func waterHighlight(in size: CGSize) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size.height * 0.48))
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.52),
                control1: CGPoint(x: size.width * 0.30, y: size.height * 0.26),
                control2: CGPoint(x: size.width * 0.68, y: size.height * 0.72)
            )
        }
        .stroke(Color.white.opacity(0.26), lineWidth: 2)
    }

    private func roadHighlight(in size: CGSize) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size.height * 0.52))
            path.addLine(to: CGPoint(x: size.width, y: size.height * 0.48))
        }
        .stroke(Color.white.opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
    }

    private func endpoint(for direction: Int, in size: CGSize) -> CGPoint {
        switch direction {
        case 0: CGPoint(x: size.width, y: size.height * 0.5)
        case 1: CGPoint(x: size.width * 0.75, y: 0)
        case 2: CGPoint(x: size.width * 0.25, y: 0)
        case 3: CGPoint(x: 0, y: size.height * 0.5)
        case 4: CGPoint(x: size.width * 0.25, y: size.height)
        default: CGPoint(x: size.width * 0.75, y: size.height)
        }
    }
}

struct ObjectiveFlagMarker: View {
    let owner: Faction?

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flag.fill")
                .font(.system(size: 9, weight: .black))
            Text(owner?.shortTitle ?? "NEU")
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background((owner?.accentColor ?? Color.gray).opacity(0.86), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

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
    let name: String
    let owner: Faction?

    var body: some View {
        Text(name)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity)
            .background(BattlefieldTheme.commandDeckDeep.opacity(0.70), in: RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke((owner?.accentColor ?? BattlefieldTheme.brass).opacity(0.56), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 2, x: 0, y: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct UnitStatusPlate: View {
    let unit: BattleUnit

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: unit.hasAttacked ? "checkmark.seal.fill" : "bolt.fill")
                .font(.system(size: 7, weight: .black))
            Text(unit.hasAttacked ? "DONE" : "READY")
                .font(.system(size: 7, weight: .black, design: .rounded))
            Spacer(minLength: 2)
            Text("\(unit.hp)")
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
        .background(unit.faction.accentColor.opacity(unit.hasAttacked ? 0.58 : 0.84), in: RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white.opacity(unit.hasAttacked ? 0.20 : 0.38), lineWidth: 1)
        )
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
    var body: some View {
        Capsule()
            .fill(Color.green.opacity(0.22))
            .frame(width: 56, height: 10)
            .overlay(
                Capsule()
                    .stroke(Color.green.opacity(0.46), lineWidth: 1)
            )
            .rotationEffect(.degrees(-18))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 7, weight: .black))
            Text("THR")
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.red.opacity(0.78), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
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
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .black))
            Text(label)
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(backgroundColor, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
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
            return controlZonePenalty > 0 ? "M\(cost)+" : "M\(cost)"
        case let .attack(damage, counterDamage, willDestroy):
            let counterText = counterDamage > 0 ? "/C\(counterDamage)" : ""
            return willDestroy ? "KILL" : "A\(damage)\(counterText)"
        case let .approachAttack(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "POS\(cost)+" : "POS\(cost)"
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
        let width = rect.width
        let height = rect.height
        let points = [
            CGPoint(x: width * 0.25, y: 0),
            CGPoint(x: width * 0.75, y: 0),
            CGPoint(x: width, y: height * 0.5),
            CGPoint(x: width * 0.75, y: height),
            CGPoint(x: width * 0.25, y: height),
            CGPoint(x: 0, y: height * 0.5)
        ]

        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
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
    var connectionColor: Color {
        switch self {
        case .river:
            Color(red: 0.18, green: 0.46, blue: 0.68).opacity(0.82)
        case .road:
            Color(red: 0.62, green: 0.52, blue: 0.34).opacity(0.72)
        case .forest:
            Color(red: 0.12, green: 0.28, blue: 0.14).opacity(0.32)
        case .city:
            Color.black.opacity(0.12)
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
        case .river: 17
        case .road: 9
        case .forest, .city: 12
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

    var mapColor: Color {
        switch self {
        case .plains:
            Color(red: 0.54, green: 0.61, blue: 0.41)
        case .forest:
            Color(red: 0.25, green: 0.42, blue: 0.26)
        case .city:
            Color(red: 0.54, green: 0.53, blue: 0.49)
        case .mountain:
            Color(red: 0.48, green: 0.48, blue: 0.45)
        case .snow:
            Color(red: 0.78, green: 0.82, blue: 0.80)
        case .river:
            Color(red: 0.22, green: 0.42, blue: 0.60)
        case .road:
            Color(red: 0.62, green: 0.55, blue: 0.42)
        }
    }

    private var mapHighlightColor: Color {
        switch self {
        case .plains:
            Color(red: 0.66, green: 0.72, blue: 0.48)
        case .forest:
            Color(red: 0.34, green: 0.52, blue: 0.31)
        case .city:
            Color(red: 0.66, green: 0.65, blue: 0.58)
        case .mountain:
            Color(red: 0.62, green: 0.61, blue: 0.56)
        case .snow:
            Color(red: 0.92, green: 0.95, blue: 0.92)
        case .river:
            Color(red: 0.34, green: 0.56, blue: 0.74)
        case .road:
            Color(red: 0.74, green: 0.66, blue: 0.48)
        }
    }

    private var mapShadowColor: Color {
        switch self {
        case .plains:
            Color(red: 0.40, green: 0.48, blue: 0.31)
        case .forest:
            Color(red: 0.16, green: 0.29, blue: 0.18)
        case .city:
            Color(red: 0.40, green: 0.40, blue: 0.36)
        case .mountain:
            Color(red: 0.34, green: 0.34, blue: 0.32)
        case .snow:
            Color(red: 0.64, green: 0.72, blue: 0.72)
        case .river:
            Color(red: 0.14, green: 0.30, blue: 0.48)
        case .road:
            Color(red: 0.46, green: 0.40, blue: 0.30)
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
