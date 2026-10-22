import SwiftUI

enum MapCommandPreviewChrome {
    static func iconName(for preview: MapCommandPreview) -> String {
        switch preview {
        case .move:
            return "arrow.turn.up.right"
        case .attack:
            return "target"
        case .approachAttack:
            return "scope"
        case .selectedUnit, .selectUnit, .friendlyOccupied:
            return "shield.fill"
        case .enemyOutOfRange, .enemyUnavailable, .unreachable:
            return "exclamationmark.triangle.fill"
        case .inspectTerrain:
            return "hexagon.fill"
        }
    }

    static func commandActionIcon(for preview: MapCommandPreview) -> String {
        switch preview {
        case .move:
            return "arrow.turn.up.right"
        case .attack:
            return "target"
        case .approachAttack:
            return "scope"
        case .inspectTerrain, .selectedUnit, .selectUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable, .unreachable:
            return "play.fill"
        }
    }

    static func accentColor(for preview: MapCommandPreview) -> Color {
        switch preview {
        case .move:
            return .cyan
        case .attack, .approachAttack:
            return .orange
        case .enemyOutOfRange, .enemyUnavailable, .unreachable:
            return .red
        case .selectedUnit, .selectUnit, .friendlyOccupied:
            return .yellow
        case .inspectTerrain:
            return .white.opacity(0.72)
        }
    }

    static func compactTitle(for preview: MapCommandPreview) -> String {
        switch preview {
        case .move:
            return "MOVE 移动预览"
        case .attack:
            return "ATK 攻击判定"
        case .approachAttack:
            return "POS 接敌位置"
        case let .selectedUnit(unitName):
            return unitName
        case let .selectUnit(unitName, _):
            return "可选择 \(unitName)"
        case .friendlyOccupied:
            return "友军占据"
        case .enemyOutOfRange:
            return "目标在射程外"
        case .enemyUnavailable:
            return "攻击不可用"
        case .unreachable:
            return "无法移动"
        case .inspectTerrain:
            return "查看地形"
        }
    }

    static func panelTitle(for preview: MapCommandPreview) -> String {
        switch preview {
        case .inspectTerrain:
            return "查看地形"
        case let .selectedUnit(unitName):
            return unitName
        case let .selectUnit(_, kind):
            return "选择 \(kind.title)"
        case .move:
            return "移动预览"
        case .approachAttack:
            return "接敌移动"
        case .attack:
            return "攻击预览"
        case .friendlyOccupied:
            return "友军占据"
        case .enemyOutOfRange:
            return "超出射程"
        case .enemyUnavailable:
            return "攻击不可用"
        case .unreachable:
            return "无法到达"
        }
    }

    static func uniqueThreatNames(from steps: [RouteStepPreview]) -> [String] {
        var names: [String] = []
        for step in steps {
            for name in step.threatNames where !names.contains(name) {
                names.append(name)
            }
        }
        return names
    }

    static func routeRiskCompact(threatenedSteps: [RouteStepPreview]) -> String {
        guard !threatenedSteps.isEmpty else { return "，无敌火风险" }
        let names = uniqueThreatNames(from: threatenedSteps).prefix(2).joined(separator: "、")
        return "，\(threatenedSteps.count) 步受威胁：\(names)"
    }

    static func routeRiskDetailed(threatenedSteps: [RouteStepPreview]) -> String {
        guard !threatenedSteps.isEmpty else { return "无敌火风险" }
        let names = uniqueThreatNames(from: threatenedSteps).prefix(2).joined(separator: "、")
        return "\(threatenedSteps.count) 步暴露在 \(names) 火力下"
    }

