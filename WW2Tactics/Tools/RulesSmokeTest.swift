import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAILED: \(message)\n", stderr)
        Foundation.exit(1)
    }
}

func requireSequentialTimelineOrders(_ timeline: [AIPhaseTimelineEvent], _ message: String) {
    for (index, event) in timeline.enumerated() {
        require(event.order == index + 1, "\(message): expected order \(index + 1), got \(event.order)")
    }
}

func requireAIPhaseMapMarkersMatchSummary(
    _ markers: [AIPhaseMapMarker],
    _ summary: AIPhaseSummary,
    _ message: String
) {
    let timelineOrders = Set(summary.timeline.map(\.order))
    require(!markers.isEmpty, "\(message): markers should not be empty")
    require(
        markers.allSatisfy { $0.faction == summary.faction && $0.turn == summary.turn },
        "\(message): markers should match AI phase faction and turn"
    )
    require(
        markers.allSatisfy { timelineOrders.contains($0.eventOrder) },
        "\(message): markers should point back to timeline orders"
    )
}

func requireAIPhaseMapMarker(
    _ markers: [AIPhaseMapMarker],
    kind: AIPhaseTimelineEventKind,
    role: AIPhaseMapMarkerRole,
    coordinate: HexCoordinate,
    order: Int? = nil,
    _ message: String
) {
    require(
        markers.contains { marker in
            marker.eventKind == kind &&
                marker.role == role &&
                marker.coordinate == coordinate &&
                (order.map { marker.eventOrder == $0 } ?? true)
        },
        message
    )
}

func smokeAIPhaseSummary(timeline: [AIPhaseTimelineEvent]) -> AIPhaseSummary {
    AIPhaseSummary(
        faction: .axis,
        turn: 1,
        startingCommandPoints: 0,
        endingCommandPoints: 0,
        reinforcements: 0,
        deployments: 0,
        tacticalCommands: 0,
        attacks: 0,
        moves: timeline.filter { $0.kind == .move }.count,
        objectivesCaptured: 0,
        enemyUnitsDestroyed: 0,
        friendlyUnitsDestroyed: 0,
        damageDealt: 0,
        damageTaken: 0,
        timeline: timeline
    )
}

func smokeAIPhaseTimelineEvent(
    order: Int,
    from: HexCoordinate?,
    to: HexCoordinate?
) -> AIPhaseTimelineEvent {
    AIPhaseTimelineEvent(
        order: order,
        faction: .axis,
        turn: 1,
        kind: .move,
        actorUnitID: nil,
        actorName: "测试AI单位",
        actorKind: .infantry,
        targetUnitID: nil,
        targetName: nil,
        targetKind: nil,
        from: from,
        to: to,
        tacticalCommand: nil,
        deployedUnitKind: nil,
        objectiveName: nil,
        previousOwner: nil,
        newOwner: nil,
        damage: 0,
        counterDamage: 0,
        recoveredHP: 0,
        commandPointCost: 0,
        commandPointReward: 0,
        commandPointsAfter: nil,
        didDestroyTarget: false,
        didCaptureObjective: false,
        detail: "test"
    )
}

