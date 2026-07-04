import XCTest
@testable import WW2Tactics

@MainActor
final class GameStateTests: XCTestCase {
    func testScenarioIncludesWW2TacticsRequirements() {
        let game = GameState()

        XCTAssertEqual(game.scenario.name, "阿登反击战")
        XCTAssertEqual(game.tiles.count, game.scenario.mapColumns * game.scenario.mapRows)
        XCTAssertGreaterThanOrEqual(game.scenario.mapColumns, 22)
        XCTAssertGreaterThanOrEqual(game.scenario.mapRows, 14)
        XCTAssertEqual(game.objectiveTiles.count, 14)
        XCTAssertTrue(game.objectiveTiles.contains { $0.objectiveName == "南部桥头堡" })
        XCTAssertTrue(game.objectiveTiles.contains { $0.objectiveName == "莱茵补给线" })
        XCTAssertTrue(game.objectiveTiles.contains { $0.objectiveName == "默兹渡口" })
        XCTAssertTrue(game.objectiveTiles.contains { $0.objectiveName == "鲁尔工业区" })
        XCTAssertTrue(game.units.contains { $0.kind == .tank })
        XCTAssertTrue(game.units.contains { $0.kind == .infantry })
        XCTAssertTrue(game.units.contains { $0.kind == .artillery })
        XCTAssertTrue(game.units.contains { $0.kind == .recon })
        XCTAssertGreaterThanOrEqual(game.units(for: .allies).count, 12)
        XCTAssertGreaterThanOrEqual(game.units(for: .axis).count, 15)
        XCTAssertGreaterThanOrEqual(game.units.compactMap(\.commander).count, 4)
    }

    func testStartingObjectiveOwnersMatchOccupyingUnits() {
        let game = GameState()

        for objective in game.objectiveTiles {
            guard let unit = game.unit(at: objective.coordinate) else { continue }
            XCTAssertEqual(
                objective.owner,
                unit.faction,
                "\(objective.objectiveName ?? objective.id) starts occupied by \(unit.name), so owner should match the occupying faction"
            )
        }
    }