    static func fireExposureCompact(preview: PostMoveFireExposurePreview?) -> String {
        guard let preview else { return "" }
        guard preview.riskLevel != .none else {
            return "，终点 \(preview.riskLevel.shortTitle)，无潜在伤害"
        }
        let sources = preview.sources.prefix(2).map(\.sourceName).joined(separator: "、")
        let sourceText = sources.isEmpty ? "" : "，来源 \(sources)"
        return "，终点 \(preview.riskLevel.shortTitle) \(preview.riskLevel.title)，潜在 -\(preview.totalPotentialDamage)，预计剩 \(preview.projectedHPAfterExposure)\(sourceText)"
    }

    static func fireExposureDetailed(preview: PostMoveFireExposurePreview?) -> String {
        guard let preview else { return "" }
        guard preview.riskLevel != .none else {
            return "，终点 \(preview.riskLevel.shortTitle)，无潜在伤害"
        }
        let sources = preview.sources.prefix(2).map(\.sourceName).joined(separator: "、")
        let sourceText = sources.isEmpty ? "" : "，主要来源 \(sources)"
        let destroyedText = preview.canBeDestroyedByCombinedFire ? "，可能被合计火力击毁" : ""
        return "，终点 \(preview.riskLevel.shortTitle) \(preview.riskLevel.title)，潜在承伤 \(preview.totalPotentialDamage)，预计剩余 \(preview.projectedHPAfterExposure)\(sourceText)\(destroyedText)"
    }

    static func routeSummaryCompact(
        route: MovementRoute,
        threatenedSteps: [RouteStepPreview],
        fireExposure: PostMoveFireExposurePreview?
    ) -> String {
        let zone = route.controlZonePenalty > 0 ? "，控区 +\(route.controlZonePenalty)" : ""
        return "\(route.stepCount) 步，总消耗 \(route.totalCost)\(zone)\(routeRiskCompact(threatenedSteps: threatenedSteps))\(fireExposureCompact(preview: fireExposure))。"
    }

    static func routeSummaryDetailed(
        route: MovementRoute,
        threatenedSteps: [RouteStepPreview],
        fireExposure: PostMoveFireExposurePreview?
    ) -> String {
        let penaltyText = route.controlZonePenalty > 0 ? "其中敌方控制区 +\(route.controlZonePenalty)，" : ""
        return "路线 \(route.stepCount) 步，总消耗 \(route.totalCost) 移动力，\(penaltyText)\(routeRiskDetailed(threatenedSteps: threatenedSteps))\(fireExposureDetailed(preview: fireExposure))。"
    }

    static func postMoveAttackCompact(
        canAttack: Bool,
        previews: [PostMoveAttackPreview]
    ) -> String {
        guard let best = previews.first else {
            return canAttack ? "移动后暂无射程内目标。" : "本回合已无法继续攻击。"
        }
        let result = best.willDestroy ? "预计击毁" : "目标剩 \(best.defenderHPAfterAttack)"
        let counter = best.counterDamage > 0 ? "，反击 -\(best.counterDamage)" : "，无反击"
        return "最佳目标 \(best.targetName)：-\(best.damage)，\(result)\(counter)。"
    }

    static func postMoveAttackDetailed(
        canAttack: Bool,
        previews: [PostMoveAttackPreview]
    ) -> String {
        if previews.isEmpty {
            return canAttack ? "移动后暂无射程内目标。" : "本回合已无法继续攻击。"
        }
        guard let best = previews.first else { return "" }
        let result = best.willDestroy ? "预计击毁" : "目标剩余 \(best.defenderHPAfterAttack) 耐久"
        let counter = best.counterDamage > 0 ? "，可能遭反击 -\(best.counterDamage)" : "，无反击"
        let extraCount = previews.count - 1
        let extraText = extraCount > 0 ? "，另有 \(extraCount) 个目标" : ""
        return "移动后最佳目标 \(best.targetName)：造成 \(best.damage) 伤害，\(result)\(counter)\(extraText)。"
    }

