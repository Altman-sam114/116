import Foundation

enum Faction: String, CaseIterable, Identifiable {
    case allies
    case axis

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allies: "盟军"
        case .axis: "轴心国"
        }
    }

    var shortTitle: String {
        switch self {
        case .allies: "AL"
        case .axis: "AX"
        }
    }

    var opponent: Faction {
        switch self {
        case .allies: .axis
        case .axis: .allies
        }
    }
}

enum UnitKind: String, CaseIterable, Identifiable {
    case infantry
    case tank
    case artillery
    case recon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .infantry: "步兵"
        case .tank: "坦克"
        case .artillery: "火炮"
        case .recon: "侦察车"
        }
    }

    var code: String {
        switch self {
        case .infantry: "INF"
        case .tank: "TNK"
        case .artillery: "ART"
        case .recon: "RCN"
        }
    }

    var baseHP: Int {
        switch self {
        case .infantry: 82
        case .tank: 118
        case .artillery: 72
        case .recon: 64
        }
    }

    var baseAttack: Int {
        switch self {
        case .infantry: 22
        case .tank: 34
        case .artillery: 30
        case .recon: 20
        }
    }

    var movement: Int {
        switch self {
        case .infantry: 3
        case .tank: 4
        case .artillery: 2
        case .recon: 5
        }
    }

    var range: Int {
        switch self {
        case .artillery: 3
        default: 1
        }
    }

    var sortOrder: Int {
        switch self {
        case .tank: 0
        case .infantry: 1
        case .artillery: 2
        case .recon: 3
        }
    }

    var commandCost: Int {
        switch self {
        case .infantry: 3
        case .recon: 4
        case .artillery: 5
        case .tank: 6
        }
    }

    var reinforceAmount: Int {
        switch self {
        case .infantry: 28
        case .recon: 24
        case .artillery: 22
        case .tank: 30
        }
    }

    var reinforcementName: String {
        switch self {
        case .infantry: "步兵营"
        case .tank: "装甲连"
        case .artillery: "炮兵连"
        case .recon: "侦察排"
        }
    }

    func matchupAttackMultiplierPercent(against defender: UnitKind) -> Int {
        switch (self, defender) {
        case (.tank, .infantry):
            116
        case (.tank, .recon):
            112
        case (.infantry, .artillery):
            118
        case (.artillery, .tank):
            114
        case (.artillery, .infantry):
            108
        case (.recon, .artillery):
            120
        case (.recon, .infantry):
            106
        case (.infantry, .tank):
            92
        case (.artillery, .recon):
            90
        default:
            100
        }
    }
}

enum TerrainKind: String, CaseIterable, Identifiable {
    case plains
    case forest
    case city
    case mountain
    case snow
    case river
    case road

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plains: "平原"
        case .forest: "森林"
        case .city: "城市"
        case .mountain: "山地"
        case .snow: "雪原"
        case .river: "河流"
        case .road: "公路"
        }
    }

    var code: String {
        switch self {
        case .plains: "PLN"
        case .forest: "FOR"
        case .city: "CTY"
        case .mountain: "MTN"
        case .snow: "SNW"
        case .river: "RIV"
        case .road: "RD"
        }
    }

    var movementCost: Int {
        switch self {
        case .road: 1
        case .plains, .city, .snow: 2
        case .forest, .mountain: 3
        case .river: 4
        }
    }

    func movementCost(for unitKind: UnitKind) -> Int {
        switch (self, unitKind) {
        case (.road, _):
            1
        case (.plains, .recon):
            1
        case (.plains, _):
            2
        case (.city, .tank):
            3
        case (.city, _):
            2
        case (.forest, .infantry):
            2
        case (.forest, .tank):
            4
        case (.forest, _):
            3
        case (.mountain, .tank):
            5
        case (.mountain, .artillery), (.mountain, .recon):
            4
        case (.mountain, .infantry):
            3
        case (.snow, .infantry), (.snow, .recon):
            2
        case (.snow, .tank), (.snow, .artillery):
            3
        case (.river, .infantry):
            3
        case (.river, .tank):
            5
        case (.river, .artillery), (.river, .recon):
            4
        }
    }

    func attackMultiplierPercent(for unitKind: UnitKind) -> Int {
        switch (self, unitKind) {
        case (.plains, .tank):
            108
        case (.plains, .recon):
            106
        case (.road, .tank), (.road, .recon):
            110
        case (.road, .artillery):
            96
        case (.forest, .infantry):
            112
        case (.forest, .tank):
            84
        case (.forest, .artillery):
            94
        case (.forest, .recon):
            96
        case (.city, .infantry):
            110
        case (.city, .artillery):
            104
        case (.city, .tank):
            90
        case (.city, .recon):
            96
        case (.mountain, .artillery):
            112
        case (.mountain, .infantry):
            106
        case (.mountain, .tank):
            78
        case (.mountain, .recon):
            86
        case (.snow, .infantry):
            98
        case (.snow, .tank), (.snow, .recon):
            90
        case (.snow, .artillery):
            96
        case (.river, .infantry):
            88
        case (.river, .tank):
            72
        case (.river, .artillery):
            92
        case (.river, .recon):
            82
        default:
            100
        }
    }

    var defenseBonus: Int {
        switch self {
        case .city: 8
        case .forest, .mountain: 6
        case .snow: 3
        case .river: 2
        case .plains, .road: 0
        }
    }
}

struct HexCoordinate: Hashable, Identifiable {
    let q: Int
    let r: Int

    var id: String { "\(q),\(r)" }

    func distance(to other: HexCoordinate) -> Int {
        let dq = q - other.q
        let dr = r - other.r
        return (abs(dq) + abs(dq + dr) + abs(dr)) / 2
    }

    var neighbors: [HexCoordinate] {
        [
            HexCoordinate(q: q + 1, r: r),
            HexCoordinate(q: q + 1, r: r - 1),
            HexCoordinate(q: q, r: r - 1),
            HexCoordinate(q: q - 1, r: r),
            HexCoordinate(q: q - 1, r: r + 1),
            HexCoordinate(q: q, r: r + 1)
        ]
    }
}

struct Commander: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let nation: String
    let rank: String
    let armor: Int
    let tactics: Int
    let morale: Int
    let trait: String

    var rating: Int { armor + tactics + morale }

    static let patton = Commander(
        name: "巴顿",
        nation: "美国",
        rank: "装甲上将",
        armor: 5,
        tactics: 4,
        morale: 4,
        trait: "装甲突击：坦克攻击 +8"
    )

    static let montgomery = Commander(
        name: "蒙哥马利",
        nation: "英国",
        rank: "元帅",
        armor: 4,
        tactics: 5,
        morale: 4,
        trait: "稳固防线：城市防御 +6"
    )

    static let guderian = Commander(
        name: "古德里安",
        nation: "德国",
        rank: "装甲上将",
        armor: 5,
        tactics: 5,
        morale: 3,
        trait: "闪击：首轮移动 +1"
    )

    static let manstein = Commander(
        name: "曼施坦因",
        nation: "德国",
        rank: "元帅",
        armor: 4,
        tactics: 5,
        morale: 4,
        trait: "机动作战：反击伤害 +5"
    )
}

struct CombatPreview: Equatable {
    let attackerName: String
    let defenderName: String
    let damage: Int
    let counterDamage: Int
    let matchupMultiplierPercent: Int
    let defenderTerrainName: String
    let terrainAttackMultiplierPercent: Int
    let terrainDefenseBonus: Int
    let commanderSupportName: String?
    let commanderSupportBonusPercent: Int
    let supportUnitCount: Int
    let supportDamageBonusPercent: Int
    let defenderIsEntrenched: Bool
    let defenseMultiplierPercent: Int
    let defenderHPAfterAttack: Int
    let attackerHPAfterCounter: Int
    let willDestroyDefender: Bool
    let willLoseAttacker: Bool

    var matchupTitle: String {
        if matchupMultiplierPercent >= 110 {
            return "战术优势"
        }
        if matchupMultiplierPercent <= 94 {
            return "战术劣势"
        }
        return "常规交战"
    }

    var matchupDetail: String {
        if matchupMultiplierPercent == 100 {
            return "兵种无额外修正"
        }
        return "兵种伤害 \(matchupMultiplierPercent)%"
    }

    var terrainTitle: String {
        if terrainAttackMultiplierPercent >= 106 {
            return "地形适性"
        }
        if terrainAttackMultiplierPercent <= 94 {
            return "地形牵制"
        }
        return "地形中性"
    }

    var terrainDetail: String {
        "\(defenderTerrainName) 攻势 \(terrainAttackMultiplierPercent)%，防御 +\(terrainDefenseBonus)"
    }

    var commanderSupportTitle: String {
        commanderSupportName == nil ? "无将领协同" : "将领协同"
    }

    var commanderSupportDetail: String {
        guard let commanderSupportName else { return "相邻无友军将领" }
        return "\(commanderSupportName) 指挥，伤害 +\(commanderSupportBonusPercent)%"
    }

    var supportTitle: String {
        supportUnitCount > 0 ? "夹击协同" : "单兵接战"
    }

    var supportDetail: String {
        supportUnitCount > 0 ? "\(supportUnitCount) 支友军，伤害 +\(supportDamageBonusPercent)%" : "无相邻友军支援"
    }

    var defenseTitle: String {
        defenderIsEntrenched ? "防御姿态" : "常规防御"
    }

    var defenseDetail: String {
        defenderIsEntrenched ? "受到伤害 \(defenseMultiplierPercent)%" : "无额外减伤"
    }
}

enum TacticalCommand: String, CaseIterable, Identifiable {
    case artilleryBarrage
    case breakthroughAssault

    var id: String { rawValue }

    var title: String {
        switch self {
        case .artilleryBarrage: "火炮弹幕"
        case .breakthroughAssault: "突破突击"
        }
    }

    var shortTitle: String {
        switch self {
        case .artilleryBarrage: "BRG"
        case .breakthroughAssault: "BRK"
        }
    }

    var detail: String {
        switch self {
        case .artilleryBarrage: "火炮单位消耗指令点，对远距离目标造成压制伤害且不触发反击。"
        case .breakthroughAssault: "坦克和侦察单位消耗指令点，对近距离目标发动高强度突击且不触发反击。"
        }
    }

    var commandCost: Int {
        switch self {
        case .artilleryBarrage: 4
        case .breakthroughAssault: 3
        }
    }

    var range: Int {
        switch self {
        case .artilleryBarrage: 4
        case .breakthroughAssault: 1
        }
    }

    var moraleDamage: Int {
        switch self {
        case .artilleryBarrage: 14
        case .breakthroughAssault: 8
        }
    }

    var statusEffect: UnitTacticalStatus {
        switch self {
        case .artilleryBarrage: .suppressed
        case .breakthroughAssault: .disrupted
        }
    }

    var actionVerb: String {
        switch self {
        case .artilleryBarrage: "呼叫"
        case .breakthroughAssault: "发动"
        }
    }

