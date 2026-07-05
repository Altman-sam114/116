import Foundation

@MainActor
final class GameState: ObservableObject {
    @Published private(set) var scenario: Scenario
    @Published var selectedUnitID: BattleUnit.ID?
    @Published var activeFaction: Faction = .allies
    @Published var turn = 1
    @Published var message = "夺取全部据点，保持装甲突击节奏。"
    @Published var battleLog: [String] = ["1944 阿登战役开始，盟军必须夺取地图上的全部据点。"]
    @Published var winner: Faction?
    @Published private(set) var earnedStars = 0
    @Published var focusedCoordinate: HexCoordinate?
    @Published private(set) var guidedObjectiveCoordinate: HexCoordinate?
    @Published private(set) var focusedSafeEngagementDestination: HexCoordinate?
    @Published var commandPoints: [Faction: Int]
    @Published private(set) var latestCombatResult: CombatResultSummary?
    @Published private(set) var latestTacticalCommandResult: TacticalCommandResultSummary?
    @Published private(set) var latestObjectiveCaptureResult: ObjectiveCaptureResultSummary?
    @Published private(set) var latestDeploymentResult: DeploymentResultSummary?
    @Published private(set) var latestReinforcementResult: ReinforcementResultSummary?
    @Published private(set) var latestEnemyThreatCountermeasureExecutionResult: EnemyThreatCountermeasureExecutionResultSummary?
    @Published private(set) var latestEnemyThreatCountermeasureFollowUpResult: EnemyThreatCountermeasureFollowUpSummary?
    @Published private(set) var latestAIPhaseSummary: AIPhaseSummary?

    private enum MapCommandInputMode {
        case directTap
        case secondaryAction
        case commandButton

        var followUpAttackPrompt: String {
            switch self {
            case .directTap:
                return "继续点击可攻击"
            case .secondaryAction:
                return "再次右键可攻击"
            case .commandButton:
                return "再次点执行可攻击"
            }
        }
    }

    private enum AIPhaseAction {
        case reinforcement
        case deployment
        case tacticalCommand
        case attack
        case move
    }

    private struct AIPhaseActionCounts {
        var reinforcements = 0
        var deployments = 0
        var tacticalCommands = 0
        var attacks = 0
        var moves = 0
    }

    private struct AIPhaseBaseline {
        let faction: Faction
        let turn: Int
        let commandPoints: Int
        let unitHPByID: [BattleUnit.ID: Int]
        let unitFactionByID: [BattleUnit.ID: Faction]
        let aliveUnitIDs: Set<BattleUnit.ID>
        let objectiveOwnersByCoordinate: [HexCoordinate: Faction]
    }

    private struct EnemyThreatCountermeasureFollowUpUnitSnapshot {
        let id: BattleUnit.ID
        let name: String
        let hp: Int
        let maxHP: Int
        let position: HexCoordinate

        var isDestroyed: Bool {
            hp <= 0
        }
    }

    private struct EnemyThreatCountermeasureFollowUpBaseline {
        let execution: EnemyThreatCountermeasureExecutionResultSummary
        let actingUnit: EnemyThreatCountermeasureFollowUpUnitSnapshot?
        let targetUnit: EnemyThreatCountermeasureFollowUpUnitSnapshot?
        let threatEnemyUnit: EnemyThreatCountermeasureFollowUpUnitSnapshot?
        let objectiveOwner: Faction?
    }

    private struct ObjectiveAdvancePlan {
        let tile: TerrainTile
        let route: MovementRoute
        let reachesObjective: Bool
        let currentDistance: Int
        let remainingDistance: Int
    }

    private var focusedSafeEngagementTargetID: BattleUnit.ID?
    private var focusedEnemyThreatCountermeasurePreview: EnemyThreatCountermeasurePreview?
    private var activeAIPhaseBaseline: AIPhaseBaseline?
    private var activeAIPhaseActionCounts = AIPhaseActionCounts()
    private var activeAIPhaseTimeline: [AIPhaseTimelineEvent] = []
    private var pendingEnemyThreatCountermeasureFollowUpBaseline: EnemyThreatCountermeasureFollowUpBaseline?

    private static let objectiveCaptureCommandReward = 3
    private static let objectiveCaptureMoraleReward = 8
    private static let objectiveCaptureExperienceReward = 10
    private static let enemyControlZoneMovementPenalty = 1
    private static let entrenchedDamageMultiplierPercent = 75
    private static let flankingSupportBonusPercent = 10
    private static let maxFlankingSupportBonusPercent = 30
    private static let commanderAuraDamageBonusPercent = 8
    private static let objectiveRestRecoveryAmount = 10

    init(
        scenario: Scenario = Scenario.ardennesPrototype(),
        commandPoints: [Faction: Int] = [.allies: 6, .axis: 6]
    ) {
        self.scenario = scenario
        self.commandPoints = commandPoints
        focusedCoordinate = scenario.initialFocus
        message = Self.openingMessage(for: scenario)
        battleLog = [Self.openingLog(for: scenario)]
    }

    var campaignCatalog: [Scenario] {
        Scenario.campaignCatalog
    }

    var tiles: [TerrainTile] { scenario.tiles }
    var units: [BattleUnit] { scenario.units.filter { !$0.isDestroyed } }

    var selectedUnit: BattleUnit? {
        guard let selectedUnitID else { return nil }
        return scenario.units.first { $0.id == selectedUnitID && !$0.isDestroyed }
    }

    var focusedTile: TerrainTile? {
        guard let focusedCoordinate else { return selectedUnit.flatMap { tile(at: $0.position) } }
        return tile(at: focusedCoordinate)
    }

    var guidedObjectiveTile: TerrainTile? {
        guard let guidedObjectiveCoordinate,
              let tile = tile(at: guidedObjectiveCoordinate),
              tile.isObjective else { return nil }
        return tile
    }

    var focusedUnit: BattleUnit? {
        guard let focusedCoordinate else { return selectedUnit }
        return unit(at: focusedCoordinate)
    }

    var focusedCommandPreview: MapCommandPreview? {
        guard let focusedCoordinate else { return nil }
        return mapCommandPreview(for: focusedCoordinate)
    }

    var focusedMovementRoute: MovementRoute? {
        guard let selectedUnit,
              let focusedCoordinate else { return nil }
        return movementRoute(for: selectedUnit, to: focusedCoordinate)
    }

    var focusedPostMoveAttackOpportunities: [BattleUnit] {
        guard let selectedUnit,
              let route = focusedMovementRoute else { return [] }
        return postMoveAttackOpportunities(for: selectedUnit, to: route.destination)
    }

    var focusedRouteStepPreviews: [RouteStepPreview] {
        guard let selectedUnit else { return [] }
        if let route = focusedMovementRoute {
            return routeStepPreviews(for: selectedUnit, route: route)
        }
        guard let route = focusedAttackPositionRoute else { return [] }
        return routeStepPreviews(for: selectedUnit, route: route)
    }

    var focusedPostMoveAttackPreviews: [PostMoveAttackPreview] {
        guard let selectedUnit,
              let route = focusedMovementRoute else { return [] }
        return postMoveAttackPreviews(for: selectedUnit, to: route.destination)
    }

    var focusedFireExposurePreview: PostMoveFireExposurePreview? {
        guard let selectedUnit else { return nil }
        if let route = focusedMovementRoute {
            return fireExposurePreview(for: selectedUnit, at: route.destination)
        }
        guard let route = focusedAttackPositionRoute else { return nil }
        return fireExposurePreview(for: selectedUnit, at: route.destination)
    }

    var focusedThreatExposurePreview: PostMoveFireExposurePreview? {
        focusedFireExposurePreview
    }

    var focusedObjectiveAdvancePreviews: [ObjectiveAdvancePreview] {
        guard let selectedUnit else { return [] }
        return objectiveAdvancePreviews(for: selectedUnit)
    }

    var focusedAttackPositionRoutes: [MovementRoute] {
        guard let selectedUnit,
              let focusedUnit,
              focusedUnit.faction != selectedUnit.faction,
              !attackableTiles(for: selectedUnit).contains(focusedUnit.position) else { return [] }
        return attackPositionRoutes(for: selectedUnit, against: focusedUnit)
    }

    var focusedAttackPositionRoute: MovementRoute? {
        guard let selectedUnit,
              let focusedUnit,
              focusedUnit.faction != selectedUnit.faction,
              !attackableTiles(for: selectedUnit).contains(focusedUnit.position) else { return nil }
        return preferredAttackPositionRoute(for: selectedUnit, against: focusedUnit)
    }

    var focusedSafeEngagementOptions: [SafeEngagementOption] {
        guard let selectedUnit,
              let focusedUnit,
              focusedUnit.faction != selectedUnit.faction,
              !attackableTiles(for: selectedUnit).contains(focusedUnit.position) else { return [] }
        return safeEngagementOptions(for: selectedUnit, against: focusedUnit)
    }

    var visibleEnemyThreatIntentPreviews: [EnemyThreatIntentPreview] {
        enemyThreatIntentPreviews(against: .allies)
    }

    var visibleEnemyThreatCountermeasurePreviews: [EnemyThreatCountermeasurePreview] {
        enemyThreatCountermeasurePreviews(for: visibleEnemyThreatIntentPreviews)
    }

    var focusedEnemyThreatCountermeasureMapMarkers: [EnemyThreatCountermeasureMapMarker] {
        guard let preview = focusedEnemyThreatCountermeasurePreview,
              isEnemyThreatCountermeasureFocused(preview),
              isEnemyThreatCountermeasureValidForMapMarkers(preview) else { return [] }
        return enemyThreatCountermeasureMapMarkers(for: preview)
    }

    var latestAIPhaseMapMarkers: [AIPhaseMapMarker] {
        guard let timeline = latestAIPhaseSummary?.timeline else { return [] }
        return timeline
            .flatMap(aiPhaseMapMarkers)
            .sorted {
                if $0.eventOrder != $1.eventOrder {
                    return $0.eventOrder < $1.eventOrder
                }
                if $0.role.sortOrder != $1.role.sortOrder {
                    return $0.role.sortOrder < $1.role.sortOrder
                }
                return $0.coordinate.id < $1.coordinate.id
            }
    }

    var focusedEnemyThreatCountermeasureExecutionPreview: EnemyThreatCountermeasureExecutionPreview? {
        guard let preview = focusedEnemyThreatCountermeasurePreview,
              isEnemyThreatCountermeasureFocused(preview) else { return nil }
        return enemyThreatCountermeasureExecutionPreview(for: preview)
    }

    var objectiveTiles: [TerrainTile] {
        scenario.tiles.filter(\.isObjective)
    }

    var alliedScore: Int {
        objectiveTiles.filter { $0.owner == .allies }.count
    }

    var axisScore: Int {
        objectiveTiles.filter { $0.owner == .axis }.count
    }

    var readyUnitCount: Int {
        units.filter { $0.faction == activeFaction && (!$0.hasMoved || !$0.hasAttacked) }.count
    }

    var readyUnits: [BattleUnit] {
        units(for: activeFaction)
            .filter { !$0.hasMoved || !$0.hasAttacked }
    }

    var mapEnemyFocusUnits: [BattleUnit] {
        let anchor = selectedUnit?.position ?? focusedCoordinate ?? scenario.initialFocus
        return units
            .filter { $0.faction != activeFaction }
            .sorted { left, right in
                let leftDistance = anchor.distance(to: left.position)
                let rightDistance = anchor.distance(to: right.position)
                if leftDistance == rightDistance {
                    if left.kind == right.kind {
                        return left.name < right.name
                    }
                    return left.kind.sortOrder < right.kind.sortOrder
                }
                return leftDistance < rightDistance
            }
    }

    var mapFriendlyFocusUnits: [BattleUnit] {
        let anchor = selectedUnit?.position ?? focusedCoordinate ?? scenario.initialFocus
        return units
            .filter { $0.faction == activeFaction }
            .sorted { left, right in
                let leftReady = !left.hasMoved || !left.hasAttacked
                let rightReady = !right.hasMoved || !right.hasAttacked
                if leftReady != rightReady {
                    return leftReady && !rightReady
                }

                let leftDistance = anchor.distance(to: left.position)
                let rightDistance = anchor.distance(to: right.position)
                if leftDistance == rightDistance {
                    if left.kind == right.kind {
                        return left.name < right.name
                    }
                    return left.kind.sortOrder < right.kind.sortOrder
                }
                return leftDistance < rightDistance
            }
    }

    var activeCommandPoints: Int {
        commandPoints[activeFaction, default: 0]
    }

    var alliedStrength: Int {
        strength(for: .allies)
    }

    var axisStrength: Int {
        strength(for: .axis)
    }

    var objectiveProgress: Double {
        guard !objectiveTiles.isEmpty else { return 0 }
        return Double(alliedScore) / Double(objectiveTiles.count)
    }

    var remainingTurns: Int {
        max(0, scenario.turnLimit - turn + 1)
    }

    var missionObjectives: [MissionObjectiveStatus] {
        let primaryComplete = winner == .allies
        let failed = winner == .axis || turn > scenario.turnLimit
        let speedComplete = primaryComplete && turn <= scenario.decisiveTurnLimit
        let speedFailed = failed || turn > scenario.decisiveTurnLimit
        let alliedSurvivors = units.filter { $0.faction == .allies }.count
        let survivalComplete = primaryComplete && alliedSurvivors >= scenario.survivalStarThreshold
        let survivalFailed = failed || (primaryComplete && !survivalComplete)

        return [
            MissionObjectiveStatus(
                id: "primary",
                title: "完成主目标",
                detail: "\(alliedScore)/\(objectiveTiles.count) 据点",
                state: primaryComplete ? .complete : (failed ? .failed : .pending)
            ),
            MissionObjectiveStatus(
                id: "speed",
                title: "\(scenario.decisiveTurnLimit) 回合内获胜",
                detail: "当前第 \(turn) 回合",
                state: speedComplete ? .complete : (speedFailed ? .failed : .pending)
            ),
            MissionObjectiveStatus(
                id: "survival",
                title: "保留 \(scenario.survivalStarThreshold) 支部队",
                detail: "现有 \(alliedSurvivors)",
                state: survivalComplete ? .complete : (survivalFailed ? .failed : .pending)
            )
        ]
    }

    var objectiveCaptureRewardSummary: String {
        "占领/夺取据点：指令 +\(Self.objectiveCaptureCommandReward)，士气 +\(Self.objectiveCaptureMoraleReward)，经验 +\(Self.objectiveCaptureExperienceReward)"
    }

    var objectiveRestSummary: String {
        "据点休整：补给畅通且驻守己方据点的受损单位，回合开始恢复 +\(Self.objectiveRestRecoveryAmount) 耐久"
    }

    var zoneOfControlSummary: String {
        "敌方控制区：进入相邻敌军格额外消耗 +\(Self.enemyControlZoneMovementPenalty) 移动力"
    }

    var entrenchmentSummary: String {
        "待命构筑防御：下一次受击伤害降至 \(Self.entrenchedDamageMultiplierPercent)%"
    }

    var flankingSupportSummary: String {
        "夹击协同：目标相邻的其他友军每支伤害 +\(Self.flankingSupportBonusPercent)%，最高 +\(Self.maxFlankingSupportBonusPercent)%"
    }

    var commanderAuraSummary: String {
        "将领协同：相邻友军由将领指挥时，普通攻击和突破突击伤害 +\(Self.commanderAuraDamageBonusPercent)%"
    }

    var maneuverPursuitSummary: String {
        "机动追击：坦克和侦察未移动时击毁目标，可保留移动继续推进"
    }

    func tile(at coordinate: HexCoordinate) -> TerrainTile? {
        scenario.tiles.first { $0.coordinate == coordinate }
    }

    func unit(at coordinate: HexCoordinate) -> BattleUnit? {
        units.first { $0.position == coordinate }
    }

    func commandPoints(for faction: Faction) -> Int {
        commandPoints[faction, default: 0]
    }

    func selectScenario(id: Scenario.ID) {
        guard let scenario = campaignCatalog.first(where: { $0.id == id }) else { return }
        loadScenario(scenario)
    }

    func units(for faction: Faction) -> [BattleUnit] {
        units
            .filter { $0.faction == faction }
            .sorted { left, right in
                if left.kind == right.kind {
                    return left.name < right.name
                }
                return left.kind.sortOrder < right.kind.sortOrder
            }
    }

    func select(unitID: BattleUnit.ID) {
        guard let unit = units.first(where: { $0.id == unitID }),
              unit.faction == activeFaction else { return }
        clearObjectiveGuidance()
        selectedUnitID = unit.id
        focusedCoordinate = unit.position
        message = unitSelectionMessage(for: unit)
    }

    func focus(unitID: BattleUnit.ID) {
        guard let unit = units.first(where: { $0.id == unitID }) else { return }
        focus(coordinate: unit.position)
    }

    func focus(coordinate: HexCoordinate) {
        clearObjectiveGuidance()
        guard tile(at: coordinate) != nil else {
            focusedCoordinate = coordinate
            message = "地图外区域。"
            return
        }

        focusedCoordinate = coordinate

        if let focusedUnit = unit(at: coordinate) {
            if focusedUnit.faction == activeFaction {
                message = "\(focusedUnit.faction.title)\(focusedUnit.kind.title) \(focusedUnit.name)：耐久 \(focusedUnit.hp)，左键或编队条可选择。"
            } else if selectedUnit != nil,
                      let preview = mapCommandPreview(for: coordinate) {
                message = primaryEnemyPreviewMessage(for: preview, fallbackUnit: focusedUnit)
            } else {
                message = "\(focusedUnit.faction.title)\(focusedUnit.kind.title) \(focusedUnit.name)：耐久 \(focusedUnit.hp)，射程 \(focusedUnit.range)。"
            }
            return
        }

        if let selectedUnit {
            message = primaryTilePreviewMessage(for: selectedUnit, to: coordinate)
        } else {
            message = tileMessage(for: coordinate)
        }
    }

    func selectNextReadyUnitFromMap() {
        guard winner == nil else { return }
        guard let unit = readyUnits.first else {
            selectedUnitID = nil
            message = "\(activeFaction.title)没有待命部队。"
            return
        }

        selectedUnitID = unit.id
        focusedCoordinate = unit.position
        clearObjectiveGuidance()
        message = "快速选择 \(unit.name)。\(unitSelectionMessage(for: unit))"
    }

    func focusNearestAttackTarget() {
        guard winner == nil else { return }
        guard let selectedUnit else {
            selectNextReadyUnitFromMap()
            return
        }

        guard let target = attackableUnits(for: selectedUnit).first else {
            message = "\(selectedUnit.name) 当前射程内没有可攻击目标。"
            return
        }

        focus(unitID: target.id)
    }

    func focusNearestApproachTarget() {
        guard winner == nil else { return }
        guard let selectedUnit else {
            selectNextReadyUnitFromMap()
            return
        }

        guard let target = nearestApproachTarget(for: selectedUnit) else {
            message = "\(selectedUnit.name) 本回合没有可进入的攻击位。"
            return
        }

        focus(unitID: target.id)
    }

    func nearestObjectiveTarget(for unit: BattleUnit) -> TerrainTile? {
        objectiveAdvancePlans(for: unit).first?.tile
    }

    func objectiveAdvanceRoute(for unit: BattleUnit, to objective: TerrainTile) -> MovementRoute? {
        guard objective.isObjective,
              objective.owner != unit.faction,
              self.unit(at: objective.coordinate) == nil else { return nil }

        return objectiveAdvancePlan(
            for: unit,
            objective: objective,
            routes: movementRoutes(for: unit)
        )?.route
    }

    func objectiveAdvancePreviews(for unit: BattleUnit, limit: Int = 3) -> [ObjectiveAdvancePreview] {
        guard limit > 0 else { return [] }
        return objectiveAdvancePlans(for: unit)
            .prefix(limit)
            .map { objectiveAdvancePreview(for: unit, plan: $0) }
    }

    func focusObjectiveAdvancePreview(_ preview: ObjectiveAdvancePreview) {
        focusObjectiveAdvanceTarget(coordinate: preview.coordinate)
    }

    func focusSafeEngagementOption(_ option: SafeEngagementOption) {
        focusSafeEngagement(targetID: option.targetID, destination: option.route.destination)
    }

    func focusEnemyThreatCountermeasure(_ preview: EnemyThreatCountermeasurePreview) {
        guard winner == nil else { return }
        guard let actingUnitID = preview.actingUnitID,
              let actingUnit = units.first(where: {
                  $0.id == actingUnitID &&
                      $0.faction == activeFaction &&
                      !$0.isDestroyed
              }) else {
            clearObjectiveGuidance()
            focusedCoordinate = preview.destination ?? preview.threatTargetCoordinate
            message = "\(preview.actingUnitName) 已不可用，反制建议已过期。"
            return
        }

        selectedUnitID = actingUnit.id

        switch preview.kind {
        case .firstStrike:
            focusFirstStrikeCountermeasure(preview, actingUnit: actingUnit)
        case .withdraw:
            focusWithdrawCountermeasure(preview, actingUnit: actingUnit)
        case .objectiveDefense:
            focusObjectiveDefenseCountermeasure(preview, actingUnit: actingUnit)
        case .reinforce:
            focusReinforceCountermeasure(preview, actingUnit: actingUnit)
        }

        focusedEnemyThreatCountermeasurePreview = isEnemyThreatCountermeasureFocused(preview) ? preview : nil
    }

    func isEnemyThreatCountermeasureFocused(_ preview: EnemyThreatCountermeasurePreview) -> Bool {
        guard selectedUnitID == preview.actingUnitID else { return false }
        switch preview.kind {
        case .firstStrike:
            guard let enemy = units.first(where: { $0.id == preview.threatEnemyUnitID }) else { return false }
            return focusedCoordinate == enemy.position
        case .withdraw:
            return focusedCoordinate == preview.destination && guidedObjectiveCoordinate == nil
        case .objectiveDefense:
            return focusedCoordinate == preview.destination &&
                guidedObjectiveCoordinate == preview.threatTargetCoordinate
        case .reinforce:
            guard let actingUnitID = preview.actingUnitID,
                  let unit = units.first(where: { $0.id == actingUnitID }) else { return false }
            return focusedCoordinate == unit.position && guidedObjectiveCoordinate == nil
        }
    }

    func focusSafeEngagement(targetID: BattleUnit.ID, destination: HexCoordinate) {
        guard winner == nil else { return }
        guard let selectedUnit else {
            selectNextReadyUnitFromMap()
            return
        }

        guard let target = units.first(where: {
            $0.id == targetID &&
                $0.faction != selectedUnit.faction &&
                !$0.isDestroyed
        }) else {
            clearSafeEngagementFocus()
            message = "安全接敌目标已不可用。"
            return
        }

        guard let option = safeEngagementOptions(for: selectedUnit, against: target)
            .first(where: { $0.route.destination == destination }) else {
            clearSafeEngagementFocus()
            focusedCoordinate = target.position
            message = "\(selectedUnit.name) 当前无法切换到 q\(destination.q),r\(destination.r) 接敌位。"
            return
        }

        guidedObjectiveCoordinate = nil
        focusedEnemyThreatCountermeasurePreview = nil
        focusedSafeEngagementTargetID = target.id
        focusedSafeEngagementDestination = option.route.destination
        focusedCoordinate = target.position

        let exposure = option.exposure
        let penaltyText = option.route.controlZonePenalty > 0 ? "，含敌方控制区 +\(option.route.controlZonePenalty)" : ""
        let sourceNames = exposure.sources.prefix(2).map(\.sourceName).joined(separator: "、")
        let sourceText = sourceNames.isEmpty ? "" : "，主要敌火 \(sourceNames)"
        message = "\(selectedUnit.name) 切换安全接敌：先到 q\(option.route.destination.q),r\(option.route.destination.r) 接近 \(target.name)，消耗 \(option.route.totalCost) 移动力\(penaltyText)，终点 \(exposure.riskLevel.shortTitle) 潜在承伤 \(exposure.totalPotentialDamage)\(sourceText)。执行命令后才会移动。"
    }