    static func safeEngagementCompact(
        currentRoute: MovementRoute,
        comparison: SafeEngagementComparisonPreview?
    ) -> String {
        guard let comparison, comparison.destination != currentRoute.destination else { return "" }
        return "更安全攻击位 q\(comparison.destination.q),r\(comparison.destination.r)：\(comparison.summaryText)。"
    }

    static func safeEngagementDetailed(
        currentRoute: MovementRoute,
        comparison: SafeEngagementComparisonPreview?
    ) -> String {
        guard let comparison, comparison.destination != currentRoute.destination else { return "" }
        return "安全接敌建议：q\(comparison.destination.q),r\(comparison.destination.r)，\(comparison.summaryText)。"
    }

    static func attackPositionHint(routes: [MovementRoute]) -> String {
        guard let bestRoute = routes.first else { return "本回合没有可进入的攻击位。" }
        if routes.count == 1 {
            return "可移动到 q\(bestRoute.destination.q),r\(bestRoute.destination.r) 进入攻击位。"
        }
        return "地图标出 \(routes.count) 个攻击位，最近 q\(bestRoute.destination.q),r\(bestRoute.destination.r)，消耗 \(bestRoute.totalCost) 移动力。"
    }

    static func attackDetailCompact(
        attackerName: String,
        defenderName: String,
        damage: Int,
        counterDamage: Int,
        defenderHPAfterAttack: Int,
        willDestroy: Bool
    ) -> String {
        let result = willDestroy ? "可击毁" : "目标剩 \(defenderHPAfterAttack)"
        let counter = counterDamage > 0 ? "，反击 -\(counterDamage)" : "，无反击"
        return "\(attackerName) 攻击 \(defenderName)：-\(damage)，\(result)\(counter)。"
    }

    static func attackDetailDetailed(
        attackerName: String,
        defenderName: String,
        damage: Int,
        counterDamage: Int,
        defenderHPAfterAttack: Int,
        willDestroy: Bool
    ) -> String {
        let outcome = willDestroy ? "预计击毁目标" : "目标剩余 \(defenderHPAfterAttack) 耐久"
        let counter = counterDamage > 0 ? "，可能遭反击 -\(counterDamage)" : "，无反击"
        return "右键命令 \(attackerName) 攻击 \(defenderName)，造成 \(damage) 伤害，\(outcome)\(counter)。"
    }
}