    func canBeUsed(by kind: UnitKind) -> Bool {
        switch self {
        case .artilleryBarrage:
            kind == .artillery
        case .breakthroughAssault:
            kind == .tank || kind == .recon
        }
    }
}

enum UnitTacticalStatus: String, Identifiable {
    case normal
    case suppressed
    case disrupted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "状态正常"
        case .suppressed: "火力压制"
        case .disrupted: "队形瓦解"
        }
    }

    var shortTitle: String {
        switch self {
        case .normal: "OK"
        case .suppressed: "PIN"
        case .disrupted: "BRK"
        }
    }

    var attackMultiplierPercent: Int {
        switch self {
        case .normal: 100
        case .suppressed: 85
        case .disrupted: 92
        }
    }

    var movementPenalty: Int {
        switch self {
        case .normal: 0
        case .suppressed, .disrupted: 1
        }
    }

    var detail: String {
        switch self {
        case .normal:
            "无额外战术影响。"
        case .suppressed:
            "攻击降至 85%，移动 -1，持续到本方行动结束。"
        case .disrupted:
            "攻击降至 92%，移动 -1，持续到本方行动结束。"
        }
    }
}

struct CombatantResultSnapshot: Equatable {
    let unitID: BattleUnit.ID
    let name: String
    let kind: UnitKind
    let faction: Faction
    let startingHP: Int
    let endingHP: Int
    let startingExperience: Int
    let endingExperience: Int
    let startingMorale: Int
    let endingMorale: Int
    let startingRank: UnitRank
    let endingRank: UnitRank

    var hpDelta: Int { endingHP - startingHP }
    var experienceDelta: Int { endingExperience - startingExperience }
    var moraleDelta: Int { endingMorale - startingMorale }
    var didPromote: Bool { endingRank != startingRank }
    var isDestroyed: Bool { endingHP <= 0 }
}

struct CombatResultSummary: Identifiable, Equatable {
    let id = UUID()
    let attacker: CombatantResultSnapshot
    let defender: CombatantResultSnapshot
    let damage: Int
    let counterDamage: Int
    let supportDamageBonusPercent: Int
    let didDestroyDefender: Bool
    let didDestroyAttacker: Bool
    let didTriggerManeuverPursuit: Bool
    let didConsumeDefenderEntrenchment: Bool

    var hasCounterAttack: Bool { counterDamage > 0 }
    var hasFlankingSupport: Bool { supportDamageBonusPercent > 0 }
}

struct TacticalCommandPreview: Equatable {
    let command: TacticalCommand
    let casterName: String
    let targetName: String
    let commandCost: Int
    let range: Int
    let damage: Int
    let targetHPAfterCommand: Int
    let moraleDamage: Int
    let targetIsEntrenched: Bool
    let defenseMultiplierPercent: Int
    let statusEffect: UnitTacticalStatus
    let willDestroyTarget: Bool

    var outcomeText: String {
        let defenseText = targetIsEntrenched ? "防御姿态减伤，" : ""
        if willDestroyTarget {
            return "\(defenseText)预计击毁目标"
        }
        return "\(defenseText)目标剩余 \(targetHPAfterCommand) 耐久，士气 -\(moraleDamage)，\(statusEffect.title)"
    }
}

struct TacticalCommandResultSummary: Identifiable, Equatable {
    let id = UUID()
    let command: TacticalCommand
    let caster: CombatantResultSnapshot
    let target: CombatantResultSnapshot
    let damage: Int
    let commandCost: Int
    let moraleDamage: Int
    let statusEffect: UnitTacticalStatus
    let didDestroyTarget: Bool
    let didConsumeTargetEntrenchment: Bool
    let didAvoidCounterAttack: Bool

    var didApplyStatusEffect: Bool {
        statusEffect != .normal && !didDestroyTarget
    }
}

struct ObjectiveCaptureResultSummary: Identifiable, Equatable {
    let id = UUID()
    let objectiveName: String
    let coordinate: HexCoordinate
    let capturingUnitName: String
    let capturingUnitKind: UnitKind
    let previousOwner: Faction?
    let newOwner: Faction
    let commandPointReward: Int
    let moraleReward: Int
    let experienceReward: Int
    let alliedScoreAfterCapture: Int
    let axisScoreAfterCapture: Int
    let totalObjectiveCount: Int

    var actionTitle: String {
        previousOwner == nil ? "占领" : "夺取"
    }

    var ownerTransitionText: String {
        "\(previousOwner?.title ?? "中立") -> \(newOwner.title)"
    }

    var progressText: String {
        "\(alliedScoreAfterCapture)/\(totalObjectiveCount)"
    }
}

struct DeploymentResultSummary: Identifiable, Equatable {
    let id = UUID()
    let sourceObjectiveName: String
    let coordinate: HexCoordinate
    let unitID: BattleUnit.ID
    let unitName: String
    let unitKind: UnitKind
    let faction: Faction
    let commandCost: Int
    let commandPointsAfterDeployment: Int
}

struct ReinforcementResultSummary: Identifiable, Equatable {
    let id = UUID()
    let unitID: BattleUnit.ID
    let unitName: String
    let unitKind: UnitKind
    let faction: Faction
    let coordinate: HexCoordinate
    let startingHP: Int
    let endingHP: Int
    let recoveredHP: Int
    let commandCost: Int
    let commandPointsAfterReinforcement: Int
}

struct AIPhaseSummary: Identifiable, Equatable {
    let id = UUID()
    let faction: Faction
    let turn: Int
    let startingCommandPoints: Int
    let endingCommandPoints: Int
    let reinforcements: Int
    let deployments: Int
    let tacticalCommands: Int
    let attacks: Int
    let moves: Int
    let objectivesCaptured: Int
    let enemyUnitsDestroyed: Int
    let friendlyUnitsDestroyed: Int
    let damageDealt: Int
    let damageTaken: Int
    let timeline: [AIPhaseTimelineEvent]

    var totalActions: Int {
        reinforcements + deployments + tacticalCommands + attacks + moves
    }

    var logisticsActions: Int {
        reinforcements + deployments
    }

    var commandPointDelta: Int {
        endingCommandPoints - startingCommandPoints
    }

    var replayConclusion: AIPhaseReplayConclusion {
        let kind = AIPhaseReplayConclusionKind.classify(summary: self)
        return AIPhaseReplayConclusion(
            kind: kind,
            title: kind.title,
            summary: kind.summary(for: self),
            metrics: AIPhaseReplayConclusionMetric.metrics(for: self),
            keyEvents: AIPhaseReplayKeyEvent.keyEvents(for: timeline)
        )
    }
}

enum AIPhaseReplayConclusionKind: String, Identifiable, Hashable {
    case objectiveBreakthrough
    case fireSuppression
    case logistics
    case maneuver
    case quiet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .objectiveBreakthrough: "夺点突破"
        case .fireSuppression: "火力压制"
        case .logistics: "后勤整备"
        case .maneuver: "机动推进"
        case .quiet: "低强度回合"
        }
    }

    var shortTitle: String {
        switch self {
        case .objectiveBreakthrough: "夺点"
        case .fireSuppression: "压制"
        case .logistics: "后勤"
        case .maneuver: "机动"
        case .quiet: "低烈度"
        }
    }

    var systemImage: String {
        switch self {
        case .objectiveBreakthrough: "flag.fill"
        case .fireSuppression: "scope"
        case .logistics: "shippingbox.fill"
        case .maneuver: "arrow.triangle.turn.up.right.diamond.fill"
        case .quiet: "moon.zzz.fill"
        }
    }

    static func classify(summary: AIPhaseSummary) -> AIPhaseReplayConclusionKind {
        if summary.objectivesCaptured > 0 {
            return .objectiveBreakthrough
        }
        if summary.attacks > 0 || summary.damageDealt >= 18 || summary.enemyUnitsDestroyed > 0 || summary.tacticalCommands > 0 {
            return .fireSuppression
        }
        if summary.logisticsActions > 0 {
            return .logistics
        }
        if summary.moves > 0 {
            return .maneuver
        }
        return .quiet
    }

    func summary(for summary: AIPhaseSummary) -> String {
        switch self {
        case .objectiveBreakthrough:
            return "敌军夺取 \(summary.objectivesCaptured) 个据点，造成 \(summary.damageDealt) 伤害。"
        case .fireSuppression:
            return "敌军以攻击或战术命令压制我方，造成 \(summary.damageDealt) 伤害。"
        case .logistics:
            return "敌军主要投入 \(summary.logisticsActions) 次后勤动作，巩固据点和兵力。"
        case .maneuver:
            return "敌军进行了 \(summary.moves) 次机动，尚未形成明显战果。"
        case .quiet:
            return "敌军本回合没有形成有效推进或火力战果。"
        }
    }
}

enum AIPhaseReplayConclusionMetricKind: String, Identifiable, Hashable {
    case damage
    case objectives
    case logistics
    case command

    var id: String { rawValue }
}

struct AIPhaseReplayConclusionMetric: Identifiable, Equatable {
    let kind: AIPhaseReplayConclusionMetricKind
    let title: String
    let value: String
    let detail: String

    var id: String {
        "\(kind.rawValue)-\(title)-\(value)"
    }

    static func metrics(for summary: AIPhaseSummary) -> [AIPhaseReplayConclusionMetric] {
        [
            AIPhaseReplayConclusionMetric(
                kind: .damage,
                title: "伤害",
                value: "-\(summary.damageDealt)",
                detail: summary.damageTaken > 0 ? "承伤 \(summary.damageTaken)" : "无承伤"
            ),
            AIPhaseReplayConclusionMetric(
                kind: .objectives,
                title: "占点",
                value: "\(summary.objectivesCaptured)",
                detail: summary.enemyUnitsDestroyed > 0 ? "歼灭 \(summary.enemyUnitsDestroyed)" : "无歼灭"
            ),
            AIPhaseReplayConclusionMetric(
                kind: .logistics,
                title: "后勤",
                value: "\(summary.logisticsActions)",
                detail: "整补 \(summary.reinforcements)，部署 \(summary.deployments)"
            ),
            AIPhaseReplayConclusionMetric(
                kind: .command,
                title: "指令",
                value: summary.commandPointDelta >= 0 ? "+\(summary.commandPointDelta)" : "\(summary.commandPointDelta)",
                detail: "\(summary.startingCommandPoints)->\(summary.endingCommandPoints)"
            )
        ]
    }
}

struct AIPhaseReplayKeyEvent: Identifiable, Equatable {
    let order: Int
    let kind: AIPhaseTimelineEventKind
    let title: String
    let detail: String

    var id: Int { order }