@main
struct RulesSmokeTest {
    static func main() async {
        await MainActor.run {
            let game = GameState()

            require(game.scenario.name == "阿登反击战", "scenario name should be present")
            require(game.campaignCatalog.count >= 2, "campaign catalog should include multiple scenarios")
            require(game.campaignCatalog.contains { $0.name == "诺曼底突破" }, "Normandy scenario should be available")
            require(game.tiles.count == game.scenario.mapColumns * game.scenario.mapRows, "map should be rectangular")
            require(game.scenario.mapColumns >= 22 && game.scenario.mapRows >= 14, "default scenario should use a larger playable campaign map")
            require(game.objectiveTiles.count == 14, "scenario should include fourteen objectives")
            require(game.objectiveTiles.contains { $0.objectiveName == "南部桥头堡" }, "expanded Ardennes map should include a southern bridgehead")
            require(game.objectiveTiles.contains { $0.objectiveName == "莱茵补给线" }, "expanded Ardennes map should include a Rhine supply objective")
            require(game.objectiveTiles.contains { $0.objectiveName == "默兹渡口" }, "expanded Ardennes map should include a Meuse crossing")
            require(game.objectiveTiles.contains { $0.objectiveName == "鲁尔工业区" }, "expanded Ardennes map should include a Ruhr objective")
            require(game.units.contains { $0.kind == .tank }, "scenario should include tanks")
            require(game.units.contains { $0.kind == .artillery }, "scenario should include artillery")
            require(game.units.contains { $0.kind == .recon }, "scenario should include recon units")
            require(game.units.compactMap(\.commander).count >= 4, "scenario should include commanders")
            require(game.objectiveProgress > 0, "objective progress should be calculated")
            require(game.alliedStrength > 0 && game.axisStrength > 0, "force strength should be calculated")
            require(game.units(for: .allies).count == 12, "expanded allied force roster should be available")
            require(game.units(for: .axis).count == 15, "expanded axis force roster should be available")
            require(game.mapFriendlyFocusUnits.count == game.units(for: .allies).count, "map friendly focus strip should expose every allied unit")
            require(game.mapFriendlyFocusUnits.contains { $0.name == "自由法国装甲群" }, "map friendly focus strip should include deep allied units")
            require(game.mapEnemyFocusUnits.count == game.units(for: .axis).count, "map enemy focus strip should expose every enemy unit")
            require(game.mapEnemyFocusUnits.contains { $0.name == "鲁尔防空炮群" }, "map enemy focus strip should include deep-map enemies")
            require(game.commandPoints(for: .allies) == 6, "allied command points should start at six")
            require(game.commandIncome(for: .allies) == 7, "owned objectives should add command income")
            require(game.remainingTurns == game.scenario.turnLimit, "mission timer should start at the scenario turn limit")
            require(game.earnedStars == 0, "mission stars should start at zero")
            require(game.missionObjectives.count == 3, "mission should expose three star objectives")
            require(game.missionObjectives.allSatisfy { $0.state == .pending }, "mission objectives should start pending")
            let startingSituation = game.battlefieldSituationSummary
            require(startingSituation.faction == .allies, "battlefield situation should describe active faction")
            require(startingSituation.commandPoints == game.activeCommandPoints, "battlefield situation should expose active command points")
            require(startingSituation.readyUnitCount == game.readyUnits.count, "battlefield situation should expose ready unit count")
            require(startingSituation.totalUnitCount == game.units(for: .allies).count, "battlefield situation should expose active force size")
            require(startingSituation.objectiveProgressText == "\(game.alliedScore)/\(game.objectiveTiles.count)", "battlefield situation should summarize objective progress")
            require(startingSituation.metrics.count == 5, "battlefield situation should expose compact metrics")
            guard let suppliedTank = game.units.first(where: { $0.name == "第4装甲师" }) else {
                require(false, "supplied tank should exist")
                return
            }
            require(game.supplyState(for: suppliedTank) == .supplied, "starting allied tank should have supply")
            require(!game.supplyLineTiles(for: suppliedTank).isEmpty, "supplied tank should show a supply path")

            game.selectScenario(id: "normandy-1944")
            require(game.scenario.name == "诺曼底突破", "scenario selector should load Normandy")
            require(game.focusedCoordinate == game.scenario.initialFocus, "scenario selector should reset focus")
            require(game.tiles.count == game.scenario.mapColumns * game.scenario.mapRows, "Normandy map should be rectangular")
            require(game.objectiveTiles.count >= 4, "Normandy should include objectives")
            game.restart()
            require(game.scenario.name == "诺曼底突破", "restart should keep selected scenario")
            game.selectScenario(id: "ardennes-1944")

            guard let pattonTank = game.units.first(where: { $0.name == "第4装甲师" }) else {
                require(false, "Patton tank should exist")
                return
            }
            require(pattonTank.commander?.name == "巴顿", "Patton should command the allied tank")
            require(pattonTank.attack > UnitKind.tank.baseAttack, "commander should boost attack")
            require(pattonTank.rank == .green, "units should start as green troops")
            require(pattonTank.moraleState == .steady, "units should start with steady morale")

            guard let axisTank = game.units.first(where: { $0.name == "第2装甲集团" }) else {
                require(false, "Axis tank should exist")
                return
            }
            let testAttacker = BattleUnit(
                name: "测试装甲",
                kind: .tank,
                faction: .allies,
                position: HexCoordinate(q: 9, r: 4),
                hp: UnitKind.tank.baseHP,
                commander: .patton
            )
            guard let preview = game.combatPreview(attacker: testAttacker, defender: axisTank) else {
                require(false, "combat preview should be available for adjacent enemies")
                return
            }
            require(preview.damage > 0, "combat preview should calculate damage")
            require(preview.defenderHPAfterAttack < axisTank.hp, "combat preview should reduce defender HP")
            require(game.attackCoverageTiles(for: testAttacker).contains(axisTank.position), "attack coverage should include targets inside weapon range")
            require(!game.attackCoverageTiles(for: testAttacker).contains(testAttacker.position), "attack coverage should not include the attacking unit's own tile")
            require(game.attackableUnits(for: testAttacker).contains { $0.id == axisTank.id }, "attackable unit query should find valid target")
            require(game.attackableTiles(for: testAttacker).isSubset(of: game.attackCoverageTiles(for: testAttacker)), "attackable target tiles should be inside attack coverage")

            let combatResultGame = GameState(scenario: combatResultScenario())
            guard let resultAttacker = combatResultGame.units.first(where: { $0.name == "结果攻击方" }),
                  let resultDefender = combatResultGame.units.first(where: { $0.name == "结果防守方" }),
                  let resultPreview = combatResultGame.combatPreview(attacker: resultAttacker, defender: resultDefender) else {
                require(false, "combat result scenario should produce a combat preview")
                return
            }
            require(combatResultGame.latestCombatResult == nil, "combat result should start empty")
            _ = combatResultGame.fireExposurePreview(for: resultAttacker, at: resultAttacker.position)
            require(combatResultGame.latestCombatResult == nil, "preview helpers should not write combat results")
            combatResultGame.handleTap(on: resultAttacker.position)
            combatResultGame.handleTap(on: resultDefender.position)
            guard let resultSummary = combatResultGame.latestCombatResult,
                  let finalResultAttacker = combatResultGame.scenario.units.first(where: { $0.id == resultAttacker.id }),
                  let finalResultDefender = combatResultGame.scenario.units.first(where: { $0.id == resultDefender.id }) else {
                require(false, "executed attack should publish combat result summary")
                return
            }
            require(resultSummary.damage == resultPreview.damage, "combat result damage should match preview")
            require(resultSummary.counterDamage > 0, "combat result should record actual counter damage")
            require(resultSummary.attacker.startingHP == resultAttacker.hp, "combat result should record attacker starting HP")
            require(resultSummary.attacker.endingHP == finalResultAttacker.hp, "combat result should record attacker ending HP")
            require(resultSummary.defender.startingHP == resultDefender.hp, "combat result should record defender starting HP")
            require(resultSummary.defender.endingHP == finalResultDefender.hp, "combat result should record defender ending HP")
            require(resultSummary.didConsumeDefenderEntrenchment, "combat result should record consumed defense posture")
            require(resultSummary.attacker.experienceDelta == finalResultAttacker.experience - resultAttacker.experience, "combat result should record attacker experience delta")
            require(resultSummary.defender.moraleDelta == finalResultDefender.morale - resultDefender.morale, "combat result should record defender morale delta")
            combatResultGame.restart()
            require(combatResultGame.latestCombatResult == nil, "restart should clear latest combat result")

            let baselineAuraGame = GameState(scenario: commanderAuraScenario(includeCommander: false))
            let auraGame = GameState(scenario: commanderAuraScenario(includeCommander: true))
            guard let baselineAuraAttacker = baselineAuraGame.units.first(where: { $0.name == "受援步兵" }),
                  let baselineAuraTarget = baselineAuraGame.units.first(where: { $0.name == "光环目标" }),
                  let auraAttacker = auraGame.units.first(where: { $0.name == "受援步兵" }),
                  let auraTarget = auraGame.units.first(where: { $0.name == "光环目标" }),
                  let baselineAuraPreview = baselineAuraGame.combatPreview(attacker: baselineAuraAttacker, defender: baselineAuraTarget),
                  let auraPreview = auraGame.combatPreview(attacker: auraAttacker, defender: auraTarget) else {
                require(false, "commander aura test previews should exist")
                return
            }
            require(auraGame.commanderSupport(attacker: auraAttacker)?.name == "巴顿", "adjacent commander should support friendly attacks")
            require(auraPreview.commanderSupportName == "巴顿", "combat preview should expose commander support")
            require(auraPreview.commanderSupportBonusPercent == 8, "commander aura should add eight percent damage")
            require(auraPreview.commanderSupportTitle == "将领协同", "commander aura should be labeled")
            require(auraPreview.damage > baselineAuraPreview.damage, "commander aura should increase damage")
            require(auraGame.commanderAuraSummary.contains("+8%"), "commander aura summary should describe the bonus")

            let matchupGame = GameState(scenario: matchupScenario())
            guard let reconAttacker = matchupGame.units.first(where: { $0.name == "克制侦察" }),
                  let infantryAttacker = matchupGame.units.first(where: { $0.name == "步兵攻击" }),
                  let artilleryTarget = matchupGame.units.first(where: { $0.name == "炮兵目标" }),
                  let tankTarget = matchupGame.units.first(where: { $0.name == "装甲目标" }),
                  let reconVsArtillery = matchupGame.combatPreview(attacker: reconAttacker, defender: artilleryTarget),
                  let reconVsTank = matchupGame.combatPreview(attacker: reconAttacker, defender: tankTarget),
                  let infantryVsTank = matchupGame.combatPreview(attacker: infantryAttacker, defender: tankTarget) else {
                require(false, "matchup test previews should exist")
                return
            }
            require(reconVsArtillery.matchupMultiplierPercent == 120, "recon should have tactical advantage against artillery")
            require(reconVsArtillery.matchupTitle == "战术优势", "advantage preview should label tactical edge")
            require(reconVsArtillery.damage > reconVsTank.damage, "advantage matchup should increase damage")
            require(infantryVsTank.matchupMultiplierPercent == 92, "infantry should be disadvantaged against tanks")
            require(infantryVsTank.matchupTitle == "战术劣势", "disadvantage preview should label tactical risk")

            let infantryTerrainGame = GameState(scenario: terrainMovementScenario(unitKind: .infantry))
            let tankTerrainGame = GameState(scenario: terrainMovementScenario(unitKind: .tank))
            guard let terrainInfantry = infantryTerrainGame.units.first(where: { $0.name == "地形测试步兵" }),
                  let terrainTank = tankTerrainGame.units.first(where: { $0.name == "地形测试坦克" }) else {
                require(false, "terrain movement test units should exist")
                return
            }
            let mountain = HexCoordinate(q: 1, r: 1)
            require(TerrainKind.mountain.movementCost(for: .infantry) == 3, "infantry should handle mountains at normal cost")
            require(TerrainKind.mountain.movementCost(for: .tank) == 5, "tanks should pay extra movement in mountains")
            require(infantryTerrainGame.reachableTiles(for: terrainInfantry).contains(mountain), "infantry should reach adjacent mountains")
            require(!tankTerrainGame.reachableTiles(for: terrainTank).contains(mountain), "tank should be blocked by high mountain movement cost")

            let terrainCombatGame = GameState(scenario: terrainCombatScenario())
            guard let terrainAttacker = terrainCombatGame.units.first(where: { $0.name == "地形测试装甲" }),
                  let plainsTarget = terrainCombatGame.units.first(where: { $0.name == "平原目标" }),
                  let riverTarget = terrainCombatGame.units.first(where: { $0.name == "河流目标" }),
                  let plainsTerrainPreview = terrainCombatGame.combatPreview(attacker: terrainAttacker, defender: plainsTarget),
                  let riverTerrainPreview = terrainCombatGame.combatPreview(attacker: terrainAttacker, defender: riverTarget) else {
                require(false, "terrain combat previews should exist")
                return
            }
            require(plainsTerrainPreview.terrainAttackMultiplierPercent == 108, "tanks should attack effectively on plains")
            require(plainsTerrainPreview.terrainTitle == "地形适性", "favorable terrain should be labeled")
            require(riverTerrainPreview.terrainAttackMultiplierPercent == 72, "river attacks should penalize tanks")
            require(riverTerrainPreview.terrainTitle == "地形牵制", "bad terrain should be labeled")
            require(plainsTerrainPreview.damage > riverTerrainPreview.damage, "terrain affinity should change combat damage")
            require(riverTerrainPreview.terrainDetail.contains("河流"), "terrain preview should name defender terrain")

            let postMoveGame = GameState(scenario: postMoveAttackScenario())
            guard let postMoveTank = postMoveGame.units.first(where: { $0.name == "机动装甲" }),
                  let postMoveTarget = postMoveGame.units.first(where: { $0.name == "前方守军" }) else {
                require(false, "post-move attack preview units should exist")
                return
            }
            let postMoveDestination = HexCoordinate(q: 3, r: 0)
            postMoveGame.handlePrimaryAction(on: postMoveTank.position)
            require(!postMoveGame.attackableTiles(for: postMoveTank).contains(postMoveTarget.position), "target should start outside current attack range")
            postMoveGame.handlePrimaryAction(on: postMoveTarget.position)
            require(!postMoveGame.focusedAttackPositionRoutes.isEmpty, "out-of-range target focus should expose reachable attack positions")
            require(
                postMoveGame.message.contains("右键命令 \(postMoveTank.name)") &&
                    postMoveGame.message.contains("攻击位"),
                "primary focus on approachable target should describe the secondary approach command"
            )
            require(
                postMoveGame.focusedAttackPositionRoutes.map(\.destination).contains(postMoveDestination),
                "attack-position preview should include the planned destination"
            )
            require(
                postMoveGame.focusedAttackPositionRoute?.destination == postMoveGame.focusedAttackPositionRoutes.first?.destination,
                "focused attack-position route should pick the best listed attack position"
            )
            require(
                postMoveGame.focusedAttackPositionRoute?.coordinates.first == postMoveTank.position &&
                    postMoveGame.focusedAttackPositionRoute?.coordinates.contains(postMoveDestination) == true,
                "focused attack-position route should expose the movement path to the recommended position"
            )
            require(
                postMoveGame.focusedAttackPositionRoutes.allSatisfy { route in
                    postMoveGame.postMoveAttackOpportunities(for: postMoveTank, to: route.destination).contains { $0.id == postMoveTarget.id }
                },
                "each attack position should create an attack opportunity on the focused target"
            )
            guard let postMoveApproachRoute = postMoveGame.focusedAttackPositionRoute else {
                require(false, "out-of-range target focus should expose a recommended approach route")
                return
            }
            require(
                postMoveGame.focusedRouteStepPreviews.map(\.movementCost).reduce(0, +) == postMoveApproachRoute.totalCost,
                "focused approach route step costs should sum to the route total"
            )
            require(
                postMoveGame.focusedRouteStepPreviews.contains { step in
                    step.coordinate == postMoveDestination &&
                        step.threatNames.contains(postMoveTarget.name) &&
                        step.controlZonePenalty > 0
                },
                "focused approach route should expose destination threat and control-zone risk"
            )
            require(
                postMoveGame.mapActionHint(for: postMoveTarget.position) == .approachAttack(
                    cost: postMoveApproachRoute.totalCost,
                    controlZonePenalty: postMoveApproachRoute.controlZonePenalty
                ),
                "out-of-range target with attack position should show an executable approach hint"
            )
            require(
                postMoveGame.focusedCommandPreview == .approachAttack(
                    unitName: postMoveTank.name,
                    defenderName: postMoveTarget.name,
                    route: postMoveApproachRoute
                ),
                "out-of-range target with attack position should preview an approach move"
            )
            require(
                postMoveGame.postMoveAttackOpportunities(for: postMoveTank, to: postMoveDestination).contains { $0.id == postMoveTarget.id },
                "move preview should expose attack opportunities from the destination"
            )
            postMoveGame.handlePrimaryAction(on: postMoveDestination)
            require(postMoveGame.focusedPostMoveAttackOpportunities.map(\.id) == [postMoveTarget.id], "focused move preview should list the future target")
            guard let postMoveAttackPreview = postMoveGame.focusedPostMoveAttackPreviews.first else {
                require(false, "focused move preview should expose future combat numbers")
                return
            }
            var previewAttacker = postMoveTank
            previewAttacker.position = postMoveDestination
            guard let expectedPostMoveCombat = postMoveGame.combatPreview(attacker: previewAttacker, defender: postMoveTarget) else {
                require(false, "future combat preview should be computable from the destination")
                return
            }
            var previewDefender = postMoveTank
            previewDefender.position = postMoveDestination
            previewDefender.tacticalStatus = .normal
            previewDefender.isEntrenched = false
            guard let expectedFireExposureCombat = postMoveGame.combatPreview(attacker: postMoveTarget, defender: previewDefender),
                  let fireExposure = postMoveGame.focusedFireExposurePreview else {
                require(false, "focused move preview should expose fire exposure numbers")
                return
            }
            require(postMoveAttackPreview.targetID == postMoveTarget.id, "focused post-move attack preview should name the future target")
            require(postMoveAttackPreview.damage == expectedPostMoveCombat.damage, "post-move attack preview damage should match combat preview")
            require(postMoveAttackPreview.counterDamage == expectedPostMoveCombat.counterDamage, "post-move attack preview counter damage should match combat preview")
            require(postMoveAttackPreview.willDestroy == expectedPostMoveCombat.willDestroyDefender, "post-move attack preview kill flag should match combat preview")
            require(fireExposure.sources.map(\.sourceID) == [postMoveTarget.id], "fire exposure preview should identify the covering enemy")
            require(fireExposure.totalPotentialDamage == expectedFireExposureCombat.damage, "fire exposure damage should match enemy combat preview")
            require(fireExposure.highestSingleDamage == expectedFireExposureCombat.damage, "fire exposure highest damage should match the source damage")
            require(fireExposure.projectedHPAfterExposure == max(0, postMoveTank.hp - expectedFireExposureCombat.damage), "fire exposure should project HP after possible enemy fire")
            require(fireExposure.riskLevel != .none, "threatened destination should report a non-empty risk level")
            require(
                postMoveGame.message.contains("移动后可攻击 \(postMoveTarget.name)"),
                "primary focus on a move tile should describe post-move attack targets"
            )

            let safeTileGame = GameState(scenario: postMoveAttackScenario())
            guard let safeTileTank = safeTileGame.units.first(where: { $0.name == "机动装甲" }),
                  let safeExposure = safeTileGame.fireExposurePreview(for: safeTileTank, at: HexCoordinate(q: 1, r: 0)) else {
                require(false, "safe move tile should still produce a fire exposure preview")
                return
            }
            require(safeExposure.riskLevel == .none, "uncovered move tile should report SAFE risk")
            require(safeExposure.sources.isEmpty, "uncovered move tile should have no fire sources")
            require(safeExposure.projectedHPAfterExposure == safeTileTank.hp, "uncovered move tile should not project HP loss")

            let safeOptionGame = GameState(scenario: safeEngagementScenario())
            guard let safeOptionTank = safeOptionGame.units.first(where: { $0.name == "接敌装甲" }),
                  let safeOptionTarget = safeOptionGame.units.first(where: { $0.name == "主目标" }) else {
                require(false, "safe engagement units should exist")
                return
            }
            safeOptionGame.handlePrimaryAction(on: safeOptionTank.position)
            safeOptionGame.handlePrimaryAction(on: safeOptionTarget.position)
            require(safeOptionGame.focusedAttackPositionRoute?.destination == HexCoordinate(q: 3, r: 0), "safe suggestions should not change the default POS route")
            let optionDebug = safeOptionGame.focusedSafeEngagementOptions.map { option in
                "\(option.route.destination.id):\(option.exposure.totalPotentialDamage):\(option.exposure.sources.map(\.sourceName))"
            }
            require(
                safeOptionGame.focusedSafeEngagementOptions.first?.route.destination == HexCoordinate(q: 3, r: 1),
                "safe engagement options should prefer the lower exposure attack position, got \(optionDebug)"
            )
            require(
                (safeOptionGame.focusedSafeEngagementOptions.first?.exposure.totalPotentialDamage ?? Int.max) <
                    (safeOptionGame.focusedFireExposurePreview?.totalPotentialDamage ?? 0),
                "safe engagement option should reduce projected exposure damage"
            )
            let safeComparisons = safeOptionGame.focusedSafeEngagementComparisons
            require(
                safeComparisons.count == safeOptionGame.focusedSafeEngagementOptions.count,
                "safe engagement comparisons should mirror option count"
            )
            guard let saferComparison = safeComparisons.first else {
                require(false, "safe engagement comparison should exist")
                return
            }
            require(saferComparison.destination == HexCoordinate(q: 3, r: 1), "safe comparison should describe the safer destination")
            require(saferComparison.referenceDestination == HexCoordinate(q: 3, r: 0), "safe comparison should keep the default POS route as baseline")
            require(saferComparison.potentialDamageDelta < 0, "safe comparison should report reduced potential damage")
            require(saferComparison.riskRankDelta <= 0, "safe comparison should not report higher risk for the safer option")
            require(saferComparison.sourceCountDelta <= 0, "safe comparison should report same or fewer fire sources")
            require(saferComparison.referenceThreatenedStepCount > 0, "safe comparison should report default route threatened steps")
            require(saferComparison.optionThreatenedStepCount >= 0, "safe comparison should report option route threatened steps")
            require(
                saferComparison.referenceRouteThreatNames.contains("侧翼装甲"),
                "safe comparison should list the default route threat source"
            )
            require(saferComparison.movementCostDelta >= 0, "safe comparison should expose the route cost tradeoff")
            require(!saferComparison.isFocused, "safe comparison should not be focused before choosing the option")
            require(saferComparison.summaryText.contains("少承伤"), "safe comparison summary should explain reduced damage")
            require(saferComparison.summaryText.contains("路线"), "safe comparison summary should explain route exposure")
            guard let saferOption = safeOptionGame.focusedSafeEngagementOptions.first else {
                require(false, "safe engagement option should exist")
                return
            }
            safeOptionGame.focusSafeEngagementOption(saferOption)
            require(safeOptionGame.focusedCoordinate == safeOptionTarget.position, "safe engagement focus should keep the target focused")
            require(safeOptionGame.focusedSafeEngagementDestination == HexCoordinate(q: 3, r: 1), "safe engagement focus should remember the selected destination")
            require(safeOptionGame.focusedAttackPositionRoute?.destination == HexCoordinate(q: 3, r: 1), "safe engagement focus should switch the POS route")
            require(safeOptionGame.focusedFireExposurePreview?.coordinate == HexCoordinate(q: 3, r: 1), "safe engagement focus should switch fire exposure preview")
            guard let focusedSafeComparison = safeOptionGame.focusedSafeEngagementComparisons.first else {
                require(false, "focused safe engagement comparison should still exist")
                return
            }
            require(focusedSafeComparison.referenceDestination == HexCoordinate(q: 3, r: 0), "focused comparison should still compare against the default POS route")
            require(focusedSafeComparison.isFocused, "focused comparison should mark the selected safe route")
            require(
                focusedSafeComparison.threatenedStepDelta == saferComparison.threatenedStepDelta,
                "focused comparison should preserve route exposure delta"
            )
            guard case let .approachAttack(_, _, saferRoute) = safeOptionGame.focusedCommandPreview else {
                require(false, "safe engagement focus should keep an executable approach preview")
                return
            }
            require(saferRoute.destination == HexCoordinate(q: 3, r: 1), "safe engagement focused command should use the selected route")
            require(
                safeOptionGame.units.first(where: { $0.id == safeOptionTank.id })?.position == safeOptionTank.position,
                "safe engagement focus should not move before execution"
            )
            safeOptionGame.executeFocusedCommand()
            guard let safeOptionTankAfter = safeOptionGame.units.first(where: { $0.id == safeOptionTank.id }) else {
                require(false, "safe engagement tank should exist after execution")
                return
            }
            require(safeOptionTankAfter.position == HexCoordinate(q: 3, r: 1), "safe engagement execution should move to selected safe position")
            require(!safeOptionTankAfter.hasAttacked, "safe engagement execution should not auto-attack")
            require(safeOptionGame.focusedCoordinate == safeOptionTarget.position, "safe engagement execution should focus target for follow-up attack")
            var unavailableSafeScenario = safeEngagementScenario()
            if let unavailableTankIndex = unavailableSafeScenario.units.firstIndex(where: { $0.name == "接敌装甲" }) {
                unavailableSafeScenario.units[unavailableTankIndex].hasMoved = true
            }
            let unavailableSafeGame = GameState(scenario: unavailableSafeScenario)
            guard let unavailableTank = unavailableSafeGame.units.first(where: { $0.name == "接敌装甲" }),
                  let unavailableTarget = unavailableSafeGame.units.first(where: { $0.name == "主目标" }) else {
                require(false, "unavailable safe engagement units should exist")
                return
            }
            unavailableSafeGame.handlePrimaryAction(on: unavailableTank.position)
            unavailableSafeGame.handlePrimaryAction(on: unavailableTarget.position)
            unavailableSafeGame.focusSafeEngagement(targetID: unavailableTarget.id, destination: HexCoordinate(q: 3, r: 1))
            require(unavailableSafeGame.focusedSafeEngagementDestination == nil, "unavailable safe engagement should not keep stale destination")
            require(unavailableSafeGame.focusedAttackPositionRoute == nil, "unavailable safe engagement should not keep executable POS route")
            var destroyedSafeScenario = safeEngagementScenario()
            if let destroyedTargetIndex = destroyedSafeScenario.units.firstIndex(where: { $0.name == "主目标" }) {
                let destroyedTargetID = destroyedSafeScenario.units[destroyedTargetIndex].id
                destroyedSafeScenario.units[destroyedTargetIndex].hp = 0
                let destroyedSafeGame = GameState(scenario: destroyedSafeScenario)
                guard let destroyedSafeTank = destroyedSafeGame.units.first(where: { $0.name == "接敌装甲" }) else {
                    require(false, "destroyed safe engagement tank should exist")
                    return
                }
                destroyedSafeGame.handlePrimaryAction(on: destroyedSafeTank.position)
                destroyedSafeGame.focusSafeEngagement(targetID: destroyedTargetID, destination: HexCoordinate(q: 3, r: 1))
                require(destroyedSafeGame.focusedSafeEngagementDestination == nil, "destroyed safe target should not keep stale destination")
                require(destroyedSafeGame.focusedAttackPositionRoute == nil, "destroyed safe target should not keep executable POS route")
            }
            let alliedSafeGame = GameState(scenario: safeEngagementScenario())
            guard let alliedSafeTank = alliedSafeGame.units.first(where: { $0.name == "接敌装甲" }) else {
                require(false, "allied safe engagement tank should exist")
                return
            }
            alliedSafeGame.handlePrimaryAction(on: alliedSafeTank.position)
            alliedSafeGame.focusSafeEngagement(targetID: alliedSafeTank.id, destination: HexCoordinate(q: 3, r: 1))
            require(alliedSafeGame.focusedSafeEngagementDestination == nil, "allied safe target should not keep stale destination")
            require(alliedSafeGame.focusedAttackPositionRoute == nil, "allied safe target should not keep executable POS route")
            var occupiedSafeScenario = safeEngagementScenario()
            guard let occupiedSafeTank = occupiedSafeScenario.units.first(where: { $0.name == "接敌装甲" }),
                  let occupiedSafeTarget = occupiedSafeScenario.units.first(where: { $0.name == "主目标" }) else {
                require(false, "occupied safe engagement units should exist")
                return
            }
            occupiedSafeScenario.units.append(
                BattleUnit(
                    name: "占位友军",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 3, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            )
            let occupiedSafeGame = GameState(scenario: occupiedSafeScenario)
            occupiedSafeGame.handlePrimaryAction(on: occupiedSafeTank.position)
            occupiedSafeGame.handlePrimaryAction(on: occupiedSafeTarget.position)
            occupiedSafeGame.focusSafeEngagement(targetID: occupiedSafeTarget.id, destination: HexCoordinate(q: 3, r: 1))
            require(occupiedSafeGame.focusedSafeEngagementDestination == nil, "occupied safe destination should not keep stale destination")
            require(occupiedSafeGame.focusedAttackPositionRoute?.destination != HexCoordinate(q: 3, r: 1), "occupied safe destination should not become the POS route")
            postMoveGame.handleSecondaryAction(on: postMoveDestination)
            guard let postMoveTankAfter = postMoveGame.units.first(where: { $0.id == postMoveTank.id }) else {
                require(false, "post-move tank should exist after movement")
                return
            }
            guard let postMoveTargetAfterMove = postMoveGame.units.first(where: { $0.id == postMoveTarget.id }) else {
                require(false, "post-move target should survive the movement step")
                return
            }
            require(postMoveTankAfter.position == postMoveDestination, "secondary move should still move to the previewed destination")
            require(postMoveTankAfter.hasMoved && !postMoveTankAfter.hasAttacked, "moving should preserve attack when the unit has not attacked yet")
            require(postMoveGame.attackableTiles(for: postMoveTankAfter).contains(postMoveTarget.position), "target should be attackable after the planned move")
            require(postMoveGame.focusedCoordinate == postMoveTarget.position, "secondary move should focus the next attack target when one is available")
            require(postMoveGame.focusedAttackPositionRoute == nil, "attackable follow-up target should not keep a POS route")
            guard let postMoveFollowUpPreview = postMoveGame.combatPreview(attacker: postMoveTankAfter, defender: postMoveTargetAfterMove) else {
                require(false, "post-move focus should expose an immediate attack preview")
                return
            }
            require(
                postMoveGame.focusedCommandPreview == .attack(
                    attackerName: postMoveTankAfter.name,
                    defenderName: postMoveTargetAfterMove.name,
                    damage: postMoveFollowUpPreview.damage,
                    counterDamage: postMoveFollowUpPreview.counterDamage,
                    defenderHPAfterAttack: postMoveFollowUpPreview.defenderHPAfterAttack,
                    willDestroy: postMoveFollowUpPreview.willDestroyDefender
                ),
                "secondary move should switch the focused command preview to the follow-up attack"
            )
            postMoveGame.handleSecondaryAction(on: postMoveTarget.position)
            guard let postMoveTankAfterAttack = postMoveGame.units.first(where: { $0.id == postMoveTank.id }),
                  let postMoveTargetAfterAttack = postMoveGame.scenario.units.first(where: { $0.id == postMoveTarget.id }) else {
                require(false, "post-move units should remain inspectable after the follow-up attack")
                return
            }
            require(postMoveTankAfterAttack.hasAttacked, "second right-click after a post-move focus should spend the attack action")
            require(postMoveTargetAfterAttack.hp < postMoveTarget.hp, "second right-click after a post-move focus should damage the target")

            let directMoveGame = GameState(scenario: postMoveAttackScenario())
            guard let directMoveTank = directMoveGame.units.first(where: { $0.name == "机动装甲" }),
                  let directMoveTarget = directMoveGame.units.first(where: { $0.name == "前方守军" }) else {
                require(false, "direct tap move units should exist")
                return
            }
            directMoveGame.handleTap(on: directMoveTank.position)
            directMoveGame.handleTap(on: postMoveDestination)
            guard let directMoveTankAfter = directMoveGame.units.first(where: { $0.id == directMoveTank.id }),
                  let directMoveTargetAfterMove = directMoveGame.units.first(where: { $0.id == directMoveTarget.id }) else {
                require(false, "direct tap move units should survive movement")
                return
            }
            require(directMoveTankAfter.position == postMoveDestination, "direct tap on a move tile should execute movement")
            require(directMoveTankAfter.hasMoved && !directMoveTankAfter.hasAttacked, "direct tap movement should preserve the attack action")
            require(directMoveGame.focusedCoordinate == directMoveTarget.position, "direct tap movement should focus the next attack target")
            require(directMoveGame.message.contains("继续点击可攻击"), "direct tap movement should use touch-friendly follow-up copy")
            directMoveGame.handleTap(on: directMoveTarget.position)
            guard let directMoveTankAfterAttack = directMoveGame.units.first(where: { $0.id == directMoveTank.id }),
                  let directMoveTargetAfterAttack = directMoveGame.scenario.units.first(where: { $0.id == directMoveTarget.id }) else {
                require(false, "direct tap move units should remain inspectable after attack")
                return
            }
            require(directMoveTankAfterAttack.hasAttacked, "direct tap follow-up should spend the attack action")
            require(directMoveTargetAfterAttack.hp < directMoveTargetAfterMove.hp, "direct tap follow-up should damage the focused target")

            let approachGame = GameState(scenario: postMoveAttackScenario())
            guard let approachTank = approachGame.units.first(where: { $0.name == "机动装甲" }),
                  let approachTarget = approachGame.units.first(where: { $0.name == "前方守军" }) else {
                require(false, "approach attack units should exist")
                return
            }
            approachGame.handlePrimaryAction(on: approachTank.position)
            approachGame.handleSecondaryAction(on: approachTarget.position)
            guard let approachTankAfter = approachGame.units.first(where: { $0.id == approachTank.id }),
                  let approachTargetAfter = approachGame.units.first(where: { $0.id == approachTarget.id }) else {
                require(false, "approach attack units should survive")
                return
            }
            require(approachTankAfter.position == postMoveDestination, "right-clicking an out-of-range enemy should move to the recommended attack position")
            require(approachTankAfter.hasMoved && !approachTankAfter.hasAttacked, "approach movement should preserve the attack action")
            require(approachTargetAfter.hp == approachTarget.hp, "approach movement should not attack immediately")
            require(approachGame.attackableTiles(for: approachTankAfter).contains(approachTarget.position), "approach destination should put the target in range")
            require(approachGame.focusedCoordinate == approachTarget.position, "approach movement should keep the enemy target focused for the next attack")
            guard let approachAttackPreview = approachGame.combatPreview(attacker: approachTankAfter, defender: approachTargetAfter) else {
                require(false, "approach movement should expose an immediate attack preview")
                return
            }
            require(
                approachGame.focusedCommandPreview == .attack(
                    attackerName: approachTankAfter.name,
                    defenderName: approachTargetAfter.name,
                    damage: approachAttackPreview.damage,
                    counterDamage: approachAttackPreview.counterDamage,
                    defenderHPAfterAttack: approachAttackPreview.defenderHPAfterAttack,
                    willDestroy: approachAttackPreview.willDestroyDefender
                ),
                "focused command preview should switch to attack after approach movement"
            )
            approachGame.handleSecondaryAction(on: approachTarget.position)
            guard let approachTankAfterAttack = approachGame.units.first(where: { $0.id == approachTank.id }),
                  let approachTargetAfterAttack = approachGame.scenario.units.first(where: { $0.id == approachTarget.id }) else {
                require(false, "approach attack units should still be inspectable after the follow-up attack")
                return
            }
            require(approachTankAfterAttack.hasAttacked, "second right-click after approach should spend the attack action")
            require(approachTargetAfterAttack.hp < approachTarget.hp, "second right-click after approach should damage the target")

            let directApproachGame = GameState(scenario: postMoveAttackScenario())
            guard let directApproachTank = directApproachGame.units.first(where: { $0.name == "机动装甲" }),
                  let directApproachTarget = directApproachGame.units.first(where: { $0.name == "前方守军" }) else {
                require(false, "direct tap approach units should exist")
                return
            }
            directApproachGame.handleTap(on: directApproachTank.position)
            directApproachGame.handleTap(on: directApproachTarget.position)
            guard let directApproachTankAfter = directApproachGame.units.first(where: { $0.id == directApproachTank.id }),
                  let directApproachTargetAfter = directApproachGame.units.first(where: { $0.id == directApproachTarget.id }) else {
                require(false, "direct tap approach units should survive movement")
                return
            }
            require(directApproachTankAfter.position == postMoveDestination, "direct tap on an approachable target should move to the recommended attack position")
            require(directApproachTankAfter.hasMoved && !directApproachTankAfter.hasAttacked, "direct tap approach should preserve attack")
            require(directApproachTargetAfter.hp == directApproachTarget.hp, "direct tap approach should not attack immediately")
            require(directApproachGame.focusedCoordinate == directApproachTarget.position, "direct tap approach should keep the target focused")
            require(directApproachGame.message.contains("继续点击可攻击"), "direct tap approach should use touch-friendly follow-up copy")
            directApproachGame.handleTap(on: directApproachTarget.position)
            guard let directApproachTankAfterAttack = directApproachGame.units.first(where: { $0.id == directApproachTank.id }),
                  let directApproachTargetAfterAttack = directApproachGame.scenario.units.first(where: { $0.id == directApproachTarget.id }) else {
                require(false, "direct tap approach units should remain inspectable after attack")
                return
            }
            require(directApproachTankAfterAttack.hasAttacked, "direct tap follow-up after approach should spend the attack action")
            require(directApproachTargetAfterAttack.hp < directApproachTarget.hp, "direct tap follow-up after approach should damage the target")

            let buttonMoveGame = GameState(scenario: postMoveAttackScenario())
            guard let buttonMoveTank = buttonMoveGame.units.first(where: { $0.name == "机动装甲" }),
                  let buttonMoveTarget = buttonMoveGame.units.first(where: { $0.name == "前方守军" }) else {
                require(false, "execute button move units should exist")
                return
            }
            buttonMoveGame.handlePrimaryAction(on: buttonMoveTank.position)
            buttonMoveGame.focus(coordinate: postMoveDestination)
            require(buttonMoveGame.focusedCommandPreview?.isExecutable == true, "focused move preview should be executable by the command button")
            buttonMoveGame.executeFocusedCommand()
            guard let buttonMoveTankAfter = buttonMoveGame.units.first(where: { $0.id == buttonMoveTank.id }),
                  let buttonMoveTargetAfterMove = buttonMoveGame.units.first(where: { $0.id == buttonMoveTarget.id }) else {
                require(false, "execute button move units should survive movement")
                return
            }
            require(buttonMoveTankAfter.position == postMoveDestination, "execute button should move to the focused destination")
            require(buttonMoveTankAfter.hasMoved && !buttonMoveTankAfter.hasAttacked, "execute button movement should preserve the follow-up attack")
            require(buttonMoveGame.focusedCoordinate == buttonMoveTarget.position, "execute button movement should focus the next attack target")
            require(buttonMoveGame.message.contains("再次点执行可攻击"), "execute button movement should use button follow-up copy")
            guard let buttonMoveAttackPreview = buttonMoveGame.combatPreview(attacker: buttonMoveTankAfter, defender: buttonMoveTargetAfterMove) else {
                require(false, "execute button move should expose a follow-up attack preview")
                return
            }
            require(
                buttonMoveGame.focusedCommandPreview == .attack(
                    attackerName: buttonMoveTankAfter.name,
                    defenderName: buttonMoveTargetAfterMove.name,
                    damage: buttonMoveAttackPreview.damage,
                    counterDamage: buttonMoveAttackPreview.counterDamage,
                    defenderHPAfterAttack: buttonMoveAttackPreview.defenderHPAfterAttack,
                    willDestroy: buttonMoveAttackPreview.willDestroyDefender
                ),
                "execute button move should switch the focused preview to follow-up attack"
            )
            buttonMoveGame.executeFocusedCommand()
            guard let buttonMoveTankAfterAttack = buttonMoveGame.units.first(where: { $0.id == buttonMoveTank.id }),
                  let buttonMoveTargetAfterAttack = buttonMoveGame.scenario.units.first(where: { $0.id == buttonMoveTarget.id }) else {
                require(false, "execute button move units should remain inspectable after attack")
                return
            }
            require(buttonMoveTankAfterAttack.hasAttacked, "second execute button press should spend the attack action")
            require(buttonMoveTargetAfterAttack.hp < buttonMoveTarget.hp, "second execute button press should damage the focused target")

            let buttonApproachGame = GameState(scenario: postMoveAttackScenario())
            guard let buttonApproachTank = buttonApproachGame.units.first(where: { $0.name == "机动装甲" }),
                  let buttonApproachTarget = buttonApproachGame.units.first(where: { $0.name == "前方守军" }) else {
                require(false, "execute button approach units should exist")
                return
            }
            buttonApproachGame.handlePrimaryAction(on: buttonApproachTank.position)
            buttonApproachGame.focus(unitID: buttonApproachTarget.id)
            require(buttonApproachGame.focusedCommandPreview?.isExecutable == true, "focused approach preview should be executable by the command button")
            buttonApproachGame.executeFocusedCommand()
            guard let buttonApproachTankAfter = buttonApproachGame.units.first(where: { $0.id == buttonApproachTank.id }),
                  let buttonApproachTargetAfterMove = buttonApproachGame.units.first(where: { $0.id == buttonApproachTarget.id }) else {
                require(false, "execute button approach units should survive movement")
                return
            }
            require(buttonApproachTankAfter.position == postMoveDestination, "execute button should move to the focused attack position")
            require(buttonApproachTankAfter.hasMoved && !buttonApproachTankAfter.hasAttacked, "execute button approach should preserve the follow-up attack")
            require(buttonApproachTargetAfterMove.hp == buttonApproachTarget.hp, "execute button approach should not attack immediately")
            require(buttonApproachGame.focusedCoordinate == buttonApproachTarget.position, "execute button approach should keep the enemy target focused")
            require(buttonApproachGame.message.contains("再次点执行可攻击"), "execute button approach should use button follow-up copy")
            buttonApproachGame.executeFocusedCommand()
            guard let buttonApproachTankAfterAttack = buttonApproachGame.units.first(where: { $0.id == buttonApproachTank.id }),
                  let buttonApproachTargetAfterAttack = buttonApproachGame.scenario.units.first(where: { $0.id == buttonApproachTarget.id }) else {
                require(false, "execute button approach units should remain inspectable after attack")
                return
            }
            require(buttonApproachTankAfterAttack.hasAttacked, "second execute button press after approach should spend the attack action")
            require(buttonApproachTargetAfterAttack.hp < buttonApproachTarget.hp, "second execute button press after approach should damage the target")

            let objectiveAdvanceGame = GameState(scenario: objectiveAdvanceScenario(includeOccupiedDecoy: true))
            guard let objectiveAdvanceTank = objectiveAdvanceGame.units.first(where: { $0.name == "目标推进装甲" }),
                  let alliedObjective = objectiveAdvanceGame.objectiveTiles.first(where: { $0.objectiveName == "出发据点" }),
                  let occupiedObjective = objectiveAdvanceGame.objectiveTiles.first(where: { $0.objectiveName == "占据村镇" }),
                  let targetObjective = objectiveAdvanceGame.objectiveTiles.first(where: { $0.objectiveName == "前线据点" }) else {
                require(false, "objective advance test targets should exist")
                return
            }
            objectiveAdvanceGame.handlePrimaryAction(on: objectiveAdvanceTank.position)
            require(
                objectiveAdvanceGame.nearestObjectiveTarget(for: objectiveAdvanceTank)?.coordinate == targetObjective.coordinate,
                "objective shortcut should ignore occupied objectives and target the nearest open objective"
            )
            require(
                objectiveAdvanceGame.objectiveAdvanceRoute(for: objectiveAdvanceTank, to: occupiedObjective) == nil,
                "objective shortcut should not route into occupied objective tiles"
            )
            let objectiveAdvancePreviews = objectiveAdvanceGame.objectiveAdvancePreviews(for: objectiveAdvanceTank)
            guard let objectiveAdvancePreview = objectiveAdvancePreviews.first else {
                require(false, "objective shortcut should expose a direct objective advance preview")
                return
            }
            require(objectiveAdvancePreviews.count == 1, "objective advance preview should filter occupied and allied objectives")
            require(objectiveAdvancePreview.coordinate == targetObjective.coordinate, "objective advance preview should match shortcut target")
            require(objectiveAdvancePreview.coordinate == objectiveAdvanceGame.nearestObjectiveTarget(for: objectiveAdvanceTank)?.coordinate, "first objective advance preview should match OBJ shortcut")
            require(objectiveAdvancePreview.route.destination == targetObjective.coordinate, "direct objective advance preview should end on the objective")
            require(objectiveAdvancePreview.reachesObjective, "direct objective advance preview should mark reachable capture")
            require(objectiveAdvancePreview.remainingDistance == 0, "direct objective advance preview should report zero remaining distance")
            require(objectiveAdvancePreview.fireExposure?.riskLevel == FireRiskLevel.none, "direct objective advance preview should include terminal fire exposure")
            require(objectiveAdvancePreview.distanceClosed == 2, "direct objective advance preview should report closed distance")
            require(objectiveAdvancePreview.priorityReasonText == "本回合可夺取", "direct objective priority should explain reachable capture")
            require(objectiveAdvancePreview.distanceSummaryText == "距 2->0", "direct objective priority should summarize distance")
            require(objectiveAdvancePreview.riskSummaryText == "终点 SAFE", "direct objective priority should summarize safe terminal risk")
            require(
                objectiveAdvancePreview.prioritySummaryText.contains("\(objectiveAdvancePreview.ownerTitle)目标"),
                "direct objective priority should include owner"
            )
            require(
                objectiveAdvanceGame.focusedObjectiveAdvancePreviews == objectiveAdvancePreviews,
                "focused objective advance previews should mirror selected unit previews"
            )
            objectiveAdvanceGame.focusObjectiveAdvancePreview(objectiveAdvancePreview)
            require(
                objectiveAdvanceGame.guidedObjectiveCoordinate == targetObjective.coordinate,
                "direct objective preview click should mark the valid objective"
            )
            objectiveAdvanceGame.focusObjectiveAdvanceTarget(coordinate: occupiedObjective.coordinate)
            require(
                objectiveAdvanceGame.focusedCoordinate == objectiveAdvanceTank.position &&
                    objectiveAdvanceGame.guidedObjectiveCoordinate == nil,
                "occupied objective preview clicks should clear stale objective guidance without moving"
            )
            objectiveAdvanceGame.focusObjectiveAdvancePreview(objectiveAdvancePreview)
            objectiveAdvanceGame.focusObjectiveAdvanceTarget(coordinate: alliedObjective.coordinate)
            require(
                objectiveAdvanceGame.focusedCoordinate == objectiveAdvanceTank.position &&
                    objectiveAdvanceGame.guidedObjectiveCoordinate == nil,
                "allied objective preview clicks should clear stale objective guidance without moving"
            )
            let objectiveFireRiskGame = GameState(scenario: objectiveAdvanceFireRiskScenario())
            guard let riskyObjectiveTank = objectiveFireRiskGame.units.first(where: { $0.name == "冒险装甲" }),
                  let riskyObjective = objectiveFireRiskGame.objectiveTiles.first(where: { $0.objectiveName == "炮火据点" }) else {
                require(false, "objective fire risk preview targets should exist")
                return
            }
            objectiveFireRiskGame.handlePrimaryAction(on: riskyObjectiveTank.position)
            guard let riskyObjectivePreview = objectiveFireRiskGame.objectiveAdvancePreviews(for: riskyObjectiveTank).first,
                  let riskyObjectiveExposure = riskyObjectivePreview.fireExposure else {
                require(false, "objective advance preview should include fire exposure for threatened destinations")
                return
            }
            require(riskyObjectivePreview.coordinate == riskyObjective.coordinate, "risky objective preview should target the threatened objective")
            require(riskyObjectiveExposure.coordinate == riskyObjective.coordinate, "risky objective preview should evaluate exposure at the objective")
            require(riskyObjectiveExposure.totalPotentialDamage > 0, "risky objective preview should report potential terminal damage")
            require(riskyObjectiveExposure.riskLevel != FireRiskLevel.none, "risky objective preview should elevate fire risk above SAFE")
            require(
                riskyObjectiveExposure.sources.first?.sourceName == "火力警戒炮",
                "risky objective preview should preserve terminal fire source names"
            )
            require(
                riskyObjectivePreview.riskSummaryText == "终点 \(riskyObjectiveExposure.riskLevel.shortTitle) -\(riskyObjectiveExposure.totalPotentialDamage)",
                "risky objective priority should summarize terminal fire risk"
            )
            guard let objectiveAdvanceRoute = objectiveAdvanceGame.objectiveAdvanceRoute(for: objectiveAdvanceTank, to: targetObjective) else {
                require(false, "objective shortcut should expose a route to the target objective")
                return
            }
            objectiveAdvanceGame.focusNearestObjectiveTarget()
            require(objectiveAdvanceGame.focusedCoordinate == targetObjective.coordinate, "objective shortcut should focus a reachable objective")
            require(
                objectiveAdvanceGame.guidedObjectiveCoordinate == targetObjective.coordinate,
                "objective shortcut should mark the final reachable objective on the map"
            )
            require(objectiveAdvanceGame.message.contains("夺取前线据点"), "objective shortcut should describe the capture order")
            require(
                objectiveAdvanceGame.focusedCommandPreview == .move(
                    unitName: objectiveAdvanceTank.name,
                    terrainName: objectiveAdvanceGame.tile(at: targetObjective.coordinate)?.terrain.title ?? "",
                    route: objectiveAdvanceRoute
                ),
                "objective shortcut should create an executable MOVE preview on reachable objectives"
            )
            objectiveAdvanceGame.executeFocusedCommand()
            require(
                objectiveAdvanceGame.scenario.units.first(where: { $0.id == objectiveAdvanceTank.id })?.position == targetObjective.coordinate,
                "executing focused objective MOVE should move onto the objective"
            )
            require(objectiveAdvanceGame.tile(at: targetObjective.coordinate)?.owner == .allies, "executing focused objective MOVE should capture the objective")
            require(
                objectiveAdvanceGame.guidedObjectiveCoordinate == nil,
                "capturing the guided objective should clear objective guidance"
            )
            guard let objectiveAdvanceCapture = objectiveAdvanceGame.latestObjectiveCaptureResult else {
                require(false, "capturing the guided objective should record capture summary")
                return
            }
            require(objectiveAdvanceCapture.objectiveName == "前线据点", "guided objective capture summary should name the objective")
            require(objectiveAdvanceCapture.coordinate == targetObjective.coordinate, "guided objective capture summary should record coordinate")
            require(objectiveAdvanceCapture.previousOwner == .axis, "guided objective capture summary should record previous owner")
            require(objectiveAdvanceCapture.newOwner == .allies, "guided objective capture summary should record new owner")

            let distantObjectiveGame = GameState(scenario: distantObjectiveAdvanceScenario())
            guard let distantAdvanceTank = distantObjectiveGame.units.first(where: { $0.name == "目标推进装甲" }),
                  let distantObjective = distantObjectiveGame.objectiveTiles.first(where: { $0.objectiveName == "纵深据点" }) else {
                require(false, "distant objective advance test targets should exist")
                return
            }
            let expectedAdvance = HexCoordinate(q: 4, r: 0)
            distantObjectiveGame.handlePrimaryAction(on: distantAdvanceTank.position)
            require(
                distantObjectiveGame.nearestObjectiveTarget(for: distantAdvanceTank)?.coordinate == distantObjective.coordinate,
                "objective shortcut should pick the nearest distant objective"
            )
            guard let distantObjectivePreview = distantObjectiveGame.objectiveAdvancePreviews(for: distantAdvanceTank).first else {
                require(false, "distant objective shortcut should expose an advance preview")
                return
            }
            require(distantObjectivePreview.coordinate == distantObjective.coordinate, "distant objective preview should target the final objective")
            require(distantObjectivePreview.route.destination == expectedAdvance, "distant objective preview should route to the best forward tile")
            require(!distantObjectivePreview.reachesObjective, "distant objective preview should not mark capture this turn")
            require(distantObjectivePreview.remainingDistance == 1, "distant objective preview should report remaining distance")
            require(distantObjectivePreview.fireExposure?.coordinate == expectedAdvance, "distant objective preview should evaluate fire risk at the forward tile")
            require(distantObjectivePreview.distanceClosed == 4, "distant objective priority should report distance closed")
            require(distantObjectivePreview.priorityReasonText == "推进 4 格，剩 1 格", "distant objective priority should explain partial advance")
            require(distantObjectivePreview.distanceSummaryText == "距 5->1", "distant objective priority should summarize distance")
            guard let distantAdvanceRoute = distantObjectiveGame.objectiveAdvanceRoute(for: distantAdvanceTank, to: distantObjective) else {
                require(false, "objective shortcut should expose an advance route toward distant objectives")
                return
            }
            require(distantAdvanceRoute.destination == expectedAdvance, "distant objective shortcut should route to the best forward tile")
            distantObjectiveGame.focusObjectiveAdvancePreview(distantObjectivePreview)
            require(distantObjectiveGame.focusedCoordinate == expectedAdvance, "distant objective preview click should focus the forward tile")
            require(
                distantObjectiveGame.guidedObjectiveCoordinate == distantObjective.coordinate,
                "distant objective preview click should mark the final objective"
            )
            require(
                distantObjectiveGame.focusedCommandPreview == .move(
                    unitName: distantAdvanceTank.name,
                    terrainName: distantObjectiveGame.tile(at: expectedAdvance)?.terrain.title ?? "",
                    route: distantAdvanceRoute
                ),
                "distant objective preview click should create a MOVE preview without executing it"
            )
            require(
                distantObjectiveGame.scenario.units.first(where: { $0.id == distantAdvanceTank.id })?.position == distantAdvanceTank.position,
                "distant objective preview click should not move the unit"
            )
            distantObjectiveGame.focusNearestObjectiveTarget()
            require(distantObjectiveGame.focusedCoordinate == expectedAdvance, "distant objective shortcut should focus the forward tile")
            require(
                distantObjectiveGame.guidedObjectiveCoordinate == distantObjective.coordinate,
                "distant objective shortcut should keep the final objective marked"
            )
            require(distantObjectiveGame.message.contains("向纵深据点"), "distant objective shortcut should describe the objective direction")
            require(distantObjectiveGame.message.contains("距目标剩 1 格"), "distant objective shortcut should report remaining distance")
            require(
                distantObjectiveGame.focusedCommandPreview == .move(
                    unitName: distantAdvanceTank.name,
                    terrainName: distantObjectiveGame.tile(at: expectedAdvance)?.terrain.title ?? "",
                    route: distantAdvanceRoute
                ),
                "distant objective shortcut should create a MOVE preview toward the objective"
            )
            distantObjectiveGame.executeFocusedCommand()
            require(
                distantObjectiveGame.scenario.units.first(where: { $0.id == distantAdvanceTank.id })?.position == expectedAdvance,
                "executing distant objective MOVE should advance to the forward tile"
            )
            require(
                distantObjectiveGame.guidedObjectiveCoordinate == distantObjective.coordinate,
                "advancing toward a distant objective should preserve final objective guidance"
            )
            require(
                distantObjectiveGame.latestObjectiveCaptureResult == nil,
                "advancing toward a distant objective should not record a capture summary"
            )
            distantObjectiveGame.focus(coordinate: distantObjective.coordinate)
            require(
                distantObjectiveGame.guidedObjectiveCoordinate == nil,
                "ordinary map focus should clear objective guidance"
            )

            let multipleObjectiveGame = GameState(scenario: multipleObjectiveAdvancePreviewScenario())
            guard let multipleObjectiveTank = multipleObjectiveGame.units.first(where: { $0.name == "计划装甲" }) else {
                require(false, "multiple objective preview test unit should exist")
                return
            }
            multipleObjectiveGame.handlePrimaryAction(on: multipleObjectiveTank.position)
            let defaultObjectivePreviews = multipleObjectiveGame.objectiveAdvancePreviews(for: multipleObjectiveTank)
            require(
                defaultObjectivePreviews.map(\.objectiveName) == ["一号据点", "二号据点", "三号据点"],
                "objective advance previews should default to three sorted plans"
            )
            require(
                defaultObjectivePreviews.first?.coordinate == multipleObjectiveGame.nearestObjectiveTarget(for: multipleObjectiveTank)?.coordinate,
                "first sorted objective preview should match nearest objective shortcut"
            )
            require(
                defaultObjectivePreviews.allSatisfy { !$0.prioritySummaryText.isEmpty },
                "objective advance previews should expose priority summaries"
            )
            require(
                defaultObjectivePreviews.map(\.priorityReasonText) == ["本回合可夺取", "本回合可夺取", "本回合可占领"],
                "objective priority summaries should explain direct capture or occupation"
            )
            require(
                multipleObjectiveGame.objectiveAdvancePreviews(for: multipleObjectiveTank, limit: 10).map(\.objectiveName) == ["一号据点", "二号据点", "三号据点", "四号据点"],
                "objective advance preview limit should allow callers to inspect all plans"
            )
            require(
                multipleObjectiveGame.objectiveAdvancePreviews(for: multipleObjectiveTank, limit: 0).isEmpty,
                "objective advance preview limit zero should return no plans"
            )
            guard defaultObjectivePreviews.count >= 2 else {
                require(false, "multiple objective previews should include a second candidate")
                return
            }
            let secondObjectivePreview = defaultObjectivePreviews[1]
            multipleObjectiveGame.focusObjectiveAdvancePreview(secondObjectivePreview)
            require(
                multipleObjectiveGame.focusedCoordinate == secondObjectivePreview.route.destination,
                "second objective preview click should focus its route destination"
            )
            require(
                multipleObjectiveGame.guidedObjectiveCoordinate == secondObjectivePreview.coordinate,
                "second objective preview click should mark the selected final objective"
            )
            require(
                multipleObjectiveGame.scenario.units.first(where: { $0.id == multipleObjectiveTank.id })?.position == multipleObjectiveTank.position,
                "second objective preview click should not move the unit"
            )
            require(
                multipleObjectiveGame.focusedCommandPreview == .move(
                    unitName: multipleObjectiveTank.name,
                    terrainName: multipleObjectiveGame.tile(at: secondObjectivePreview.route.destination)?.terrain.title ?? "",
                    route: secondObjectivePreview.route
                ),
                "second objective preview click should expose an executable MOVE preview"
            )
            multipleObjectiveGame.executeFocusedCommand()
            require(
                multipleObjectiveGame.scenario.units.first(where: { $0.id == multipleObjectiveTank.id })?.position == secondObjectivePreview.route.destination,
                "executing focused second objective preview should move through the existing MOVE chain"
            )
            require(
                multipleObjectiveGame.tile(at: secondObjectivePreview.coordinate)?.owner == .allies,
                "executing focused second objective preview should capture direct objectives"
            )
            require(
                multipleObjectiveGame.latestObjectiveCaptureResult?.objectiveName == "二号据点",
                "executing focused second objective preview should record capture summary"
            )
            multipleObjectiveGame.focusObjectiveAdvanceTarget(coordinate: HexCoordinate(q: 3, r: 0))
            require(
                multipleObjectiveGame.guidedObjectiveCoordinate == nil,
                "invalid objective preview after movement should clear stale objective guidance"
            )

            let contestedZoneGame = GameState(scenario: zoneOfControlScenario(includeEnemy: true))
            let openZoneGame = GameState(scenario: zoneOfControlScenario(includeEnemy: false))
            guard let contestedRecon = contestedZoneGame.units.first(where: { $0.name == "接敌侦察" }),
                  let openRecon = openZoneGame.units.first(where: { $0.name == "接敌侦察" }) else {
                require(false, "zone of control test units should exist")
                return
            }
            let contactTile = HexCoordinate(q: 1, r: 1)
            let deepTile = HexCoordinate(q: 3, r: 0)
            require(contestedZoneGame.enemyControlZoneTiles(for: .allies).contains(contactTile), "enemy units should project adjacent control zones")
            require(!contestedZoneGame.threateningEnemies(against: .allies, at: contactTile).isEmpty, "enemy units should project attack threats onto covered tiles")
            require(contestedZoneGame.threatenedTiles(for: .allies).contains(deepTile), "threat map should include enemy fire coverage beyond reachable tiles")
            require(contestedZoneGame.threatenedReachableTiles(for: contestedRecon).contains(contactTile), "reachable threat overlay should include dangerous move destinations")
            require(contestedZoneGame.enemyControlZonePenalty(for: contestedRecon, entering: contactTile) == 1, "entering enemy control zones should add movement cost")
            require(
                contestedZoneGame.movementCostPreview(for: contestedRecon, entering: contactTile) == TerrainKind.plains.movementCost(for: .recon) + 1,
                "movement preview should include control zone cost"
            )
            guard let contestedRoute = contestedZoneGame.movementRoute(for: contestedRecon, to: contactTile) else {
                require(false, "contested contact tile should be reachable")
                return
            }
            let contestedRouteSteps = contestedZoneGame.routeStepPreviews(for: contestedRecon, route: contestedRoute)
            require(contestedRouteSteps.map(\.movementCost).reduce(0, +) == contestedRoute.totalCost, "route step costs should sum to total movement cost")
            require(contestedRouteSteps.map(\.controlZonePenalty).reduce(0, +) == contestedRoute.controlZonePenalty, "route step control-zone costs should sum to route penalty")
            require(contestedRouteSteps.first?.threatNames == ["控制区守军"], "route step preview should expose threat source names")
            require(openZoneGame.reachableTiles(for: openRecon).contains(deepTile), "open ground should allow recon to reach the deep tile")
            require(!contestedZoneGame.reachableTiles(for: contestedRecon).contains(deepTile), "control zone cost should restrict deep movement")
            require(openZoneGame.threatenedReachableTiles(for: openRecon).isEmpty, "threat overlay should stay empty when no enemy covers reachable tiles")
            require(contestedZoneGame.zoneOfControlSummary.contains("+1"), "control zone summary should describe movement penalty")

            let enemyThreatGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
            let startingEnemyThreatUnits = enemyThreatGame.scenario.units
            let startingEnemyThreatTiles = enemyThreatGame.scenario.tiles
            let startingEnemyThreatLog = enemyThreatGame.battleLog
            let enemyThreats = enemyThreatGame.enemyThreatIntentPreviews(against: .allies, limit: 10)
            require(enemyThreatGame.enemyThreatIntentPreviews(against: .allies, limit: 0).isEmpty, "enemy threat intent limit zero should return no previews")
            require(enemyThreatGame.enemyThreatIntentPreviews(against: .allies, limit: 2) == Array(enemyThreats.prefix(2)), "enemy threat intent limit should preserve sorted prefix")
            require(enemyThreatGame.visibleEnemyThreatIntentPreviews == enemyThreatGame.enemyThreatIntentPreviews(against: .allies), "visible enemy threat intents should expose the allied preview")
            guard let directThreat = enemyThreats.first(where: {
                $0.kind == .directAttack &&
                    $0.enemyUnitName == "威胁炮兵" &&
                    $0.targetName == "前线装甲"
            }) else {
                require(false, "enemy threat intents should include direct attack previews")
                return
            }
            guard let directEnemy = enemyThreatGame.units.first(where: { $0.id == directThreat.enemyUnitID }),
                  let directTarget = enemyThreatGame.units.first(where: { $0.id == directThreat.targetUnitID }),
                  let directCombat = enemyThreatGame.combatPreview(attacker: directEnemy, defender: directTarget) else {
                require(false, "direct enemy threat combat preview should be reproducible")
                return
            }
            require(directThreat.routeDestination == nil, "direct enemy threat should not expose a route destination")
            require(directThreat.projectedDamage == directCombat.damage, "direct enemy threat damage should match combat preview")
            require(directThreat.projectedTargetHPAfterDamage == directCombat.defenderHPAfterAttack, "direct enemy threat HP projection should match combat preview")

            guard let approachThreat = enemyThreats.first(where: {
                $0.kind == .approachAttack &&
                    $0.enemyUnitName == "突击侦察" &&
                    $0.targetName == "后方步兵"
            }) else {
                require(false, "enemy threat intents should include approach attack previews")
                return
            }
            require(approachThreat.routeDestination != nil, "approach enemy threat should include route destination")
            require((approachThreat.routeCost ?? 0) > 0, "approach enemy threat should include route cost")
            require(approachThreat.projectedDamage > 0, "approach enemy threat should include projected damage")

            guard let objectiveThreat = enemyThreats.first(where: {
                $0.kind == .objectiveCapture &&
                    $0.enemyUnitName == "夺点步兵" &&
                    $0.targetName == "后方油库"
            }) else {
                require(false, "enemy threat intents should include objective capture previews")
                return
            }
            require(objectiveThreat.targetUnitID == nil, "objective enemy threat should not target a unit")
            require(objectiveThreat.routeDestination == objectiveThreat.targetCoordinate, "objective enemy threat route should end on the objective")
            require(objectiveThreat.objectiveOwner == .allies, "objective enemy threat should expose the current owner")
            require(objectiveThreat.projectedDamage == 0, "objective enemy threat should not invent combat damage")
            require(enemyThreatGame.scenario.units == startingEnemyThreatUnits, "enemy threat intents should not mutate units")
            require(enemyThreatGame.scenario.tiles == startingEnemyThreatTiles, "enemy threat intents should not mutate objectives")
            require(enemyThreatGame.battleLog == startingEnemyThreatLog, "enemy threat intents should not write battle log entries")

            let startingCountermeasureCommandPoints = enemyThreatGame.commandPoints
            let enemyCountermeasures = enemyThreatGame.enemyThreatCountermeasurePreviews(for: enemyThreats, limit: 10)
            func expectedCountermeasureComparisonTitle(
                leading: EnemyThreatCountermeasurePreview,
                trailing: EnemyThreatCountermeasurePreview
            ) -> String {
                if leading.canExecuteNow != trailing.canExecuteNow { return "可执行" }
                if leading.willDestroyEnemy != trailing.willDestroyEnemy { return "击毁" }
                if leading.score != trailing.score { return "优先值" }
                if leading.routeCost != trailing.routeCost { return "路线" }
                if leading.actingUnitName != trailing.actingUnitName { return "执行单位" }
                if leading.targetName != trailing.targetName { return "目标" }
                if leading.destination?.id != trailing.destination?.id { return "坐标" }
                if leading.threatID != trailing.threatID { return "威胁" }
                if leading.threatTargetCoordinate.id != trailing.threatTargetCoordinate.id { return "威胁坐标" }
                if leading.actingUnitID?.uuidString != trailing.actingUnitID?.uuidString { return "执行ID" }
                if leading.targetUnitID?.uuidString != trailing.targetUnitID?.uuidString { return "目标ID" }
                return "类型"
            }
            func syntheticCountermeasure(
                canExecuteNow: Bool = true,
                willDestroyEnemy: Bool = false,
                score: Int = 100,
                routeCost: Int? = 2
            ) -> EnemyThreatCountermeasurePreview {
                EnemyThreatCountermeasurePreview(
                    kind: .withdraw,
                    threatID: "synthetic-\(canExecuteNow)-\(willDestroyEnemy)-\(score)-\(routeCost ?? -1)",
                    threatKind: .directAttack,
                    threatEnemyUnitID: UUID(),
                    threatEnemyUnitName: "合成威胁",
                    threatTargetCoordinate: HexCoordinate(q: 0, r: 0),
                    actingUnitID: UUID(),
                    actingUnitName: "合成单位",
                    targetUnitID: UUID(),
                    targetName: "合成目标",
                    destination: HexCoordinate(q: 0, r: 0),
                    routeCost: routeCost,
                    projectedDamage: willDestroyEnemy ? 10 : 2,
                    projectedEnemyHPAfterDamage: willDestroyEnemy ? 0 : 8,
                    willDestroyEnemy: willDestroyEnemy,
                    projectedFriendlyHPAfterAction: 8,
                    projectedRecoveredHP: 0,
                    canExecuteNow: canExecuteNow,
                    reason: "合成排序测试",
                    score: score,
                    impactComparisons: []
                )
            }
            @MainActor
            func requireTopComparison(
                previews: [EnemyThreatCountermeasurePreview],
                expectedKind: EnemyThreatCountermeasurePriorityFactorKind,
                expectedTitle: String,
                expectedValue: String,
                expectedDetail: String
            ) {
                guard let comparison = enemyThreatGame.enemyThreatCountermeasureComparisonPreviews(for: previews, limit: 2).first else {
                    require(false, "synthetic countermeasure comparison should exist")
                    return
                }
                require(comparison.factor.kind == expectedKind, "synthetic countermeasure comparison kind should match")
                require(comparison.factor.title == expectedTitle, "synthetic countermeasure comparison title should match")
                require(comparison.factor.value == expectedValue, "synthetic countermeasure comparison value should match")
                require(comparison.factor.detail == expectedDetail, "synthetic countermeasure comparison detail should match")
                require(comparison.summary.contains(expectedDetail), "synthetic countermeasure comparison summary should include detail")
            }

            require(!enemyCountermeasures.isEmpty, "enemy threat countermeasures should be available")
            require(enemyThreatGame.enemyThreatCountermeasurePreviews(for: enemyThreats, limit: 0).isEmpty, "enemy threat countermeasure limit zero should return no previews")
            require(enemyThreatGame.enemyThreatCountermeasurePreviews(for: enemyThreats, limit: 2) == Array(enemyCountermeasures.prefix(2)), "enemy threat countermeasure limit should preserve sorted prefix")
            require(enemyThreatGame.visibleEnemyThreatCountermeasurePreviews == enemyThreatGame.enemyThreatCountermeasurePreviews(for: enemyThreatGame.visibleEnemyThreatIntentPreviews), "visible enemy threat countermeasures should expose the allied preview")
            require(!(enemyThreatGame.focusedEnemyThreatCountermeasureExecutionPreview?.isExecutable == true), "enemy threat countermeasure execution bridge should require focused advice")
            require(enemyThreatGame.enemyThreatCountermeasureComparisonPreviews(for: enemyCountermeasures, limit: 0).isEmpty, "countermeasure comparison limit zero should return no previews")
            require(enemyThreatGame.enemyThreatCountermeasureComparisonPreviews(for: enemyCountermeasures, limit: 1).isEmpty, "countermeasure comparison limit one should not invent adjacency")
            let enemyCountermeasureComparisons = enemyThreatGame.enemyThreatCountermeasureComparisonPreviews(for: enemyCountermeasures, limit: 3)
            require(enemyCountermeasureComparisons.count == max(0, min(enemyCountermeasures.count, 3) - 1), "countermeasure comparison count should match adjacent previews")
            if enemyCountermeasures.count >= 2 {
                guard let topComparison = enemyCountermeasureComparisons.first else {
                    require(false, "countermeasure comparison should explain the top adjacent ordering")
                    return
                }
                require(topComparison.leading.id == enemyCountermeasures[0].id, "countermeasure comparison should keep the top advice")
                require(topComparison.trailing.id == enemyCountermeasures[1].id, "countermeasure comparison should compare against the second advice")
                require(topComparison.factor.title == expectedCountermeasureComparisonTitle(leading: enemyCountermeasures[0], trailing: enemyCountermeasures[1]), "countermeasure comparison should match the existing sort dimension")
                require(!topComparison.factor.value.isEmpty, "countermeasure comparison value should not be empty")
                require(topComparison.summary.contains(topComparison.factor.detail), "countermeasure comparison summary should include the deciding detail")
            }
            requireTopComparison(
                previews: [
                    syntheticCountermeasure(canExecuteNow: false, score: 999),
                    syntheticCountermeasure(canExecuteNow: true, score: 1)
                ],
                expectedKind: .availability,
                expectedTitle: "可执行",
                expectedValue: "是 > 否",
                expectedDetail: "执行单位当前可行动"
            )
            requireTopComparison(
                previews: [
                    syntheticCountermeasure(willDestroyEnemy: false, score: 999),
                    syntheticCountermeasure(willDestroyEnemy: true, score: 1)
                ],
                expectedKind: .decisiveStrike,
                expectedTitle: "击毁",
                expectedValue: "是 > 否",
                expectedDetail: "可直接击毁威胁来源"
            )
            requireTopComparison(
                previews: [
                    syntheticCountermeasure(score: 80),
                    syntheticCountermeasure(score: 120)
                ],
                expectedKind: .priorityScore,
                expectedTitle: "优先值",
                expectedValue: "120 > 80",
                expectedDetail: "优先值 120 高于 80"
            )
            requireTopComparison(
                previews: [
                    syntheticCountermeasure(score: 100, routeCost: 5),
                    syntheticCountermeasure(score: 100, routeCost: 1)
                ],
                expectedKind: .routeCost,
                expectedTitle: "路线",
                expectedValue: "1 < 5",
                expectedDetail: "路线消耗 1 更低"
            )
            for countermeasure in enemyCountermeasures {
                require(!countermeasure.priorityFactors.isEmpty, "countermeasure should expose priority factors")
                require(countermeasure.prioritySummary.contains("优先值 \(countermeasure.score)"), "countermeasure priority summary should include score")
                require(countermeasure.priorityFactors.contains { $0.kind == .priorityScore && $0.value == "\(countermeasure.score)" }, "countermeasure priority factors should expose score")
                require(!countermeasure.impactComparisons.isEmpty, "countermeasure should expose before-after impact comparisons")
                require(!countermeasure.impactSummary.isEmpty, "countermeasure should expose before-after impact summary")
            }

            guard let firstStrike = enemyCountermeasures.first(where: {
                $0.kind == .firstStrike &&
                    $0.actingUnitName == "反击炮兵" &&
                    $0.threatEnemyUnitName == "威胁炮兵"
            }) else {
                require(false, "enemy threat countermeasures should include first strike advice")
                return
            }
            guard let firstStrikeThreat = enemyThreats.first(where: { $0.id == firstStrike.threatID }),
                  let counterBattery = enemyThreatGame.units.first(where: { $0.id == firstStrike.actingUnitID }),
                  let firstStrikeTarget = enemyThreatGame.units.first(where: { $0.id == firstStrike.targetUnitID }),
                  let firstStrikeCombat = enemyThreatGame.combatPreview(attacker: counterBattery, defender: firstStrikeTarget) else {
                require(false, "first strike countermeasure combat preview should be reproducible")
                return
            }
            require(firstStrike.projectedDamage == firstStrikeCombat.damage, "first strike damage should match combat preview")
            require(firstStrike.projectedEnemyHPAfterDamage == firstStrikeCombat.defenderHPAfterAttack, "first strike HP projection should match combat preview")
            require(firstStrike.routeCost == nil, "first strike should not invent a movement route")
            require(!firstStrike.benefitSummary.isEmpty, "first strike should expose benefit summary")
            require(firstStrike.benefitMetrics.contains { $0.kind == .damage }, "first strike should expose damage benefit")
            require(firstStrike.prioritySummary.contains(firstStrike.willDestroyEnemy ? "可击毁威胁" : firstStrike.kind.title), "first strike should explain its priority basis")
            guard let firstStrikeImpact = firstStrike.impactComparisons.first(where: { $0.kind == .threatDamage }) else {
                require(false, "first strike should expose threat damage impact")
                return
            }
            let firstStrikeBefore = firstStrikeThreat.willDestroyTarget ? "击毁风险" : "-\(firstStrikeThreat.projectedDamage)"
            require(firstStrikeImpact.before == firstStrikeBefore, "first strike impact should expose the current threat")
            require(!firstStrikeImpact.after.isEmpty, "first strike impact should expose the post-action threat source state")

            guard let withdraw = enemyCountermeasures.first(where: {
                $0.kind == .withdraw &&
                    $0.actingUnitName == "前线装甲"
            }) else {
                require(false, "enemy threat countermeasures should include withdraw advice")
                return
            }
            guard let withdrawThreat = enemyThreats.first(where: { $0.id == withdraw.threatID }),
                  let withdrawBeforeHP = withdrawThreat.projectedTargetHPAfterDamage else {
                require(false, "withdraw countermeasure should link to an attack threat with before HP")
                return
            }
            guard let withdrawDestination = withdraw.destination,
                  let withdrawUnit = enemyThreatGame.units.first(where: { $0.id == withdraw.actingUnitID }),
                  let withdrawRoute = enemyThreatGame.movementRoute(for: withdrawUnit, to: withdrawDestination) else {
                require(false, "withdraw countermeasure route should be reproducible")
                return
            }
            require(withdraw.routeCost == withdrawRoute.totalCost, "withdraw route cost should match movement route")
            require((withdraw.projectedFriendlyHPAfterAction ?? 0) > 0, "withdraw should project surviving HP")
            require(withdraw.benefitMetrics.contains { $0.kind == .survival }, "withdraw should expose survival benefit")
            require(withdraw.benefitMetrics.contains { $0.kind == .route && $0.value == "\(withdrawRoute.totalCost)" }, "withdraw should expose route benefit")
            require(withdraw.prioritySummary.contains("路线 \(withdrawRoute.totalCost)"), "withdraw should explain route priority")
            guard let withdrawImpact = withdraw.impactComparisons.first(where: { $0.kind == .survival }) else {
                require(false, "withdraw should expose survival impact")
                return
            }
            require(withdrawImpact.before == "HP \(withdrawBeforeHP)", "withdraw impact should expose before HP")
            require(withdrawImpact.after == "HP \(withdraw.projectedFriendlyHPAfterAction ?? 0)", "withdraw impact should expose projected after HP")
            require((withdraw.projectedFriendlyHPAfterAction ?? 0) > withdrawBeforeHP, "withdraw impact should improve projected HP")

            guard let objectiveDefense = enemyCountermeasures.first(where: {
                $0.kind == .objectiveDefense &&
                    $0.targetName == "后方油库"
            }) else {
                require(false, "enemy threat countermeasures should include objective defense advice")
                return
            }
            require(objectiveDefense.destination?.distance(to: HexCoordinate(q: 2, r: 2)) ?? Int.max <= 1, "objective defense should reach or screen the threatened objective")
            require(objectiveDefense.benefitMetrics.contains { $0.kind == .objective }, "objective defense should expose objective benefit")
            require(objectiveDefense.benefitMetrics.contains { $0.kind == .route }, "objective defense should expose route benefit")
            require(objectiveDefense.prioritySummary.contains(objectiveDefense.kind.title), "objective defense should explain its priority basis")
            guard let objectiveImpact = objectiveDefense.impactComparisons.first(where: { $0.kind == .objective }) else {
                require(false, "objective defense should expose objective impact")
                return
            }
            require(objectiveImpact.before == "被夺风险", "objective impact should expose capture risk")
            require(objectiveImpact.after == "进驻" || objectiveImpact.after == "封堵", "objective impact should expose defense action")

            guard let reinforce = enemyCountermeasures.first(where: {
                $0.kind == .reinforce &&
                    $0.actingUnitName == "前线装甲"
            }) else {
                require(false, "enemy threat countermeasures should include reinforce advice")
                return
            }
            guard let reinforceThreat = enemyThreats.first(where: { $0.id == reinforce.threatID }),
                  let reinforceBeforeHP = reinforceThreat.projectedTargetHPAfterDamage else {
                require(false, "reinforce countermeasure should link to an attack threat with before HP")
                return
            }
            require(reinforce.projectedRecoveredHP == UnitKind.tank.reinforceAmount, "reinforce countermeasure should project recovery amount")
            require(reinforce.destination == withdrawUnit.position, "reinforce countermeasure should stay on the threatened objective")
            require(reinforce.benefitMetrics.contains { $0.kind == .recovery && $0.value.contains("\(reinforce.projectedRecoveredHP)") }, "reinforce should expose recovery benefit")
            require(reinforce.prioritySummary.contains("当前位置"), "reinforce should explain current-position priority")
            guard let reinforceRecoveryImpact = reinforce.impactComparisons.first(where: { $0.kind == .recovery }),
                  let reinforceSurvivalImpact = reinforce.impactComparisons.first(where: { $0.kind == .survival }) else {
                require(false, "reinforce should expose recovery and survival impact")
                return
            }
            let reinforceExpectedHPAfterThreat = max(0, (reinforce.projectedFriendlyHPAfterAction ?? 0) - reinforceThreat.projectedDamage)
            let reinforceBeforeText = reinforceThreat.willDestroyTarget ? "被击毁" : "HP \(reinforceBeforeHP)"
            require(reinforce.impactComparisons.first?.kind == .survival, "reinforce should lead with survival after the projected threat")
            require(reinforceSurvivalImpact.before == reinforceBeforeText, "reinforce survival impact should expose current threat outcome")
            require(reinforceSurvivalImpact.after == "HP \(reinforceExpectedHPAfterThreat)", "reinforce survival impact should expose projected HP after the threat")
            require(reinforceExpectedHPAfterThreat > reinforceBeforeHP, "reinforce survival impact should improve projected HP after the threat")
            require(reinforceRecoveryImpact.before == "HP \(reinforceBeforeHP)", "reinforce impact should expose before HP")
            require(reinforceRecoveryImpact.after == "HP \(reinforce.projectedFriendlyHPAfterAction ?? 0)", "reinforce impact should expose recovery HP")

            let situationSummary = enemyThreatGame.battlefieldSituationSummary
            require(situationSummary.enemyThreatCount == enemyThreatGame.enemyThreatIntentPreviews(against: .allies, limit: 6).count, "battlefield situation should reuse threat previews")
            require(situationSummary.attackThreatCount == enemyThreatGame.enemyThreatIntentPreviews(against: .allies, limit: 6).filter(\.isAttackThreat).count, "battlefield situation should count attack threats")
            require(situationSummary.objectiveThreatCount == enemyThreatGame.enemyThreatIntentPreviews(against: .allies, limit: 6).filter { $0.kind == .objectiveCapture }.count, "battlefield situation should count objective threats")
            require(situationSummary.executableCountermeasureCount == enemyThreatGame.enemyThreatCountermeasurePreviews(for: enemyThreatGame.enemyThreatIntentPreviews(against: .allies, limit: 6), limit: 6).filter(\.canExecuteNow).count, "battlefield situation should count executable countermeasures")
            require(situationSummary.threatenedObjectiveNames.contains("后方油库"), "battlefield situation should list threatened objectives")
            require(situationSummary.priority == .threatened, "battlefield situation should mark threatened front")
            require(situationSummary.focusKind == .countermeasure, "battlefield situation should recommend countermeasures when available")
            require(situationSummary.threatenedObjectiveSummary.contains("后方油库"), "battlefield situation should summarize threatened objectives")
            require(enemyThreatGame.commandPoints == startingCountermeasureCommandPoints, "enemy threat countermeasures should not spend command points")
            require(enemyThreatGame.scenario.units == startingEnemyThreatUnits, "enemy threat countermeasures should not mutate units")
            require(enemyThreatGame.scenario.tiles == startingEnemyThreatTiles, "enemy threat countermeasures should not mutate objectives")
            require(enemyThreatGame.battleLog == startingEnemyThreatLog, "enemy threat countermeasures should not write battle log entries")

            @MainActor
            func countermeasureMarkerRoles(at coordinate: HexCoordinate) -> Set<EnemyThreatCountermeasureMapMarkerRole> {
                Set(
                    enemyThreatGame.focusedEnemyThreatCountermeasureMapMarkers
                        .filter { $0.coordinate == coordinate }
                        .map(\.role)
                )
            }

            enemyThreatGame.focusEnemyThreatCountermeasure(firstStrike)
            guard let firstStrikeEnemy = enemyThreatGame.units.first(where: { $0.id == firstStrike.threatEnemyUnitID }) else {
                require(false, "first strike focus should still have a threat source")
                return
            }
            guard let firstStrikeUnit = enemyThreatGame.units.first(where: { $0.id == firstStrike.actingUnitID }) else {
                require(false, "first strike focus should still have an acting unit")
                return
            }
            require(enemyThreatGame.selectedUnit?.id == firstStrike.actingUnitID, "first strike focus should select the acting unit")
            require(enemyThreatGame.focusedCoordinate == firstStrikeEnemy.position, "first strike focus should target the enemy")
            require(enemyThreatGame.guidedObjectiveCoordinate == nil, "first strike focus should clear objective guidance")
            require(enemyThreatGame.isEnemyThreatCountermeasureFocused(firstStrike), "first strike focus state should be detectable")
            require(countermeasureMarkerRoles(at: firstStrikeUnit.position).contains(.actingUnit), "first strike marker should identify the acting unit")
            require(countermeasureMarkerRoles(at: firstStrikeEnemy.position).contains(.threatSource), "first strike marker should identify the threat source")
            require(countermeasureMarkerRoles(at: firstStrikeEnemy.position).contains(.counterTarget), "first strike marker should identify the counter target")
            guard let firstStrikeExecution = enemyThreatGame.focusedEnemyThreatCountermeasureExecutionPreview else {
                require(false, "first strike focus should expose an execution bridge preview")
                return
            }
            require(firstStrikeExecution.kind == .attack, "first strike execution bridge should point to ATK")
            require(firstStrikeExecution.countermeasureKind == .firstStrike, "first strike execution bridge should keep the countermeasure kind")
            require(firstStrikeExecution.isExecutable, "first strike execution bridge should be executable")
            require(firstStrikeExecution.coordinate == firstStrikeEnemy.position, "first strike execution bridge should point to the enemy position")
            require(firstStrikeExecution.unitName == firstStrikeUnit.name, "first strike execution bridge should name the acting unit")

            enemyThreatGame.focusEnemyThreatCountermeasure(withdraw)
            guard let withdrawFocusDestination = withdraw.destination,
                  let withdrawFocusUnit = enemyThreatGame.units.first(where: { $0.id == withdraw.actingUnitID }) else {
                require(false, "withdraw focus should keep unit and destination")
                return
            }
            guard let withdrawEnemy = enemyThreatGame.units.first(where: { $0.id == withdraw.threatEnemyUnitID }) else {
                require(false, "withdraw focus should keep the threat source")
                return
            }
            require(enemyThreatGame.selectedUnit?.id == withdraw.actingUnitID, "withdraw focus should select the threatened unit")
            require(enemyThreatGame.focusedCoordinate == withdrawFocusDestination, "withdraw focus should target the retreat destination")
            require(enemyThreatGame.guidedObjectiveCoordinate == nil, "withdraw focus should not set objective guidance")
            require(enemyThreatGame.movementRoute(for: withdrawFocusUnit, to: withdrawFocusDestination) != nil, "withdraw focus route should be reproducible")
            require(enemyThreatGame.isEnemyThreatCountermeasureFocused(withdraw), "withdraw focus state should be detectable")
            require(countermeasureMarkerRoles(at: withdrawFocusUnit.position).contains(.actingUnit), "withdraw marker should identify the acting unit")
            require(countermeasureMarkerRoles(at: withdrawEnemy.position).contains(.threatSource), "withdraw marker should identify the threat source")
            require(countermeasureMarkerRoles(at: withdrawFocusDestination).contains(.counterTarget), "withdraw marker should identify the retreat destination")
            require(countermeasureMarkerRoles(at: withdraw.threatTargetCoordinate).contains(.threatenedTarget), "withdraw marker should identify the threatened target")
            guard let withdrawExecution = enemyThreatGame.focusedEnemyThreatCountermeasureExecutionPreview else {
                require(false, "withdraw focus should expose an execution bridge preview")
                return
            }
            require(withdrawExecution.kind == .move, "withdraw execution bridge should point to MOVE")
            require(withdrawExecution.countermeasureKind == .withdraw, "withdraw execution bridge should keep the countermeasure kind")
            require(withdrawExecution.isExecutable, "withdraw execution bridge should be executable")
            require(withdrawExecution.coordinate == withdrawFocusDestination, "withdraw execution bridge should point to the retreat destination")
            require(withdrawExecution.unitName == withdrawFocusUnit.name, "withdraw execution bridge should name the acting unit")

            enemyThreatGame.focusEnemyThreatCountermeasure(objectiveDefense)
            guard let defenseDestination = objectiveDefense.destination,
                  let defenseUnit = enemyThreatGame.units.first(where: { $0.id == objectiveDefense.actingUnitID }) else {
                require(false, "objective defense focus should keep unit and destination")
                return
            }
            guard let defenseEnemy = enemyThreatGame.units.first(where: { $0.id == objectiveDefense.threatEnemyUnitID }) else {
                require(false, "objective defense focus should keep the threat source")
                return
            }
            require(enemyThreatGame.selectedUnit?.id == objectiveDefense.actingUnitID, "objective defense focus should select the acting unit")
            require(enemyThreatGame.focusedCoordinate == defenseDestination, "objective defense focus should target the defense destination")
            require(enemyThreatGame.guidedObjectiveCoordinate == objectiveDefense.threatTargetCoordinate, "objective defense focus should guide the threatened objective")
            require(enemyThreatGame.movementRoute(for: defenseUnit, to: defenseDestination) != nil, "objective defense focus route should be reproducible")
            require(enemyThreatGame.isEnemyThreatCountermeasureFocused(objectiveDefense), "objective defense focus state should be detectable")
            require(countermeasureMarkerRoles(at: defenseUnit.position).contains(.actingUnit), "objective defense marker should identify the acting unit")
            require(countermeasureMarkerRoles(at: defenseEnemy.position).contains(.threatSource), "objective defense marker should identify the threat source")
            require(countermeasureMarkerRoles(at: defenseDestination).contains(.counterTarget), "objective defense marker should identify the defense destination")
            require(countermeasureMarkerRoles(at: objectiveDefense.threatTargetCoordinate).contains(.threatenedTarget), "objective defense marker should identify the threatened objective")
            guard let objectiveDefenseExecution = enemyThreatGame.focusedEnemyThreatCountermeasureExecutionPreview else {
                require(false, "objective defense focus should expose an execution bridge preview")
                return
            }
            require(objectiveDefenseExecution.kind == .move, "objective defense execution bridge should point to MOVE")
            require(objectiveDefenseExecution.countermeasureKind == .objectiveDefense, "objective defense execution bridge should keep the countermeasure kind")
            require(objectiveDefenseExecution.isExecutable, "objective defense execution bridge should be executable")
            require(objectiveDefenseExecution.coordinate == defenseDestination, "objective defense execution bridge should point to the defense destination")
            require(objectiveDefenseExecution.unitName == defenseUnit.name, "objective defense execution bridge should name the acting unit")

            enemyThreatGame.focusEnemyThreatCountermeasure(reinforce)
            guard let reinforceUnit = enemyThreatGame.units.first(where: { $0.id == reinforce.actingUnitID }) else {
                require(false, "reinforce focus should keep the acting unit")
                return
            }
            guard let reinforceEnemy = enemyThreatGame.units.first(where: { $0.id == reinforce.threatEnemyUnitID }) else {
                require(false, "reinforce focus should keep the threat source")
                return
            }
            require(enemyThreatGame.selectedUnit?.id == reinforce.actingUnitID, "reinforce focus should select the acting unit")
            require(enemyThreatGame.focusedCoordinate == reinforceUnit.position, "reinforce focus should stay on the unit")
            require(enemyThreatGame.guidedObjectiveCoordinate == nil, "reinforce focus should clear objective guidance")
            require(enemyThreatGame.isEnemyThreatCountermeasureFocused(reinforce), "reinforce focus state should be detectable")
            require(countermeasureMarkerRoles(at: reinforceUnit.position).contains(.actingUnit), "reinforce marker should identify the acting unit")
            require(countermeasureMarkerRoles(at: reinforceEnemy.position).contains(.threatSource), "reinforce marker should identify the threat source")
            require(countermeasureMarkerRoles(at: reinforceUnit.position).contains(.counterTarget), "reinforce marker should identify the counter target")
            require(countermeasureMarkerRoles(at: reinforce.threatTargetCoordinate).contains(.threatenedTarget), "reinforce marker should identify the threatened target")
            guard let reinforceExecution = enemyThreatGame.focusedEnemyThreatCountermeasureExecutionPreview else {
                require(false, "reinforce focus should expose an execution bridge preview")
                return
            }
            require(reinforceExecution.kind == .reinforce, "reinforce execution bridge should point to the reinforce button")
            require(reinforceExecution.countermeasureKind == .reinforce, "reinforce execution bridge should keep the countermeasure kind")
            require(reinforceExecution.isExecutable, "reinforce execution bridge should be executable")
            require(reinforceExecution.coordinate == reinforceUnit.position, "reinforce execution bridge should point to the unit position")
            require(reinforceExecution.unitName == reinforceUnit.name, "reinforce execution bridge should name the acting unit")

            enemyThreatGame.focus(coordinate: reinforceUnit.position)
            require(enemyThreatGame.focusedEnemyThreatCountermeasureMapMarkers.isEmpty, "plain focus should clear countermeasure map markers")
            require(!(enemyThreatGame.focusedEnemyThreatCountermeasureExecutionPreview?.isExecutable == true), "plain focus should clear the executable bridge preview")

            let staleCountermeasure = EnemyThreatCountermeasurePreview(
                kind: .firstStrike,
                threatID: "stale-countermeasure",
                threatKind: firstStrike.threatKind,
                threatEnemyUnitID: firstStrike.threatEnemyUnitID,
                threatEnemyUnitName: firstStrike.threatEnemyUnitName,
                threatTargetCoordinate: firstStrike.threatTargetCoordinate,
                actingUnitID: UUID(),
                actingUnitName: "不存在单位",
                targetUnitID: firstStrike.targetUnitID,
                targetName: firstStrike.targetName,
                destination: nil,
                routeCost: nil,
                projectedDamage: 0,
                projectedEnemyHPAfterDamage: nil,
                willDestroyEnemy: false,
                projectedFriendlyHPAfterAction: nil,
                projectedRecoveredHP: 0,
                canExecuteNow: false,
                reason: "测试过期建议",
                score: 0,
                impactComparisons: []
            )
            enemyThreatGame.focusEnemyThreatCountermeasure(staleCountermeasure)
            require(enemyThreatGame.message.contains("已不可用"), "stale countermeasure focus should explain that the advice expired")
            require(enemyThreatGame.focusedEnemyThreatCountermeasureMapMarkers.isEmpty, "stale countermeasure focus should not keep map markers")
            require(!(enemyThreatGame.focusedEnemyThreatCountermeasureExecutionPreview?.isExecutable == true), "stale countermeasure focus should not keep an executable bridge preview")
            require(enemyThreatGame.latestEnemyThreatCountermeasureExecutionResult == nil, "countermeasure focus should not publish execution replay")
            require(enemyThreatGame.commandPoints == startingCountermeasureCommandPoints, "countermeasure focus should not spend command points")
            require(enemyThreatGame.scenario.units == startingEnemyThreatUnits, "countermeasure focus should not mutate units")
            require(enemyThreatGame.scenario.tiles == startingEnemyThreatTiles, "countermeasure focus should not mutate objectives")
            require(enemyThreatGame.battleLog == startingEnemyThreatLog, "countermeasure focus should not write battle log entries")

            verifyCountermeasureExecutionReplay()
            verifyCountermeasureFollowUpVerification()

            let commandGame = GameState(
                scenario: tacticalCommandScenario(),
                commandPoints: [.allies: 6, .axis: 6]
            )
            guard let barrageArtillery = commandGame.units.first(where: { $0.name == "弹幕炮兵" }),
                  let barrageTarget = commandGame.units.first(where: { $0.name == "弹幕目标" }),
                  let ordinaryInfantry = commandGame.units.first(where: { $0.name == "普通步兵" }),
                  let barragePreview = commandGame.tacticalCommandPreview(command: .artilleryBarrage, caster: barrageArtillery, target: barrageTarget) else {
                require(false, "tactical command preview units should exist")
                return
            }
            require(barragePreview.command == .artilleryBarrage, "barrage preview should identify the command")
            require(barragePreview.commandCost == TacticalCommand.artilleryBarrage.commandCost, "barrage preview should expose command cost")
            require(barragePreview.damage > 0, "barrage should deal damage")
            require(barragePreview.outcomeText.contains("士气"), "barrage preview should show morale suppression")
            require(commandGame.tacticalCommandTargets(for: barrageArtillery, command: .artilleryBarrage).count == 1, "barrage should find targets in command range")
            require(commandGame.canUseTacticalCommand(.artilleryBarrage, with: barrageArtillery), "artillery should be able to use barrage")
            require(!commandGame.canUseTacticalCommand(.artilleryBarrage, with: ordinaryInfantry), "non-artillery units should not use barrage")
            commandGame.useTacticalCommand(.artilleryBarrage, casterID: barrageArtillery.id, targetID: barrageTarget.id)
            guard let barrageArtilleryAfter = commandGame.units.first(where: { $0.id == barrageArtillery.id }),
                  let barrageTargetAfter = commandGame.units.first(where: { $0.id == barrageTarget.id }) else {
                require(false, "barrage units should survive the tactical command test")
                return
            }
            require(commandGame.commandPoints(for: .allies) == 6 - TacticalCommand.artilleryBarrage.commandCost, "barrage should spend command points")
            require(barrageTargetAfter.hp == barrageTarget.hp - barragePreview.damage, "barrage should apply previewed damage")
            require(barrageTargetAfter.morale == barrageTarget.morale - TacticalCommand.artilleryBarrage.moraleDamage, "barrage should suppress morale")
            require(barrageArtilleryAfter.hp == barrageArtillery.hp, "barrage should not trigger counterattack damage")
            require(barrageArtilleryAfter.hasMoved && barrageArtilleryAfter.hasAttacked, "barrage should spend the artillery action")
            guard let barrageSummary = commandGame.latestTacticalCommandResult else {
                require(false, "barrage should publish tactical command result summary")
                return
            }
            require(commandGame.latestCombatResult == nil, "barrage should clear ordinary combat result")
            require(barrageSummary.command == .artilleryBarrage, "barrage summary should identify command")
            require(barrageSummary.caster.unitID == barrageArtillery.id, "barrage summary should identify caster")
            require(barrageSummary.target.unitID == barrageTarget.id, "barrage summary should identify target")
            require(barrageSummary.damage == barragePreview.damage, "barrage summary should record damage")
            require(barrageSummary.commandCost == TacticalCommand.artilleryBarrage.commandCost, "barrage summary should record command cost")
            require(barrageSummary.moraleDamage == TacticalCommand.artilleryBarrage.moraleDamage, "barrage summary should record morale damage")
            require(barrageSummary.statusEffect == .suppressed, "barrage summary should record suppression")
            require(barrageSummary.didAvoidCounterAttack, "barrage summary should record no counterattack")
            require(barrageSummary.target.startingHP == barrageTarget.hp && barrageSummary.target.endingHP == barrageTargetAfter.hp, "barrage summary should record HP before and after")
            require(commandGame.battleLog.contains { $0.contains("火炮弹幕") && $0.contains("无反击") }, "barrage log should mention no counterattack")

            let lowCommandGame = GameState(
                scenario: tacticalCommandScenario(),
                commandPoints: [.allies: 2, .axis: 6]
            )
            guard let lowCommandArtillery = lowCommandGame.units.first(where: { $0.name == "弹幕炮兵" }),
                  let lowCommandTarget = lowCommandGame.units.first(where: { $0.name == "弹幕目标" }) else {
                require(false, "low command point tactical command units should exist")
                return
            }
            require(!lowCommandGame.canUseTacticalCommand(.artilleryBarrage, with: lowCommandArtillery), "barrage should require enough command points")
            lowCommandGame.useTacticalCommand(.artilleryBarrage, casterID: lowCommandArtillery.id, targetID: lowCommandTarget.id)
            guard let lowCommandTargetAfter = lowCommandGame.units.first(where: { $0.id == lowCommandTarget.id }) else {
                require(false, "low command target should survive blocked command attempt")
                return
            }
            require(lowCommandGame.commandPoints(for: .allies) == 2, "blocked command should not spend points")
            require(lowCommandTargetAfter.hp == lowCommandTarget.hp, "blocked command should not damage target")
            require(lowCommandGame.latestTacticalCommandResult == nil, "blocked command should not publish a tactical command result")

            let breakthroughGame = GameState(
                scenario: breakthroughAssaultScenario(),
                commandPoints: [.allies: 6, .axis: 6]
            )
            guard let breakthroughTank = breakthroughGame.units.first(where: { $0.name == "突击装甲" }),
                  let breakthroughInfantry = breakthroughGame.units.first(where: { $0.name == "普通步兵" }),
                  let breakthroughTarget = breakthroughGame.units.first(where: { $0.name == "突破目标" }),
                  let normalBreakthroughPreview = breakthroughGame.combatPreview(attacker: breakthroughTank, defender: breakthroughTarget),
                  let breakthroughPreview = breakthroughGame.tacticalCommandPreview(command: .breakthroughAssault, caster: breakthroughTank, target: breakthroughTarget) else {
                require(false, "breakthrough assault test units should exist")
                return
            }
            require(breakthroughPreview.command == .breakthroughAssault, "breakthrough preview should identify the command")
            require(breakthroughPreview.commandCost == TacticalCommand.breakthroughAssault.commandCost, "breakthrough preview should expose command cost")
            require(breakthroughPreview.range == TacticalCommand.breakthroughAssault.range, "breakthrough preview should expose command range")
            require(breakthroughPreview.damage > normalBreakthroughPreview.damage, "breakthrough assault should hit harder than a normal attack")
            require(breakthroughGame.tacticalCommandTargets(for: breakthroughTank, command: .breakthroughAssault).count == 1, "breakthrough assault should find adjacent targets")
            require(breakthroughGame.canUseTacticalCommand(.breakthroughAssault, with: breakthroughTank), "tanks should be able to use breakthrough assault")
            require(!breakthroughGame.canUseTacticalCommand(.breakthroughAssault, with: breakthroughInfantry), "infantry should not use breakthrough assault")
            breakthroughGame.useTacticalCommand(.breakthroughAssault, casterID: breakthroughTank.id, targetID: breakthroughTarget.id)
            guard let breakthroughTankAfter = breakthroughGame.units.first(where: { $0.id == breakthroughTank.id }),
                  let breakthroughTargetAfter = breakthroughGame.units.first(where: { $0.id == breakthroughTarget.id }) else {
                require(false, "breakthrough units should survive the tactical command test")
                return
            }
            require(breakthroughGame.commandPoints(for: .allies) == 6 - TacticalCommand.breakthroughAssault.commandCost, "breakthrough assault should spend command points")
            require(breakthroughTargetAfter.hp == breakthroughTarget.hp - breakthroughPreview.damage, "breakthrough assault should apply previewed damage")
            require(breakthroughTargetAfter.morale == breakthroughTarget.morale - TacticalCommand.breakthroughAssault.moraleDamage, "breakthrough assault should suppress morale")
            require(breakthroughTankAfter.hp == breakthroughTank.hp, "breakthrough assault should not trigger counterattack damage")
            require(breakthroughTankAfter.hasMoved && breakthroughTankAfter.hasAttacked, "breakthrough assault should spend the unit action")
            require(breakthroughGame.battleLog.contains { $0.contains("突破突击") }, "breakthrough assault should be logged")
            guard let breakthroughSummary = breakthroughGame.latestTacticalCommandResult else {
                require(false, "breakthrough assault should publish tactical command result summary")
                return
            }
            require(breakthroughSummary.command == .breakthroughAssault, "breakthrough summary should identify command")
            require(breakthroughSummary.caster.unitID == breakthroughTank.id, "breakthrough summary should identify caster")
            require(breakthroughSummary.target.unitID == breakthroughTarget.id, "breakthrough summary should identify target")
            require(breakthroughSummary.damage == breakthroughPreview.damage, "breakthrough summary should record damage")
            require(breakthroughSummary.commandCost == TacticalCommand.breakthroughAssault.commandCost, "breakthrough summary should record command cost")
            require(breakthroughSummary.statusEffect == .disrupted, "breakthrough summary should record disruption")
            require(breakthroughSummary.didAvoidCounterAttack, "breakthrough summary should record no counterattack")

            var lethalBreakthroughScenario = breakthroughAssaultScenario()
            if let lethalTargetIndex = lethalBreakthroughScenario.units.firstIndex(where: { $0.name == "突破目标" }) {
                lethalBreakthroughScenario.units[lethalTargetIndex].hp = 12
            }
            let lethalBreakthroughGame = GameState(
                scenario: lethalBreakthroughScenario,
                commandPoints: [.allies: 6, .axis: 6]
            )
            guard let lethalBreakthroughTank = lethalBreakthroughGame.units.first(where: { $0.name == "突击装甲" }),
                  let lethalBreakthroughTarget = lethalBreakthroughGame.units.first(where: { $0.name == "突破目标" }),
                  let lethalBreakthroughPreview = lethalBreakthroughGame.tacticalCommandPreview(command: .breakthroughAssault, caster: lethalBreakthroughTank, target: lethalBreakthroughTarget) else {
                require(false, "lethal breakthrough units should exist")
                return
            }
            require(lethalBreakthroughPreview.willDestroyTarget, "lethal breakthrough preview should mark target destruction")
            lethalBreakthroughGame.useTacticalCommand(.breakthroughAssault, casterID: lethalBreakthroughTank.id, targetID: lethalBreakthroughTarget.id)
            guard let lethalBreakthroughSummary = lethalBreakthroughGame.latestTacticalCommandResult,
                  let lethalBreakthroughTargetAfter = lethalBreakthroughGame.scenario.units.first(where: { $0.id == lethalBreakthroughTarget.id }) else {
                require(false, "lethal breakthrough should publish tactical command result summary")
                return
            }
            require(lethalBreakthroughSummary.didDestroyTarget, "lethal breakthrough summary should record destroyed target")
            require(lethalBreakthroughSummary.target.endingHP == 0, "lethal breakthrough summary should record zero target HP")
            require(lethalBreakthroughTargetAfter.hp == 0, "lethal breakthrough should reduce target HP to zero")
            require(lethalBreakthroughSummary.moraleDamage == 0, "lethal breakthrough summary should not report morale damage against destroyed target")
            require(lethalBreakthroughSummary.statusEffect == .normal, "lethal breakthrough summary should not report status effect against destroyed target")
            require(!lethalBreakthroughSummary.didApplyStatusEffect, "lethal breakthrough summary should not apply status effect")
            require(lethalBreakthroughGame.battleLog.contains { $0.contains("突破突击") && $0.contains("击毁") }, "lethal breakthrough log should mention destroyed target")

            let pursuitGame = GameState(
                scenario: maneuverPursuitScenario(attackerKind: .tank),
                commandPoints: [.allies: 6, .axis: 6]
            )
            guard let pursuitTank = pursuitGame.units.first(where: { $0.name == "追击装甲" }),
                  let pursuitTarget = pursuitGame.units.first(where: { $0.name == "追击目标" }) else {
                require(false, "maneuver pursuit units should exist")
                return
            }
            let pursuitObjective = HexCoordinate(q: 3, r: 0)
            require(pursuitGame.canUseManeuverPursuit(afterDestroyingWith: pursuitTank), "tanks should be eligible for maneuver pursuit before moving")
            require(pursuitGame.maneuverPursuitSummary.contains("坦克"), "maneuver pursuit summary should describe eligible units")
            pursuitGame.handleTap(on: pursuitTank.position)
            pursuitGame.handleTap(on: pursuitTarget.position)
            guard let pursuitTankAfterKill = pursuitGame.units.first(where: { $0.id == pursuitTank.id }) else {
                require(false, "pursuit tank should survive after kill")
                return
            }
            require(pursuitTankAfterKill.hasAttacked && !pursuitTankAfterKill.hasMoved, "mobile units should keep movement after destroying a target")
            require(pursuitGame.selectedUnit?.id == pursuitTank.id, "pursuit unit should remain selected")
            require(pursuitGame.reachableTiles(for: pursuitTankAfterKill).contains(pursuitObjective), "pursuit unit should be able to move after kill")
            require(pursuitGame.attackCoverageTiles(for: pursuitTankAfterKill).isEmpty, "pursuit should hide attack coverage after spending attack")
            require(pursuitGame.attackableTiles(for: pursuitTankAfterKill).isEmpty, "pursuit should not restore attack")
            require(pursuitGame.battleLog.contains { $0.contains("可继续机动") }, "maneuver pursuit should be logged")
            pursuitGame.handleTap(on: pursuitObjective)
            guard let pursuitTankAfterMove = pursuitGame.units.first(where: { $0.id == pursuitTank.id }) else {
                require(false, "pursuit tank should survive after moving")
                return
            }
            require(pursuitTankAfterMove.position == pursuitObjective, "pursuit unit should move after destroying target")
            require(pursuitTankAfterMove.hasMoved && pursuitTankAfterMove.hasAttacked, "pursuit movement should spend remaining movement only")
            require(pursuitGame.tile(at: pursuitObjective)?.owner == .allies, "pursuit movement should capture objectives")

            let infantryPursuitGame = GameState(
                scenario: maneuverPursuitScenario(attackerKind: .infantry),
                commandPoints: [.allies: 6, .axis: 6]
            )
            guard let pursuitInfantry = infantryPursuitGame.units.first(where: { $0.name == "追击步兵" }),
                  let infantryPursuitTarget = infantryPursuitGame.units.first(where: { $0.name == "追击目标" }) else {
                require(false, "infantry pursuit test units should exist")
                return
            }
            require(!infantryPursuitGame.canUseManeuverPursuit(afterDestroyingWith: pursuitInfantry), "infantry should not be eligible for maneuver pursuit")
            infantryPursuitGame.handleTap(on: pursuitInfantry.position)
            infantryPursuitGame.handleTap(on: infantryPursuitTarget.position)
            guard let pursuitInfantryAfterKill = infantryPursuitGame.units.first(where: { $0.id == pursuitInfantry.id }) else {
                require(false, "pursuit infantry should survive after kill")
                return
            }
            require(pursuitInfantryAfterKill.hasMoved && pursuitInfantryAfterKill.hasAttacked, "infantry kills should spend the full action")
            require(!infantryPursuitGame.battleLog.contains { $0.contains("可继续机动") }, "infantry kills should not log maneuver pursuit")

            let axisCommandGame = GameState(
                scenario: axisTacticalCommandScenario(),
                commandPoints: [.allies: 6, .axis: 8]
            )
            guard let axisCommandTarget = axisCommandGame.units.first(where: { $0.name == "盟军指挥坦克" }),
                  let axisCommandArtillery = axisCommandGame.units.first(where: { $0.name == "轴心炮兵" }) else {
                require(false, "axis tactical command units should exist")
                return
            }
            axisCommandGame.endTurn()
            if axisCommandGame.winner == nil {
                guard let axisCommandTargetAfter = axisCommandGame.units.first(where: { $0.id == axisCommandTarget.id }),
                      let axisCommandArtilleryAfter = axisCommandGame.units.first(where: { $0.id == axisCommandArtillery.id }) else {
                    require(false, "axis tactical command units should survive AI turn")
                    return
                }
                require(axisCommandTargetAfter.hp < axisCommandTarget.hp, "axis AI barrage should damage valuable target")
                require(axisCommandTargetAfter.morale < axisCommandTarget.morale, "axis AI barrage should suppress target morale")
                require(axisCommandArtilleryAfter.hp == axisCommandArtillery.hp, "axis AI barrage should not take counterattack damage")
                require(axisCommandArtilleryAfter.hasMoved && axisCommandArtilleryAfter.hasAttacked, "axis AI barrage should spend artillery action")
                require(
                    axisCommandGame.commandPoints(for: .axis) < 8 + axisCommandGame.commandIncome(for: .axis),
                    "axis AI barrage should spend command points"
                )
                require(axisCommandGame.battleLog.contains { $0.contains("火炮弹幕") }, "axis AI barrage should be logged")
                guard let axisCommandSummary = axisCommandGame.latestTacticalCommandResult else {
                    require(false, "axis AI barrage should publish tactical command result summary")
                    return
                }
                require(axisCommandSummary.command == .artilleryBarrage, "axis AI summary should identify barrage")
                require(axisCommandSummary.caster.unitID == axisCommandArtillery.id, "axis AI summary should identify caster")
                require(axisCommandSummary.target.unitID == axisCommandTarget.id, "axis AI summary should identify target")
                require(axisCommandSummary.caster.faction == .axis, "axis AI summary should record caster faction")
                guard let axisCommandPhaseSummary = axisCommandGame.latestAIPhaseSummary else {
                    require(false, "axis tactical command turn should publish AI phase summary")
                    return
                }
                require(axisCommandPhaseSummary.faction == .axis, "AI phase summary should record axis faction")
                require(axisCommandPhaseSummary.tacticalCommands >= 1, "AI phase summary should count tactical commands")
                require(axisCommandPhaseSummary.damageDealt == axisCommandTarget.hp - axisCommandTargetAfter.hp, "AI phase summary should record tactical command damage")
                requireSequentialTimelineOrders(axisCommandPhaseSummary.timeline, "axis command timeline should use sequential orders")
                guard let axisCommandEvent = axisCommandPhaseSummary.timeline.first(where: { $0.kind == .tacticalCommand }) else {
                    require(false, "axis command timeline should include tactical command event")
                    return
                }
                require(axisCommandEvent.actorName == "轴心炮兵", "axis command timeline should identify actor")
                require(axisCommandEvent.targetName == "盟军指挥坦克", "axis command timeline should identify target")
                require(axisCommandEvent.damage == axisCommandSummary.damage, "axis command timeline should match result damage")
                require(axisCommandEvent.commandPointCost == TacticalCommand.artilleryBarrage.commandCost, "axis command timeline should record command cost")
                require(axisCommandEvent.from == HexCoordinate(q: 4, r: 0), "axis command timeline should record caster coordinate")
                require(axisCommandEvent.to == HexCoordinate(q: 1, r: 0), "axis command timeline should record target coordinate")
                let axisCommandMarkers = axisCommandGame.latestAIPhaseMapMarkers
                requireAIPhaseMapMarkersMatchSummary(axisCommandMarkers, axisCommandPhaseSummary, "axis command map replay markers")
                requireAIPhaseMapMarker(
                    axisCommandMarkers,
                    kind: .tacticalCommand,
                    role: .actor,
                    coordinate: HexCoordinate(q: 4, r: 0),
                    order: axisCommandEvent.order,
                    "axis command map replay should mark caster"
                )
                requireAIPhaseMapMarker(
                    axisCommandMarkers,
                    kind: .tacticalCommand,
                    role: .target,
                    coordinate: HexCoordinate(q: 1, r: 0),
                    order: axisCommandEvent.order,
                    "axis command map replay should mark target"
                )
            }

            let axisDeploymentPhaseGame = GameState(
                scenario: axisDeploymentResultScenario(),
                commandPoints: [.allies: 6, .axis: 1]
            )
            axisDeploymentPhaseGame.endTurn()
            guard let axisDeploymentPhaseSummary = axisDeploymentPhaseGame.latestAIPhaseSummary else {
                require(false, "axis deployment turn should publish AI phase summary")
                return
            }
            require(axisDeploymentPhaseSummary.faction == .axis, "deployment AI phase summary should record axis faction")
            require(axisDeploymentPhaseSummary.deployments == 1, "deployment AI phase summary should count deployments")
            require(axisDeploymentPhaseSummary.reinforcements == 0, "deployment AI phase summary should not count passive rest as reinforcement")
            require(axisDeploymentPhaseSummary.startingCommandPoints == 6, "deployment AI phase summary should record post-income command points")
            require(axisDeploymentPhaseSummary.endingCommandPoints == axisDeploymentPhaseGame.commandPoints(for: .axis), "deployment AI phase summary should record ending command points")
            require(axisDeploymentPhaseSummary.damageDealt == 0, "deployment-only AI phase should not record damage")
            let axisDeploymentConclusion = axisDeploymentPhaseSummary.replayConclusion
            require(axisDeploymentConclusion.kind == .logistics, "deployment AI phase conclusion should classify as logistics")
            require(axisDeploymentConclusion.metrics.contains { $0.kind == .logistics }, "deployment AI phase conclusion should include logistics metric")
            require(axisDeploymentConclusion.metrics.contains { $0.kind == .command }, "deployment AI phase conclusion should include command metric")
            require(axisDeploymentConclusion.keyEvents.contains { $0.kind == .deployment }, "deployment AI phase conclusion should include deployment key event")
            requireSequentialTimelineOrders(axisDeploymentPhaseSummary.timeline, "axis deployment timeline should use sequential orders")
            guard let axisDeploymentEvent = axisDeploymentPhaseSummary.timeline.first(where: { $0.kind == .deployment }) else {
                require(false, "axis deployment timeline should include deployment event")
                return
            }
            require(axisDeploymentEvent.deployedUnitKind != nil, "axis deployment timeline should record deployed kind")
            require(axisDeploymentEvent.to != nil, "axis deployment timeline should record destination")
            require(axisDeploymentEvent.commandPointCost > 0, "axis deployment timeline should record command point cost")
            require(axisDeploymentEvent.commandPointsAfter == axisDeploymentPhaseGame.commandPoints(for: .axis), "axis deployment timeline should record ending command points")
            let axisDeploymentMarkers = axisDeploymentPhaseGame.latestAIPhaseMapMarkers
            requireAIPhaseMapMarkersMatchSummary(axisDeploymentMarkers, axisDeploymentPhaseSummary, "axis deployment map replay markers")
            if let axisDeploymentCoordinate = axisDeploymentEvent.to {
                requireAIPhaseMapMarker(
                    axisDeploymentMarkers,
                    kind: .deployment,
                    role: .destination,
                    coordinate: axisDeploymentCoordinate,
                    order: axisDeploymentEvent.order,
                    "axis deployment map replay should mark deployment destination"
                )
            }

            let axisReinforcementPhaseGame = GameState(
                scenario: axisReinforcementResultScenario(),
                commandPoints: [.allies: 6, .axis: 0]
            )
            axisReinforcementPhaseGame.endTurn()
            guard let axisReinforcementPhaseSummary = axisReinforcementPhaseGame.latestAIPhaseSummary else {
                require(false, "axis reinforcement turn should publish AI phase summary")
                return
            }
            require(axisReinforcementPhaseSummary.faction == .axis, "reinforcement AI phase summary should record axis faction")
            require(axisReinforcementPhaseSummary.reinforcements == 1, "reinforcement AI phase summary should count one active reinforcement")
            require(axisReinforcementPhaseSummary.deployments == 0, "reinforcement AI phase summary should not count blocked deployment")
            require(axisReinforcementPhaseSummary.damageDealt == 0, "reinforcement-only AI phase should not record damage dealt")
            require(axisReinforcementPhaseSummary.damageTaken == 0, "reinforcement-only AI phase should not record damage taken")
            let axisReinforcementConclusion = axisReinforcementPhaseSummary.replayConclusion
            require(axisReinforcementConclusion.kind == .logistics, "reinforcement AI phase conclusion should classify as logistics")
            require(axisReinforcementConclusion.metrics.contains { $0.kind == .logistics }, "reinforcement AI phase conclusion should include logistics metric")
            require(axisReinforcementConclusion.metrics.contains { $0.kind == .command }, "reinforcement AI phase conclusion should include command metric")
            require(axisReinforcementConclusion.keyEvents.contains { $0.kind == .reinforcement }, "reinforcement AI phase conclusion should include reinforcement key event")
            requireSequentialTimelineOrders(axisReinforcementPhaseSummary.timeline, "axis reinforcement timeline should use sequential orders")
            guard let axisReinforcementEvent = axisReinforcementPhaseSummary.timeline.first(where: { $0.kind == .reinforcement }) else {
                require(false, "axis reinforcement timeline should include reinforcement event")
                return
            }
            require(axisReinforcementEvent.actorName == "受损轴心守军", "axis reinforcement timeline should identify unit")
            require(axisReinforcementEvent.recoveredHP > 0, "axis reinforcement timeline should record recovery")
            require(axisReinforcementEvent.commandPointCost > 0, "axis reinforcement timeline should record command point cost")
            let axisReinforcementMarkers = axisReinforcementPhaseGame.latestAIPhaseMapMarkers
            requireAIPhaseMapMarkersMatchSummary(axisReinforcementMarkers, axisReinforcementPhaseSummary, "axis reinforcement map replay markers")
            requireAIPhaseMapMarker(
                axisReinforcementMarkers,
                kind: .reinforcement,
                role: .destination,
                coordinate: HexCoordinate(q: 0, r: 0),
                order: axisReinforcementEvent.order,
                "axis reinforcement map replay should mark reinforcement coordinate"
            )

            let axisAdvanceGame = GameState(
                scenario: axisFullAdvanceScenario(),
                commandPoints: [.allies: 6, .axis: 0]
            )
            guard let advanceTarget = axisAdvanceGame.units.first(where: { $0.name == "远端步兵" }),
                  let advanceRecon = axisAdvanceGame.units.first(where: { $0.name == "突进侦察" }) else {
                require(false, "axis advance test units should exist")
                return
            }
            axisAdvanceGame.endTurn()
            if axisAdvanceGame.winner == nil {
                guard let advanceTargetAfter = axisAdvanceGame.units.first(where: { $0.id == advanceTarget.id }),
                      let advanceReconAfter = axisAdvanceGame.units.first(where: { $0.id == advanceRecon.id }) else {
                    require(false, "axis advance units should survive AI turn")
                    return
                }
                require(advanceReconAfter.position == HexCoordinate(q: 1, r: 0), "axis AI should use full movement to reach attack position")
                require(advanceTargetAfter.hp < advanceTarget.hp, "axis AI should attack after full advance")
                require(advanceReconAfter.hasMoved && advanceReconAfter.hasAttacked, "axis AI full advance should spend movement and attack")
                guard let axisAdvanceCombatSummary = axisAdvanceGame.latestCombatResult else {
                    require(false, "axis advance turn should publish combat result summary")
                    return
                }
                guard let axisAdvancePhaseSummary = axisAdvanceGame.latestAIPhaseSummary else {
                    require(false, "axis advance turn should publish AI phase summary")
                    return
                }
                require(axisAdvancePhaseSummary.moves == 1, "AI phase summary should count full advance movement")
                require(axisAdvancePhaseSummary.attacks == 1, "AI phase summary should count post-move attack")
                require(
                    axisAdvancePhaseSummary.damageDealt == axisAdvanceCombatSummary.damage,
                    "AI phase summary should record move-attack damage: expected \(axisAdvanceCombatSummary.damage), got \(axisAdvancePhaseSummary.damageDealt)"
                )
                require(advanceTarget.hp - advanceTargetAfter.hp >= axisAdvancePhaseSummary.damageDealt, "AI phase damage should not exceed final target HP loss")
                requireSequentialTimelineOrders(axisAdvancePhaseSummary.timeline, "axis advance timeline should use sequential orders")
                require(axisAdvancePhaseSummary.timeline.count >= 2, "axis advance timeline should include move and attack")
                require(axisAdvancePhaseSummary.timeline[0].kind == .move, "axis advance timeline should record move before attack")
                require(axisAdvancePhaseSummary.timeline[0].from == HexCoordinate(q: 4, r: 0), "axis advance timeline should record move origin")
                require(axisAdvancePhaseSummary.timeline[0].to == HexCoordinate(q: 1, r: 0), "axis advance timeline should record move destination")
                require(axisAdvancePhaseSummary.timeline[1].kind == .attack, "axis advance timeline should record attack second")
                require(axisAdvancePhaseSummary.timeline[1].damage == axisAdvanceCombatSummary.damage, "axis advance timeline should match combat damage")
                let axisAdvanceMarkers = axisAdvanceGame.latestAIPhaseMapMarkers
                requireAIPhaseMapMarkersMatchSummary(axisAdvanceMarkers, axisAdvancePhaseSummary, "axis advance map replay markers")
                requireAIPhaseMapMarker(
                    axisAdvanceMarkers,
                    kind: .move,
                    role: .origin,
                    coordinate: HexCoordinate(q: 4, r: 0),
                    order: axisAdvancePhaseSummary.timeline[0].order,
                    "axis advance map replay should mark move origin"
                )
                requireAIPhaseMapMarker(
                    axisAdvanceMarkers,
                    kind: .move,
                    role: .destination,
                    coordinate: HexCoordinate(q: 1, r: 0),
                    order: axisAdvancePhaseSummary.timeline[0].order,
                    "axis advance map replay should mark move destination"
                )
                requireAIPhaseMapMarker(
                    axisAdvanceMarkers,
                    kind: .attack,
                    role: .target,
                    coordinate: HexCoordinate(q: 0, r: 0),
                    order: axisAdvancePhaseSummary.timeline[1].order,
                    "axis advance map replay should mark attack target"
                )
            }

            let axisPostMoveBarrageGame = GameState(
                scenario: axisPostMoveBarrageScenario(),
                commandPoints: [.allies: 6, .axis: 1]
            )
            guard let axisPostMoveBarrageTarget = axisPostMoveBarrageGame.units.first(where: { $0.name == "远距指挥坦克" }),
                  let axisPostMoveArtillery = axisPostMoveBarrageGame.units.first(where: { $0.name == "机动轴心炮兵" }) else {
                require(false, "axis post-move barrage test units should exist")
                return
            }
            let axisPostMoveBarragePosition = HexCoordinate(q: 4, r: 0)
            require(
                !axisPostMoveBarrageGame.attackableTiles(for: axisPostMoveArtillery).contains(axisPostMoveBarrageTarget.position),
                "axis post-move barrage target should start outside ordinary artillery range"
            )
            require(
                axisPostMoveBarrageGame.tacticalCommandTargets(for: axisPostMoveArtillery, command: .artilleryBarrage).isEmpty,
                "axis post-move barrage target should start outside barrage range before AI moves"
            )
            axisPostMoveBarrageGame.endTurn()
            if axisPostMoveBarrageGame.winner == nil {
                guard let axisPostMoveBarrageTargetAfterAI = axisPostMoveBarrageGame.units.first(where: { $0.id == axisPostMoveBarrageTarget.id }),
                      let axisPostMoveArtilleryAfterAI = axisPostMoveBarrageGame.units.first(where: { $0.id == axisPostMoveArtillery.id }) else {
                    require(false, "axis post-move barrage units should survive AI turn")
                    return
                }
                require(axisPostMoveArtilleryAfterAI.position == axisPostMoveBarragePosition, "axis artillery should move into barrage range")
                require(axisPostMoveBarrageTargetAfterAI.hp < axisPostMoveBarrageTarget.hp, "axis post-move barrage should damage target")
                require(axisPostMoveBarrageTargetAfterAI.morale < axisPostMoveBarrageTarget.morale, "axis post-move barrage should suppress target morale")
                require(axisPostMoveArtilleryAfterAI.hasMoved && axisPostMoveArtilleryAfterAI.hasAttacked, "post-move barrage should spend artillery action")
                guard let axisPostMoveBarrageCommandSummary = axisPostMoveBarrageGame.latestTacticalCommandResult else {
                    require(false, "axis post-move barrage should publish tactical command result")
                    return
                }
                require(axisPostMoveBarrageCommandSummary.command == .artilleryBarrage, "axis post-move command should be artillery barrage")
                require(axisPostMoveBarrageCommandSummary.caster.unitID == axisPostMoveArtillery.id, "axis post-move barrage should bind caster")
                require(axisPostMoveBarrageCommandSummary.target.unitID == axisPostMoveBarrageTarget.id, "axis post-move barrage should bind target")
                require(axisPostMoveBarrageCommandSummary.didAvoidCounterAttack, "axis post-move barrage should avoid counterattack")
                require(axisPostMoveBarrageGame.latestCombatResult == nil, "axis post-move barrage should not publish ordinary combat result")
                guard let axisPostMoveBarragePhaseSummary = axisPostMoveBarrageGame.latestAIPhaseSummary else {
                    require(false, "axis post-move barrage turn should publish AI phase summary")
                    return
                }
                require(axisPostMoveBarragePhaseSummary.moves == 1, "axis post-move barrage summary should count one move")
                require(axisPostMoveBarragePhaseSummary.tacticalCommands == 1, "axis post-move barrage summary should count one tactical command")
                require(axisPostMoveBarragePhaseSummary.attacks == 0, "axis post-move barrage summary should not count ordinary attacks")
                require(axisPostMoveBarragePhaseSummary.damageDealt == axisPostMoveBarrageCommandSummary.damage, "axis post-move barrage summary should record command damage")
                require(axisPostMoveBarragePhaseSummary.startingCommandPoints == TacticalCommand.artilleryBarrage.commandCost, "axis post-move barrage should start AI phase with barrage cost")
                require(axisPostMoveBarragePhaseSummary.endingCommandPoints == 0, "axis post-move barrage should spend all available command points")
                let axisPostMoveBarrageConclusion = axisPostMoveBarragePhaseSummary.replayConclusion
                require(axisPostMoveBarrageConclusion.kind == .fireSuppression, "axis post-move barrage conclusion should classify as fire suppression")
                require(axisPostMoveBarrageConclusion.metrics.contains { $0.kind == .damage }, "axis post-move barrage conclusion should include damage metric")
                require(axisPostMoveBarrageConclusion.metrics.contains { $0.kind == .command }, "axis post-move barrage conclusion should include command metric")
                require(axisPostMoveBarrageConclusion.keyEvents.contains { $0.kind == .tacticalCommand }, "axis post-move barrage conclusion should include tactical key event")
                requireSequentialTimelineOrders(axisPostMoveBarragePhaseSummary.timeline, "axis post-move barrage timeline should use sequential orders")
                require(axisPostMoveBarragePhaseSummary.timeline.count >= 2, "axis post-move barrage timeline should include move and tactical command")
                require(axisPostMoveBarragePhaseSummary.timeline[0].kind == .move, "axis post-move barrage timeline should record move first")
                require(axisPostMoveBarragePhaseSummary.timeline[0].from == HexCoordinate(q: 5, r: 0), "axis post-move barrage timeline should record move origin")
                require(axisPostMoveBarragePhaseSummary.timeline[0].to == axisPostMoveBarragePosition, "axis post-move barrage timeline should record move destination")
                require(axisPostMoveBarragePhaseSummary.timeline[1].kind == .tacticalCommand, "axis post-move barrage timeline should record tactical command second")
                require(axisPostMoveBarragePhaseSummary.timeline[1].tacticalCommand == .artilleryBarrage, "axis post-move barrage timeline should identify barrage")
                require(axisPostMoveBarragePhaseSummary.timeline[1].from == axisPostMoveBarragePosition, "axis post-move barrage timeline should record caster coordinate")
                require(axisPostMoveBarragePhaseSummary.timeline[1].to == axisPostMoveBarrageTarget.position, "axis post-move barrage timeline should record target coordinate")
                let axisPostMoveBarrageMarkers = axisPostMoveBarrageGame.latestAIPhaseMapMarkers
                requireAIPhaseMapMarkersMatchSummary(axisPostMoveBarrageMarkers, axisPostMoveBarragePhaseSummary, "axis post-move barrage map replay markers")
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == nil,
                    "axis post-move barrage should start without focused replay event"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseMapMarkers.isEmpty,
                    "axis post-move barrage should start without focused replay markers"
                )
                requireAIPhaseMapMarker(
                    axisPostMoveBarrageMarkers,
                    kind: .move,
                    role: .destination,
                    coordinate: axisPostMoveBarragePosition,
                    order: axisPostMoveBarragePhaseSummary.timeline[0].order,
                    "axis post-move barrage map replay should mark move destination"
                )
                requireAIPhaseMapMarker(
                    axisPostMoveBarrageMarkers,
                    kind: .tacticalCommand,
                    role: .actor,
                    coordinate: axisPostMoveBarragePosition,
                    order: axisPostMoveBarragePhaseSummary.timeline[1].order,
                    "axis post-move barrage map replay should mark caster"
                )
                requireAIPhaseMapMarker(
                    axisPostMoveBarrageMarkers,
                    kind: .tacticalCommand,
                    role: .target,
                    coordinate: axisPostMoveBarrageTarget.position,
                    order: axisPostMoveBarragePhaseSummary.timeline[1].order,
                    "axis post-move barrage map replay should mark target"
                )
                let axisPostMoveBarrageUnitsBeforeReplayFocus = axisPostMoveBarrageGame.scenario.units
                let axisPostMoveBarrageCommandPointsBeforeReplayFocus = axisPostMoveBarrageGame.commandPoints
                let axisPostMoveBarrageFirstEvent = axisPostMoveBarragePhaseSummary.timeline[0]
                let axisPostMoveBarrageReplayEvent = axisPostMoveBarragePhaseSummary.timeline[1]
                guard let axisPostMoveBarrageLastEvent = axisPostMoveBarragePhaseSummary.timeline.last else {
                    require(false, "axis post-move barrage timeline should have a last event")
                    return
                }
                guard let axisPostMoveBarrageFirstCoordinate = axisPostMoveBarrageFirstEvent.to ?? axisPostMoveBarrageFirstEvent.from else {
                    require(false, "axis post-move barrage first replay event should have focus coordinate")
                    return
                }
                guard let axisPostMoveBarrageReplayCoordinate = axisPostMoveBarrageReplayEvent.to ?? axisPostMoveBarrageReplayEvent.from else {
                    require(false, "axis post-move barrage replay event should have focus coordinate")
                    return
                }
                guard let axisPostMoveBarrageLastCoordinate = axisPostMoveBarrageLastEvent.to ?? axisPostMoveBarrageLastEvent.from else {
                    require(false, "axis post-move barrage last replay event should have focus coordinate")
                    return
                }
                require(
                    axisPostMoveBarrageGame.canFocusPreviousAIPhaseTimelineEvent,
                    "axis post-move barrage should allow previous replay navigation before an event is focused"
                )
                require(
                    axisPostMoveBarrageGame.canFocusNextAIPhaseTimelineEvent,
                    "axis post-move barrage should allow next replay navigation before an event is focused"
                )
                axisPostMoveBarrageGame.focusNextAIPhaseTimelineEvent()
                require(
                    axisPostMoveBarrageGame.focusedCoordinate == axisPostMoveBarrageFirstCoordinate,
                    "axis post-move barrage next replay navigation should start at first event"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageFirstEvent.order,
                    "axis post-move barrage next replay navigation should record first event order"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseMapMarkers == axisPostMoveBarrageMarkers.filter { $0.eventOrder == axisPostMoveBarrageFirstEvent.order },
                    "axis post-move barrage next replay markers should derive from latest map markers"
                )
                require(
                    !axisPostMoveBarrageGame.canFocusPreviousAIPhaseTimelineEvent,
                    "axis post-move barrage first replay event should disable previous navigation"
                )
                axisPostMoveBarrageGame.focusPreviousAIPhaseTimelineEvent()
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageFirstEvent.order,
                    "axis post-move barrage previous replay boundary should preserve first event order"
                )
                require(
                    axisPostMoveBarrageGame.message.contains("已经是第一条AI复盘事件"),
                    "axis post-move barrage previous replay boundary should publish clear message"
                )
                axisPostMoveBarrageGame.focusAIPhaseTimelineEvent(order: axisPostMoveBarrageReplayEvent.order)
                require(
                    axisPostMoveBarrageGame.focusedCoordinate == axisPostMoveBarrageReplayCoordinate,
                    "axis post-move barrage replay focus should use event destination"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageReplayEvent.order,
                    "axis post-move barrage replay focus should record focused event order"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseMapMarkers == axisPostMoveBarrageMarkers.filter { $0.eventOrder == axisPostMoveBarrageReplayEvent.order },
                    "axis post-move barrage replay focus markers should derive from latest map markers"
                )
                require(
                    axisPostMoveBarrageGame.message.contains("AI复盘 #\(axisPostMoveBarrageReplayEvent.order)"),
                    "axis post-move barrage replay focus message should identify event order"
                )
                require(
                    axisPostMoveBarrageGame.message.contains(axisPostMoveBarrageReplayEvent.summary),
                    "axis post-move barrage replay focus message should include event summary"
                )
                require(
                    axisPostMoveBarrageGame.scenario.units == axisPostMoveBarrageUnitsBeforeReplayFocus,
                    "axis post-move barrage replay focus should not mutate units"
                )
                require(
                    axisPostMoveBarrageGame.commandPoints == axisPostMoveBarrageCommandPointsBeforeReplayFocus,
                    "axis post-move barrage replay focus should not mutate command points"
                )
                guard let axisPostMoveBarrageSummaryAfterReplayFocus = axisPostMoveBarrageGame.latestAIPhaseSummary else {
                    require(false, "axis post-move barrage replay focus should preserve AI phase summary")
                    return
                }
                require(
                    axisPostMoveBarrageSummaryAfterReplayFocus == axisPostMoveBarragePhaseSummary,
                    "axis post-move barrage replay focus should not mutate AI phase summary"
                )
                require(
                    axisPostMoveBarrageGame.latestAIPhaseMapMarkers == axisPostMoveBarrageMarkers,
                    "axis post-move barrage replay focus should not mutate map replay markers"
                )
                require(
                    axisPostMoveBarrageGame.canFocusPreviousAIPhaseTimelineEvent,
                    "axis post-move barrage focused tactical replay should allow previous navigation"
                )
                guard let axisPostMoveBarrageConclusionEvent = axisPostMoveBarrageConclusion.keyEvents.first,
                      let axisPostMoveBarrageConclusionTimelineEvent = axisPostMoveBarragePhaseSummary.timeline.first(where: { $0.order == axisPostMoveBarrageConclusionEvent.order }),
                      let axisPostMoveBarrageConclusionCoordinate = axisPostMoveBarrageConclusionTimelineEvent.to ?? axisPostMoveBarrageConclusionTimelineEvent.from else {
                    require(false, "axis post-move barrage conclusion should expose a focusable key event")
                    return
                }
                let axisPostMoveBarrageUnitsBeforeConclusionFocus = axisPostMoveBarrageGame.scenario.units
                let axisPostMoveBarrageCommandPointsBeforeConclusionFocus = axisPostMoveBarrageGame.commandPoints
                let axisPostMoveBarrageSummaryBeforeConclusionFocus = axisPostMoveBarrageGame.latestAIPhaseSummary
                let axisPostMoveBarrageMarkersBeforeConclusionFocus = axisPostMoveBarrageGame.latestAIPhaseMapMarkers
                let axisPostMoveBarragePlaybackBeforeConclusionFocus = axisPostMoveBarrageGame.isAIPhaseTimelinePlaybackActive
                axisPostMoveBarrageGame.focusAIPhaseTimelineEvent(order: axisPostMoveBarrageConclusionEvent.order)
                require(
                    axisPostMoveBarrageGame.focusedCoordinate == axisPostMoveBarrageConclusionCoordinate,
                    "axis post-move barrage conclusion key event should focus its replay coordinate"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageConclusionEvent.order,
                    "axis post-move barrage conclusion key event should record focused order"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseMapMarkers == axisPostMoveBarrageMarkers.filter { $0.eventOrder == axisPostMoveBarrageConclusionEvent.order },
                    "axis post-move barrage conclusion key event markers should derive from latest map markers"
                )
                require(
                    axisPostMoveBarrageGame.message.contains("AI复盘 #\(axisPostMoveBarrageConclusionEvent.order)") &&
                        axisPostMoveBarrageGame.message.contains(axisPostMoveBarrageConclusionTimelineEvent.summary),
                    "axis post-move barrage conclusion key event should publish replay focus message"
                )
                require(
                    axisPostMoveBarrageGame.scenario.units == axisPostMoveBarrageUnitsBeforeConclusionFocus,
                    "axis post-move barrage conclusion key event focus should not mutate units"
                )
                require(
                    axisPostMoveBarrageGame.commandPoints == axisPostMoveBarrageCommandPointsBeforeConclusionFocus,
                    "axis post-move barrage conclusion key event focus should not mutate command points"
                )
                require(
                    axisPostMoveBarrageGame.latestAIPhaseSummary == axisPostMoveBarrageSummaryBeforeConclusionFocus,
                    "axis post-move barrage conclusion key event focus should not mutate AI summary"
                )
                require(
                    axisPostMoveBarrageGame.latestAIPhaseMapMarkers == axisPostMoveBarrageMarkersBeforeConclusionFocus,
                    "axis post-move barrage conclusion key event focus should not mutate map replay markers"
                )
                require(
                    axisPostMoveBarrageGame.isAIPhaseTimelinePlaybackActive == axisPostMoveBarragePlaybackBeforeConclusionFocus,
                    "axis post-move barrage conclusion key event focus should preserve playback state"
                )
                axisPostMoveBarrageGame.focusAIPhaseTimelineEvent(order: axisPostMoveBarrageLastEvent.order)
                require(
                    axisPostMoveBarrageGame.focusedCoordinate == axisPostMoveBarrageLastCoordinate,
                    "axis post-move barrage replay focus should use last event coordinate"
                )
                require(
                    !axisPostMoveBarrageGame.canFocusNextAIPhaseTimelineEvent,
                    "axis post-move barrage last replay event should disable next navigation"
                )
                let axisPostMoveBarrageLastFocus = axisPostMoveBarrageGame.focusedCoordinate
                axisPostMoveBarrageGame.focusNextAIPhaseTimelineEvent()
                require(
                    axisPostMoveBarrageGame.focusedCoordinate == axisPostMoveBarrageLastFocus,
                    "axis post-move barrage next replay boundary should preserve focused coordinate"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageLastEvent.order,
                    "axis post-move barrage next replay boundary should preserve last event order"
                )
                require(
                    axisPostMoveBarrageGame.message.contains("已经是最后一条AI复盘事件"),
                    "axis post-move barrage next replay boundary should publish clear message"
                )
                axisPostMoveBarrageGame.focusPreviousAIPhaseTimelineEvent()
                let axisPostMoveBarrageExpectedPreviousEvent = axisPostMoveBarragePhaseSummary.timeline[
                    axisPostMoveBarragePhaseSummary.timeline.count - 2
                ]
                guard let axisPostMoveBarrageExpectedPreviousCoordinate = axisPostMoveBarrageExpectedPreviousEvent.to ?? axisPostMoveBarrageExpectedPreviousEvent.from else {
                    require(false, "axis post-move barrage previous replay event should have focus coordinate")
                    return
                }
                require(
                    axisPostMoveBarrageGame.focusedCoordinate == axisPostMoveBarrageExpectedPreviousCoordinate,
                    "axis post-move barrage previous replay navigation should move to adjacent event"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageExpectedPreviousEvent.order,
                    "axis post-move barrage previous replay navigation should record adjacent event order"
                )

                let axisPostMoveBarragePlaybackGame = GameState(
                    scenario: axisPostMoveBarrageScenario(),
                    commandPoints: [.allies: 6, .axis: 1]
                )
                axisPostMoveBarragePlaybackGame.endTurn()
                guard let axisPostMoveBarragePlaybackSummary = axisPostMoveBarragePlaybackGame.latestAIPhaseSummary,
                      let axisPostMoveBarragePlaybackFirstEvent = axisPostMoveBarragePlaybackSummary.timeline.first,
                      let axisPostMoveBarragePlaybackLastEvent = axisPostMoveBarragePlaybackSummary.timeline.last,
                      let axisPostMoveBarragePlaybackFirstCoordinate = axisPostMoveBarragePlaybackFirstEvent.to ?? axisPostMoveBarragePlaybackFirstEvent.from else {
                    require(false, "axis post-move barrage playback should publish replay events")
                    return
                }
                let axisPostMoveBarragePlaybackMarkers = axisPostMoveBarragePlaybackGame.latestAIPhaseMapMarkers
                let axisPostMoveBarragePlaybackUnitsBefore = axisPostMoveBarragePlaybackGame.scenario.units
                let axisPostMoveBarragePlaybackCommandPointsBefore = axisPostMoveBarragePlaybackGame.commandPoints
                require(
                    axisPostMoveBarragePlaybackGame.canPlayAIPhaseTimeline,
                    "axis post-move barrage playback should be playable before any event is focused"
                )
                axisPostMoveBarragePlaybackGame.setAIPhaseTimelinePlaybackPace(.fast)
                require(
                    axisPostMoveBarragePlaybackGame.aiPhaseTimelinePlaybackPace == .fast,
                    "axis post-move barrage playback pace should switch to fast"
                )
                require(
                    axisPostMoveBarragePlaybackGame.scenario.units == axisPostMoveBarragePlaybackUnitsBefore,
                    "axis post-move barrage pace switch should not mutate units"
                )
                axisPostMoveBarragePlaybackGame.toggleAIPhaseTimelinePlayback()
                require(
                    axisPostMoveBarragePlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "axis post-move barrage playback toggle should start playback"
                )
                axisPostMoveBarragePlaybackGame.advanceAIPhaseTimelinePlayback()
                require(
                    axisPostMoveBarragePlaybackGame.focusedCoordinate == axisPostMoveBarragePlaybackFirstCoordinate,
                    "axis post-move barrage playback first tick should focus first event"
                )
                require(
                    axisPostMoveBarragePlaybackGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarragePlaybackFirstEvent.order,
                    "axis post-move barrage playback first tick should record first order"
                )
                require(
                    axisPostMoveBarragePlaybackGame.focusedAIPhaseMapMarkers == axisPostMoveBarragePlaybackMarkers.filter { $0.eventOrder == axisPostMoveBarragePlaybackFirstEvent.order },
                    "axis post-move barrage playback markers should derive from current order"
                )
                var axisPostMoveBarragePlaybackGuard = axisPostMoveBarragePlaybackSummary.timeline.count + 2
                while axisPostMoveBarragePlaybackGame.isAIPhaseTimelinePlaybackActive && axisPostMoveBarragePlaybackGuard > 0 {
                    axisPostMoveBarragePlaybackGame.advanceAIPhaseTimelinePlayback()
                    axisPostMoveBarragePlaybackGuard -= 1
                }
                require(
                    !axisPostMoveBarragePlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "axis post-move barrage playback should auto-pause at the last event"
                )
                require(
                    axisPostMoveBarragePlaybackGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarragePlaybackLastEvent.order,
                    "axis post-move barrage playback should stop on last event order"
                )
                require(
                    axisPostMoveBarragePlaybackGame.message.contains("自动暂停"),
                    "axis post-move barrage playback should publish auto-pause message"
                )
                require(
                    !axisPostMoveBarragePlaybackGame.canPlayAIPhaseTimeline,
                    "axis post-move barrage playback should not be playable from last event"
                )
                require(
                    axisPostMoveBarragePlaybackGame.scenario.units == axisPostMoveBarragePlaybackUnitsBefore,
                    "axis post-move barrage playback should not mutate units"
                )
                require(
                    axisPostMoveBarragePlaybackGame.commandPoints == axisPostMoveBarragePlaybackCommandPointsBefore,
                    "axis post-move barrage playback should not mutate command points"
                )
                require(
                    axisPostMoveBarragePlaybackGame.latestAIPhaseSummary == axisPostMoveBarragePlaybackSummary,
                    "axis post-move barrage playback should not mutate summary"
                )
                require(
                    axisPostMoveBarragePlaybackGame.latestAIPhaseMapMarkers == axisPostMoveBarragePlaybackMarkers,
                    "axis post-move barrage playback should not mutate map markers"
                )
                axisPostMoveBarragePlaybackGame.toggleAIPhaseTimelinePlayback()
                require(
                    !axisPostMoveBarragePlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "axis post-move barrage playback should not restart from the last event"
                )
                require(
                    axisPostMoveBarragePlaybackGame.message.contains("最后一条"),
                    "axis post-move barrage playback last-event toggle should publish boundary message"
                )
                axisPostMoveBarragePlaybackGame.focusAIPhaseTimelineEvent(order: axisPostMoveBarragePlaybackFirstEvent.order)
                axisPostMoveBarragePlaybackGame.toggleAIPhaseTimelinePlayback()
                axisPostMoveBarragePlaybackGame.pauseAIPhaseTimelinePlayback()
                require(
                    !axisPostMoveBarragePlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "axis post-move barrage playback pause should stop active playback"
                )
                let axisPostMoveBarrageNoSummaryPlaybackGame = GameState(
                    scenario: axisPostMoveBarrageScenario(),
                    commandPoints: [.allies: 6, .axis: 1]
                )
                let axisPostMoveBarrageNoSummaryFocus = axisPostMoveBarrageNoSummaryPlaybackGame.focusedCoordinate
                let axisPostMoveBarrageNoSummaryUnits = axisPostMoveBarrageNoSummaryPlaybackGame.scenario.units
                axisPostMoveBarrageNoSummaryPlaybackGame.toggleAIPhaseTimelinePlayback()
                axisPostMoveBarrageNoSummaryPlaybackGame.advanceAIPhaseTimelinePlayback()
                require(
                    !axisPostMoveBarrageNoSummaryPlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "AI replay playback should stay paused without a published summary"
                )
                require(
                    axisPostMoveBarrageNoSummaryPlaybackGame.focusedCoordinate == axisPostMoveBarrageNoSummaryFocus,
                    "AI replay playback without summary should preserve focus"
                )
                require(
                    axisPostMoveBarrageNoSummaryPlaybackGame.scenario.units == axisPostMoveBarrageNoSummaryUnits,
                    "AI replay playback without summary should not mutate units"
                )
                require(
                    axisPostMoveBarrageNoSummaryPlaybackGame.latestAIPhaseSummary == nil,
                    "AI replay playback without summary should not create summary"
                )
                let axisPostMoveBarrageInvalidPlaybackGame = GameState(
                    scenario: axisPostMoveBarrageScenario(),
                    commandPoints: [.allies: 6, .axis: 1]
                )
                guard let axisPostMoveBarrageValidFocus = axisPostMoveBarrageInvalidPlaybackGame.focusedCoordinate else {
                    require(false, "invalid replay playback test should have an initial focus")
                    return
                }
                axisPostMoveBarrageInvalidPlaybackGame.replaceLatestAIPhaseSummaryForTesting(
                    smokeAIPhaseSummary(timeline: [])
                )
                axisPostMoveBarrageInvalidPlaybackGame.toggleAIPhaseTimelinePlayback()
                axisPostMoveBarrageInvalidPlaybackGame.advanceAIPhaseTimelinePlayback()
                require(
                    !axisPostMoveBarrageInvalidPlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "AI replay playback should stay paused with empty timeline"
                )
                require(
                    axisPostMoveBarrageInvalidPlaybackGame.focusedCoordinate == axisPostMoveBarrageValidFocus,
                    "AI replay playback with empty timeline should preserve focus"
                )
                axisPostMoveBarrageInvalidPlaybackGame.replaceLatestAIPhaseSummaryForTesting(
                    smokeAIPhaseSummary(timeline: [
                        smokeAIPhaseTimelineEvent(order: 1, from: axisPostMoveBarrageValidFocus, to: axisPostMoveBarrageValidFocus)
                    ])
                )
                axisPostMoveBarrageInvalidPlaybackGame.focusAIPhaseTimelineEvent(order: 1)
                let axisPostMoveBarrageInvalidPlaybackFocus = axisPostMoveBarrageInvalidPlaybackGame.focusedCoordinate
                let axisPostMoveBarrageInvalidPlaybackOrder = axisPostMoveBarrageInvalidPlaybackGame.focusedAIPhaseTimelineEventOrder
                let axisPostMoveBarrageInvalidPlaybackUnits = axisPostMoveBarrageInvalidPlaybackGame.scenario.units
                axisPostMoveBarrageInvalidPlaybackGame.replaceLatestAIPhaseSummaryForTesting(
                    smokeAIPhaseSummary(timeline: [
                        smokeAIPhaseTimelineEvent(order: 2, from: nil, to: nil)
                    ])
                )
                axisPostMoveBarrageInvalidPlaybackGame.toggleAIPhaseTimelinePlayback()
                axisPostMoveBarrageInvalidPlaybackGame.advanceAIPhaseTimelinePlayback()
                require(
                    !axisPostMoveBarrageInvalidPlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "AI replay playback should pause when next event has no coordinate"
                )
                require(
                    axisPostMoveBarrageInvalidPlaybackGame.focusedCoordinate == axisPostMoveBarrageInvalidPlaybackFocus,
                    "AI replay playback no-coordinate failure should preserve focus"
                )
                require(
                    axisPostMoveBarrageInvalidPlaybackGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageInvalidPlaybackOrder,
                    "AI replay playback no-coordinate failure should preserve order"
                )
                require(
                    axisPostMoveBarrageInvalidPlaybackGame.scenario.units == axisPostMoveBarrageInvalidPlaybackUnits,
                    "AI replay playback no-coordinate failure should not mutate units"
                )
                axisPostMoveBarrageInvalidPlaybackGame.replaceLatestAIPhaseSummaryForTesting(
                    smokeAIPhaseSummary(timeline: [
                        smokeAIPhaseTimelineEvent(order: 3, from: HexCoordinate(q: 999, r: 999), to: HexCoordinate(q: 999, r: 999))
                    ])
                )
                axisPostMoveBarrageInvalidPlaybackGame.toggleAIPhaseTimelinePlayback()
                axisPostMoveBarrageInvalidPlaybackGame.advanceAIPhaseTimelinePlayback()
                require(
                    !axisPostMoveBarrageInvalidPlaybackGame.isAIPhaseTimelinePlaybackActive,
                    "AI replay playback should pause when next event coordinate is off-map"
                )
                require(
                    axisPostMoveBarrageInvalidPlaybackGame.focusedCoordinate == axisPostMoveBarrageInvalidPlaybackFocus,
                    "AI replay playback off-map failure should preserve focus"
                )
                require(
                    axisPostMoveBarrageInvalidPlaybackGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageInvalidPlaybackOrder,
                    "AI replay playback off-map failure should preserve order"
                )

                axisPostMoveBarrageGame.focusAIPhaseTimelineEvent(order: axisPostMoveBarrageReplayEvent.order)
                let axisPostMoveBarrageFocusAfterReplay = axisPostMoveBarrageGame.focusedCoordinate
                axisPostMoveBarrageGame.focusAIPhaseTimelineEvent(order: 999)
                require(
                    axisPostMoveBarrageGame.focusedCoordinate == axisPostMoveBarrageFocusAfterReplay,
                    "invalid AI replay event order should preserve focused coordinate"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == axisPostMoveBarrageReplayEvent.order,
                    "invalid AI replay event order should preserve focused replay event order"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseMapMarkers == axisPostMoveBarrageMarkers.filter { $0.eventOrder == axisPostMoveBarrageReplayEvent.order },
                    "invalid AI replay event order should preserve focused replay markers"
                )
                require(
                    axisPostMoveBarrageGame.message.contains("未找到AI复盘事件 #999"),
                    "invalid AI replay event order should publish clear message"
                )
                axisPostMoveBarrageGame.endTurn()
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseTimelineEventOrder == nil,
                    "next AI phase should clear focused replay event order"
                )
                require(
                    axisPostMoveBarrageGame.focusedAIPhaseMapMarkers.isEmpty,
                    "next AI phase should clear focused replay markers"
                )
            }