struct InlineMapCommandPreview: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        let preview = game.focusedCommandPreview

        if case let .some(.attack(attackerName, defenderName, damage, counterDamage, defenderHPAfterAttack, willDestroy)) = preview,
           let attacker = game.selectedUnit,
           let defender = game.focusedUnit {
            InlineAttackFireSolution(
                attackerName: attackerName,
                defenderName: defenderName,
                attackerHP: attacker.hp,
                attackerMaxHP: attacker.maxHP,
                attackerHPAfterCounter: game.combatPreviewAgainstFocusedTarget()?.attackerHPAfterCounter,
                defenderHP: defender.hp,
                defenderMaxHP: defender.maxHP,
                defenderHPAfterAttack: defenderHPAfterAttack,
                damage: damage,
                counterDamage: counterDamage,
                willDestroy: willDestroy,
                execute: executeFocusedCommand
            )
        } else {
            compactPreview(preview)
        }
    }

    private func executeFocusedCommand() {
        game.executeFocusedCommand()
    }

    private func compactPreview(_ preview: MapCommandPreview?) -> some View {
        HStack(spacing: 9) {
            Image(systemName: preview.map(MapCommandPreviewChrome.iconName) ?? "scope")
                .font(.caption.weight(.bold))
                .frame(width: 18, height: 18)
                .foregroundStyle(preview.map(MapCommandPreviewChrome.accentColor) ?? .white.opacity(0.66))

            VStack(alignment: .leading, spacing: 2) {
                Text(preview.map(MapCommandPreviewChrome.compactTitle) ?? "地图命令")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(preview.map(compactDetail) ?? "选择部队后，地图会标出移动、攻击和接敌位置。")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 6)

            if let preview, preview.isExecutable {
                Button(action: executeFocusedCommand) {
                    Label("执行", systemImage: MapCommandPreviewChrome.commandActionIcon(for: preview))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(MapCommandPreviewChrome.accentColor(for: preview).opacity(0.64), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("执行当前地图命令")
            } else {
                Text("预览")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background((preview.map(MapCommandPreviewChrome.accentColor) ?? Color.white).opacity(0.28), in: Capsule())
            }
        }
        .padding(9)
        .background((preview.map(MapCommandPreviewChrome.accentColor) ?? Color.white).opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke((preview.map(MapCommandPreviewChrome.accentColor) ?? Color.white).opacity(0.22), lineWidth: 1)
        )
    }

    private func compactDetail(for preview: MapCommandPreview) -> String {
        let threatenedSteps = game.focusedRouteStepPreviews.filter(\.isThreatened)
        switch preview {
        case let .move(unitName, terrainName, route):
            return "\(unitName) 可进入\(terrainName)，\(MapCommandPreviewChrome.routeSummaryCompact(route: route, threatenedSteps: threatenedSteps, fireExposure: game.focusedFireExposurePreview))\(MapCommandPreviewChrome.postMoveAttackCompact(canAttack: game.selectedUnit?.canAttack ?? false, previews: game.focusedPostMoveAttackPreviews))"
        case let .attack(attackerName, defenderName, damage, counterDamage, defenderHPAfterAttack, willDestroy):
            return MapCommandPreviewChrome.attackDetailCompact(
                attackerName: attackerName,
                defenderName: defenderName,
                damage: damage,
                counterDamage: counterDamage,
                defenderHPAfterAttack: defenderHPAfterAttack,
                willDestroy: willDestroy
            )
        case let .approachAttack(unitName, defenderName, route):
            return "\(unitName) 接近 \(defenderName)：\(MapCommandPreviewChrome.routeSummaryCompact(route: route, threatenedSteps: threatenedSteps, fireExposure: game.focusedFireExposurePreview))移动后目标进射程，不自动攻击。\(MapCommandPreviewChrome.safeEngagementCompact(currentRoute: route, comparison: game.focusedSafeEngagementComparisons.first))"
        case let .selectedUnit(unitName):
            return "\(unitName) 已选中，地图已标出可执行命令。"
        case let .selectUnit(unitName, kind):
            return "左键切换到 \(unitName)（\(kind.title)）。"
        case let .friendlyOccupied(unitName):
            return "\(unitName) 占据该格，不能作为移动目标。"
        case let .enemyOutOfRange(defenderName, distance, range):
            return "\(defenderName) 距离 \(distance)，当前射程 \(range)。"
        case let .enemyUnavailable(defenderName, _, _):
            return "\(defenderName) 当前不可攻击。"
        case let .unreachable(unitName, terrainName):
            return "\(unitName) 本回合无法进入该\(terrainName)格。"
        case let .inspectTerrain(terrainName):
            return "\(terrainName) 地格。"
        }
    }
}

private struct InlineAttackFireSolution: View {
    let attackerName: String
    let defenderName: String
    let attackerHP: Int
    let attackerMaxHP: Int
    let attackerHPAfterCounter: Int?
    let defenderHP: Int
    let defenderMaxHP: Int
    let defenderHPAfterAttack: Int
    let damage: Int
    let counterDamage: Int
    let willDestroy: Bool
    let execute: () -> Void

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 7) {
                Label("火力解算", systemImage: "scope")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Text("ATK")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 3))
                Spacer(minLength: 4)
                Label("攻击前", systemImage: "clock.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.58))
            }

            HStack(spacing: 6) {
                FireSolutionUnitStatus(
                    role: "我方",
                    name: attackerName,
                    icon: "shield.lefthalf.filled",
                    currentHP: attackerHP,
                    projectedHP: attackerHPAfterCounter,
                    maxHP: attackerMaxHP,
                    color: .cyan
                )
                Image(systemName: "arrow.right")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                FireSolutionUnitStatus(
                    role: "目标",
                    name: defenderName,
                    icon: "scope",
                    currentHP: defenderHP,
                    projectedHP: defenderHPAfterAttack,
                    maxHP: defenderMaxHP,
                    color: .red
                )
            }

            HStack(spacing: 5) {
                FireSolutionMetric(label: "HIT", icon: "burst.fill", value: "-\(damage)", color: .orange)
                FireSolutionMetric(
                    label: "RET",
                    icon: counterDamage > 0 ? "arrow.uturn.backward.circle.fill" : "shield.slash.fill",
                    value: counterDamage > 0 ? "-\(counterDamage)" : "无",
                    color: counterDamage > 0 ? .yellow : .white.opacity(0.62)
                )
                FireSolutionMetric(
                    label: "OUT",
                    icon: willDestroy ? "xmark.octagon.fill" : "heart.fill",
                    value: willDestroy ? "击毁" : "存活",
                    color: willDestroy ? .red : .green
                )
            }

            Button(action: execute) {
                Label("开火", systemImage: "scope")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.red.opacity(0.78), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.orange.opacity(0.74), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("开火攻击 \(defenderName)")
            .accessibilityHint("执行当前火力解算中的攻击命令")
        }
        .padding(8)
        .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.orange.opacity(0.38), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