    static func keyEvents(for timeline: [AIPhaseTimelineEvent]) -> [AIPhaseReplayKeyEvent] {
        timeline
            .filter { $0.replayConclusionPriority > 0 }
            .sorted { left, right in
                if left.replayConclusionPriority != right.replayConclusionPriority {
                    return left.replayConclusionPriority > right.replayConclusionPriority
                }
                return left.order < right.order
            }
            .prefix(3)
            .map {
                AIPhaseReplayKeyEvent(
                    order: $0.order,
                    kind: $0.kind,
                    title: "#\($0.order) \($0.kind.title)",
                    detail: $0.summary
                )
            }
    }
}

struct AIPhaseReplayConclusion: Identifiable, Equatable {
    var id: String { kind.rawValue }

    let kind: AIPhaseReplayConclusionKind
    let title: String
    let summary: String
    let metrics: [AIPhaseReplayConclusionMetric]
    let keyEvents: [AIPhaseReplayKeyEvent]
}

enum AIPhaseTimelinePlaybackPace: String, CaseIterable, Identifiable {
    case slow
    case normal
    case fast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slow: "慢速"
        case .normal: "标准"
        case .fast: "快速"
        }
    }

    var shortTitle: String {
        switch self {
        case .slow: "慢"
        case .normal: "中"
        case .fast: "快"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .slow: 1.8
        case .normal: 1.1
        case .fast: 0.6
        }
    }
}

enum AIPhaseTimelineEventKind: String, Identifiable, Hashable {
    case reinforcement
    case deployment
    case tacticalCommand
    case attack
    case move
    case objectiveCapture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reinforcement: "整补"
        case .deployment: "部署"
        case .tacticalCommand: "战术"
        case .attack: "攻击"
        case .move: "移动"
        case .objectiveCapture: "占点"
        }
    }

    var shortCode: String {
        switch self {
        case .reinforcement: "REP"
        case .deployment: "DEP"
        case .tacticalCommand: "CMD"
        case .attack: "ATK"
        case .move: "MOV"
        case .objectiveCapture: "CAP"
        }
    }
}

struct AIPhaseTimelineEvent: Identifiable, Equatable {
    var id: Int { order }

    let order: Int
    let faction: Faction
    let turn: Int
    let kind: AIPhaseTimelineEventKind
    let actorUnitID: BattleUnit.ID?
    let actorName: String
    let actorKind: UnitKind?
    let targetUnitID: BattleUnit.ID?
    let targetName: String?
    let targetKind: UnitKind?
    let from: HexCoordinate?
    let to: HexCoordinate?
    let tacticalCommand: TacticalCommand?
    let deployedUnitKind: UnitKind?
    let objectiveName: String?
    let previousOwner: Faction?
    let newOwner: Faction?
    let damage: Int
    let counterDamage: Int
    let recoveredHP: Int
    let commandPointCost: Int
    let commandPointReward: Int
    let commandPointsAfter: Int?
    let didDestroyTarget: Bool
    let didCaptureObjective: Bool
    let detail: String

    var shortCode: String {
        kind.shortCode
    }

    var summary: String {
        switch kind {
        case .reinforcement:
            return "\(actorName) 整补 +\(recoveredHP) 耐久\(commandPointText)。"
        case .deployment:
            let coordinateText = to.map { " q\($0.q),r\($0.r)" } ?? ""
            let kindText = deployedUnitKind?.title ?? actorKind?.title ?? "部队"
            return "\(actorName) 部署\(kindText)\(coordinateText)\(commandPointText)。"
        case .tacticalCommand:
            let commandTitle = tacticalCommand?.title ?? "战术命令"
            let target = targetName ?? "目标"
            let destroyText = didDestroyTarget ? "，击毁" : ""
            return "\(actorName) 对 \(target) 使用\(commandTitle)，伤害 \(damage)\(destroyText)\(commandPointText)。"
        case .attack:
            let target = targetName ?? "目标"
            let counterText = counterDamage > 0 ? "，反击 \(counterDamage)" : ""
            let destroyText = didDestroyTarget ? "，击毁" : ""
            return "\(actorName) 攻击 \(target)，伤害 \(damage)\(counterText)\(destroyText)。"
        case .move:
            let startText = from.map { "q\($0.q),r\($0.r)" } ?? "未知"
            let endText = to.map { "q\($0.q),r\($0.r)" } ?? "未知"
            return "\(actorName) 从 \(startText) 机动到 \(endText)。"
        case .objectiveCapture:
            let objective = objectiveName ?? targetName ?? "据点"
            let ownerText = newOwner?.title ?? "中立"
            let rewardText = commandPointReward > 0 ? "，指令 +\(commandPointReward)" : ""
            return "\(actorName) 占领\(objective)，归属 \(ownerText)\(rewardText)。"
        }
    }

    private var commandPointText: String {
        commandPointCost > 0 ? "，指令 -\(commandPointCost)" : ""
    }

    var replayConclusionPriority: Int {
        var priority = 0
        if didCaptureObjective || kind == .objectiveCapture {
            priority += 100
        }
        if didDestroyTarget {
            priority += 80
        }
        if damage > 0 {
            priority += min(60, damage)
        }
        if kind == .tacticalCommand {
            priority += 25
        }
        if kind == .deployment || kind == .reinforcement {
            priority += 18 + recoveredHP / 2
        }
        if kind == .move && priority == 0 {
            priority = 6
        }
        return priority
    }
}

enum AIPhaseMapMarkerRole: String, CaseIterable, Identifiable {
    case actor
    case target
    case origin
    case destination
    case objective

    var id: String { rawValue }

    var title: String {
        switch self {
        case .actor: "AI行动单位"
        case .target: "AI目标"
        case .origin: "AI起点"
        case .destination: "AI终点"
        case .objective: "AI占点"
        }
    }

    var shortTitle: String {
        switch self {
        case .actor: "AIU"
        case .target: "AIT"
        case .origin: "AIO"
        case .destination: "AID"
        case .objective: "AIP"
        }
    }

    var compactTitle: String {
        switch self {
        case .actor: "A"
        case .target: "T"
        case .origin: "O"
        case .destination: "D"
        case .objective: "P"
        }
    }

    var sortOrder: Int {
        switch self {
        case .actor: 0
        case .origin: 1
        case .target: 2
        case .destination: 3
        case .objective: 4
        }
    }
}

struct AIPhaseMapMarker: Identifiable, Equatable {
    let faction: Faction
    let turn: Int
    let eventOrder: Int
    let eventKind: AIPhaseTimelineEventKind
    let role: AIPhaseMapMarkerRole
    let coordinate: HexCoordinate
    let shortCode: String
    let summary: String

    var id: String {
        "AI-\(faction.rawValue)-\(turn)-\(eventOrder)-\(role.rawValue)-\(coordinate.id)"
    }
}

enum EnemyThreatIntentKind: String, Identifiable {
    case directAttack
    case approachAttack
    case objectiveCapture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .directAttack: "直接攻击"
        case .approachAttack: "接敌攻击"
        case .objectiveCapture: "据点威胁"
        }
    }

    var shortTitle: String {
        switch self {
        case .directAttack: "ATK"
        case .approachAttack: "POS"
        case .objectiveCapture: "OBJ"
        }
    }
}

struct EnemyThreatIntentPreview: Identifiable, Equatable {
    let kind: EnemyThreatIntentKind
    let enemyUnitID: BattleUnit.ID
    let enemyUnitName: String
    let enemyUnitKind: UnitKind
    let targetCoordinate: HexCoordinate
    let targetUnitID: BattleUnit.ID?
    let targetName: String
    let targetFaction: Faction
    let currentDistance: Int
    let routeDestination: HexCoordinate?
    let routeCost: Int?
    let projectedDamage: Int
    let projectedTargetHPAfterDamage: Int?
    let willDestroyTarget: Bool
    let objectiveOwner: Faction?
    let score: Int

    var id: String {
        "\(kind.rawValue)-\(enemyUnitID.uuidString)-\(targetCoordinate.id)-\(routeDestination?.id ?? "direct")"
    }

    var isAttackThreat: Bool {
        kind == .directAttack || kind == .approachAttack
    }

    var threatLabel: String {
        "\(enemyUnitName)的\(kind.title)"
    }

    var destinationText: String {
        guard let routeDestination else { return "当前射程" }
        return "q\(routeDestination.q),r\(routeDestination.r)"
    }
}

enum EnemyThreatCountermeasureKind: String, Identifiable {
    case firstStrike
    case withdraw
    case objectiveDefense
    case reinforce

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstStrike: "抢先打击"
        case .withdraw: "撤出危险区"
        case .objectiveDefense: "据点防守"
        case .reinforce: "整补支撑"
        }
    }

    var shortTitle: String {
        switch self {
        case .firstStrike: "HIT"
        case .withdraw: "OUT"
        case .objectiveDefense: "DEF"
        case .reinforce: "REP"
        }
    }
}

enum EnemyThreatCountermeasureMapMarkerRole: String, CaseIterable, Identifiable {
    case actingUnit
    case threatSource
    case counterTarget
    case threatenedTarget

    var id: String { rawValue }

    var title: String {
        switch self {
        case .actingUnit: "反制执行单位"
        case .threatSource: "威胁来源"
        case .counterTarget: "反制目标"
        case .threatenedTarget: "受威胁目标"
        }
    }

    var shortTitle: String {
        switch self {
        case .actingUnit: "ACT"
        case .threatSource: "SRC"
        case .counterTarget: "CTR"
        case .threatenedTarget: "TGT"
        }
    }

    var compactTitle: String {
        switch self {
        case .actingUnit: "A"
        case .threatSource: "S"
        case .counterTarget: "C"
        case .threatenedTarget: "T"
        }
    }

    var sortOrder: Int {
        switch self {
        case .actingUnit: 0
        case .threatSource: 1
        case .counterTarget: 2
        case .threatenedTarget: 3
        }
    }
}

struct EnemyThreatCountermeasureMapMarker: Identifiable, Equatable {
    let role: EnemyThreatCountermeasureMapMarkerRole
    let coordinate: HexCoordinate
    let countermeasureKind: EnemyThreatCountermeasureKind

    var id: String {
        "\(role.rawValue)-\(coordinate.id)-\(countermeasureKind.rawValue)"
    }
}

struct EnemyThreatCountermeasurePreview: Identifiable, Equatable {
    let kind: EnemyThreatCountermeasureKind
    let threatID: String
    let threatKind: EnemyThreatIntentKind
    let threatEnemyUnitID: BattleUnit.ID
    let threatEnemyUnitName: String
    let threatTargetCoordinate: HexCoordinate
    let actingUnitID: BattleUnit.ID?
    let actingUnitName: String
    let targetUnitID: BattleUnit.ID?
    let targetName: String
    let destination: HexCoordinate?
    let routeCost: Int?
    let projectedDamage: Int
    let projectedEnemyHPAfterDamage: Int?
    let willDestroyEnemy: Bool
    let projectedFriendlyHPAfterAction: Int?
    let projectedRecoveredHP: Int
    let canExecuteNow: Bool
    let reason: String
    let score: Int
    let impactComparisons: [EnemyThreatCountermeasureImpactComparison]