    private func focusFirstStrikeCountermeasure(
        _ preview: EnemyThreatCountermeasurePreview,
        actingUnit: BattleUnit
    ) {
        clearObjectiveGuidance()
        guard let enemy = units.first(where: {
            $0.id == preview.threatEnemyUnitID &&
                $0.faction != actingUnit.faction &&
                !$0.isDestroyed
        }) else {
            focusedCoordinate = actingUnit.position
            message = "\(preview.threatEnemyUnitName) 已不可用，抢先打击建议已过期。"
            return
        }

        focusedCoordinate = enemy.position
        guard actingUnit.canAttack,
              let combat = combatPreview(attacker: actingUnit, defender: enemy) else {
            message = "\(actingUnit.name) 当前无法执行抢先打击，已聚焦 \(enemy.name)。"
            return
        }

        let outcome = combat.willDestroyDefender ? "可击毁" : "预计造成 \(combat.damage) 伤害"
        message = "\(actingUnit.name) 聚焦抢先打击 \(enemy.name)：\(outcome)。点 ATK 才会攻击。"
    }

    private func focusWithdrawCountermeasure(
        _ preview: EnemyThreatCountermeasurePreview,
        actingUnit: BattleUnit
    ) {
        clearObjectiveGuidance()
        guard let destination = preview.destination else {
            focusedCoordinate = actingUnit.position
            message = "\(actingUnit.name) 的撤退目的地已不可用。"
            return
        }

        guard actingUnit.canMove,
              let route = movementRoute(for: actingUnit, to: destination) else {
            focusedCoordinate = actingUnit.position
            message = "\(actingUnit.name) 当前无法撤至 \(coordinateText(destination))，反制建议已过期。"
            return
        }

        focusedCoordinate = destination
        let penaltyText = route.controlZonePenalty > 0 ? "，含敌方控制区 +\(route.controlZonePenalty)" : ""
        let hpText = preview.projectedFriendlyHPAfterAction.map { "，预计保留 \($0) 耐久" } ?? ""
        message = "\(actingUnit.name) 聚焦撤出危险区：前往 \(coordinateText(destination))，消耗 \(route.totalCost) 移动力\(penaltyText)\(hpText)。点 MOVE 才会移动。"
    }

    private func focusObjectiveDefenseCountermeasure(
        _ preview: EnemyThreatCountermeasurePreview,
        actingUnit: BattleUnit
    ) {
        clearSafeEngagementFocus()
        guard let destination = preview.destination else {
            guidedObjectiveCoordinate = nil
            focusedCoordinate = actingUnit.position
            message = "\(actingUnit.name) 的据点防守目的地已不可用。"
            return
        }

        guard actingUnit.canMove,
              let route = movementRoute(for: actingUnit, to: destination) else {
            guidedObjectiveCoordinate = nil
            focusedCoordinate = actingUnit.position
            message = "\(actingUnit.name) 当前无法前往 \(coordinateText(destination)) 防守 \(preview.targetName)。"
            return
        }

        focusedCoordinate = destination
        guidedObjectiveCoordinate = preview.threatTargetCoordinate
        let reachesObjective = destination == preview.threatTargetCoordinate
        let action = reachesObjective ? "进驻" : "封堵"
        let penaltyText = route.controlZonePenalty > 0 ? "，含敌方控制区 +\(route.controlZonePenalty)" : ""
        message = "\(actingUnit.name) 聚焦据点防守：\(action)\(preview.targetName)，先到 \(coordinateText(destination))，消耗 \(route.totalCost) 移动力\(penaltyText)。点 MOVE 才会移动。"
    }

    private func focusReinforceCountermeasure(
        _ preview: EnemyThreatCountermeasurePreview,
        actingUnit: BattleUnit
    ) {
        clearObjectiveGuidance()
        focusedCoordinate = actingUnit.position
        guard canReinforce(actingUnit) else {
            message = "\(actingUnit.name) 当前不满足整补条件，反制建议已过期。"
            return
        }

        let recoveredHP = min(actingUnit.kind.reinforceAmount, actingUnit.maxHP - actingUnit.hp)
        let cost = reinforceCost(for: actingUnit)
        message = "\(actingUnit.name) 聚焦整补支撑：可恢复 \(recoveredHP) 耐久，消耗 \(cost) 指令点。点整补才会执行。"
    }

    private func enemyThreatCountermeasureMapMarkers(
        for preview: EnemyThreatCountermeasurePreview
    ) -> [EnemyThreatCountermeasureMapMarker] {
        var markers: [EnemyThreatCountermeasureMapMarker] = []

        if let actingUnitID = preview.actingUnitID,
           let actingUnit = units.first(where: { $0.id == actingUnitID && !$0.isDestroyed }) {
            markers.append(
                EnemyThreatCountermeasureMapMarker(
                    role: .actingUnit,
                    coordinate: actingUnit.position,
                    countermeasureKind: preview.kind
                )
            )
        }

        if let enemy = units.first(where: { $0.id == preview.threatEnemyUnitID && !$0.isDestroyed }) {
            markers.append(
                EnemyThreatCountermeasureMapMarker(
                    role: .threatSource,
                    coordinate: enemy.position,
                    countermeasureKind: preview.kind
                )
            )

            if preview.kind == .firstStrike {
                markers.append(
                    EnemyThreatCountermeasureMapMarker(
                        role: .counterTarget,
                        coordinate: enemy.position,
                        countermeasureKind: preview.kind
                    )
                )
            }
        }

        if let destination = preview.destination {
            markers.append(
                EnemyThreatCountermeasureMapMarker(
                    role: .counterTarget,
                    coordinate: destination,
                    countermeasureKind: preview.kind
                )
            )
        }

        markers.append(
            EnemyThreatCountermeasureMapMarker(
                role: .threatenedTarget,
                coordinate: preview.threatTargetCoordinate,
                countermeasureKind: preview.kind
            )
        )

        return markers
    }

    private func aiPhaseMapMarkers(for event: AIPhaseTimelineEvent) -> [AIPhaseMapMarker] {
        func marker(role: AIPhaseMapMarkerRole, coordinate: HexCoordinate) -> AIPhaseMapMarker {
            AIPhaseMapMarker(
                faction: event.faction,
                turn: event.turn,
                eventOrder: event.order,
                eventKind: event.kind,
                role: role,
                coordinate: coordinate,
                shortCode: event.shortCode,
                summary: event.summary
            )
        }

        switch event.kind {
        case .move:
            var markers: [AIPhaseMapMarker] = []
            if let origin = event.from {
                markers.append(marker(role: .origin, coordinate: origin))
            }
            if let destination = event.to {
                markers.append(marker(role: .destination, coordinate: destination))
            }
            return markers
        case .attack, .tacticalCommand:
            var markers: [AIPhaseMapMarker] = []
            if let actorCoordinate = event.from {
                markers.append(marker(role: .actor, coordinate: actorCoordinate))
            }
            if let targetCoordinate = event.to {
                markers.append(marker(role: .target, coordinate: targetCoordinate))
            }
            return markers
        case .deployment, .reinforcement:
            guard let coordinate = event.to else { return [] }
            return [marker(role: .destination, coordinate: coordinate)]
        case .objectiveCapture:
            guard let coordinate = event.to else { return [] }
            return [marker(role: .objective, coordinate: coordinate)]
        }
    }

    private func isEnemyThreatCountermeasureValidForMapMarkers(
        _ preview: EnemyThreatCountermeasurePreview
    ) -> Bool {
        guard let actingUnitID = preview.actingUnitID,
              let actingUnit = units.first(where: {
                  $0.id == actingUnitID &&
                      $0.faction == activeFaction &&
                      !$0.isDestroyed
              }) else { return false }

        switch preview.kind {
        case .firstStrike:
            guard let enemy = units.first(where: {
                $0.id == preview.threatEnemyUnitID &&
                    $0.faction != actingUnit.faction &&
                    !$0.isDestroyed
            }) else { return false }
            return actingUnit.canAttack && combatPreview(attacker: actingUnit, defender: enemy) != nil
        case .withdraw, .objectiveDefense:
            guard let destination = preview.destination else { return false }
            return actingUnit.canMove && movementRoute(for: actingUnit, to: destination) != nil
        case .reinforce:
            return canReinforce(actingUnit)
        }
    }

    private func enemyThreatCountermeasureExecutionPreview(
        for preview: EnemyThreatCountermeasurePreview
    ) -> EnemyThreatCountermeasureExecutionPreview {
        guard let actingUnitID = preview.actingUnitID,
              let actingUnit = units.first(where: {
                  $0.id == actingUnitID &&
                      $0.faction == activeFaction &&
                      !$0.isDestroyed
              }) else {
            return unavailableCountermeasureExecutionPreview(
                for: preview,
                unitName: preview.actingUnitName,
                targetName: preview.targetName,
                coordinate: preview.destination ?? preview.threatTargetCoordinate,
                reason: "\(preview.actingUnitName) 已不可用，无法连接执行入口。"
            )
        }

        switch preview.kind {
        case .firstStrike:
            return firstStrikeExecutionPreview(for: preview, actingUnit: actingUnit)
        case .withdraw:
            return movementExecutionPreview(
                for: preview,
                actingUnit: actingUnit,
                actionTitle: "撤出危险区",
                unavailableReason: "\(actingUnit.name) 当前无法撤至该目的地。"
            )
        case .objectiveDefense:
            return movementExecutionPreview(
                for: preview,
                actingUnit: actingUnit,
                actionTitle: "据点防守",
                unavailableReason: "\(actingUnit.name) 当前无法前往防守目的地。"
            )
        case .reinforce:
            return reinforceExecutionPreview(for: preview, actingUnit: actingUnit)
        }
    }

    private func firstStrikeExecutionPreview(
        for preview: EnemyThreatCountermeasurePreview,
        actingUnit: BattleUnit
    ) -> EnemyThreatCountermeasureExecutionPreview {
        guard let enemy = units.first(where: {
            $0.id == preview.threatEnemyUnitID &&
                $0.faction != actingUnit.faction &&
                !$0.isDestroyed
        }) else {
            return unavailableCountermeasureExecutionPreview(
                for: preview,
                unitName: actingUnit.name,
                targetName: preview.threatEnemyUnitName,
                coordinate: actingUnit.position,
                reason: "\(preview.threatEnemyUnitName) 已不可用，无法连接 ATK。"
            )
        }

        guard actingUnit.canAttack,
              combatPreview(attacker: actingUnit, defender: enemy) != nil,
              let commandPreview = mapCommandPreview(for: enemy.position),
              case .attack = commandPreview,
              commandPreview.isExecutable else {
            return unavailableCountermeasureExecutionPreview(
                for: preview,
                unitName: actingUnit.name,
                targetName: enemy.name,
                coordinate: enemy.position,
                reason: "\(actingUnit.name) 当前无法用地图 ATK 执行抢先打击。"
            )
        }

        return EnemyThreatCountermeasureExecutionPreview(
            kind: .attack,
            countermeasureKind: preview.kind,
            actionTitle: "抢先打击",
            entryTitle: "点地图 ATK 或执行按钮",
            coordinate: enemy.position,
            unitName: actingUnit.name,
            targetName: enemy.name,
            isExecutable: true,
            reason: "聚焦敌军后通过现有攻击入口执行，不会由建议行自动攻击。"
        )
    }

    private func movementExecutionPreview(
        for preview: EnemyThreatCountermeasurePreview,
        actingUnit: BattleUnit,
        actionTitle: String,
        unavailableReason: String
    ) -> EnemyThreatCountermeasureExecutionPreview {
        guard let destination = preview.destination else {
            return unavailableCountermeasureExecutionPreview(
                for: preview,
                unitName: actingUnit.name,
                targetName: preview.targetName,
                coordinate: actingUnit.position,
                reason: "\(actingUnit.name) 的目的地已不可用，无法连接 MOVE。"
            )
        }

        guard actingUnit.canMove,
              movementRoute(for: actingUnit, to: destination) != nil,
              let commandPreview = mapCommandPreview(for: destination),
              case .move = commandPreview,
              commandPreview.isExecutable else {
            return unavailableCountermeasureExecutionPreview(
                for: preview,
                unitName: actingUnit.name,
                targetName: preview.targetName,
                coordinate: destination,
                reason: unavailableReason
            )
        }

        return EnemyThreatCountermeasureExecutionPreview(
            kind: .move,
            countermeasureKind: preview.kind,
            actionTitle: actionTitle,
            entryTitle: "点地图 MOVE 或执行按钮",
            coordinate: destination,
            unitName: actingUnit.name,
            targetName: preview.targetName,
            isExecutable: true,
            reason: "聚焦目的格后通过现有移动入口执行，不会由建议行自动移动。"
        )
    }

    private func reinforceExecutionPreview(
        for preview: EnemyThreatCountermeasurePreview,
        actingUnit: BattleUnit
    ) -> EnemyThreatCountermeasureExecutionPreview {
        guard canReinforce(actingUnit) else {
            return unavailableCountermeasureExecutionPreview(
                for: preview,
                unitName: actingUnit.name,
                targetName: preview.targetName,
                coordinate: actingUnit.position,
                reason: "\(actingUnit.name) 当前不满足整补条件。"
            )
        }

        return EnemyThreatCountermeasureExecutionPreview(
            kind: .reinforce,
            countermeasureKind: preview.kind,
            actionTitle: "整补支撑",
            entryTitle: "使用单位详情整补按钮",
            coordinate: actingUnit.position,
            unitName: actingUnit.name,
            targetName: preview.targetName,
            isExecutable: true,
            reason: "聚焦单位后通过既有整补按钮执行，不会由建议行自动整补。"
        )
    }

    private func unavailableCountermeasureExecutionPreview(
        for preview: EnemyThreatCountermeasurePreview,
        unitName: String,
        targetName: String,
        coordinate: HexCoordinate?,
        reason: String
    ) -> EnemyThreatCountermeasureExecutionPreview {
        EnemyThreatCountermeasureExecutionPreview(
            kind: .unavailable,
            countermeasureKind: preview.kind,
            actionTitle: preview.kind.title,
            entryTitle: "入口暂不可用",
            coordinate: coordinate,
            unitName: unitName,
            targetName: targetName,
            isExecutable: false,
            reason: reason
        )
    }

    private func focusedEnemyThreatCountermeasureForExecution(
        kind: EnemyThreatCountermeasureKind? = nil,
        executionKind: EnemyThreatCountermeasureExecutionKind,
        coordinate: HexCoordinate? = nil
    ) -> EnemyThreatCountermeasurePreview? {
        guard let preview = focusedEnemyThreatCountermeasurePreview,
              isEnemyThreatCountermeasureFocused(preview) else { return nil }
        if let kind, preview.kind != kind { return nil }

        let executionPreview = enemyThreatCountermeasureExecutionPreview(for: preview)
        guard executionPreview.isExecutable,
              executionPreview.kind == executionKind else { return nil }
        if let coordinate, executionPreview.coordinate != coordinate { return nil }
        return preview
    }

    private func publishCountermeasureAttackExecutionResult(
        for preview: EnemyThreatCountermeasurePreview
    ) {
        guard preview.kind == .firstStrike,
              let combatResult = latestCombatResult else { return }

        let enemyCoordinate = scenario.units.first { $0.id == preview.threatEnemyUnitID }?.position
        let expectedEnemyHP = preview.willDestroyEnemy ?
            "击毁" :
            preview.projectedEnemyHPAfterDamage.map { "HP \($0)" } ?? "压制"
        let actualEnemyHP = combatResult.didDestroyDefender ?
            "击毁" :
            "HP \(combatResult.defender.endingHP)"

        var comparisons: [EnemyThreatCountermeasureExecutionResultComparison] = [
            EnemyThreatCountermeasureExecutionResultComparison(
                kind: .damage,
                title: "伤害",
                expected: "-\(preview.projectedDamage)",
                actual: "-\(combatResult.damage)",
                result: combatResult.damage == preview.projectedDamage ? "符合预期" : "伤害偏差"
            ),
            EnemyThreatCountermeasureExecutionResultComparison(
                kind: .enemyHP,
                title: "敌耐久",
                expected: expectedEnemyHP,
                actual: actualEnemyHP,
                result: combatResult.didDestroyDefender == preview.willDestroyEnemy ? "符合预期" : "击毁结果偏差"
            )
        ]

        if let projectedFriendlyHPAfterAction = preview.projectedFriendlyHPAfterAction {
            comparisons.append(
                EnemyThreatCountermeasureExecutionResultComparison(
                    kind: .survival,
                    title: "执行单位",
                    expected: "HP \(projectedFriendlyHPAfterAction)",
                    actual: "HP \(combatResult.attacker.endingHP)",
                    result: combatResult.attacker.endingHP == projectedFriendlyHPAfterAction ? "符合预期" : "反击后耐久偏差"
                )
            )
        }

        latestEnemyThreatCountermeasureFollowUpResult = nil
        latestEnemyThreatCountermeasureExecutionResult = countermeasureExecutionResultSummary(
            for: preview,
            executionKind: .attack,
            coordinate: enemyCoordinate,
            comparisons: comparisons
        )
    }

    private func publishCountermeasureMoveExecutionResult(
        for preview: EnemyThreatCountermeasurePreview,
        route: MovementRoute
    ) {
        guard preview.kind == .withdraw || preview.kind == .objectiveDefense,
              let actingUnitID = preview.actingUnitID,
              let movedUnit = scenario.units.first(where: { $0.id == actingUnitID }) else { return }

        let expectedDestination = preview.destination.map(coordinateText) ?? "未知"
        let actualDestination = coordinateText(movedUnit.position)
        var comparisons: [EnemyThreatCountermeasureExecutionResultComparison] = [
            EnemyThreatCountermeasureExecutionResultComparison(
                kind: .route,
                title: "位置",
                expected: expectedDestination,
                actual: actualDestination,
                result: movedUnit.position == preview.destination ? "到位" : "位置偏差"
            )
        ]

        if preview.kind == .withdraw {
            if let projectedFriendlyHPAfterAction = preview.projectedFriendlyHPAfterAction {
                comparisons.append(
                    EnemyThreatCountermeasureExecutionResultComparison(
                        kind: .survival,
                        title: "耐久",
                        expected: "威胁后 HP \(projectedFriendlyHPAfterAction)",
                        actual: "当前 HP \(movedUnit.hp)",
                        result: "已撤离，待敌方回合验证"
                    )
                )
            }
        } else {
            let expectedAction = preview.destination == preview.threatTargetCoordinate ? "进驻" : "封堵"
            let actualAction = movedUnit.position == preview.threatTargetCoordinate ? "进驻" :
                (movedUnit.position.distance(to: preview.threatTargetCoordinate) <= 1 ? "封堵" : "未到位")
            let objectiveOwner = tile(at: preview.threatTargetCoordinate)?.owner?.title ?? "中立"
            comparisons.append(
                EnemyThreatCountermeasureExecutionResultComparison(
                    kind: .objective,
                    title: "守点",
                    expected: expectedAction,
                    actual: "\(actualAction) · \(objectiveOwner)",
                    result: actualAction == expectedAction ? "\(expectedAction)\(preview.targetName)" : "守点位置偏差"
                )
            )
        }

        comparisons.append(
            EnemyThreatCountermeasureExecutionResultComparison(
                kind: .route,
                title: "路线",
                expected: preview.routeCost.map { "\($0)" } ?? "\(route.totalCost)",
                actual: "\(route.totalCost)",
                result: preview.routeCost == route.totalCost ? "符合预期" : "路线消耗偏差"
            )
        )

        latestEnemyThreatCountermeasureFollowUpResult = nil
        latestEnemyThreatCountermeasureExecutionResult = countermeasureExecutionResultSummary(
            for: preview,
            executionKind: .move,
            coordinate: movedUnit.position,
            comparisons: comparisons
        )
    }

    private func publishCountermeasureReinforceExecutionResult(
        for preview: EnemyThreatCountermeasurePreview
    ) {
        guard preview.kind == .reinforce,
              let reinforcementResult = latestReinforcementResult else { return }

        let comparisons = [
            EnemyThreatCountermeasureExecutionResultComparison(
                kind: .recovery,
                title: "恢复",
                expected: "+\(preview.projectedRecoveredHP)",
                actual: "+\(reinforcementResult.recoveredHP)",
                result: reinforcementResult.recoveredHP == preview.projectedRecoveredHP ? "符合预期" : "恢复量偏差"
            ),
            EnemyThreatCountermeasureExecutionResultComparison(
                kind: .survival,
                title: "整补后",
                expected: preview.projectedFriendlyHPAfterAction.map { "HP \($0)" } ?? "HP --",
                actual: "HP \(reinforcementResult.endingHP)",
                result: reinforcementResult.endingHP == preview.projectedFriendlyHPAfterAction ? "符合预期" : "整补后耐久偏差"
            )
        ]

        latestEnemyThreatCountermeasureFollowUpResult = nil
        latestEnemyThreatCountermeasureExecutionResult = countermeasureExecutionResultSummary(
            for: preview,
            executionKind: .reinforce,
            coordinate: reinforcementResult.coordinate,
            comparisons: comparisons
        )
    }

    private func countermeasureExecutionResultSummary(
        for preview: EnemyThreatCountermeasurePreview,
        executionKind: EnemyThreatCountermeasureExecutionKind,
        coordinate: HexCoordinate?,
        comparisons: [EnemyThreatCountermeasureExecutionResultComparison]
    ) -> EnemyThreatCountermeasureExecutionResultSummary {
        EnemyThreatCountermeasureExecutionResultSummary(
            countermeasureID: preview.id,
            countermeasureKind: preview.kind,
            executionKind: executionKind,
            actingUnitID: preview.actingUnitID,
            targetUnitID: preview.targetUnitID,
            threatEnemyUnitID: preview.threatEnemyUnitID,
            actingUnitName: preview.actingUnitName,
            targetName: preview.targetName,
            threatEnemyUnitName: preview.threatEnemyUnitName,
            coordinate: coordinate,
            threatTargetCoordinate: preview.threatTargetCoordinate,
            expectedSummary: preview.impactSummary,
            comparisons: comparisons
        )
    }

    private func prepareEnemyThreatCountermeasureFollowUpBaseline() {
        guard let execution = latestEnemyThreatCountermeasureExecutionResult else {
            pendingEnemyThreatCountermeasureFollowUpBaseline = nil
            latestEnemyThreatCountermeasureFollowUpResult = nil
            return
        }

        pendingEnemyThreatCountermeasureFollowUpBaseline = EnemyThreatCountermeasureFollowUpBaseline(
            execution: execution,
            actingUnit: countermeasureFollowUpSnapshot(for: execution.actingUnitID),
            targetUnit: countermeasureFollowUpSnapshot(for: execution.targetUnitID),
            threatEnemyUnit: countermeasureFollowUpSnapshot(for: execution.threatEnemyUnitID),
            objectiveOwner: tile(at: execution.threatTargetCoordinate)?.owner
        )
        latestEnemyThreatCountermeasureFollowUpResult = nil
    }

    private func publishEnemyThreatCountermeasureFollowUpResultIfNeeded() {
        guard let baseline = pendingEnemyThreatCountermeasureFollowUpBaseline,
              let aiSummary = latestAIPhaseSummary else {
            pendingEnemyThreatCountermeasureFollowUpBaseline = nil
            return
        }

        latestEnemyThreatCountermeasureFollowUpResult = countermeasureFollowUpSummary(
            from: baseline,
            aiSummary: aiSummary
        )
        pendingEnemyThreatCountermeasureFollowUpBaseline = nil
    }