private struct FireSolutionUnitStatus: View {
    let role: String
    let name: String
    let icon: String
    let currentHP: Int
    let projectedHP: Int?
    let maxHP: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(role)
                    .foregroundStyle(color)
                Text(name)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .font(.caption2.bold())

            HStack(spacing: 3) {
                Text("HP")
                    .foregroundStyle(.white.opacity(0.48))
                Text("\(currentHP)/\(maxHP)")
                    .foregroundStyle(.white)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.38))
                Text(projectedHP.map { String($0) } ?? "--")
                    .foregroundStyle(projectedHP == 0 ? .red : color)
            }
            .font(.caption2.monospacedDigit().bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(color.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(role) \(name)，当前耐久 \(currentHP)，预计耐久 \(projectedHP.map { String($0) } ?? "未知")")
    }
}

private struct FireSolutionMetric: View {
    let label: String
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Label(label, systemImage: icon)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
            Text(value)
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 5))
        .accessibilityElement(children: .combine)
    }
}

private struct OperationalOverview: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("作战进度", systemImage: "flag.2.crossed.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))
                Spacer()
                Text("\(game.alliedScore)/\(game.objectiveTiles.count) 据点")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            ProgressView(value: game.objectiveProgress)
                .tint(Faction.allies.accentColor)

            HStack(spacing: 8) {
                ForceScorePill(faction: .allies, strength: game.alliedStrength)
                ForceScorePill(faction: .axis, strength: game.axisStrength)
            }

            VStack(spacing: 6) {
                ForEach(game.missionObjectives) { objective in
                    MissionObjectiveRow(objective: objective)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MissionObjectiveRow: View {
    let objective: MissionObjectiveStatus

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: objective.state.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(objective.state.accentColor)
                .frame(width: 16)
            Text(objective.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 6)
            Text(objective.detail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct ForceScorePill: View {
    let faction: Faction
    let strength: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(faction.accentColor)
                .frame(width: 8, height: 8)
            Text(faction.title)
                .font(.caption2.weight(.bold))
            Spacer(minLength: 4)
            Text("\(strength)")
                .font(.caption.weight(.black))
        }
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 7))
    }
}

struct ForceRibbon: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        HStack(spacing: 0) {
            ForceRosterSummary(faction: .allies, units: game.units(for: .allies))

            Rectangle()
                .fill(BattlefieldTheme.hairline)
                .frame(width: 1, height: 28)
                .padding(.horizontal, 10)

            ForceRosterSummary(faction: .axis, units: game.units(for: .axis))
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BattlefieldTheme.hairline)
                .frame(height: 1)
        }
    }
}

