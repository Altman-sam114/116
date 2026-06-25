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
