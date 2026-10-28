import SwiftUI

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
                    Hexagon().fill(BattlefieldTheme.movement.opacity(0.12))
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
        if actionHint.isMove { return BattlefieldTheme.movement.opacity(isFocused || isRouteDestination ? 0.90 : 0.30) }
        if isPostMoveAttackTarget { return .orange.opacity(0.9) }
        if isAttackPosition { return .orange.opacity(0.78) }
        if let fireExposurePreview { return fireExposurePreview.riskLevel.accentColor.opacity(0.95) }
        if isLatestObjectiveCapture { return .yellow.opacity(0.96) }
        if isGuidedObjective { return .green.opacity(0.96) }
        if !enemyThreatCountermeasureMarkers.isEmpty { return .mint.opacity(0.96) }
        if !objectivePressureMarkers.isEmpty { return .pink.opacity(0.96) }
        if !focusedAIPhaseMapMarkers.isEmpty { return .white.opacity(0.96) }
        if let battlefieldSituationResponseMarker { return battlefieldSituationResponseColor(for: battlefieldSituationResponseMarker.kind).opacity(0.96) }
        if isEnemyThreatIntentTarget { return BattlefieldTheme.alert.opacity(0.80) }
        if isMovementRoute { return .cyan.opacity(0.88) }
        if isAttackCoverage { return .orange.opacity(0.40) }
        if isFocused { return .white.opacity(0.9) }
        return .clear
    }

    private var borderWidth: CGFloat {
        if isAttackFocusMode {
            if isSelected { return 1.5 }
            if isFocused && actionHint.isAttack { return 3 }
            return 0.45
        }
        if isSelected { return 1.5 }
        if actionHint.isAttack || actionHint.isApproachAttack { return 2.2 }
        if actionHint.isMove { return isFocused || isRouteDestination ? 1.6 : 0.65 }
        if isPostMoveAttackTarget { return 3 }
        if isAttackPosition { return 3 }
        if fireExposurePreview?.riskLevel.sortRank ?? 0 >= FireRiskLevel.high.sortRank { return 3 }
        if isLatestObjectiveCapture { return 3 }
        if isGuidedObjective { return 3 }
        if !enemyThreatCountermeasureMarkers.isEmpty { return 3 }
        if !objectivePressureMarkers.isEmpty { return 3 }
        if !focusedAIPhaseMapMarkers.isEmpty { return 3 }
        if battlefieldSituationResponseMarker != nil { return 3 }
        if isEnemyThreatIntentTarget { return 1.3 }
        if isMovementRoute { return 2 }
        if isAttackCoverage { return 1 }
        if isFocused { return 2 }
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
        BattlefieldActionMarkerPresentation.showsMarker(
            for: actionHint, focused: isFocused, routeDestination: isRouteDestination, attackFocus: isAttackFocusMode
        )
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
        if !BattlefieldActionMarkerPresentation.showsTacticalDetails(focused: isFocused, selected: isSelected) {
            if isLatestObjectiveCapture { chips.append(.latestCapture) }
            if isGuidedObjective { chips.append(.guidedObjective) }
            return chips
        }
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
        if !aiPhaseMapMarkers.isEmpty && BattlefieldActionMarkerPresentation.showsReplay(
            focused: isFocused, explicitReplay: !focusedAIPhaseMapMarkers.isEmpty
        ) {
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

}