            let axisPursuitGame = GameState(
                scenario: axisManeuverPursuitScenario(),
                commandPoints: [.allies: 6, .axis: 0]
            )
            guard let axisPursuitTarget = axisPursuitGame.units.first(where: { $0.name == "薄弱前哨" }),
                  let axisPursuitReserve = axisPursuitGame.units.first(where: { $0.name == "纵深守军" }),
                  let axisPursuitTank = axisPursuitGame.units.first(where: { $0.name == "追击装甲群" }) else {
                require(false, "axis maneuver pursuit test units should exist")
                return
            }
            axisPursuitGame.endTurn()
            if axisPursuitGame.winner == nil {
                guard let axisPursuitTankAfterAI = axisPursuitGame.units.first(where: { $0.id == axisPursuitTank.id }),
                      let axisPursuitReserveAfterAI = axisPursuitGame.units.first(where: { $0.id == axisPursuitReserve.id }) else {
                    require(false, "axis pursuit units should survive AI turn")
                    return
                }
                require(!axisPursuitGame.units.contains { $0.id == axisPursuitTarget.id }, "axis pursuit should destroy the weak outpost")
                require(axisPursuitTankAfterAI.position == HexCoordinate(q: 0, r: 0), "axis AI should advance after maneuver pursuit")
                require(axisPursuitGame.tile(at: HexCoordinate(q: 0, r: 0))?.owner == .axis, "axis pursuit should capture the forward objective")
                require(axisPursuitReserveAfterAI.hp == axisPursuitReserve.hp, "axis pursuit should not grant a second attack")
                require(axisPursuitTankAfterAI.hasMoved && axisPursuitTankAfterAI.hasAttacked, "axis pursuit should spend remaining movement")
                require(axisPursuitGame.battleLog.contains { $0.contains("可继续机动") }, "axis maneuver pursuit should be logged")
                guard let axisPursuitPhaseSummary = axisPursuitGame.latestAIPhaseSummary else {
                    require(false, "axis pursuit turn should publish AI phase summary")
                    return
                }
                require(axisPursuitPhaseSummary.objectivesCaptured == 1, "AI phase summary should count captured objective")
                require(axisPursuitPhaseSummary.enemyUnitsDestroyed == 1, "AI phase summary should count destroyed allied units")
                require(axisPursuitPhaseSummary.friendlyUnitsDestroyed == 0, "AI phase summary should count zero axis losses")
                let axisPursuitConclusion = axisPursuitPhaseSummary.replayConclusion
                require(axisPursuitConclusion.kind == .objectiveBreakthrough, "axis pursuit conclusion should classify as objective breakthrough")
                require(axisPursuitConclusion.metrics.contains { $0.kind == .objectives }, "axis pursuit conclusion should include objective metric")
                require(axisPursuitConclusion.metrics.contains { $0.kind == .damage }, "axis pursuit conclusion should include damage metric")
                require(axisPursuitConclusion.keyEvents.first?.kind == .objectiveCapture, "axis pursuit conclusion should prioritize objective capture")
                require(axisPursuitConclusion.keyEvents.contains { $0.kind == .attack }, "axis pursuit conclusion should include attack key event")
                requireSequentialTimelineOrders(axisPursuitPhaseSummary.timeline, "axis pursuit timeline should use sequential orders")
                guard let axisPursuitAttackIndex = axisPursuitPhaseSummary.timeline.firstIndex(where: { $0.kind == .attack }),
                      let axisPursuitMoveIndex = axisPursuitPhaseSummary.timeline.firstIndex(where: { $0.kind == .move }),
                      let axisPursuitCaptureIndex = axisPursuitPhaseSummary.timeline.firstIndex(where: { $0.kind == .objectiveCapture }) else {
                    require(false, "axis pursuit timeline should include attack, move, and capture")
                    return
                }
                require(axisPursuitAttackIndex < axisPursuitMoveIndex, "axis pursuit timeline should attack before maneuver move")
                require(axisPursuitMoveIndex < axisPursuitCaptureIndex, "axis pursuit timeline should capture after move")
                require(axisPursuitPhaseSummary.timeline[axisPursuitAttackIndex].didDestroyTarget, "axis pursuit timeline should record destroyed target")
                require(axisPursuitPhaseSummary.timeline[axisPursuitCaptureIndex].objectiveName == "前线据点", "axis pursuit timeline should record objective name")
                require(axisPursuitPhaseSummary.timeline[axisPursuitCaptureIndex].commandPointReward == 3, "axis pursuit timeline should record capture reward")
                require(
                    axisPursuitPhaseSummary.timeline.filter { $0.kind == .objectiveCapture }.count == axisPursuitPhaseSummary.objectivesCaptured,
                    "axis pursuit timeline capture count should match AI phase summary"
                )
                let axisPursuitMarkers = axisPursuitGame.latestAIPhaseMapMarkers
                requireAIPhaseMapMarkersMatchSummary(axisPursuitMarkers, axisPursuitPhaseSummary, "axis pursuit map replay markers")
                requireAIPhaseMapMarker(
                    axisPursuitMarkers,
                    kind: .attack,
                    role: .target,
                    coordinate: HexCoordinate(q: 1, r: 0),
                    order: axisPursuitPhaseSummary.timeline[axisPursuitAttackIndex].order,
                    "axis pursuit map replay should keep destroyed target coordinate"
                )
                requireAIPhaseMapMarker(
                    axisPursuitMarkers,
                    kind: .move,
                    role: .destination,
                    coordinate: HexCoordinate(q: 0, r: 0),
                    order: axisPursuitPhaseSummary.timeline[axisPursuitMoveIndex].order,
                    "axis pursuit map replay should mark pursuit destination"
                )
                requireAIPhaseMapMarker(
                    axisPursuitMarkers,
                    kind: .objectiveCapture,
                    role: .objective,
                    coordinate: HexCoordinate(q: 0, r: 0),
                    order: axisPursuitPhaseSummary.timeline[axisPursuitCaptureIndex].order,
                    "axis pursuit map replay should mark captured objective"
                )
                require(
                    axisPursuitMarkers.contains {
                        $0.eventKind == .objectiveCapture &&
                            $0.role == .objective &&
                            $0.summary.contains("前线据点")
                    },
                    "axis pursuit map replay should carry objective summary"
                )
            }