    var id: String {
        [
            kind.rawValue,
            threatID,
            actingUnitID?.uuidString ?? "none",
            targetUnitID?.uuidString ?? targetName,
            destination?.id ?? "direct"
        ].joined(separator: "-")
    }

    var destinationText: String {
        guard let destination else { return "当前位置" }
        return "q\(destination.q),r\(destination.r)"
    }

    var benefitSummary: String {
        benefitMetrics
            .map { "\($0.title)：\($0.value)" }
            .joined(separator: "，")
    }

    var impactSummary: String {
        impactComparisons
            .map { "\($0.title)：\($0.before) -> \($0.after)，\($0.impact)" }
            .joined(separator: "，")
    }

    var prioritySummary: String {
        let impact = willDestroyEnemy ? "可击毁威胁" : "\(kind.title)"
        let route = routeCost.map { "路线 \($0)" } ?? (kind == .firstStrike ? "无需移动" : "当前位置")
        return "\(canExecuteNow ? "当前可执行" : "暂不可执行")，\(impact)，优先值 \(score)，\(route)"
    }

    var objectiveDefenseTradeoff: EnemyThreatObjectiveDefenseTradeoff? {
        guard kind == .objectiveDefense else { return nil }

        let actionTitle = destination == threatTargetCoordinate ? "进驻" : "封堵"
        let routeTitle = routeCost.map { "路线 \($0)" } ?? "无需移动"
        let objectiveImpact = impactComparisons.first { $0.kind == .objective }
        let impactTitle = objectiveImpact.map {
            "\($0.before) -> \($0.after)"
        } ?? "被夺风险 -> \(actionTitle)"
        let impactDetail = objectiveImpact?.impact ?? "\(actionTitle)\(targetName)"
        let tradeoffDetail = actionTitle == "进驻" ?
            "直接占位，优先阻止夺点" :
            "相邻卡位，封堵敌方抢点路线"
        let summary = "\(actionTitle)\(targetName)：\(tradeoffDetail)，\(routeTitle)，优先值 \(score)"

        return EnemyThreatObjectiveDefenseTradeoff(
            actionTitle: actionTitle,
            targetName: targetName,
            positionTitle: destinationText,
            routeTitle: routeTitle,
            impactTitle: impactTitle,
            impactDetail: impactDetail,
            priorityTitle: "优先值 \(score)",
            summary: summary
        )
    }

    var priorityFactors: [EnemyThreatCountermeasurePriorityFactor] {
        var factors: [EnemyThreatCountermeasurePriorityFactor] = [
            EnemyThreatCountermeasurePriorityFactor(
                kind: .availability,
                title: "可执行",
                value: canExecuteNow ? "是" : "否",
                detail: canExecuteNow ? "执行单位仍可行动" : "当前状态下不可执行"
            ),
            EnemyThreatCountermeasurePriorityFactor(
                kind: .decisiveStrike,
                title: "击毁",
                value: willDestroyEnemy ? "是" : "否",
                detail: willDestroyEnemy ? "可直接解除威胁来源" : "不以击毁作为首要优势"
            ),
            EnemyThreatCountermeasurePriorityFactor(
                kind: .priorityScore,
                title: "优先值",
                value: "\(score)",
                detail: "排序主分"
            )
        ]

        factors.append(
            EnemyThreatCountermeasurePriorityFactor(
                kind: .routeCost,
                title: "路线",
                value: routeCost.map { "\($0)" } ?? "0",
                detail: routeCost.map { "移动力消耗 \($0)" } ?? "无需额外移动"
            )
        )
        factors.append(
            EnemyThreatCountermeasurePriorityFactor(
                kind: .actingUnit,
                title: "执行",
                value: actingUnitName,
                detail: "稳定排序执行单位"
            )
        )
        factors.append(
            EnemyThreatCountermeasurePriorityFactor(
                kind: .target,
                title: "目标",
                value: targetName,
                detail: "稳定排序目标"
            )
        )
        factors.append(
            EnemyThreatCountermeasurePriorityFactor(
                kind: .destination,
                title: "坐标",
                value: destinationText,
                detail: "稳定排序位置"
            )
        )

        return factors
    }

    var benefitMetrics: [EnemyThreatCountermeasureBenefitMetric] {
        var metrics: [EnemyThreatCountermeasureBenefitMetric] = []

        switch kind {
        case .firstStrike:
            metrics.append(
                EnemyThreatCountermeasureBenefitMetric(
                    kind: .damage,
                    title: "战果",
                    value: willDestroyEnemy ? "击毁" : "-\(projectedDamage)",
                    detail: projectedEnemyHPAfterDamage.map { "敌剩余 \($0)" } ?? "压低威胁来源"
                )
            )
            if let projectedEnemyHPAfterDamage, !willDestroyEnemy {
                metrics.append(
                    EnemyThreatCountermeasureBenefitMetric(
                        kind: .survival,
                        title: "敌耐久",
                        value: "\(projectedEnemyHPAfterDamage)",
                        detail: "打击后剩余耐久"
                    )
                )
            }
            if let projectedFriendlyHPAfterAction {
                metrics.append(
                    EnemyThreatCountermeasureBenefitMetric(
                        kind: .survival,
                        title: "反击后",
                        value: "\(projectedFriendlyHPAfterAction)",
                        detail: "执行单位预计耐久"
                    )
                )
            }
        case .withdraw:
            if let projectedFriendlyHPAfterAction {
                metrics.append(
                    EnemyThreatCountermeasureBenefitMetric(
                        kind: .survival,
                        title: "保留",
                        value: "HP \(projectedFriendlyHPAfterAction)",
                        detail: "撤出后预计耐久"
                    )
                )
            }
            metrics.append(
                EnemyThreatCountermeasureBenefitMetric(
                    kind: .objective,
                    title: "目的",
                    value: destinationText,
                    detail: "远离当前威胁"
                )
            )
            if let routeCost {
                metrics.append(
                    EnemyThreatCountermeasureBenefitMetric(
                        kind: .route,
                        title: "路线",
                        value: "\(routeCost)",
                        detail: "移动力消耗"
                    )
                )
            }
        case .objectiveDefense:
            let action = destination == threatTargetCoordinate ? "进驻" : "封堵"
            metrics.append(
                EnemyThreatCountermeasureBenefitMetric(
                    kind: .objective,
                    title: "守点",
                    value: action,
                    detail: targetName
                )
            )
            metrics.append(
                EnemyThreatCountermeasureBenefitMetric(
                    kind: .objective,
                    title: "目的",
                    value: destinationText,
                    detail: "防守位置"
                )
            )
            if let routeCost {
                metrics.append(
                    EnemyThreatCountermeasureBenefitMetric(
                        kind: .route,
                        title: "路线",
                        value: "\(routeCost)",
                        detail: "移动力消耗"
                    )
                )
            }
        case .reinforce:
            metrics.append(
                EnemyThreatCountermeasureBenefitMetric(
                    kind: .recovery,
                    title: "恢复",
                    value: "+\(projectedRecoveredHP)",
                    detail: "主动整补耐久"
                )
            )
            if let projectedFriendlyHPAfterAction {
                metrics.append(
                    EnemyThreatCountermeasureBenefitMetric(
                        kind: .survival,
                        title: "整补后",
                        value: "HP \(projectedFriendlyHPAfterAction)",
                        detail: "承受威胁前耐久"
                    )
                )
            }
            metrics.append(
                EnemyThreatCountermeasureBenefitMetric(
                    kind: .objective,
                    title: "位置",
                    value: destinationText,
                    detail: "己方据点整补"
                )
            )
        }

        metrics.append(
            EnemyThreatCountermeasureBenefitMetric(
                kind: .priority,
                title: "优先",
                value: "\(score)",
                detail: "排序参考值"
            )
        )

        return metrics
    }
}

struct EnemyThreatObjectiveDefenseTradeoff: Identifiable, Equatable {
    let actionTitle: String
    let targetName: String
    let positionTitle: String
    let routeTitle: String
    let impactTitle: String
    let impactDetail: String
    let priorityTitle: String
    let summary: String

    var id: String {
        [
            actionTitle,
            targetName,
            positionTitle,
            routeTitle,
            impactTitle,
            impactDetail,
            priorityTitle
        ].joined(separator: "-")
    }
}

enum EnemyThreatCountermeasureBenefitKind: String, Identifiable {
    case damage
    case survival
    case objective
    case recovery
    case route
    case priority

    var id: String { rawValue }
}

struct EnemyThreatCountermeasureBenefitMetric: Identifiable, Equatable {
    let kind: EnemyThreatCountermeasureBenefitKind
    let title: String
    let value: String
    let detail: String

    var id: String {
        "\(kind.rawValue)-\(title)-\(value)"
    }
}

enum EnemyThreatCountermeasureImpactKind: String, Identifiable {
    case threatDamage
    case survival
    case enemyHP
    case objective
    case recovery
    case route

    var id: String { rawValue }
}

struct EnemyThreatCountermeasureImpactComparison: Identifiable, Equatable {
    let kind: EnemyThreatCountermeasureImpactKind
    let title: String
    let before: String
    let after: String
    let impact: String

    var id: String {
        "\(kind.rawValue)-\(title)-\(before)-\(after)-\(impact)"
    }
}

enum EnemyThreatCountermeasurePriorityFactorKind: String, Identifiable {
    case availability
    case decisiveStrike
    case priorityScore
    case routeCost
    case actingUnit
    case target
    case destination
    case threat
    case stableTieBreaker

    var id: String { rawValue }
}

struct EnemyThreatCountermeasurePriorityFactor: Identifiable, Equatable {
    let kind: EnemyThreatCountermeasurePriorityFactorKind
    let title: String
    let value: String
    let detail: String

    var id: String {
        "\(kind.rawValue)-\(title)-\(value)"
    }
}

struct EnemyThreatCountermeasureComparisonPreview: Identifiable, Equatable {
    let leading: EnemyThreatCountermeasurePreview
    let trailing: EnemyThreatCountermeasurePreview
    let factor: EnemyThreatCountermeasurePriorityFactor
    let summary: String

    var id: String {
        "\(leading.id)-vs-\(trailing.id)-\(factor.id)"
    }
}

enum EnemyThreatCountermeasureExecutionKind: String, Identifiable {
    case attack
    case move
    case reinforce
    case unavailable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .attack: "攻击入口"
        case .move: "移动入口"
        case .reinforce: "整补入口"
        case .unavailable: "暂不可用"
        }
    }

    var shortTitle: String {
        switch self {
        case .attack: "ATK"
        case .move: "MOVE"
        case .reinforce: "整补"
        case .unavailable: "--"
        }
    }
}

struct EnemyThreatCountermeasureExecutionPreview: Equatable {
    let kind: EnemyThreatCountermeasureExecutionKind
    let countermeasureKind: EnemyThreatCountermeasureKind
    let actionTitle: String
    let entryTitle: String
    let coordinate: HexCoordinate?
    let unitName: String
    let targetName: String
    let isExecutable: Bool
    let reason: String
}