    func testMapEnemyFocusListExposesAllEnemiesSortedByCurrentAnchor() throws {
        let game = GameState()
        let axisUnits = game.units(for: .axis)

        XCTAssertEqual(Set(game.mapEnemyFocusUnits.map(\.id)), Set(axisUnits.map(\.id)))
        XCTAssertEqual(game.mapEnemyFocusUnits.count, 15)

        let initialAnchor = game.focusedCoordinate ?? game.scenario.initialFocus
        let initialDistances = game.mapEnemyFocusUnits.map { initialAnchor.distance(to: $0.position) }
        XCTAssertEqual(initialDistances, initialDistances.sorted())

        let tank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })
        game.select(unitID: tank.id)

        let selectedDistances = game.mapEnemyFocusUnits.map { tank.position.distance(to: $0.position) }
        XCTAssertEqual(selectedDistances, selectedDistances.sorted())
    }

    func testMapFriendlyFocusListExposesAllAlliesAndPrioritizesReadyUnits() throws {
        var scenario = Scenario.ardennesPrototype()
        let spentIndex = try XCTUnwrap(scenario.units.firstIndex { $0.name == "第101空降师" })
        scenario.units[spentIndex].hasMoved = true
        scenario.units[spentIndex].hasAttacked = true

        let game = GameState(scenario: scenario)
        let alliedUnits = game.units(for: .allies)

        XCTAssertEqual(Set(game.mapFriendlyFocusUnits.map(\.id)), Set(alliedUnits.map(\.id)))
        XCTAssertEqual(game.mapFriendlyFocusUnits.count, 12)
        XCTAssertEqual(game.mapFriendlyFocusUnits.last?.name, "第101空降师")
        XCTAssertTrue(game.mapFriendlyFocusUnits.dropLast().allSatisfy { !$0.hasMoved || !$0.hasAttacked })

        let tank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })
        game.select(unitID: tank.id)

        let readyUnits = game.mapFriendlyFocusUnits.filter { !$0.hasMoved || !$0.hasAttacked }
        let selectedDistances = readyUnits.map { tank.position.distance(to: $0.position) }
        XCTAssertEqual(selectedDistances, selectedDistances.sorted())
    }

    func testCampaignCatalogIncludesMultipleWW2Scenarios() {
        let game = GameState()

        XCTAssertGreaterThanOrEqual(game.campaignCatalog.count, 2)
        XCTAssertTrue(game.campaignCatalog.contains { $0.name == "阿登反击战" })
        XCTAssertTrue(game.campaignCatalog.contains { $0.name == "诺曼底突破" })

        let normandy = Scenario.normandyBreakout()
        XCTAssertEqual(normandy.tiles.count, normandy.mapColumns * normandy.mapRows)
        XCTAssertGreaterThanOrEqual(normandy.tiles.filter(\.isObjective).count, 4)
        XCTAssertTrue(normandy.units.contains { $0.kind == .tank && $0.faction == .allies })
        XCTAssertTrue(normandy.units.contains { $0.kind == .artillery && $0.faction == .axis })
    }

    func testSelectingScenarioResetsBattleState() throws {
        let game = GameState()
        let tank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })
        game.handleTap(on: tank.position)
        game.deploy(kind: .infantry, at: try XCTUnwrap(game.deploymentSites(for: .allies).first).coordinate)

        game.selectScenario(id: "normandy-1944")

        XCTAssertEqual(game.scenario.name, "诺曼底突破")
        XCTAssertEqual(game.turn, 1)
        XCTAssertNil(game.selectedUnit)
        XCTAssertEqual(game.activeFaction, .allies)
        XCTAssertEqual(game.focusedCoordinate, game.scenario.initialFocus)
        XCTAssertEqual(game.commandPoints(for: .allies), 6)
        XCTAssertTrue(game.message.contains("诺曼底突破"))
        XCTAssertTrue(game.battleLog.first?.contains("诺曼底突破") == true)
    }

    func testRestartKeepsCurrentScenario() {
        let game = GameState()
        game.selectScenario(id: "normandy-1944")
        game.endTurn()

        game.restart()

        XCTAssertEqual(game.scenario.id, "normandy-1944")
        XCTAssertEqual(game.turn, 1)
        XCTAssertEqual(game.focusedCoordinate, Scenario.normandyBreakout().initialFocus)
        XCTAssertEqual(game.commandPoints(for: .allies), 6)
    }

    func testCommanderBonusesAffectUnits() throws {
        let game = GameState()

        let pattonTank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })
        XCTAssertEqual(pattonTank.commander?.name, "巴顿")
        XCTAssertGreaterThan(pattonTank.attack, UnitKind.tank.baseAttack)

        let guderianTank = try XCTUnwrap(game.units.first { $0.name == "第2装甲集团" })
        XCTAssertEqual(guderianTank.commander?.name, "古德里安")
        XCTAssertGreaterThan(guderianTank.movement, UnitKind.tank.movement)
    }

    func testAdjacentCommanderAuraBoostsFriendlyAttackPreview() throws {
        let baselineGame = GameState(scenario: Self.commanderAuraScenario(includeCommander: false))
        let baselineAttacker = try XCTUnwrap(baselineGame.units.first { $0.name == "受援步兵" })
        let baselineTarget = try XCTUnwrap(baselineGame.units.first { $0.name == "光环目标" })
        let baselinePreview = try XCTUnwrap(baselineGame.combatPreview(attacker: baselineAttacker, defender: baselineTarget))

        let game = GameState(scenario: Self.commanderAuraScenario(includeCommander: true))
        let attacker = try XCTUnwrap(game.units.first { $0.name == "受援步兵" })
        let target = try XCTUnwrap(game.units.first { $0.name == "光环目标" })
        let preview = try XCTUnwrap(game.combatPreview(attacker: attacker, defender: target))

        XCTAssertEqual(game.commanderSupport(attacker: attacker)?.name, "巴顿")
        XCTAssertEqual(preview.commanderSupportName, "巴顿")
        XCTAssertEqual(preview.commanderSupportBonusPercent, 8)
        XCTAssertEqual(preview.commanderSupportTitle, "将领协同")
        XCTAssertTrue(preview.commanderSupportDetail.contains("+8%"))
        XCTAssertGreaterThan(preview.damage, baselinePreview.damage)
        XCTAssertTrue(game.commanderAuraSummary.contains("+8%"))
    }

    func testVeteranExperienceImprovesUnitStats() {
        let rookie = BattleUnit(
            name: "测试新兵",
            kind: .infantry,
            faction: .allies,
            position: HexCoordinate(q: 0, r: 0),
            hp: UnitKind.infantry.baseHP,
            commander: nil
        )
        let veteran = BattleUnit(
            name: "测试老兵",
            kind: .infantry,
            faction: .allies,
            position: HexCoordinate(q: 0, r: 0),
            hp: UnitKind.infantry.baseHP,
            commander: nil,
            experience: UnitRank.veteran.minimumExperience
        )

        XCTAssertEqual(rookie.rank, .green)
        XCTAssertEqual(veteran.rank, .veteran)
        XCTAssertGreaterThan(veteran.attack, rookie.attack)
        XCTAssertGreaterThan(veteran.maxHP, rookie.maxHP)
    }

    func testOperationalOverviewValuesAreAvailable() {
        let game = GameState()

        XCTAssertEqual(game.alliedScore, 2)
        XCTAssertEqual(game.axisScore, 7)
        XCTAssertEqual(game.objectiveProgress, 2.0 / 14.0, accuracy: 0.001)
        XCTAssertGreaterThan(game.alliedStrength, 0)
        XCTAssertGreaterThan(game.axisStrength, 0)
        XCTAssertEqual(game.units(for: .allies).count, 12)
        XCTAssertEqual(game.units(for: .axis).count, 15)
        XCTAssertEqual(game.commandPoints(for: .allies), 6)
        XCTAssertEqual(game.commandIncome(for: .allies), 7)
        XCTAssertEqual(game.remainingTurns, game.scenario.turnLimit)
        XCTAssertEqual(game.earnedStars, 0)
        XCTAssertEqual(game.missionObjectives.count, 3)
        XCTAssertTrue(game.missionObjectives.allSatisfy { $0.state == .pending })
    }

    func testMissionObjectivesAwardStarsOnFastVictory() throws {
        let game = GameState(scenario: Self.missionStarScenario())
        let attacker = try XCTUnwrap(game.units.first { $0.name == "任务装甲" })

        game.handleTap(on: attacker.position)
        game.handleTap(on: HexCoordinate(q: 1, r: 0))

        XCTAssertEqual(game.winner, .allies)
        XCTAssertEqual(game.earnedStars, 3)
        XCTAssertEqual(game.remainingTurns, game.scenario.turnLimit)
        XCTAssertTrue(game.message.contains("3 星"))
        XCTAssertTrue(game.missionObjectives.allSatisfy { $0.state == .complete })
    }

    func testMissionTimerFailsScenarioAfterTurnLimit() {
        let game = GameState(scenario: Self.missionTimeoutScenario())

        game.endTurn()

        XCTAssertEqual(game.winner, .axis)
        XCTAssertEqual(game.earnedStars, 0)
        XCTAssertEqual(game.remainingTurns, 0)
        XCTAssertTrue(game.message.contains("超过 1 回合期限"))
        XCTAssertTrue(game.missionObjectives.contains { $0.id == "primary" && $0.state == .failed })
    }

    func testSupplyLineConnectsUnitsToOwnedObjectives() throws {
        let game = GameState()
        let infantry = try XCTUnwrap(game.units.first { $0.name == "第101空降师" })
        let tank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })

        XCTAssertEqual(game.supplyState(for: infantry), .supplied)
        XCTAssertEqual(game.supplyState(for: tank), .supplied)
        XCTAssertFalse(game.supplyLineTiles(for: tank).isEmpty)
    }

    func testIsolatedUnitsLoseMovementDamageAndTakeAttrition() throws {
        let scenario = Self.supplyTestScenario()
        let suppliedGame = GameState(scenario: scenario)
        let suppliedTank = try XCTUnwrap(suppliedGame.units.first { $0.name == "补给装甲" })
        let defender = try XCTUnwrap(suppliedGame.units.first { $0.name == "目标步兵" })
        let suppliedPreview = try XCTUnwrap(suppliedGame.combatPreview(attacker: suppliedTank, defender: defender))

        var isolatedScenario = scenario
        isolatedScenario.units.append(BattleUnit(
            name: "封锁一",
            kind: .infantry,
            faction: .axis,
            position: HexCoordinate(q: 1, r: 0),
            hp: UnitKind.infantry.baseHP,
            commander: nil
        ))
        isolatedScenario.units.append(BattleUnit(
            name: "封锁二",
            kind: .infantry,
            faction: .axis,
            position: HexCoordinate(q: 1, r: 1),
            hp: UnitKind.infantry.baseHP,
            commander: nil
        ))
        let isolatedGame = GameState(scenario: isolatedScenario)
        let isolatedTank = try XCTUnwrap(isolatedGame.units.first { $0.name == "补给装甲" })
        let isolatedDefender = try XCTUnwrap(isolatedGame.units.first { $0.name == "目标步兵" })
        let isolatedPreview = try XCTUnwrap(isolatedGame.combatPreview(attacker: isolatedTank, defender: isolatedDefender))
        let reachableBeforeAttrition = isolatedGame.reachableTiles(for: isolatedTank).count

        XCTAssertEqual(isolatedGame.supplyState(for: isolatedTank), .isolated)
        XCTAssertTrue(isolatedGame.supplyLineTiles(for: isolatedTank).isEmpty)
        XCTAssertLessThan(reachableBeforeAttrition, suppliedGame.reachableTiles(for: suppliedTank).count)
        XCTAssertLessThan(isolatedPreview.damage, suppliedPreview.damage)

        let hpBeforeAttrition = isolatedTank.hp
        isolatedGame.endTurn()
        let attritedTank = try XCTUnwrap(isolatedGame.units.first { $0.id == isolatedTank.id })
        XCTAssertLessThan(attritedTank.hp, hpBeforeAttrition)
        XCTAssertTrue(isolatedGame.battleLog.contains { $0.contains("断补给") })
    }

    func testMoraleStateAffectsMovementAndDamage() throws {
        let inspiredGame = GameState(scenario: Self.moraleCombatScenario(attackerMorale: 90))
        let shakenGame = GameState(scenario: Self.moraleCombatScenario(attackerMorale: 20))
        let inspiredMovementGame = GameState(scenario: Self.moraleMovementScenario(unitMorale: 90))
        let shakenMovementGame = GameState(scenario: Self.moraleMovementScenario(unitMorale: 20))
        let inspiredTank = try XCTUnwrap(inspiredGame.units.first { $0.name == "士气装甲" })
        let shakenTank = try XCTUnwrap(shakenGame.units.first { $0.name == "士气装甲" })
        let inspiredMover = try XCTUnwrap(inspiredMovementGame.units.first { $0.name == "士气行军装甲" })
        let shakenMover = try XCTUnwrap(shakenMovementGame.units.first { $0.name == "士气行军装甲" })
        let inspiredTarget = try XCTUnwrap(inspiredGame.units.first { $0.name == "目标守军" })
        let shakenTarget = try XCTUnwrap(shakenGame.units.first { $0.name == "目标守军" })
        let inspiredPreview = try XCTUnwrap(inspiredGame.combatPreview(attacker: inspiredTank, defender: inspiredTarget))
        let shakenPreview = try XCTUnwrap(shakenGame.combatPreview(attacker: shakenTank, defender: shakenTarget))

        XCTAssertEqual(inspiredTank.moraleState, .inspired)
        XCTAssertEqual(shakenTank.moraleState, .shaken)
        XCTAssertGreaterThan(inspiredPreview.damage, shakenPreview.damage)
        XCTAssertGreaterThan(inspiredMovementGame.reachableTiles(for: inspiredMover).count, shakenMovementGame.reachableTiles(for: shakenMover).count)
    }

    func testTacticalStatusAffectsMovementDamageAndClearsAfterAction() throws {
        var suppressedMovementScenario = Self.moraleMovementScenario(unitMorale: 60)
        let suppressedMoverIndex = try XCTUnwrap(suppressedMovementScenario.units.firstIndex { $0.name == "士气行军装甲" })
        suppressedMovementScenario.units[suppressedMoverIndex].tacticalStatus = .suppressed

        let baselineMovementGame = GameState(scenario: Self.moraleMovementScenario(unitMorale: 60))
        let suppressedMovementGame = GameState(scenario: suppressedMovementScenario)
        let baselineMover = try XCTUnwrap(baselineMovementGame.units.first { $0.name == "士气行军装甲" })
        let suppressedMover = try XCTUnwrap(suppressedMovementGame.units.first { $0.name == "士气行军装甲" })

        XCTAssertEqual(suppressedMover.tacticalStatus, .suppressed)
        XCTAssertLessThan(suppressedMovementGame.reachableTiles(for: suppressedMover).count, baselineMovementGame.reachableTiles(for: baselineMover).count)

        var suppressedCombatScenario = Self.moraleCombatScenario(attackerMorale: 60)
        let suppressedAttackerIndex = try XCTUnwrap(suppressedCombatScenario.units.firstIndex { $0.name == "士气装甲" })
        suppressedCombatScenario.units[suppressedAttackerIndex].tacticalStatus = .suppressed

        let baselineCombatGame = GameState(scenario: Self.moraleCombatScenario(attackerMorale: 60))
        let suppressedCombatGame = GameState(scenario: suppressedCombatScenario)
        let baselineAttacker = try XCTUnwrap(baselineCombatGame.units.first { $0.name == "士气装甲" })
        let baselineTarget = try XCTUnwrap(baselineCombatGame.units.first { $0.name == "目标守军" })
        let suppressedAttacker = try XCTUnwrap(suppressedCombatGame.units.first { $0.name == "士气装甲" })
        let suppressedTarget = try XCTUnwrap(suppressedCombatGame.units.first { $0.name == "目标守军" })
        let baselinePreview = try XCTUnwrap(baselineCombatGame.combatPreview(attacker: baselineAttacker, defender: baselineTarget))
        let suppressedPreview = try XCTUnwrap(suppressedCombatGame.combatPreview(attacker: suppressedAttacker, defender: suppressedTarget))

        XCTAssertLessThan(suppressedPreview.damage, baselinePreview.damage)

        let destination = try XCTUnwrap(suppressedMovementGame.reachableTiles(for: suppressedMover).sorted { $0.id < $1.id }.first)
        suppressedMovementGame.handlePrimaryAction(on: suppressedMover.position)
        suppressedMovementGame.handleSecondaryAction(on: destination)

        let movedUnit = try XCTUnwrap(suppressedMovementGame.units.first { $0.id == suppressedMover.id })
        XCTAssertEqual(movedUnit.tacticalStatus, .normal)
    }

    func testCombatChangesMoraleAndSuppliedUnitsRecoverOnNewTurn() throws {
        let combatGame = GameState(scenario: Self.moraleCombatScenario(attackerMorale: 60, defenderMorale: 60))
        let attacker = try XCTUnwrap(combatGame.units.first { $0.name == "士气装甲" })
        let defender = try XCTUnwrap(combatGame.units.first { $0.name == "目标守军" })

        combatGame.handleTap(on: attacker.position)
        combatGame.handleTap(on: defender.position)

        let attackerAfterAttack = try XCTUnwrap(combatGame.units.first { $0.id == attacker.id })
        let defenderAfterAttack = try XCTUnwrap(combatGame.units.first { $0.id == defender.id })
        XCTAssertGreaterThan(attackerAfterAttack.morale, attacker.morale)
        XCTAssertLessThan(defenderAfterAttack.morale, defender.morale)

        let recoveryGame = GameState(scenario: Self.moraleRecoveryScenario())
        let tiredUnit = try XCTUnwrap(recoveryGame.units.first { $0.name == "休整步兵" })
        recoveryGame.endTurn()

        let recoveredUnit = try XCTUnwrap(recoveryGame.units.first { $0.id == tiredUnit.id })
        XCTAssertEqual(recoveredUnit.morale, tiredUnit.morale + 10)
        XCTAssertEqual(recoveredUnit.moraleState, .shaken)
    }

    func testWaitingEntrenchesUnitAndReducesNextIncomingDamage() throws {
        let baselineGame = GameState(scenario: Self.entrenchmentScenario())
        let baselineDefender = try XCTUnwrap(baselineGame.units.first { $0.name == "防御步兵" })
        let baselineAttacker = try XCTUnwrap(baselineGame.units.first { $0.name == "进攻装甲" })
        let baselinePreview = try XCTUnwrap(baselineGame.combatPreview(attacker: baselineAttacker, defender: baselineDefender))

        let game = GameState(scenario: Self.entrenchmentScenario())
        let defender = try XCTUnwrap(game.units.first { $0.name == "防御步兵" })
        let attacker = try XCTUnwrap(game.units.first { $0.name == "进攻装甲" })

        game.handleTap(on: defender.position)
        game.waitSelectedUnit()

        let entrenchedDefender = try XCTUnwrap(game.units.first { $0.id == defender.id })
        let entrenchedPreview = try XCTUnwrap(game.combatPreview(attacker: attacker, defender: entrenchedDefender))
        XCTAssertTrue(entrenchedDefender.isEntrenched)
        XCTAssertTrue(entrenchedPreview.defenderIsEntrenched)
        XCTAssertEqual(entrenchedPreview.defenseMultiplierPercent, 75)
        XCTAssertLessThan(entrenchedPreview.damage, baselinePreview.damage)
        XCTAssertTrue(game.entrenchmentSummary.contains("75%"))
        XCTAssertTrue(game.battleLog.contains { $0.contains("构筑防御姿态") })

        game.endTurn()

        if game.winner == nil {
            let defenderAfterAttack = try XCTUnwrap(game.units.first { $0.id == defender.id })
            let hpAfterIncomingAttack = defender.hp - entrenchedPreview.damage
            let expectedObjectiveRest = min(10, defender.maxHP - hpAfterIncomingAttack)
            XCTAssertEqual(defenderAfterAttack.hp, hpAfterIncomingAttack + expectedObjectiveRest)
            XCTAssertFalse(defenderAfterAttack.isEntrenched)
            XCTAssertTrue(game.battleLog.contains { $0.contains("恢复 \(expectedObjectiveRest) 耐久") })
        }
    }

    func testFlankingSupportIncreasesCombatDamageAndPreview() throws {
        let baselineGame = GameState(scenario: Self.flankingScenario(supportCount: 0))
        let baselineAttacker = try XCTUnwrap(baselineGame.units.first { $0.name == "协同装甲" })
        let baselineTarget = try XCTUnwrap(baselineGame.units.first { $0.name == "夹击目标" })
        let baselinePreview = try XCTUnwrap(baselineGame.combatPreview(attacker: baselineAttacker, defender: baselineTarget))

        let game = GameState(scenario: Self.flankingScenario(supportCount: 2))
        let attacker = try XCTUnwrap(game.units.first { $0.name == "协同装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "夹击目标" })
        let preview = try XCTUnwrap(game.combatPreview(attacker: attacker, defender: target))

        XCTAssertEqual(game.flankingSupportUnits(attacker: attacker, defender: target).count, 2)
        XCTAssertEqual(preview.supportUnitCount, 2)
        XCTAssertEqual(preview.supportDamageBonusPercent, 20)
        XCTAssertEqual(preview.supportTitle, "夹击协同")
        XCTAssertTrue(preview.supportDetail.contains("+20%"))
        XCTAssertGreaterThan(preview.damage, baselinePreview.damage)
        XCTAssertTrue(game.flankingSupportSummary.contains("+10%"))

        game.handleTap(on: attacker.position)
        game.handleTap(on: target.position)

        let targetAfterAttack = try XCTUnwrap(game.units.first { $0.id == target.id })
        XCTAssertEqual(targetAfterAttack.hp, target.hp - preview.damage)
        XCTAssertTrue(game.battleLog.contains { $0.contains("夹击 +20%") })
    }

    func testCommandPointsIncreaseOnNewPlayerTurn() {
        let game = GameState()
        let startingPoints = game.commandPoints(for: .allies)

        game.endTurn()

        if game.winner == nil {
            XCTAssertEqual(game.commandPoints(for: .allies), startingPoints + game.commandIncome(for: .allies))
        }
    }

    func testCapturingObjectiveAwardsImmediateResourcesMoraleAndExperience() throws {
        let game = GameState(
            scenario: Self.objectiveRewardScenario(),
            commandPoints: [.allies: 4, .axis: 6]
        )
        let infantry = try XCTUnwrap(game.units.first { $0.name == "占点步兵" })
        let objective = HexCoordinate(q: 2, r: 0)

        game.handleTap(on: infantry.position)
        game.handleTap(on: objective)

        let infantryAfterCapture = try XCTUnwrap(game.units.first { $0.id == infantry.id })
        XCTAssertEqual(game.tile(at: objective)?.owner, .allies)
        XCTAssertEqual(game.commandPoints(for: .allies), 7)
        XCTAssertEqual(infantryAfterCapture.morale, infantry.morale + 8)
        XCTAssertEqual(infantryAfterCapture.experience, infantry.experience + 10)
        XCTAssertTrue(game.objectiveCaptureRewardSummary.contains("指令 +3"))
        XCTAssertTrue(game.battleLog.contains { $0.contains("夺取前线村镇") })

        let summary = try XCTUnwrap(game.latestObjectiveCaptureResult)
        XCTAssertEqual(summary.objectiveName, "前线村镇")
        XCTAssertEqual(summary.coordinate, objective)
        XCTAssertEqual(summary.capturingUnitName, "占点步兵")
        XCTAssertEqual(summary.capturingUnitKind, .infantry)
        XCTAssertEqual(summary.previousOwner, .axis)
        XCTAssertEqual(summary.newOwner, .allies)
        XCTAssertEqual(summary.commandPointReward, 3)
        XCTAssertEqual(summary.moraleReward, 8)
        XCTAssertEqual(summary.experienceReward, 10)
        XCTAssertEqual(summary.alliedScoreAfterCapture, game.alliedScore)
        XCTAssertEqual(summary.axisScoreAfterCapture, game.axisScore)
        XCTAssertEqual(summary.totalObjectiveCount, game.objectiveTiles.count)
    }

    func testCapturingNeutralObjectiveRecordsCaptureSummary() throws {
        var scenario = Self.objectiveRewardScenario()
        let objective = HexCoordinate(q: 2, r: 0)
        let objectiveIndex = try XCTUnwrap(scenario.tiles.firstIndex { $0.coordinate == objective })
        scenario.tiles[objectiveIndex].owner = nil

        let game = GameState(
            scenario: scenario,
            commandPoints: [.allies: 4, .axis: 6]
        )
        let infantry = try XCTUnwrap(game.units.first { $0.name == "占点步兵" })

        game.handleTap(on: infantry.position)
        game.handleTap(on: objective)

        let summary = try XCTUnwrap(game.latestObjectiveCaptureResult)
        XCTAssertNil(summary.previousOwner)
        XCTAssertEqual(summary.actionTitle, "占领")
        XCTAssertEqual(summary.ownerTransitionText, "中立 -> 盟军")
    }

    func testOwnedObjectiveRestRecoversDamagedSuppliedUnitOnNewTurn() throws {
        let game = GameState(
            scenario: Self.objectiveRestScenario(),
            commandPoints: [.allies: 6, .axis: 0]
        )
        let restingInfantry = try XCTUnwrap(game.units.first { $0.name == "休整守军" })

        XCTAssertEqual(game.objectiveRestRecovery(for: restingInfantry), 10)
        XCTAssertTrue(game.objectiveRestSummary.contains("+10"))

        game.endTurn()

        if game.winner == nil {
            let recoveredInfantry = try XCTUnwrap(game.units.first { $0.id == restingInfantry.id })
            XCTAssertEqual(recoveredInfantry.hp, restingInfantry.hp + 10)
            XCTAssertTrue(game.battleLog.contains { $0.contains("恢复 10 耐久") })
        }
    }

    func testDeployingReinforcementConsumesCommandPointsAndAddsUnit() throws {
        let game = GameState()
        let site = try XCTUnwrap(game.deploymentSites(for: .allies).first)
        let startingPoints = game.commandPoints(for: .allies)
        let startingCount = game.units(for: .allies).count

        game.deploy(kind: .infantry, at: site.coordinate)

        XCTAssertEqual(game.commandPoints(for: .allies), startingPoints - UnitKind.infantry.commandCost)
        XCTAssertEqual(game.units(for: .allies).count, startingCount + 1)
        XCTAssertEqual(game.selectedUnit?.position, site.coordinate)
        XCTAssertEqual(game.selectedUnit?.kind, .infantry)
        XCTAssertTrue(game.selectedUnit?.hasMoved == true)
        XCTAssertTrue(game.selectedUnit?.hasAttacked == true)

        let deployedUnit = try XCTUnwrap(game.selectedUnit)
        let result = try XCTUnwrap(game.latestDeploymentResult)
        XCTAssertEqual(result.unitID, deployedUnit.id)
        XCTAssertEqual(result.unitName, deployedUnit.name)
        XCTAssertEqual(result.unitKind, .infantry)
        XCTAssertEqual(result.faction, .allies)
        XCTAssertEqual(result.coordinate, site.coordinate)
        XCTAssertEqual(result.sourceObjectiveName, site.sourceObjectiveName)
        XCTAssertEqual(result.commandCost, UnitKind.infantry.commandCost)
        XCTAssertEqual(result.commandPointsAfterDeployment, game.commandPoints(for: .allies))
        XCTAssertNil(game.latestCombatResult)
        XCTAssertNil(game.latestTacticalCommandResult)
        XCTAssertNil(game.latestObjectiveCaptureResult)
        XCTAssertNil(game.latestReinforcementResult)
    }

    func testReinforcingDamagedUnitAtOwnedObjectiveConsumesCommandPoints() throws {
        var scenario = Scenario.ardennesPrototype()
        guard let infantryIndex = scenario.units.firstIndex(where: { $0.name == "第101空降师" }) else {
            XCTFail("Infantry should exist")
            return
        }
        scenario.units[infantryIndex].hp = 42
        let game = GameState(scenario: scenario)
        let infantry = try XCTUnwrap(game.units.first { $0.name == "第101空降师" })
        game.handleTap(on: infantry.position)
        let damagedInfantry = try XCTUnwrap(game.selectedUnit)
        let cost = game.reinforceCost(for: damagedInfantry)
        let startingPoints = game.commandPoints(for: .allies)

        game.reinforceSelectedUnit()

        XCTAssertEqual(game.commandPoints(for: .allies), startingPoints - cost)
        let reinforcedUnit = try XCTUnwrap(game.units.first { $0.id == infantry.id })
        XCTAssertGreaterThan(reinforcedUnit.hp, 42)
        XCTAssertTrue(reinforcedUnit.hasMoved)
        XCTAssertTrue(reinforcedUnit.hasAttacked)

        let result = try XCTUnwrap(game.latestReinforcementResult)
        XCTAssertEqual(result.unitID, infantry.id)
        XCTAssertEqual(result.unitName, infantry.name)
        XCTAssertEqual(result.unitKind, infantry.kind)
        XCTAssertEqual(result.faction, .allies)
        XCTAssertEqual(result.coordinate, infantry.position)
        XCTAssertEqual(result.startingHP, 42)
        XCTAssertEqual(result.endingHP, reinforcedUnit.hp)
        XCTAssertEqual(result.recoveredHP, reinforcedUnit.hp - 42)
        XCTAssertEqual(result.commandCost, cost)
        XCTAssertEqual(result.commandPointsAfterReinforcement, game.commandPoints(for: .allies))
        XCTAssertNil(game.latestCombatResult)
        XCTAssertNil(game.latestTacticalCommandResult)
        XCTAssertNil(game.latestObjectiveCaptureResult)
        XCTAssertNil(game.latestDeploymentResult)
    }

    func testFailedLogisticsOrdersDoNotCreateOrClearResults() throws {
        let lowPointGame = GameState(commandPoints: [.allies: 0, .axis: 6])
        let lowPointSite = try XCTUnwrap(lowPointGame.deploymentSites(for: .allies).first)

        lowPointGame.deploy(kind: .infantry, at: lowPointSite.coordinate)

        XCTAssertNil(lowPointGame.latestDeploymentResult)
        XCTAssertEqual(lowPointGame.commandPoints(for: .allies), 0)

        let game = GameState()
        let site = try XCTUnwrap(game.deploymentSites(for: .allies).first)
        game.deploy(kind: .tank, at: site.coordinate)
        let previousResult = try XCTUnwrap(game.latestDeploymentResult)

        game.deploy(kind: .infantry, at: site.coordinate)

        XCTAssertEqual(game.latestDeploymentResult, previousResult)
        XCTAssertEqual(game.commandPoints(for: .allies), 0)

        let fullStrengthGame = GameState(scenario: Self.logisticsResultScenario())
        let attacker = try XCTUnwrap(fullStrengthGame.units.first { $0.name == "后勤攻击方" })
        let fullStrengthSite = try XCTUnwrap(fullStrengthGame.deploymentSites(for: .allies).first)
        fullStrengthGame.deploy(kind: .infantry, at: fullStrengthSite.coordinate)
        let previousDeploymentResult = try XCTUnwrap(fullStrengthGame.latestDeploymentResult)
        fullStrengthGame.handlePrimaryAction(on: attacker.position)

        fullStrengthGame.reinforceSelectedUnit()

        XCTAssertNil(fullStrengthGame.latestReinforcementResult)
        XCTAssertEqual(fullStrengthGame.latestDeploymentResult, previousDeploymentResult)
    }

    func testLogisticsResultsAreMutuallyExclusiveWithCombatResults() throws {
        let game = GameState(
            scenario: Self.logisticsResultScenario(),
            commandPoints: [.allies: 12, .axis: 6]
        )
        let damagedUnit = try XCTUnwrap(game.units.first { $0.name == "后勤守军" })
        game.handlePrimaryAction(on: damagedUnit.position)
        game.reinforceSelectedUnit()

        XCTAssertNotNil(game.latestReinforcementResult)
        XCTAssertNil(game.latestDeploymentResult)

        let site = try XCTUnwrap(game.deploymentSites(for: .allies).first)
        game.deploy(kind: .infantry, at: site.coordinate)

        XCTAssertNotNil(game.latestDeploymentResult)
        XCTAssertNil(game.latestReinforcementResult)

        let attacker = try XCTUnwrap(game.units.first { $0.name == "后勤攻击方" })
        let target = try XCTUnwrap(game.units.first { $0.name == "后勤目标" })
        game.handlePrimaryAction(on: attacker.position)
        game.handleSecondaryAction(on: target.position)

        XCTAssertNotNil(game.latestCombatResult)
        XCTAssertNil(game.latestDeploymentResult)
        XCTAssertNil(game.latestReinforcementResult)
    }

    func testAxisAIDeploymentRecordsLogisticsSummary() throws {
        let game = GameState(
            scenario: Self.axisDeploymentResultScenario(),
            commandPoints: [.allies: 6, .axis: 1]
        )

        game.endTurn()

        XCTAssertNil(game.winner)
        let result = try XCTUnwrap(game.latestDeploymentResult)
        let deployedUnit = try XCTUnwrap(game.units.first { $0.id == result.unitID })
        XCTAssertEqual(result.faction, .axis)
        XCTAssertEqual(result.unitKind, deployedUnit.kind)
        XCTAssertEqual(result.coordinate, deployedUnit.position)
        XCTAssertEqual(result.commandCost, deployedUnit.kind.commandCost)
        XCTAssertEqual(result.commandPointsAfterDeployment, game.commandPoints(for: .axis))
        XCTAssertNil(game.latestReinforcementResult)
    }

    func testAxisAIUsesCommandPointsToDeployReinforcement() {
        let game = GameState()
        let startingAxisUnits = game.units(for: .axis).count
        let axisPointsAfterIncome = game.commandPoints(for: .axis) + game.commandIncome(for: .axis)

        game.endTurn()

        if game.winner == nil {
            XCTAssertGreaterThan(game.units(for: .axis).count, startingAxisUnits)
            XCTAssertLessThan(game.commandPoints(for: .axis), axisPointsAfterIncome)
        }
    }

    func testAxisAIRepairsDamagedObjectiveDefenderBeforeActing() throws {
        var scenario = Scenario.ardennesPrototype()
        guard let tankIndex = scenario.units.firstIndex(where: { $0.name == "第2装甲集团" }) else {
            XCTFail("Axis tank should exist")
            return
        }
        scenario.units[tankIndex].hp = 50
        let tankID = scenario.units[tankIndex].id
        let game = GameState(
            scenario: scenario,
            commandPoints: [.allies: 6, .axis: 8]
        )

        game.endTurn()

        if game.winner == nil {
            let repairedTank = try XCTUnwrap(game.units.first { $0.id == tankID })
            XCTAssertEqual(repairedTank.hp, repairedTank.maxHP)
            XCTAssertTrue(repairedTank.hasMoved)
            XCTAssertTrue(repairedTank.hasAttacked)
        }
    }

    func testAxisAIUsesArtilleryBarrageWhenValuableTargetIsInRange() throws {
        let game = GameState(
            scenario: Self.axisTacticalCommandScenario(),
            commandPoints: [.allies: 6, .axis: 8]
        )
        let alliedTarget = try XCTUnwrap(game.units.first { $0.name == "盟军指挥坦克" })
        let axisArtillery = try XCTUnwrap(game.units.first { $0.name == "轴心炮兵" })

        game.endTurn()

        if game.winner == nil {
            let targetAfterAI = try XCTUnwrap(game.units.first { $0.id == alliedTarget.id })
            let artilleryAfterAI = try XCTUnwrap(game.units.first { $0.id == axisArtillery.id })
            XCTAssertLessThan(targetAfterAI.hp, alliedTarget.hp)
            XCTAssertLessThan(targetAfterAI.morale, alliedTarget.morale)
            XCTAssertEqual(artilleryAfterAI.hp, axisArtillery.hp)
            XCTAssertTrue(artilleryAfterAI.hasMoved)
            XCTAssertTrue(artilleryAfterAI.hasAttacked)
            XCTAssertLessThan(game.commandPoints(for: .axis), 8 + game.commandIncome(for: .axis))
            XCTAssertTrue(game.battleLog.contains { $0.contains("火炮弹幕") })
            let summary = try XCTUnwrap(game.latestTacticalCommandResult)
            XCTAssertEqual(summary.command, .artilleryBarrage)
            XCTAssertEqual(summary.caster.unitID, axisArtillery.id)
            XCTAssertEqual(summary.target.unitID, alliedTarget.id)
            XCTAssertEqual(summary.caster.faction, .axis)
            XCTAssertTrue(summary.didAvoidCounterAttack)
        }
    }

    func testAxisAIUsesFullMovementToReachAttackPosition() throws {
        let game = GameState(
            scenario: Self.axisFullAdvanceScenario(),
            commandPoints: [.allies: 6, .axis: 0]
        )
        let alliedInfantry = try XCTUnwrap(game.units.first { $0.name == "远端步兵" })
        let axisRecon = try XCTUnwrap(game.units.first { $0.name == "突进侦察" })

        game.endTurn()

        if game.winner == nil {
            let reconAfterAI = try XCTUnwrap(game.units.first { $0.id == axisRecon.id })
            let infantryAfterAI = try XCTUnwrap(game.units.first { $0.id == alliedInfantry.id })
            XCTAssertEqual(reconAfterAI.position, HexCoordinate(q: 1, r: 0))
            XCTAssertLessThan(infantryAfterAI.hp, alliedInfantry.hp)
            XCTAssertTrue(reconAfterAI.hasMoved)
            XCTAssertTrue(reconAfterAI.hasAttacked)
        }
    }

    func testAxisAIUsesManeuverPursuitAfterDestroyingAdjacentTarget() throws {
        let game = GameState(
            scenario: Self.axisManeuverPursuitScenario(),
            commandPoints: [.allies: 6, .axis: 0]
        )
        let lowTarget = try XCTUnwrap(game.units.first { $0.name == "薄弱前哨" })
        let reserve = try XCTUnwrap(game.units.first { $0.name == "纵深守军" })
        let axisTank = try XCTUnwrap(game.units.first { $0.name == "追击装甲群" })

        game.endTurn()

        if game.winner == nil {
            let axisTankAfterAI = try XCTUnwrap(game.units.first { $0.id == axisTank.id })
            let reserveAfterAI = try XCTUnwrap(game.units.first { $0.id == reserve.id })
            XCTAssertNil(game.units.first { $0.id == lowTarget.id })
            XCTAssertEqual(axisTankAfterAI.position, HexCoordinate(q: 0, r: 0))
            XCTAssertEqual(game.tile(at: HexCoordinate(q: 0, r: 0))?.owner, .axis)
            XCTAssertEqual(reserveAfterAI.hp, reserve.hp)
            XCTAssertTrue(axisTankAfterAI.hasMoved)
            XCTAssertTrue(axisTankAfterAI.hasAttacked)
            XCTAssertTrue(game.battleLog.contains { $0.contains("可继续机动") })
            let summary = try XCTUnwrap(game.latestAIPhaseSummary)
            XCTAssertEqual(summary.objectivesCaptured, 1)
            XCTAssertEqual(summary.enemyUnitsDestroyed, 1)
            XCTAssertEqual(summary.friendlyUnitsDestroyed, 0)
        }
    }

    func testAxisAIPhaseSummaryRecordsTacticalCommand() throws {
        let game = GameState(
            scenario: Self.axisTacticalCommandScenario(),
            commandPoints: [.allies: 6, .axis: 8]
        )
        let alliedTarget = try XCTUnwrap(game.units.first { $0.name == "盟军指挥坦克" })
        let startingAxisPoints = game.commandPoints(for: .axis) + game.commandIncome(for: .axis)

        game.endTurn()

        XCTAssertNil(game.winner)
        let targetAfterAI = try XCTUnwrap(game.units.first { $0.id == alliedTarget.id })
        let summary = try XCTUnwrap(game.latestAIPhaseSummary)
        XCTAssertEqual(summary.faction, .axis)
        XCTAssertEqual(summary.turn, 1)
        XCTAssertEqual(summary.startingCommandPoints, startingAxisPoints)
        XCTAssertEqual(summary.endingCommandPoints, game.commandPoints(for: .axis))
        XCTAssertGreaterThanOrEqual(summary.tacticalCommands, 1)
        XCTAssertEqual(summary.damageDealt, alliedTarget.hp - targetAfterAI.hp)
        XCTAssertEqual(summary.damageTaken, 0)
        XCTAssertEqual(summary.enemyUnitsDestroyed, 0)
    }

    func testAxisAIPhaseSummaryRecordsMoveAndAttack() throws {
        let game = GameState(
            scenario: Self.axisFullAdvanceScenario(),
            commandPoints: [.allies: 6, .axis: 0]
        )
        let alliedInfantry = try XCTUnwrap(game.units.first { $0.name == "远端步兵" })

        game.endTurn()

        XCTAssertNil(game.winner)
        let infantryAfterAI = try XCTUnwrap(game.units.first { $0.id == alliedInfantry.id })
        let combatSummary = try XCTUnwrap(game.latestCombatResult)
        let summary = try XCTUnwrap(game.latestAIPhaseSummary)
        XCTAssertEqual(summary.faction, .axis)
        XCTAssertEqual(summary.moves, 1)
        XCTAssertEqual(summary.attacks, 1)
        XCTAssertEqual(summary.tacticalCommands, 0)
        XCTAssertEqual(summary.deployments, 0)
        XCTAssertEqual(summary.reinforcements, 0)
        XCTAssertEqual(summary.damageDealt, combatSummary.damage)
        XCTAssertGreaterThanOrEqual(alliedInfantry.hp - infantryAfterAI.hp, summary.damageDealt)
        XCTAssertEqual(summary.objectivesCaptured, 0)
    }

    func testAxisAIPhaseSummaryRecordsLogistics() throws {
        let deploymentGame = GameState(
            scenario: Self.axisDeploymentResultScenario(),
            commandPoints: [.allies: 6, .axis: 1]
        )
        deploymentGame.endTurn()

        XCTAssertNil(deploymentGame.winner)
        let deploymentSummary = try XCTUnwrap(deploymentGame.latestAIPhaseSummary)
        XCTAssertEqual(deploymentSummary.faction, .axis)
        XCTAssertEqual(deploymentSummary.deployments, 1)
        XCTAssertEqual(deploymentSummary.reinforcements, 0)
        XCTAssertEqual(deploymentSummary.startingCommandPoints, 6)
        XCTAssertEqual(deploymentSummary.endingCommandPoints, deploymentGame.commandPoints(for: .axis))

        let reinforcementGame = GameState(
            scenario: Self.axisReinforcementResultScenario(),
            commandPoints: [.allies: 6, .axis: 0]
        )
        reinforcementGame.endTurn()

        XCTAssertNil(reinforcementGame.winner)
        let reinforcementSummary = try XCTUnwrap(reinforcementGame.latestAIPhaseSummary)
        XCTAssertEqual(reinforcementSummary.reinforcements, 1)
        XCTAssertEqual(reinforcementSummary.deployments, 0)
        XCTAssertEqual(reinforcementSummary.damageDealt, 0)
        XCTAssertEqual(reinforcementSummary.damageTaken, 0)
    }

    func testAIPhaseSummaryClearsOnScenarioReset() throws {
        let game = GameState(
            scenario: Self.axisDeploymentResultScenario(),
            commandPoints: [.allies: 6, .axis: 1]
        )
        game.endTurn()
        XCTAssertNotNil(game.latestAIPhaseSummary)

        game.restart()

        XCTAssertNil(game.latestAIPhaseSummary)
        game.endTurn()
        XCTAssertNotNil(game.latestAIPhaseSummary)

        game.selectScenario(id: "normandy-1944")

        XCTAssertNil(game.latestAIPhaseSummary)
    }

    func testPlayerPreviewAndFailedOrdersDoNotCreateAIPhaseSummary() throws {
        let game = GameState()
        game.handlePrimaryAction(on: HexCoordinate(q: 0, r: 0))
        XCTAssertNil(game.latestAIPhaseSummary)

        let lowPointGame = GameState(commandPoints: [.allies: 0, .axis: 6])
        let site = try XCTUnwrap(lowPointGame.deploymentSites(for: .allies).first)
        lowPointGame.deploy(kind: .infantry, at: site.coordinate)

        XCTAssertNil(lowPointGame.latestAIPhaseSummary)
    }

    func testCombatPreviewAndTargetQueries() throws {
        let game = GameState()
        let attacker = BattleUnit(
            name: "测试装甲",
            kind: .tank,
            faction: .allies,
            position: HexCoordinate(q: 9, r: 4),
            hp: UnitKind.tank.baseHP,
            commander: .patton
        )
        let defender = try XCTUnwrap(game.units.first { $0.name == "第2装甲集团" })

        let preview = try XCTUnwrap(game.combatPreview(attacker: attacker, defender: defender))
        XCTAssertEqual(preview.attackerName, "测试装甲")
        XCTAssertEqual(preview.defenderName, "第2装甲集团")
        XCTAssertGreaterThan(preview.damage, 0)
        XCTAssertLessThan(preview.defenderHPAfterAttack, defender.hp)

        let targets = game.attackableUnits(for: attacker)
        XCTAssertTrue(targets.contains { $0.id == defender.id })
    }

    func testUnitMatchupsModifyCombatDamage() throws {
        let game = GameState(scenario: Self.matchupScenario())
        let recon = try XCTUnwrap(game.units.first { $0.name == "克制侦察" })
        let artillery = try XCTUnwrap(game.units.first { $0.name == "炮兵目标" })
        let tank = try XCTUnwrap(game.units.first { $0.name == "装甲目标" })
        let infantry = try XCTUnwrap(game.units.first { $0.name == "步兵攻击" })
        let infantryAgainstTank = try XCTUnwrap(game.combatPreview(attacker: infantry, defender: tank))
        let reconAgainstArtillery = try XCTUnwrap(game.combatPreview(attacker: recon, defender: artillery))
        let reconAgainstTank = try XCTUnwrap(game.combatPreview(attacker: recon, defender: tank))

        XCTAssertEqual(reconAgainstArtillery.matchupMultiplierPercent, 120)
        XCTAssertEqual(reconAgainstArtillery.matchupTitle, "战术优势")
        XCTAssertGreaterThan(reconAgainstArtillery.damage, reconAgainstTank.damage)
        XCTAssertEqual(infantryAgainstTank.matchupMultiplierPercent, 92)
        XCTAssertEqual(infantryAgainstTank.matchupTitle, "战术劣势")
    }

    func testTerrainAffinityAffectsMovementAndCombatPreview() throws {
        let infantryMovementGame = GameState(scenario: Self.terrainMovementScenario(unitKind: .infantry))
        let tankMovementGame = GameState(scenario: Self.terrainMovementScenario(unitKind: .tank))
        let infantry = try XCTUnwrap(infantryMovementGame.units.first { $0.name == "地形测试步兵" })
        let tank = try XCTUnwrap(tankMovementGame.units.first { $0.name == "地形测试坦克" })
        let mountain = HexCoordinate(q: 1, r: 1)

        XCTAssertEqual(TerrainKind.mountain.movementCost(for: .infantry), 3)
        XCTAssertEqual(TerrainKind.mountain.movementCost(for: .tank), 5)
        XCTAssertTrue(infantryMovementGame.reachableTiles(for: infantry).contains(mountain))
        XCTAssertFalse(tankMovementGame.reachableTiles(for: tank).contains(mountain))

        let combatGame = GameState(scenario: Self.terrainCombatScenario())
        let attacker = try XCTUnwrap(combatGame.units.first { $0.name == "地形测试装甲" })
        let plainsTarget = try XCTUnwrap(combatGame.units.first { $0.name == "平原目标" })
        let riverTarget = try XCTUnwrap(combatGame.units.first { $0.name == "河流目标" })
        let plainsPreview = try XCTUnwrap(combatGame.combatPreview(attacker: attacker, defender: plainsTarget))
        let riverPreview = try XCTUnwrap(combatGame.combatPreview(attacker: attacker, defender: riverTarget))

        XCTAssertEqual(plainsPreview.terrainAttackMultiplierPercent, 108)
        XCTAssertEqual(plainsPreview.terrainTitle, "地形适性")
        XCTAssertEqual(riverPreview.terrainAttackMultiplierPercent, 72)
        XCTAssertEqual(riverPreview.terrainTitle, "地形牵制")
        XCTAssertGreaterThan(plainsPreview.damage, riverPreview.damage)
        XCTAssertTrue(riverPreview.terrainDetail.contains("河流"))
    }

    func testEnemyControlZonesIncreaseMovementCostAndLimitReach() throws {
        let contestedGame = GameState(scenario: Self.zoneOfControlScenario(includeEnemy: true))
        let openGame = GameState(scenario: Self.zoneOfControlScenario(includeEnemy: false))
        let contestedRecon = try XCTUnwrap(contestedGame.units.first { $0.name == "接敌侦察" })
        let openRecon = try XCTUnwrap(openGame.units.first { $0.name == "接敌侦察" })
        let contactTile = HexCoordinate(q: 1, r: 1)
        let deepTile = HexCoordinate(q: 3, r: 0)

        XCTAssertTrue(contestedGame.enemyControlZoneTiles(for: .allies).contains(contactTile))
        XCTAssertEqual(contestedGame.enemyControlZonePenalty(for: contestedRecon, entering: contactTile), 1)
        XCTAssertEqual(
            contestedGame.movementCostPreview(for: contestedRecon, entering: contactTile),
            TerrainKind.plains.movementCost(for: .recon) + 1
        )
        XCTAssertTrue(openGame.reachableTiles(for: openRecon).contains(deepTile))
        XCTAssertFalse(contestedGame.reachableTiles(for: contestedRecon).contains(deepTile))
        XCTAssertTrue(contestedGame.zoneOfControlSummary.contains("+1"))
    }

    func testArtilleryBarrageUsesCommandPointsAndSuppressesTarget() throws {
        let game = GameState(
            scenario: Self.tacticalCommandScenario(),
            commandPoints: [.allies: 6, .axis: 6]
        )
        let artillery = try XCTUnwrap(game.units.first { $0.name == "弹幕炮兵" })
        let target = try XCTUnwrap(game.units.first { $0.name == "弹幕目标" })
        let infantry = try XCTUnwrap(game.units.first { $0.name == "普通步兵" })
        let preview = try XCTUnwrap(game.tacticalCommandPreview(command: .artilleryBarrage, caster: artillery, target: target))

        XCTAssertEqual(preview.command, .artilleryBarrage)
        XCTAssertEqual(preview.commandCost, TacticalCommand.artilleryBarrage.commandCost)
        XCTAssertEqual(preview.range, TacticalCommand.artilleryBarrage.range)
        XCTAssertGreaterThan(preview.damage, 0)
        XCTAssertEqual(preview.statusEffect, .suppressed)
        XCTAssertTrue(preview.outcomeText.contains("士气"))
        XCTAssertEqual(game.tacticalCommandTargets(for: artillery, command: .artilleryBarrage).count, 1)
        XCTAssertTrue(game.canUseTacticalCommand(.artilleryBarrage, with: artillery))
        XCTAssertFalse(game.canUseTacticalCommand(.artilleryBarrage, with: infantry))

        game.useTacticalCommand(.artilleryBarrage, casterID: artillery.id, targetID: target.id)

        let artilleryAfterCommand = try XCTUnwrap(game.units.first { $0.id == artillery.id })
        let targetAfterCommand = try XCTUnwrap(game.units.first { $0.id == target.id })
        let summary = try XCTUnwrap(game.latestTacticalCommandResult)
        XCTAssertEqual(game.commandPoints(for: .allies), 6 - TacticalCommand.artilleryBarrage.commandCost)
        XCTAssertEqual(targetAfterCommand.hp, target.hp - preview.damage)
        XCTAssertEqual(targetAfterCommand.morale, target.morale - TacticalCommand.artilleryBarrage.moraleDamage)
        XCTAssertEqual(targetAfterCommand.tacticalStatus, .suppressed)
        XCTAssertEqual(artilleryAfterCommand.hp, artillery.hp)
        XCTAssertTrue(artilleryAfterCommand.hasMoved)
        XCTAssertTrue(artilleryAfterCommand.hasAttacked)
        XCTAssertTrue(game.battleLog.contains { $0.contains("火炮弹幕") })
        XCTAssertNil(game.latestCombatResult)
        XCTAssertEqual(summary.command, .artilleryBarrage)
        XCTAssertEqual(summary.caster.unitID, artillery.id)
        XCTAssertEqual(summary.target.unitID, target.id)
        XCTAssertEqual(summary.damage, preview.damage)
        XCTAssertEqual(summary.commandCost, TacticalCommand.artilleryBarrage.commandCost)
        XCTAssertEqual(summary.moraleDamage, TacticalCommand.artilleryBarrage.moraleDamage)
        XCTAssertEqual(summary.statusEffect, .suppressed)
        XCTAssertTrue(summary.didApplyStatusEffect)
        XCTAssertFalse(summary.didDestroyTarget)
        XCTAssertFalse(summary.didConsumeTargetEntrenchment)
        XCTAssertTrue(summary.didAvoidCounterAttack)
        XCTAssertEqual(summary.caster.startingHP, artillery.hp)
        XCTAssertEqual(summary.caster.endingHP, artilleryAfterCommand.hp)
        XCTAssertEqual(summary.target.startingHP, target.hp)
        XCTAssertEqual(summary.target.endingHP, targetAfterCommand.hp)
        XCTAssertEqual(summary.target.startingMorale, target.morale)
        XCTAssertEqual(summary.target.endingMorale, targetAfterCommand.morale)
        XCTAssertTrue(game.battleLog.contains { $0.contains("火炮弹幕") && $0.contains("无反击") })
        XCTAssertTrue(game.battleLog.contains { $0.contains("火炮弹幕") && $0.contains("消耗 4 指令点") })
    }

    func testBreakthroughAssaultUsesCommandPointsAndAvoidsCounterattack() throws {
        let game = GameState(
            scenario: Self.breakthroughAssaultScenario(),
            commandPoints: [.allies: 6, .axis: 6]
        )
        let tank = try XCTUnwrap(game.units.first { $0.name == "突击装甲" })
        let infantry = try XCTUnwrap(game.units.first { $0.name == "普通步兵" })
        let target = try XCTUnwrap(game.units.first { $0.name == "突破目标" })
        let normalPreview = try XCTUnwrap(game.combatPreview(attacker: tank, defender: target))
        let preview = try XCTUnwrap(game.tacticalCommandPreview(command: .breakthroughAssault, caster: tank, target: target))

        XCTAssertEqual(preview.command, .breakthroughAssault)
        XCTAssertEqual(preview.commandCost, TacticalCommand.breakthroughAssault.commandCost)
        XCTAssertEqual(preview.range, TacticalCommand.breakthroughAssault.range)
        XCTAssertGreaterThan(preview.damage, normalPreview.damage)
        XCTAssertEqual(preview.statusEffect, .disrupted)
        XCTAssertEqual(game.tacticalCommandTargets(for: tank, command: .breakthroughAssault).count, 1)
        XCTAssertTrue(game.canUseTacticalCommand(.breakthroughAssault, with: tank))
        XCTAssertFalse(game.canUseTacticalCommand(.breakthroughAssault, with: infantry))

        game.useTacticalCommand(.breakthroughAssault, casterID: tank.id, targetID: target.id)

        let tankAfterCommand = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterCommand = try XCTUnwrap(game.units.first { $0.id == target.id })
        let summary = try XCTUnwrap(game.latestTacticalCommandResult)
        XCTAssertEqual(game.commandPoints(for: .allies), 6 - TacticalCommand.breakthroughAssault.commandCost)
        XCTAssertEqual(targetAfterCommand.hp, target.hp - preview.damage)
        XCTAssertEqual(targetAfterCommand.morale, target.morale - TacticalCommand.breakthroughAssault.moraleDamage)
        XCTAssertEqual(targetAfterCommand.tacticalStatus, .disrupted)
        XCTAssertEqual(tankAfterCommand.hp, tank.hp)
        XCTAssertTrue(tankAfterCommand.hasMoved)
        XCTAssertTrue(tankAfterCommand.hasAttacked)
        XCTAssertTrue(game.battleLog.contains { $0.contains("突破突击") })
        XCTAssertNil(game.latestCombatResult)
        XCTAssertEqual(summary.command, .breakthroughAssault)
        XCTAssertEqual(summary.caster.unitID, tank.id)
        XCTAssertEqual(summary.target.unitID, target.id)
        XCTAssertEqual(summary.damage, preview.damage)
        XCTAssertEqual(summary.commandCost, TacticalCommand.breakthroughAssault.commandCost)
        XCTAssertEqual(summary.moraleDamage, TacticalCommand.breakthroughAssault.moraleDamage)
        XCTAssertEqual(summary.statusEffect, .disrupted)
        XCTAssertTrue(summary.didApplyStatusEffect)
        XCTAssertFalse(summary.didDestroyTarget)
        XCTAssertTrue(summary.didAvoidCounterAttack)
        XCTAssertEqual(summary.caster.endingHP, tank.hp)
        XCTAssertEqual(summary.target.endingHP, targetAfterCommand.hp)
        XCTAssertTrue(game.battleLog.contains { $0.contains("突破突击") && $0.contains("无反击") })
    }

    func testTacticalCommandResultRecordsDestroyedTargetWithoutStatusEffect() throws {
        var scenario = Self.breakthroughAssaultScenario()
        let targetIndex = try XCTUnwrap(scenario.units.firstIndex { $0.name == "突破目标" })
        scenario.units[targetIndex].hp = 12
        let game = GameState(
            scenario: scenario,
            commandPoints: [.allies: 6, .axis: 6]
        )
        let tank = try XCTUnwrap(game.units.first { $0.name == "突击装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "突破目标" })
        let preview = try XCTUnwrap(game.tacticalCommandPreview(command: .breakthroughAssault, caster: tank, target: target))

        XCTAssertTrue(preview.willDestroyTarget)

        game.useTacticalCommand(.breakthroughAssault, casterID: tank.id, targetID: target.id)

        let summary = try XCTUnwrap(game.latestTacticalCommandResult)
        let targetAfterCommand = try XCTUnwrap(game.scenario.units.first { $0.id == target.id })

        XCTAssertEqual(summary.command, .breakthroughAssault)
        XCTAssertTrue(summary.didDestroyTarget)
        XCTAssertEqual(summary.target.endingHP, 0)
        XCTAssertEqual(targetAfterCommand.hp, 0)
        XCTAssertEqual(summary.moraleDamage, 0)
        XCTAssertEqual(summary.statusEffect, .normal)
        XCTAssertFalse(summary.didApplyStatusEffect)
        XCTAssertTrue(game.battleLog.contains { $0.contains("突破突击") && $0.contains("击毁") })
    }

    func testManeuverPursuitLetsMobileUnitMoveAfterDestroyingTarget() throws {
        let game = GameState(
            scenario: Self.maneuverPursuitScenario(attackerKind: .tank),
            commandPoints: [.allies: 6, .axis: 6]
        )
        let tank = try XCTUnwrap(game.units.first { $0.name == "追击装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "追击目标" })
        let pursuitObjective = HexCoordinate(q: 3, r: 0)

        XCTAssertTrue(game.canUseManeuverPursuit(afterDestroyingWith: tank))
        XCTAssertTrue(game.maneuverPursuitSummary.contains("坦克"))

        game.handleTap(on: tank.position)
        game.handleTap(on: target.position)

        let tankAfterKill = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let summary = try XCTUnwrap(game.latestCombatResult)
        XCTAssertTrue(tankAfterKill.hasAttacked)
        XCTAssertFalse(tankAfterKill.hasMoved)
        XCTAssertEqual(game.selectedUnit?.id, tank.id)
        XCTAssertTrue(game.reachableTiles(for: tankAfterKill).contains(pursuitObjective))
        XCTAssertTrue(game.attackableTiles(for: tankAfterKill).isEmpty)
        XCTAssertTrue(game.battleLog.contains { $0.contains("可继续机动") })
        XCTAssertEqual(summary.attacker.unitID, tank.id)
        XCTAssertEqual(summary.defender.unitID, target.id)
        XCTAssertTrue(summary.didDestroyDefender)
        XCTAssertTrue(summary.didTriggerManeuverPursuit)
        XCTAssertFalse(summary.didDestroyAttacker)

        game.handleTap(on: pursuitObjective)

        let tankAfterPursuit = try XCTUnwrap(game.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterPursuit.position, pursuitObjective)
        XCTAssertTrue(tankAfterPursuit.hasMoved)
        XCTAssertTrue(tankAfterPursuit.hasAttacked)
        XCTAssertEqual(game.tile(at: pursuitObjective)?.owner, .allies)
    }

    func testInfantryDoesNotTriggerManeuverPursuitAfterDestroyingTarget() throws {
        let game = GameState(
            scenario: Self.maneuverPursuitScenario(attackerKind: .infantry),
            commandPoints: [.allies: 6, .axis: 6]
        )
        let infantry = try XCTUnwrap(game.units.first { $0.name == "追击步兵" })
        let target = try XCTUnwrap(game.units.first { $0.name == "追击目标" })

        XCTAssertFalse(game.canUseManeuverPursuit(afterDestroyingWith: infantry))

        game.handleTap(on: infantry.position)
        game.handleTap(on: target.position)

        let infantryAfterKill = try XCTUnwrap(game.units.first { $0.id == infantry.id })
        let summary = try XCTUnwrap(game.latestCombatResult)
        XCTAssertTrue(infantryAfterKill.hasMoved)
        XCTAssertTrue(infantryAfterKill.hasAttacked)
        XCTAssertFalse(game.battleLog.contains { $0.contains("可继续机动") })
        XCTAssertTrue(summary.didDestroyDefender)
        XCTAssertFalse(summary.didTriggerManeuverPursuit)
    }

    func testArtilleryBarrageConsumesEntrenchedTargetDefense() throws {
        let baselineGame = GameState(
            scenario: Self.tacticalCommandScenario(),
            commandPoints: [.allies: 6, .axis: 6]
        )
        let baselineArtillery = try XCTUnwrap(baselineGame.units.first { $0.name == "弹幕炮兵" })
        let baselineTarget = try XCTUnwrap(baselineGame.units.first { $0.name == "弹幕目标" })
        let baselinePreview = try XCTUnwrap(baselineGame.tacticalCommandPreview(command: .artilleryBarrage, caster: baselineArtillery, target: baselineTarget))

        var scenario = Self.tacticalCommandScenario()
        let targetIndex = try XCTUnwrap(scenario.units.firstIndex { $0.name == "弹幕目标" })
        scenario.units[targetIndex].isEntrenched = true
        let game = GameState(
            scenario: scenario,
            commandPoints: [.allies: 6, .axis: 6]
        )
        let artillery = try XCTUnwrap(game.units.first { $0.name == "弹幕炮兵" })
        let target = try XCTUnwrap(game.units.first { $0.name == "弹幕目标" })
        let preview = try XCTUnwrap(game.tacticalCommandPreview(command: .artilleryBarrage, caster: artillery, target: target))

        XCTAssertTrue(preview.targetIsEntrenched)
        XCTAssertEqual(preview.defenseMultiplierPercent, 75)
        XCTAssertLessThan(preview.damage, baselinePreview.damage)
        XCTAssertTrue(preview.outcomeText.contains("防御姿态"))

        game.useTacticalCommand(.artilleryBarrage, casterID: artillery.id, targetID: target.id)

        let targetAfterCommand = try XCTUnwrap(game.units.first { $0.id == target.id })
        let summary = try XCTUnwrap(game.latestTacticalCommandResult)
        XCTAssertEqual(targetAfterCommand.hp, target.hp - preview.damage)
        XCTAssertFalse(targetAfterCommand.isEntrenched)
        XCTAssertTrue(summary.didConsumeTargetEntrenchment)
        XCTAssertTrue(game.battleLog.contains { $0.contains("火炮弹幕") && $0.contains("防御姿态") })
    }

    func testTacticalCommandRequiresEnoughCommandPoints() throws {
        let game = GameState(
            scenario: Self.tacticalCommandScenario(),
            commandPoints: [.allies: 2, .axis: 6]
        )
        let artillery = try XCTUnwrap(game.units.first { $0.name == "弹幕炮兵" })
        let target = try XCTUnwrap(game.units.first { $0.name == "弹幕目标" })

        XCTAssertFalse(game.canUseTacticalCommand(.artilleryBarrage, with: artillery))

        game.useTacticalCommand(.artilleryBarrage, casterID: artillery.id, targetID: target.id)

        let targetAfterAttempt = try XCTUnwrap(game.units.first { $0.id == target.id })
        XCTAssertEqual(game.commandPoints(for: .allies), 2)
        XCTAssertEqual(targetAfterAttempt.hp, target.hp)
        XCTAssertTrue(game.message.contains("无法执行"))
        XCTAssertNil(game.latestTacticalCommandResult)
    }

    func testCombatAwardsExperienceAndCanPromoteUnit() throws {
        var scenario = Scenario.ardennesPrototype()
        guard let attackerIndex = scenario.units.firstIndex(where: { $0.name == "第4装甲师" }),
              let defenderIndex = scenario.units.firstIndex(where: { $0.name == "第2装甲集团" }) else {
            XCTFail("Expected attacker and defender")
            return
        }
        scenario.units[attackerIndex].position = HexCoordinate(q: 9, r: 4)
        scenario.units[attackerIndex].experience = UnitRank.regular.minimumExperience - 1
        scenario.units[defenderIndex].hp = 12
        let attackerID = scenario.units[attackerIndex].id
        let game = GameState(scenario: scenario)

        game.handleTap(on: HexCoordinate(q: 9, r: 4))
        game.handleTap(on: scenario.units[defenderIndex].position)

        let promoted = try XCTUnwrap(game.units.first { $0.id == attackerID })
        XCTAssertGreaterThanOrEqual(promoted.experience, UnitRank.regular.minimumExperience)
        XCTAssertNotEqual(promoted.rank, .green)
        XCTAssertGreaterThan(promoted.maxHP, promoted.kind.baseHP)
        XCTAssertTrue(game.battleLog.contains { $0.contains("晋升") })
    }

    func testLatestCombatResultTracksDamageCounterAndProgression() throws {
        let game = GameState(scenario: Self.combatResultScenario())
        let attacker = try XCTUnwrap(game.units.first { $0.name == "结果攻击方" })
        let defender = try XCTUnwrap(game.units.first { $0.name == "结果防守方" })
        let preview = try XCTUnwrap(game.combatPreview(attacker: attacker, defender: defender))

        XCTAssertNil(game.latestCombatResult)
        game.handlePrimaryAction(on: attacker.position)
        game.handlePrimaryAction(on: defender.position)
        _ = game.postMoveAttackPreviews(for: attacker, to: attacker.position)
        XCTAssertNil(game.latestCombatResult)

        game.handleTap(on: attacker.position)
        game.handleTap(on: defender.position)

        let summary = try XCTUnwrap(game.latestCombatResult)
        let finalAttacker = try XCTUnwrap(game.scenario.units.first { $0.id == attacker.id })
        let finalDefender = try XCTUnwrap(game.scenario.units.first { $0.id == defender.id })

        XCTAssertEqual(summary.attacker.unitID, attacker.id)
        XCTAssertEqual(summary.defender.unitID, defender.id)
        XCTAssertEqual(summary.damage, preview.damage)
        XCTAssertGreaterThan(summary.counterDamage, 0)
        XCTAssertEqual(summary.supportDamageBonusPercent, 0)
        XCTAssertTrue(summary.didConsumeDefenderEntrenchment)
        XCTAssertFalse(summary.didDestroyDefender)
        XCTAssertFalse(summary.didDestroyAttacker)
        XCTAssertFalse(summary.didTriggerManeuverPursuit)

        XCTAssertEqual(summary.attacker.startingHP, attacker.hp)
        XCTAssertEqual(summary.attacker.endingHP, finalAttacker.hp)
        XCTAssertEqual(summary.attacker.startingExperience, attacker.experience)
        XCTAssertEqual(summary.attacker.endingExperience, finalAttacker.experience)
        XCTAssertEqual(summary.attacker.experienceDelta, finalAttacker.experience - attacker.experience)
        XCTAssertEqual(summary.attacker.startingMorale, attacker.morale)
        XCTAssertEqual(summary.attacker.endingMorale, finalAttacker.morale)
        XCTAssertEqual(summary.attacker.startingRank, attacker.rank)
        XCTAssertEqual(summary.attacker.endingRank, finalAttacker.rank)
        XCTAssertTrue(summary.attacker.didPromote)
        let attackerHPGain = summary.attacker.endingRank.hpBonus - summary.attacker.startingRank.hpBonus
        let attackerHPBeforeCounter = min(
            finalAttacker.maxHP,
            attacker.hp + max(0, attackerHPGain)
        )
        XCTAssertEqual(summary.attacker.endingHP, max(0, attackerHPBeforeCounter - summary.counterDamage))

        XCTAssertEqual(summary.defender.startingHP, defender.hp)
        XCTAssertEqual(summary.defender.endingHP, finalDefender.hp)
        XCTAssertEqual(summary.defender.endingHP, preview.defenderHPAfterAttack)
        XCTAssertEqual(summary.defender.startingExperience, defender.experience)
        XCTAssertEqual(summary.defender.endingExperience, finalDefender.experience)
        XCTAssertEqual(summary.defender.experienceDelta, finalDefender.experience - defender.experience)
        XCTAssertEqual(summary.defender.startingMorale, defender.morale)
        XCTAssertEqual(summary.defender.endingMorale, finalDefender.morale)
        XCTAssertEqual(summary.defender.startingRank, defender.rank)
        XCTAssertEqual(summary.defender.endingRank, finalDefender.rank)
        XCTAssertFalse(finalDefender.isEntrenched)
    }

    func testCombatAndTacticalCommandResultsAreMutuallyExclusive() throws {
        let commandGame = GameState(
            scenario: Self.tacticalCommandScenario(),
            commandPoints: [.allies: 6, .axis: 6]
        )
        let artillery = try XCTUnwrap(commandGame.units.first { $0.name == "弹幕炮兵" })
        let commandTarget = try XCTUnwrap(commandGame.units.first { $0.name == "弹幕目标" })
        commandGame.useTacticalCommand(.artilleryBarrage, casterID: artillery.id, targetID: commandTarget.id)

        XCTAssertNotNil(commandGame.latestTacticalCommandResult)
        XCTAssertNil(commandGame.latestCombatResult)

        let attackGame = GameState(scenario: Self.combatResultScenario())
        let attacker = try XCTUnwrap(attackGame.units.first { $0.name == "结果攻击方" })
        let defender = try XCTUnwrap(attackGame.units.first { $0.name == "结果防守方" })
        attackGame.handleTap(on: attacker.position)
        attackGame.handleTap(on: defender.position)

        XCTAssertNotNil(attackGame.latestCombatResult)
        XCTAssertNil(attackGame.latestTacticalCommandResult)
    }

    func testLatestCombatResultRecordsAttackerDestroyedByCounter() throws {
        let game = GameState(
            scenario: Self.combatResultScenario(
                attackerKind: .infantry,
                defenderKind: .tank,
                attackerHP: 8,
                defenderHP: UnitKind.tank.baseHP,
                attackerExperience: 0,
                defenderEntrenched: false
            )
        )
        let attacker = try XCTUnwrap(game.units.first { $0.name == "结果攻击方" })
        let defender = try XCTUnwrap(game.units.first { $0.name == "结果防守方" })
        let preview = try XCTUnwrap(game.combatPreview(attacker: attacker, defender: defender))

        game.handleTap(on: attacker.position)
        game.handleTap(on: defender.position)

        let summary = try XCTUnwrap(game.latestCombatResult)
        let finalAttacker = try XCTUnwrap(game.scenario.units.first { $0.id == attacker.id })

        XCTAssertGreaterThan(preview.counterDamage, 0)
        XCTAssertGreaterThan(summary.counterDamage, 0)
        XCTAssertTrue(summary.didDestroyAttacker)
        XCTAssertEqual(summary.attacker.endingHP, 0)
        XCTAssertTrue(finalAttacker.isDestroyed)
        XCTAssertFalse(summary.didDestroyDefender)
    }

    func testThreateningEnemiesDetectsUnitsInRange() throws {
        let game = GameState()
        let exposedRecon = BattleUnit(
            name: "前出侦察",
            kind: .recon,
            faction: .allies,
            position: HexCoordinate(q: 7, r: 2),
            hp: UnitKind.recon.baseHP,
            commander: nil
        )

        let threats = game.threateningEnemies(against: exposedRecon)
        XCTAssertFalse(threats.isEmpty)
        XCTAssertTrue(threats.contains { $0.name == "88炮阵地" || $0.name == "第2装甲集团" })
        XCTAssertEqual(
            game.threateningEnemies(against: .allies, at: exposedRecon.position).map(\.id),
            threats.map(\.id)
        )
        XCTAssertTrue(game.threatenedTiles(for: .allies).contains(exposedRecon.position))
    }

    func testThreatenedReachableTilesExposeDangerousMoves() throws {
        let contestedGame = GameState(scenario: Self.zoneOfControlScenario(includeEnemy: true))
        let openGame = GameState(scenario: Self.zoneOfControlScenario(includeEnemy: false))
        let contestedRecon = try XCTUnwrap(contestedGame.units.first { $0.name == "接敌侦察" })
        let openRecon = try XCTUnwrap(openGame.units.first { $0.name == "接敌侦察" })
        let contactTile = HexCoordinate(q: 1, r: 1)
        let deepThreatTile = HexCoordinate(q: 3, r: 0)

        XCTAssertTrue(contestedGame.reachableTiles(for: contestedRecon).contains(contactTile))
        XCTAssertTrue(contestedGame.threatenedReachableTiles(for: contestedRecon).contains(contactTile))
        XCTAssertTrue(contestedGame.threatenedTiles(for: .allies).contains(deepThreatTile))
        XCTAssertFalse(contestedGame.threatenedReachableTiles(for: contestedRecon).contains(deepThreatTile))
        XCTAssertTrue(openGame.threatenedReachableTiles(for: openRecon).isEmpty)

        contestedGame.handlePrimaryAction(on: contestedRecon.position)
        contestedGame.handlePrimaryAction(on: contactTile)
        XCTAssertTrue(contestedGame.message.contains("暴露在 控制区守军 火力下"))
    }

    func testRouteStepPreviewsExposeCostsControlZonesAndThreats() throws {
        let game = GameState(scenario: Self.zoneOfControlScenario(includeEnemy: true))
        let recon = try XCTUnwrap(game.units.first { $0.name == "接敌侦察" })
        let contactTile = HexCoordinate(q: 1, r: 1)
        let route = try XCTUnwrap(game.movementRoute(for: recon, to: contactTile))

        let steps = game.routeStepPreviews(for: recon, route: route)

        XCTAssertEqual(steps.count, route.stepCount)
        XCTAssertEqual(route.coordinates.first, recon.position)
        XCTAssertEqual(steps.first?.coordinate, contactTile)
        XCTAssertEqual(steps.first?.stepIndex, 1)
        XCTAssertEqual(steps.last?.isDestination, true)
        XCTAssertEqual(steps.map(\.movementCost).reduce(0, +), route.totalCost)
        XCTAssertEqual(steps.map(\.controlZonePenalty).reduce(0, +), route.controlZonePenalty)
        XCTAssertEqual(steps.first?.controlZonePenalty, 1)
        XCTAssertEqual(steps.first?.threatCount, 1)
        XCTAssertEqual(steps.first?.threatNames, ["控制区守军"])

        game.handlePrimaryAction(on: recon.position)
        game.handlePrimaryAction(on: contactTile)

        XCTAssertEqual(game.focusedRouteStepPreviews, steps)
    }

    func testSelectingAndMovingUnitUpdatesBattlefieldState() throws {
        let game = GameState()
        let tank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })

        game.handleTap(on: tank.position)
        XCTAssertEqual(game.selectedUnit?.id, tank.id)
        XCTAssertFalse(game.reachableTiles(for: tank).isEmpty)

        let destination = try XCTUnwrap(game.reachableTiles(for: tank).sorted { $0.id < $1.id }.first)
        game.handleTap(on: destination)

        XCTAssertEqual(game.selectedUnit?.position, destination)
        XCTAssertEqual(game.focusedCoordinate, destination)
        XCTAssertTrue(game.selectedUnit?.hasMoved == true)
    }

    func testPrimaryActionSelectsAndPreviewsWithoutMoving() throws {
        let game = GameState()
        let tank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })

        game.handlePrimaryAction(on: HexCoordinate(q: 0, r: 0))
        XCTAssertNil(game.selectedUnit)
        XCTAssertFalse(game.message.contains("需要先选择"))

        game.handlePrimaryAction(on: tank.position)
        XCTAssertEqual(game.selectedUnit?.id, tank.id)

        let destination = try XCTUnwrap(game.reachableTiles(for: tank).sorted { $0.id < $1.id }.first)
        game.handlePrimaryAction(on: destination)

        let tankAfterPrimaryActions = try XCTUnwrap(game.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterPrimaryActions.position, tank.position)
        XCTAssertFalse(tankAfterPrimaryActions.hasMoved)
        XCTAssertEqual(game.focusedCoordinate, destination)
        XCTAssertTrue(game.message.contains("可进入") || game.message.contains("基础移动"))
    }

    func testSecondaryActionMovesSelectedUnitAndAttacksValidTarget() throws {
        let moveGame = GameState()
        let movingTank = try XCTUnwrap(moveGame.units.first { $0.name == "第4装甲师" })
        moveGame.handlePrimaryAction(on: movingTank.position)
        let destination = try XCTUnwrap(moveGame.reachableTiles(for: movingTank).sorted { $0.id < $1.id }.first)

        moveGame.handleSecondaryAction(on: destination)

        let movedTank = try XCTUnwrap(moveGame.units.first { $0.id == movingTank.id })
        XCTAssertEqual(movedTank.position, destination)
        XCTAssertTrue(movedTank.hasMoved)

        var scenario = Scenario.ardennesPrototype()
        let attackerIndex = try XCTUnwrap(scenario.units.firstIndex { $0.name == "第4装甲师" })
        scenario.units[attackerIndex].position = HexCoordinate(q: 9, r: 4)
        let attackGame = GameState(scenario: scenario)
        let attacker = try XCTUnwrap(attackGame.units.first { $0.name == "第4装甲师" })
        let defender = try XCTUnwrap(attackGame.units.first { $0.name == "第2装甲集团" })

        attackGame.handlePrimaryAction(on: attacker.position)
        attackGame.handlePrimaryAction(on: defender.position)
        XCTAssertEqual(try XCTUnwrap(attackGame.units.first { $0.id == defender.id }).hp, defender.hp)

        attackGame.handleSecondaryAction(on: defender.position)

        let defenderAfterAttack = try XCTUnwrap(attackGame.units.first { $0.id == defender.id })
        let attackerAfterAttack = try XCTUnwrap(attackGame.units.first { $0.id == attacker.id })
        XCTAssertLessThan(defenderAfterAttack.hp, defender.hp)
        XCTAssertTrue(attackerAfterAttack.hasAttacked)
    }

    func testSecondaryActionRejectsInvalidMapOrdersWithoutStateChanges() throws {
        let noSelectionGame = GameState()
        let distantEnemy = try XCTUnwrap(noSelectionGame.units.first { $0.name == "第2装甲集团" })
        let distantEnemyHP = distantEnemy.hp

        noSelectionGame.handleSecondaryAction(on: distantEnemy.position)

        XCTAssertNil(noSelectionGame.selectedUnit)
        XCTAssertEqual(try XCTUnwrap(noSelectionGame.units.first { $0.id == distantEnemy.id }).hp, distantEnemyHP)
        XCTAssertTrue(noSelectionGame.message.contains("需要先选择"))

        let noSelectionTileGame = GameState()
        noSelectionTileGame.handleSecondaryAction(on: HexCoordinate(q: 0, r: 0))

        XCTAssertNil(noSelectionTileGame.selectedUnit)
        XCTAssertTrue(noSelectionTileGame.message.contains("需要先选择"))

        let friendlyBlockedGame = GameState()
        let tank = try XCTUnwrap(friendlyBlockedGame.units.first { $0.name == "第4装甲师" })
        let infantry = try XCTUnwrap(friendlyBlockedGame.units.first { $0.name == "第101空降师" })

        friendlyBlockedGame.handlePrimaryAction(on: tank.position)
        friendlyBlockedGame.handleSecondaryAction(on: infantry.position)

        let tankAfterFriendlyOrder = try XCTUnwrap(friendlyBlockedGame.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterFriendlyOrder.position, tank.position)
        XCTAssertFalse(tankAfterFriendlyOrder.hasMoved)
        XCTAssertTrue(friendlyBlockedGame.message.contains("占据该格"))

        let outOfRangeGame = GameState()
        let attacker = try XCTUnwrap(outOfRangeGame.units.first { $0.name == "第4装甲师" })
        let outOfRangeTarget = try XCTUnwrap(outOfRangeGame.units.first { $0.name == "第2装甲集团" })

        outOfRangeGame.handlePrimaryAction(on: attacker.position)
        outOfRangeGame.handleSecondaryAction(on: outOfRangeTarget.position)

        let attackerAfterRejectedAttack = try XCTUnwrap(outOfRangeGame.units.first { $0.id == attacker.id })
        let targetAfterRejectedAttack = try XCTUnwrap(outOfRangeGame.units.first { $0.id == outOfRangeTarget.id })
        XCTAssertFalse(attackerAfterRejectedAttack.hasAttacked)
        XCTAssertEqual(targetAfterRejectedAttack.hp, outOfRangeTarget.hp)
        XCTAssertTrue(outOfRangeGame.message.contains("超出射程"))

        var spentScenario = Scenario.ardennesPrototype()
        let spentAttackerIndex = try XCTUnwrap(spentScenario.units.firstIndex { $0.name == "第4装甲师" })
        spentScenario.units[spentAttackerIndex].position = HexCoordinate(q: 9, r: 4)
        spentScenario.units[spentAttackerIndex].hasAttacked = true
        let spentGame = GameState(scenario: spentScenario)
        let spentAttacker = try XCTUnwrap(spentGame.units.first { $0.name == "第4装甲师" })
        let spentDefender = try XCTUnwrap(spentGame.units.first { $0.name == "第2装甲集团" })

        spentGame.handlePrimaryAction(on: spentAttacker.position)
        spentGame.handleSecondaryAction(on: spentDefender.position)

        let spentAttackerAfterRejectedAttack = try XCTUnwrap(spentGame.units.first { $0.id == spentAttacker.id })
        let spentDefenderAfterRejectedAttack = try XCTUnwrap(spentGame.units.first { $0.id == spentDefender.id })
        XCTAssertTrue(spentAttackerAfterRejectedAttack.hasAttacked)
        XCTAssertEqual(spentDefenderAfterRejectedAttack.hp, spentDefender.hp)
        XCTAssertTrue(spentGame.message.contains("当前不可攻击"))
    }

    func testMapActionHintsDescribeSelectionMoveAndAttackIntent() throws {
        let moveGame = GameState()
        let tank = try XCTUnwrap(moveGame.units.first { $0.name == "第4装甲师" })
        let infantry = try XCTUnwrap(moveGame.units.first { $0.name == "第101空降师" })
        let distantEnemy = try XCTUnwrap(moveGame.units.first { $0.name == "第2装甲集团" })

        XCTAssertEqual(moveGame.mapActionHint(for: tank.position), .selectableUnit)

        moveGame.handlePrimaryAction(on: tank.position)
        let destination = try XCTUnwrap(moveGame.reachableTiles(for: tank).sorted { $0.id < $1.id }.first)
        let route = try XCTUnwrap(moveGame.movementRoute(for: tank, to: destination))

        XCTAssertEqual(moveGame.mapActionHint(for: tank.position), .selectedUnit)
        XCTAssertEqual(moveGame.mapActionHint(for: infantry.position), .friendlyOccupied)
        XCTAssertEqual(
            moveGame.mapActionHint(for: destination),
            .move(
                cost: route.totalCost,
                controlZonePenalty: route.controlZonePenalty
            )
        )
        XCTAssertEqual(route.coordinates.first, tank.position)
        XCTAssertEqual(route.coordinates.last, destination)
        XCTAssertGreaterThan(route.stepCount, 0)
        moveGame.handlePrimaryAction(on: destination)

        XCTAssertEqual(
            moveGame.focusedMovementRoute,
            route
        )
        XCTAssertEqual(
            moveGame.focusedCommandPreview,
            .move(
                unitName: tank.name,
                terrainName: try XCTUnwrap(moveGame.tile(at: destination)?.terrain.title),
                route: route
            )
        )

        if tank.position.distance(to: distantEnemy.position) > tank.range {
            XCTAssertEqual(
                moveGame.mapActionHint(for: distantEnemy.position),
                .enemyOutOfRange(distance: tank.position.distance(to: distantEnemy.position), range: tank.range)
            )
        }

        var scenario = Scenario.ardennesPrototype()
        let attackerIndex = try XCTUnwrap(scenario.units.firstIndex { $0.name == "第4装甲师" })
        scenario.units[attackerIndex].position = HexCoordinate(q: 9, r: 4)
        let attackGame = GameState(scenario: scenario)
        let attacker = try XCTUnwrap(attackGame.units.first { $0.name == "第4装甲师" })
        let defender = try XCTUnwrap(attackGame.units.first { $0.name == "第2装甲集团" })
        let preview = try XCTUnwrap(attackGame.combatPreview(attacker: attacker, defender: defender))

        attackGame.handlePrimaryAction(on: attacker.position)
        XCTAssertEqual(attackGame.focusedCommandPreview, .selectedUnit(unitName: attacker.name))
        attackGame.handlePrimaryAction(on: defender.position)
        let attackCoverage = attackGame.attackCoverageTiles(for: attacker)

        XCTAssertTrue(attackCoverage.contains(defender.position))
        XCTAssertFalse(attackCoverage.contains(attacker.position))
        XCTAssertTrue(attackGame.attackableTiles(for: attacker).isSubset(of: attackCoverage))
        XCTAssertEqual(
            attackGame.mapActionHint(for: defender.position),
            .attack(
                damage: preview.damage,
                counterDamage: preview.counterDamage,
                willDestroy: preview.willDestroyDefender
            )
        )
        XCTAssertEqual(
            attackGame.focusedCommandPreview,
            .attack(
                attackerName: attacker.name,
                defenderName: defender.name,
                damage: preview.damage,
                counterDamage: preview.counterDamage,
                defenderHPAfterAttack: preview.defenderHPAfterAttack,
                willDestroy: preview.willDestroyDefender
            )
        )

        var spentScenario = Scenario.ardennesPrototype()
        let spentAttackerIndex = try XCTUnwrap(spentScenario.units.firstIndex { $0.name == "第4装甲师" })
        spentScenario.units[spentAttackerIndex].position = HexCoordinate(q: 9, r: 4)
        spentScenario.units[spentAttackerIndex].hasAttacked = true
        let spentGame = GameState(scenario: spentScenario)
        let spentAttacker = try XCTUnwrap(spentGame.units.first { $0.name == "第4装甲师" })
        let spentDefender = try XCTUnwrap(spentGame.units.first { $0.name == "第2装甲集团" })

        spentGame.handlePrimaryAction(on: spentAttacker.position)
        spentGame.handlePrimaryAction(on: spentDefender.position)

        XCTAssertTrue(spentGame.attackCoverageTiles(for: spentAttacker).isEmpty)
        XCTAssertTrue(spentGame.attackableTiles(for: spentAttacker).isEmpty)
        XCTAssertEqual(
            spentGame.mapActionHint(for: spentDefender.position),
            .enemyUnavailable(
                distance: spentAttacker.position.distance(to: spentDefender.position),
                range: spentAttacker.range
            )
        )
        XCTAssertEqual(
            spentGame.focusedCommandPreview,
            .enemyUnavailable(
                defenderName: spentDefender.name,
                distance: spentAttacker.position.distance(to: spentDefender.position),
                range: spentAttacker.range
            )
        )
    }

    func testFocusingMapTargetsDoesNotExecuteOrders() throws {
        let game = GameState()
        let tank = try XCTUnwrap(game.units.first { $0.name == "第4装甲师" })
        let enemy = try XCTUnwrap(game.units.first { $0.name == "第2装甲集团" })
        let objective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "南部桥头堡" })

        game.focus(unitID: enemy.id)

        XCTAssertNil(game.selectedUnit)
        XCTAssertEqual(game.focusedCoordinate, enemy.position)
        XCTAssertEqual(try XCTUnwrap(game.units.first { $0.id == enemy.id }).hp, enemy.hp)
        XCTAssertTrue(game.message.contains(enemy.name))

        game.focus(coordinate: objective.coordinate)

        XCTAssertNil(game.selectedUnit)
        XCTAssertEqual(game.focusedCoordinate, objective.coordinate)
        XCTAssertEqual(try XCTUnwrap(game.units.first { $0.id == enemy.id }).hp, enemy.hp)
        XCTAssertTrue(game.message.contains(objective.objectiveName ?? ""))

        game.select(unitID: tank.id)
        game.focus(unitID: enemy.id)

        let tankAfterFocus = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let enemyAfterFocus = try XCTUnwrap(game.units.first { $0.id == enemy.id })
        XCTAssertEqual(game.selectedUnit?.id, tank.id)
        XCTAssertEqual(game.focusedCoordinate, enemy.position)
        XCTAssertEqual(tankAfterFocus.position, tank.position)
        XCTAssertFalse(tankAfterFocus.hasMoved)
        XCTAssertFalse(tankAfterFocus.hasAttacked)
        XCTAssertEqual(enemyAfterFocus.hp, enemy.hp)
        XCTAssertTrue(game.message.contains("射程") || game.message.contains("攻击位"))
    }

    func testFocusedMovePreviewShowsPostMoveAttackOpportunities() throws {
        let game = GameState(scenario: Self.postMoveAttackScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "机动装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "前方守军" })
        let destination = HexCoordinate(q: 3, r: 0)

        game.handlePrimaryAction(on: tank.position)

        XCTAssertFalse(game.attackableTiles(for: tank).contains(target.position))
        XCTAssertTrue(game.postMoveAttackOpportunities(for: tank, to: destination).contains { $0.id == target.id })

        game.handlePrimaryAction(on: destination)

        XCTAssertEqual(game.focusedMovementRoute?.destination, destination)
        XCTAssertEqual(game.focusedPostMoveAttackOpportunities.map(\.id), [target.id])
        XCTAssertTrue(game.message.contains("移动后可攻击 \(target.name)"))

        game.handleSecondaryAction(on: destination)

        let movedTank = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterMove = try XCTUnwrap(game.units.first { $0.id == target.id })
        XCTAssertEqual(movedTank.position, destination)
        XCTAssertTrue(movedTank.hasMoved)
        XCTAssertFalse(movedTank.hasAttacked)
        XCTAssertTrue(game.attackableTiles(for: movedTank).contains(target.position))
        XCTAssertEqual(game.focusedCoordinate, target.position)
        XCTAssertTrue(game.message.contains("再次右键可攻击"))

        let followUpPreview = try XCTUnwrap(game.combatPreview(attacker: movedTank, defender: targetAfterMove))
        XCTAssertEqual(
            game.focusedCommandPreview,
            .attack(
                attackerName: movedTank.name,
                defenderName: targetAfterMove.name,
                damage: followUpPreview.damage,
                counterDamage: followUpPreview.counterDamage,
                defenderHPAfterAttack: followUpPreview.defenderHPAfterAttack,
                willDestroy: followUpPreview.willDestroyDefender
            )
        )

        game.handleSecondaryAction(on: target.position)

        let tankAfterAttack = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterAttack = try XCTUnwrap(game.scenario.units.first { $0.id == target.id })
        XCTAssertTrue(tankAfterAttack.hasAttacked)
        XCTAssertLessThan(targetAfterAttack.hp, target.hp)
    }

    func testPostMoveAttackPreviewsMatchCombatPreviewFromDestination() throws {
        let game = GameState(scenario: Self.postMoveAttackScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "机动装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "前方守军" })
        let destination = HexCoordinate(q: 3, r: 0)

        game.handlePrimaryAction(on: tank.position)
        game.handlePrimaryAction(on: destination)

        var movedAttacker = tank
        movedAttacker.position = destination
        let expectedCombat = try XCTUnwrap(game.combatPreview(attacker: movedAttacker, defender: target))
        let previews = game.postMoveAttackPreviews(for: tank, to: destination)

        XCTAssertEqual(previews.count, 1)
        XCTAssertEqual(game.focusedPostMoveAttackPreviews, previews)
        XCTAssertEqual(previews.first?.targetID, target.id)
        XCTAssertEqual(previews.first?.targetName, target.name)
        XCTAssertEqual(previews.first?.damage, expectedCombat.damage)
        XCTAssertEqual(previews.first?.counterDamage, expectedCombat.counterDamage)
        XCTAssertEqual(previews.first?.defenderHPAfterAttack, expectedCombat.defenderHPAfterAttack)
        XCTAssertEqual(previews.first?.willDestroy, expectedCombat.willDestroyDefender)
    }

    func testFireExposurePreviewMatchesEnemyCombatPreviewFromDestination() throws {
        let game = GameState(scenario: Self.postMoveAttackScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "机动装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "前方守军" })
        let destination = HexCoordinate(q: 3, r: 0)
        let startingLogCount = game.battleLog.count

        var movedDefender = tank
        movedDefender.position = destination
        movedDefender.tacticalStatus = .normal
        movedDefender.isEntrenched = false
        let expectedCombat = try XCTUnwrap(game.combatPreview(attacker: target, defender: movedDefender))
        let exposure = try XCTUnwrap(game.fireExposurePreview(for: tank, at: destination))

        XCTAssertEqual(exposure.coordinate, destination)
        XCTAssertEqual(exposure.currentHP, tank.hp)
        XCTAssertEqual(exposure.sources.map(\.sourceID), [target.id])
        XCTAssertEqual(exposure.sources.first?.sourceName, target.name)
        XCTAssertEqual(exposure.sources.first?.sourceKind, target.kind)
        XCTAssertEqual(exposure.sources.first?.distance, 1)
        XCTAssertEqual(exposure.sources.first?.range, target.range)
        XCTAssertEqual(exposure.sources.first?.potentialDamage, expectedCombat.damage)
        XCTAssertEqual(exposure.totalPotentialDamage, expectedCombat.damage)
        XCTAssertEqual(exposure.highestSingleDamage, expectedCombat.damage)
        XCTAssertEqual(exposure.projectedHPAfterExposure, max(0, tank.hp - expectedCombat.damage))
        XCTAssertNotEqual(exposure.riskLevel, .none)
        XCTAssertNil(game.latestCombatResult)

        let unchangedTank = try XCTUnwrap(game.units.first { $0.id == tank.id })
        XCTAssertEqual(unchangedTank.position, tank.position)
        XCTAssertEqual(unchangedTank.hp, tank.hp)
        XCTAssertFalse(unchangedTank.hasMoved)
        XCTAssertFalse(unchangedTank.hasAttacked)
        XCTAssertEqual(game.battleLog.count, startingLogCount)
    }

    func testFireExposurePreviewReportsNoRiskAndCriticalRisk() throws {
        let safeGame = GameState(scenario: Self.postMoveAttackScenario())
        let safeTank = try XCTUnwrap(safeGame.units.first { $0.name == "机动装甲" })
        let safeExposure = try XCTUnwrap(safeGame.fireExposurePreview(for: safeTank, at: HexCoordinate(q: 1, r: 0)))

        XCTAssertEqual(safeExposure.riskLevel, .none)
        XCTAssertTrue(safeExposure.sources.isEmpty)
        XCTAssertEqual(safeExposure.totalPotentialDamage, 0)
        XCTAssertEqual(safeExposure.projectedHPAfterExposure, safeTank.hp)

        var criticalScenario = Self.postMoveAttackScenario()
        let tankIndex = try XCTUnwrap(criticalScenario.units.firstIndex { $0.name == "机动装甲" })
        criticalScenario.units[tankIndex].hp = 10
        let criticalGame = GameState(scenario: criticalScenario)
        let criticalTank = try XCTUnwrap(criticalGame.units.first { $0.name == "机动装甲" })
        let criticalExposure = try XCTUnwrap(criticalGame.fireExposurePreview(for: criticalTank, at: HexCoordinate(q: 3, r: 0)))

        XCTAssertEqual(criticalExposure.riskLevel, .critical)
        XCTAssertTrue(criticalExposure.canBeDestroyedByCombinedFire)
        XCTAssertEqual(criticalExposure.projectedHPAfterExposure, 0)
    }

    func testSafeEngagementOptionsPreferLowerExposureWithoutChangingDefaultApproach() throws {
        let game = GameState(scenario: Self.safeEngagementScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "接敌装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "主目标" })
        let defaultDestination = HexCoordinate(q: 3, r: 0)
        let saferDestination = HexCoordinate(q: 3, r: 1)

        game.handlePrimaryAction(on: tank.position)
        game.handlePrimaryAction(on: target.position)

        let defaultRoute = try XCTUnwrap(game.focusedAttackPositionRoute)
        XCTAssertEqual(defaultRoute.destination, defaultDestination)
        XCTAssertEqual(game.focusedFireExposurePreview?.coordinate, defaultDestination)

        let options = game.focusedSafeEngagementOptions
        XCTAssertEqual(options.count, game.focusedAttackPositionRoutes.count)
        XCTAssertEqual(options.first?.route.destination, saferDestination)
        XCTAssertLessThan(
            try XCTUnwrap(options.first?.exposure.totalPotentialDamage),
            try XCTUnwrap(game.focusedFireExposurePreview?.totalPotentialDamage)
        )
        XCTAssertTrue(options.allSatisfy { option in
            game.focusedAttackPositionRoutes.contains(option.route)
        })

        game.executeFocusedCommand()

        let movedTank = try XCTUnwrap(game.units.first { $0.id == tank.id })
        XCTAssertEqual(movedTank.position, defaultDestination)
        XCTAssertNotEqual(movedTank.position, saferDestination)
        XCTAssertFalse(movedTank.hasAttacked)
        XCTAssertEqual(game.focusedCoordinate, target.position)
    }

    func testSafeEngagementOptionFocusesPreviewBeforeExecuting() throws {
        let game = GameState(scenario: Self.safeEngagementScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "接敌装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "主目标" })
        let defaultDestination = HexCoordinate(q: 3, r: 0)
        let saferDestination = HexCoordinate(q: 3, r: 1)

        game.handlePrimaryAction(on: tank.position)
        game.handlePrimaryAction(on: target.position)

        XCTAssertEqual(game.focusedAttackPositionRoute?.destination, defaultDestination)

        let safeOption = try XCTUnwrap(game.focusedSafeEngagementOptions.first)
        XCTAssertEqual(safeOption.route.destination, saferDestination)

        game.focusSafeEngagementOption(safeOption)

        let tankAfterFocus = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterFocus.position, tank.position)
        XCTAssertFalse(tankAfterFocus.hasMoved)
        XCTAssertFalse(tankAfterFocus.hasAttacked)
        XCTAssertEqual(game.focusedCoordinate, target.position)
        XCTAssertEqual(game.focusedSafeEngagementDestination, saferDestination)
        XCTAssertEqual(game.focusedAttackPositionRoute?.destination, saferDestination)
        XCTAssertEqual(game.focusedFireExposurePreview?.coordinate, saferDestination)
        XCTAssertNil(game.latestCombatResult)
        XCTAssertNil(game.latestTacticalCommandResult)
        XCTAssertNil(game.latestObjectiveCaptureResult)

        guard case let .approachAttack(_, defenderName, route) = game.focusedCommandPreview else {
            return XCTFail("safe engagement focus should keep an executable POS preview")
        }
        XCTAssertEqual(defenderName, target.name)
        XCTAssertEqual(route.destination, saferDestination)

        game.executeFocusedCommand()

        let movedTank = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(movedTank.position, saferDestination)
        XCTAssertTrue(movedTank.hasMoved)
        XCTAssertFalse(movedTank.hasAttacked)
        XCTAssertEqual(game.focusedCoordinate, target.position)
        XCTAssertNil(game.focusedSafeEngagementDestination)
    }

    func testSafeEngagementFocusRejectsUnavailableCandidateWithoutExecuting() throws {
        var scenario = Self.safeEngagementScenario()
        let tankIndex = try XCTUnwrap(scenario.units.firstIndex { $0.name == "接敌装甲" })
        scenario.units[tankIndex].hasMoved = true
        let game = GameState(scenario: scenario)
        let tank = try XCTUnwrap(game.units.first { $0.name == "接敌装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "主目标" })
        let saferDestination = HexCoordinate(q: 3, r: 1)

        game.handlePrimaryAction(on: tank.position)
        game.handlePrimaryAction(on: target.position)
        game.focusSafeEngagement(targetID: target.id, destination: saferDestination)

        let tankAfterFocus = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterFocus.position, tank.position)
        XCTAssertTrue(tankAfterFocus.hasMoved)
        XCTAssertFalse(tankAfterFocus.hasAttacked)
        XCTAssertNil(game.focusedSafeEngagementDestination)
        XCTAssertNil(game.focusedAttackPositionRoute)
        XCTAssertNil(game.focusedFireExposurePreview)
    }

    func testSafeEngagementFocusRejectsStaleTargetAndOccupiedDestination() throws {
        var destroyedScenario = Self.safeEngagementScenario()
        let destroyedTargetIndex = try XCTUnwrap(destroyedScenario.units.firstIndex { $0.name == "主目标" })
        let destroyedTargetID = destroyedScenario.units[destroyedTargetIndex].id
        destroyedScenario.units[destroyedTargetIndex].hp = 0
        let destroyedGame = GameState(scenario: destroyedScenario)
        let destroyedTank = try XCTUnwrap(destroyedGame.units.first { $0.name == "接敌装甲" })

        destroyedGame.handlePrimaryAction(on: destroyedTank.position)
        destroyedGame.focusSafeEngagement(targetID: destroyedTargetID, destination: HexCoordinate(q: 3, r: 1))

        XCTAssertNil(destroyedGame.focusedSafeEngagementDestination)
        XCTAssertNil(destroyedGame.focusedAttackPositionRoute)

        let alliedGame = GameState(scenario: Self.safeEngagementScenario())
        let alliedTank = try XCTUnwrap(alliedGame.units.first { $0.name == "接敌装甲" })

        alliedGame.handlePrimaryAction(on: alliedTank.position)
        alliedGame.focusSafeEngagement(targetID: alliedTank.id, destination: HexCoordinate(q: 3, r: 1))

        XCTAssertNil(alliedGame.focusedSafeEngagementDestination)
        XCTAssertNil(alliedGame.focusedAttackPositionRoute)

        var occupiedScenario = Self.safeEngagementScenario()
        let occupiedTank = try XCTUnwrap(occupiedScenario.units.first { $0.name == "接敌装甲" })
        let occupiedTarget = try XCTUnwrap(occupiedScenario.units.first { $0.name == "主目标" })
        occupiedScenario.units.append(
            BattleUnit(
                name: "占位友军",
                kind: .infantry,
                faction: .allies,
                position: HexCoordinate(q: 3, r: 1),
                hp: UnitKind.infantry.baseHP,
                commander: nil
            )
        )
        let occupiedGame = GameState(scenario: occupiedScenario)

        occupiedGame.handlePrimaryAction(on: occupiedTank.position)
        occupiedGame.handlePrimaryAction(on: occupiedTarget.position)
        occupiedGame.focusSafeEngagement(targetID: occupiedTarget.id, destination: HexCoordinate(q: 3, r: 1))

        XCTAssertNil(occupiedGame.focusedSafeEngagementDestination)
        XCTAssertNotEqual(occupiedGame.focusedAttackPositionRoute?.destination, HexCoordinate(q: 3, r: 1))
        XCTAssertEqual(
            occupiedGame.scenario.units.first { $0.id == occupiedTank.id }?.position,
            occupiedTank.position
        )
    }

    func testFocusedAttackPositionRouteIsNilWhenTargetAlreadyAttackable() throws {
        let game = GameState(scenario: Self.postMoveAttackScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "机动装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "前方守军" })
        let destination = HexCoordinate(q: 3, r: 0)

        game.handlePrimaryAction(on: tank.position)
        game.handleSecondaryAction(on: destination)

        XCTAssertEqual(game.focusedCoordinate, target.position)
        XCTAssertTrue(try XCTUnwrap(game.selectedUnit).position.distance(to: target.position) <= tank.range)
        XCTAssertNil(game.focusedAttackPositionRoute)
        XCTAssertNil(game.focusedFireExposurePreview)
    }

    func testExecuteFocusedCommandRunsMoveAttackAndApproachOrders() throws {
        let moveGame = GameState(scenario: Self.postMoveAttackScenario())
        let moveTank = try XCTUnwrap(moveGame.units.first { $0.name == "机动装甲" })
        let moveTarget = try XCTUnwrap(moveGame.units.first { $0.name == "前方守军" })
        let destination = HexCoordinate(q: 3, r: 0)

        moveGame.handlePrimaryAction(on: moveTank.position)
        moveGame.focus(coordinate: destination)
        moveGame.executeFocusedCommand()

        let movedTank = try XCTUnwrap(moveGame.units.first { $0.id == moveTank.id })
        XCTAssertEqual(movedTank.position, destination)
        XCTAssertTrue(movedTank.hasMoved)
        XCTAssertFalse(movedTank.hasAttacked)
        XCTAssertEqual(moveGame.focusedCoordinate, moveTarget.position)
        XCTAssertTrue(moveGame.message.contains("再次点执行可攻击"))

        moveGame.executeFocusedCommand()

        let moveTargetAfterAttack = try XCTUnwrap(moveGame.scenario.units.first { $0.id == moveTarget.id })
        XCTAssertTrue(try XCTUnwrap(moveGame.units.first { $0.id == moveTank.id }).hasAttacked)
        XCTAssertLessThan(moveTargetAfterAttack.hp, moveTarget.hp)

        var attackScenario = Scenario.ardennesPrototype()
        let attackerIndex = try XCTUnwrap(attackScenario.units.firstIndex { $0.name == "第4装甲师" })
        attackScenario.units[attackerIndex].position = HexCoordinate(q: 9, r: 4)
        let attackGame = GameState(scenario: attackScenario)
        let attacker = try XCTUnwrap(attackGame.units.first { $0.name == "第4装甲师" })
        let defender = try XCTUnwrap(attackGame.units.first { $0.name == "第2装甲集团" })

        attackGame.handlePrimaryAction(on: attacker.position)
        attackGame.focus(unitID: defender.id)
        attackGame.executeFocusedCommand()

        let defenderAfterAttack = try XCTUnwrap(attackGame.units.first { $0.id == defender.id })
        XCTAssertLessThan(defenderAfterAttack.hp, defender.hp)
        XCTAssertTrue(try XCTUnwrap(attackGame.units.first { $0.id == attacker.id }).hasAttacked)

        let approachGame = GameState(scenario: Self.postMoveAttackScenario())
        let approachTank = try XCTUnwrap(approachGame.units.first { $0.name == "机动装甲" })
        let approachTarget = try XCTUnwrap(approachGame.units.first { $0.name == "前方守军" })

        approachGame.handlePrimaryAction(on: approachTank.position)
        approachGame.focus(unitID: approachTarget.id)
        approachGame.executeFocusedCommand()

        let approachTankAfterMove = try XCTUnwrap(approachGame.units.first { $0.id == approachTank.id })
        let approachTargetAfterMove = try XCTUnwrap(approachGame.units.first { $0.id == approachTarget.id })
        XCTAssertEqual(approachTankAfterMove.position, destination)
        XCTAssertTrue(approachTankAfterMove.hasMoved)
        XCTAssertFalse(approachTankAfterMove.hasAttacked)
        XCTAssertEqual(approachTargetAfterMove.hp, approachTarget.hp)
        XCTAssertEqual(approachGame.focusedCoordinate, approachTarget.position)
        XCTAssertTrue(approachGame.message.contains("再次点执行可攻击"))

        approachGame.executeFocusedCommand()

        let approachTargetAfterAttack = try XCTUnwrap(approachGame.scenario.units.first { $0.id == approachTarget.id })
        XCTAssertTrue(try XCTUnwrap(approachGame.units.first { $0.id == approachTank.id }).hasAttacked)
        XCTAssertLessThan(approachTargetAfterAttack.hp, approachTarget.hp)
    }

    func testDirectTapMoveCanChainIntoFollowUpAttack() throws {
        let game = GameState(scenario: Self.postMoveAttackScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "机动装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "前方守军" })
        let destination = HexCoordinate(q: 3, r: 0)

        game.handleTap(on: tank.position)
        game.handleTap(on: destination)

        let movedTank = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterMove = try XCTUnwrap(game.units.first { $0.id == target.id })
        XCTAssertEqual(movedTank.position, destination)
        XCTAssertTrue(movedTank.hasMoved)
        XCTAssertFalse(movedTank.hasAttacked)
        XCTAssertEqual(game.focusedCoordinate, target.position)
        XCTAssertTrue(game.message.contains("继续点击可攻击"))

        let followUpPreview = try XCTUnwrap(game.combatPreview(attacker: movedTank, defender: targetAfterMove))
        XCTAssertEqual(
            game.focusedCommandPreview,
            .attack(
                attackerName: movedTank.name,
                defenderName: targetAfterMove.name,
                damage: followUpPreview.damage,
                counterDamage: followUpPreview.counterDamage,
                defenderHPAfterAttack: followUpPreview.defenderHPAfterAttack,
                willDestroy: followUpPreview.willDestroyDefender
            )
        )

        game.handleTap(on: target.position)

        let tankAfterAttack = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterAttack = try XCTUnwrap(game.scenario.units.first { $0.id == target.id })
        XCTAssertTrue(tankAfterAttack.hasAttacked)
        XCTAssertLessThan(targetAfterAttack.hp, target.hp)
    }

    func testFocusedOutOfRangeEnemyShowsReachableAttackPositions() throws {
        let game = GameState(scenario: Self.postMoveAttackScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "机动装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "前方守军" })
        let expectedPosition = HexCoordinate(q: 3, r: 0)

        game.handlePrimaryAction(on: tank.position)
        game.handlePrimaryAction(on: target.position)

        let approachRoute = try XCTUnwrap(game.focusedAttackPositionRoute)
        XCTAssertTrue(game.message.contains("右键命令 \(tank.name)"))
        XCTAssertTrue(game.message.contains("攻击位"))
        XCTAssertEqual(
            game.mapActionHint(for: target.position),
            .approachAttack(
                cost: approachRoute.totalCost,
                controlZonePenalty: approachRoute.controlZonePenalty
            )
        )
        XCTAssertEqual(
            game.focusedCommandPreview,
            .approachAttack(
                unitName: tank.name,
                defenderName: target.name,
                route: approachRoute
            )
        )

        let attackPositions = game.focusedAttackPositionRoutes.map(\.destination)
        XCTAssertTrue(attackPositions.contains(expectedPosition))
        XCTAssertEqual(approachRoute.destination, game.focusedAttackPositionRoutes.first?.destination)
        XCTAssertEqual(approachRoute.destination, expectedPosition)
        XCTAssertEqual(approachRoute.coordinates.first, tank.position)
        XCTAssertTrue(approachRoute.coordinates.contains(expectedPosition))
        XCTAssertTrue(game.focusedAttackPositionRoutes.allSatisfy { route in
            game.postMoveAttackOpportunities(for: tank, to: route.destination).contains { $0.id == target.id }
        })
        XCTAssertEqual(game.focusedRouteStepPreviews.last?.coordinate, expectedPosition)
        XCTAssertEqual(
            game.focusedRouteStepPreviews.map(\.movementCost).reduce(0, +),
            approachRoute.totalCost
        )
        XCTAssertTrue(game.focusedRouteStepPreviews.contains { step in
            step.coordinate == expectedPosition &&
                step.threatNames.contains(target.name) &&
                step.controlZonePenalty > 0
        })

        game.handleSecondaryAction(on: target.position)

        let movedTank = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterApproach = try XCTUnwrap(game.units.first { $0.id == target.id })
        XCTAssertEqual(movedTank.position, expectedPosition)
        XCTAssertTrue(movedTank.hasMoved)
        XCTAssertFalse(movedTank.hasAttacked)
        XCTAssertEqual(targetAfterApproach.hp, target.hp)
        XCTAssertTrue(game.attackableTiles(for: movedTank).contains(target.position))
        XCTAssertEqual(game.focusedCoordinate, target.position)
        XCTAssertTrue(game.message.contains("再次右键可攻击"))

        let approachAttackPreview = try XCTUnwrap(game.combatPreview(attacker: movedTank, defender: targetAfterApproach))
        XCTAssertEqual(
            game.focusedCommandPreview,
            .attack(
                attackerName: movedTank.name,
                defenderName: targetAfterApproach.name,
                damage: approachAttackPreview.damage,
                counterDamage: approachAttackPreview.counterDamage,
                defenderHPAfterAttack: approachAttackPreview.defenderHPAfterAttack,
                willDestroy: approachAttackPreview.willDestroyDefender
            )
        )

        game.handleSecondaryAction(on: target.position)

        let tankAfterAttack = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterAttack = try XCTUnwrap(game.scenario.units.first { $0.id == target.id })
        XCTAssertTrue(tankAfterAttack.hasAttacked)
        XCTAssertLessThan(targetAfterAttack.hp, target.hp)

        let previewGame = GameState(scenario: Self.postMoveAttackScenario())
        let previewTank = try XCTUnwrap(previewGame.units.first { $0.name == "机动装甲" })
        let previewTarget = try XCTUnwrap(previewGame.units.first { $0.name == "前方守军" })
        previewGame.handlePrimaryAction(on: previewTank.position)
        previewGame.handlePrimaryAction(on: expectedPosition)

        XCTAssertEqual(previewGame.focusedMovementRoute?.destination, expectedPosition)
        XCTAssertEqual(previewGame.focusedPostMoveAttackOpportunities.map(\.id), [previewTarget.id])
    }

    func testDirectTapApproachCanChainIntoFollowUpAttack() throws {
        let game = GameState(scenario: Self.postMoveAttackScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "机动装甲" })
        let target = try XCTUnwrap(game.units.first { $0.name == "前方守军" })
        let expectedPosition = HexCoordinate(q: 3, r: 0)

        game.handleTap(on: tank.position)
        game.handleTap(on: target.position)

        let movedTank = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterApproach = try XCTUnwrap(game.units.first { $0.id == target.id })
        XCTAssertEqual(movedTank.position, expectedPosition)
        XCTAssertTrue(movedTank.hasMoved)
        XCTAssertFalse(movedTank.hasAttacked)
        XCTAssertEqual(targetAfterApproach.hp, target.hp)
        XCTAssertEqual(game.focusedCoordinate, target.position)
        XCTAssertTrue(game.message.contains("继续点击可攻击"))

        game.handleTap(on: target.position)

        let tankAfterAttack = try XCTUnwrap(game.units.first { $0.id == tank.id })
        let targetAfterAttack = try XCTUnwrap(game.scenario.units.first { $0.id == target.id })
        XCTAssertTrue(tankAfterAttack.hasAttacked)
        XCTAssertLessThan(targetAfterAttack.hp, target.hp)
    }

    func testObjectiveQuickFocusTargetsNearestUnoccupiedObjective() throws {
        let game = GameState(scenario: Self.objectiveAdvanceScenario(includeOccupiedDecoy: true))
        let tank = try XCTUnwrap(game.units.first { $0.name == "目标推进装甲" })
        let occupiedObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "占据村镇" })
        let targetObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "前线据点" })

        game.handlePrimaryAction(on: tank.position)

        XCTAssertEqual(game.nearestObjectiveTarget(for: tank)?.coordinate, targetObjective.coordinate)
        XCTAssertNil(game.objectiveAdvanceRoute(for: tank, to: occupiedObjective))

        let route = try XCTUnwrap(game.objectiveAdvanceRoute(for: tank, to: targetObjective))
        XCTAssertEqual(route.destination, targetObjective.coordinate)

        game.focusNearestObjectiveTarget()

        XCTAssertEqual(game.focusedCoordinate, targetObjective.coordinate)
        XCTAssertEqual(game.guidedObjectiveCoordinate, targetObjective.coordinate)
        XCTAssertTrue(game.message.contains("夺取前线据点"))
        XCTAssertEqual(
            game.focusedCommandPreview,
            .move(
                unitName: tank.name,
                terrainName: try XCTUnwrap(game.tile(at: targetObjective.coordinate)?.terrain.title),
                route: route
            )
        )

        game.executeFocusedCommand()

        let tankAfterMove = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterMove.position, targetObjective.coordinate)
        XCTAssertEqual(game.tile(at: targetObjective.coordinate)?.owner, .allies)
        XCTAssertNil(game.guidedObjectiveCoordinate)

        let summary = try XCTUnwrap(game.latestObjectiveCaptureResult)
        XCTAssertEqual(summary.objectiveName, "前线据点")
        XCTAssertEqual(summary.coordinate, targetObjective.coordinate)
        XCTAssertEqual(summary.previousOwner, .axis)
        XCTAssertEqual(summary.newOwner, .allies)
    }

    func testObjectiveAdvancePreviewSummarizesDirectObjectivePlan() throws {
        let game = GameState(scenario: Self.objectiveAdvanceScenario(includeOccupiedDecoy: true))
        let tank = try XCTUnwrap(game.units.first { $0.name == "目标推进装甲" })
        let occupiedObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "占据村镇" })
        let targetObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "前线据点" })

        game.handlePrimaryAction(on: tank.position)

        let previews = game.objectiveAdvancePreviews(for: tank)
        let preview = try XCTUnwrap(previews.first)
        XCTAssertEqual(previews.count, 1)
        XCTAssertEqual(preview.coordinate, targetObjective.coordinate)
        XCTAssertEqual(preview.coordinate, game.nearestObjectiveTarget(for: tank)?.coordinate)
        XCTAssertNotEqual(preview.coordinate, occupiedObjective.coordinate)
        XCTAssertEqual(preview.objectiveName, "前线据点")
        XCTAssertEqual(preview.owner, .axis)
        XCTAssertEqual(preview.route.destination, targetObjective.coordinate)
        XCTAssertTrue(preview.reachesObjective)
        XCTAssertEqual(preview.currentDistance, 2)
        XCTAssertEqual(preview.remainingDistance, 0)
        XCTAssertEqual(preview.fireExposure?.coordinate, targetObjective.coordinate)
        XCTAssertEqual(preview.fireExposure?.riskLevel, FireRiskLevel.none)
        XCTAssertEqual(game.focusedObjectiveAdvancePreviews, previews)
    }

    func testObjectiveAdvancePreviewIncludesTerminalFireExposure() throws {
        let game = GameState(scenario: Self.objectiveAdvanceFireRiskScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "冒险装甲" })
        let targetObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "炮火据点" })

        game.handlePrimaryAction(on: tank.position)

        let preview = try XCTUnwrap(game.objectiveAdvancePreviews(for: tank).first)
        XCTAssertEqual(preview.coordinate, targetObjective.coordinate)
        XCTAssertEqual(preview.route.destination, targetObjective.coordinate)

        let exposure = try XCTUnwrap(preview.fireExposure)
        XCTAssertEqual(exposure.coordinate, targetObjective.coordinate)
        XCTAssertGreaterThan(exposure.totalPotentialDamage, 0)
        XCTAssertNotEqual(exposure.riskLevel, FireRiskLevel.none)
        XCTAssertEqual(exposure.sources.first?.sourceName, "火力警戒炮")
    }

    func testObjectiveQuickFocusAdvancesTowardDistantObjective() throws {
        let game = GameState(scenario: Self.distantObjectiveAdvanceScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "目标推进装甲" })
        let targetObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "纵深据点" })
        let expectedAdvance = HexCoordinate(q: 4, r: 0)

        game.handlePrimaryAction(on: tank.position)

        XCTAssertEqual(game.nearestObjectiveTarget(for: tank)?.coordinate, targetObjective.coordinate)
        let route = try XCTUnwrap(game.objectiveAdvanceRoute(for: tank, to: targetObjective))
        XCTAssertEqual(route.destination, expectedAdvance)

        game.focusNearestObjectiveTarget()

        XCTAssertEqual(game.focusedCoordinate, expectedAdvance)
        XCTAssertEqual(game.guidedObjectiveCoordinate, targetObjective.coordinate)
        XCTAssertTrue(game.message.contains("向纵深据点"))
        XCTAssertTrue(game.message.contains("距目标剩 1 格"))
        XCTAssertEqual(
            game.focusedCommandPreview,
            .move(
                unitName: tank.name,
                terrainName: try XCTUnwrap(game.tile(at: expectedAdvance)?.terrain.title),
                route: route
            )
        )

        game.executeFocusedCommand()

        let tankAfterAdvance = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterAdvance.position, expectedAdvance)
        XCTAssertEqual(game.guidedObjectiveCoordinate, targetObjective.coordinate)
        XCTAssertNil(game.latestObjectiveCaptureResult)

        game.focus(coordinate: targetObjective.coordinate)

        XCTAssertNil(game.guidedObjectiveCoordinate)
    }

    func testObjectiveAdvancePreviewSummarizesDistantObjectivePlan() throws {
        let game = GameState(scenario: Self.distantObjectiveAdvanceScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "目标推进装甲" })
        let targetObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "纵深据点" })
        let expectedAdvance = HexCoordinate(q: 4, r: 0)

        game.handlePrimaryAction(on: tank.position)

        let preview = try XCTUnwrap(game.objectiveAdvancePreviews(for: tank).first)
        XCTAssertEqual(preview.coordinate, targetObjective.coordinate)
        XCTAssertEqual(preview.coordinate, game.nearestObjectiveTarget(for: tank)?.coordinate)
        XCTAssertEqual(preview.route.destination, expectedAdvance)
        XCTAssertFalse(preview.reachesObjective)
        XCTAssertEqual(preview.currentDistance, 5)
        XCTAssertEqual(preview.remainingDistance, 1)
        XCTAssertEqual(preview.fireExposure?.coordinate, expectedAdvance)
        XCTAssertEqual(preview.fireExposure?.riskLevel, FireRiskLevel.none)
    }

    func testObjectiveAdvancePreviewsLimitAndPreserveShortcutOrder() throws {
        let game = GameState(scenario: Self.multipleObjectiveAdvancePreviewScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "计划装甲" })

        game.handlePrimaryAction(on: tank.position)

        let defaultPreviews = game.objectiveAdvancePreviews(for: tank)
        XCTAssertEqual(defaultPreviews.map(\.objectiveName), ["一号据点", "二号据点", "三号据点"])
        XCTAssertEqual(defaultPreviews.count, 3)
        XCTAssertEqual(defaultPreviews.first?.coordinate, game.nearestObjectiveTarget(for: tank)?.coordinate)
        XCTAssertEqual(game.focusedObjectiveAdvancePreviews, defaultPreviews)
        XCTAssertEqual(game.objectiveAdvancePreviews(for: tank, limit: 10).map(\.objectiveName), ["一号据点", "二号据点", "三号据点", "四号据点"])
        XCTAssertTrue(game.objectiveAdvancePreviews(for: tank, limit: 0).isEmpty)

        game.focusNearestObjectiveTarget()
        XCTAssertEqual(game.focusedCoordinate, HexCoordinate(q: 1, r: 0))
        XCTAssertEqual(game.guidedObjectiveCoordinate, HexCoordinate(q: 1, r: 0))
    }

    func testObjectiveAdvancePreviewFocusesSecondPlanWithoutExecuting() throws {
        let game = GameState(scenario: Self.multipleObjectiveAdvancePreviewScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "计划装甲" })

        game.handlePrimaryAction(on: tank.position)
        let previews = game.objectiveAdvancePreviews(for: tank)
        let secondPreview = try XCTUnwrap(previews.dropFirst().first)

        game.focusObjectiveAdvancePreview(secondPreview)

        let tankAfterFocus = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterFocus.position, tank.position)
        XCTAssertFalse(tankAfterFocus.hasMoved)
        XCTAssertEqual(game.focusedCoordinate, secondPreview.route.destination)
        XCTAssertEqual(game.guidedObjectiveCoordinate, secondPreview.coordinate)
        XCTAssertNil(game.latestObjectiveCaptureResult)
        XCTAssertTrue(game.message.contains("二号据点"))
        XCTAssertEqual(
            game.focusedCommandPreview,
            .move(
                unitName: tank.name,
                terrainName: try XCTUnwrap(game.tile(at: secondPreview.route.destination)?.terrain.title),
                route: secondPreview.route
            )
        )

        game.executeFocusedCommand()

        let tankAfterMove = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterMove.position, secondPreview.route.destination)
        XCTAssertTrue(tankAfterMove.hasMoved)
        XCTAssertEqual(game.tile(at: secondPreview.coordinate)?.owner, .allies)
        XCTAssertNil(game.guidedObjectiveCoordinate)
        XCTAssertEqual(game.latestObjectiveCaptureResult?.objectiveName, "二号据点")

        game.focusObjectiveAdvanceTarget(coordinate: HexCoordinate(q: 3, r: 0))

        XCTAssertEqual(game.focusedCoordinate, tankAfterMove.position)
        XCTAssertNil(game.guidedObjectiveCoordinate)
        XCTAssertTrue(game.message.contains("当前无法推进"))
    }

    func testObjectiveAdvanceTargetFocusRejectsAlliedAndOccupiedObjectives() throws {
        let game = GameState(scenario: Self.objectiveAdvanceScenario(includeOccupiedDecoy: true))
        let tank = try XCTUnwrap(game.units.first { $0.name == "目标推进装甲" })
        let alliedObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "出发据点" })
        let occupiedObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "占据村镇" })
        let validPreview = try XCTUnwrap(game.objectiveAdvancePreviews(for: tank).first)

        game.handlePrimaryAction(on: tank.position)
        game.focusObjectiveAdvancePreview(validPreview)
        XCTAssertEqual(game.guidedObjectiveCoordinate, validPreview.coordinate)

        game.focusObjectiveAdvanceTarget(coordinate: occupiedObjective.coordinate)

        let tankAfterOccupiedFocus = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterOccupiedFocus.position, tank.position)
        XCTAssertFalse(tankAfterOccupiedFocus.hasMoved)
        XCTAssertEqual(game.focusedCoordinate, tank.position)
        XCTAssertNil(game.guidedObjectiveCoordinate)
        XCTAssertTrue(game.message.contains("当前无法推进"))

        game.focusObjectiveAdvancePreview(validPreview)
        XCTAssertEqual(game.guidedObjectiveCoordinate, validPreview.coordinate)

        game.focusObjectiveAdvanceTarget(coordinate: alliedObjective.coordinate)

        let tankAfterAlliedFocus = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterAlliedFocus.position, tank.position)
        XCTAssertFalse(tankAfterAlliedFocus.hasMoved)
        XCTAssertEqual(game.focusedCoordinate, tank.position)
        XCTAssertNil(game.guidedObjectiveCoordinate)
        XCTAssertTrue(game.message.contains("当前无法推进"))
    }

    func testObjectiveAdvancePreviewFocusesDistantPlanAndExecutionPreservesGuidance() throws {
        let game = GameState(scenario: Self.distantObjectiveAdvanceScenario())
        let tank = try XCTUnwrap(game.units.first { $0.name == "目标推进装甲" })
        let targetObjective = try XCTUnwrap(game.objectiveTiles.first { $0.objectiveName == "纵深据点" })
        let preview = try XCTUnwrap(game.objectiveAdvancePreviews(for: tank).first)

        game.handlePrimaryAction(on: tank.position)
        game.focusObjectiveAdvancePreview(preview)

        XCTAssertEqual(game.focusedCoordinate, preview.route.destination)
        XCTAssertEqual(game.guidedObjectiveCoordinate, targetObjective.coordinate)
        XCTAssertNotEqual(preview.route.destination, targetObjective.coordinate)
        XCTAssertEqual(
            game.focusedCommandPreview,
            .move(
                unitName: tank.name,
                terrainName: try XCTUnwrap(game.tile(at: preview.route.destination)?.terrain.title),
                route: preview.route
            )
        )

        game.executeFocusedCommand()

        let tankAfterMove = try XCTUnwrap(game.scenario.units.first { $0.id == tank.id })
        XCTAssertEqual(tankAfterMove.position, preview.route.destination)
        XCTAssertEqual(game.guidedObjectiveCoordinate, targetObjective.coordinate)
        XCTAssertNil(game.latestObjectiveCaptureResult)
    }

    func testObjectiveCaptureSummaryClearsOnRestartScenarioSwitchAndCombat() throws {
        let game = GameState(
            scenario: Self.captureThenAttackScenario(),
            commandPoints: [.allies: 6, .axis: 6]
        )
        let infantry = try XCTUnwrap(game.units.first { $0.name == "占点突击队" })
        let objective = HexCoordinate(q: 1, r: 0)
        let target = try XCTUnwrap(game.units.first { $0.name == "反击守军" })

        game.handleTap(on: infantry.position)
        game.handleTap(on: objective)
        XCTAssertNotNil(game.latestObjectiveCaptureResult)

        game.handleTap(on: target.position)
        XCTAssertNil(game.latestObjectiveCaptureResult)
        XCTAssertNotNil(game.latestCombatResult)

        game.restart()
        XCTAssertNil(game.latestObjectiveCaptureResult)

        let alternateScenario = try XCTUnwrap(game.campaignCatalog.last)
        game.selectScenario(id: alternateScenario.id)
        XCTAssertNil(game.latestObjectiveCaptureResult)
    }

    func testObjectiveCaptureSummaryClearsOnTacticalCommand() throws {
        let game = GameState(
            scenario: Self.captureThenTacticalCommandScenario(),
            commandPoints: [.allies: 8, .axis: 6]
        )
        let artillery = try XCTUnwrap(game.units.first { $0.name == "占点炮兵" })
        let objective = HexCoordinate(q: 1, r: 0)
        let target = try XCTUnwrap(game.units.first { $0.name == "纵深目标" })

        game.handleTap(on: artillery.position)
        game.handleTap(on: objective)
        XCTAssertNotNil(game.latestObjectiveCaptureResult)

        game.useTacticalCommand(.artilleryBarrage, casterID: artillery.id, targetID: target.id)
        XCTAssertNil(game.latestObjectiveCaptureResult)
        XCTAssertNotNil(game.latestTacticalCommandResult)
    }

    func testEndTurnRunsAxisAIAndReturnsToAllies() {
        let game = GameState()
        let startingTurn = game.turn

        game.endTurn()

        if game.winner == nil {
            XCTAssertEqual(game.activeFaction, .allies)
            XCTAssertEqual(game.turn, startingTurn + 1)
        } else {
            XCTAssertNotNil(game.winner)
        }
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

    private static func logisticsResultScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for r in 0..<2 {
            for q in 0..<4 {
                var tile = TerrainTile(
                    coordinate: HexCoordinate(q: q, r: r),
                    terrain: .plains
                )
                if q == 0 && r == 0 {
                    tile.objectiveName = "后勤基地"
                    tile.owner = .allies
                } else if q == 3 && r == 1 {
                    tile.objectiveName = "后勤目标据点"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        return Scenario(
            id: "logistics-result-test",
            name: "后勤结果测试",
            year: "1944",
            briefing: "测试部署和整补结果摘要。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 4,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "后勤守军",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: 42,
                    commander: nil
                ),
                BattleUnit(
                    name: "后勤攻击方",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 2, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "后勤目标",
                    kind: .tank,
                    faction: .axis,
                    position: HexCoordinate(q: 3, r: 1),
                    hp: UnitKind.tank.baseHP,
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

    private static func combatResultScenario(
        attackerKind: UnitKind = .tank,
        defenderKind: UnitKind = .infantry,
        attackerHP: Int = UnitKind.tank.baseHP,
        defenderHP: Int = UnitKind.infantry.baseHP,
        attackerExperience: Int = UnitRank.regular.minimumExperience - 1,
        defenderEntrenched: Bool = true
    ) -> Scenario {
        var objectiveTile = TerrainTile(
            coordinate: HexCoordinate(q: 2, r: 0),
            terrain: .city
        )
        objectiveTile.objectiveName = "结果据点"
        objectiveTile.owner = nil

        return Scenario(
            id: "combat-result-test",
            name: "战斗结果测试",
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
                    kind: attackerKind,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: attackerHP,
                    commander: nil,
                    experience: attackerExperience
                ),
                BattleUnit(
                    name: "结果防守方",
                    kind: defenderKind,
                    faction: .axis,
                    position: HexCoordinate(q: 1, r: 0),
                    hp: defenderHP,
                    commander: nil,
                    isEntrenched: defenderEntrenched
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

    private static func captureThenAttackScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<4 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "出发基地"
                tile.owner = .allies
            } else if q == 1 {
                tile.objectiveName = "前沿村镇"
                tile.owner = .axis
            } else if q == 3 {
                tile.objectiveName = "纵深据点"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "capture-then-attack-test",
            name: "占点后攻击测试",
            year: "1944",
            briefing: "测试占点结果被后续普通攻击清理。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 4,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "占点突击队",
                    kind: .infantry,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "反击守军",
                    kind: .infantry,
                    faction: .axis,
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

    private static func captureThenTacticalCommandScenario() -> Scenario {
        var tiles: [TerrainTile] = []
        for q in 0..<5 {
            var tile = TerrainTile(
                coordinate: HexCoordinate(q: q, r: 0),
                terrain: .road
            )
            if q == 0 {
                tile.objectiveName = "炮兵阵地"
                tile.owner = .allies
            } else if q == 1 {
                tile.objectiveName = "前沿观察所"
                tile.owner = .axis
            } else if q == 4 {
                tile.objectiveName = "纵深据点"
                tile.owner = .axis
            }
            tiles.append(tile)
        }

        return Scenario(
            id: "capture-then-tactical-command-test",
            name: "占点后战术命令测试",
            year: "1944",
            briefing: "测试占点结果被后续战术命令清理。",
            initialFocus: HexCoordinate(q: 0, r: 0),
            mapColumns: 5,
            mapRows: 1,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "占点炮兵",
                    kind: .artillery,
                    faction: .allies,
                    position: HexCoordinate(q: 0, r: 0),
                    hp: UnitKind.artillery.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "纵深目标",
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

    private static func supplyTestScenario() -> Scenario {
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
            id: "supply-test",
            name: "补给测试",
            year: "1944",
            briefing: "测试补给线。",
            initialFocus: HexCoordinate(q: 2, r: 0),
            mapColumns: 3,
            mapRows: 2,
            tiles: tiles,
            units: [
                BattleUnit(
                    name: "补给装甲",
                    kind: .tank,
                    faction: .allies,
                    position: HexCoordinate(q: 2, r: 0),
                    hp: UnitKind.tank.baseHP,
                    commander: nil
                ),
                BattleUnit(
                    name: "目标步兵",
                    kind: .infantry,
                    faction: .axis,
                    position: HexCoordinate(q: 2, r: 1),
                    hp: UnitKind.infantry.baseHP,
                    commander: nil
                )
            ]
        )
    }
}