            let axisImmediateObjectiveGame = GameState(
                scenario: axisImmediateObjectiveCaptureScenario(),
                commandPoints: [.allies: 6, .axis: 0]
            )
            guard let axisImmediateInfantry = axisImmediateObjectiveGame.units.first(where: { $0.name == "夺点步兵" }),
                  let axisImmediateScreen = axisImmediateObjectiveGame.units.first(where: { $0.name == "牵制守军" }) else {
                require(false, "axis immediate objective capture test units should exist")
                return
            }
            let axisImmediateCaptureCoordinate = HexCoordinate(q: 0, r: 0)
            axisImmediateObjectiveGame.endTurn()
            if axisImmediateObjectiveGame.winner == nil {
                guard let axisImmediateInfantryAfterAI = axisImmediateObjectiveGame.units.first(where: { $0.id == axisImmediateInfantry.id }),
                      let axisImmediateScreenAfterAI = axisImmediateObjectiveGame.units.first(where: { $0.id == axisImmediateScreen.id }) else {
                    require(false, "axis immediate objective capture units should survive AI turn")
                    return
                }
                require(axisImmediateInfantryAfterAI.position == axisImmediateCaptureCoordinate, "axis AI should capture reachable objective before nonlethal attack")
                require(axisImmediateObjectiveGame.tile(at: axisImmediateCaptureCoordinate)?.owner == .axis, "axis immediate objective should change owner")
                require(axisImmediateScreenAfterAI.hp == axisImmediateScreen.hp, "axis AI should skip nonlethal attack when immediate objective is reachable")
                guard let axisImmediatePhaseSummary = axisImmediateObjectiveGame.latestAIPhaseSummary else {
                    require(false, "axis immediate objective turn should publish AI phase summary")
                    return
                }
                require(axisImmediatePhaseSummary.moves == 1, "axis immediate objective summary should count one move")
                require(axisImmediatePhaseSummary.attacks == 0, "axis immediate objective summary should not count skipped nonlethal attack")
                require(axisImmediatePhaseSummary.objectivesCaptured == 1, "axis immediate objective summary should count captured objective")
                let axisImmediateConclusion = axisImmediatePhaseSummary.replayConclusion
                require(axisImmediateConclusion.kind == .objectiveBreakthrough, "axis immediate objective conclusion should classify as objective breakthrough")
                require(axisImmediateConclusion.metrics.contains { $0.kind == .objectives }, "axis immediate objective conclusion should include objective metric")
                require(axisImmediateConclusion.metrics.contains { $0.kind == .damage && $0.value == "-0" }, "axis immediate objective conclusion should show zero damage")
                require(axisImmediateConclusion.keyEvents.contains { $0.kind == .objectiveCapture }, "axis immediate objective conclusion should include capture key event")
                require(!axisImmediateConclusion.keyEvents.contains { $0.kind == .attack }, "axis immediate objective conclusion should not invent attack key event")
                requireSequentialTimelineOrders(axisImmediatePhaseSummary.timeline, "axis immediate objective timeline should use sequential orders")
                guard let axisImmediateMoveIndex = axisImmediatePhaseSummary.timeline.firstIndex(where: { $0.kind == .move }),
                      let axisImmediateCaptureIndex = axisImmediatePhaseSummary.timeline.firstIndex(where: { $0.kind == .objectiveCapture }) else {
                    require(false, "axis immediate objective timeline should include move and capture")
                    return
                }
                require(axisImmediateMoveIndex < axisImmediateCaptureIndex, "axis immediate objective timeline should move before capture")
                require(axisImmediatePhaseSummary.timeline[axisImmediateMoveIndex].to == axisImmediateCaptureCoordinate, "axis immediate objective move should end at objective")
                require(axisImmediatePhaseSummary.timeline[axisImmediateCaptureIndex].objectiveName == "前沿村镇", "axis immediate objective capture should record objective name")
                require(axisImmediatePhaseSummary.timeline[axisImmediateCaptureIndex].commandPointReward == 3, "axis immediate objective capture should record reward")
                let axisImmediateMarkers = axisImmediateObjectiveGame.latestAIPhaseMapMarkers
                requireAIPhaseMapMarkersMatchSummary(axisImmediateMarkers, axisImmediatePhaseSummary, "axis immediate objective map replay markers")
                requireAIPhaseMapMarker(
                    axisImmediateMarkers,
                    kind: .move,
                    role: .destination,
                    coordinate: axisImmediateCaptureCoordinate,
                    order: axisImmediatePhaseSummary.timeline[axisImmediateMoveIndex].order,
                    "axis immediate objective map replay should mark move destination"
                )
                requireAIPhaseMapMarker(
                    axisImmediateMarkers,
                    kind: .objectiveCapture,
                    role: .objective,
                    coordinate: axisImmediateCaptureCoordinate,
                    order: axisImmediatePhaseSummary.timeline[axisImmediateCaptureIndex].order,
                    "axis immediate objective map replay should mark captured objective"
                )
            }