enum EnemyThreatCountermeasureExecutionResultKind: String, Identifiable {
    case damage
    case survival
    case enemyHP
    case objective
    case recovery
    case route

    var id: String { rawValue }
}

struct EnemyThreatCountermeasureExecutionResultComparison: Identifiable, Equatable {
    let kind: EnemyThreatCountermeasureExecutionResultKind
    let title: String
    let expected: String
    let actual: String
    let result: String

    var id: String {
        "\(kind.rawValue)-\(title)-\(expected)-\(actual)-\(result)"
    }
}

struct EnemyThreatCountermeasureExecutionResultSummary: Identifiable, Equatable {
    let countermeasureID: String
    let countermeasureKind: EnemyThreatCountermeasureKind
    let executionKind: EnemyThreatCountermeasureExecutionKind
    let actingUnitID: BattleUnit.ID?
    let targetUnitID: BattleUnit.ID?
    let threatEnemyUnitID: BattleUnit.ID
    let actingUnitName: String
    let targetName: String
    let threatEnemyUnitName: String
    let coordinate: HexCoordinate?
    let threatTargetCoordinate: HexCoordinate
    let expectedSummary: String
    let comparisons: [EnemyThreatCountermeasureExecutionResultComparison]

    var id: String {
        "\(countermeasureID)-\(executionKind.rawValue)-\(coordinate?.id ?? "none")"
    }

    var actualSummary: String {
        comparisons
            .map { "\($0.title)：\($0.expected) -> \($0.actual)，\($0.result)" }
            .joined(separator: "，")
    }
}

enum EnemyThreatCountermeasureFollowUpResultKind: String, Identifiable {
    case survival
    case enemyHP
    case objective
    case position
    case aiImpact
    case recovery

    var id: String { rawValue }
}

enum EnemyThreatCountermeasureFollowUpOutcomeLevel: String, Identifiable {
    case effective
    case partial
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .effective: "奏效"
        case .partial: "部分奏效"
        case .failed: "失败"
        }
    }

    var shortTitle: String {
        switch self {
        case .effective: "OK"
        case .partial: "MID"
        case .failed: "FAIL"
        }
    }
}

enum EnemyThreatCountermeasureFollowUpFocusTargetKind: String, Identifiable {
    case actingUnit
    case threatEnemy
    case threatenedTarget

    var id: String { rawValue }

    var title: String {
        switch self {
        case .actingUnit: "执行"
        case .threatEnemy: "威胁"
        case .threatenedTarget: "目标"
        }
    }
}

struct EnemyThreatCountermeasureFollowUpFocusTarget: Identifiable, Equatable {
    let kind: EnemyThreatCountermeasureFollowUpFocusTargetKind
    let title: String
    let unitID: BattleUnit.ID?
    let coordinate: HexCoordinate?

    var id: String {
        "\(kind.rawValue)-\(unitID?.uuidString ?? coordinate?.id ?? title)"
    }
}

struct EnemyThreatCountermeasureFollowUpComparison: Identifiable, Equatable {
    let kind: EnemyThreatCountermeasureFollowUpResultKind
    let title: String
    let beforeEnemyPhase: String
    let afterEnemyPhase: String
    let result: String

    var id: String {
        "\(kind.rawValue)-\(title)-\(beforeEnemyPhase)-\(afterEnemyPhase)-\(result)"
    }
}

struct EnemyThreatCountermeasureFollowUpSummary: Identifiable, Equatable {
    let countermeasureID: String
    let countermeasureKind: EnemyThreatCountermeasureKind
    let executionKind: EnemyThreatCountermeasureExecutionKind
    let actingUnitID: BattleUnit.ID?
    let targetUnitID: BattleUnit.ID?
    let threatEnemyUnitID: BattleUnit.ID
    let actingUnitName: String
    let targetName: String
    let threatEnemyUnitName: String
    let coordinate: HexCoordinate?
    let threatTargetCoordinate: HexCoordinate
    let aiFaction: Faction
    let aiTurn: Int
    let conclusion: String
    let comparisons: [EnemyThreatCountermeasureFollowUpComparison]

    var id: String {
        "\(countermeasureID)-follow-up-\(aiFaction.rawValue)-\(aiTurn)-\(coordinate?.id ?? "none")"
    }

    var detailSummary: String {
        comparisons
            .map { "\($0.title)：\($0.beforeEnemyPhase) -> \($0.afterEnemyPhase)，\($0.result)" }
            .joined(separator: "，")
    }

    var outcomeLevel: EnemyThreatCountermeasureFollowUpOutcomeLevel {
        let results = comparisons.map(\.result)
        if results.contains(where: { result in
            result.contains("未能") ||
                result.contains("击毁") ||
                result.contains("失守") ||
                result.contains("仍在原威胁射程")
        }) {
            return .failed
        }
        if results.contains(where: { result in
            result.contains("威胁源仍在") ||
                result.contains("损失") ||
                result.contains("仍可能覆盖")
        }) {
            return .partial
        }
        return .effective
    }

    var outcomeTitle: String {
        "\(outcomeLevel.title)：\(conclusion)"
    }

    var focusTargets: [EnemyThreatCountermeasureFollowUpFocusTarget] {
        var targets: [EnemyThreatCountermeasureFollowUpFocusTarget] = []

        if let actingUnitID {
            targets.append(
                EnemyThreatCountermeasureFollowUpFocusTarget(
                    kind: .actingUnit,
                    title: actingUnitName,
                    unitID: actingUnitID,
                    coordinate: coordinate
                )
            )
        }

        targets.append(
            EnemyThreatCountermeasureFollowUpFocusTarget(
                kind: .threatEnemy,
                title: threatEnemyUnitName,
                unitID: threatEnemyUnitID,
                coordinate: nil
            )
        )

        targets.append(
            EnemyThreatCountermeasureFollowUpFocusTarget(
                kind: .threatenedTarget,
                title: targetName,
                unitID: targetUnitID,
                coordinate: threatTargetCoordinate
            )
        )

        return targets
    }
}

enum BattlefieldSituationPriority: String, Identifiable {
    case decisive
    case threatened
    case active
    case stable
    case spent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .decisive: "决胜"
        case .threatened: "受压"
        case .active: "可行动"
        case .stable: "稳定"
        case .spent: "待结算"
        }
    }

    var shortTitle: String {
        switch self {
        case .decisive: "WIN"
        case .threatened: "THR"
        case .active: "ACT"
        case .stable: "OK"
        case .spent: "END"
        }
    }
}

enum BattlefieldSituationFocusKind: String, Identifiable {
    case countermeasure
    case objectiveDefense
    case objectiveAdvance
    case forceReadiness
    case turnControl
    case resolved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countermeasure: "反制"
        case .objectiveDefense: "守点"
        case .objectiveAdvance: "推进"
        case .forceReadiness: "整队"
        case .turnControl: "回合"
        case .resolved: "结算"
        }
    }
}

struct BattlefieldSituationMetric: Identifiable, Equatable {
    let title: String
    let value: String
    let detail: String

    var id: String {
        "\(title)-\(value)-\(detail)"
    }
}

enum BattlefieldSituationActionHintKind: String, Identifiable {
    case attack
    case move
    case reinforce
    case select
    case defend

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .attack: "ATK"
        case .move: "MOVE"
        case .reinforce: "整补"
        case .select: "SEL"
        case .defend: "DEF"
        }
    }

    var iconName: String {
        switch self {
        case .attack: "scope"
        case .move: "arrow.right.circle.fill"
        case .reinforce: "cross.case.fill"
        case .select: "cursorarrow.click.2"
        case .defend: "shield.lefthalf.filled"
        }
    }
}

struct BattlefieldSituationActionHint: Identifiable, Equatable {
    let kind: BattlefieldSituationActionHintKind
    let title: String
    let entryTitle: String
    let detail: String
    let isExecutable: Bool

    var id: String {
        "\(kind.rawValue)-\(title)-\(entryTitle)-\(detail)-\(isExecutable)"
    }
}

enum BattlefieldSituationResponseKind: String, Identifiable {
    case countermeasureFollowUp
    case countermeasure
    case objectiveCapture
    case combat
    case tacticalCommand
    case deployment
    case reinforcement

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .countermeasureFollowUp: "AI"
        case .countermeasure: "CTR"
        case .objectiveCapture: "CAP"
        case .combat: "ATK"
        case .tacticalCommand: "CMD"
        case .deployment: "DEP"
        case .reinforcement: "REP"
        }
    }

    var iconName: String {
        switch self {
        case .countermeasureFollowUp: "shield.lefthalf.filled"
        case .countermeasure: "checkmark.shield.fill"
        case .objectiveCapture: "flag.checkered"
        case .combat: "scope"
        case .tacticalCommand: "bolt.fill"
        case .deployment: "shippingbox.fill"
        case .reinforcement: "cross.case.fill"
        }
    }
}

struct BattlefieldSituationResponseSummary: Identifiable, Equatable {
    let kind: BattlefieldSituationResponseKind
    let title: String
    let detail: String
    let resultTitle: String
    let resultDetail: String
    let coordinate: HexCoordinate?

    var id: String {
        [
            kind.rawValue,
            title,
            detail,
            resultTitle,
            resultDetail,
            coordinate?.id ?? "none"
        ].joined(separator: "-")
    }
}

struct BattlefieldSituationResponseHistoryEntry: Identifiable, Equatable {
    let order: Int
    let response: BattlefieldSituationResponseSummary

    var id: String {
        "\(order)-\(response.id)"
    }
}

struct BattlefieldSituationResponseMapMarker: Identifiable, Equatable {
    let kind: BattlefieldSituationResponseKind
    let coordinate: HexCoordinate
    let title: String
    let resultTitle: String
    let resultDetail: String

    var shortTitle: String {
        kind.shortTitle
    }

    var iconName: String {
        kind.iconName
    }

    var summary: String {
        "\(title)，\(resultTitle)，\(resultDetail)"
    }

    var id: String {
        [
            kind.rawValue,
            coordinate.id,
            title,
            resultTitle,
            resultDetail
        ].joined(separator: "-")
    }
}

struct BattlefieldSituationReplayTarget: Identifiable, Equatable {
    let order: Int
    let title: String
    let detail: String
    let coordinate: HexCoordinate

    var id: String {
        "\(order)-\(title)-\(coordinate.id)"
    }
}

enum BattlefieldSituationFocusTargetKind: String, Identifiable {
    case countermeasure
    case objectiveDefense
    case objectiveAdvance
    case readyUnit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countermeasure: "反制定位"
        case .objectiveDefense: "守点定位"
        case .objectiveAdvance: "推进定位"
        case .readyUnit: "待命定位"
        }
    }

    var shortTitle: String {
        switch self {
        case .countermeasure: "CTR"
        case .objectiveDefense: "DEF"
        case .objectiveAdvance: "OBJ"
        case .readyUnit: "RDY"
        }
    }
}