    private func countermeasureFollowUpSnapshot(
        for unitID: BattleUnit.ID?
    ) -> EnemyThreatCountermeasureFollowUpUnitSnapshot? {
        guard let unitID,
              let unit = scenario.units.first(where: { $0.id == unitID }) else { return nil }
        return EnemyThreatCountermeasureFollowUpUnitSnapshot(
            id: unit.id,
            name: unit.name,
            hp: max(0, unit.hp),
            maxHP: unit.maxHP,
            position: unit.position
        )
    }

    private func countermeasureFollowUpSummary(
        from baseline: EnemyThreatCountermeasureFollowUpBaseline,
        aiSummary: AIPhaseSummary
    ) -> EnemyThreatCountermeasureFollowUpSummary {
        let outcome = countermeasureFollowUpOutcome(from: baseline, aiSummary: aiSummary)
        let execution = baseline.execution
        return EnemyThreatCountermeasureFollowUpSummary(
            countermeasureID: execution.countermeasureID,
            countermeasureKind: execution.countermeasureKind,
            executionKind: execution.executionKind,
            actingUnitID: execution.actingUnitID,
            targetUnitID: execution.targetUnitID,
            threatEnemyUnitID: execution.threatEnemyUnitID,
            actingUnitName: execution.actingUnitName,
            targetName: execution.targetName,
            threatEnemyUnitName: execution.threatEnemyUnitName,
            coordinate: execution.coordinate,
            threatTargetCoordinate: execution.threatTargetCoordinate,
            aiFaction: aiSummary.faction,
            aiTurn: aiSummary.turn,
            conclusion: outcome.conclusion,
            comparisons: outcome.comparisons
        )
    }