            let objectiveRewardGame = GameState(
                scenario: objectiveRewardScenario(),
                commandPoints: [.allies: 4, .axis: 6]
            )
            guard let objectiveRewardInfantry = objectiveRewardGame.units.first(where: { $0.name == "占点步兵" }) else {
                require(false, "objective reward infantry should exist")
                return
            }
            let rewardObjective = HexCoordinate(q: 2, r: 0)
            objectiveRewardGame.handleTap(on: objectiveRewardInfantry.position)
            objectiveRewardGame.handleTap(on: rewardObjective)
            guard let objectiveRewardInfantryAfter = objectiveRewardGame.units.first(where: { $0.id == objectiveRewardInfantry.id }) else {
                require(false, "objective reward infantry should survive capture")
                return
            }
            require(objectiveRewardGame.tile(at: rewardObjective)?.owner == .allies, "captured objective should change owner")
            require(objectiveRewardGame.commandPoints(for: .allies) == 7, "capturing objective should award command points")
            require(objectiveRewardInfantryAfter.morale == objectiveRewardInfantry.morale + 8, "capturing objective should raise morale")
            require(objectiveRewardInfantryAfter.experience == objectiveRewardInfantry.experience + 10, "capturing objective should award experience")
            require(objectiveRewardGame.objectiveCaptureRewardSummary.contains("指令 +3"), "objective reward summary should describe command reward")
            require(objectiveRewardGame.battleLog.contains { $0.contains("夺取前线村镇") }, "capturing objective should be logged")
            guard let objectiveRewardCapture = objectiveRewardGame.latestObjectiveCaptureResult else {
                require(false, "capturing objective should record capture summary")
                return
            }
            require(objectiveRewardCapture.objectiveName == "前线村镇", "capture summary should name the captured objective")
            require(objectiveRewardCapture.coordinate == rewardObjective, "capture summary should record captured coordinate")
            require(objectiveRewardCapture.capturingUnitName == "占点步兵", "capture summary should record capturing unit")
            require(objectiveRewardCapture.commandPointReward == 3, "capture summary should record command reward")
            require(objectiveRewardCapture.moraleReward == 8, "capture summary should record morale reward")
            require(objectiveRewardCapture.experienceReward == 10, "capture summary should record experience reward")
            require(objectiveRewardCapture.alliedScoreAfterCapture == objectiveRewardGame.alliedScore, "capture summary should record allied objective progress")