struct BattlefieldSituationFocusTarget: Identifiable, Equatable {
    let kind: BattlefieldSituationFocusTargetKind
    let title: String
    let detail: String
    let coordinate: HexCoordinate?
    let unitID: BattleUnit.ID?
    let countermeasurePreview: EnemyThreatCountermeasurePreview?
    let objectiveAdvancePreview: ObjectiveAdvancePreview?
    let actionHint: BattlefieldSituationActionHint

    var id: String {
        [
            kind.rawValue,
            unitID?.uuidString ?? "none",
            coordinate?.id ?? "none",
            countermeasurePreview?.id ?? "none",
            objectiveAdvancePreview?.id ?? "none",
            actionHint.id
        ].joined(separator: "-")
    }
}

struct BattlefieldSituationSummary: Equatable {
    let faction: Faction
    let priority: BattlefieldSituationPriority
    let focusKind: BattlefieldSituationFocusKind
    let title: String
    let detail: String
    let commandPoints: Int
    let readyUnitCount: Int
    let totalUnitCount: Int
    let controlledObjectiveCount: Int
    let totalObjectiveCount: Int
    let enemyThreatCount: Int
    let attackThreatCount: Int
    let objectiveThreatCount: Int
    let executableCountermeasureCount: Int
    let threatenedObjectiveNames: [String]
    let replayTarget: BattlefieldSituationReplayTarget?
    let primaryFocusTarget: BattlefieldSituationFocusTarget?

    var id: String {
        "\(faction.rawValue)-\(priority.rawValue)-\(focusKind.rawValue)-\(commandPoints)-\(readyUnitCount)-\(controlledObjectiveCount)-\(enemyThreatCount)-\(executableCountermeasureCount)-\(replayTarget?.id ?? "none")-\(primaryFocusTarget?.id ?? "none")"
    }

    var objectiveProgressText: String {
        "\(controlledObjectiveCount)/\(totalObjectiveCount)"
    }

    var readinessText: String {
        "\(readyUnitCount)/\(totalUnitCount)"
    }

    var threatenedObjectiveSummary: String {
        guard !threatenedObjectiveNames.isEmpty else { return "暂无据点威胁" }
        return threatenedObjectiveNames.joined(separator: "、")
    }

    var metrics: [BattlefieldSituationMetric] {
        [
            BattlefieldSituationMetric(
                title: "指令",
                value: "\(commandPoints)",
                detail: "\(faction.title)可用指令点"
            ),
            BattlefieldSituationMetric(
                title: "待命",
                value: readinessText,
                detail: "仍可移动或攻击的部队"
            ),
            BattlefieldSituationMetric(
                title: "据点",
                value: objectiveProgressText,
                detail: "当前控制据点进度"
            ),
            BattlefieldSituationMetric(
                title: "威胁",
                value: "\(enemyThreatCount)",
                detail: "敌方意图预判"
            ),
            BattlefieldSituationMetric(
                title: "反制",
                value: "\(executableCountermeasureCount)",
                detail: "当前可执行建议"
            )
        ]
    }
}

struct DeploymentSite: Identifiable, Equatable {
    let coordinate: HexCoordinate
    let sourceObjectiveName: String

    var id: String { "\(sourceObjectiveName)-\(coordinate.id)" }
    var title: String { "\(sourceObjectiveName) q\(coordinate.q),r\(coordinate.r)" }
}

enum MissionObjectiveState: String, Identifiable {
    case pending
    case complete
    case failed

    var id: String { rawValue }
}

struct MissionObjectiveStatus: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let state: MissionObjectiveState
}

enum MapActionHint: Equatable {
    case none
    case selectedUnit
    case selectableUnit
    case move(cost: Int, controlZonePenalty: Int)
    case attack(damage: Int, counterDamage: Int, willDestroy: Bool)
    case approachAttack(cost: Int, controlZonePenalty: Int)
    case friendlyOccupied
    case enemyOutOfRange(distance: Int, range: Int)
    case enemyUnavailable(distance: Int, range: Int)

    var isCommandable: Bool {
        switch self {
        case .move, .attack, .approachAttack:
            return true
        case .none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable:
            return false
        }
    }

    var isMove: Bool {
        if case .move = self {
            return true
        }
        return false
    }

    var isAttack: Bool {
        if case .attack = self {
            return true
        }
        return false
    }

    var isApproachAttack: Bool {
        if case .approachAttack = self {
            return true
        }
        return false
    }
}

struct MovementRoute: Equatable {
    let destination: HexCoordinate
    let coordinates: [HexCoordinate]
    let totalCost: Int
    let controlZonePenalty: Int

    var stepCount: Int {
        max(0, coordinates.count - 1)
    }
}

struct RouteStepPreview: Identifiable, Equatable {
    let coordinate: HexCoordinate
    let stepIndex: Int
    let movementCost: Int
    let controlZonePenalty: Int
    let threatCount: Int
    let threatNames: [String]
    let isDestination: Bool

    var id: String { "\(stepIndex)-\(coordinate.id)" }
    var isThreatened: Bool { threatCount > 0 }
}

struct PostMoveAttackPreview: Identifiable, Equatable {
    let targetID: BattleUnit.ID
    let targetName: String
    let damage: Int
    let counterDamage: Int
    let defenderHPAfterAttack: Int
    let willDestroy: Bool

    var id: BattleUnit.ID { targetID }
}

enum FireRiskLevel: String, CaseIterable, Identifiable {
    case none
    case low
    case medium
    case high
    case critical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "无暴露"
        case .low: "低风险"
        case .medium: "中风险"
        case .high: "高风险"
        case .critical: "致命风险"
        }
    }

    var shortTitle: String {
        switch self {
        case .none: "SAFE"
        case .low: "LOW"
        case .medium: "MED"
        case .high: "HIGH"
        case .critical: "CRIT"
        }
    }

    var sortRank: Int {
        switch self {
        case .none: 0
        case .low: 1
        case .medium: 2
        case .high: 3
        case .critical: 4
        }
    }
}

struct FireExposureSourcePreview: Identifiable, Equatable {
    let sourceID: BattleUnit.ID
    let sourceName: String
    let sourceKind: UnitKind
    let distance: Int
    let range: Int
    let potentialDamage: Int

    var id: BattleUnit.ID { sourceID }
}

struct PostMoveFireExposurePreview: Identifiable, Equatable {
    let coordinate: HexCoordinate
    let currentHP: Int
    let projectedHPAfterExposure: Int
    let totalPotentialDamage: Int
    let highestSingleDamage: Int
    let sources: [FireExposureSourcePreview]
    let riskLevel: FireRiskLevel
    let canBeDestroyedBySingleSource: Bool
    let canBeDestroyedByCombinedFire: Bool

    var id: String { coordinate.id }
}

struct ObjectiveAdvancePreview: Identifiable, Equatable {
    let objectiveName: String
    let coordinate: HexCoordinate
    let owner: Faction?
    let route: MovementRoute
    let reachesObjective: Bool
    let currentDistance: Int
    let remainingDistance: Int
    let fireExposure: PostMoveFireExposurePreview?

    var id: String { coordinate.id }
    var ownerTitle: String { owner?.title ?? "中立" }
    var destinationText: String { "q\(route.destination.q),r\(route.destination.r)" }
    var distanceClosed: Int { max(0, currentDistance - remainingDistance) }

    var actionTitle: String {
        if reachesObjective {
            return owner == nil ? "占领" : "夺取"
        }
        return "推进"
    }

    var priorityReasonText: String {
        if reachesObjective {
            return "本回合可\(actionTitle)"
        }
        return "推进 \(distanceClosed) 格，剩 \(remainingDistance) 格"
    }

    var distanceSummaryText: String {
        "距 \(currentDistance)->\(remainingDistance)"
    }

    var routeCostSummaryText: String {
        let zoneText = route.controlZonePenalty > 0 ? "，ZOC +\(route.controlZonePenalty)" : ""
        return "消耗 \(route.totalCost)，\(route.stepCount) 步\(zoneText)"
    }

    var riskSummaryText: String {
        guard let fireExposure else { return "终点 SAFE" }
        guard fireExposure.totalPotentialDamage > 0 else {
            return "终点 \(fireExposure.riskLevel.shortTitle)"
        }
        return "终点 \(fireExposure.riskLevel.shortTitle) -\(fireExposure.totalPotentialDamage)"
    }

    var prioritySummaryText: String {
        "\(ownerTitle)目标，\(priorityReasonText)，\(distanceSummaryText)，\(routeCostSummaryText)，\(riskSummaryText)"
    }
}

struct SafeEngagementOption: Identifiable, Equatable {
    let route: MovementRoute
    let exposure: PostMoveFireExposurePreview
    let targetID: BattleUnit.ID
    let targetName: String

    var id: String { "\(targetID.uuidString)-\(route.destination.id)" }
}

struct SafeEngagementComparisonPreview: Identifiable, Equatable {
    let option: SafeEngagementOption
    let referenceRoute: MovementRoute
    let referenceExposure: PostMoveFireExposurePreview
    let optionThreatenedStepCount: Int
    let referenceThreatenedStepCount: Int
    let optionRouteThreatNames: [String]
    let referenceRouteThreatNames: [String]
    let isFocused: Bool

    var id: String { option.id }
    var destination: HexCoordinate { option.route.destination }
    var referenceDestination: HexCoordinate { referenceRoute.destination }
    var riskRankDelta: Int { option.exposure.riskLevel.sortRank - referenceExposure.riskLevel.sortRank }
    var potentialDamageDelta: Int { option.exposure.totalPotentialDamage - referenceExposure.totalPotentialDamage }
    var highestSingleDamageDelta: Int { option.exposure.highestSingleDamage - referenceExposure.highestSingleDamage }
    var sourceCountDelta: Int { option.exposure.sources.count - referenceExposure.sources.count }
    var movementCostDelta: Int { option.route.totalCost - referenceRoute.totalCost }
    var controlZonePenaltyDelta: Int { option.route.controlZonePenalty - referenceRoute.controlZonePenalty }
    var threatenedStepDelta: Int { optionThreatenedStepCount - referenceThreatenedStepCount }

    var improvesExposure: Bool {
        riskRankDelta < 0 ||
            potentialDamageDelta < 0 ||
            highestSingleDamageDelta < 0 ||
            sourceCountDelta < 0 ||
            threatenedStepDelta < 0
    }

    var riskDeltaText: String {
        if riskRankDelta < 0 {
            return "风险降至 \(option.exposure.riskLevel.shortTitle)"
        }
        if riskRankDelta > 0 {
            return "风险升至 \(option.exposure.riskLevel.shortTitle)"
        }
        return "风险同为 \(option.exposure.riskLevel.shortTitle)"
    }

    var damageDeltaText: String {
        if potentialDamageDelta < 0 {
            return "少承伤 \(abs(potentialDamageDelta))"
        }
        if potentialDamageDelta > 0 {
            return "多承伤 \(potentialDamageDelta)"
        }
        return "承伤相同"
    }