    private func countermeasureFollowUpOutcome(
        from baseline: EnemyThreatCountermeasureFollowUpBaseline,
        aiSummary: AIPhaseSummary
    ) -> (conclusion: String, comparisons: [EnemyThreatCountermeasureFollowUpComparison]) {
        let execution = baseline.execution
        let threatAfter = currentUnit(matching: baseline.threatEnemyUnit)
        let trackedBefore = baseline.targetUnit ?? baseline.actingUnit
        let trackedAfter = currentUnit(matching: trackedBefore)
        let actingAfter = currentUnit(matching: baseline.actingUnit)
        let objectiveOwnerAfter = tile(at: execution.threatTargetCoordinate)?.owner
        var comparisons: [EnemyThreatCountermeasureFollowUpComparison]
        let conclusion: String

        switch execution.countermeasureKind {
        case .firstStrike:
            comparisons = [
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .enemyHP,
                    title: "威胁源",
                    beforeEnemyPhase: followUpStatusText(baseline.threatEnemyUnit),
                    afterEnemyPhase: followUpStatusText(threatAfter),
                    result: threatAfter?.isDestroyed == false ? "威胁源仍在" : "威胁源已解除"
                ),
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .survival,
                    title: "受威胁目标",
                    beforeEnemyPhase: followUpStatusText(trackedBefore),
                    afterEnemyPhase: followUpStatusText(trackedAfter),
                    result: followUpSurvivalResult(before: trackedBefore, after: trackedAfter)
                )
            ]
            if threatAfter?.isDestroyed != false {
                conclusion = "抢先打击后，原威胁来源已解除。"
            } else if trackedAfter?.isDestroyed == false {
                conclusion = "抢先打击后，目标仍存活，原威胁仍需关注。"
            } else {
                conclusion = "抢先打击后，目标未能撑过敌方回合。"
            }
        case .withdraw:
            let reachResult = followUpThreatReachResult(threat: threatAfter, target: trackedAfter)
            comparisons = [
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .position,
                    title: "撤离位置",
                    beforeEnemyPhase: followUpStatusText(trackedBefore),
                    afterEnemyPhase: followUpStatusText(trackedAfter),
                    result: reachResult
                ),
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .survival,
                    title: "撤离单位",
                    beforeEnemyPhase: followUpStatusText(trackedBefore),
                    afterEnemyPhase: followUpStatusText(trackedAfter),
                    result: followUpSurvivalResult(before: trackedBefore, after: trackedAfter)
                )
            ]
            if trackedAfter?.isDestroyed == false && reachResult != "仍在原威胁射程" {
                conclusion = "撤离后，目标存活并避开原威胁直接覆盖。"
            } else if trackedAfter?.isDestroyed == false {
                conclusion = "撤离后，目标仍存活，但原威胁仍可能覆盖。"
            } else {
                conclusion = "撤离后，目标未能撑过敌方回合。"
            }
        case .objectiveDefense:
            let ownerResult = objectiveOwnerAfter == .allies ? "据点守住" :
                (objectiveOwnerAfter == .axis ? "据点失守" : "据点未被敌军占领")
            comparisons = [
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .objective,
                    title: "据点归属",
                    beforeEnemyPhase: ownerText(baseline.objectiveOwner),
                    afterEnemyPhase: ownerText(objectiveOwnerAfter),
                    result: ownerResult
                ),
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .survival,
                    title: "防守单位",
                    beforeEnemyPhase: followUpStatusText(baseline.actingUnit),
                    afterEnemyPhase: followUpStatusText(actingAfter),
                    result: followUpSurvivalResult(before: baseline.actingUnit, after: actingAfter)
                )
            ]
            conclusion = objectiveOwnerAfter == .allies ?
                "据点防守后，目标据点仍由盟军控制。" :
                "据点防守后，目标据点归属已变化。"
        case .reinforce:
            comparisons = [
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .recovery,
                    title: "整补单位",
                    beforeEnemyPhase: followUpStatusText(trackedBefore),
                    afterEnemyPhase: followUpStatusText(trackedAfter),
                    result: followUpSurvivalResult(before: trackedBefore, after: trackedAfter)
                ),
                EnemyThreatCountermeasureFollowUpComparison(
                    kind: .enemyHP,
                    title: "威胁源",
                    beforeEnemyPhase: followUpStatusText(baseline.threatEnemyUnit),
                    afterEnemyPhase: followUpStatusText(threatAfter),
                    result: followUpThreatReachResult(threat: threatAfter, target: trackedAfter)
                )
            ]
            if trackedAfter?.isDestroyed == false {
                conclusion = "整补后，目标单位撑过敌方回合。"
            } else {
                conclusion = "整补后，目标单位仍被敌方回合击毁。"
            }
        }

        comparisons.append(
            EnemyThreatCountermeasureFollowUpComparison(
                kind: .aiImpact,
                title: "AI总览",
                beforeEnemyPhase: "待验证",
                afterEnemyPhase: "\(aiSummary.totalActions) 行动，伤害 \(aiSummary.damageDealt)",
                result: aiSummary.objectivesCaptured > 0 ?
                    "敌军夺取 \(aiSummary.objectivesCaptured) 据点" :
                    "敌方回合结束"
            )
        )

        return (conclusion, comparisons)
    }

    private func currentUnit(
        matching snapshot: EnemyThreatCountermeasureFollowUpUnitSnapshot?
    ) -> BattleUnit? {
        guard let snapshot else { return nil }
        return scenario.units.first { $0.id == snapshot.id }
    }

    private func followUpStatusText(
        _ snapshot: EnemyThreatCountermeasureFollowUpUnitSnapshot?
    ) -> String {
        guard let snapshot else { return "无记录" }
        if snapshot.isDestroyed {
            return "已被击毁"
        }
        return "HP \(snapshot.hp) @ \(coordinateText(snapshot.position))"
    }

    private func followUpStatusText(_ unit: BattleUnit?) -> String {
        guard let unit else { return "不存在" }
        if unit.isDestroyed {
            return "已被击毁"
        }
        return "HP \(max(0, unit.hp)) @ \(coordinateText(unit.position))"
    }

    private func followUpSurvivalResult(
        before: EnemyThreatCountermeasureFollowUpUnitSnapshot?,
        after: BattleUnit?
    ) -> String {
        guard let after else { return "目标不存在" }
        if after.isDestroyed {
            return "已被击毁"
        }
        guard let before else { return "仍存活" }
        let delta = max(0, after.hp) - before.hp
        if delta < 0 {
            return "损失 \(abs(delta)) HP"
        }
        if delta > 0 {
            return "恢复 +\(delta) HP"
        }
        return "HP 保持"
    }

    private func followUpThreatReachResult(threat: BattleUnit?, target: BattleUnit?) -> String {
        guard let threat, !threat.isDestroyed else { return "威胁源已解除" }
        guard let target, !target.isDestroyed else { return "目标已被击毁" }
        return threat.position.distance(to: target.position) <= threat.range ?
            "仍在原威胁射程" :
            "避开原威胁射程"
    }

    private func ownerText(_ owner: Faction?) -> String {
        owner?.title ?? "中立"
    }

    func focusObjectiveAdvanceTarget(coordinate: HexCoordinate) {
        guard winner == nil else { return }
        guard let selectedUnit else {
            selectNextReadyUnitFromMap()
            return
        }

        guard let plan = objectiveAdvancePlans(for: selectedUnit).first(where: { $0.tile.coordinate == coordinate }) else {
            clearObjectiveGuidance()
            focusedCoordinate = selectedUnit.position
            let objectiveName = tile(at: coordinate)?.objectiveName ?? "该目标"
            message = "\(selectedUnit.name) 当前无法推进 \(objectiveName)。"
            return
        }

        focusObjectiveAdvancePlan(plan, for: selectedUnit)
    }

    func focusNearestObjectiveTarget() {
        guard winner == nil else { return }
        guard let selectedUnit else {
            selectNextReadyUnitFromMap()
            return
        }

        guard let plan = objectiveAdvancePlans(for: selectedUnit).first else {
            clearObjectiveGuidance()
            focusedCoordinate = selectedUnit.position
            message = "\(selectedUnit.name) 本回合没有可推进的空置目标据点。"
            return
        }

        focusObjectiveAdvancePlan(plan, for: selectedUnit)
    }

    private func focusObjectiveAdvancePlan(_ plan: ObjectiveAdvancePlan, for unit: BattleUnit) {
        clearSafeEngagementFocus()
        let objectiveName = plan.tile.objectiveName ?? "目标据点"
        let ownerText = plan.tile.owner?.title ?? "中立"
        let penaltyText = plan.route.controlZonePenalty > 0 ? "，含敌方控制区 +\(plan.route.controlZonePenalty)" : ""

        if plan.reachesObjective {
            focusedCoordinate = plan.tile.coordinate
            guidedObjectiveCoordinate = plan.tile.coordinate
            let action = plan.tile.owner == nil ? "占领" : "夺取"
            message = "\(unit.name) 可\(action)\(objectiveName)（\(ownerText)），执行 MOVE 消耗 \(plan.route.totalCost) 移动力\(penaltyText)。"
        } else {
            focusedCoordinate = plan.route.destination
            guidedObjectiveCoordinate = plan.tile.coordinate
            message = "\(unit.name) 向\(objectiveName)（\(ownerText)）推进：先到 q\(plan.route.destination.q),r\(plan.route.destination.r)，消耗 \(plan.route.totalCost) 移动力\(penaltyText)，距目标剩 \(plan.remainingDistance) 格。"
        }
    }

    func combatPreview(attacker: BattleUnit, defender: BattleUnit) -> CombatPreview? {
        guard attacker.faction != defender.faction,
              !attacker.isDestroyed,
              !defender.isDestroyed,
              attacker.position.distance(to: defender.position) <= attacker.range else { return nil }

        let supportUnits = flankingSupportUnits(attacker: attacker, defender: defender)
        let supportBonus = flankingSupportDamageBonusPercent(forSupportCount: supportUnits.count)
        let damage = damageValue(attacker: attacker, defender: defender)
        let defenderHPAfterAttack = max(0, defender.hp - damage)
        let counterDamage: Int
        let attackerHPAfterCounter: Int

        if defenderHPAfterAttack > 0,
           defender.position.distance(to: attacker.position) <= defender.range {
            counterDamage = counterDamageValue(defender: defender, attacker: attacker)
            attackerHPAfterCounter = max(0, attacker.hp - counterDamage)
        } else {
            counterDamage = 0
            attackerHPAfterCounter = attacker.hp
        }

        return CombatPreview(
            attackerName: attacker.name,
            defenderName: defender.name,
            damage: damage,
            counterDamage: counterDamage,
            matchupMultiplierPercent: matchupAttackMultiplier(attacker: attacker, defender: defender),
            defenderTerrainName: tile(at: defender.position)?.terrain.title ?? "未知地形",
            terrainAttackMultiplierPercent: terrainAttackMultiplier(attacker: attacker, defender: defender),
            terrainDefenseBonus: tile(at: defender.position)?.terrain.defenseBonus ?? 0,
            commanderSupportName: commanderSupport(attacker: attacker)?.name,
            commanderSupportBonusPercent: commanderAuraDamageBonusPercent(attacker: attacker),
            supportUnitCount: supportUnits.count,
            supportDamageBonusPercent: supportBonus,
            defenderIsEntrenched: defender.isEntrenched,
            defenseMultiplierPercent: defenseDamageMultiplierPercent(for: defender),
            defenderHPAfterAttack: defenderHPAfterAttack,
            attackerHPAfterCounter: attackerHPAfterCounter,
            willDestroyDefender: defenderHPAfterAttack == 0,
            willLoseAttacker: attackerHPAfterCounter == 0
        )
    }

    func combatPreviewAgainstFocusedTarget() -> CombatPreview? {
        guard let attacker = selectedUnit,
              let defender = focusedUnit,
              attacker.faction != defender.faction,
              attackableTiles(for: attacker).contains(defender.position) else { return nil }
        return combatPreview(attacker: attacker, defender: defender)
    }

    func canUseTacticalCommand(_ command: TacticalCommand, with unit: BattleUnit) -> Bool {
        guard winner == nil,
              unit.faction == activeFaction,
              !unit.isDestroyed,
              command.canBeUsed(by: unit.kind),
              !unit.hasAttacked,
              activeCommandPoints >= command.commandCost else { return false }
        return !tacticalCommandTargets(for: unit, command: command).isEmpty
    }

    func tacticalCommandTargets(for unit: BattleUnit, command: TacticalCommand) -> [BattleUnit] {
        guard unit.faction == activeFaction,
              !unit.isDestroyed,
              command.canBeUsed(by: unit.kind),
              !unit.hasAttacked else { return [] }

        return units
            .filter { target in
                target.faction != unit.faction &&
                !target.isDestroyed &&
                unit.position.distance(to: target.position) <= command.range
            }
            .sorted { left, right in
                let leftDistance = unit.position.distance(to: left.position)
                let rightDistance = unit.position.distance(to: right.position)
                if leftDistance == rightDistance {
                    return left.hp < right.hp
                }
                return leftDistance < rightDistance
            }
    }

    func tacticalCommandPreview(command: TacticalCommand, caster: BattleUnit, target: BattleUnit) -> TacticalCommandPreview? {
        guard caster.faction != target.faction,
              !caster.isDestroyed,
              !target.isDestroyed,
              command.canBeUsed(by: caster.kind),
              caster.position.distance(to: target.position) <= command.range else { return nil }

        let damage = tacticalCommandDamage(command: command, caster: caster, target: target)
        let hpAfterCommand = max(0, target.hp - damage)
        return TacticalCommandPreview(
            command: command,
            casterName: caster.name,
            targetName: target.name,
            commandCost: command.commandCost,
            range: command.range,
            damage: damage,
            targetHPAfterCommand: hpAfterCommand,
            moraleDamage: command.moraleDamage,
            targetIsEntrenched: target.isEntrenched,
            defenseMultiplierPercent: defenseDamageMultiplierPercent(for: target),
            statusEffect: command.statusEffect,
            willDestroyTarget: hpAfterCommand == 0
        )
    }

    func useTacticalCommand(_ command: TacticalCommand, casterID: BattleUnit.ID, targetID: BattleUnit.ID) {
        guard winner == nil,
              let casterIndex = scenario.units.firstIndex(where: { $0.id == casterID }),
              let targetIndex = scenario.units.firstIndex(where: { $0.id == targetID }) else { return }

        let caster = scenario.units[casterIndex]
        let target = scenario.units[targetIndex]
        guard caster.faction == activeFaction,
              !caster.hasAttacked,
              activeCommandPoints >= command.commandCost,
              tacticalCommandPreview(command: command, caster: caster, target: target) != nil else {
            message = "无法执行\(command.title)。"
            return
        }

        clearObjectiveGuidance()
        let targetWasEntrenched = target.isEntrenched
        let damage = tacticalCommandDamage(command: command, caster: caster, target: target)
        spendCommandPoints(command.commandCost, for: activeFaction)
        scenario.units[targetIndex].hp = max(0, scenario.units[targetIndex].hp - damage)
        scenario.units[targetIndex].isEntrenched = false
        scenario.units[casterIndex].tacticalStatus = .normal
        scenario.units[casterIndex].hasMoved = true
        scenario.units[casterIndex].hasAttacked = true
        scenario.units[casterIndex].isEntrenched = false
        let targetDestroyed = scenario.units[targetIndex].isDestroyed

        awardExperience(
            to: casterID,
            amount: experienceForDamage(damage) + (targetDestroyed ? 10 : 0),
            reason: command.title
        )

        if targetDestroyed {
            message = tacticalCommandResultMessage(
                command: command,
                casterName: caster.name,
                targetName: target.name,
                startingTargetHP: target.hp,
                endingTargetHP: scenario.units[targetIndex].hp,
                damage: damage,
                statusEffect: nil,
                didDestroyTarget: true,
                didConsumeTargetEntrenchment: targetWasEntrenched
            )
        } else {
            scenario.units[targetIndex].tacticalStatus = command.statusEffect
            adjustMorale(unitID: targetID, delta: -command.moraleDamage, reason: command.title)
            message = tacticalCommandResultMessage(
                command: command,
                casterName: caster.name,
                targetName: target.name,
                startingTargetHP: target.hp,
                endingTargetHP: scenario.units[targetIndex].hp,
                damage: damage,
                statusEffect: command.statusEffect,
                didDestroyTarget: false,
                didConsumeTargetEntrenchment: targetWasEntrenched
            )
        }

        if let finalCaster = scenario.units.first(where: { $0.id == casterID }),
           let finalTarget = scenario.units.first(where: { $0.id == targetID }) {
            latestTacticalCommandResult = TacticalCommandResultSummary(
                command: command,
                caster: combatantResultSnapshot(starting: caster, ending: finalCaster),
                target: combatantResultSnapshot(starting: target, ending: finalTarget),
                damage: damage,
                commandCost: command.commandCost,
                moraleDamage: targetDestroyed ? 0 : command.moraleDamage,
                statusEffect: targetDestroyed ? .normal : command.statusEffect,
                didDestroyTarget: finalTarget.isDestroyed,
                didConsumeTargetEntrenchment: targetWasEntrenched,
                didAvoidCounterAttack: true
            )
            latestCombatResult = nil
            latestObjectiveCaptureResult = nil
            latestDeploymentResult = nil
            latestReinforcementResult = nil
            latestEnemyThreatCountermeasureExecutionResult = nil
            latestEnemyThreatCountermeasureFollowUpResult = nil
            recordAIPhaseTimelineEvent(
                kind: .tacticalCommand,
                actorUnitID: finalCaster.id,
                actorName: finalCaster.name,
                actorKind: finalCaster.kind,
                targetUnitID: finalTarget.id,
                targetName: finalTarget.name,
                targetKind: finalTarget.kind,
                from: finalCaster.position,
                to: finalTarget.position,
                tacticalCommand: command,
                damage: damage,
                commandPointCost: command.commandCost,
                commandPointsAfter: commandPoints(for: finalCaster.faction),
                didDestroyTarget: finalTarget.isDestroyed,
                detail: "\(command.title) \(finalTarget.name) -\(damage)"
            )
        }

        appendLog(message)
        recordAIPhaseAction(.tacticalCommand)
        updateObjectiveControl()
        checkVictory()
        selectNextReadyUnit()
    }

    private func tacticalCommandResultMessage(
        command: TacticalCommand,
        casterName: String,
        targetName: String,
        startingTargetHP: Int,
        endingTargetHP: Int,
        damage: Int,
        statusEffect: UnitTacticalStatus?,
        didDestroyTarget: Bool,
        didConsumeTargetEntrenchment: Bool
    ) -> String {
        let hpText = "\(targetName) \(startingTargetHP)->\(endingTargetHP)"
        let defenseText = didConsumeTargetEntrenchment ? "，消耗防御姿态" : ""
        let counterText = "，无反击"
        let costText = "，消耗 \(command.commandCost) 指令点"

        if didDestroyTarget {
            return "\(casterName) \(command.actionVerb)\(command.title)，击毁 \(targetName)，造成 \(damage) 伤害（\(hpText)\(defenseText)\(counterText)\(costText)）。"
        }

        let statusText = statusEffect.map { "，士气 -\(command.moraleDamage)，\($0.title)" } ?? ""
        return "\(casterName) \(command.actionVerb)\(command.title)压制 \(targetName)，造成 \(damage) 伤害（\(hpText)\(statusText)\(defenseText)\(counterText)\(costText)）。"
    }

    func threateningEnemies(against unit: BattleUnit) -> [BattleUnit] {
        threateningEnemies(against: unit.faction, at: unit.position)
    }

    func threateningEnemies(against faction: Faction, at coordinate: HexCoordinate) -> [BattleUnit] {
        units
            .filter { enemy in
                enemy.faction != faction &&
                !enemy.isDestroyed &&
                enemy.position != coordinate &&
                enemy.position.distance(to: coordinate) <= enemy.range
            }
            .sorted { left, right in
                let leftDistance = left.position.distance(to: coordinate)
                let rightDistance = right.position.distance(to: coordinate)
                if leftDistance == rightDistance {
                    if left.kind == right.kind {
                        return left.name < right.name
                    }
                    return left.kind.sortOrder < right.kind.sortOrder
                }
                return leftDistance < rightDistance
            }
    }

    func threatenedTiles(for faction: Faction) -> Set<HexCoordinate> {
        Set(tiles
            .map(\.coordinate)
            .filter { !threateningEnemies(against: faction, at: $0).isEmpty })
    }

    func threatenedReachableTiles(for unit: BattleUnit) -> Set<HexCoordinate> {
        Set(reachableTiles(for: unit)
            .filter { !threateningEnemies(against: unit.faction, at: $0).isEmpty })
    }

    func enemyThreatIntentPreviews(
        from enemyFaction: Faction = .axis,
        against targetFaction: Faction = .allies,
        limit: Int = 3
    ) -> [EnemyThreatIntentPreview] {
        guard limit > 0 else { return [] }

        let intents = units
            .filter { $0.faction == enemyFaction && !$0.isDestroyed }
            .flatMap { enemy in
                enemyThreatIntentCandidates(
                    for: readyThreatPreviewUnit(enemy),
                    against: targetFaction
                )
            }
            .sorted(by: enemyThreatIntentSort)

        var seen: Set<String> = []
        var uniqueIntents: [EnemyThreatIntentPreview] = []
        for intent in intents {
            let key = "\(intent.kind.rawValue)-\(intent.enemyUnitID.uuidString)-\(intent.targetCoordinate.id)-\(intent.targetUnitID?.uuidString ?? intent.targetName)"
            guard seen.insert(key).inserted else { continue }
            uniqueIntents.append(intent)
            if uniqueIntents.count == limit { break }
        }
        return uniqueIntents
    }

    func enemyThreatCountermeasurePreviews(
        for threats: [EnemyThreatIntentPreview]? = nil,
        limit: Int = 3
    ) -> [EnemyThreatCountermeasurePreview] {
        guard limit > 0 else { return [] }

        let sourceThreats = threats ?? visibleEnemyThreatIntentPreviews
        let candidates = sourceThreats
            .flatMap { enemyThreatCountermeasureCandidates(for: $0) }
            .sorted(by: enemyThreatCountermeasureSort)

        var seen: Set<String> = []
        var uniqueCountermeasures: [EnemyThreatCountermeasurePreview] = []
        for countermeasure in candidates {
            let key = "\(countermeasure.kind.rawValue)-\(countermeasure.threatEnemyUnitID.uuidString)-\(countermeasure.actingUnitID?.uuidString ?? "none")-\(countermeasure.destination?.id ?? countermeasure.targetName)"
            guard seen.insert(key).inserted else { continue }
            uniqueCountermeasures.append(countermeasure)
            if uniqueCountermeasures.count == limit { break }
        }
        return uniqueCountermeasures
    }

    func enemyThreatCountermeasureComparisonPreviews(
        for previews: [EnemyThreatCountermeasurePreview]? = nil,
        limit: Int = 3
    ) -> [EnemyThreatCountermeasureComparisonPreview] {
        guard limit > 1 else { return [] }

        let sourcePreviews = previews ?? visibleEnemyThreatCountermeasurePreviews
        let sortedPreviews = sourcePreviews.sorted(by: enemyThreatCountermeasureSort)
        let comparedPreviews = Array(sortedPreviews.prefix(limit))
        guard comparedPreviews.count > 1 else { return [] }

        return zip(comparedPreviews, comparedPreviews.dropFirst()).map { pair in
            enemyThreatCountermeasureComparisonPreview(leading: pair.0, trailing: pair.1)
        }
    }

    func flankingSupportUnits(attacker: BattleUnit, defender: BattleUnit) -> [BattleUnit] {
        units
            .filter { support in
                support.id != attacker.id &&
                    support.faction == attacker.faction &&
                    !support.isDestroyed &&
                    support.position.distance(to: defender.position) == 1
            }
            .sorted { left, right in
                if left.kind == right.kind {
                    return left.name < right.name
                }
                return left.kind.sortOrder < right.kind.sortOrder
            }
    }

    func commanderSupport(attacker: BattleUnit) -> Commander? {
        return units
            .filter { support in
                support.id != attacker.id &&
                    support.faction == attacker.faction &&
                    !support.isDestroyed &&
                    support.commander != nil &&
                    support.position.distance(to: attacker.position) == 1
            }
            .sorted { left, right in
                let leftRating = left.commander?.rating ?? 0
                let rightRating = right.commander?.rating ?? 0
                if leftRating == rightRating {
                    return left.name < right.name
                }
                return leftRating > rightRating
            }
            .first?
            .commander
    }

    func supplyState(for unit: BattleUnit) -> SupplyState {
        supplyLineTiles(for: unit).isEmpty ? .isolated : .supplied
    }

    func supplyLineTiles(for unit: BattleUnit) -> Set<HexCoordinate> {
        guard !unit.isDestroyed else { return [] }
        if let tile = tile(at: unit.position),
           tile.isObjective,
           tile.owner == unit.faction {
            return [unit.position]
        }

        let sources = Set(objectiveTiles
            .filter { $0.owner == unit.faction }
            .map(\.coordinate))
        guard !sources.isEmpty else { return [] }

        let enemyOccupied = Set(units
            .filter { $0.faction != unit.faction }
            .map(\.position))
        var frontier: [HexCoordinate] = [unit.position]
        var visited: Set<HexCoordinate> = [unit.position]
        var parent: [HexCoordinate: HexCoordinate] = [:]

        while !frontier.isEmpty {
            let current = frontier.removeFirst()
            if sources.contains(current) {
                var path: Set<HexCoordinate> = [current]
                var cursor = current
                while let previous = parent[cursor] {
                    path.insert(previous)
                    cursor = previous
                }
                return path
            }

            for next in current.neighbors {
                guard !visited.contains(next),
                      tile(at: next) != nil,
                      !enemyOccupied.contains(next) else { continue }
                visited.insert(next)
                parent[next] = current
                frontier.append(next)
            }
        }

        return []
    }

    func commandIncome(for faction: Faction) -> Int {
        3 + objectiveTiles.filter { $0.owner == faction }.count * 2
    }

    func deploymentSites(for faction: Faction) -> [DeploymentSite] {
        var seen: Set<HexCoordinate> = []
        var sites: [DeploymentSite] = []

        for objective in objectiveTiles
            .filter({ $0.owner == faction })
            .sorted(by: { ($0.objectiveName ?? $0.id) < ($1.objectiveName ?? $1.id) }) {
            let candidates = [objective.coordinate] + objective.coordinate.neighbors
            for coordinate in candidates {
                guard seen.insert(coordinate).inserted,
                      tile(at: coordinate) != nil,
                      unit(at: coordinate) == nil else { continue }
                sites.append(DeploymentSite(
                    coordinate: coordinate,
                    sourceObjectiveName: objective.objectiveName ?? "据点"
                ))
            }
        }

        return sites
    }

    func enemyControlZoneTiles(for faction: Faction) -> Set<HexCoordinate> {
        Set(units
            .filter { $0.faction != faction }
            .flatMap { $0.position.neighbors }
            .filter { tile(at: $0) != nil })
    }

    func isEnemyControlZone(_ coordinate: HexCoordinate, for faction: Faction) -> Bool {
        enemyControlZoneTiles(for: faction).contains(coordinate)
    }

    func enemyControlZonePenalty(for unit: BattleUnit, entering coordinate: HexCoordinate) -> Int {
        isEnemyControlZone(coordinate, for: unit.faction) ? Self.enemyControlZoneMovementPenalty : 0
    }

    func movementCostPreview(for unit: BattleUnit, entering coordinate: HexCoordinate) -> Int? {
        guard let tile = tile(at: coordinate) else { return nil }
        return movementCost(for: unit, entering: tile)
    }

    func routeStepPreviews(for unit: BattleUnit, route: MovementRoute) -> [RouteStepPreview] {
        route.coordinates.dropFirst().enumerated().compactMap { offset, coordinate in
            guard let movementCost = movementCostPreview(for: unit, entering: coordinate) else { return nil }
            let threats = threateningEnemies(against: unit.faction, at: coordinate)
            return RouteStepPreview(
                coordinate: coordinate,
                stepIndex: offset + 1,
                movementCost: movementCost,
                controlZonePenalty: enemyControlZonePenalty(for: unit, entering: coordinate),
                threatCount: threats.count,
                threatNames: Array(threats.prefix(2).map(\.name)),
                isDestination: coordinate == route.destination
            )
        }
    }

    func postMoveAttackPreviews(for unit: BattleUnit, to coordinate: HexCoordinate) -> [PostMoveAttackPreview] {
        guard unit.canMove,
              unit.canAttack,
              movementRoute(for: unit, to: coordinate) != nil else { return [] }

        var attacker = unit
        attacker.position = coordinate

        return postMoveAttackOpportunities(for: unit, to: coordinate)
            .compactMap { target -> PostMoveAttackPreview? in
                guard let preview = combatPreview(attacker: attacker, defender: target) else { return nil }
                return PostMoveAttackPreview(
                    targetID: target.id,
                    targetName: target.name,
                    damage: preview.damage,
                    counterDamage: preview.counterDamage,
                    defenderHPAfterAttack: preview.defenderHPAfterAttack,
                    willDestroy: preview.willDestroyDefender
                )
            }
            .sorted(by: postMoveAttackPreviewSort)
    }

    func fireExposurePreview(for unit: BattleUnit, at coordinate: HexCoordinate) -> PostMoveFireExposurePreview? {
        guard unit.canMove,
              movementRoute(for: unit, to: coordinate) != nil else { return nil }

        var movedUnit = unit
        movedUnit.position = coordinate
        movedUnit.tacticalStatus = .normal
        movedUnit.isEntrenched = false

        let sources = threateningEnemies(against: unit.faction, at: coordinate)
            .compactMap { source -> FireExposureSourcePreview? in
                guard let preview = combatPreview(attacker: source, defender: movedUnit) else { return nil }
                return FireExposureSourcePreview(
                    sourceID: source.id,
                    sourceName: source.name,
                    sourceKind: source.kind,
                    distance: source.position.distance(to: coordinate),
                    range: source.range,
                    potentialDamage: preview.damage
                )
            }
            .sorted(by: fireExposureSourcePreviewSort)
        let totalPotentialDamage = sources.map(\.potentialDamage).reduce(0, +)
        let highestSingleDamage = sources.map(\.potentialDamage).max() ?? 0
        let projectedHPAfterExposure = max(0, unit.hp - totalPotentialDamage)
        let canBeDestroyedBySingleSource = highestSingleDamage >= unit.hp && !sources.isEmpty
        let canBeDestroyedByCombinedFire = totalPotentialDamage >= unit.hp && !sources.isEmpty

        return PostMoveFireExposurePreview(
            coordinate: coordinate,
            currentHP: unit.hp,
            projectedHPAfterExposure: projectedHPAfterExposure,
            totalPotentialDamage: totalPotentialDamage,
            highestSingleDamage: highestSingleDamage,
            sources: sources,
            riskLevel: fireRiskLevel(
                currentHP: unit.hp,
                totalPotentialDamage: totalPotentialDamage,
                highestSingleDamage: highestSingleDamage,
                sourceCount: sources.count
            ),
            canBeDestroyedBySingleSource: canBeDestroyedBySingleSource,
            canBeDestroyedByCombinedFire: canBeDestroyedByCombinedFire
        )
    }

    func safeEngagementOptions(for unit: BattleUnit, against target: BattleUnit) -> [SafeEngagementOption] {
        attackPositionRoutes(for: unit, against: target)
            .compactMap { route in
                guard let exposure = fireExposurePreview(for: unit, at: route.destination) else { return nil }
                return SafeEngagementOption(
                    route: route,
                    exposure: exposure,
                    targetID: target.id,
                    targetName: target.name
                )
            }
            .sorted(by: safeEngagementOptionSort)
    }

    func mapActionHint(for coordinate: HexCoordinate) -> MapActionHint {
        guard winner == nil else { return .none }

        if let occupant = unit(at: coordinate) {
            if occupant.id == selectedUnit?.id {
                return .selectedUnit
            }
            if occupant.faction == activeFaction {
                return selectedUnit == nil ? .selectableUnit : .friendlyOccupied
            }
        }

        guard let selectedUnit else { return .none }

        if let target = unit(at: coordinate), target.faction != selectedUnit.faction {
            let distance = selectedUnit.position.distance(to: target.position)
            if attackableTiles(for: selectedUnit).contains(coordinate),
               let preview = combatPreview(attacker: selectedUnit, defender: target) {
                return .attack(
                    damage: preview.damage,
                    counterDamage: preview.counterDamage,
                    willDestroy: preview.willDestroyDefender
                )
            }
            if selectedUnit.canAttack {
                if let route = preferredAttackPositionRoute(for: selectedUnit, against: target) {
                    return .approachAttack(
                        cost: route.totalCost,
                        controlZonePenalty: route.controlZonePenalty
                    )
                }
                return .enemyOutOfRange(distance: distance, range: selectedUnit.range)
            }
            return .enemyUnavailable(distance: distance, range: selectedUnit.range)
        }

        if let route = movementRoute(for: selectedUnit, to: coordinate) {
            return .move(
                cost: route.totalCost,
                controlZonePenalty: route.controlZonePenalty
            )
        }

        return .none
    }

    func mapCommandPreview(for coordinate: HexCoordinate) -> MapCommandPreview? {
        guard let tile = tile(at: coordinate) else { return nil }

        let hint = mapActionHint(for: coordinate)
        switch hint {
        case .none:
            if let selectedUnit {
                return .unreachable(
                    unitName: selectedUnit.name,
                    terrainName: tile.terrain.title
                )
            }
            return .inspectTerrain(terrainName: tile.terrain.title)
        case .selectedUnit:
            guard let unit = unit(at: coordinate) else { return .inspectTerrain(terrainName: tile.terrain.title) }
            return .selectedUnit(unitName: unit.name)
        case .selectableUnit:
            guard let unit = unit(at: coordinate) else { return .inspectTerrain(terrainName: tile.terrain.title) }
            return .selectUnit(unitName: unit.name, kind: unit.kind)
        case .move:
            guard let selectedUnit else { return .inspectTerrain(terrainName: tile.terrain.title) }
            guard let route = movementRoute(for: selectedUnit, to: coordinate) else {
                return .unreachable(unitName: selectedUnit.name, terrainName: tile.terrain.title)
            }
            return .move(
                unitName: selectedUnit.name,
                terrainName: tile.terrain.title,
                route: route
            )
        case let .attack(damage, counterDamage, willDestroy):
            guard let attacker = selectedUnit,
                  let defender = unit(at: coordinate),
                  let preview = combatPreview(attacker: attacker, defender: defender) else { return nil }
            return .attack(
                attackerName: attacker.name,
                defenderName: defender.name,
                damage: damage,
                counterDamage: counterDamage,
                defenderHPAfterAttack: preview.defenderHPAfterAttack,
                willDestroy: willDestroy
            )
        case .approachAttack:
            guard let selectedUnit,
                  let unit = unit(at: coordinate),
                  let route = preferredAttackPositionRoute(for: selectedUnit, against: unit) else {
                return .inspectTerrain(terrainName: tile.terrain.title)
            }
            return .approachAttack(
                unitName: selectedUnit.name,
                defenderName: unit.name,
                route: route
            )
        case .friendlyOccupied:
            guard let unit = unit(at: coordinate) else { return .inspectTerrain(terrainName: tile.terrain.title) }
            return .friendlyOccupied(unitName: unit.name)
        case let .enemyOutOfRange(distance, range):
            guard let unit = unit(at: coordinate) else { return .inspectTerrain(terrainName: tile.terrain.title) }
            return .enemyOutOfRange(defenderName: unit.name, distance: distance, range: range)
        case let .enemyUnavailable(distance, range):
            guard let unit = unit(at: coordinate) else { return .inspectTerrain(terrainName: tile.terrain.title) }
            return .enemyUnavailable(defenderName: unit.name, distance: distance, range: range)
        }
    }

    func canReinforce(_ unit: BattleUnit) -> Bool {
        guard unit.faction == activeFaction,
              !unit.isDestroyed,
              unit.hp < unit.maxHP,
              let tile = tile(at: unit.position),
              tile.isObjective,
              tile.owner == unit.faction else { return false }
        return activeCommandPoints >= reinforceCost(for: unit)
    }

    func reinforceCost(for unit: BattleUnit) -> Int {
        max(2, (unit.maxHP - unit.hp + 19) / 20)
    }

    func objectiveRestRecovery(for unit: BattleUnit) -> Int {
        guard !unit.isDestroyed,
              unit.hp < unit.maxHP,
              supplyState(for: unit) == .supplied,
              let tile = tile(at: unit.position),
              tile.isObjective,
              tile.owner == unit.faction else { return 0 }
        return min(Self.objectiveRestRecoveryAmount, unit.maxHP - unit.hp)
    }

    func canUseManeuverPursuit(afterDestroyingWith unit: BattleUnit) -> Bool {
        !unit.hasMoved && (unit.kind == .tank || unit.kind == .recon) && !unit.isDestroyed
    }

    func reinforceSelectedUnit() {
        guard let unit = selectedUnit else { return }
        let countermeasureExecution = focusedEnemyThreatCountermeasureForExecution(
            kind: .reinforce,
            executionKind: .reinforce,
            coordinate: unit.position
        )
        reinforce(unitID: unit.id)
        if let countermeasureExecution {
            publishCountermeasureReinforceExecutionResult(for: countermeasureExecution)
        }
    }

    func deploy(kind: UnitKind, at coordinate: HexCoordinate) {
        guard winner == nil,
              activeCommandPoints >= kind.commandCost,
              let site = deploymentSites(for: activeFaction).first(where: { $0.coordinate == coordinate }) else {
            message = "无法在此处部署 \(kind.title)。"
            return
        }

        clearObjectiveGuidance()
        spendCommandPoints(kind.commandCost, for: activeFaction)
        let unit = BattleUnit(
            name: "\(kind.reinforcementName)增援",
            kind: kind,
            faction: activeFaction,
            position: coordinate,
            hp: kind.baseHP,
            commander: nil,
            hasMoved: true,
            hasAttacked: true
        )
        scenario.units.append(unit)
        selectedUnitID = unit.id
        focusedCoordinate = coordinate
        latestDeploymentResult = DeploymentResultSummary(
            sourceObjectiveName: site.sourceObjectiveName,
            coordinate: coordinate,
            unitID: unit.id,
            unitName: unit.name,
            unitKind: unit.kind,
            faction: unit.faction,
            commandCost: kind.commandCost,
            commandPointsAfterDeployment: commandPoints(for: unit.faction)
        )
        latestCombatResult = nil
        latestTacticalCommandResult = nil
        latestObjectiveCaptureResult = nil
        latestReinforcementResult = nil
        latestEnemyThreatCountermeasureExecutionResult = nil
        latestEnemyThreatCountermeasureFollowUpResult = nil
        recordAIPhaseTimelineEvent(
            kind: .deployment,
            actorUnitID: unit.id,
            actorName: unit.name,
            actorKind: unit.kind,
            to: coordinate,
            deployedUnitKind: kind,
            objectiveName: site.sourceObjectiveName,
            commandPointCost: kind.commandCost,
            commandPointsAfter: commandPoints(for: unit.faction),
            detail: "\(site.sourceObjectiveName) 部署 \(unit.kind.title)"
        )
        message = "\(site.sourceObjectiveName) 部署 \(unit.name)，消耗 \(kind.commandCost) 指令点。"
        appendLog(message)
        recordAIPhaseAction(.deployment)
        checkVictory()
    }

    func handleTap(on coordinate: HexCoordinate) {
        guard winner == nil else { return }
        focusedCoordinate = coordinate

        if let tappedUnit = unit(at: coordinate) {
            if tappedUnit.faction == activeFaction {
                clearObjectiveGuidance()
                selectedUnitID = tappedUnit.id
                message = unitSelectionMessage(for: tappedUnit)
                return
            }
        }

        if let preview = mapCommandPreview(for: coordinate),
           preview.isExecutable {
            executeMapCommand(preview, on: coordinate, inputMode: .directTap)
            return
        }

        if let tappedUnit = unit(at: coordinate), tappedUnit.faction != activeFaction {
            clearObjectiveGuidance()
            message = selectedUnit == nil
                ? "\(tappedUnit.faction.title)\(tappedUnit.kind.title) \(tappedUnit.name)：耐久 \(tappedUnit.hp)，射程 \(tappedUnit.range)。"
                : "目标不在射程内。"
            return
        }

        guard let selectedUnit else {
            clearObjectiveGuidance()
            message = tileMessage(for: coordinate)
            return
        }

        if reachableTiles(for: selectedUnit).contains(coordinate) {
            move(unitID: selectedUnit.id, to: coordinate)
        } else {
            clearObjectiveGuidance()
            message = "\(tileMessage(for: coordinate)) 超出 \(selectedUnit.name) 的移动范围。"
        }
    }

    func handlePrimaryAction(on coordinate: HexCoordinate) {
        guard winner == nil else { return }
        clearObjectiveGuidance()
        focusedCoordinate = coordinate

        if let focusedUnit = unit(at: coordinate) {
            if focusedUnit.faction == activeFaction {
                selectedUnitID = focusedUnit.id
                message = unitSelectionMessage(for: focusedUnit)
            } else if selectedUnit != nil,
                      let preview = mapCommandPreview(for: coordinate) {
                message = primaryEnemyPreviewMessage(for: preview, fallbackUnit: focusedUnit)
            } else {
                message = "\(focusedUnit.faction.title)\(focusedUnit.kind.title) \(focusedUnit.name)：耐久 \(focusedUnit.hp)，射程 \(focusedUnit.range)。"
            }
            return
        }

        guard let selectedUnit else {
            message = tileMessage(for: coordinate)
            return
        }

        message = primaryTilePreviewMessage(for: selectedUnit, to: coordinate)
    }

    private func primaryTilePreviewMessage(for selectedUnit: BattleUnit, to coordinate: HexCoordinate) -> String {
        if let route = movementRoute(for: selectedUnit, to: coordinate) {
            let terrainName = tile(at: coordinate)?.terrain.title ?? "目标格"
            let penaltyText = route.controlZonePenalty > 0 ? "，含敌方控制区 +\(route.controlZonePenalty)" : ""
            let threatText = threatExposureText(for: selectedUnit.faction, at: coordinate)
            let fireRiskText = fireExposureBriefText(for: selectedUnit, at: coordinate)
            let opportunities = postMoveAttackOpportunities(for: selectedUnit, to: coordinate)
            if opportunities.isEmpty {
                return "\(selectedUnit.name) 可进入 \(terrainName)，消耗 \(route.totalCost) 移动力\(penaltyText)\(threatText)\(fireRiskText)。"
            }

            let names = opportunities.prefix(2).map(\.name).joined(separator: "、")
            let extraCount = opportunities.count - min(opportunities.count, 2)
            let extraText = extraCount > 0 ? "等 \(opportunities.count) 个目标" : ""
            return "\(selectedUnit.name) 可进入 \(terrainName)，消耗 \(route.totalCost) 移动力\(penaltyText)\(threatText)\(fireRiskText)，移动后可攻击 \(names)\(extraText)。"
        }

        return tileMessage(for: coordinate)
    }

    private func primaryEnemyPreviewMessage(
        for preview: MapCommandPreview,
        fallbackUnit: BattleUnit
    ) -> String {
        switch preview {
        case let .attack(_, defenderName, damage, counterDamage, defenderHPAfterAttack, willDestroy):
            let outcome = willDestroy ? "预计击毁" : "目标剩余 \(defenderHPAfterAttack) 耐久"
            let counter = counterDamage > 0 ? "，反击 \(counterDamage)" : "，无反击"
            return "\(defenderName) 在射程内，右键攻击造成 \(damage) 伤害，\(outcome)\(counter)。"
        case let .approachAttack(unitName, defenderName, route):
            let penaltyText = route.controlZonePenalty > 0 ? "，含敌方控制区 +\(route.controlZonePenalty)" : ""
            let threatText = selectedUnit.map { threatExposureText(for: $0.faction, at: route.destination) } ?? ""
            let fireRiskText = selectedUnit.map { fireExposureBriefText(for: $0, at: route.destination) } ?? ""
            return "\(defenderName) 射程外，右键命令 \(unitName) 进入 q\(route.destination.q),r\(route.destination.r) 攻击位，消耗 \(route.totalCost) 移动力\(penaltyText)\(threatText)\(fireRiskText)。"
        case let .enemyOutOfRange(defenderName, distance, range):
            return "\(defenderName) 距离 \(distance)，超出当前射程 \(range)。"
        case let .enemyUnavailable(defenderName, distance, range):
            return "\(defenderName) 距离 \(distance)，射程 \(range)，当前单位本回合已无法攻击。"
        default:
            return "\(fallbackUnit.faction.title)\(fallbackUnit.kind.title) \(fallbackUnit.name)：耐久 \(fallbackUnit.hp)，射程 \(fallbackUnit.range)。"
        }
    }

    func handleSecondaryAction(on coordinate: HexCoordinate) {
        guard winner == nil else { return }
        focusedCoordinate = coordinate

        guard let preview = mapCommandPreview(for: coordinate) else {
            message = "无法在地图外执行命令。"
            return
        }

        executeMapCommand(preview, on: coordinate, inputMode: .secondaryAction)
    }

    func executeFocusedCommand() {
        guard winner == nil else { return }
        guard let focusedCoordinate else {
            message = "需要先聚焦地图目标。"
            return
        }
        guard let preview = mapCommandPreview(for: focusedCoordinate) else {
            message = "无法在地图外执行命令。"
            return
        }

        executeMapCommand(preview, on: focusedCoordinate, inputMode: .commandButton)
    }

    private func executeMapCommand(
        _ preview: MapCommandPreview,
        on coordinate: HexCoordinate,
        inputMode: MapCommandInputMode
    ) {
        switch preview {
        case let .move(_, _, route):
            guard let selectedUnit else {
                message = "需要先选择可行动部队。"
                return
            }
            guard route.destination == coordinate else {
                message = "无法确认移动目标。"
                return
            }
            let countermeasureExecution = focusedEnemyThreatCountermeasureForExecution(
                executionKind: .move,
                coordinate: coordinate
            )
            let preservesObjectiveGuidance = shouldPreserveObjectiveGuidance(for: route, unit: selectedUnit)
            let postMoveTargets = postMoveAttackOpportunities(for: selectedUnit, to: coordinate)
            move(
                unitID: selectedUnit.id,
                to: coordinate,
                preservingObjectiveGuidance: preservesObjectiveGuidance
            )
            if let countermeasureExecution,
               countermeasureExecution.kind == .withdraw || countermeasureExecution.kind == .objectiveDefense {
                publishCountermeasureMoveExecutionResult(for: countermeasureExecution, route: route)
            }
            if winner == nil,
               let nextTarget = postMoveTargets.first,
               let movedUnit = self.selectedUnit,
               unit(at: nextTarget.position)?.id == nextTarget.id {
                clearObjectiveGuidance()
                focusedCoordinate = nextTarget.position
                message = "\(movedUnit.name) 进入攻击位，\(nextTarget.name) 已在射程内，\(inputMode.followUpAttackPrompt)。"
                appendLog(message)
            }
        case .attack:
            guard let attacker = selectedUnit,
                  let target = unit(at: coordinate),
                  target.faction != attacker.faction else {
                message = "无法确认攻击目标。"
                return
            }
            let countermeasureExecution = focusedEnemyThreatCountermeasureForExecution(
                kind: .firstStrike,
                executionKind: .attack,
                coordinate: coordinate
            )
            attack(attackerID: attacker.id, targetID: target.id)
            if let countermeasureExecution {
                publishCountermeasureAttackExecutionResult(for: countermeasureExecution)
            }
        case let .approachAttack(_, defenderName, route):
            guard let selectedUnit else {
                message = "需要先选择可行动部队。"
                return
            }
            let destination = route.destination
            let threatText = threatExposureText(for: selectedUnit.faction, at: destination)
            move(unitID: selectedUnit.id, to: destination)
            if winner == nil,
               let movedUnit = self.selectedUnit {
                focusedCoordinate = coordinate
                message = "\(movedUnit.name) 进入攻击位\(threatText)，\(defenderName) 已在射程内，\(inputMode.followUpAttackPrompt)。"
                appendLog(message)
            }
        case let .selectedUnit(unitName):
            message = "\(unitName) 已选中。"
        case let .selectUnit(unitName, _):
            message = "右键不会切换选择。左键选择 \(unitName)。"
        case let .friendlyOccupied(unitName):
            message = "\(unitName) 占据该格。"
        case let .enemyOutOfRange(defenderName, distance, range):
            message = "\(defenderName) 距离 \(distance)，超出射程 \(range)。"
        case let .enemyUnavailable(defenderName, _, _):
            message = "\(defenderName) 当前不可攻击。"
        case let .unreachable(unitName, terrainName):
            message = "\(terrainName) 超出 \(unitName) 的移动范围。"
        case let .inspectTerrain(terrainName):
            message = "需要先选择可行动部队。\(terrainName)：\(tileMessage(for: coordinate))"
        }
    }

    func reachableTiles(for unit: BattleUnit) -> Set<HexCoordinate> {
        Set(movementRoutes(for: unit).keys)
    }

    func movementRoute(for unit: BattleUnit, to coordinate: HexCoordinate) -> MovementRoute? {
        movementRoutes(for: unit)[coordinate]
    }

    func movementRoutes(for unit: BattleUnit) -> [HexCoordinate: MovementRoute] {
        movementRoutes(for: unit, requireActiveFaction: true)
    }

    private func predictedMovementRoutes(for unit: BattleUnit) -> [HexCoordinate: MovementRoute] {
        movementRoutes(for: unit, requireActiveFaction: false)
    }

    private func movementRoutes(
        for unit: BattleUnit,
        requireActiveFaction: Bool
    ) -> [HexCoordinate: MovementRoute] {
        guard (!requireActiveFaction || unit.faction == activeFaction),
              unit.canMove else { return [:] }

        let movementAllowance = effectiveMovement(for: unit)
        var bestCost: [HexCoordinate: Int] = [unit.position: 0]
        var bestPenalty: [HexCoordinate: Int] = [unit.position: 0]
        var parent: [HexCoordinate: HexCoordinate] = [:]
        var frontier: [HexCoordinate] = [unit.position]
        let occupied = Set(units.filter { $0.id != unit.id }.map(\.position))

        while !frontier.isEmpty {
            let current = frontier.removeFirst()
            let currentCost = bestCost[current, default: 0]

            for next in current.neighbors {
                guard let tile = tile(at: next), !occupied.contains(next) else { continue }
                let stepPenalty = enemyControlZonePenalty(for: unit, entering: next)
                let newCost = currentCost + movementCost(for: unit, entering: tile)
                let newPenalty = bestPenalty[current, default: 0] + stepPenalty
                guard newCost <= movementAllowance else { continue }

                let shouldUpdate = bestCost[next] == nil ||
                    newCost < bestCost[next, default: Int.max] ||
                    (newCost == bestCost[next, default: Int.max] && newPenalty < bestPenalty[next, default: Int.max])

                if shouldUpdate {
                    bestCost[next] = newCost
                    bestPenalty[next] = newPenalty
                    parent[next] = current
                    frontier.append(next)
                }
            }
        }

        bestCost.removeValue(forKey: unit.position)
        return bestCost.reduce(into: [HexCoordinate: MovementRoute]()) { routes, entry in
            let destination = entry.key
            var coordinates = [destination]
            var cursor = destination

            while cursor != unit.position {
                guard let previous = parent[cursor] else { return }
                coordinates.append(previous)
                cursor = previous
            }

            routes[destination] = MovementRoute(
                destination: destination,
                coordinates: coordinates.reversed(),
                totalCost: entry.value,
                controlZonePenalty: bestPenalty[destination, default: 0]
            )
        }
    }

    func attackCoverageTiles(for unit: BattleUnit) -> Set<HexCoordinate> {
        attackCoverageTiles(for: unit, from: unit.position)
    }

    func attackCoverageTiles(for unit: BattleUnit, from coordinate: HexCoordinate) -> Set<HexCoordinate> {
        guard unit.faction == activeFaction, unit.canAttack else { return [] }
        guard tile(at: coordinate) != nil else { return [] }
        return Set(tiles
            .map(\.coordinate)
            .filter { $0 != coordinate && coordinate.distance(to: $0) <= unit.range })
    }

    func attackableTiles(for unit: BattleUnit) -> Set<HexCoordinate> {
        attackableTiles(for: unit, from: unit.position)
    }

    func attackableTiles(for unit: BattleUnit, from coordinate: HexCoordinate) -> Set<HexCoordinate> {
        let coverage = attackCoverageTiles(for: unit, from: coordinate)
        guard !coverage.isEmpty else { return [] }
        return Set(units
            .filter { $0.faction != unit.faction && !$0.isDestroyed }
            .filter { coverage.contains($0.position) }
            .map(\.position))
    }

    func attackableUnits(for unit: BattleUnit) -> [BattleUnit] {
        attackableUnits(for: unit, from: unit.position)
    }

    func attackableUnits(for unit: BattleUnit, from coordinate: HexCoordinate) -> [BattleUnit] {
        let attackable = attackableTiles(for: unit, from: coordinate)
        return units
            .filter { $0.faction != unit.faction && attackable.contains($0.position) }
            .sorted { left, right in
                let leftDistance = coordinate.distance(to: left.position)
                let rightDistance = coordinate.distance(to: right.position)
                if leftDistance == rightDistance {
                    return left.hp < right.hp
                }
                return leftDistance < rightDistance
            }
    }

    func postMoveAttackOpportunities(for unit: BattleUnit, to coordinate: HexCoordinate) -> [BattleUnit] {
        guard unit.canMove,
              unit.canAttack,
              movementRoute(for: unit, to: coordinate) != nil else { return [] }
        return attackableUnits(for: unit, from: coordinate)
    }

    func attackPositionRoutes(for unit: BattleUnit, against target: BattleUnit) -> [MovementRoute] {
        guard unit.faction == activeFaction,
              unit.faction != target.faction,
              unit.canMove,
              unit.canAttack,
              !target.isDestroyed else { return [] }

        return movementRoutes(for: unit)
            .values
            .filter { $0.destination.distance(to: target.position) <= unit.range }
            .sorted { left, right in
                if left.totalCost == right.totalCost {
                    if left.stepCount == right.stepCount {
                        return left.destination.id < right.destination.id
                    }
                    return left.stepCount < right.stepCount
                }
                return left.totalCost < right.totalCost
            }
    }

    private func preferredAttackPositionRoute(for unit: BattleUnit, against target: BattleUnit) -> MovementRoute? {
        let routes = attackPositionRoutes(for: unit, against: target)
        if focusedSafeEngagementTargetID == target.id,
           let destination = focusedSafeEngagementDestination,
           let focusedRoute = routes.first(where: { $0.destination == destination }) {
            return focusedRoute
        }

        return routes.first
    }

    func nearestApproachTarget(for unit: BattleUnit) -> BattleUnit? {
        guard unit.faction == activeFaction,
              unit.canMove,
              unit.canAttack else { return nil }

        return units
            .filter { target in
                target.faction != unit.faction &&
                    !target.isDestroyed &&
                    !attackableTiles(for: unit).contains(target.position) &&
                    !attackPositionRoutes(for: unit, against: target).isEmpty
            }
            .sorted { left, right in
                let leftRoute = attackPositionRoutes(for: unit, against: left).first
                let rightRoute = attackPositionRoutes(for: unit, against: right).first
                let leftCost = leftRoute?.totalCost ?? Int.max
                let rightCost = rightRoute?.totalCost ?? Int.max
                if leftCost == rightCost {
                    let leftDistance = unit.position.distance(to: left.position)
                    let rightDistance = unit.position.distance(to: right.position)
                    if leftDistance == rightDistance {
                        return left.hp < right.hp
                    }
                    return leftDistance < rightDistance
                }
                return leftCost < rightCost
            }
            .first
    }

    private func postMoveAttackPreviewSort(_ left: PostMoveAttackPreview, _ right: PostMoveAttackPreview) -> Bool {
        if left.willDestroy != right.willDestroy {
            return left.willDestroy && !right.willDestroy
        }
        if left.damage != right.damage {
            return left.damage > right.damage
        }
        if left.defenderHPAfterAttack != right.defenderHPAfterAttack {
            return left.defenderHPAfterAttack < right.defenderHPAfterAttack
        }
        return left.targetName < right.targetName
    }

    private func fireExposureSourcePreviewSort(
        _ left: FireExposureSourcePreview,
        _ right: FireExposureSourcePreview
    ) -> Bool {
        if left.potentialDamage != right.potentialDamage {
            return left.potentialDamage > right.potentialDamage
        }
        if left.distance != right.distance {
            return left.distance < right.distance
        }
        if left.sourceKind != right.sourceKind {
            return left.sourceKind.sortOrder < right.sourceKind.sortOrder
        }
        return left.sourceName < right.sourceName
    }

    private func safeEngagementOptionSort(_ left: SafeEngagementOption, _ right: SafeEngagementOption) -> Bool {
        if left.exposure.riskLevel.sortRank != right.exposure.riskLevel.sortRank {
            return left.exposure.riskLevel.sortRank < right.exposure.riskLevel.sortRank
        }
        if left.exposure.totalPotentialDamage != right.exposure.totalPotentialDamage {
            return left.exposure.totalPotentialDamage < right.exposure.totalPotentialDamage
        }
        if left.exposure.highestSingleDamage != right.exposure.highestSingleDamage {
            return left.exposure.highestSingleDamage < right.exposure.highestSingleDamage
        }
        if left.route.totalCost != right.route.totalCost {
            return left.route.totalCost < right.route.totalCost
        }
        if left.route.stepCount != right.route.stepCount {
            return left.route.stepCount < right.route.stepCount
        }
        return left.route.destination.id < right.route.destination.id
    }

    private func readyThreatPreviewUnit(_ unit: BattleUnit) -> BattleUnit {
        var readyUnit = unit
        readyUnit.hasMoved = false
        readyUnit.hasAttacked = false
        return readyUnit
    }

    private func enemyThreatIntentCandidates(
        for enemy: BattleUnit,
        against targetFaction: Faction
    ) -> [EnemyThreatIntentPreview] {
        guard !enemy.isDestroyed, enemy.canAttack else { return [] }
        return directAttackThreatIntents(for: enemy, against: targetFaction) +
            approachAttackThreatIntents(for: enemy, against: targetFaction) +
            objectiveCaptureThreatIntents(for: enemy, against: targetFaction)
    }

    private func directAttackThreatIntents(
        for enemy: BattleUnit,
        against targetFaction: Faction
    ) -> [EnemyThreatIntentPreview] {
        units
            .filter { target in
                target.faction == targetFaction &&
                    !target.isDestroyed &&
                    enemy.position.distance(to: target.position) <= enemy.range
            }
            .compactMap { target in
                guard let preview = combatPreview(attacker: enemy, defender: target) else { return nil }
                return enemyThreatIntent(
                    kind: .directAttack,
                    enemy: enemy,
                    target: target,
                    targetCoordinate: target.position,
                    targetName: target.name,
                    targetFaction: target.faction,
                    currentDistance: enemy.position.distance(to: target.position),
                    route: nil,
                    combatPreview: preview,
                    objectiveOwner: nil
                )
            }
    }

    private func approachAttackThreatIntents(
        for enemy: BattleUnit,
        against targetFaction: Faction
    ) -> [EnemyThreatIntentPreview] {
        let routes = predictedMovementRoutes(for: enemy)
        guard !routes.isEmpty else { return [] }

        return units
            .filter { target in
                target.faction == targetFaction &&
                    !target.isDestroyed &&
                    enemy.position.distance(to: target.position) > enemy.range
            }
            .compactMap { target -> EnemyThreatIntentPreview? in
                guard let route = routes.values
                    .filter({ $0.destination.distance(to: target.position) <= enemy.range })
                    .sorted(by: threatRouteSort)
                    .first else { return nil }

                var movedEnemy = enemy
                movedEnemy.position = route.destination

                guard let preview = combatPreview(attacker: movedEnemy, defender: target) else { return nil }
                return enemyThreatIntent(
                    kind: .approachAttack,
                    enemy: enemy,
                    target: target,
                    targetCoordinate: target.position,
                    targetName: target.name,
                    targetFaction: target.faction,
                    currentDistance: enemy.position.distance(to: target.position),
                    route: route,
                    combatPreview: preview,
                    objectiveOwner: nil
                )
            }
    }

    private func objectiveCaptureThreatIntents(
        for enemy: BattleUnit,
        against targetFaction: Faction
    ) -> [EnemyThreatIntentPreview] {
        let routes = predictedMovementRoutes(for: enemy)
        guard !routes.isEmpty else { return [] }

        return objectiveTiles
            .filter { objective in
                objective.owner == targetFaction &&
                    self.unit(at: objective.coordinate) == nil
            }
            .compactMap { objective -> EnemyThreatIntentPreview? in
                guard let route = routes[objective.coordinate] else { return nil }
                return enemyThreatIntent(
                    kind: .objectiveCapture,
                    enemy: enemy,
                    target: nil,
                    targetCoordinate: objective.coordinate,
                    targetName: objective.objectiveName ?? "目标据点",
                    targetFaction: targetFaction,
                    currentDistance: enemy.position.distance(to: objective.coordinate),
                    route: route,
                    combatPreview: nil,
                    objectiveOwner: objective.owner
                )
            }
    }

    private func enemyThreatIntent(
        kind: EnemyThreatIntentKind,
        enemy: BattleUnit,
        target: BattleUnit?,
        targetCoordinate: HexCoordinate,
        targetName: String,
        targetFaction: Faction,
        currentDistance: Int,
        route: MovementRoute?,
        combatPreview: CombatPreview?,
        objectiveOwner: Faction?
    ) -> EnemyThreatIntentPreview {
        let projectedDamage = combatPreview?.damage ?? 0
        let projectedHPAfterDamage = combatPreview?.defenderHPAfterAttack
        let willDestroyTarget = combatPreview?.willDestroyDefender ?? false
        return EnemyThreatIntentPreview(
            kind: kind,
            enemyUnitID: enemy.id,
            enemyUnitName: enemy.name,
            enemyUnitKind: enemy.kind,
            targetCoordinate: targetCoordinate,
            targetUnitID: target?.id,
            targetName: targetName,
            targetFaction: targetFaction,
            currentDistance: currentDistance,
            routeDestination: route?.destination,
            routeCost: route?.totalCost,
            projectedDamage: projectedDamage,
            projectedTargetHPAfterDamage: projectedHPAfterDamage,
            willDestroyTarget: willDestroyTarget,
            objectiveOwner: objectiveOwner,
            score: enemyThreatIntentScore(
                kind: kind,
                target: target,
                currentDistance: currentDistance,
                route: route,
                projectedDamage: projectedDamage,
                willDestroyTarget: willDestroyTarget
            )
        )
    }

    private func enemyThreatIntentScore(
        kind: EnemyThreatIntentKind,
        target: BattleUnit?,
        currentDistance: Int,
        route: MovementRoute?,
        projectedDamage: Int,
        willDestroyTarget: Bool
    ) -> Int {
        let targetValue = target.map { unit in
            unit.kind.commandCost * 14 +
                (unit.commander == nil ? 0 : 40) +
                max(0, unit.maxHP - unit.hp) / 3
        } ?? 0
        let kindValue: Int
        switch kind {
        case .directAttack:
            kindValue = 260
        case .approachAttack:
            kindValue = 220
        case .objectiveCapture:
            kindValue = 250
        }
        let routePenalty = (route?.totalCost ?? 0) * 4 + (route?.stepCount ?? 0)
        return (willDestroyTarget ? 1_000 : 0) +
            kindValue +
            targetValue +
            projectedDamage * 6 -
            routePenalty -
            currentDistance
    }

    private func enemyThreatIntentSort(
        _ left: EnemyThreatIntentPreview,
        _ right: EnemyThreatIntentPreview
    ) -> Bool {
        if left.willDestroyTarget != right.willDestroyTarget {
            return left.willDestroyTarget && !right.willDestroyTarget
        }
        if left.score != right.score {
            return left.score > right.score
        }
        if left.routeCost != right.routeCost {
            return (left.routeCost ?? 0) < (right.routeCost ?? 0)
        }
        if left.currentDistance != right.currentDistance {
            return left.currentDistance < right.currentDistance
        }
        if left.enemyUnitName != right.enemyUnitName {
            return left.enemyUnitName < right.enemyUnitName
        }
        if left.targetName != right.targetName {
            return left.targetName < right.targetName
        }
        if left.targetCoordinate.id != right.targetCoordinate.id {
            return left.targetCoordinate.id < right.targetCoordinate.id
        }
        return left.kind.rawValue < right.kind.rawValue
    }

    private func threatRouteSort(_ left: MovementRoute, _ right: MovementRoute) -> Bool {
        if left.totalCost != right.totalCost {
            return left.totalCost < right.totalCost
        }
        if left.stepCount != right.stepCount {
            return left.stepCount < right.stepCount
        }
        return left.destination.id < right.destination.id
    }

    private func enemyThreatCountermeasureCandidates(
        for threat: EnemyThreatIntentPreview
    ) -> [EnemyThreatCountermeasurePreview] {
        [
            firstStrikeCountermeasure(for: threat),
            withdrawCountermeasure(for: threat),
            objectiveDefenseCountermeasure(for: threat),
            reinforceCountermeasure(for: threat)
        ].compactMap { $0 }
    }

    private func firstStrikeCountermeasure(
        for threat: EnemyThreatIntentPreview
    ) -> EnemyThreatCountermeasurePreview? {
        guard let enemy = units.first(where: { $0.id == threat.enemyUnitID }) else { return nil }

        let candidates = units
            .filter { attacker in
                attacker.faction == threat.targetFaction &&
                    attacker.faction == activeFaction &&
                    attacker.canAttack &&
                    attacker.position.distance(to: enemy.position) <= attacker.range
            }
            .compactMap { attacker -> (unit: BattleUnit, preview: CombatPreview, score: Int)? in
                guard let preview = combatPreview(attacker: attacker, defender: enemy) else { return nil }
                let score = 320 +
                    (preview.willDestroyDefender ? 700 : 0) +
                    preview.damage * 6 +
                    enemy.kind.commandCost * 12 -
                    attacker.position.distance(to: enemy.position)
                return (attacker, preview, score)
            }
            .sorted { left, right in
                if left.preview.willDestroyDefender != right.preview.willDestroyDefender {
                    return left.preview.willDestroyDefender && !right.preview.willDestroyDefender
                }
                if left.score != right.score {
                    return left.score > right.score
                }
                if left.preview.damage != right.preview.damage {
                    return left.preview.damage > right.preview.damage
                }
                return left.unit.name < right.unit.name
            }

        guard let best = candidates.first else { return nil }
        return enemyThreatCountermeasure(
            kind: .firstStrike,
            threat: threat,
            actingUnit: best.unit,
            targetUnitID: enemy.id,
            targetName: enemy.name,
            destination: nil,
            routeCost: nil,
            projectedDamage: best.preview.damage,
            projectedEnemyHPAfterDamage: best.preview.defenderHPAfterAttack,
            willDestroyEnemy: best.preview.willDestroyDefender,
            projectedFriendlyHPAfterAction: best.preview.attackerHPAfterCounter,
            projectedRecoveredHP: 0,
            impactComparisons: firstStrikeImpactComparisons(threat: threat, preview: best.preview),
            reason: best.preview.willDestroyDefender ?
                "当前射程内可先击毁 \(enemy.name)，解除 \(threat.targetName) 威胁。" :
                "当前射程内可先压低 \(enemy.name) 耐久，削弱 \(threat.targetName) 威胁。",
            score: best.score
        )
    }

    private func withdrawCountermeasure(
        for threat: EnemyThreatIntentPreview
    ) -> EnemyThreatCountermeasurePreview? {
        guard threat.isAttackThreat,
              let targetUnitID = threat.targetUnitID,
              let target = units.first(where: { $0.id == targetUnitID }),
              let enemy = units.first(where: { $0.id == threat.enemyUnitID }),
              target.faction == activeFaction,
              target.canMove else { return nil }

        let startingHPAfterThreat = threat.projectedTargetHPAfterDamage ?? max(0, target.hp - threat.projectedDamage)
        let routes = movementRoutes(for: target).values
        let candidates = routes
            .compactMap { route -> (route: MovementRoute, projectedHP: Int, score: Int)? in
                let exposure = fireExposurePreview(for: target, at: route.destination)
                let otherExposureDamage = exposure?.sources
                    .filter { $0.sourceID != enemy.id }
                    .map(\.potentialDamage)
                    .reduce(0, +) ?? 0
                let sourceDamage = predictedThreatSourceDamage(
                    from: enemy,
                    against: target,
                    at: route.destination
                )
                let totalProjectedDamage = otherExposureDamage + sourceDamage
                let projectedHP = max(0, target.hp - totalProjectedDamage)
                guard totalProjectedDamage < threat.projectedDamage,
                      projectedHP > startingHPAfterThreat,
                      projectedHP > 0 else { return nil }

                let preservedHP = max(0, projectedHP - startingHPAfterThreat)
                let score = 250 +
                    preservedHP * 8 +
                    (sourceDamage == 0 ? 60 : 0) -
                    route.totalCost * 4 -
                    route.stepCount
                return (route, projectedHP, score)
            }
            .sorted { left, right in
                if left.score != right.score {
                    return left.score > right.score
                }
                if left.projectedHP != right.projectedHP {
                    return left.projectedHP > right.projectedHP
                }
                if left.route.totalCost != right.route.totalCost {
                    return left.route.totalCost < right.route.totalCost
                }
                if left.route.stepCount != right.route.stepCount {
                    return left.route.stepCount < right.route.stepCount
                }
                return left.route.destination.id < right.route.destination.id
            }

        guard let best = candidates.first else { return nil }
        return enemyThreatCountermeasure(
            kind: .withdraw,
            threat: threat,
            actingUnit: target,
            targetUnitID: target.id,
            targetName: target.name,
            destination: best.route.destination,
            routeCost: best.route.totalCost,
            projectedDamage: 0,
            projectedEnemyHPAfterDamage: nil,
            willDestroyEnemy: false,
            projectedFriendlyHPAfterAction: best.projectedHP,
            projectedRecoveredHP: 0,
            impactComparisons: withdrawImpactComparisons(
                threat: threat,
                beforeHP: startingHPAfterThreat,
                afterHP: best.projectedHP,
                destination: best.route.destination,
                routeCost: best.route.totalCost
            ),
            reason: "转移到 \(coordinateText(best.route.destination)) 可降低 \(threat.threatLabel) 对 \(target.name) 的火力风险。",
            score: best.score
        )
    }

    private func predictedThreatSourceDamage(
        from enemy: BattleUnit,
        against target: BattleUnit,
        at coordinate: HexCoordinate
    ) -> Int {
        var movedTarget = target
        movedTarget.position = coordinate
        movedTarget.tacticalStatus = .normal
        movedTarget.isEntrenched = false

        let readyEnemy = readyThreatPreviewUnit(enemy)
        let candidatePositions = Set(
            [readyEnemy.position] + predictedMovementRoutes(for: readyEnemy).values.map(\.destination)
        )

        return candidatePositions
            .filter { $0.distance(to: coordinate) <= readyEnemy.range }
            .compactMap { position -> Int? in
                var projectedEnemy = readyEnemy
                projectedEnemy.position = position
                return combatPreview(attacker: projectedEnemy, defender: movedTarget)?.damage
            }
            .max() ?? 0
    }

    private func objectiveDefenseCountermeasure(
        for threat: EnemyThreatIntentPreview
    ) -> EnemyThreatCountermeasurePreview? {
        guard threat.kind == .objectiveCapture,
              threat.targetFaction == activeFaction,
              let objective = tile(at: threat.targetCoordinate),
              objective.isObjective else { return nil }

        let candidates = units
            .filter { unit in
                unit.faction == threat.targetFaction &&
                    unit.faction == activeFaction &&
                    unit.canMove
            }
            .compactMap { unit -> (unit: BattleUnit, route: MovementRoute, reachesObjective: Bool, score: Int)? in
                let routes = movementRoutes(for: unit)
                if let route = routes[threat.targetCoordinate] {
                    let score = 300 +
                        unit.kind.commandCost * 10 -
                        route.totalCost * 5 -
                        route.stepCount
                    return (unit, route, true, score)
                }

                guard let route = routes.values
                    .filter({ $0.destination.distance(to: threat.targetCoordinate) == 1 })
                    .sorted(by: threatRouteSort)
                    .first else { return nil }
                let score = 240 +
                    unit.kind.commandCost * 8 -
                    route.totalCost * 5 -
                    route.stepCount
                return (unit, route, false, score)
            }
            .sorted { left, right in
                if left.reachesObjective != right.reachesObjective {
                    return left.reachesObjective && !right.reachesObjective
                }
                if left.score != right.score {
                    return left.score > right.score
                }
                if left.route.totalCost != right.route.totalCost {
                    return left.route.totalCost < right.route.totalCost
                }
                if left.unit.kind != right.unit.kind {
                    return left.unit.kind.sortOrder < right.unit.kind.sortOrder
                }
                return left.unit.name < right.unit.name
            }

        guard let best = candidates.first else { return nil }
        let actionText = best.reachesObjective ? "进驻" : "封堵"
        return enemyThreatCountermeasure(
            kind: .objectiveDefense,
            threat: threat,
            actingUnit: best.unit,
            targetUnitID: nil,
            targetName: threat.targetName,
            destination: best.route.destination,
            routeCost: best.route.totalCost,
            projectedDamage: 0,
            projectedEnemyHPAfterDamage: nil,
            willDestroyEnemy: false,
            projectedFriendlyHPAfterAction: best.unit.hp,
            projectedRecoveredHP: 0,
            impactComparisons: objectiveDefenseImpactComparisons(
                threat: threat,
                destination: best.route.destination,
                routeCost: best.route.totalCost,
                reachesObjective: best.reachesObjective
            ),
            reason: "\(best.unit.name) 可\(actionText)\(threat.targetName)，阻止 \(threat.threatLabel) 抢点。",
            score: best.score
        )
    }

    private func reinforceCountermeasure(
        for threat: EnemyThreatIntentPreview
    ) -> EnemyThreatCountermeasurePreview? {
        guard threat.isAttackThreat,
              let targetUnitID = threat.targetUnitID,
              let target = units.first(where: { $0.id == targetUnitID }),
              canReinforce(target) else { return nil }

        let recoveredHP = min(target.kind.reinforceAmount, target.maxHP - target.hp)
        guard recoveredHP > 0 else { return nil }

        let hpAfterRecovery = target.hp + recoveredHP
        let projectedHPAfterThreat = max(0, hpAfterRecovery - threat.projectedDamage)
        let score = 220 +
            recoveredHP * 6 +
            (threat.willDestroyTarget && projectedHPAfterThreat > 0 ? 120 : 0) +
            target.kind.commandCost * 6 -
            reinforceCost(for: target) * 8

        return enemyThreatCountermeasure(
            kind: .reinforce,
            threat: threat,
            actingUnit: target,
            targetUnitID: target.id,
            targetName: target.name,
            destination: target.position,
            routeCost: nil,
            projectedDamage: 0,
            projectedEnemyHPAfterDamage: nil,
            willDestroyEnemy: false,
            projectedFriendlyHPAfterAction: hpAfterRecovery,
            projectedRecoveredHP: recoveredHP,
            impactComparisons: reinforceImpactComparisons(
                threat: threat,
                beforeHP: threat.projectedTargetHPAfterDamage ?? max(0, target.hp - threat.projectedDamage),
                afterRecoveryHP: hpAfterRecovery,
                afterThreatHP: projectedHPAfterThreat,
                recoveredHP: recoveredHP
            ),
            reason: "在己方据点整补 \(target.name) +\(recoveredHP) 耐久，提高承受 \(threat.threatLabel) 的能力。",
            score: score
        )
    }

    private func enemyThreatCountermeasure(
        kind: EnemyThreatCountermeasureKind,
        threat: EnemyThreatIntentPreview,
        actingUnit: BattleUnit,
        targetUnitID: BattleUnit.ID?,
        targetName: String,
        destination: HexCoordinate?,
        routeCost: Int?,
        projectedDamage: Int,
        projectedEnemyHPAfterDamage: Int?,
        willDestroyEnemy: Bool,
        projectedFriendlyHPAfterAction: Int?,
        projectedRecoveredHP: Int,
        impactComparisons: [EnemyThreatCountermeasureImpactComparison],
        reason: String,
        score: Int
    ) -> EnemyThreatCountermeasurePreview {
        EnemyThreatCountermeasurePreview(
            kind: kind,
            threatID: threat.id,
            threatKind: threat.kind,
            threatEnemyUnitID: threat.enemyUnitID,
            threatEnemyUnitName: threat.enemyUnitName,
            threatTargetCoordinate: threat.targetCoordinate,
            actingUnitID: actingUnit.id,
            actingUnitName: actingUnit.name,
            targetUnitID: targetUnitID,
            targetName: targetName,
            destination: destination,
            routeCost: routeCost,
            projectedDamage: projectedDamage,
            projectedEnemyHPAfterDamage: projectedEnemyHPAfterDamage,
            willDestroyEnemy: willDestroyEnemy,
            projectedFriendlyHPAfterAction: projectedFriendlyHPAfterAction,
            projectedRecoveredHP: projectedRecoveredHP,
            canExecuteNow: actingUnit.faction == activeFaction && !actingUnit.isDestroyed,
            reason: reason,
            score: score,
            impactComparisons: impactComparisons
        )
    }

    private func firstStrikeImpactComparisons(
        threat: EnemyThreatIntentPreview,
        preview: CombatPreview
    ) -> [EnemyThreatCountermeasureImpactComparison] {
        let beforeHPText = threat.projectedTargetHPAfterDamage.map { "HP \($0)" } ?? "据点风险"
        let afterThreatText = preview.willDestroyDefender ?
            "威胁解除" :
            "敌 HP \(preview.defenderHPAfterAttack)"
        return [
            EnemyThreatCountermeasureImpactComparison(
                kind: .threatDamage,
                title: "当前",
                before: threat.willDestroyTarget ? "击毁风险" : "-\(threat.projectedDamage)",
                after: afterThreatText,
                impact: preview.willDestroyDefender ? "先手击毁威胁源" : "先手削弱威胁源"
            ),
            EnemyThreatCountermeasureImpactComparison(
                kind: .survival,
                title: "目标",
                before: beforeHPText,
                after: preview.willDestroyDefender ? "不再受该威胁" : beforeHPText,
                impact: preview.willDestroyDefender ? "避免本条威胁" : "降低后续威胁强度"
            )
        ]
    }

    private func withdrawImpactComparisons(
        threat: EnemyThreatIntentPreview,
        beforeHP: Int,
        afterHP: Int,
        destination: HexCoordinate,
        routeCost: Int
    ) -> [EnemyThreatCountermeasureImpactComparison] {
        let preservedHP = max(0, afterHP - beforeHP)
        return [
            EnemyThreatCountermeasureImpactComparison(
                kind: .survival,
                title: "耐久",
                before: "HP \(beforeHP)",
                after: "HP \(afterHP)",
                impact: "+\(preservedHP) 生存"
            ),
            EnemyThreatCountermeasureImpactComparison(
                kind: .route,
                title: "位置",
                before: threat.destinationText,
                after: coordinateText(destination),
                impact: "路线 \(routeCost)"
            )
        ]
    }

    private func objectiveDefenseImpactComparisons(
        threat: EnemyThreatIntentPreview,
        destination: HexCoordinate,
        routeCost: Int,
        reachesObjective: Bool
    ) -> [EnemyThreatCountermeasureImpactComparison] {
        let actionText = reachesObjective ? "进驻" : "封堵"
        return [
            EnemyThreatCountermeasureImpactComparison(
                kind: .objective,
                title: "据点",
                before: "被夺风险",
                after: actionText,
                impact: "\(actionText)\(threat.targetName)"
            ),
            EnemyThreatCountermeasureImpactComparison(
                kind: .route,
                title: "位置",
                before: threat.destinationText,
                after: coordinateText(destination),
                impact: "路线 \(routeCost)"
            )
        ]
    }

    private func reinforceImpactComparisons(
        threat: EnemyThreatIntentPreview,
        beforeHP: Int,
        afterRecoveryHP: Int,
        afterThreatHP: Int,
        recoveredHP: Int
    ) -> [EnemyThreatCountermeasureImpactComparison] {
        let preservedHP = max(0, afterThreatHP - beforeHP)
        return [
            EnemyThreatCountermeasureImpactComparison(
                kind: .survival,
                title: "承受",
                before: threat.willDestroyTarget ? "被击毁" : "HP \(beforeHP)",
                after: "HP \(afterThreatHP)",
                impact: "+\(preservedHP) 生存"
            ),
            EnemyThreatCountermeasureImpactComparison(
                kind: .recovery,
                title: "整补",
                before: "HP \(beforeHP)",
                after: "HP \(afterRecoveryHP)",
                impact: "+\(recoveredHP) 耐久"
            )
        ]
    }

    private func enemyThreatCountermeasureComparisonPreview(
        leading: EnemyThreatCountermeasurePreview,
        trailing: EnemyThreatCountermeasurePreview
    ) -> EnemyThreatCountermeasureComparisonPreview {
        let factor = enemyThreatCountermeasureComparisonFactor(leading: leading, trailing: trailing)
        return EnemyThreatCountermeasureComparisonPreview(
            leading: leading,
            trailing: trailing,
            factor: factor,
            summary: "\(leading.kind.title)领先\(trailing.kind.title)：\(factor.detail)"
        )
    }

    private func enemyThreatCountermeasureComparisonFactor(
        leading: EnemyThreatCountermeasurePreview,
        trailing: EnemyThreatCountermeasurePreview
    ) -> EnemyThreatCountermeasurePriorityFactor {
        enemyThreatCountermeasureOrderingDecision(leading, trailing)?.factor ??
            EnemyThreatCountermeasurePriorityFactor(
                kind: .stableTieBreaker,
                title: "类型",
                value: "\(leading.kind.rawValue) = \(trailing.kind.rawValue)",
                detail: "建议排序完全相同"
            )
    }

    private func enemyThreatCountermeasureOrderingDecision(
        _ left: EnemyThreatCountermeasurePreview,
        _ right: EnemyThreatCountermeasurePreview
    ) -> (leftComesFirst: Bool, factor: EnemyThreatCountermeasurePriorityFactor)? {
        if left.canExecuteNow != right.canExecuteNow {
            let leftComesFirst = left.canExecuteNow && !right.canExecuteNow
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .availability,
                title: "可执行",
                value: "\(availabilityText(left.canExecuteNow)) \(leftComesFirst ? ">" : "<") \(availabilityText(right.canExecuteNow))",
                detail: leftComesFirst ? "执行单位当前可行动" : "右侧建议当前可行动"
            ))
        }
        if left.willDestroyEnemy != right.willDestroyEnemy {
            let leftComesFirst = left.willDestroyEnemy && !right.willDestroyEnemy
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .decisiveStrike,
                title: "击毁",
                value: "\(availabilityText(left.willDestroyEnemy)) \(leftComesFirst ? ">" : "<") \(availabilityText(right.willDestroyEnemy))",
                detail: leftComesFirst ? "可直接击毁威胁来源" : "右侧建议可直接击毁威胁来源"
            ))
        }
        if left.score != right.score {
            let leftComesFirst = left.score > right.score
            let winningScore = leftComesFirst ? left.score : right.score
            let losingScore = leftComesFirst ? right.score : left.score
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .priorityScore,
                title: "优先值",
                value: "\(left.score) \(leftComesFirst ? ">" : "<") \(right.score)",
                detail: "优先值 \(winningScore) 高于 \(losingScore)"
            ))
        }
        if left.routeCost != right.routeCost {
            let leftRouteCost = left.routeCost ?? 0
            let rightRouteCost = right.routeCost ?? 0
            let leftComesFirst = leftRouteCost < rightRouteCost
            let winningRouteCost = leftComesFirst ? leftRouteCost : rightRouteCost
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .routeCost,
                title: "路线",
                value: "\(leftRouteCost) \(leftComesFirst ? "<" : ">") \(rightRouteCost)",
                detail: "路线消耗 \(winningRouteCost) 更低"
            ))
        }
        if left.actingUnitName != right.actingUnitName {
            let leftComesFirst = left.actingUnitName < right.actingUnitName
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .actingUnit,
                title: "执行单位",
                value: "\(left.actingUnitName) \(leftComesFirst ? "<" : ">") \(right.actingUnitName)",
                detail: "执行单位名称稳定排序更靠前"
            ))
        }
        if left.targetName != right.targetName {
            let leftComesFirst = left.targetName < right.targetName
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .target,
                title: "目标",
                value: "\(left.targetName) \(leftComesFirst ? "<" : ">") \(right.targetName)",
                detail: "目标名称稳定排序更靠前"
            ))
        }
        if left.destination?.id != right.destination?.id {
            let leftDestination = left.destination?.id ?? ""
            let rightDestination = right.destination?.id ?? ""
            let leftComesFirst = leftDestination < rightDestination
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .destination,
                title: "坐标",
                value: "\(leftDestination.isEmpty ? "direct" : leftDestination) \(leftComesFirst ? "<" : ">") \(rightDestination.isEmpty ? "direct" : rightDestination)",
                detail: "目的坐标稳定排序更靠前"
            ))
        }
        if left.threatID != right.threatID {
            let leftComesFirst = left.threatID < right.threatID
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .threat,
                title: "威胁",
                value: "\(left.threatID) \(leftComesFirst ? "<" : ">") \(right.threatID)",
                detail: "威胁 ID 稳定排序更靠前"
            ))
        }
        if left.threatTargetCoordinate.id != right.threatTargetCoordinate.id {
            let leftComesFirst = left.threatTargetCoordinate.id < right.threatTargetCoordinate.id
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .threat,
                title: "威胁坐标",
                value: "\(left.threatTargetCoordinate.id) \(leftComesFirst ? "<" : ">") \(right.threatTargetCoordinate.id)",
                detail: "受威胁坐标稳定排序更靠前"
            ))
        }
        if left.actingUnitID?.uuidString != right.actingUnitID?.uuidString {
            let leftActingID = left.actingUnitID?.uuidString ?? ""
            let rightActingID = right.actingUnitID?.uuidString ?? ""
            let leftComesFirst = leftActingID < rightActingID
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .stableTieBreaker,
                title: "执行ID",
                value: "\(leftActingID.isEmpty ? "none" : leftActingID) \(leftComesFirst ? "<" : ">") \(rightActingID.isEmpty ? "none" : rightActingID)",
                detail: "执行单位 ID 稳定排序更靠前"
            ))
        }
        if left.targetUnitID?.uuidString != right.targetUnitID?.uuidString {
            let leftTargetID = left.targetUnitID?.uuidString ?? ""
            let rightTargetID = right.targetUnitID?.uuidString ?? ""
            let leftComesFirst = leftTargetID < rightTargetID
            return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
                kind: .stableTieBreaker,
                title: "目标ID",
                value: "\(leftTargetID.isEmpty ? "none" : leftTargetID) \(leftComesFirst ? "<" : ">") \(rightTargetID.isEmpty ? "none" : rightTargetID)",
                detail: "目标单位 ID 稳定排序更靠前"
            ))
        }
        guard left.kind.rawValue != right.kind.rawValue else { return nil }
        let leftComesFirst = left.kind.rawValue < right.kind.rawValue
        return (leftComesFirst, EnemyThreatCountermeasurePriorityFactor(
            kind: .stableTieBreaker,
            title: "类型",
            value: "\(left.kind.rawValue) \(leftComesFirst ? "<" : ">") \(right.kind.rawValue)",
            detail: "建议类型稳定排序更靠前"
        ))
    }

    private func availabilityText(_ value: Bool) -> String {
        value ? "是" : "否"
    }

    private func enemyThreatCountermeasureSort(
        _ left: EnemyThreatCountermeasurePreview,
        _ right: EnemyThreatCountermeasurePreview
    ) -> Bool {
        enemyThreatCountermeasureOrderingDecision(left, right)?.leftComesFirst ?? false
    }

    private func coordinateText(_ coordinate: HexCoordinate) -> String {
        "q\(coordinate.q),r\(coordinate.r)"
    }

    private func fireRiskLevel(
        currentHP: Int,
        totalPotentialDamage: Int,
        highestSingleDamage: Int,
        sourceCount: Int
    ) -> FireRiskLevel {
        guard sourceCount > 0, totalPotentialDamage > 0 else { return .none }
        if highestSingleDamage >= currentHP || totalPotentialDamage >= currentHP {
            return .critical
        }
        if totalPotentialDamage * 100 >= currentHP * 50 || sourceCount >= 3 {
            return .high
        }
        if totalPotentialDamage * 100 >= currentHP * 25 {
            return .medium
        }
        return .low
    }

    private func objectiveAdvancePlans(for unit: BattleUnit) -> [ObjectiveAdvancePlan] {
        guard unit.faction == activeFaction,
              unit.canMove,
              !unit.isDestroyed else { return [] }

        let routes = movementRoutes(for: unit)

        return objectiveTiles
            .filter { objective in
                objective.owner != unit.faction &&
                    self.unit(at: objective.coordinate) == nil
            }
            .compactMap { objectiveAdvancePlan(for: unit, objective: $0, routes: routes) }
            .sorted(by: objectiveAdvancePlanSort)
    }

    private func objectiveAdvancePlan(
        for unit: BattleUnit,
        objective: TerrainTile,
        routes: [HexCoordinate: MovementRoute]
    ) -> ObjectiveAdvancePlan? {
        let currentDistance = unit.position.distance(to: objective.coordinate)

        if let directRoute = routes[objective.coordinate] {
            return ObjectiveAdvancePlan(
                tile: objective,
                route: directRoute,
                reachesObjective: true,
                currentDistance: currentDistance,
                remainingDistance: 0
            )
        }

        guard let bestRoute = routes.values
            .filter({ $0.destination.distance(to: objective.coordinate) < currentDistance })
            .sorted(by: { left, right in
                let leftDistance = left.destination.distance(to: objective.coordinate)
                let rightDistance = right.destination.distance(to: objective.coordinate)
                if leftDistance == rightDistance {
                    if left.totalCost == right.totalCost {
                        return left.destination.id < right.destination.id
                    }
                    return left.totalCost < right.totalCost
                }
                return leftDistance < rightDistance
            })
            .first else { return nil }

        return ObjectiveAdvancePlan(
            tile: objective,
            route: bestRoute,
            reachesObjective: false,
            currentDistance: currentDistance,
            remainingDistance: bestRoute.destination.distance(to: objective.coordinate)
        )
    }

    private func objectiveAdvancePlanSort(_ left: ObjectiveAdvancePlan, _ right: ObjectiveAdvancePlan) -> Bool {
        if left.currentDistance == right.currentDistance {
            if left.reachesObjective != right.reachesObjective {
                return left.reachesObjective && !right.reachesObjective
            }

            if left.remainingDistance == right.remainingDistance {
                if left.route.totalCost == right.route.totalCost {
                    if left.route.stepCount == right.route.stepCount {
                        return (left.tile.objectiveName ?? left.tile.id) < (right.tile.objectiveName ?? right.tile.id)
                    }
                    return left.route.stepCount < right.route.stepCount
                }

                return left.route.totalCost < right.route.totalCost
            }

            return left.remainingDistance < right.remainingDistance
        }

        return left.currentDistance < right.currentDistance
    }

    private func objectiveAdvancePreview(for unit: BattleUnit, plan: ObjectiveAdvancePlan) -> ObjectiveAdvancePreview {
        ObjectiveAdvancePreview(
            objectiveName: plan.tile.objectiveName ?? "目标据点",
            coordinate: plan.tile.coordinate,
            owner: plan.tile.owner,
            route: plan.route,
            reachesObjective: plan.reachesObjective,
            currentDistance: plan.currentDistance,
            remainingDistance: plan.remainingDistance,
            fireExposure: fireExposurePreview(for: unit, at: plan.route.destination)
        )
    }

    func waitSelectedUnit() {
        guard let selectedUnit else { return }
        clearObjectiveGuidance()
        latestEnemyThreatCountermeasureExecutionResult = nil
        latestEnemyThreatCountermeasureFollowUpResult = nil
        updateUnit(id: selectedUnit.id) { unit in
            unit.hasMoved = true
            unit.hasAttacked = true
            unit.tacticalStatus = .normal
            unit.isEntrenched = true
        }
        message = "\(selectedUnit.name) 原地待命，构筑防御姿态。"
        appendLog(message)
        selectNextReadyUnit()
    }

    func clearSelection() {
        selectedUnitID = nil
        clearObjectiveGuidance()
        message = "已取消选择。"
    }

    func endTurn() {
        guard winner == nil else { return }
        selectedUnitID = nil
        clearObjectiveGuidance()
        prepareEnemyThreatCountermeasureFollowUpBaseline()
        latestEnemyThreatCountermeasureExecutionResult = nil
        resetUnits(for: .axis)
        activeFaction = .axis
        addCommandIncome(for: .axis)
        message = "轴心国回合开始。"
        appendLog("第 \(turn) 回合：轴心国行动。")
        beginAIPhaseRecording(for: .axis)
        runAxisAI()
        finishAIPhaseRecording()
        publishEnemyThreatCountermeasureFollowUpResultIfNeeded()

        if winner == nil {
            resetUnits(for: .allies)
            activeFaction = .allies
            turn += 1
            checkTurnLimit()

            if winner == nil {
                addCommandIncome(for: .allies)
                message = "第 \(turn) 回合，盟军行动。获得 \(commandIncome(for: .allies)) 指令点。"
                appendLog("第 \(turn) 回合：盟军行动。")
                selectNextReadyUnit()
            }
        }
    }

    func restart() {
        let scenarioID = scenario.id
        let freshScenario = campaignCatalog.first { $0.id == scenarioID } ?? Scenario.ardennesPrototype()
        loadScenario(freshScenario)
    }

    private func loadScenario(_ newScenario: Scenario) {
        scenario = newScenario
        selectedUnitID = nil
        activeFaction = .allies
        turn = 1
        winner = nil
        earnedStars = 0
        focusedCoordinate = newScenario.initialFocus
        guidedObjectiveCoordinate = nil
        focusedEnemyThreatCountermeasurePreview = nil
        clearSafeEngagementFocus()
        latestCombatResult = nil
        latestTacticalCommandResult = nil
        latestObjectiveCaptureResult = nil
        latestDeploymentResult = nil
        latestReinforcementResult = nil
        latestEnemyThreatCountermeasureExecutionResult = nil
        latestEnemyThreatCountermeasureFollowUpResult = nil
        latestAIPhaseSummary = nil
        activeAIPhaseBaseline = nil
        activeAIPhaseActionCounts = AIPhaseActionCounts()
        activeAIPhaseTimeline = []
        pendingEnemyThreatCountermeasureFollowUpBaseline = nil
        commandPoints = [.allies: 6, .axis: 6]
        message = Self.openingMessage(for: newScenario)
        battleLog = [Self.openingLog(for: newScenario)]
    }

    private func move(
        unitID: BattleUnit.ID,
        to coordinate: HexCoordinate,
        preservingObjectiveGuidance: Bool = false
    ) {
        guard let index = scenario.units.firstIndex(where: { $0.id == unitID }) else { return }
        let origin = scenario.units[index].position
        focusedEnemyThreatCountermeasurePreview = nil
        latestEnemyThreatCountermeasureExecutionResult = nil
        latestEnemyThreatCountermeasureFollowUpResult = nil
        scenario.units[index].position = coordinate
        scenario.units[index].hasMoved = true
        scenario.units[index].tacticalStatus = .normal
        scenario.units[index].isEntrenched = false

        let unit = scenario.units[index]
        recordAIPhaseTimelineEvent(
            kind: .move,
            actorUnitID: unit.id,
            actorName: unit.name,
            actorKind: unit.kind,
            from: origin,
            to: coordinate,
            detail: "\(unit.name) \(origin.q),\(origin.r)->\(coordinate.q),\(coordinate.r)"
        )
        updateObjectiveControl()
        selectedUnitID = unit.id
        focusedCoordinate = coordinate
        if shouldClearObjectiveGuidance(afterMoving: unit, to: coordinate, preserving: preservingObjectiveGuidance) {
            clearObjectiveGuidance()
        }
        message = "\(unit.name) 进入 \(tile(at: coordinate)?.terrain.title ?? "未知地形")\(threatExposureText(for: unit.faction, at: coordinate))。"
        appendLog(message)
        recordAIPhaseAction(.move)
        checkVictory()
    }

    private func clearObjectiveGuidance() {
        guidedObjectiveCoordinate = nil
        focusedEnemyThreatCountermeasurePreview = nil
        clearSafeEngagementFocus()
    }

    private func clearSafeEngagementFocus() {
        focusedSafeEngagementTargetID = nil
        focusedSafeEngagementDestination = nil
    }

    private func threatExposureText(for faction: Faction, at coordinate: HexCoordinate) -> String {
        let threats = threateningEnemies(against: faction, at: coordinate)
        guard !threats.isEmpty else { return "" }

        let names = threats.prefix(2).map(\.name).joined(separator: "、")
        let extraCount = threats.count - min(threats.count, 2)
        let extraText = extraCount > 0 ? "等 \(threats.count) 支敌军" : ""
        return "，暴露在 \(names)\(extraText) 火力下"
    }

    private func fireExposureBriefText(for unit: BattleUnit, at coordinate: HexCoordinate) -> String {
        guard let preview = fireExposurePreview(for: unit, at: coordinate) else { return "" }
        guard preview.riskLevel != .none else { return "，无敌火暴露" }
        return "，\(preview.riskLevel.title)：潜在 -\(preview.totalPotentialDamage)，预计剩 \(preview.projectedHPAfterExposure)"
    }

    private func shouldPreserveObjectiveGuidance(for route: MovementRoute, unit: BattleUnit) -> Bool {
        guard let guidedObjectiveTile,
              guidedObjectiveTile.owner != unit.faction,
              self.unit(at: guidedObjectiveTile.coordinate) == nil,
              let guidedRoute = objectiveAdvanceRoute(for: unit, to: guidedObjectiveTile) else { return false }
        return guidedRoute == route
    }

    private func shouldClearObjectiveGuidance(
        afterMoving unit: BattleUnit,
        to coordinate: HexCoordinate,
        preserving: Bool
    ) -> Bool {
        guard preserving,
              let guidedObjectiveCoordinate,
              let guidedObjective = tile(at: guidedObjectiveCoordinate),
              guidedObjective.isObjective,
              guidedObjective.owner != unit.faction,
              coordinate != guidedObjectiveCoordinate else { return true }
        return false
    }

    private func attack(attackerID: BattleUnit.ID, targetID: BattleUnit.ID) {
        guard let attackerIndex = scenario.units.firstIndex(where: { $0.id == attackerID }),
              let targetIndex = scenario.units.firstIndex(where: { $0.id == targetID }) else { return }

        clearObjectiveGuidance()
        let attacker = scenario.units[attackerIndex]
        let defender = scenario.units[targetIndex]
        let supportBonus = flankingSupportDamageBonusPercent(attacker: attacker, defender: defender)
        let supportText = supportBonus > 0 ? "（夹击 +\(supportBonus)%）" : ""
        let damage = damageValue(attacker: attacker, defender: defender)
        let defenderWasEntrenched = defender.isEntrenched

        scenario.units[targetIndex].hp = max(0, scenario.units[targetIndex].hp - damage)
        scenario.units[targetIndex].isEntrenched = false
        let targetDestroyed = scenario.units[targetIndex].isDestroyed
        let keepsMovementAfterKill = targetDestroyed && canUseManeuverPursuit(afterDestroyingWith: attacker)
        scenario.units[attackerIndex].hasAttacked = true
        scenario.units[attackerIndex].hasMoved = !keepsMovementAfterKill
        scenario.units[attackerIndex].tacticalStatus = .normal
        scenario.units[attackerIndex].isEntrenched = false
        awardExperience(
            to: attackerID,
            amount: experienceForDamage(damage) + (targetDestroyed ? 18 : 0),
            reason: targetDestroyed ? "击毁" : "攻击"
        )
        adjustMorale(
            unitID: attackerID,
            delta: targetDestroyed ? 12 : 6,
            reason: targetDestroyed ? "击毁敌军" : "攻击奏效"
        )

        let counterDamage: Int
        if targetDestroyed {
            counterDamage = 0
            let pursuitText = keepsMovementAfterKill ? "，可继续机动" : ""
            message = "\(attacker.name) 击毁 \(defender.name)，造成 \(damage) 伤害\(supportText)\(pursuitText)。"
        } else {
            adjustMorale(unitID: targetID, delta: -10, reason: "遭受攻击")
            message = "\(attacker.name) 攻击 \(defender.name)，造成 \(damage) 伤害\(supportText)。"
            counterDamage = counterAttackIfPossible(defenderID: targetID, attackerID: attackerID)
        }

        if let finalAttacker = scenario.units.first(where: { $0.id == attackerID }),
           let finalDefender = scenario.units.first(where: { $0.id == targetID }) {
            latestCombatResult = CombatResultSummary(
                attacker: combatantResultSnapshot(starting: attacker, ending: finalAttacker),
                defender: combatantResultSnapshot(starting: defender, ending: finalDefender),
                damage: damage,
                counterDamage: counterDamage,
                supportDamageBonusPercent: supportBonus,
                didDestroyDefender: finalDefender.isDestroyed,
                didDestroyAttacker: finalAttacker.isDestroyed,
                didTriggerManeuverPursuit: keepsMovementAfterKill,
                didConsumeDefenderEntrenchment: defenderWasEntrenched
            )
            latestTacticalCommandResult = nil
            latestObjectiveCaptureResult = nil
            latestDeploymentResult = nil
            latestReinforcementResult = nil
            latestEnemyThreatCountermeasureExecutionResult = nil
            latestEnemyThreatCountermeasureFollowUpResult = nil
            recordAIPhaseTimelineEvent(
                kind: .attack,
                actorUnitID: finalAttacker.id,
                actorName: finalAttacker.name,
                actorKind: finalAttacker.kind,
                targetUnitID: finalDefender.id,
                targetName: finalDefender.name,
                targetKind: finalDefender.kind,
                from: finalAttacker.position,
                to: finalDefender.position,
                damage: damage,
                counterDamage: counterDamage,
                didDestroyTarget: finalDefender.isDestroyed,
                detail: "\(finalAttacker.name) 攻击 \(finalDefender.name) -\(damage)"
            )
        }

        appendLog(message)
        recordAIPhaseAction(.attack)
        updateObjectiveControl()
        checkVictory()
        selectNextReadyUnit(preferredUnitID: keepsMovementAfterKill ? attackerID : nil)
    }

    private func combatantResultSnapshot(
        starting: BattleUnit,
        ending: BattleUnit
    ) -> CombatantResultSnapshot {
        CombatantResultSnapshot(
            unitID: starting.id,
            name: starting.name,
            kind: starting.kind,
            faction: starting.faction,
            startingHP: starting.hp,
            endingHP: ending.hp,
            startingExperience: starting.experience,
            endingExperience: ending.experience,
            startingMorale: starting.morale,
            endingMorale: ending.morale,
            startingRank: starting.rank,
            endingRank: ending.rank
        )
    }

    private func counterAttackIfPossible(defenderID: BattleUnit.ID, attackerID: BattleUnit.ID) -> Int {
        guard let defenderIndex = scenario.units.firstIndex(where: { $0.id == defenderID }),
              let attackerIndex = scenario.units.firstIndex(where: { $0.id == attackerID }) else { return 0 }

        let defender = scenario.units[defenderIndex]
        let attacker = scenario.units[attackerIndex]
        guard !defender.isDestroyed,
              !attacker.isDestroyed,
              defender.position.distance(to: attacker.position) <= defender.range else { return 0 }

        let counterDamage = counterDamageValue(defender: defender, attacker: attacker)
        scenario.units[attackerIndex].hp = max(0, scenario.units[attackerIndex].hp - counterDamage)
        awardExperience(
            to: defenderID,
            amount: experienceForDamage(counterDamage),
            reason: "反击"
        )
        adjustMorale(unitID: defenderID, delta: 4, reason: "反击成功")
        adjustMorale(unitID: attackerID, delta: -5, reason: "遭到反击")
        appendLog("\(defender.name) 反击 \(attacker.name)，造成 \(counterDamage) 伤害。")
        return counterDamage
    }

    private func counterDamageValue(defender: BattleUnit, attacker: BattleUnit) -> Int {
        var counterDamage = max(6, damageValue(attacker: defender, defender: attacker) / 2)
        if defender.commander?.name == "曼施坦因" {
            counterDamage += 5
        }
        return counterDamage
    }

    private func tacticalCommandDamage(command: TacticalCommand, caster: BattleUnit, target: BattleUnit) -> Int {
        switch command {
        case .artilleryBarrage:
            let terrainDefense = tile(at: target.position)?.terrain.defenseBonus ?? 0
            let healthFactor = max(45, caster.hp) * 100 / caster.maxHP
            let moraleFactor = caster.moraleState.attackMultiplierPercent
            let supplyFactor = supplyState(for: caster).attackMultiplierPercent
            let terrainFactor = tile(at: target.position)?.terrain.attackMultiplierPercent(for: .artillery) ?? 100
            let scaled = effectiveAttack(for: caster) * healthFactor * moraleFactor * supplyFactor * terrainFactor / 100_000_000
            return applyDefensePosture(to: max(10, scaled - terrainDefense / 2), defender: target)
        case .breakthroughAssault:
            return max(12, damageValue(attacker: caster, defender: target) * 115 / 100)
        }
    }

    private func applyDefensePosture(to damage: Int, defender: BattleUnit) -> Int {
        max(1, damage * defenseDamageMultiplierPercent(for: defender) / 100)
    }

    private func defenseDamageMultiplierPercent(for defender: BattleUnit) -> Int {
        defender.isEntrenched ? Self.entrenchedDamageMultiplierPercent : 100
    }

    private func reinforce(unitID: BattleUnit.ID) {
        guard let index = scenario.units.firstIndex(where: { $0.id == unitID }) else { return }
        let unit = scenario.units[index]
        guard canReinforce(unit) else {
            message = "该单位必须在己方据点且有损伤，才可整补。"
            return
        }

        clearObjectiveGuidance()
        let cost = reinforceCost(for: unit)
        let startingHP = unit.hp
        spendCommandPoints(cost, for: activeFaction)
        let recovered = min(unit.kind.reinforceAmount, unit.maxHP - unit.hp)
        scenario.units[index].hp += recovered
        scenario.units[index].hasMoved = true
        scenario.units[index].hasAttacked = true
        scenario.units[index].tacticalStatus = .normal
        scenario.units[index].isEntrenched = false
        selectedUnitID = scenario.units[index].id
        focusedCoordinate = scenario.units[index].position
        latestReinforcementResult = ReinforcementResultSummary(
            unitID: scenario.units[index].id,
            unitName: scenario.units[index].name,
            unitKind: scenario.units[index].kind,
            faction: scenario.units[index].faction,
            coordinate: scenario.units[index].position,
            startingHP: startingHP,
            endingHP: scenario.units[index].hp,
            recoveredHP: recovered,
            commandCost: cost,
            commandPointsAfterReinforcement: commandPoints(for: scenario.units[index].faction)
        )
        latestCombatResult = nil
        latestTacticalCommandResult = nil
        latestObjectiveCaptureResult = nil
        latestDeploymentResult = nil
        latestEnemyThreatCountermeasureExecutionResult = nil
        latestEnemyThreatCountermeasureFollowUpResult = nil
        recordAIPhaseTimelineEvent(
            kind: .reinforcement,
            actorUnitID: scenario.units[index].id,
            actorName: scenario.units[index].name,
            actorKind: scenario.units[index].kind,
            to: scenario.units[index].position,
            recoveredHP: recovered,
            commandPointCost: cost,
            commandPointsAfter: commandPoints(for: scenario.units[index].faction),
            detail: "\(scenario.units[index].name) +\(recovered)"
        )
        message = "\(unit.name) 整补 +\(recovered) 耐久，消耗 \(cost) 指令点。"
        appendLog(message)
        recordAIPhaseAction(.reinforcement)
        selectNextReadyUnit()
    }

    private func addCommandIncome(for faction: Faction) {
        commandPoints[faction, default: 0] += commandIncome(for: faction)
    }

    private func spendCommandPoints(_ amount: Int, for faction: Faction) {
        commandPoints[faction, default: 0] = max(0, commandPoints[faction, default: 0] - amount)
    }

    private func beginAIPhaseRecording(for faction: Faction) {
        let objectiveOwners = Dictionary(uniqueKeysWithValues: objectiveTiles.compactMap { tile -> (HexCoordinate, Faction)? in
            guard let owner = tile.owner else { return nil }
            return (tile.coordinate, owner)
        })
        activeAIPhaseBaseline = AIPhaseBaseline(
            faction: faction,
            turn: turn,
            commandPoints: commandPoints(for: faction),
            unitHPByID: Dictionary(uniqueKeysWithValues: scenario.units.map { ($0.id, max(0, $0.hp)) }),
            unitFactionByID: Dictionary(uniqueKeysWithValues: scenario.units.map { ($0.id, $0.faction) }),
            aliveUnitIDs: Set(scenario.units.filter { !$0.isDestroyed }.map(\.id)),
            objectiveOwnersByCoordinate: objectiveOwners
        )
        activeAIPhaseActionCounts = AIPhaseActionCounts()
        activeAIPhaseTimeline = []
    }

    private func finishAIPhaseRecording() {
        guard let baseline = activeAIPhaseBaseline else { return }
        latestAIPhaseSummary = aiPhaseSummary(
            from: baseline,
            counts: activeAIPhaseActionCounts
        )
        activeAIPhaseBaseline = nil
        activeAIPhaseActionCounts = AIPhaseActionCounts()
        activeAIPhaseTimeline = []
    }

    private func recordAIPhaseAction(_ action: AIPhaseAction) {
        guard let baseline = activeAIPhaseBaseline,
              baseline.faction == activeFaction else { return }

        switch action {
        case .reinforcement:
            activeAIPhaseActionCounts.reinforcements += 1
        case .deployment:
            activeAIPhaseActionCounts.deployments += 1
        case .tacticalCommand:
            activeAIPhaseActionCounts.tacticalCommands += 1
        case .attack:
            activeAIPhaseActionCounts.attacks += 1
        case .move:
            activeAIPhaseActionCounts.moves += 1
        }
    }

    private func recordAIPhaseTimelineEvent(
        kind: AIPhaseTimelineEventKind,
        actorUnitID: BattleUnit.ID?,
        actorName: String,
        actorKind: UnitKind?,
        targetUnitID: BattleUnit.ID? = nil,
        targetName: String? = nil,
        targetKind: UnitKind? = nil,
        from: HexCoordinate? = nil,
        to: HexCoordinate? = nil,
        tacticalCommand: TacticalCommand? = nil,
        deployedUnitKind: UnitKind? = nil,
        objectiveName: String? = nil,
        previousOwner: Faction? = nil,
        newOwner: Faction? = nil,
        damage: Int = 0,
        counterDamage: Int = 0,
        recoveredHP: Int = 0,
        commandPointCost: Int = 0,
        commandPointReward: Int = 0,
        commandPointsAfter: Int? = nil,
        didDestroyTarget: Bool = false,
        didCaptureObjective: Bool = false,
        detail: String = ""
    ) {
        guard let baseline = activeAIPhaseBaseline,
              baseline.faction == activeFaction else { return }
        if kind == .objectiveCapture,
           let newOwner,
           newOwner != baseline.faction {
            return
        }

        activeAIPhaseTimeline.append(
            AIPhaseTimelineEvent(
                order: activeAIPhaseTimeline.count + 1,
                faction: baseline.faction,
                turn: baseline.turn,
                kind: kind,
                actorUnitID: actorUnitID,
                actorName: actorName,
                actorKind: actorKind,
                targetUnitID: targetUnitID,
                targetName: targetName,
                targetKind: targetKind,
                from: from,
                to: to,
                tacticalCommand: tacticalCommand,
                deployedUnitKind: deployedUnitKind,
                objectiveName: objectiveName,
                previousOwner: previousOwner,
                newOwner: newOwner,
                damage: damage,
                counterDamage: counterDamage,
                recoveredHP: recoveredHP,
                commandPointCost: commandPointCost,
                commandPointReward: commandPointReward,
                commandPointsAfter: commandPointsAfter,
                didDestroyTarget: didDestroyTarget,
                didCaptureObjective: didCaptureObjective,
                detail: detail
            )
        )
    }

    private func aiPhaseSummary(
        from baseline: AIPhaseBaseline,
        counts: AIPhaseActionCounts
    ) -> AIPhaseSummary {
        let endingHPByID = Dictionary(uniqueKeysWithValues: scenario.units.map { ($0.id, max(0, $0.hp)) })
        let enemyUnitIDs = baseline.aliveUnitIDs.filter {
            baseline.unitFactionByID[$0] != baseline.faction
        }
        let friendlyUnitIDs = baseline.aliveUnitIDs.filter {
            baseline.unitFactionByID[$0] == baseline.faction
        }

        let damageDealt = totalDamage(
            for: enemyUnitIDs,
            baselineHPByID: baseline.unitHPByID,
            endingHPByID: endingHPByID
        )
        let damageTaken = totalDamage(
            for: friendlyUnitIDs,
            baselineHPByID: baseline.unitHPByID,
            endingHPByID: endingHPByID
        )
        let enemyUnitsDestroyed = enemyUnitIDs.filter {
            (endingHPByID[$0] ?? 0) <= 0
        }.count
        let friendlyUnitsDestroyed = friendlyUnitIDs.filter {
            (endingHPByID[$0] ?? 0) <= 0
        }.count
        let objectivesCaptured = objectiveTiles.filter { tile in
            tile.owner == baseline.faction &&
                baseline.objectiveOwnersByCoordinate[tile.coordinate] != baseline.faction
        }.count

        return AIPhaseSummary(
            faction: baseline.faction,
            turn: baseline.turn,
            startingCommandPoints: baseline.commandPoints,
            endingCommandPoints: commandPoints(for: baseline.faction),
            reinforcements: counts.reinforcements,
            deployments: counts.deployments,
            tacticalCommands: counts.tacticalCommands,
            attacks: counts.attacks,
            moves: counts.moves,
            objectivesCaptured: objectivesCaptured,
            enemyUnitsDestroyed: enemyUnitsDestroyed,
            friendlyUnitsDestroyed: friendlyUnitsDestroyed,
            damageDealt: damageDealt,
            damageTaken: damageTaken,
            timeline: activeAIPhaseTimeline
        )
    }

    private func totalDamage<S: Sequence>(
        for unitIDs: S,
        baselineHPByID: [BattleUnit.ID: Int],
        endingHPByID: [BattleUnit.ID: Int]
    ) -> Int where S.Element == BattleUnit.ID {
        unitIDs.reduce(0) { total, unitID in
            let startingHP = baselineHPByID[unitID] ?? 0
            let endingHP = endingHPByID[unitID] ?? 0
            return total + max(0, startingHP - endingHP)
        }
    }

    private func applySupplyAttrition(for faction: Faction) {
        var attritionEntries: [String] = []

        for index in scenario.units.indices where scenario.units[index].faction == faction && !scenario.units[index].isDestroyed {
            let state = supplyState(for: scenario.units[index])
            guard state == .isolated else { continue }

            scenario.units[index].hp = max(1, scenario.units[index].hp - state.attritionDamage)
            adjustMorale(unitID: scenario.units[index].id, delta: -8, reason: "断补给")
            attritionEntries.append("\(scenario.units[index].name) 断补给，损失 \(state.attritionDamage) 耐久。")
        }

        for entry in attritionEntries {
            appendLog(entry)
        }
    }

    private func recoverMorale(for faction: Faction) {
        for unit in units where unit.faction == faction {
            guard supplyState(for: unit) == .supplied else { continue }
            let onOwnedObjective = tile(at: unit.position)?.owner == unit.faction &&
                tile(at: unit.position)?.isObjective == true
            adjustMorale(
                unitID: unit.id,
                delta: onOwnedObjective ? 10 : 4,
                reason: onOwnedObjective ? "据点休整" : "补给恢复"
            )
        }
    }

    private func recoverObjectiveRest(for faction: Faction) {
        var recoveryEntries: [String] = []

        for index in scenario.units.indices where scenario.units[index].faction == faction && !scenario.units[index].isDestroyed {
            let recovered = objectiveRestRecovery(for: scenario.units[index])
            guard recovered > 0 else { continue }

            scenario.units[index].hp += recovered
            recoveryEntries.append("\(scenario.units[index].name) 在己方据点休整，恢复 \(recovered) 耐久。")
        }

        for entry in recoveryEntries {
            appendLog(entry)
        }
    }

    private func awardExperience(to unitID: BattleUnit.ID, amount: Int, reason: String) {
        guard amount > 0,
              let index = scenario.units.firstIndex(where: { $0.id == unitID }),
              !scenario.units[index].isDestroyed else { return }

        let previousRank = scenario.units[index].rank
        scenario.units[index].experience += amount
        let newRank = scenario.units[index].rank
        if newRank != previousRank {
            let hpGain = newRank.hpBonus - previousRank.hpBonus
            scenario.units[index].hp = min(
                scenario.units[index].maxHP,
                scenario.units[index].hp + max(0, hpGain)
            )
            appendLog("\(scenario.units[index].name) 晋升为\(newRank.title)，攻击 +\(newRank.attackBonus)，耐久上限 +\(newRank.hpBonus)。")
        } else {
            appendLog("\(scenario.units[index].name) 因\(reason)获得 \(amount) 经验。")
        }
    }

    private func experienceForDamage(_ damage: Int) -> Int {
        max(3, damage / 4)
    }

    private func adjustMorale(unitID: BattleUnit.ID, delta: Int, reason: String) {
        guard delta != 0,
              let index = scenario.units.firstIndex(where: { $0.id == unitID }),
              !scenario.units[index].isDestroyed else { return }

        let previousState = scenario.units[index].moraleState
        scenario.units[index].morale = max(0, min(100, scenario.units[index].morale + delta))
        let newState = scenario.units[index].moraleState

        if newState != previousState {
            appendLog("\(scenario.units[index].name) 因\(reason)\(delta > 0 ? "士气提升" : "士气受挫")，进入\(newState.title)。")
        }
    }

    private func damageValue(attacker: BattleUnit, defender: BattleUnit) -> Int {
        let terrainDefense = tile(at: defender.position)?.terrain.defenseBonus ?? 0
        var commanderDefense = defender.commander?.morale ?? 0
        if defender.commander?.name == "蒙哥马利",
           tile(at: defender.position)?.terrain == .city {
            commanderDefense += 6
        }

        let healthFactor = max(40, attacker.hp) * 100 / attacker.maxHP
        let supplyFactor = supplyState(for: attacker).attackMultiplierPercent
        let moraleFactor = attacker.moraleState.attackMultiplierPercent
        let matchupFactor = matchupAttackMultiplier(attacker: attacker, defender: defender)
        let terrainAttackFactor = terrainAttackMultiplier(attacker: attacker, defender: defender)
        let commanderAuraFactor = 100 + commanderAuraDamageBonusPercent(attacker: attacker)
        let scaledAttack = effectiveAttack(for: attacker) * healthFactor * supplyFactor * moraleFactor * matchupFactor * terrainAttackFactor * commanderAuraFactor / 1_000_000_000_000
        let supportedAttack = scaledAttack * (100 + flankingSupportDamageBonusPercent(attacker: attacker, defender: defender)) / 100
        return applyDefensePosture(to: max(8, supportedAttack - terrainDefense - commanderDefense), defender: defender)
    }

    private func commanderAuraDamageBonusPercent(attacker: BattleUnit) -> Int {
        commanderSupport(attacker: attacker) == nil ? 0 : Self.commanderAuraDamageBonusPercent
    }

    private func flankingSupportDamageBonusPercent(attacker: BattleUnit, defender: BattleUnit) -> Int {
        flankingSupportDamageBonusPercent(forSupportCount: flankingSupportUnits(attacker: attacker, defender: defender).count)
    }

    private func flankingSupportDamageBonusPercent(forSupportCount supportCount: Int) -> Int {
        min(supportCount * Self.flankingSupportBonusPercent, Self.maxFlankingSupportBonusPercent)
    }

    private func matchupAttackMultiplier(attacker: BattleUnit, defender: BattleUnit) -> Int {
        attacker.kind.matchupAttackMultiplierPercent(against: defender.kind)
    }

    private func terrainAttackMultiplier(attacker: BattleUnit, defender: BattleUnit) -> Int {
        tile(at: defender.position)?.terrain.attackMultiplierPercent(for: attacker.kind) ?? 100
    }

    private func movementCost(for unit: BattleUnit, entering tile: TerrainTile) -> Int {
        tile.terrain.movementCost(for: unit.kind) +
            enemyControlZonePenalty(for: unit, entering: tile.coordinate)
    }

    private func effectiveMovement(for unit: BattleUnit) -> Int {
        max(1, unit.movement - supplyState(for: unit).movementPenalty - unit.tacticalStatus.movementPenalty + unit.moraleState.movementModifier)
    }

    private func effectiveAttack(for unit: BattleUnit) -> Int {
        unit.attack * unit.tacticalStatus.attackMultiplierPercent / 100
    }

    private func runAxisAI() {
        runAxisLogistics()

        var actedIDs: [BattleUnit.ID] = []

        while winner == nil,
              let unit = scenario.units.first(where: { unit in
            unit.faction == .axis &&
            !unit.isDestroyed &&
            !actedIDs.contains(unit.id) &&
            (!unit.hasMoved || !unit.hasAttacked)
        }) {
            actedIDs.append(unit.id)

            if let target = bestAttackTarget(for: unit, requiringKill: true) {
                attack(attackerID: unit.id, targetID: target.id)
                advanceAfterManeuverPursuitIfPossible(unitID: unit.id)
                continue
            }

            if let plan = bestTacticalCommandPlan(for: unit) {
                useTacticalCommand(plan.command, casterID: unit.id, targetID: plan.target.id)
                continue
            }

            if let destination = bestImmediateObjectiveCaptureDestination(for: unit) {
                move(unitID: unit.id, to: destination)
                if winner != nil {
                    break
                }
                resolveAxisPostMoveAction(unitID: unit.id)
                continue
            }

            if let target = bestAttackTarget(for: unit) {
                attack(attackerID: unit.id, targetID: target.id)
                continue
            }

            if let destination = bestAdvanceDestination(for: unit) {
                move(unitID: unit.id, to: destination)
            }

            if winner != nil {
                break
            }

            resolveAxisPostMoveAction(unitID: unit.id)
        }
    }

    private func bestAttackTarget(for unit: BattleUnit, requiringKill: Bool = false) -> BattleUnit? {
        guard !unit.hasAttacked else { return nil }

        return units
            .filter { target in
                target.faction != unit.faction &&
                !target.isDestroyed &&
                unit.position.distance(to: target.position) <= unit.range
            }
            .compactMap { target -> (target: BattleUnit, preview: CombatPreview, score: Int)? in
                guard let preview = combatPreview(attacker: unit, defender: target),
                      !requiringKill || preview.willDestroyDefender else { return nil }
                let commanderBonus = target.commander == nil ? 0 : 18
                let score = (preview.willDestroyDefender ? 120 : 0) +
                    preview.damage +
                    target.kind.commandCost * 3 +
                    commanderBonus -
                    target.hp / 8
                return (target, preview, score)
            }
            .sorted { left, right in
                if left.score == right.score {
                    return left.target.hp < right.target.hp
                }
                return left.score > right.score
            }
            .first?
            .target
    }

    private func bestTacticalCommandPlan(for unit: BattleUnit) -> (command: TacticalCommand, target: BattleUnit, preview: TacticalCommandPreview)? {
        guard !unit.hasAttacked else { return nil }

        return TacticalCommand.allCases
            .filter { commandPoints(for: unit.faction) >= $0.commandCost }
            .flatMap { command in
                tacticalCommandTargets(for: unit, command: command)
                    .compactMap { target -> (command: TacticalCommand, target: BattleUnit, preview: TacticalCommandPreview, score: Int)? in
                        guard let preview = tacticalCommandPreview(command: command, caster: unit, target: target),
                              shouldUseTacticalCommand(command, caster: unit, target: target, preview: preview) else { return nil }

                        let distance = unit.position.distance(to: target.position)
                        let commanderBonus = target.commander == nil ? 0 : 22
                        let rangeBonus = distance > unit.range ? 32 : 0
                        let moraleBonus = target.moraleState == .inspired ? 10 : 0
                        let score = (preview.willDestroyTarget ? 140 : 0) +
                            rangeBonus +
                            commanderBonus +
                            moraleBonus +
                            preview.damage +
                            target.kind.commandCost * 4 -
                            target.hp / 10
                        return (command, target, preview, score)
                    }
            }
            .sorted { left, right in
                if left.score == right.score {
                    return left.preview.damage > right.preview.damage
                }
                return left.score > right.score
            }
            .first
            .map { (command: $0.command, target: $0.target, preview: $0.preview) }
    }

    private func shouldUseTacticalCommand(
        _ command: TacticalCommand,
        caster: BattleUnit,
        target: BattleUnit,
        preview: TacticalCommandPreview
    ) -> Bool {
        switch command {
        case .artilleryBarrage:
            let distance = caster.position.distance(to: target.position)
            return preview.willDestroyTarget ||
                distance > caster.range ||
                target.commander != nil ||
                target.moraleState == .inspired
        case .breakthroughAssault:
            return preview.willDestroyTarget ||
                target.commander != nil ||
                target.moraleState == .inspired
        }
    }

    private func runAxisLogistics() {
        while let unit = axisReinforcementCandidate() {
            reinforce(unitID: unit.id)
        }

        deployAxisReinforcementIfPossible()
    }

    private func advanceAfterManeuverPursuitIfPossible(unitID: BattleUnit.ID) {
        guard winner == nil,
              let unit = scenario.units.first(where: { $0.id == unitID }),
              unit.faction == activeFaction,
              unit.hasAttacked,
              !unit.hasMoved,
              let destination = bestAdvanceDestination(for: unit) else { return }
        move(unitID: unit.id, to: destination)
    }

    private func resolveAxisPostMoveAction(unitID: BattleUnit.ID) {
        if let refreshed = scenario.units.first(where: { $0.id == unitID }),
           let target = bestAttackTarget(for: refreshed) {
            attack(attackerID: refreshed.id, targetID: target.id)
            advanceAfterManeuverPursuitIfPossible(unitID: refreshed.id)
        } else if let refreshed = scenario.units.first(where: { $0.id == unitID }),
                  let plan = bestTacticalCommandPlan(for: refreshed) {
            useTacticalCommand(plan.command, casterID: refreshed.id, targetID: plan.target.id)
        } else {
            updateUnit(id: unitID) { axisUnit in
                axisUnit.hasMoved = true
                axisUnit.hasAttacked = true
                axisUnit.isEntrenched = true
            }
        }
    }

    private func axisReinforcementCandidate() -> BattleUnit? {
        units
            .filter { $0.faction == .axis && canReinforce($0) }
            .sorted { left, right in
                if left.hp == right.hp {
                    return left.kind.commandCost > right.kind.commandCost
                }
                return left.hp < right.hp
            }
            .first
    }

    private func deployAxisReinforcementIfPossible() {
        guard let site = deploymentSites(for: .axis).first else { return }
        let affordableKinds = UnitKind.allCases
            .filter { commandPoints(for: .axis) >= $0.commandCost }
            .sorted { left, right in
                if left.commandCost == right.commandCost {
                    return left.sortOrder < right.sortOrder
                }
                return left.commandCost > right.commandCost
            }
        guard let kind = affordableKinds.first else { return }
        deploy(kind: kind, at: site.coordinate)
    }

    private func bestImmediateObjectiveCaptureDestination(for unit: BattleUnit) -> HexCoordinate? {
        guard unit.canMove else { return nil }

        return reachableTiles(for: unit)
            .compactMap { coordinate -> (coordinate: HexCoordinate, priority: Int, distance: Int)? in
                guard self.unit(at: coordinate) == nil,
                      let tile = tile(at: coordinate),
                      tile.isObjective,
                      tile.owner != unit.faction else { return nil }

                let priority = tile.owner == nil ? 1 : 2
                return (
                    coordinate,
                    priority,
                    nearestAdvanceTargetDistance(from: coordinate, for: unit)
                )
            }
            .sorted { left, right in
                if left.priority != right.priority {
                    return left.priority > right.priority
                }
                if left.distance != right.distance {
                    return left.distance < right.distance
                }
                return left.coordinate.id < right.coordinate.id
            }
            .first?
            .coordinate
    }

    private func bestAdvanceDestination(for unit: BattleUnit) -> HexCoordinate? {
        reachableTiles(for: unit)
            .compactMap { coordinate -> (coordinate: HexCoordinate, score: Int, distance: Int)? in
                guard let tile = tile(at: coordinate) else { return nil }
                let score = advanceScore(for: unit, movingTo: coordinate, tile: tile)
                guard score > 0 else { return nil }
                return (coordinate, score, nearestAdvanceTargetDistance(from: coordinate, for: unit))
            }
            .sorted { left, right in
                if left.score == right.score {
                    if left.distance == right.distance {
                        return left.coordinate.id < right.coordinate.id
                    }
                    return left.distance < right.distance
                }
                return left.score > right.score
            }
            .first?
            .coordinate
    }

    private func advanceScore(for unit: BattleUnit, movingTo coordinate: HexCoordinate, tile: TerrainTile) -> Int {
        var score = 0

        if tile.isObjective, tile.owner != unit.faction {
            score += tile.owner == nil ? 900 : 1_100
        }

        if let attackScore = attackOpportunityScore(for: unit, from: coordinate) {
            score += 500 + attackScore
        }

        if let objectiveProgress = distanceProgress(
            from: unit.position,
            to: coordinate,
            targets: objectiveTiles.filter { $0.owner != unit.faction }.map(\.coordinate)
        ) {
            score += objectiveProgress * 80
        }

        if let enemyProgress = distanceProgress(
            from: unit.position,
            to: coordinate,
            targets: units.filter { $0.faction != unit.faction }.map(\.position)
        ) {
            score += enemyProgress * 35
        }

        return score
    }

    private func attackOpportunityScore(for unit: BattleUnit, from coordinate: HexCoordinate) -> Int? {
        units
            .filter { target in
                target.faction != unit.faction &&
                !target.isDestroyed &&
                coordinate.distance(to: target.position) <= unit.range
            }
            .map { target in
                let commanderBonus = target.commander == nil ? 0 : 24
                return target.kind.commandCost * 8 + commanderBonus - target.hp / 8
            }
            .max()
    }

    private func distanceProgress(from origin: HexCoordinate, to destination: HexCoordinate, targets: [HexCoordinate]) -> Int? {
        guard let currentDistance = targets.map({ origin.distance(to: $0) }).min(),
              let newDistance = targets.map({ destination.distance(to: $0) }).min() else { return nil }
        return max(0, currentDistance - newDistance)
    }

    private func nearestAdvanceTargetDistance(from coordinate: HexCoordinate, for unit: BattleUnit) -> Int {
        let targets = objectiveTiles
            .filter { $0.owner != unit.faction }
            .map(\.coordinate) +
            units
            .filter { $0.faction != unit.faction }
            .map(\.position)

        return targets.map { coordinate.distance(to: $0) }.min() ?? 0
    }

    private func updateObjectiveControl() {
        for index in scenario.tiles.indices where scenario.tiles[index].isObjective {
            if let occupyingUnit = unit(at: scenario.tiles[index].coordinate) {
                let previousOwner = scenario.tiles[index].owner
                guard previousOwner != occupyingUnit.faction else { continue }

                scenario.tiles[index].owner = occupyingUnit.faction
                applyObjectiveCaptureReward(
                    to: occupyingUnit,
                    coordinate: scenario.tiles[index].coordinate,
                    objectiveName: scenario.tiles[index].objectiveName ?? "据点",
                    previousOwner: previousOwner
                )
            }
        }
    }

    private func applyObjectiveCaptureReward(
        to unit: BattleUnit,
        coordinate: HexCoordinate,
        objectiveName: String,
        previousOwner: Faction?
    ) {
        commandPoints[unit.faction, default: 0] += Self.objectiveCaptureCommandReward
        awardExperience(
            to: unit.id,
            amount: Self.objectiveCaptureExperienceReward,
            reason: "夺取据点"
        )
        adjustMorale(
            unitID: unit.id,
            delta: Self.objectiveCaptureMoraleReward,
            reason: "夺取\(objectiveName)"
        )

        let action = previousOwner == nil ? "占领" : "夺取"
        latestObjectiveCaptureResult = ObjectiveCaptureResultSummary(
            objectiveName: objectiveName,
            coordinate: coordinate,
            capturingUnitName: unit.name,
            capturingUnitKind: unit.kind,
            previousOwner: previousOwner,
            newOwner: unit.faction,
            commandPointReward: Self.objectiveCaptureCommandReward,
            moraleReward: Self.objectiveCaptureMoraleReward,
            experienceReward: Self.objectiveCaptureExperienceReward,
            alliedScoreAfterCapture: alliedScore,
            axisScoreAfterCapture: axisScore,
            totalObjectiveCount: objectiveTiles.count
        )
        latestCombatResult = nil
        latestTacticalCommandResult = nil
        latestDeploymentResult = nil
        latestReinforcementResult = nil
        latestEnemyThreatCountermeasureExecutionResult = nil
        latestEnemyThreatCountermeasureFollowUpResult = nil
        recordAIPhaseTimelineEvent(
            kind: .objectiveCapture,
            actorUnitID: unit.id,
            actorName: unit.name,
            actorKind: unit.kind,
            to: coordinate,
            objectiveName: objectiveName,
            previousOwner: previousOwner,
            newOwner: unit.faction,
            commandPointReward: Self.objectiveCaptureCommandReward,
            commandPointsAfter: commandPoints(for: unit.faction),
            didCaptureObjective: true,
            detail: "\(objectiveName) \(previousOwner?.title ?? "中立")->\(unit.faction.title)"
        )
        appendLog("\(unit.name)\(action)\(objectiveName)，\(unit.faction.title)获得 \(Self.objectiveCaptureCommandReward) 指令点。")
    }

    private func checkVictory() {
        let alliedAlive = units.contains { $0.faction == .allies }
        let axisAlive = units.contains { $0.faction == .axis }
        let allObjectivesAllied = !objectiveTiles.isEmpty && objectiveTiles.allSatisfy { $0.owner == .allies }
        let allObjectivesAxis = !objectiveTiles.isEmpty && objectiveTiles.allSatisfy { $0.owner == .axis }

        if !axisAlive || allObjectivesAllied {
            winner = .allies
            earnedStars = alliedVictoryStars()
            selectedUnitID = nil
            message = "盟军胜利：完成 \(scenario.name) 目标，获得 \(earnedStars) 星。"
            appendLog(message)
        } else if !alliedAlive || allObjectivesAxis {
            winner = .axis
            earnedStars = 0
            selectedUnitID = nil
            message = "任务失败：盟军防线崩溃。"
            appendLog(message)
        }
    }

    private func checkTurnLimit() {
        guard winner == nil, turn > scenario.turnLimit else { return }
        winner = .axis
        earnedStars = 0
        selectedUnitID = nil
        message = "任务失败：超过 \(scenario.turnLimit) 回合期限。"
        appendLog(message)
    }

    private func alliedVictoryStars() -> Int {
        let survivedAllies = units.filter { $0.faction == .allies }.count
        return 1 +
            (turn <= scenario.decisiveTurnLimit ? 1 : 0) +
            (survivedAllies >= scenario.survivalStarThreshold ? 1 : 0)
    }

    private func resetUnits(for faction: Faction) {
        for index in scenario.units.indices where scenario.units[index].faction == faction {
            scenario.units[index].hasMoved = false
            scenario.units[index].hasAttacked = false
        }
        applySupplyAttrition(for: faction)
        recoverObjectiveRest(for: faction)
        recoverMorale(for: faction)
    }

    private func updateUnit(id: BattleUnit.ID, mutate: (inout BattleUnit) -> Void) {
        guard let index = scenario.units.firstIndex(where: { $0.id == id }) else { return }
        mutate(&scenario.units[index])
    }

    private func selectNextReadyUnit(preferredUnitID: BattleUnit.ID? = nil) {
        guard winner == nil else {
            selectedUnitID = nil
            clearObjectiveGuidance()
            return
        }

        if let preferredUnitID,
           let preferredUnit = scenario.units.first(where: {
               $0.id == preferredUnitID &&
                   $0.faction == activeFaction &&
                   !$0.isDestroyed &&
                   (!$0.hasMoved || !$0.hasAttacked)
        }) {
            selectedUnitID = preferredUnit.id
            focusedCoordinate = preferredUnit.position
            clearObjectiveGuidance()
            return
        }

        selectedUnitID = scenario.units.first {
            $0.faction == activeFaction && !$0.isDestroyed && (!$0.hasMoved || !$0.hasAttacked)
        }?.id
        if let selectedUnit {
            focusedCoordinate = selectedUnit.position
        }
        clearObjectiveGuidance()
    }

    private func appendLog(_ entry: String) {
        battleLog.insert(entry, at: 0)
        if battleLog.count > 8 {
            battleLog.removeLast()
        }
    }

    private func strength(for faction: Faction) -> Int {
        units
            .filter { $0.faction == faction }
            .reduce(0) { total, unit in
                let moraleAdjustedAttack = effectiveAttack(for: unit) * unit.moraleState.attackMultiplierPercent / 100
                return total + unit.hp + moraleAdjustedAttack * 2 + effectiveMovement(for: unit) * 4 + unit.range * 6
            }
    }

    private func unitSelectionMessage(for unit: BattleUnit) -> String {
        let moveCount = reachableTiles(for: unit).count
        let attackCount = attackableTiles(for: unit).count
        return "\(unit.name)：\(supplyState(for: unit).title)，\(unit.moraleState.title)，可移动 \(moveCount) 格，可攻击 \(attackCount) 个目标。"
    }

    private func tileMessage(for coordinate: HexCoordinate) -> String {
        guard let tile = tile(at: coordinate) else { return "地图外区域。" }
        let objective = tile.objectiveName.map { " 据点：\($0)。" } ?? ""
        let owner = tile.owner.map { " 控制：\($0.title)。" } ?? ""
        let controlZone = isEnemyControlZone(coordinate, for: activeFaction) ? " 敌方控制区：进入 +\(Self.enemyControlZoneMovementPenalty) 移动。" : ""
        return "\(tile.terrain.title) q\(coordinate.q),r\(coordinate.r)：基础移动 \(tile.terrain.movementCost)，防御 +\(tile.terrain.defenseBonus)。\(controlZone)\(objective)\(owner)"
    }

    private static func openingMessage(for scenario: Scenario) -> String {
        "\(scenario.name)：\(scenario.turnLimit) 回合内夺取全部据点。"
    }

    private static func openingLog(for scenario: Scenario) -> String {
        "\(scenario.year) \(scenario.name)开始，盟军必须在 \(scenario.turnLimit) 回合内夺取地图上的全部据点。"
    }
}