            let objectiveRestGame = GameState(
                scenario: objectiveRestScenario(),
                commandPoints: [.allies: 6, .axis: 0]
            )
            guard let restingInfantry = objectiveRestGame.units.first(where: { $0.name == "休整守军" }) else {
                require(false, "objective rest infantry should exist")
                return
            }
            require(objectiveRestGame.objectiveRestRecovery(for: restingInfantry) == 10, "owned objective should recover damaged supplied units")
            require(objectiveRestGame.objectiveRestSummary.contains("+10"), "objective rest summary should describe recovery amount")
            objectiveRestGame.endTurn()
            if objectiveRestGame.winner == nil {
                guard let recoveredInfantry = objectiveRestGame.units.first(where: { $0.id == restingInfantry.id }) else {
                    require(false, "resting infantry should survive objective rest")
                    return
                }
                require(recoveredInfantry.hp == restingInfantry.hp + 10, "objective rest should restore HP on new player turn")
                require(objectiveRestGame.battleLog.contains { $0.contains("恢复 10 耐久") }, "objective rest should be logged")
            }

            var veteranScenario = Scenario.ardennesPrototype()
            guard let veteranAttackerIndex = veteranScenario.units.firstIndex(where: { $0.name == "第4装甲师" }),
                  let veteranTargetIndex = veteranScenario.units.firstIndex(where: { $0.name == "第2装甲集团" }) else {
                require(false, "veteran test units should exist")
                return
            }
            veteranScenario.units[veteranAttackerIndex].position = HexCoordinate(q: 9, r: 4)
            veteranScenario.units[veteranAttackerIndex].experience = UnitRank.regular.minimumExperience - 1
            veteranScenario.units[veteranTargetIndex].hp = 12
            let veteranAttackerID = veteranScenario.units[veteranAttackerIndex].id
            let veteranTargetPosition = veteranScenario.units[veteranTargetIndex].position
            let veteranGame = GameState(scenario: veteranScenario)
            veteranGame.handleTap(on: HexCoordinate(q: 9, r: 4))
            veteranGame.handleTap(on: veteranTargetPosition)
            guard let promoted = veteranGame.units.first(where: { $0.id == veteranAttackerID }) else {
                require(false, "promoted attacker should survive")
                return
            }
            require(promoted.experience >= UnitRank.regular.minimumExperience, "combat should award experience")
            require(promoted.rank != .green, "experience should promote units")
            require(promoted.maxHP > promoted.kind.baseHP, "rank should increase max HP")