private struct ForceRosterSummary: View {
    let faction: Faction
    let units: [BattleUnit]

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: faction == .allies ? "shield.fill" : "scope")
                .font(.caption.weight(.black))
                .foregroundStyle(faction.accentColor)

            Text(faction.shortTitle)
                .font(.caption.weight(.black))
                .foregroundStyle(faction.accentColor)

            Text("\(units.count) 支")
                .font(.caption2.weight(.bold))
                .foregroundStyle(BattlefieldTheme.mutedInk)

            Text("\(readyCount) READY")
                .font(.caption2.weight(.black))
                .foregroundStyle(readyCount > 0 ? BattlefieldTheme.signal : BattlefieldTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(faction.title)编队摘要")
        .accessibilityValue("\(units.count) 支部队，\(readyCount) 支待命")
    }

    private var readyCount: Int {
        units.filter { !$0.hasMoved || !$0.hasAttacked }.count
    }
}

struct TacticalOrderStrip: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        Group {
            if let unit = game.selectedUnit {
                ViewThatFits(in: .horizontal) {
                    horizontalLayout(for: unit)
                    verticalLayout(for: unit)
                }
            } else {
                noSelectionLayout
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BattlefieldTheme.commandDeckDeep.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.brass.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func horizontalLayout(for unit: BattleUnit) -> some View {
        HStack(spacing: 10) {
            UnitShapeBadge(
                kind: unit.kind,
                faction: unit.faction,
                hasCommander: unit.commander != nil,
                rank: unit.rank,
                supplyState: game.supplyState(for: unit),
                tacticalStatus: unit.tacticalStatus,
                isSpent: unit.hasMoved && unit.hasAttacked,
                width: 52,
                height: 30
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(unit.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(unit.commander.map { "\($0.name) · \($0.trait)" } ?? "\(unit.kind.title) · \(unit.rank.title) · \(game.supplyState(for: unit).title)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
            }

            Spacer(minLength: 6)

            TacticalMetric(icon: "point.topleft.down.curvedto.point.bottomright.up", label: "MOVE", value: "\(game.reachableTiles(for: unit).count)")
            TacticalMetric(icon: "target", label: "ATK", value: "\(game.attackableTiles(for: unit).count)")
            TacticalMetric(icon: "shield.fill", label: "HP", value: "\(unit.hp)")
            TacticalMetric(icon: "flag.fill", label: unit.moraleState.shortTitle, value: "\(unit.morale)")
            TacticalMetric(icon: game.supplyState(for: unit) == .supplied ? "fuelpump.fill" : "exclamationmark.octagon.fill", label: game.supplyState(for: unit).shortTitle, value: "\(max(0, game.supplyLineTiles(for: unit).count - 1))")
            ForEach(TacticalCommand.allCases.filter { $0.canBeUsed(by: unit.kind) }) { command in
                TacticalMetric(icon: command.systemImage, label: command.shortTitle, value: "\(game.tacticalCommandTargets(for: unit, command: command).count)")
            }
            tacticalButtons(for: unit)
        }
    }

    private func verticalLayout(for unit: BattleUnit) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                UnitShapeBadge(
                    kind: unit.kind,
                    faction: unit.faction,
                    hasCommander: unit.commander != nil,
                    rank: unit.rank,
                    supplyState: game.supplyState(for: unit),
                    tacticalStatus: unit.tacticalStatus,
                    isSpent: unit.hasMoved && unit.hasAttacked,
                    width: 50,
                    height: 30
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("\(unit.kind.title) · \(unit.rank.title) · \(game.supplyState(for: unit).title)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer(minLength: 4)
                tacticalButtons(for: unit)
            }

            HStack(spacing: 8) {
                TacticalMetric(icon: "point.topleft.down.curvedto.point.bottomright.up", label: "MOVE", value: "\(game.reachableTiles(for: unit).count)")
                TacticalMetric(icon: "target", label: "ATK", value: "\(game.attackableTiles(for: unit).count)")
                TacticalMetric(icon: "shield.fill", label: "HP", value: "\(unit.hp)")
                TacticalMetric(icon: "flag.fill", label: unit.moraleState.shortTitle, value: "\(unit.morale)")
                TacticalMetric(icon: game.supplyState(for: unit) == .supplied ? "fuelpump.fill" : "exclamationmark.octagon.fill", label: game.supplyState(for: unit).shortTitle, value: "\(max(0, game.supplyLineTiles(for: unit).count - 1))")
                ForEach(TacticalCommand.allCases.filter { $0.canBeUsed(by: unit.kind) }) { command in
                    TacticalMetric(icon: command.systemImage, label: command.shortTitle, value: "\(game.tacticalCommandTargets(for: unit, command: command).count)")
                }
            }
        }
    }

    private var noSelectionLayout: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.body.weight(.bold))
                .foregroundStyle(.yellow)
                .frame(width: 28, height: 28)
                .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text("作战目标")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(game.scenario.name) · 夺取 \(game.objectiveTiles.count) 个据点 · 当前 \(game.alliedScore)/\(game.objectiveTiles.count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 6)
        }
    }

    private func tacticalButtons(for unit: BattleUnit) -> some View {
        HStack(spacing: 6) {
            Button {
                game.waitSelectedUnit()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.caption.weight(.bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(unit.hasMoved && unit.hasAttacked)
            .accessibilityLabel("待命")

            Button {
                game.clearSelection()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .accessibilityLabel("取消选择")

            Button {
                game.focusNearestObjectiveTarget()
            } label: {
                Image(systemName: "flag.checkered")
                    .font(.caption.weight(.bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .tint(.green)
            .disabled(game.nearestObjectiveTarget(for: unit) == nil)
            .accessibilityLabel("定位最近目标据点")
        }
    }
}

private struct TacticalMetric: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
            Text(value)
                .font(.caption.weight(.black))
        }
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 7))
    }
}