    var sourceDeltaText: String {
        if sourceCountDelta < 0 {
            return "少 \(abs(sourceCountDelta)) 个敌火"
        }
        if sourceCountDelta > 0 {
            return "多 \(sourceCountDelta) 个敌火"
        }
        return "敌火数相同"
    }

    var movementDeltaText: String {
        if movementCostDelta < 0 {
            return "少走 \(abs(movementCostDelta))"
        }
        if movementCostDelta > 0 {
            return "多走 \(movementCostDelta)"
        }
        return "移动相同"
    }

    var routeThreatDeltaText: String {
        if threatenedStepDelta < 0 {
            return "路线少 \(abs(threatenedStepDelta)) 步暴露"
        }
        if threatenedStepDelta > 0 {
            return "路线多 \(threatenedStepDelta) 步暴露"
        }
        return "路线暴露相同"
    }

    var controlZoneDeltaText: String {
        if controlZonePenaltyDelta < 0 {
            return "少控区 +\(abs(controlZonePenaltyDelta))"
        }
        if controlZonePenaltyDelta > 0 {
            return "多控区 +\(controlZonePenaltyDelta)"
        }
        return "控区相同"
    }

    var summaryText: String {
        "\(damageDeltaText)，\(riskDeltaText)，\(movementDeltaText)，\(routeThreatDeltaText)"
    }
}

enum MapCommandPreview: Equatable {
    case inspectTerrain(terrainName: String)
    case selectedUnit(unitName: String)
    case selectUnit(unitName: String, kind: UnitKind)
    case move(unitName: String, terrainName: String, route: MovementRoute)
    case attack(
        attackerName: String,
        defenderName: String,
        damage: Int,
        counterDamage: Int,
        defenderHPAfterAttack: Int,
        willDestroy: Bool
    )
    case approachAttack(unitName: String, defenderName: String, route: MovementRoute)
    case friendlyOccupied(unitName: String)
    case enemyOutOfRange(defenderName: String, distance: Int, range: Int)
    case enemyUnavailable(defenderName: String, distance: Int, range: Int)
    case unreachable(unitName: String, terrainName: String)

    var isExecutable: Bool {
        switch self {
        case .move, .attack, .approachAttack:
            return true
        case .inspectTerrain, .selectedUnit, .selectUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable, .unreachable:
            return false
        }
    }
}

enum SupplyState: String, Identifiable {
    case supplied
    case isolated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .supplied: "补给畅通"
        case .isolated: "断补给"
        }
    }

    var shortTitle: String {
        switch self {
        case .supplied: "SUP"
        case .isolated: "CUT"
        }
    }

    var attackMultiplierPercent: Int {
        switch self {
        case .supplied: 100
        case .isolated: 78
        }
    }

    var movementPenalty: Int {
        switch self {
        case .supplied: 0
        case .isolated: 1
        }
    }

    var attritionDamage: Int {
        switch self {
        case .supplied: 0
        case .isolated: 6
        }
    }
}

enum MoraleState: String, Identifiable {
    case shaken
    case steady
    case inspired

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shaken: "士气低落"
        case .steady: "士气稳定"
        case .inspired: "士气高昂"
        }
    }

    var shortTitle: String {
        switch self {
        case .shaken: "LOW"
        case .steady: "OK"
        case .inspired: "HIGH"
        }
    }

    var attackMultiplierPercent: Int {
        switch self {
        case .shaken: 84
        case .steady: 100
        case .inspired: 112
        }
    }

    var movementModifier: Int {
        switch self {
        case .shaken: -1
        case .steady: 0
        case .inspired: 1
        }
    }

    static func state(for morale: Int) -> MoraleState {
        if morale >= 75 {
            return .inspired
        }
        if morale <= 34 {
            return .shaken
        }
        return .steady
    }
}

struct TerrainTile: Identifiable, Equatable {
    let coordinate: HexCoordinate
    let terrain: TerrainKind
    var objectiveName: String?
    var owner: Faction?

    var id: String { coordinate.id }
    var isObjective: Bool { objectiveName != nil }
}

struct BattleUnit: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let kind: UnitKind
    let faction: Faction
    var position: HexCoordinate
    var hp: Int
    var commander: Commander?
    var experience = 0
    var morale = 60
    var hasMoved = false
    var hasAttacked = false
    var isEntrenched = false
    var tacticalStatus: UnitTacticalStatus = .normal

    var rank: UnitRank { UnitRank.rank(for: experience) }
    var moraleState: MoraleState { MoraleState.state(for: morale) }
    var maxHP: Int { kind.baseHP + rank.hpBonus }
    var isDestroyed: Bool { hp <= 0 }
    var movement: Int {
        var value = kind.movement
        if commander?.name == "古德里安", kind == .tank {
            value += 1
        }
        return value
    }
    var range: Int { kind.range }
    var canMove: Bool { !hasMoved && !isDestroyed }
    var canAttack: Bool { !hasAttacked && !isDestroyed }

    var attack: Int {
        var value = kind.baseAttack + rank.attackBonus
        if let commander {
            value += commander.tactics * 2
            if commander.name == "巴顿", kind == .tank {
                value += 8
            }
        }
        return value
    }
}

enum UnitRank: String, CaseIterable, Identifiable {
    case green
    case regular
    case veteran
    case elite
    case ace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .green: "新兵"
        case .regular: "正规"
        case .veteran: "老兵"
        case .elite: "精锐"
        case .ace: "王牌"
        }
    }

    var insignia: String {
        switch self {
        case .green: "I"
        case .regular: "II"
        case .veteran: "III"
        case .elite: "IV"
        case .ace: "V"
        }
    }

    var minimumExperience: Int {
        switch self {
        case .green: 0
        case .regular: 20
        case .veteran: 50
        case .elite: 90
        case .ace: 140
        }
    }

    var attackBonus: Int {
        switch self {
        case .green: 0
        case .regular: 2
        case .veteran: 5
        case .elite: 8
        case .ace: 12
        }
    }

    var hpBonus: Int {
        switch self {
        case .green: 0
        case .regular: 4
        case .veteran: 9
        case .elite: 15
        case .ace: 22
        }
    }

    var nextRank: UnitRank? {
        switch self {
        case .green: .regular
        case .regular: .veteran
        case .veteran: .elite
        case .elite: .ace
        case .ace: nil
        }
    }

    static func rank(for experience: Int) -> UnitRank {
        UnitRank.allCases
            .filter { experience >= $0.minimumExperience }
            .last ?? .green
    }
}

struct Scenario: Identifiable {
    let id: String
    let name: String
    let year: String
    let briefing: String
    let initialFocus: HexCoordinate
    let mapColumns: Int
    let mapRows: Int
    var tiles: [TerrainTile]
    var units: [BattleUnit]
    var turnLimit = 10
    var decisiveTurnLimit = 6
    var survivalStarThreshold = 3

    static var campaignCatalog: [Scenario] {
        [
            ardennesPrototype(),
            normandyBreakout()
        ]
    }