            let isolatedGame = GameState(scenario: isolatedSupplyScenario())
            guard let isolatedTank = isolatedGame.units.first(where: { $0.name == "孤立装甲" }),
                  let isolatedTarget = isolatedGame.units.first(where: { $0.name == "靶标步兵" }) else {
                require(false, "isolated supply test units should exist")
                return
            }
            require(isolatedGame.supplyState(for: isolatedTank) == .isolated, "blocked unit should be isolated")
            require(isolatedGame.supplyLineTiles(for: isolatedTank).isEmpty, "blocked unit should have no supply path")
            let isolatedPreview = isolatedGame.combatPreview(attacker: isolatedTank, defender: isolatedTarget)
            let fullSupplyPreview = game.combatPreview(
                attacker: BattleUnit(
                    name: "补给装甲",
                    kind: .tank,
                    faction: .allies,
                    position: isolatedTank.position,
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                defender: isolatedTarget
            )
            require((isolatedPreview?.damage ?? 0) < (fullSupplyPreview?.damage ?? 99), "isolated unit should deal less damage")
            let isolatedHP = isolatedTank.hp
            isolatedGame.endTurn()
            guard let attritedTank = isolatedGame.units.first(where: { $0.id == isolatedTank.id }) else {
                require(false, "isolated tank should survive attrition")
                return
            }
            require(attritedTank.hp < isolatedHP, "isolated unit should take attrition on turn reset")

            let inspiredGame = GameState(scenario: moraleCombatScenario(attackerMorale: 90))
            let shakenGame = GameState(scenario: moraleCombatScenario(attackerMorale: 20))
            let inspiredMovementGame = GameState(scenario: moraleMovementScenario(unitMorale: 90))
            let shakenMovementGame = GameState(scenario: moraleMovementScenario(unitMorale: 20))
            guard let inspiredTank = inspiredGame.units.first(where: { $0.name == "士气装甲" }),
                  let shakenTank = shakenGame.units.first(where: { $0.name == "士气装甲" }),
                  let inspiredMover = inspiredMovementGame.units.first(where: { $0.name == "士气行军装甲" }),
                  let shakenMover = shakenMovementGame.units.first(where: { $0.name == "士气行军装甲" }),
                  let inspiredTarget = inspiredGame.units.first(where: { $0.name == "目标守军" }),
                  let shakenTarget = shakenGame.units.first(where: { $0.name == "目标守军" }) else {
                require(false, "morale test units should exist")
                return
            }
            require(inspiredTank.moraleState == .inspired, "high morale should create inspired state")
            require(shakenTank.moraleState == .shaken, "low morale should create shaken state")
            require(
                (inspiredGame.combatPreview(attacker: inspiredTank, defender: inspiredTarget)?.damage ?? 0) >
                    (shakenGame.combatPreview(attacker: shakenTank, defender: shakenTarget)?.damage ?? 99),
                "inspired units should deal more damage than shaken units"
            )
            require(
                inspiredMovementGame.reachableTiles(for: inspiredMover).count > shakenMovementGame.reachableTiles(for: shakenMover).count,
                "inspired units should reach more tiles than shaken units"
            )

            let moraleGame = GameState(scenario: moraleCombatScenario(attackerMorale: 60, defenderMorale: 60))
            guard let moraleAttacker = moraleGame.units.first(where: { $0.name == "士气装甲" }),
                  let moraleDefender = moraleGame.units.first(where: { $0.name == "目标守军" }) else {
                require(false, "morale combat units should exist")
                return
            }
            moraleGame.handleTap(on: moraleAttacker.position)
            moraleGame.handleTap(on: moraleDefender.position)
            guard let moraleAttackerAfter = moraleGame.units.first(where: { $0.id == moraleAttacker.id }),
                  let moraleDefenderAfter = moraleGame.units.first(where: { $0.id == moraleDefender.id }) else {
                require(false, "morale combat units should survive")
                return
            }
            require(moraleAttackerAfter.morale > moraleAttacker.morale, "successful attacks should raise attacker morale")
            require(moraleDefenderAfter.morale < moraleDefender.morale, "being hit should lower defender morale")

            let recoveryGame = GameState(scenario: moraleRecoveryScenario())
            guard let tiredUnit = recoveryGame.units.first(where: { $0.name == "休整步兵" }) else {
                require(false, "morale recovery unit should exist")
                return
            }
            recoveryGame.endTurn()
            guard let recoveredUnit = recoveryGame.units.first(where: { $0.id == tiredUnit.id }) else {
                require(false, "morale recovery unit should survive")
                return
            }
            require(recoveredUnit.morale == tiredUnit.morale + 10, "supplied units on objectives should recover morale")

            let baselineEntrenchmentGame = GameState(scenario: entrenchmentScenario())
            guard let baselineDefender = baselineEntrenchmentGame.units.first(where: { $0.name == "防御步兵" }),
                  let baselineAttacker = baselineEntrenchmentGame.units.first(where: { $0.name == "进攻装甲" }),
                  let baselineEntrenchmentPreview = baselineEntrenchmentGame.combatPreview(attacker: baselineAttacker, defender: baselineDefender) else {
                require(false, "baseline entrenchment units should exist")
                return
            }
            let entrenchmentGame = GameState(scenario: entrenchmentScenario())
            guard let entrenchingDefender = entrenchmentGame.units.first(where: { $0.name == "防御步兵" }),
                  let entrenchmentAttacker = entrenchmentGame.units.first(where: { $0.name == "进攻装甲" }) else {
                require(false, "entrenchment units should exist")
                return
            }
            entrenchmentGame.handleTap(on: entrenchingDefender.position)
            entrenchmentGame.waitSelectedUnit()
            guard let entrenchedDefender = entrenchmentGame.units.first(where: { $0.id == entrenchingDefender.id }),
                  let entrenchedPreview = entrenchmentGame.combatPreview(attacker: entrenchmentAttacker, defender: entrenchedDefender) else {
                require(false, "entrenched preview should exist")
                return
            }
            require(entrenchedDefender.isEntrenched, "waiting should put unit into defensive posture")
            require(entrenchedPreview.defenderIsEntrenched, "combat preview should expose defensive posture")
            require(entrenchedPreview.defenseMultiplierPercent == 75, "defensive posture should reduce incoming damage to 75 percent")
            require(entrenchedPreview.damage < baselineEntrenchmentPreview.damage, "defensive posture should reduce incoming damage")
            require(entrenchmentGame.entrenchmentSummary.contains("75%"), "entrenchment summary should describe damage reduction")
            entrenchmentGame.endTurn()
            if entrenchmentGame.winner == nil {
                guard let defenderAfterAttack = entrenchmentGame.units.first(where: { $0.id == entrenchingDefender.id }) else {
                    require(false, "entrenched defender should survive AI attack")
                    return
                }
                let hpAfterIncomingAttack = entrenchingDefender.hp - entrenchedPreview.damage
                let expectedObjectiveRest = min(10, entrenchingDefender.maxHP - hpAfterIncomingAttack)
                require(
                    defenderAfterAttack.hp == hpAfterIncomingAttack + expectedObjectiveRest,
                    "AI attack should apply reduced entrenchment damage before objective rest"
                )
                require(!defenderAfterAttack.isEntrenched, "defensive posture should be consumed after being hit")
                require(entrenchmentGame.battleLog.contains { $0.contains("恢复 \(expectedObjectiveRest) 耐久") }, "objective rest should apply after entrenchment damage")
            }

            let baselineFlankingGame = GameState(scenario: flankingScenario(supportCount: 0))
            guard let baselineFlankingAttacker = baselineFlankingGame.units.first(where: { $0.name == "协同装甲" }),
                  let baselineFlankingTarget = baselineFlankingGame.units.first(where: { $0.name == "夹击目标" }),
                  let baselineFlankingPreview = baselineFlankingGame.combatPreview(attacker: baselineFlankingAttacker, defender: baselineFlankingTarget) else {
                require(false, "baseline flanking units should exist")
                return
            }
            let flankingGame = GameState(scenario: flankingScenario(supportCount: 2))
            guard let flankingAttacker = flankingGame.units.first(where: { $0.name == "协同装甲" }),
                  let flankingTarget = flankingGame.units.first(where: { $0.name == "夹击目标" }),
                  let flankingPreview = flankingGame.combatPreview(attacker: flankingAttacker, defender: flankingTarget) else {
                require(false, "flanking support units should exist")
                return
            }
            require(flankingGame.flankingSupportUnits(attacker: flankingAttacker, defender: flankingTarget).count == 2, "flanking support query should find adjacent friendly units")
            require(flankingPreview.supportUnitCount == 2, "combat preview should expose support unit count")
            require(flankingPreview.supportDamageBonusPercent == 20, "two support units should add 20 percent damage")
            require(flankingPreview.supportTitle == "夹击协同", "supported attacks should be labeled as flanking coordination")
            require(flankingPreview.damage > baselineFlankingPreview.damage, "flanking support should increase combat damage")
            require(flankingGame.flankingSupportSummary.contains("+10%"), "flanking support summary should describe per-unit bonus")
            flankingGame.handleTap(on: flankingAttacker.position)
            flankingGame.handleTap(on: flankingTarget.position)
            guard let flankingTargetAfterAttack = flankingGame.units.first(where: { $0.id == flankingTarget.id }) else {
                require(false, "flanking target should survive the smoke attack")
                return
            }
            require(flankingTargetAfterAttack.hp == flankingTarget.hp - flankingPreview.damage, "flanking attack should apply previewed damage")
            require(flankingGame.battleLog.contains { $0.contains("夹击 +20%") }, "flanking support should be logged")

            let missionGame = GameState(scenario: missionStarScenario())
            guard let missionTank = missionGame.units.first(where: { $0.name == "任务装甲" }) else {
                require(false, "mission star unit should exist")
                return
            }
            missionGame.handleTap(on: missionTank.position)
            missionGame.handleTap(on: HexCoordinate(q: 1, r: 0))
            require(missionGame.winner == .allies, "capturing all objectives should win the mission")
            require(missionGame.earnedStars == 3, "fast objective capture with enough survivors should award three stars")
            require(missionGame.missionObjectives.allSatisfy { $0.state == .complete }, "all star objectives should be complete after perfect victory")

            let timeoutGame = GameState(scenario: missionTimeoutScenario())
            timeoutGame.endTurn()
            require(timeoutGame.winner == .axis, "mission should fail when turn limit expires")
            require(timeoutGame.earnedStars == 0, "failed missions should award zero stars")
            require(timeoutGame.remainingTurns == 0, "expired mission should have no remaining turns")
            require(
                timeoutGame.missionObjectives.contains { $0.id == "primary" && $0.state == .failed },
                "primary objective should fail after timeout"
            )

            guard let deploySite = game.deploymentSites(for: .allies).first else {
                require(false, "allied objective should provide a deployment site")
                return
            }
            let commandPointsBeforeDeploy = game.commandPoints(for: .allies)
            let alliedCountBeforeDeploy = game.units(for: .allies).count
            game.deploy(kind: .infantry, at: deploySite.coordinate)
            require(game.commandPoints(for: .allies) == commandPointsBeforeDeploy - UnitKind.infantry.commandCost, "deployment should spend command points")
            require(game.units(for: .allies).count == alliedCountBeforeDeploy + 1, "deployment should add a unit")
            guard let deploymentResult = game.latestDeploymentResult,
                  let deployedUnit = game.units.first(where: { $0.id == deploymentResult.unitID }) else {
                require(false, "deployment should publish a logistics result")
                return
            }
            require(deploymentResult.unitName == deployedUnit.name, "deployment result should record new unit name")
            require(deploymentResult.unitKind == .infantry, "deployment result should record unit kind")
            require(deploymentResult.faction == .allies, "deployment result should record faction")
            require(deploymentResult.coordinate == deploySite.coordinate, "deployment result should record deployment coordinate")
            require(deploymentResult.sourceObjectiveName == deploySite.sourceObjectiveName, "deployment result should record source objective")
            require(deploymentResult.commandCost == UnitKind.infantry.commandCost, "deployment result should record command cost")
            require(deploymentResult.commandPointsAfterDeployment == game.commandPoints(for: .allies), "deployment result should record remaining command points")
            require(game.latestCombatResult == nil, "deployment result should clear combat result")
            require(game.latestTacticalCommandResult == nil, "deployment result should clear tactical command result")
            require(game.latestObjectiveCaptureResult == nil, "deployment result should clear objective capture result")
            require(game.latestReinforcementResult == nil, "deployment result should clear reinforcement result")

            let reinforcementGame = GameState(
                scenario: objectiveRestScenario(),
                commandPoints: [.allies: 6, .axis: 6]
            )
            guard let damagedUnit = reinforcementGame.units.first(where: { $0.name == "休整守军" }) else {
                require(false, "reinforcement smoke unit should exist")
                return
            }
            let reinforcementCost = reinforcementGame.reinforceCost(for: damagedUnit)
            reinforcementGame.handleTap(on: damagedUnit.position)
            reinforcementGame.reinforceSelectedUnit()
            guard let reinforcementResult = reinforcementGame.latestReinforcementResult,
                  let reinforcedUnit = reinforcementGame.units.first(where: { $0.id == damagedUnit.id }) else {
                require(false, "reinforcement should publish a logistics result")
                return
            }
            require(reinforcementResult.unitID == damagedUnit.id, "reinforcement result should record unit id")
            require(reinforcementResult.unitName == damagedUnit.name, "reinforcement result should record unit name")
            require(reinforcementResult.unitKind == damagedUnit.kind, "reinforcement result should record unit kind")
            require(reinforcementResult.faction == .allies, "reinforcement result should record faction")
            require(reinforcementResult.coordinate == damagedUnit.position, "reinforcement result should record coordinate")
            require(reinforcementResult.startingHP == damagedUnit.hp, "reinforcement result should record starting HP")
            require(reinforcementResult.endingHP == reinforcedUnit.hp, "reinforcement result should record ending HP")
            require(reinforcementResult.recoveredHP == reinforcedUnit.hp - damagedUnit.hp, "reinforcement result should record recovered HP")
            require(reinforcementResult.commandCost == reinforcementCost, "reinforcement result should record command cost")
            require(reinforcementResult.commandPointsAfterReinforcement == reinforcementGame.commandPoints(for: .allies), "reinforcement result should record remaining command points")
            require(reinforcementGame.latestCombatResult == nil, "reinforcement result should clear combat result")
            require(reinforcementGame.latestTacticalCommandResult == nil, "reinforcement result should clear tactical command result")
            require(reinforcementGame.latestObjectiveCaptureResult == nil, "reinforcement result should clear objective capture result")
            require(reinforcementGame.latestDeploymentResult == nil, "reinforcement result should clear deployment result")

            let primaryInspectGame = GameState()
            primaryInspectGame.handlePrimaryAction(on: HexCoordinate(q: 0, r: 0))
            require(primaryInspectGame.selectedUnit == nil, "primary click on empty terrain should not select a unit")
            require(!primaryInspectGame.message.contains("需要先选择"), "primary click on empty terrain should inspect instead of issuing an order")

            let invalidSecondaryGame = GameState()
            guard let invalidEnemy = invalidSecondaryGame.units.first(where: { $0.name == "第2装甲集团" }),
                  let invalidTank = invalidSecondaryGame.units.first(where: { $0.name == "第4装甲师" }),
                  let invalidInfantry = invalidSecondaryGame.units.first(where: { $0.name == "第101空降师" }) else {
                require(false, "invalid secondary action units should exist")
                return
            }
            invalidSecondaryGame.handleSecondaryAction(on: invalidEnemy.position)
            require(invalidSecondaryGame.selectedUnit == nil, "secondary click without selection should not auto-select")
            require(invalidSecondaryGame.units.first(where: { $0.id == invalidEnemy.id })?.hp == invalidEnemy.hp, "secondary click without selection should not damage enemies")
            require(invalidSecondaryGame.message.contains("需要先选择"), "secondary click without selection should ask for a unit")
            invalidSecondaryGame.handleSecondaryAction(on: HexCoordinate(q: 0, r: 0))
            require(invalidSecondaryGame.message.contains("需要先选择"), "secondary click on empty terrain should ask for a unit")
            invalidSecondaryGame.handlePrimaryAction(on: invalidTank.position)
            invalidSecondaryGame.handleSecondaryAction(on: invalidInfantry.position)
            require(invalidSecondaryGame.units.first(where: { $0.id == invalidTank.id })?.position == invalidTank.position, "secondary click on friendly unit should not move selected unit")
            require(invalidSecondaryGame.units.first(where: { $0.id == invalidTank.id })?.hasMoved == false, "secondary click on friendly unit should not spend movement")
            invalidSecondaryGame.handleSecondaryAction(on: invalidEnemy.position)
            require(invalidSecondaryGame.units.first(where: { $0.id == invalidTank.id })?.hasAttacked == false, "secondary click on out-of-range enemy should not spend attack")
            require(invalidSecondaryGame.units.first(where: { $0.id == invalidEnemy.id })?.hp == invalidEnemy.hp, "secondary click on out-of-range enemy should not deal damage")

            let focusGame = GameState()
            guard let focusTank = focusGame.units.first(where: { $0.name == "第4装甲师" }),
                  let focusEnemy = focusGame.units.first(where: { $0.name == "第2装甲集团" }),
                  let focusObjective = focusGame.objectiveTiles.first(where: { $0.objectiveName == "南部桥头堡" }) else {
                require(false, "focus test targets should exist")
                return
            }
            focusGame.focus(unitID: focusEnemy.id)
            require(focusGame.selectedUnit == nil, "focusing an enemy from the map UI should not select a unit")
            require(focusGame.focusedCoordinate == focusEnemy.position, "focusing an enemy should update the focused coordinate")
            require(focusGame.units.first(where: { $0.id == focusEnemy.id })?.hp == focusEnemy.hp, "focusing an enemy should not damage it")
            focusGame.focus(coordinate: focusObjective.coordinate)
            require(focusGame.selectedUnit == nil, "focusing an objective should not select a unit")
            require(focusGame.focusedCoordinate == focusObjective.coordinate, "focusing an objective should update the focused coordinate")
            focusGame.select(unitID: focusTank.id)
            focusGame.focus(unitID: focusEnemy.id)
            require(focusGame.selectedUnit?.id == focusTank.id, "focusing an enemy after selecting a unit should preserve the selected unit")
            require(focusGame.units.first(where: { $0.id == focusTank.id })?.position == focusTank.position, "focusing should not move the selected unit")
            require(focusGame.units.first(where: { $0.id == focusTank.id })?.hasMoved == false, "focusing should not spend movement")
            require(focusGame.units.first(where: { $0.id == focusTank.id })?.hasAttacked == false, "focusing should not spend attacks")
            require(focusGame.units.first(where: { $0.id == focusEnemy.id })?.hp == focusEnemy.hp, "focusing with a selected unit should not attack enemies")

            game.handleTap(on: pattonTank.position)
            require(game.selectedUnit?.id == pattonTank.id, "tap should select allied unit")
            require(!game.reachableTiles(for: pattonTank).isEmpty, "selected tank should have reachable tiles")

            guard let destination = game.reachableTiles(for: pattonTank).sorted(by: { $0.id < $1.id }).first else {
                require(false, "reachable destination should exist")
                return
            }
            game.handleTap(on: destination)
            require(game.selectedUnit?.position == destination, "selected unit should move to reachable tile")
            require(game.focusedCoordinate == destination, "focused tile should follow moved unit")

            let previousTurn = game.turn
            game.endTurn()
            require(game.turn == previousTurn + 1 || game.winner != nil, "ending turn should advance back to player or finish battle")
            require(game.activeFaction == .allies || game.winner != nil, "AI turn should return control to allies unless battle ends")

            print("Rules smoke test passed")
        }
    }

    @MainActor
    private static func verifyCountermeasureExecutionReplay() {
        func countermeasures(in game: GameState) -> [EnemyThreatCountermeasurePreview] {
            game.enemyThreatCountermeasurePreviews(
                for: game.enemyThreatIntentPreviews(against: .allies, limit: 10),
                limit: 10
            )
        }

        let firstStrikeExecutionGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
        guard let firstStrikeExecutionAdvice = countermeasures(in: firstStrikeExecutionGame).first(where: {
            $0.kind == .firstStrike &&
                $0.actingUnitName == "反击炮兵" &&
                $0.threatEnemyUnitName == "威胁炮兵"
        }) else {
            require(false, "execution replay should find first strike advice")
            return
        }
        firstStrikeExecutionGame.focusEnemyThreatCountermeasure(firstStrikeExecutionAdvice)
        require(firstStrikeExecutionGame.latestEnemyThreatCountermeasureExecutionResult == nil, "first strike focus should not publish replay before execution")
        firstStrikeExecutionGame.executeFocusedCommand()
        guard let firstStrikeReplay = firstStrikeExecutionGame.latestEnemyThreatCountermeasureExecutionResult,
              let firstStrikeResult = firstStrikeExecutionGame.latestCombatResult,
              let firstStrikeDamageReplay = firstStrikeReplay.comparisons.first(where: { $0.kind == .damage }),
              let firstStrikeEnemyHPReplay = firstStrikeReplay.comparisons.first(where: { $0.kind == .enemyHP }) else {
            require(false, "first strike execution should publish combat replay")
            return
        }
        require(firstStrikeReplay.countermeasureID == firstStrikeExecutionAdvice.id, "first strike replay should keep advice id")
        require(firstStrikeReplay.countermeasureKind == .firstStrike, "first strike replay should keep advice kind")
        require(firstStrikeReplay.executionKind == .attack, "first strike replay should record attack execution")
        require(firstStrikeDamageReplay.expected == "-\(firstStrikeExecutionAdvice.projectedDamage)", "first strike replay should keep expected damage")
        require(firstStrikeDamageReplay.actual == "-\(firstStrikeResult.damage)", "first strike replay should use actual damage")
        require(firstStrikeResult.damage == firstStrikeExecutionAdvice.projectedDamage, "first strike actual damage should match preview in smoke scenario")
        require(firstStrikeEnemyHPReplay.actual == (firstStrikeResult.didDestroyDefender ? "击毁" : "HP \(firstStrikeResult.defender.endingHP)"), "first strike replay should use actual defender HP")

        let withdrawExecutionGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
        guard let withdrawExecutionAdvice = countermeasures(in: withdrawExecutionGame).first(where: {
            $0.kind == .withdraw &&
                $0.actingUnitName == "前线装甲"
        }),
              let withdrawExecutionDestination = withdrawExecutionAdvice.destination,
              let withdrawExecutionUnit = withdrawExecutionGame.units.first(where: { $0.id == withdrawExecutionAdvice.actingUnitID }),
              let withdrawExecutionRoute = withdrawExecutionGame.movementRoute(for: withdrawExecutionUnit, to: withdrawExecutionDestination) else {
            require(false, "execution replay should find withdraw advice and route")
            return
        }
        withdrawExecutionGame.focusEnemyThreatCountermeasure(withdrawExecutionAdvice)
        withdrawExecutionGame.executeFocusedCommand()
        guard let withdrawReplay = withdrawExecutionGame.latestEnemyThreatCountermeasureExecutionResult,
              let withdrawUnitAfter = withdrawExecutionGame.units.first(where: { $0.id == withdrawExecutionAdvice.actingUnitID }),
              let withdrawPositionReplay = withdrawReplay.comparisons.first(where: { $0.title == "位置" }),
              let withdrawRouteReplay = withdrawReplay.comparisons.first(where: { $0.title == "路线" }) else {
            require(false, "withdraw execution should publish move replay")
            return
        }
        require(withdrawReplay.countermeasureID == withdrawExecutionAdvice.id, "withdraw replay should keep advice id")
        require(withdrawReplay.countermeasureKind == .withdraw, "withdraw replay should keep advice kind")
        require(withdrawReplay.executionKind == .move, "withdraw replay should record move execution")
        require(withdrawReplay.coordinate == withdrawExecutionDestination, "withdraw replay should point to actual destination")
        require(withdrawUnitAfter.position == withdrawExecutionDestination, "withdraw execution should move to advice destination")
        require(withdrawPositionReplay.actual == "q\(withdrawExecutionDestination.q),r\(withdrawExecutionDestination.r)", "withdraw replay should record actual destination")
        require(withdrawRouteReplay.actual == "\(withdrawExecutionRoute.totalCost)", "withdraw replay should record actual route cost")
        require(withdrawExecutionGame.latestCombatResult == nil, "withdraw move should not publish combat result")
        require(withdrawExecutionGame.latestReinforcementResult == nil, "withdraw move should not publish reinforcement result")
        withdrawExecutionGame.selectScenario(id: "ardennes-1944")
        require(withdrawExecutionGame.latestEnemyThreatCountermeasureExecutionResult == nil, "scenario switch should clear latest countermeasure replay")

        let objectiveExecutionGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
        guard let objectiveExecutionAdvice = countermeasures(in: objectiveExecutionGame).first(where: {
            $0.kind == .objectiveDefense &&
                $0.targetName == "后方油库"
        }),
              let objectiveExecutionDestination = objectiveExecutionAdvice.destination else {
            require(false, "execution replay should find objective defense advice")
            return
        }
        objectiveExecutionGame.focusEnemyThreatCountermeasure(objectiveExecutionAdvice)
        objectiveExecutionGame.executeFocusedCommand()
        guard let objectiveReplay = objectiveExecutionGame.latestEnemyThreatCountermeasureExecutionResult,
              let objectiveUnitAfter = objectiveExecutionGame.units.first(where: { $0.id == objectiveExecutionAdvice.actingUnitID }),
              let objectiveActionReplay = objectiveReplay.comparisons.first(where: { $0.kind == .objective }) else {
            require(false, "objective defense execution should publish move replay")
            return
        }
        let expectedObjectiveAction = objectiveExecutionDestination == objectiveExecutionAdvice.threatTargetCoordinate ? "进驻" : "封堵"
        require(objectiveReplay.countermeasureKind == .objectiveDefense, "objective replay should keep advice kind")
        require(objectiveReplay.executionKind == .move, "objective replay should record move execution")
        require(objectiveReplay.coordinate == objectiveExecutionDestination, "objective replay should point to actual destination")
        require(objectiveUnitAfter.position == objectiveExecutionDestination, "objective defense execution should move to advice destination")
        require(objectiveActionReplay.expected == expectedObjectiveAction, "objective replay should record expected defense action")
        require(objectiveActionReplay.result.contains(objectiveExecutionAdvice.targetName), "objective replay should name the defended objective")

        let reinforceExecutionGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
        guard let reinforceExecutionAdvice = countermeasures(in: reinforceExecutionGame).first(where: {
            $0.kind == .reinforce &&
                $0.actingUnitName == "前线装甲"
        }) else {
            require(false, "execution replay should find reinforce advice")
            return
        }
        let commandPointsBeforeReinforce = reinforceExecutionGame.activeCommandPoints
        reinforceExecutionGame.focusEnemyThreatCountermeasure(reinforceExecutionAdvice)
        reinforceExecutionGame.reinforceSelectedUnit()
        guard let reinforceReplay = reinforceExecutionGame.latestEnemyThreatCountermeasureExecutionResult,
              let reinforceResult = reinforceExecutionGame.latestReinforcementResult,
              let reinforceRecoveryReplay = reinforceReplay.comparisons.first(where: { $0.kind == .recovery }),
              let reinforceSurvivalReplay = reinforceReplay.comparisons.first(where: { $0.kind == .survival }) else {
            require(false, "reinforce execution should publish reinforcement replay")
            return
        }
        require(reinforceReplay.countermeasureID == reinforceExecutionAdvice.id, "reinforce replay should keep advice id")
        require(reinforceReplay.countermeasureKind == .reinforce, "reinforce replay should keep advice kind")
        require(reinforceReplay.executionKind == .reinforce, "reinforce replay should record reinforce execution")
        require(reinforceRecoveryReplay.expected == "+\(reinforceExecutionAdvice.projectedRecoveredHP)", "reinforce replay should keep expected recovery")
        require(reinforceRecoveryReplay.actual == "+\(reinforceResult.recoveredHP)", "reinforce replay should use actual recovery")
        require(reinforceResult.recoveredHP == reinforceExecutionAdvice.projectedRecoveredHP, "reinforce actual recovery should match preview")
        require(reinforceSurvivalReplay.actual == "HP \(reinforceResult.endingHP)", "reinforce replay should use actual ending HP")
        require(reinforceExecutionGame.activeCommandPoints == commandPointsBeforeReinforce - reinforceResult.commandCost, "reinforce execution should spend command points")
        guard let clearingAttackUnit = reinforceExecutionGame.units.first(where: { $0.name == "反击炮兵" }),
              let clearingAttackTarget = reinforceExecutionGame.units.first(where: { $0.name == "威胁炮兵" }) else {
            require(false, "clearing attack should find attacker and target")
            return
        }
        reinforceExecutionGame.handleTap(on: clearingAttackUnit.position)
        reinforceExecutionGame.focus(unitID: clearingAttackTarget.id)
        reinforceExecutionGame.executeFocusedCommand()
        require(reinforceExecutionGame.latestCombatResult != nil, "ordinary attack after replay should still publish combat result")
        require(reinforceExecutionGame.latestEnemyThreatCountermeasureExecutionResult == nil, "ordinary attack should clear latest countermeasure replay")
        reinforceExecutionGame.restart()
        require(reinforceExecutionGame.latestEnemyThreatCountermeasureExecutionResult == nil, "restart should clear latest countermeasure replay")

        let ordinaryMoveGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
        guard let ordinaryTank = ordinaryMoveGame.units.first(where: { $0.name == "前线装甲" }),
              let ordinaryRoute = ordinaryMoveGame.movementRoutes(for: ordinaryTank)
                .values
                .sorted(by: { $0.destination.id < $1.destination.id })
                .first else {
            require(false, "ordinary move should find a reachable destination")
            return
        }
        ordinaryMoveGame.handleTap(on: ordinaryTank.position)
        ordinaryMoveGame.focus(coordinate: ordinaryRoute.destination)
        ordinaryMoveGame.executeFocusedCommand()
        require(ordinaryMoveGame.latestEnemyThreatCountermeasureExecutionResult == nil, "ordinary move without focused countermeasure should not publish replay")

        let ordinaryAttackGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
        guard let ordinaryArtillery = ordinaryAttackGame.units.first(where: { $0.name == "反击炮兵" }),
              let ordinaryTarget = ordinaryAttackGame.units.first(where: { $0.name == "威胁炮兵" }) else {
            require(false, "ordinary attack should find attacker and target")
            return
        }
        ordinaryAttackGame.handleTap(on: ordinaryArtillery.position)
        ordinaryAttackGame.focus(unitID: ordinaryTarget.id)
        ordinaryAttackGame.executeFocusedCommand()
        require(ordinaryAttackGame.latestCombatResult != nil, "ordinary attack should still publish combat result")
        require(ordinaryAttackGame.latestEnemyThreatCountermeasureExecutionResult == nil, "ordinary attack without focused countermeasure should not publish replay")

        let ordinaryReinforceGame = GameState(scenario: enemyThreatIntentScenario(axisSpent: true))
        guard let ordinaryReinforceUnit = ordinaryReinforceGame.units.first(where: { $0.name == "前线装甲" }) else {
            require(false, "ordinary reinforce should find damaged unit")
            return
        }
        ordinaryReinforceGame.handleTap(on: ordinaryReinforceUnit.position)
        ordinaryReinforceGame.reinforceSelectedUnit()
        require(ordinaryReinforceGame.latestReinforcementResult != nil, "ordinary reinforce should still publish reinforcement result")
        require(ordinaryReinforceGame.latestEnemyThreatCountermeasureExecutionResult == nil, "ordinary reinforce without focused countermeasure should not publish replay")
    }

    @MainActor
    private static func verifyCountermeasureFollowUpVerification() {
        func countermeasures(in game: GameState) -> [EnemyThreatCountermeasurePreview] {
            game.enemyThreatCountermeasurePreviews(
                for: game.enemyThreatIntentPreviews(against: .allies, limit: 10),
                limit: 10
            )
        }

        func requireFollowUp(
            in game: GameState,
            for advice: EnemyThreatCountermeasurePreview,
            executionKind: EnemyThreatCountermeasureExecutionKind,
            comparisonTitles: [String]
        ) -> EnemyThreatCountermeasureFollowUpSummary? {
            game.endTurn()
            guard let followUp = game.latestEnemyThreatCountermeasureFollowUpResult,
                  let aiSummary = game.latestAIPhaseSummary else {
                require(false, "countermeasure follow-up should publish after enemy phase")
                return nil
            }
            require(game.latestEnemyThreatCountermeasureExecutionResult == nil, "countermeasure follow-up should not keep immediate replay through end turn")
            require(followUp.countermeasureID == advice.id, "countermeasure follow-up should keep advice id")
            require(followUp.countermeasureKind == advice.kind, "countermeasure follow-up should keep advice kind")
            require(followUp.executionKind == executionKind, "countermeasure follow-up should keep execution kind")
            require(followUp.actingUnitID == advice.actingUnitID, "countermeasure follow-up should keep acting unit id")
            require(followUp.targetUnitID == advice.targetUnitID, "countermeasure follow-up should keep target unit id")
            require(followUp.threatEnemyUnitID == advice.threatEnemyUnitID, "countermeasure follow-up should keep threat unit id")
            require(followUp.threatTargetCoordinate == advice.threatTargetCoordinate, "countermeasure follow-up should keep threat target coordinate")
            require(followUp.aiFaction == .axis, "countermeasure follow-up should bind to axis AI phase")
            require(followUp.aiTurn == aiSummary.turn, "countermeasure follow-up should bind to latest AI summary turn")
            require(!followUp.conclusion.isEmpty, "countermeasure follow-up should include a conclusion")
            require(!followUp.detailSummary.isEmpty, "countermeasure follow-up should include detail summary")
            require(!followUp.outcomeTitle.isEmpty, "countermeasure follow-up should include outcome title")
            require(followUp.focusTargets.contains(where: { $0.kind == .threatEnemy }), "countermeasure follow-up should expose threat focus target")
            require(followUp.focusTargets.contains(where: { $0.kind == .threatenedTarget }), "countermeasure follow-up should expose threatened target focus")
            for title in comparisonTitles {
                require(followUp.comparisons.contains(where: { $0.title == title }), "countermeasure follow-up should include \(title) comparison")
            }
            require(followUp.comparisons.contains(where: { $0.kind == .aiImpact }), "countermeasure follow-up should include AI impact comparison")

            let unitsBeforeFocus = game.units
            let commandPointsBeforeFocus = game.commandPoints
            let aiSummaryBeforeFocus = game.latestAIPhaseSummary
            let followUpBeforeFocus = followUp
            if let focusTarget = followUp.focusTargets.first {
                game.focusEnemyThreatCountermeasureFollowUpTarget(focusTarget)
                require(game.focusedCoordinate != nil, "countermeasure follow-up focus should update map focus")
                require(game.message.contains("复核定位"), "countermeasure follow-up focus should write a focus message")
                require(game.units == unitsBeforeFocus, "countermeasure follow-up focus should not mutate units")
                require(game.commandPoints == commandPointsBeforeFocus, "countermeasure follow-up focus should not mutate command points")
                require(game.latestAIPhaseSummary == aiSummaryBeforeFocus, "countermeasure follow-up focus should not mutate AI summary")
                require(game.latestEnemyThreatCountermeasureFollowUpResult == followUpBeforeFocus, "countermeasure follow-up focus should not mutate follow-up summary")
            }

            return followUp
        }

        let noBaselineGame = GameState(scenario: enemyThreatFollowUpScenario(axisSpent: true))
        noBaselineGame.endTurn()
        require(noBaselineGame.latestEnemyThreatCountermeasureFollowUpResult == nil, "enemy phase without countermeasure replay should not publish follow-up")
        require(noBaselineGame.latestAIPhaseSummary != nil, "enemy phase without follow-up should still publish AI summary")

        let firstStrikeGame = GameState(scenario: enemyThreatFollowUpScenario(axisSpent: true))
        guard let firstStrikeAdvice = countermeasures(in: firstStrikeGame).first(where: {
            $0.kind == .firstStrike &&
                $0.actingUnitName == "反击炮兵" &&
                $0.threatEnemyUnitName == "威胁炮兵"
        }) else {
            require(false, "countermeasure follow-up should find first strike advice")
            return
        }
        firstStrikeGame.focusEnemyThreatCountermeasure(firstStrikeAdvice)
        firstStrikeGame.executeFocusedCommand()
        require(firstStrikeGame.latestEnemyThreatCountermeasureExecutionResult != nil, "first strike should publish immediate replay before follow-up")
        let firstStrikeFollowUp = requireFollowUp(
            in: firstStrikeGame,
            for: firstStrikeAdvice,
            executionKind: .attack,
            comparisonTitles: ["威胁源", "受威胁目标", "AI总览"]
        )
        require(firstStrikeFollowUp?.outcomeLevel != .failed, "first strike follow-up should not classify as failed in smoke scenario")

        let withdrawGame = GameState(scenario: enemyThreatFollowUpScenario(axisSpent: true))
        guard let withdrawAdvice = countermeasures(in: withdrawGame).first(where: {
            $0.kind == .withdraw &&
                $0.actingUnitName == "前线装甲"
        }) else {
            require(false, "countermeasure follow-up should find withdraw advice")
            return
        }
        withdrawGame.focusEnemyThreatCountermeasure(withdrawAdvice)
        withdrawGame.executeFocusedCommand()
        let withdrawFollowUp = requireFollowUp(
            in: withdrawGame,
            for: withdrawAdvice,
            executionKind: .move,
            comparisonTitles: ["撤离位置", "撤离单位", "AI总览"]
        )
        require(withdrawFollowUp?.outcomeLevel != .failed, "withdraw follow-up should not classify as failed in smoke scenario")

        let objectiveGame = GameState(scenario: enemyThreatFollowUpScenario(axisSpent: true))
        guard let objectiveAdvice = countermeasures(in: objectiveGame).first(where: {
            $0.kind == .objectiveDefense &&
                $0.targetName == "后方油库"
        }) else {
            require(false, "countermeasure follow-up should find objective defense advice")
            return
        }
        objectiveGame.focusEnemyThreatCountermeasure(objectiveAdvice)
        objectiveGame.executeFocusedCommand()
        let objectiveFollowUp = requireFollowUp(
            in: objectiveGame,
            for: objectiveAdvice,
            executionKind: .move,
            comparisonTitles: ["据点归属", "防守单位", "AI总览"]
        )
        require(
            objectiveFollowUp?.focusTargets.contains(where: { $0.coordinate == objectiveAdvice.threatTargetCoordinate }) == true,
            "objective follow-up should expose objective coordinate focus"
        )

        let reinforceGame = GameState(scenario: enemyThreatFollowUpScenario(axisSpent: true))
        guard let reinforceAdvice = countermeasures(in: reinforceGame).first(where: {
            $0.kind == .reinforce &&
                $0.actingUnitName == "前线装甲"
        }) else {
            require(false, "countermeasure follow-up should find reinforce advice")
            return
        }
        reinforceGame.focusEnemyThreatCountermeasure(reinforceAdvice)
        reinforceGame.reinforceSelectedUnit()
        let reinforceFollowUp = requireFollowUp(
            in: reinforceGame,
            for: reinforceAdvice,
            executionKind: .reinforce,
            comparisonTitles: ["整补单位", "威胁源", "AI总览"]
        )
        require(reinforceFollowUp?.outcomeLevel.title.isEmpty == false, "reinforce follow-up should expose an outcome level")
        reinforceGame.restart()
        require(reinforceGame.latestEnemyThreatCountermeasureFollowUpResult == nil, "restart should clear countermeasure follow-up")
        if let staleTarget = reinforceFollowUp?.focusTargets.first {
            reinforceGame.focusEnemyThreatCountermeasureFollowUpTarget(staleTarget)
            require(reinforceGame.message.contains("已过期"), "stale follow-up focus should report expiration")
        }
    }

    private static func isolatedSupplyScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<3 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "补给源"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "isolated-supply-test",
            name: "断补给测试",
            year: "1944",
            briefing: "测试断补给。",
            initialFocus: HexCoordinate(q: 2, r: 0),
            mapColumns: 3,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "孤立装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 2, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "靶标步兵",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 2, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "封锁一",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "封锁二",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ]
        )
    }

    private static func commanderAuraScenario(includeCommander: Bool) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<3 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 1 {
                    tile.objectiveName = "指挥阵地"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        var units = [
            BattleUnit(
                name: "受援步兵",
                kind: .infantry,
                faction: .allies,
                position: HexCoordinate(q: 1, r: 0),
                hp: UnitKind.infantry.baseHP,
                commander: nil
            ),
            BattleUnit(
                name: "光环目标",
                kind: .infantry,
                faction: .axis,
                position: HexCoordinate(q: 2, r: 0),
                hp: UnitKind.infantry.baseHP,
                commander: nil
            )
        ]

        if includeCommander {
            units.append(BattleUnit(
                name: "指挥装甲",
                kind: .tank,
                faction: .allies,
                position: HexCoordinate(q: 0, r: 1),
                hp: UnitKind.tank.baseHP,
                commander: .patton
            ))
        }

        return Scenario(
            id: includeCommander ? "commander-aura-test" : "commander-aura-baseline-test",
            name: "将领协同测试",
            year: "1944",
            briefing: "测试相邻将领对友军攻击的协同加成。",
            initialFocus: HexCoordinate(q: 1, r: 0),
            mapColumns: 3,
            mapRows: 2,
            tiles: tiles,
            units: units,
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func objectiveRestScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<2 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .plains
            )
            if q == 0 {
                tile.objectiveName = "休整据点"
                tile.owner = .allies
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "objective-rest-test",
            name: "据点休整测试",
            year: "1944",
            briefing: "测试己方据点自动恢复受损单位。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 2,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "休整守军",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.infantry.baseHP - 18,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func matchupScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<3 {
            for q in 0..<4 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 1 {
                    tile.objectiveName = "测试据点"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "matchup-test",
            name: "兵种克制测试",
            year: "1944",
            briefing: "测试兵种克制。",
            initialFocus: HexCoordinate(q: 0, r: 1),
            mapColumns: 4,
            mapRows: 3,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "克制侦察",
                    kind: .recon,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 1),
                    hp: UnitKind.recon.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "步兵攻击",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "炮兵目标",
                    kind: .artillery,
                    faction: .axis,
                    position: HexCoordinate(q: 2, r: 1),
                    hp: UnitKind.artillery.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "装甲目标",
                    kind: .tank,
                    faction: .axis,
                    position: HexCoordinate(q: 2, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                )
            ]
        )
    }

    private static func terrainMovementScenario(unitKind: UnitKind) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<3 {
            for q in 0..<3 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: q == 1 && r == 1 ? .mountain : .plains
                )
                if q == 0 && r == 1 {
                    tile.objectiveName = "地形测试据点"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "terrain-move-\(unitKind.rawValue)",
            name: "地形移动测试",
            year: "1944",
            briefing: "测试不同兵种进入地形的移动成本。",
            initialFocus: HexCoordinate(q: 0, r: 1),
            mapColumns: 3,
            mapRows: 3,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: unitKind == .tank ? "地形测试坦克" : "地形测试步兵",
                    kind: unitKind,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 1),
                    hp: unitKind.baseHP,
                    commander: nil
                )
            ]
        )
    }

    private static func terrainCombatScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<2 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: q == 0 && r == 1 ? .river : .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "火力测试据点"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "terrain-combat-test",
            name: "地形战斗测试",
            year: "1944",
            briefing: "测试地形适性对战斗预测的影响。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 2,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "地形测试装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "平原目标",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "河流目标",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 0, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ]
        )
    }

    private static func combatResultScenario() -> Scenario {
        var objectiveTile = TerrainTile(
            coordinate: HexCoordinate(q: 2, r: 0),
            terrain: .city
        )
        objectiveTile.objectiveName = "结果据点"
        objectiveTile.owner = nil

        return Scenario(
            id: "combat-result-smoke",
            name: "战斗结果冒烟测试",
            year: "1944",
            briefing: "测试普通攻击后的战损摘要。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 3,
            mapRows: 1,
            tiles: [
                TerrainTile(
                    coordinate: HexCoordinate(q: 0, r: 0),
                    terrain: .road
                ),
                TerrainTile(
                    coordinate: HexCoordinate(q: 1, r: 0),
                    terrain: .road
                ),
                objectiveTile
            ],
            units: [
                BattleUnit(
                    name: "结果攻击方",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil,
                    experience: UnitRank.regular.minimumExperience - 1
                ),
                BattleUnit(
                    name: "结果防守方",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil,
                    isEntrenched: true
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func postMoveAttackScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<5 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "机动出发点"
                tile.owner = .allies
            } else if q == 4 {
                tile.objectiveName = "守军阵地"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "post-move-attack-test",
            name: "移动后攻击预览测试",
            year: "1944",
            briefing: "测试移动预览能显示后续攻击机会。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "机动装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "前方守军",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func safeEngagementScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in -1..<2 {
            for q in 0..<5 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .road
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "接敌出发点"
                    tile.owner = .allies
                } else if q == 4 && r == 0 {
                    tile.objectiveName = "敌方阵地"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "safe-engagement-test",
            name: "安全接敌测试",
            year: "1944",
            briefing: "测试接敌候选会按火力暴露风险排序。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 3,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "接敌装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil,
                    morale: 80
                ),
                BattleUnit(
                    name: "主目标",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "侧翼装甲",
                    kind: .tank,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: -1),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func tacticalCommandScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<5 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: q == 3 && r == 0 ? .city : .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "炮兵阵地"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "tactical-command-test",
            name: "战术命令测试",
            year: "1944",
            briefing: "测试火炮弹幕战术命令。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "弹幕炮兵",
                    kind: .artillery,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.artillery.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "普通步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "弹幕目标",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 3, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ]
        )
    }

    private static func breakthroughAssaultScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<3 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "突击出发点"
                    tile.owner = .allies
                }
                if q == 2 && r == 0 {
                    tile.objectiveName = "敌方阵地"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "breakthrough-assault-test",
            name: "突破突击测试",
            year: "1944",
            briefing: "测试装甲和侦察单位的近距战术命令。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 3,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "突击装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "普通步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 2, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "突破目标",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func maneuverPursuitScenario(attackerKind: UnitKind) -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<5 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "出发据点"
                tile.owner = .allies
            }
            if q == 3 {
                tile.objectiveName = "追击据点"
                tile.owner = nil
            }
            if q == 4 {
                tile.objectiveName = "敌后据点"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "maneuver-pursuit-\(attackerKind.rawValue)-test",
            name: "机动追击测试",
            year: "1944",
            briefing: "测试装甲和侦察击毁后继续移动。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: attackerKind == .infantry ? "追击步兵" : "追击装甲",
                    kind: attackerKind,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: attackerKind.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "追击目标",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: 8,
                    commander: nil
                ),
                BattleUnit(
                    name: "后方守军",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func axisDeploymentResultScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<5 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "盟军后方"
                tile.owner = .allies
            } else if q == 4 {
                tile.objectiveName = "轴心补给点"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "axis-deployment-result-test",
            name: "轴心部署结果测试",
            year: "1944",
            briefing: "测试轴心 AI 部署会写入后勤结果摘要。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "远离前线守军",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func axisReinforcementResultScenario() -> Scenario {
        var axisObjective = TerrainTile(
            coordinate: HexCoordinate(q: 0, r: 0),
            terrain: .plains
        )
        axisObjective.objectiveName = "轴心整补点"
        axisObjective.owner = .axis

        let forwardTile = TerrainTile(
            coordinate: HexCoordinate(q: 1, r: 0),
            terrain: .plains
        )

        return Scenario(
            id: "axis-reinforcement-result-test",
            name: "轴心整补结果测试",
            year: "1944",
            briefing: "测试轴心 AI 主动整补会写入回合摘要。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 2,
            mapRows: 1,
            tiles: [axisObjective, forwardTile],
            units: [
                BattleUnit(
                    name: "受损轴心守军",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.infantry.baseHP - 28,
                    commander: nil
                ),
                BattleUnit(
                    name: "封锁盟军",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func axisTacticalCommandScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<5 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "盟军基地"
                    tile.owner = .allies
                }
                if q == 4 && r == 0 {
                    tile.objectiveName = "轴心炮兵阵地"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "axis-tactical-command-test",
            name: "轴心战术命令测试",
            year: "1944",
            briefing: "测试轴心国 AI 使用火炮弹幕。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "盟军指挥坦克",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: .patton,
                    morale: 82
                ),
                BattleUnit(
                    name: "轴心炮兵",
                    kind: .artillery,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: 0),
                    hp: UnitKind.artillery.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "轴心守军",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 5,
            decisiveTurnLimit: 3,
            survivalStarThreshold: 1
        )
    }

    private static func axisManeuverPursuitScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<5 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "前线据点"
                tile.owner = .allies
            }
            if q == 4 {
                tile.objectiveName = "纵深据点"
                tile.owner = .allies
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "axis-maneuver-pursuit-test",
            name: "轴心机动追击测试",
            year: "1944",
            briefing: "测试轴心 AI 击毁后继续推进但不追加攻击。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "薄弱前哨",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: 8,
                    commander: nil
                ),
                BattleUnit(
                    name: "纵深守军",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 4, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "追击装甲群",
                    kind: .tank,
                    faction: .axis,
                    position: HexCoordinate(q: 2, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func axisPostMoveBarrageScenario() -> Scenario {
        let tiles = (0..<6).map { q in
            TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
        }

        return Scenario(
            id: "axis-post-move-barrage-test",
            name: "轴心移动后弹幕测试",
            year: "1944",
            briefing: "测试轴心火炮移动后进入弹幕射程并压制目标。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 6,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "远距指挥坦克",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: .patton,
                    morale: 82
                ),
                BattleUnit(
                    name: "机动轴心炮兵",
                    kind: .artillery,
                    faction: .axis,
                    position: HexCoordinate(q: 5, r: 0),
                    hp: UnitKind.artillery.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 5,
            decisiveTurnLimit: 3,
            survivalStarThreshold: 1
        )
    }

    private static func axisImmediateObjectiveCaptureScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<5 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "前沿村镇"
                tile.owner = .allies
            }
            if q == 4 {
                tile.objectiveName = "后方据点"
                tile.owner = .allies
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "axis-immediate-objective-capture-test",
            name: "轴心直取据点测试",
            year: "1944",
            briefing: "测试轴心 AI 在无击杀机会时优先夺取可达据点。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "夺点步兵",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "牵制守军",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 2, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func axisFullAdvanceScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<5 {
            tiles.append(TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            ))
        }

        return Scenario(
            id: "axis-full-advance-test",
            name: "轴心全速推进测试",
            year: "1944",
            briefing: "测试轴心国 AI 使用完整移动力进入攻击位置。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "远端步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "突进侦察",
                    kind: .recon,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: 0),
                    hp: UnitKind.recon.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func entrenchmentScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<2 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .plains
            )
            if q == 0 {
                tile.objectiveName = "防御阵地"
                tile.owner = .allies
            }
            if q == 1 {
                tile.objectiveName = "进攻阵地"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "entrenchment-test",
            name: "防御姿态测试",
            year: "1944",
            briefing: "测试待命构筑防御后的减伤和消耗。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 2,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "防御步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "进攻装甲",
                    kind: .tank,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func flankingScenario(supportCount: Int) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<3 {
            for q in 0..<3 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 1 {
                    tile.objectiveName = "协同出发点"
                    tile.owner = .allies
                }
                if q == 2 && r == 1 {
                    tile.objectiveName = "敌方阵地"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        var units = [
            BattleUnit(
                name: "协同装甲",
                kind: .tank,
                faction: .allies,
                position: HexCoordinate(q: 0, r: 1),
                hp: UnitKind.tank.baseHP,
                commander: nil
            ),
            BattleUnit(
                name: "夹击目标",
                kind: .infantry,
                faction: .axis,
                position: HexCoordinate(q: 1, r: 1),
                hp: UnitKind.infantry.baseHP,
                commander: nil
            )
        ]

        let supportPositions = [
            HexCoordinate(q: 1, r: 0),
            HexCoordinate(q: 0, r: 2),
            HexCoordinate(q: 2, r: 0)
        ]
        for index in 0..<min(supportCount, supportPositions.count) {
            units.append(BattleUnit(
                name: "协同支援\(index + 1)",
                kind: index == 0 ? .infantry : .recon,
                faction: .allies,
                position: supportPositions[index],
                hp: index == 0 ? UnitKind.infantry.baseHP : UnitKind.recon.baseHP,
                commander: nil
            ))
        }

        return Scenario(
            id: "flanking-support-\(supportCount)-test",
            name: "夹击协同测试",
            year: "1944",
            briefing: "测试友军围攻目标时的伤害加成。",
            initialFocus: HexCoordinate(q: 0, r: 1),
            mapColumns: 3,
            mapRows: 3,
            tiles: tiles,
            units: units,
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func objectiveRewardScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<3 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .plains
            )
            if q == 0 {
                tile.objectiveName = "后方基地"
                tile.owner = .allies
            }
            if q == 2 {
                tile.objectiveName = "前线村镇"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "objective-reward-test",
            name: "据点奖励测试",
            year: "1944",
            briefing: "测试夺取据点后的即时奖励。",
            initialFocus: HexCoordinate(q: 1, r: 0),
            mapColumns: 3,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "占点步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "远方守军",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 2, r: 0),
                    hp: 0,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func objectiveAdvanceScenario(includeOccupiedDecoy: Bool) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<4 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .road
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "出发据点"
                    tile.owner = .allies
                } else if includeOccupiedDecoy && q == 0 && r == 1 {
                    tile.objectiveName = "占据村镇"
                    tile.owner = .axis
                } else if q == 2 && r == 0 {
                    tile.objectiveName = "前线据点"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        var units = [
            BattleUnit(
                name: "目标推进装甲",
                kind: .tank,
                faction: .allies,
                position: HexCoordinate(q: 0, r: 0),
                hp: UnitKind.tank.baseHP,
                commander: nil
            )
        ]
        if includeOccupiedDecoy {
            units.append(BattleUnit(
                name: "占据守军",
                kind: .infantry,
                faction: .axis,
                position: HexCoordinate(q: 0, r: 1),
                hp: UnitKind.infantry.baseHP,
                commander: nil
            ))
        }

        return Scenario(
            id: "objective-advance-test",
            name: "目标推进测试",
            year: "1944",
            briefing: "测试地图快捷目标推进。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 4,
            mapRows: 2,
            tiles: tiles,
            units: units,
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func distantObjectiveAdvanceScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<6 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "出发据点"
                tile.owner = .allies
            } else if q == 5 {
                tile.objectiveName = "纵深据点"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "distant-objective-advance-test",
            name: "远距目标推进测试",
            year: "1944",
            briefing: "测试目标较远时先给出推进格。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 6,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "目标推进装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func objectiveAdvanceFireRiskScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<4 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "出发据点"
                tile.owner = .allies
            } else if q == 2 {
                tile.objectiveName = "炮火据点"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "objective-advance-fire-risk-test",
            name: "目标火力风险测试",
            year: "1944",
            briefing: "测试目标推进计划显示终点火力风险。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 4,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "冒险装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "火力警戒炮",
                    kind: .artillery,
                    faction: .axis,
                    position: HexCoordinate(q: 3, r: 0),
                    hp: UnitKind.artillery.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func multipleObjectiveAdvancePreviewScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<6 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            switch q {
            case 0:
                tile.objectiveName = "出发据点"
                tile.owner = .allies
            case 1:
                tile.objectiveName = "一号据点"
                tile.owner = .axis
            case 2:
                tile.objectiveName = "二号据点"
                tile.owner = .axis
            case 3:
                tile.objectiveName = "三号据点"
                tile.owner = nil
            case 4:
                tile.objectiveName = "四号据点"
                tile.owner = .axis
            default:
                break
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "multiple-objective-advance-preview-test",
            name: "多目标推进计划测试",
            year: "1944",
            briefing: "测试多个据点推进计划摘要。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 6,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "计划装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func zoneOfControlScenario(includeEnemy: Bool) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<4 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 1 {
                    tile.objectiveName = "接敌出发点"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        var units = [
            BattleUnit(
                name: "接敌侦察",
                kind: .recon,
                faction: .allies,
                position: HexCoordinate(q: 0, r: 1),
                hp: UnitKind.recon.baseHP,
                commander: nil
            )
        ]

        if includeEnemy {
            units.append(BattleUnit(
                name: "控制区守军",
                kind: .infantry,
                faction: .axis,
                position: HexCoordinate(q: 2, r: 0),
                hp: UnitKind.infantry.baseHP,
                commander: nil
            ))
        }

        return Scenario(
            id: includeEnemy ? "zoc-contested-test" : "zoc-open-test",
            name: "控制区测试",
            year: "1944",
            briefing: "测试敌方控制区对移动范围的影响。",
            initialFocus: HexCoordinate(q: 0, r: 1),
            mapColumns: 4,
            mapRows: 2,
            tiles: tiles,
            units: units,
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func enemyThreatFollowUpScenario(axisSpent: Bool = false) -> Scenario {
        var scenario = enemyThreatIntentScenario(axisSpent: axisSpent)
        if let index = scenario.tiles.firstIndex(where: { $0.coordinate == HexCoordinate(q: 0, r: 2) }) {
            scenario.tiles[index].objectiveName = "未夺取补给点"
            scenario.tiles[index].owner = nil
        }
        return scenario
    }

    private static func enemyThreatIntentScenario(axisSpent: Bool = false) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<3 {
            for q in 0..<5 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .road
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "盟军出发点"
                    tile.owner = .allies
                }
                if q == 1 && r == 0 {
                    tile.objectiveName = "前线阵地"
                    tile.owner = .allies
                }
                if q == 2 && r == 2 {
                    tile.objectiveName = "后方油库"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        var artillery = BattleUnit(
            name: "威胁炮兵",
            kind: .artillery,
            faction: .axis,
            position: HexCoordinate(q: 4, r: 0),
            hp: UnitKind.artillery.baseHP,
            commander: nil
        )
        var recon = BattleUnit(
            name: "突击侦察",
            kind: .recon,
            faction: .axis,
            position: HexCoordinate(q: 4, r: 1),
            hp: UnitKind.recon.baseHP,
            commander: nil
        )
        var infantry = BattleUnit(
            name: "夺点步兵",
            kind: .infantry,
            faction: .axis,
            position: HexCoordinate(q: 4, r: 2),
            hp: UnitKind.infantry.baseHP,
            commander: nil
        )

        if axisSpent {
            artillery.hasMoved = true
            artillery.hasAttacked = true
            recon.hasMoved = true
            recon.hasAttacked = true
            infantry.hasMoved = true
            infantry.hasAttacked = true
        }

        return Scenario(
            id: "enemy-threat-intent-test",
            name: "敌方意图测试",
            year: "1944",
            briefing: "测试敌方直接攻击、接敌攻击和据点占领预判。",
            initialFocus: HexCoordinate(q: 1, r: 0),
            mapColumns: 5,
            mapRows: 3,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "前线装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: 28,
                    commander: .patton
                ),
                BattleUnit(
                    name: "后方步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 1, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "反击炮兵",
                    kind: .artillery,
                    faction: .allies,
                    position: HexCoordinate(q: 2, r: 0),
                    hp: UnitKind.artillery.baseHP,
                    commander: nil
                ),
                artillery,
                recon,
                infantry
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func missionStarScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<3 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 1 && r == 0 {
                    tile.objectiveName = "任务据点"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "mission-star-test",
            name: "三星测试",
            year: "1944",
            briefing: "测试任务星级。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 3,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "任务装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "远方守军",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 2, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 4,
            decisiveTurnLimit: 2,
            survivalStarThreshold: 1
        )
    }

    private static func missionTimeoutScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<3 {
            for q in 0..<5 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "待夺取据点"
                    tile.owner = nil
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "mission-timeout-test",
            name: "期限测试",
            year: "1944",
            briefing: "测试任务期限。",
            initialFocus: HexCoordinate(q: 0, r: 1),
            mapColumns: 5,
            mapRows: 3,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "拖延步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "远方敌军",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 4, r: 2),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ],
            turnLimit: 1,
            decisiveTurnLimit: 1,
            survivalStarThreshold: 1
        )
    }

    private static func moraleCombatScenario(attackerMorale: Int, defenderMorale: Int = 60) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<3 {
            for q in 0..<5 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 1 {
                    tile.objectiveName = "前进基地"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "morale-combat-test",
            name: "士气战斗测试",
            year: "1944",
            briefing: "测试士气对移动和攻击的影响。",
            initialFocus: HexCoordinate(q: 0, r: 1),
            mapColumns: 5,
            mapRows: 3,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "士气装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 1),
                    hp: UnitKind.tank.baseHP,
                    commander: nil,
                    morale: attackerMorale
                ),
                BattleUnit(
                    name: "目标守军",
                    kind: .tank,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 1),
                    hp: UnitKind.tank.baseHP,
                    commander: nil,
                    morale: defenderMorale
                )
            ]
        )
    }

    private static func moraleMovementScenario(unitMorale: Int) -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<3 {
            for q in 0..<5 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 1 {
                    tile.objectiveName = "行军基地"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "morale-movement-test",
            name: "士气移动测试",
            year: "1944",
            briefing: "测试士气对无接敌行军范围的影响。",
            initialFocus: HexCoordinate(q: 0, r: 1),
            mapColumns: 5,
            mapRows: 3,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "士气行军装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 1),
                    hp: UnitKind.tank.baseHP,
                    commander: nil,
                    morale: unitMorale
                )
            ]
        )
    }

    private static func moraleRecoveryScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<2 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "休整据点"
                    tile.owner = .allies
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "morale-recovery-test",
            name: "士气恢复测试",
            year: "1944",
            briefing: "测试补给据点恢复士气。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 2,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "休整步兵",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil,
                    morale: 20,
                    hasMoved: true,
                    hasAttacked: true
                )
            ]
        )
    }
}