struct ReinforcementDock: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        let sites = game.deploymentSites(for: .allies)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("增援部署", systemImage: "plus.square.on.square")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.brass)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 6)
                Text("盟军指令 \(game.commandPoints(for: .allies))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if sites.isEmpty {
                Text("占领并腾出己方据点后可部署新部队。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sites) { site in
                            DeploymentGroup(site: site)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BattlefieldTheme.commandDeckDeep.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.brass.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

private struct DeploymentGroup: View {
    @EnvironmentObject private var game: GameState
    let site: DeploymentSite

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(site.title, systemImage: "flag.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 6) {
                ForEach(UnitKind.allCases) { kind in
                    DeploymentButton(kind: kind, coordinate: site.coordinate)
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct DeploymentButton: View {
    @EnvironmentObject private var game: GameState
    let kind: UnitKind
    let coordinate: HexCoordinate

    var body: some View {
        Button {
            game.deploy(kind: kind, at: coordinate)
        } label: {
            VStack(spacing: 3) {
                UnitShapeBadge(
                    kind: kind,
                    faction: .allies,
                    rank: .green,
                    supplyState: .supplied,
                    width: 34,
                    height: 20
                )
                Text("\(kind.commandCost)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .frame(width: 48, height: 46)
            .background(
                Faction.allies.accentColor.opacity(game.commandPoints(for: .allies) >= kind.commandCost ? 1 : 0.36),
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
        .disabled(game.commandPoints(for: .allies) < kind.commandCost || game.winner != nil)
        .accessibilityLabel("部署\(kind.title)，消耗\(kind.commandCost)指令点")
    }
}