    static func ardennesPrototype() -> Scenario {
        let columns = 22
        let rows = 14
        let cityCoordinates: Set<HexCoordinate> = [
            HexCoordinate(q: 2, r: 4),
            HexCoordinate(q: 4, r: 4),
            HexCoordinate(q: 7, r: 4),
            HexCoordinate(q: 5, r: 7),
            HexCoordinate(q: 10, r: 4),
            HexCoordinate(q: 12, r: 7),
            HexCoordinate(q: 6, r: 9),
            HexCoordinate(q: 15, r: 3),
            HexCoordinate(q: 16, r: 6),
            HexCoordinate(q: 14, r: 9),
            HexCoordinate(q: 18, r: 4),
            HexCoordinate(q: 19, r: 6),
            HexCoordinate(q: 20, r: 8),
            HexCoordinate(q: 17, r: 10),
            HexCoordinate(q: 11, r: 12)
        ]
        var tiles: [TerrainTile] = []

        for r in 0..<rows {
            for q in 0..<columns {
                let coordinate = HexCoordinate(q: q, r: r)
                let terrain: TerrainKind
                if cityCoordinates.contains(coordinate) {
                    terrain = .city
                } else if (q == 6 && r >= 1 && r <= 10) ||
                    (q == 10 && r >= 5 && r <= 10) ||
                    (q == 13 && r >= 3 && r <= 10) ||
                    (q == 17 && r >= 2 && r <= 12) ||
                    (q == 20 && r >= 5 && r <= 13) {
                    terrain = .river
                } else if r == 4 ||
                    q == 2 ||
                    (q >= 7 && r == 2) ||
                    (q >= 8 && q <= 16 && r == 7) ||
                    (q == 5 && r >= 5) ||
                    (q == 8 && r >= 2 && r <= 9) ||
                    (q == 12 && r >= 4 && r <= 10) ||
                    (q == 15 && r >= 1 && r <= 7) ||
                    (q >= 13 && q <= 16 && r == 9) ||
                    (q >= 16 && q <= 21 && r == 8) ||
                    (q == 18 && r >= 4 && r <= 10) ||
                    (q == 19 && r >= 6 && r <= 9) ||
                    (q == 21 && r >= 6 && r <= 10) ||
                    (q >= 8 && q <= 16 && r == 12) ||
                    (q == 11 && r >= 9 && r <= 13) {
                    terrain = .road
                } else if (q == 3 && r <= 3) ||
                    (q == 4 && r <= 2) ||
                    (q == 8 && r >= 3 && r <= 6) ||
                    (q == 11 && r >= 2 && r <= 5) ||
                    (q == 14 && r >= 2 && r <= 5) ||
                    (q == 9 && r >= 8) ||
                    (q == 3 && r >= 8) ||
                    (q >= 16 && q <= 18 && r >= 1 && r <= 3) ||
                    (q >= 17 && q <= 19 && r >= 9 && r <= 12) ||
                    (q == 21 && r >= 2 && r <= 5) {
                    terrain = .forest
                } else if (q == 5 && r <= 2) ||
                    (q == 9 && r == 1) ||
                    (q == 12 && r >= 5) ||
                    (q == 16 && r >= 8) ||
                    (q >= 14 && r == 1) ||
                    (q >= 18 && q <= 21 && r <= 1) ||
                    (q >= 19 && r >= 11) {
                    terrain = .mountain
                } else if r <= 1 || (q >= 11 && r <= 3) || (r == 11 && q >= 4 && q <= 13) || (r == 13 && q >= 6 && q <= 18) {
                    terrain = .snow
                } else {
                    terrain = .plains
                }

                var tile = TerrainTile(coordinate: coordinate, terrain: terrain)
                if q == 2 && r == 4 {
                    tile.objectiveName = "巴斯托涅"
                    tile.owner = .allies
                }
                if q == 4 && r == 4 {
                    tile.objectiveName = "圣维特"
                    tile.owner = .allies
                }
                if q == 7 && r == 4 {
                    tile.objectiveName = "马尔梅迪"
                    tile.owner = nil
                }
                if q == 5 && r == 7 {
                    tile.objectiveName = "铁路枢纽"
                    tile.owner = nil
                }
                if q == 10 && r == 4 {
                    tile.objectiveName = "补给站"
                    tile.owner = .axis
                }
                if q == 12 && r == 7 {
                    tile.objectiveName = "装甲集结地"
                    tile.owner = .axis
                }
                if q == 6 && r == 9 {
                    tile.objectiveName = "南部桥头堡"
                    tile.owner = nil
                }
                if q == 15 && r == 3 {
                    tile.objectiveName = "列日通道"
                    tile.owner = .axis
                }
                if q == 16 && r == 6 {
                    tile.objectiveName = "莱茵补给线"
                    tile.owner = .axis
                }
                if q == 14 && r == 9 {
                    tile.objectiveName = "装甲工厂"
                    tile.owner = .axis
                }
                if q == 18 && r == 4 {
                    tile.objectiveName = "默兹渡口"
                    tile.owner = nil
                }
                if q == 19 && r == 6 {
                    tile.objectiveName = "西墙工事"
                    tile.owner = .axis
                }
                if q == 20 && r == 8 {
                    tile.objectiveName = "鲁尔工业区"
                    tile.owner = .axis
                }
                if q == 11 && r == 12 {
                    tile.objectiveName = "南翼补给站"
                    tile.owner = nil
                }
                tiles.append(tile)
            }
        }

        let units = [
            BattleUnit(name: "第4装甲师", kind: .tank, faction: .allies, position: HexCoordinate(q: 2, r: 5), hp: UnitKind.tank.baseHP, commander: .patton),
            BattleUnit(name: "第101空降师", kind: .infantry, faction: .allies, position: HexCoordinate(q: 2, r: 4), hp: UnitKind.infantry.baseHP, commander: .montgomery),
            BattleUnit(name: "M7牧师炮兵", kind: .artillery, faction: .allies, position: HexCoordinate(q: 1, r: 6), hp: UnitKind.artillery.baseHP, commander: nil),
            BattleUnit(name: "灰狗侦察队", kind: .recon, faction: .allies, position: HexCoordinate(q: 3, r: 6), hp: UnitKind.recon.baseHP, commander: nil),
            BattleUnit(name: "第9步兵师", kind: .infantry, faction: .allies, position: HexCoordinate(q: 4, r: 4), hp: UnitKind.infantry.baseHP, commander: nil),
            BattleUnit(name: "第7装甲旅", kind: .tank, faction: .allies, position: HexCoordinate(q: 3, r: 7), hp: UnitKind.tank.baseHP, commander: nil),
            BattleUnit(name: "第30步兵师", kind: .infantry, faction: .allies, position: HexCoordinate(q: 1, r: 3), hp: UnitKind.infantry.baseHP, commander: nil),
            BattleUnit(name: "英军近卫装甲师", kind: .tank, faction: .allies, position: HexCoordinate(q: 5, r: 5), hp: UnitKind.tank.baseHP, commander: nil),
            BattleUnit(name: "远程炮兵群", kind: .artillery, faction: .allies, position: HexCoordinate(q: 4, r: 6), hp: UnitKind.artillery.baseHP, commander: nil),
            BattleUnit(name: "第5游骑兵团", kind: .infantry, faction: .allies, position: HexCoordinate(q: 6, r: 8), hp: UnitKind.infantry.baseHP, commander: nil),
            BattleUnit(name: "自由法国装甲群", kind: .tank, faction: .allies, position: HexCoordinate(q: 6, r: 10), hp: UnitKind.tank.baseHP, commander: nil),
            BattleUnit(name: "M10坦克歼击营", kind: .recon, faction: .allies, position: HexCoordinate(q: 7, r: 6), hp: UnitKind.recon.baseHP, commander: nil),
            BattleUnit(name: "第2装甲集团", kind: .tank, faction: .axis, position: HexCoordinate(q: 10, r: 4), hp: UnitKind.tank.baseHP, commander: .guderian),
            BattleUnit(name: "虎式重装连", kind: .tank, faction: .axis, position: HexCoordinate(q: 9, r: 3), hp: UnitKind.tank.baseHP, commander: .manstein),
            BattleUnit(name: "掷弹兵团", kind: .infantry, faction: .axis, position: HexCoordinate(q: 11, r: 5), hp: UnitKind.infantry.baseHP, commander: nil),
            BattleUnit(name: "88炮阵地", kind: .artillery, faction: .axis, position: HexCoordinate(q: 11, r: 3), hp: UnitKind.artillery.baseHP, commander: nil),
            BattleUnit(name: "装甲侦察营", kind: .recon, faction: .axis, position: HexCoordinate(q: 9, r: 6), hp: UnitKind.recon.baseHP, commander: nil),
            BattleUnit(name: "党卫装甲预备队", kind: .tank, faction: .axis, position: HexCoordinate(q: 12, r: 7), hp: UnitKind.tank.baseHP, commander: nil),
            BattleUnit(name: "东线老兵团", kind: .infantry, faction: .axis, position: HexCoordinate(q: 14, r: 4), hp: UnitKind.infantry.baseHP, commander: nil),
            BattleUnit(name: "火箭炮连", kind: .artillery, faction: .axis, position: HexCoordinate(q: 15, r: 3), hp: UnitKind.artillery.baseHP, commander: nil),
            BattleUnit(name: "第116装甲师", kind: .tank, faction: .axis, position: HexCoordinate(q: 14, r: 8), hp: UnitKind.tank.baseHP, commander: nil),
            BattleUnit(name: "警戒侦察队", kind: .recon, faction: .axis, position: HexCoordinate(q: 16, r: 6), hp: UnitKind.recon.baseHP, commander: nil),
            BattleUnit(name: "豹式预备营", kind: .tank, faction: .axis, position: HexCoordinate(q: 18, r: 5), hp: UnitKind.tank.baseHP, commander: nil),
            BattleUnit(name: "西墙守备旅", kind: .infantry, faction: .axis, position: HexCoordinate(q: 19, r: 6), hp: UnitKind.infantry.baseHP, commander: nil),
            BattleUnit(name: "鲁尔防空炮群", kind: .artillery, faction: .axis, position: HexCoordinate(q: 20, r: 8), hp: UnitKind.artillery.baseHP, commander: nil),
            BattleUnit(name: "南翼掷弹兵", kind: .infantry, faction: .axis, position: HexCoordinate(q: 12, r: 12), hp: UnitKind.infantry.baseHP, commander: nil),
            BattleUnit(name: "第1伞兵团", kind: .infantry, faction: .axis, position: HexCoordinate(q: 18, r: 10), hp: UnitKind.infantry.baseHP, commander: nil)
        ]

        return Scenario(
            id: "ardennes-1944",
            name: "阿登反击战",
            year: "1944",
            briefing: "沿公路网突破阿登森林，夺取马尔梅迪、补给站、铁路枢纽、桥头堡、默兹渡口和鲁尔工业区。大地图包含多道河线、森林防线、城市据点与多路装甲推进。",
            initialFocus: HexCoordinate(q: 2, r: 4),
            mapColumns: columns,
            mapRows: rows,
            tiles: tiles,
            units: units,
            turnLimit: 22,
            decisiveTurnLimit: 15,
            survivalStarThreshold: 8
        )
    }

    static func normandyBreakout() -> Scenario {
        let columns = 10
        let rows = 7
        var tiles: [TerrainTile] = []

        for r in 0..<rows {
            for q in 0..<columns {
                let terrain: TerrainKind
                if q <= 1 {
                    terrain = .plains
                } else if r == 3 || q == 4 {
                    terrain = .road
                } else if (q == 6 && r >= 1 && r <= 5) || (q == 8 && r >= 2) {
                    terrain = .forest
                } else if (q == 5 && r == 2) || (q == 7 && r == 4) {
                    terrain = .city
                } else if q == 3 && r >= 4 {
                    terrain = .river
                } else if (q == 7 && r == 1) || (q == 8 && r == 1) {
                    terrain = .mountain
                } else {
                    terrain = .plains
                }

                var tile = TerrainTile(coordinate: HexCoordinate(q: q, r: r), terrain: terrain)
                if q == 1 && r == 4 {
                    tile.objectiveName = "滩头阵地"
                    tile.owner = .allies
                }
                if q == 5 && r == 2 {
                    tile.objectiveName = "机场"
                    tile.owner = nil
                }
                if q == 7 && r == 4 {
                    tile.objectiveName = "卡昂"
                    tile.owner = .axis
                }
                if q == 8 && r == 2 {
                    tile.objectiveName = "装甲集结地"
                    tile.owner = .axis
                }
                tiles.append(tile)
            }
        }

        let units = [
            BattleUnit(name: "第3加拿大师", kind: .infantry, faction: .allies, position: HexCoordinate(q: 1, r: 4), hp: UnitKind.infantry.baseHP, commander: .montgomery),
            BattleUnit(name: "谢尔曼装甲旅", kind: .tank, faction: .allies, position: HexCoordinate(q: 2, r: 4), hp: UnitKind.tank.baseHP, commander: nil),
            BattleUnit(name: "海军炮兵群", kind: .artillery, faction: .allies, position: HexCoordinate(q: 0, r: 5), hp: UnitKind.artillery.baseHP, commander: nil),
            BattleUnit(name: "侦察摩托连", kind: .recon, faction: .allies, position: HexCoordinate(q: 2, r: 5), hp: UnitKind.recon.baseHP, commander: nil),
            BattleUnit(name: "第12党卫装甲师", kind: .tank, faction: .axis, position: HexCoordinate(q: 8, r: 2), hp: UnitKind.tank.baseHP, commander: .guderian),
            BattleUnit(name: "卡昂守备队", kind: .infantry, faction: .axis, position: HexCoordinate(q: 7, r: 4), hp: UnitKind.infantry.baseHP, commander: .manstein),
            BattleUnit(name: "海岸炮阵地", kind: .artillery, faction: .axis, position: HexCoordinate(q: 8, r: 3), hp: UnitKind.artillery.baseHP, commander: nil),
            BattleUnit(name: "装甲侦察营", kind: .recon, faction: .axis, position: HexCoordinate(q: 6, r: 5), hp: UnitKind.recon.baseHP, commander: nil)
        ]

        return Scenario(
            id: "normandy-1944",
            name: "诺曼底突破",
            year: "1944",
            briefing: "从滩头阵地向内陆突破，夺取机场、卡昂和装甲集结地。控制公路可快速推进，城市与森林适合防守。",
            initialFocus: HexCoordinate(q: 1, r: 4),
            mapColumns: columns,
            mapRows: rows,
            tiles: tiles,
            units: units,
            turnLimit: 12,
            decisiveTurnLimit: 7,
            survivalStarThreshold: 3
        )
    }
}
