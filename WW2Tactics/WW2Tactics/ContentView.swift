import SwiftUI
import UIKit


struct ContentView: View {
    @State private var isInspectorExpanded = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let isWide = width >= 900
            let isRegular = width >= 760
            let horizontalPadding: CGFloat = isWide ? 16 : (isRegular ? 12 : 8)
            let inspectorWidth: CGFloat = isWide ? 336 : 308
            let compactInspectorHeight = min(max(height * 0.34, 220), 320)

            ZStack(alignment: .top) {
                battlefieldBackdrop

                VStack(spacing: 0) {
                    TopCommandBar()
                    BattlefieldWorkspace(
                        isInspectorExpanded: $isInspectorExpanded,
                        isRegular: isRegular,
                        horizontalPadding: horizontalPadding,
                        bottomPadding: isWide ? 14 : (isRegular ? 10 : 8),
                        inspectorWidth: inspectorWidth,
                        compactInspectorHeight: compactInspectorHeight
                    )
                }
            }
        }
    }

    private var battlefieldBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BattlefieldTheme.backdropTop,
                    BattlefieldTheme.backdropBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            BattlefieldTheme.brass.opacity(0.10),
                            .clear,
                            BattlefieldTheme.signal.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(spacing: 0) {
                Rectangle()
                    .fill(BattlefieldTheme.brass.opacity(0.08))
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .fill(.black.opacity(0.18))
                    .frame(height: 26)
            }
        }
        .ignoresSafeArea()
    }
}

private struct BattlefieldWorkspace: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isInspectorExpanded: Bool
    let isRegular: Bool
    let horizontalPadding: CGFloat
    let bottomPadding: CGFloat
    let inspectorWidth: CGFloat
    let compactInspectorHeight: CGFloat

    var body: some View {
        ZStack(alignment: .trailing) {
            BattlefieldView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isInspectorExpanded {
                inspectorOverlay
                    .transition(inspectorTransition)
            }

            inspectorToggle
                .padding(.trailing, isInspectorExpanded && isRegular ? inspectorWidth + 18 : 10)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, bottomPadding)
    }

    private var inspectorOverlay: some View {
        Group {
            if isRegular {
                InspectorPanel()
                    .frame(width: inspectorWidth)
                    .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    InspectorPanel()
                        .frame(maxWidth: .infinity)
                        .frame(height: compactInspectorHeight)
                }
            }
        }
        .padding(8)
    }

    private var inspectorToggle: some View {
        Button(
            isInspectorExpanded ? "收起战场情报" : "展开战场情报",
            systemImage: "sidebar.right",
            action: toggleInspector
        )
        .labelStyle(.iconOnly)
        .font(.headline.bold())
        .foregroundStyle(isInspectorExpanded ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.brass)
        .frame(width: 44, height: 44)
        .background(
            isInspectorExpanded ? BattlefieldTheme.brass : BattlefieldTheme.commandDeckDeep.opacity(0.94),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(BattlefieldTheme.brass.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.34), radius: 7, x: 0, y: 4)
        .buttonStyle(.plain)
        .help(isInspectorExpanded ? "收起战场情报" : "展开战场情报")
        .accessibilityValue(isInspectorExpanded ? "已展开" : "已收起")
    }

    private var inspectorTransition: AnyTransition {
        if isRegular {
            .move(edge: .trailing).combined(with: .opacity)
        } else {
            .move(edge: .bottom).combined(with: .opacity)
        }
    }

    private func toggleInspector() {
        if reduceMotion {
            isInspectorExpanded.toggle()
        } else {
            withAnimation(.snappy) {
                isInspectorExpanded.toggle()
            }
        }
    }
}

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
                Button {
                    game.executeFocusedCommand()
                } label: {
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Label("编队", systemImage: "person.3.sequence.fill")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.brass)
                Text("盟军 \(game.units(for: .allies).count) · 轴心 \(game.units(for: .axis).count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                Spacer(minLength: 0)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForceRibbonFactionTag(title: "盟军", color: Faction.allies.accentColor)

                    ForEach(game.units(for: .allies)) { unit in
                        UnitRibbonButton(
                            unit: unit,
                            isSelected: game.selectedUnitID == unit.id,
                            isEnabled: unit.faction == game.activeFaction && game.winner == nil
                        )
                    }

                    Rectangle()
                        .fill(BattlefieldTheme.hairline)
                        .frame(width: 1, height: 40)

                    ForceRibbonFactionTag(title: "轴心", color: Faction.axis.accentColor)

                    ForEach(game.units(for: .axis)) { unit in
                        UnitRibbonButton(
                            unit: unit,
                            isSelected: game.focusedUnit?.id == unit.id,
                            isEnabled: game.winner == nil
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
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

private struct ForceRibbonFactionTag: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(minHeight: 36)
            .background(color.opacity(0.88), in: Capsule())
            .accessibilityHidden(true)
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

private struct UnitRibbonButton: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit
    let isSelected: Bool
    let isEnabled: Bool

    var body: some View {
        Button {
            if unit.faction == game.activeFaction {
                game.select(unitID: unit.id)
            } else {
                game.focus(unitID: unit.id)
            }
        } label: {
            HStack(spacing: 7) {
                UnitShapeBadge(
                    kind: unit.kind,
                    faction: unit.faction,
                    hasCommander: unit.commander != nil,
                    rank: unit.rank,
                    supplyState: game.supplyState(for: unit),
                    tacticalStatus: unit.tacticalStatus,
                    isSpent: unit.hasMoved && unit.hasAttacked,
                    width: 42,
                    height: 25
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(unit.name)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    HStack(spacing: 5) {
                        MiniHealthBar(ratio: unit.hpRatio)
                            .frame(width: 42, height: 5)
                        Text(unit.actionStateText)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .frame(width: 150, height: 46)
            .padding(.horizontal, 8)
            .background(
                (isSelected ? unit.faction.accentColor.opacity(0.18) : BattlefieldTheme.fieldGlass.opacity(0.42)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.yellow : unit.faction.accentColor.opacity(0.28),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .opacity(isEnabled || unit.faction != game.activeFaction ? 1 : 0.62)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(unit.faction == game.activeFaction ? "选择\(unit.name)" : "定位\(unit.name)")
    }
}




private struct InspectorSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(BattlefieldTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Rectangle()
                .fill(color.opacity(0.28))
                .frame(height: 1)
        }
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

private struct InspectorPanel: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                let enemyThreatIntents = game.visibleEnemyThreatIntentPreviews
                let enemyThreatCountermeasures = game.visibleEnemyThreatCountermeasurePreviews
                let hasPrimaryResult =
                    game.latestCombatResult != nil ||
                    game.latestTacticalCommandResult != nil ||
                    game.latestObjectiveCaptureResult != nil ||
                    game.latestDeploymentResult != nil ||
                    game.latestReinforcementResult != nil
                let hasCountermeasureResult =
                    game.latestEnemyThreatCountermeasureExecutionResult != nil ||
                    game.latestEnemyThreatCountermeasureFollowUpResult != nil
                let hasAIPhase = game.latestAIPhaseSummary != nil
                let hasIntel = !enemyThreatIntents.isEmpty

                InspectorSectionHeader(title: "主操作", icon: "person.crop.rectangle", color: BattlefieldTheme.brass)

                if let winner = game.winner {
                    VictoryPanel(winner: winner)
                } else if let unit = game.selectedUnit {
                    UnitDetail(unit: unit)
                } else {
                    ScenarioPanel()
                }

                if let tile = game.focusedTile {
                    TileDetail(tile: tile, unit: game.focusedUnit)
                }

                InspectorSectionHeader(title: "战线态势", icon: "map.fill", color: .cyan)
                BattlefieldSituationSummaryView(summary: game.battlefieldSituationSummary)

                if hasPrimaryResult || hasCountermeasureResult || hasAIPhase {
                    InspectorSectionHeader(title: "执行结果", icon: "doc.text.fill", color: .orange)

                    if let combatResult = game.latestCombatResult {
                        CombatResultSummaryView(summary: combatResult)
                    } else if let tacticalResult = game.latestTacticalCommandResult {
                        TacticalCommandResultSummaryView(summary: tacticalResult)
                    } else if let captureResult = game.latestObjectiveCaptureResult {
                        ObjectiveCaptureResultSummaryView(summary: captureResult)
                    } else if let deploymentResult = game.latestDeploymentResult {
                        DeploymentResultSummaryView(summary: deploymentResult)
                    } else if let reinforcementResult = game.latestReinforcementResult {
                        ReinforcementResultSummaryView(summary: reinforcementResult)
                    }

                    if let countermeasureResult = game.latestEnemyThreatCountermeasureExecutionResult {
                        EnemyThreatCountermeasureExecutionResultSummaryView(summary: countermeasureResult)
                    }

                    if let countermeasureFollowUp = game.latestEnemyThreatCountermeasureFollowUpResult {
                        EnemyThreatCountermeasureFollowUpSummaryView(summary: countermeasureFollowUp)
                    }

                    if let aiPhaseSummary = game.latestAIPhaseSummary {
                        AIPhaseSummaryView(summary: aiPhaseSummary)
                    }
                }

                if hasIntel {
                    InspectorSectionHeader(title: "敌情与反制", icon: "eye.trianglebadge.exclamationmark.fill", color: .pink)
                    EnemyThreatIntentPanel(previews: enemyThreatIntents)

                    if !enemyThreatCountermeasures.isEmpty {
                        EnemyThreatCountermeasurePanel(previews: enemyThreatCountermeasures)
                    }
                }

                InspectorSectionHeader(title: "战报", icon: "text.alignleft", color: BattlefieldTheme.mutedInk)
                BattleLogView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .foregroundStyle(BattlefieldTheme.ink)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(BattlefieldTheme.commandDeck.opacity(0.94))
                LinearGradient(
                    colors: [
                        BattlefieldTheme.brass.opacity(0.08),
                        .clear,
                        BattlefieldTheme.signal.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.20), radius: 12, x: 0, y: 6)
    }
}

private struct BattlefieldSituationSummaryView: View {
    @EnvironmentObject private var game: GameState
    let summary: BattlefieldSituationSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            BattlefieldSituationBriefingHeader(
                title: summary.title,
                detail: summary.detail,
                priorityTitle: summary.priority.shortTitle,
                color: priorityColor
            )

            if let response = game.battlefieldSituationResponseSummary {
                BattlefieldSituationResponseCard(
                    response: response,
                    color: responseColor,
                    historyPositionText: game.battlefieldSituationResponseHistoryPositionText,
                    showsHistory: game.battlefieldSituationResponseHistory.count > 1,
                    canFocusPrevious: game.canFocusPreviousBattlefieldSituationResponse,
                    canFocusNext: game.canFocusNextBattlefieldSituationResponse,
                    marker: game.battlefieldSituationResponseMapMarker,
                    previousAction: game.focusPreviousBattlefieldSituationResponse,
                    nextAction: game.focusNextBattlefieldSituationResponse,
                    locateAction: game.focusBattlefieldSituationResponseTarget
                )
            }

            if let replayTarget = summary.replayTarget {
                BattlefieldSituationReplayTargetButton(
                    replayTarget: replayTarget,
                    action: game.focusBattlefieldSituationReplayTarget
                )
            }

            if let target = summary.primaryFocusTarget {
                BattlefieldSituationPrimaryTargetButton(
                    target: target,
                    color: priorityColor,
                    action: game.focusBattlefieldSituationPrimaryTarget
                )
            }

            if !summary.objectivePressures.isEmpty {
                BattlefieldSituationObjectivePressureSection(
                    pressures: summary.objectivePressures,
                    color: priorityColor,
                    replayTarget: game.focusedBattlefieldSituationObjectivePressureReplayTarget
                )
            }

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 7) {
                ForEach(summary.metrics) { metric in
                    BattlefieldSituationMetricPill(metric: metric, color: priorityColor)
                }
            }

            BattlefieldSituationBriefingFooter(
                focusTitle: summary.focusKind.title,
                focusIcon: focusIcon,
                threatenedObjectiveSummary: summary.threatenedObjectiveSummary,
                color: priorityColor
            )
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    priorityColor.opacity(0.13),
                    BattlefieldTheme.commandDeckDeep.opacity(0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(priorityColor.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .contain)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 72), spacing: 7)]
    }

    private var priorityColor: Color {
        switch summary.priority {
        case .decisive:
            .yellow
        case .threatened:
            .red
        case .active:
            .green
        case .stable:
            .cyan
        case .spent:
            .gray
        }
    }

    private var responseColor: Color {
        guard let response = game.battlefieldSituationResponseSummary else { return priorityColor }
        switch response.kind {
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

    private var focusIcon: String {
        switch summary.focusKind {
        case .countermeasure:
            "bolt.shield.fill"
        case .objectiveDefense:
            "shield.lefthalf.filled"
        case .objectiveAdvance:
            "flag.checkered"
        case .forceReadiness:
            "person.3.fill"
        case .turnControl:
            "forward.end.fill"
        case .resolved:
            "crown.fill"
        }
    }
}

private struct BattlefieldSituationBriefingHeader: View {
    let title: String
    let detail: String
    let priorityTitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 8) {
                Label("战线态势", systemImage: "scope")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.brass)

                Spacer(minLength: 8)

                Text(priorityTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.90), in: Capsule())
            }

            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.caption.weight(.medium))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct BattlefieldSituationResponseCard: View {
    let response: BattlefieldSituationResponseSummary
    let color: Color
    let historyPositionText: String?
    let showsHistory: Bool
    let canFocusPrevious: Bool
    let canFocusNext: Bool
    let marker: BattlefieldSituationResponseMapMarker?
    let previousAction: () -> Void
    let nextAction: () -> Void
    let locateAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: response.kind.iconName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(response.kind.shortTitle)
                            .font(.caption.weight(.black))
                            .foregroundStyle(color)
                        Text(response.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(BattlefieldTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    Text(response.detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let marker {
                    Spacer(minLength: 4)

                    Button("定位", systemImage: "location.magnifyingglass", action: locateAction)
                        .labelStyle(.iconOnly)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .buttonStyle(.plain)
                        .accessibilityLabel("定位态势响应，\(marker.shortTitle)，\(marker.title)")
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(response.resultTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.90), in: Capsule())
                    .lineLimit(1)
                Text(response.resultDetail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BattlefieldTheme.fieldGlass.opacity(0.42), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(color.opacity(0.24), lineWidth: 1)
            )

            if showsHistory, let historyPositionText {
                HStack(spacing: 8) {
                    Button("上一条", systemImage: "chevron.left", action: previousAction)
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .disabled(!canFocusPrevious)
                        .accessibilityLabel("查看上一条态势响应")

                    Text("响应 \(historyPositionText)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)

                    Button("下一条", systemImage: "chevron.right", action: nextAction)
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .disabled(!canFocusNext)
                        .accessibilityLabel("查看下一条态势响应")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .buttonStyle(.plain)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("态势响应历史 \(historyPositionText)")
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    color.opacity(0.14),
                    BattlefieldTheme.commandDeckDeep.opacity(0.46)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("战线态势执行反馈，\(response.kind.shortTitle)，\(response.title)，\(response.detail)，\(response.resultTitle)，\(response.resultDetail)")
    }
}

private struct BattlefieldSituationReplayTargetButton: View {
    let replayTarget: BattlefieldSituationReplayTarget
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: "timeline.selection")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.13), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("复盘影响")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.blue)
                        Text(replayTarget.source.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BattlefieldTheme.mutedInk)
                    }
                    Text(replayTarget.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BattlefieldTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(replayTarget.detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(replayTarget.source.shortTitle)
                    Text(verbatim: "#\(replayTarget.order)")
                }
                .font(.caption2.weight(.black))
                .foregroundStyle(BattlefieldTheme.ink)
                .monospacedDigit()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.14),
                    BattlefieldTheme.commandDeckDeep.opacity(0.46)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 7, x: 0, y: 3)
        .accessibilityLabel("定位敌方复盘影响，\(replayTarget.source.title)，事件\(replayTarget.order)，\(replayTarget.title)，\(replayTarget.detail)")
    }
}

private struct BattlefieldSituationPrimaryTargetButton: View {
    let target: BattlefieldSituationFocusTarget
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: "location.magnifyingglass")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("首要目标")
                            .font(.caption.weight(.black))
                            .foregroundStyle(color)
                        Text(target.kind.shortTitle)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(BattlefieldTheme.mutedInk)
                    }
                    Text(target.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BattlefieldTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(target.detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    Label(target.actionHint.entryTitle, systemImage: target.actionHint.kind.iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color.opacity(target.actionHint.isExecutable ? 0.94 : 0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 4)

                Text(target.actionHint.kind.shortTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(color.opacity(target.actionHint.isExecutable ? 0.86 : 0.42), in: Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.28), lineWidth: 1)
        )
        .accessibilityLabel("定位战线态势首要目标，\(target.kind.title)，\(target.title)，\(target.detail)，下一步，\(target.actionHint.entryTitle)，\(target.actionHint.detail)")
    }
}

private struct BattlefieldSituationObjectivePressureSection: View {
    @EnvironmentObject private var game: GameState
    let pressures: [BattlefieldSituationObjectivePressure]
    let color: Color
    let replayTarget: BattlefieldSituationReplayTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Label("据点压力", systemImage: "shield.lefthalf.filled")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)

                Spacer(minLength: 6)

                Text("\(pressures.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .monospacedDigit()
                    .frame(minWidth: 24, minHeight: 24)
                    .background(color.opacity(0.82), in: Capsule())
            }

            ForEach(Array(pressures.prefix(3))) { pressure in
                let isFocused = game.isBattlefieldSituationObjectivePressureFocused(id: pressure.id)
                Button {
                    game.focusBattlefieldSituationObjectivePressure(id: pressure.id)
                } label: {
                    BattlefieldSituationObjectivePressureRow(
                        pressure: pressure,
                        color: color,
                        isFocused: isFocused
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(isFocused ? "当前据点压力，只定位地图标记，不执行移动、攻击、整补或部署。" : "只定位据点压力或守点建议，不执行移动、攻击、整补或部署。")
            }

            if let replayTarget {
                BattlefieldSituationObjectivePressureReplayButton(
                    replayTarget: replayTarget,
                    action: game.focusBattlefieldSituationObjectivePressureReplayTarget
                )
            }
        }
        .padding(9)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("据点防守压力，\(pressures.map { "\($0.objectiveName)，\($0.source.title)，\($0.primaryThreatDetail)，\($0.actionHint.entryTitle)" }.joined(separator: "；"))")
    }
}

private struct BattlefieldSituationBriefingFooter: View {
    let focusTitle: String
    let focusIcon: String
    let threatenedObjectiveSummary: String
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Label(focusTitle, systemImage: focusIcon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 6)

            Text(threatenedObjectiveSummary)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.72)
        }
        .padding(.top, 2)
    }
}

private struct BattlefieldSituationObjectivePressureReplayButton: View {
    let replayTarget: BattlefieldSituationReplayTarget
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: "timeline.selection")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.13), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 3) {
                    Text("复盘线索")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.blue)
                    Text(replayTarget.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BattlefieldTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(replayTarget.detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 4)

                Text(verbatim: "#\(replayTarget.order)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.24), lineWidth: 1)
        )
        .accessibilityLabel("定位当前据点压力的关联AI复盘线索，事件\(replayTarget.order)，\(replayTarget.title)，\(replayTarget.detail)")
    }
}

private struct BattlefieldSituationObjectivePressureRow: View {
    let pressure: BattlefieldSituationObjectivePressure
    let color: Color
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(pressure.objectiveName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(pressure.ownerTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08), in: Capsule())

                Text(pressure.source.shortTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(color)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.12), in: Capsule())

                Spacer(minLength: 4)

                if isFocused {
                    Text("当前")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.black.opacity(0.82))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.90), in: Capsule())
                }
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(pressure.primaryThreatTitle)
                        .font(.caption.weight(.black))
                        .foregroundStyle(color)
                        .lineLimit(1)
                    Text(pressure.primaryThreatDetail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                Text("\(pressure.threatSourceCount) 源")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.22), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 5) {
                BattlefieldSituationComparisonLine(
                    title: pressure.comparison.currentTitle,
                    detail: pressure.comparison.currentDetail,
                    icon: "shield",
                    color: BattlefieldTheme.mutedInk
                )
                BattlefieldSituationComparisonLine(
                    title: pressure.comparison.responseTitle,
                    detail: pressure.comparison.responseDetail,
                    icon: pressure.actionHint.kind.iconName,
                    color: color
                )

                if let enemyPhaseImpact = pressure.enemyPhaseImpact {
                    BattlefieldSituationComparisonLine(
                        title: enemyPhaseImpact.title,
                        detail: "\(enemyPhaseImpact.beforeEnemyPhase) -> \(enemyPhaseImpact.afterEnemyPhase)，\(enemyPhaseImpact.result)",
                        icon: "timeline.selection",
                        color: .blue
                    )
                }
            }

            HStack(spacing: 7) {
                Label(pressure.actionHint.entryTitle, systemImage: pressure.actionHint.kind.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color.opacity(pressure.actionHint.isExecutable ? 0.94 : 0.58))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 4)

                Text(pressure.actionHint.kind.shortTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.09), in: Capsule())

                Text(pressure.comparison.level.shortTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(color)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.10), in: Capsule())
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    color.opacity(isFocused ? 0.18 : 0.10),
                    BattlefieldTheme.commandDeckDeep.opacity(0.46)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? color.opacity(0.66) : color.opacity(0.18), lineWidth: isFocused ? 2 : 1)
        )
        .shadow(color: .black.opacity(isFocused ? 0.16 : 0.08), radius: isFocused ? 8 : 4, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let impactSummary: String
        if let enemyPhaseImpact = pressure.enemyPhaseImpact {
            impactSummary = "，敌方回合后，\(enemyPhaseImpact.title)，\(enemyPhaseImpact.beforeEnemyPhase) 到 \(enemyPhaseImpact.afterEnemyPhase)，\(enemyPhaseImpact.result)"
        } else {
            impactSummary = ""
        }
        return "\(isFocused ? "当前" : "定位")据点压力，\(pressure.objectiveName)，来源\(pressure.source.title)，\(pressure.ownerTitle)，\(pressure.threatSourceCount) 个威胁来源，\(pressure.primaryThreatTitle)，\(pressure.primaryThreatDetail)，\(pressure.comparison.currentTitle)，\(pressure.comparison.currentDetail)，\(pressure.comparison.responseTitle)，\(pressure.comparison.responseDetail)\(impactSummary)，推荐入口，\(pressure.actionHint.entryTitle)"
    }
}

private struct BattlefieldSituationComparisonLine: View {
    let title: String
    let detail: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .frame(width: 15)

            Text("\(title)：\(detail)")
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct BattlefieldSituationMetricPill: View {
    let metric: BattlefieldSituationMetric
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(1)
            Text(metric.value)
                .font(.headline.weight(.black))
                .foregroundStyle(BattlefieldTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [color.opacity(0.11), Color.black.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.14), lineWidth: 1)
        )
        .accessibilityLabel("\(metric.title)\(metric.value)，\(metric.detail)")
    }
}

private struct VictoryPanel: View {
    @EnvironmentObject private var game: GameState
    let winner: Faction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("\(winner.title)胜利", systemImage: "crown.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.yellow)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 6)

                Text(winner.shortTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.90), in: Capsule())
            }

            Text(winner == .allies ? "\(game.scenario.name)目标达成。" : "\(game.scenario.name)盟军失败。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.8)

            Button {
                game.restart()
            } label: {
                Label("重新开局", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityLabel("重新开局")
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.14),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 5)
    }
}

private struct ScenarioPanel: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("战役目标", systemImage: "map.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.brass)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(game.scenario.briefing)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(8)
                .minimumScaleFactor(0.82)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(game.objectiveTiles) { tile in
                        ObjectiveBadge(tile: tile)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                scenarioRuleLine(icon: "gift.fill", text: game.objectiveCaptureRewardSummary, color: .yellow)
                scenarioRuleLine(icon: "cross.case.fill", text: game.objectiveRestSummary, color: .green)
                scenarioRuleLine(icon: "exclamationmark.triangle.fill", text: game.zoneOfControlSummary, color: .red)
                scenarioRuleLine(icon: "shield.lefthalf.filled", text: game.entrenchmentSummary, color: .cyan)
                scenarioRuleLine(icon: "point.3.connected.trianglepath.dotted", text: game.flankingSupportSummary, color: .green)
                scenarioRuleLine(icon: "star.bubble.fill", text: game.commanderAuraSummary, color: .yellow)
                scenarioRuleLine(icon: "arrow.forward.circle.fill", text: game.maneuverPursuitSummary, color: .orange)
            }

            TerrainKey()
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    BattlefieldTheme.brass.opacity(0.10),
                    BattlefieldTheme.commandDeckDeep.opacity(0.46)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(BattlefieldTheme.brass.opacity(0.22), lineWidth: 1)
        )
    }

    private func scenarioRuleLine(icon: String, text: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color.opacity(0.92))
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(3)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct ObjectiveBadge: View {
    let tile: TerrainTile

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "star.fill")
                .foregroundStyle(tile.owner?.accentColor ?? .white.opacity(0.55))
            Text(tile.objectiveName ?? "据点")
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(tile.owner?.shortTitle ?? "NEU")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle((tile.owner?.accentColor ?? Color.white).opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 78)
        .padding(8)
        .background(BattlefieldTheme.fieldGlass.opacity(0.42), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke((tile.owner?.accentColor ?? Color.white).opacity(0.22), lineWidth: 1)
        )
    }
}

private struct UnitDetail: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(unit.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BattlefieldTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text("\(unit.faction.title) · \(unit.kind.title) · \(unit.rank.title)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 6)

                Text(unit.kind.code)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(unit.faction.accentColor, in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [
                        unit.faction.accentColor.opacity(0.14),
                        BattlefieldTheme.commandDeckDeep.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(unit.faction.accentColor.opacity(0.28), lineWidth: 1)
            )

            InspectorSectionHeader(title: "状态", icon: "heart.text.square.fill", color: .cyan)
            StatRows(unit: unit)
            ExperiencePanel(unit: unit)
            SupplyPanel(unit: unit)
            MoralePanel(unit: unit)
            ActionSummary(unit: unit)

            InspectorSectionHeader(title: "作战方案", icon: "scope", color: .orange)
            FocusedCommandPreviewPanel()
            SafeEngagementOptionsPanel()
            ObjectiveAdvancePlanPanel(unit: unit)
            AttackTargetsView(unit: unit)
            TacticalCommandPanel(unit: unit)
            ThreatSummary(unit: unit)

            if let preview = game.combatPreviewAgainstFocusedTarget() {
                CombatForecastView(preview: preview)
            }

            if unit.commander != nil {
                InspectorSectionHeader(title: "指挥", icon: "person.crop.square.fill", color: .yellow)
            }

            if let commander = unit.commander {
                CommanderView(commander: commander)
            }

            HStack(spacing: 8) {
                Button {
                    game.reinforceSelectedUnit()
                } label: {
                    Label("整补", systemImage: "cross.case.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!game.canReinforce(unit))

                Button {
                    game.waitSelectedUnit()
                } label: {
                    Label("待命", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .disabled(unit.hasMoved && unit.hasAttacked)

                Button {
                    game.clearSelection()
                } label: {
                    Label("取消", systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
    }
}

private struct ObjectiveAdvancePlanPanel: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        let previews = game.objectiveAdvancePreviews(for: unit)

        if !previews.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Label("目标计划", systemImage: "flag.checkered")
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)

                    Text("\(previews.count) 条")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black.opacity(0.82))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.88), in: Capsule())
                        .lineLimit(1)
                }
                .foregroundStyle(.green)

                VStack(spacing: 7) {
                    ForEach(Array(previews.enumerated()), id: \.element.id) { index, preview in
                        let isFocused = game.guidedObjectiveCoordinate == preview.coordinate &&
                            game.focusedCoordinate == preview.route.destination
                        Button {
                            game.focusObjectiveAdvancePreview(preview)
                        } label: {
                            ObjectiveAdvancePlanRow(index: index, preview: preview, isFocused: isFocused)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accessibilityLabel(for: preview, index: index, isFocused: isFocused))
                        .accessibilityHint("聚焦该目标计划，不执行移动")
                    }
                }
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.12),
                        BattlefieldTheme.commandDeckDeep.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.28), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
        }
    }

    private func accessibilityLabel(for preview: ObjectiveAdvancePreview, index: Int, isFocused: Bool) -> String {
        let slot = index == 0 ? "OBJ 首选" : "目标计划 \(index + 1)"
        let focused = isFocused ? "，当前预览" : ""
        return "\(slot)，\(preview.objectiveName)\(focused)，\(preview.prioritySummaryText)。"
    }
}

private struct ObjectiveAdvancePlanRow: View {
    let index: Int
    let preview: ObjectiveAdvancePreview
    let isFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(isFocused ? "当前" : (index == 0 ? "OBJ" : "\(index + 1)"))
                .font(.caption2.weight(.black))
                .foregroundStyle(.black.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(width: 34, height: 24)
                .background(markerColor, in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(preview.objectiveName)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 6)

                    Text(preview.ownerTitle)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(preview.owner?.accentColor ?? .white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text("\(preview.actionTitle) \(preview.destinationText) · 距离 \(preview.currentDistance)->\(preview.remainingDistance) · 消耗 \(preview.route.totalCost)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(preview.prioritySummaryText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    ObjectiveAdvanceMetric(text: "\(preview.route.stepCount) 步", color: .cyan)
                    ObjectiveAdvanceMetric(text: controlZoneText, color: preview.route.controlZonePenalty > 0 ? .orange : .white.opacity(0.62))
                    ObjectiveAdvanceMetric(text: fireRiskText, color: fireRiskColor)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(
            (isFocused ? Color.yellow.opacity(0.12) : BattlefieldTheme.fieldGlass.opacity(index == 0 ? 0.48 : 0.34)),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var markerColor: Color {
        if isFocused { return Color.yellow.opacity(0.92) }
        return index == 0 ? Color.green.opacity(0.92) : Color.white.opacity(0.68)
    }

    private var borderColor: Color {
        if isFocused { return Color.yellow.opacity(0.62) }
        return index == 0 ? Color.green.opacity(0.34) : Color.white.opacity(0.10)
    }

    private var controlZoneText: String {
        preview.route.controlZonePenalty > 0 ? "ZOC +\(preview.route.controlZonePenalty)" : "ZOC 0"
    }

    private var fireRiskText: String {
        guard let fireExposure = preview.fireExposure else { return "SAFE" }
        guard fireExposure.totalPotentialDamage > 0 else { return fireExposure.riskLevel.shortTitle }
        return "\(fireExposure.riskLevel.shortTitle) -\(fireExposure.totalPotentialDamage)"
    }

    private var fireRiskColor: Color {
        preview.fireExposure?.riskLevel.accentColor ?? FireRiskLevel.none.accentColor
    }
}

private struct ObjectiveAdvanceMetric: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct SafeEngagementOptionsPanel: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        if shouldShowPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: "shield.checkered")
                        .font(.caption.weight(.bold))
                        .frame(width: 16)
                    Text("安全接敌")
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 8)
                    Text("点选预览")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.82))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.88), in: Capsule())
                }
                .foregroundStyle(.green.opacity(0.92))

                ForEach(Array(game.focusedSafeEngagementComparisons.prefix(3))) { comparison in
                    Button {
                        game.focusSafeEngagementOption(comparison.option)
                    } label: {
                        SafeEngagementOptionRow(comparison: comparison)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: comparison))
                    .accessibilityHint("只切换接敌路线预览，不会移动或攻击")
                }
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.12),
                        BattlefieldTheme.commandDeckDeep.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.28), lineWidth: 1)
            )
        }
    }

    private var shouldShowPanel: Bool {
        guard let selectedUnit = game.selectedUnit,
              let focusedUnit = game.focusedUnit,
              focusedUnit.faction != selectedUnit.faction,
              !game.attackableTiles(for: selectedUnit).contains(focusedUnit.position) else { return false }
        return !game.focusedSafeEngagementComparisons.isEmpty
    }

    private func accessibilityLabel(for comparison: SafeEngagementComparisonPreview) -> String {
        let option = comparison.option
        let focused = comparison.isFocused ? "，当前预览" : ""
        let sourceText = option.exposure.sources.isEmpty
            ? "无主要敌火"
            : "主要敌火\(option.exposure.sources.prefix(2).map(\.sourceName).joined(separator: "、"))"
        return "安全接敌\(focused)，目的地 q\(option.route.destination.q),r\(option.route.destination.r)，\(comparison.summaryText)，\(sourceText)"
    }
}

private struct SafeEngagementOptionRow: View {
    let comparison: SafeEngagementComparisonPreview

    private var option: SafeEngagementOption { comparison.option }
    private var isFocused: Bool { comparison.isFocused }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Text(isFocused ? "当前" : option.exposure.riskLevel.shortTitle)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minWidth: 38)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(badgeColor.opacity(0.82), in: Capsule())

                Text("q\(option.route.destination.q),r\(option.route.destination.r)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("消耗 \(option.route.totalCost)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
            }

            Text(comparisonText)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(detailText)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(
            (isFocused ? Color.yellow.opacity(0.12) : BattlefieldTheme.fieldGlass.opacity(0.40)),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
        )
    }

    private var comparisonText: String {
        "\(comparison.damageDeltaText)，\(comparison.riskDeltaText)，\(comparison.movementDeltaText)，\(comparison.routeThreatDeltaText)，\(comparison.controlZoneDeltaText)"
    }

    private var detailText: String {
        let penaltyText = option.route.controlZonePenalty > 0 ? "，控制区 +\(option.route.controlZonePenalty)" : ""
        let sources = option.exposure.sources.prefix(2).map(\.sourceName).joined(separator: "、")
        let sourceText = sources.isEmpty ? "无主要敌火" : "敌火 \(sources)"
        return "\(option.exposure.riskLevel.title)，潜在承伤 \(option.exposure.totalPotentialDamage)，预计剩余 \(option.exposure.projectedHPAfterExposure)\(penaltyText)，\(sourceText)"
    }

    private var badgeColor: Color {
        isFocused ? .yellow : option.exposure.riskLevel.accentColor
    }

    private var borderColor: Color {
        isFocused ? Color.yellow.opacity(0.66) : option.exposure.riskLevel.accentColor.opacity(0.22)
    }
}

private struct TacticalCommandPanel: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        let commands = TacticalCommand.allCases.filter { $0.canBeUsed(by: unit.kind) }

        if !commands.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(commands) { command in
                    TacticalCommandGroup(unit: unit, command: command)
                }
            }
        }
    }
}

private struct TacticalCommandGroup: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit
    let command: TacticalCommand

    var body: some View {
        let targets = game.tacticalCommandTargets(for: unit, command: command)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(command.title, systemImage: command.systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(command.accentColor)
                Spacer()
                Text("指令 \(command.commandCost)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(game.commandPoints(for: unit.faction) >= command.commandCost ? .white.opacity(0.66) : .red)
            }

            Text(command.detail)
                .font(.caption.weight(.medium))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.8)

            if targets.isEmpty {
                Text(unit.hasAttacked ? "本回合已完成攻击，无法执行\(command.title)。" : "射程 \(command.range) 内没有可执行目标。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(9)
                    .background(BattlefieldTheme.fieldGlass.opacity(0.36), in: RoundedRectangle(cornerRadius: 7))
            } else {
                VStack(spacing: 7) {
                    ForEach(targets) { target in
                        TacticalCommandTargetButton(command: command, caster: unit, target: target)
                    }
                }
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    command.accentColor.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(command.accentColor.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct TacticalCommandTargetButton: View {
    @EnvironmentObject private var game: GameState
    let command: TacticalCommand
    let caster: BattleUnit
    let target: BattleUnit

    var body: some View {
        let preview = game.tacticalCommandPreview(command: command, caster: caster, target: target)

        Button {
            game.useTacticalCommand(command, casterID: caster.id, targetID: target.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 9) {
                    UnitShapeBadge(
                        kind: target.kind,
                        faction: target.faction,
                        hasCommander: target.commander != nil,
                        rank: target.rank,
                        supplyState: game.supplyState(for: target),
                        tacticalStatus: target.tacticalStatus,
                        width: 42,
                        height: 26
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(target.name)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(preview?.outcomeText ?? "无法预览")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer(minLength: 6)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(preview.map { "-\($0.damage)" } ?? "--")
                            .font(.caption.weight(.black))
                            .foregroundStyle(command.accentColor)
                        Text("无反击")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(BattlefieldTheme.fieldGlass.opacity(0.42), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(command.accentColor.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(preview == nil || game.commandPoints(for: caster.faction) < command.commandCost || game.winner != nil)
        .accessibilityLabel("使用\(command.title)攻击\(target.name)")
    }
}

private struct SupplyPanel: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        let state = game.supplyState(for: unit)
        let lineLength = max(0, game.supplyLineTiles(for: unit).count - 1)
        let accent = state == .supplied ? Color.green : Color.red

        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(state.title, systemImage: state == .supplied ? "fuelpump.fill" : "exclamationmark.octagon.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 6)
                Text(state == .supplied ? "\(lineLength) 格补给线" : "被切断")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if state == .supplied {
                Text("可从己方据点获得整补与完整战力；驻守己方据点时下回合开始自动恢复耐久。地图绿色格显示当前补给通道。")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.ink.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
            } else {
                Text("攻击降至 \(state.attackMultiplierPercent)%，移动 -\(state.movementPenalty)，下回合开始损失 \(state.attritionDamage) 耐久。夺回据点或清除阻断敌军可恢复。")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.ink.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    accent.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct MoralePanel: View {
    let unit: BattleUnit

    var body: some View {
        let state = unit.moraleState
        let movementText = state.movementModifier == 0 ? "移动不变" : "移动 \(state.movementModifier > 0 ? "+" : "")\(state.movementModifier)"

        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(state.title, systemImage: "flag.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(state.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 6)
                Text("\(unit.morale)/100")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            ProgressView(value: Double(unit.morale), total: 100)
                .tint(state.accentColor)

            Text("攻击 \(state.attackMultiplierPercent)%，\(movementText)。攻击奏效与击毁会提振士气，受击、反击和断补给会压低士气。")
                .font(.caption2.weight(.medium))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    state.accentColor.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(state.accentColor.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct ExperiencePanel: View {
    let unit: BattleUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("\(unit.rank.title) \(unit.rank.insignia)", systemImage: "chevron.up.square.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 6)
                Text("\(unit.experience) XP")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if let nextRank = unit.rank.nextRank {
                let currentFloor = unit.rank.minimumExperience
                let needed = nextRank.minimumExperience - currentFloor
                let progress = max(0, unit.experience - currentFloor)

                ProgressView(value: Double(progress), total: Double(needed))
                    .tint(.yellow)
                Text("距\(nextRank.title)还需 \(max(0, nextRank.minimumExperience - unit.experience)) XP，晋升后攻击 +\(nextRank.attackBonus)，耐久上限 +\(nextRank.hpBonus)。")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.ink.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
            } else {
                ProgressView(value: 1)
                    .tint(.yellow)
                Text("王牌部队已达到最高军衔。")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.ink.opacity(0.74))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct StatRows: View {
    let unit: BattleUnit

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(unit.hp), total: Double(unit.maxHP)) {
                HStack {
                    Text("耐久")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 6)
                    Text("\(unit.hp)/\(unit.maxHP)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .monospacedDigit()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
            }
            .tint(unit.hpRatio > 0.45 ? .green : .red)

            HStack(spacing: 8) {
                StatBox(icon: "bolt.fill", title: "攻击", value: "\(unit.attack)")
                StatBox(icon: "arrow.up.left.and.arrow.down.right", title: "移动", value: "\(unit.movement)")
                StatBox(icon: "scope", title: "射程", value: "\(unit.range)")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BattlefieldTheme.commandDeckDeep.opacity(0.40))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.hairline, lineWidth: 1)
                )
        )
    }
}

private struct StatBox: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(BattlefieldTheme.mutedInk)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(BattlefieldTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(BattlefieldTheme.fieldGlass.opacity(0.42), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        )
    }
}

private struct ActionSummary: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        HStack(spacing: 8) {
            ActionBadge(
                icon: "point.topleft.down.curvedto.point.bottomright.up",
                title: "可移动",
                value: "\(game.reachableTiles(for: unit).count)"
            )
            ActionBadge(
                icon: "target",
                title: "可攻击",
                value: "\(game.attackableTiles(for: unit).count)"
            )
            ActionBadge(
                icon: unit.isEntrenched ? "shield.lefthalf.filled" : (unit.hasAttacked ? "checkmark.seal.fill" : "circle.dotted"),
                title: "状态",
                value: unit.actionStateText
            )
        }
    }
}

private struct ActionBadge: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(BattlefieldTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(BattlefieldTheme.fieldGlass.opacity(0.42), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        )
    }
}

private struct FocusedCommandPreviewPanel: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        if let preview = game.focusedCommandPreview,
           game.selectedUnit != nil {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: MapCommandPreviewChrome.iconName(for: preview))
                        .font(.caption.weight(.bold))
                        .frame(width: 16)
                    Text(MapCommandPreviewChrome.panelTitle(for: preview))
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Spacer(minLength: 8)
                    Text(preview.isExecutable ? "右键执行" : "左键查看")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(preview.isExecutable ? .white : .white.opacity(0.58))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(preview.isExecutable ? MapCommandPreviewChrome.accentColor(for: preview).opacity(0.72) : Color.white.opacity(0.08), in: Capsule())
                }
                .foregroundStyle(MapCommandPreviewChrome.accentColor(for: preview))

                Text(panelDetail(for: preview))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(9)
            .background(MapCommandPreviewChrome.accentColor(for: preview).opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(MapCommandPreviewChrome.accentColor(for: preview).opacity(0.24), lineWidth: 1)
            )
        }
    }

    private func panelDetail(for preview: MapCommandPreview) -> String {
        let threatenedSteps = game.focusedRouteStepPreviews.filter(\.isThreatened)
        switch preview {
        case let .inspectTerrain(terrainName):
            return "当前焦点为\(terrainName)，选择部队后会显示移动或攻击预览。"
        case let .selectedUnit(unitName):
            return "\(unitName) 已选中。左键聚焦目标，右键在可执行格移动或攻击。"
        case let .selectUnit(unitName, kind):
            return "左键可切换选择 \(unitName)（\(kind.title)）。"
        case let .move(unitName, terrainName, route):
            return "右键命令 \(unitName) 进入\(terrainName)，\(MapCommandPreviewChrome.routeSummaryDetailed(route: route, threatenedSteps: threatenedSteps, fireExposure: game.focusedFireExposurePreview))\(MapCommandPreviewChrome.postMoveAttackDetailed(canAttack: game.selectedUnit?.canAttack ?? false, previews: game.focusedPostMoveAttackPreviews))"
        case let .approachAttack(unitName, defenderName, route):
            return "右键命令 \(unitName) 移动到 q\(route.destination.q),r\(route.destination.r) 接近 \(defenderName)，\(MapCommandPreviewChrome.routeSummaryDetailed(route: route, threatenedSteps: threatenedSteps, fireExposure: game.focusedFireExposurePreview))移动后目标进入射程，可继续右键攻击，不会自动攻击。\(MapCommandPreviewChrome.safeEngagementDetailed(currentRoute: route, comparison: game.focusedSafeEngagementComparisons.first))"
        case let .attack(attackerName, defenderName, damage, counterDamage, defenderHPAfterAttack, willDestroy):
            return MapCommandPreviewChrome.attackDetailDetailed(
                attackerName: attackerName,
                defenderName: defenderName,
                damage: damage,
                counterDamage: counterDamage,
                defenderHPAfterAttack: defenderHPAfterAttack,
                willDestroy: willDestroy
            )
        case let .friendlyOccupied(unitName):
            return "\(unitName) 占据该格，右键不会移动当前选中部队。"
        case let .enemyOutOfRange(defenderName, distance, range):
            return "\(defenderName) 距离 \(distance)，当前射程 \(range)，右键不会攻击。\(MapCommandPreviewChrome.attackPositionHint(routes: game.focusedAttackPositionRoutes))"
        case let .enemyUnavailable(defenderName, distance, range):
            return "\(defenderName) 距离 \(distance)，射程 \(range)，当前单位本回合已无法攻击。"
        case let .unreachable(unitName, terrainName):
            return "\(unitName) 本回合无法进入该\(terrainName)格，右键不会执行移动。"
        }
    }
}

private struct AttackTargetsView: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        let targets = game.attackableUnits(for: unit)

        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Label("攻击目标", systemImage: "target")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.brass)

                Spacer(minLength: 8)

                Text(targets.isEmpty ? "无" : "\(targets.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(targets.isEmpty ? BattlefieldTheme.mutedInk : .black.opacity(0.82))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        targets.isEmpty ? Color.white.opacity(0.08) : BattlefieldTheme.brass.opacity(0.88),
                        in: Capsule()
                    )
            }

            if targets.isEmpty {
                Label(unit.hasAttacked ? "本回合已完成攻击。" : "当前射程内没有敌军。", systemImage: unit.hasAttacked ? "checkmark.seal.fill" : "scope")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(BattlefieldTheme.hairline, lineWidth: 1)
                    )
            } else {
                VStack(spacing: 7) {
                    ForEach(targets) { target in
                        AttackTargetButton(attacker: unit, target: target)
                    }
                }
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.10),
                    BattlefieldTheme.commandDeckDeep.opacity(0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct AttackTargetButton: View {
    @EnvironmentObject private var game: GameState
    let attacker: BattleUnit
    let target: BattleUnit

    var body: some View {
        let preview = game.combatPreview(attacker: attacker, defender: target)
        let counterDamage = preview?.counterDamage ?? 0
        let isFocused = game.focusedUnit?.id == target.id

        Button {
            game.handleTap(on: target.position)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 9) {
                    UnitShapeBadge(
                        kind: target.kind,
                        faction: target.faction,
                        hasCommander: target.commander != nil,
                        rank: target.rank,
                        tacticalStatus: target.tacticalStatus,
                        width: 46,
                        height: 28
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(target.name)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(BattlefieldTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            if preview?.willDestroyDefender == true {
                                Text("KILL")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.82), in: Capsule())
                            }
                        }

                        HStack(spacing: 6) {
                            MiniHealthBar(ratio: target.hpRatio)
                                .frame(width: 56, height: 6)
                            Text("\(target.hp)/\(target.maxHP)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(BattlefieldTheme.mutedInk)
                                .monospacedDigit()
                        }
                    }

                    Spacer(minLength: 6)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(preview.map { "-\($0.damage)" } ?? "--")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.orange)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(counterDamage > 0 ? "反击 -\(counterDamage)" : "无反击")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(counterDamage > 0 ? Color.red.opacity(0.90) : BattlefieldTheme.mutedInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }

                HStack(spacing: 6) {
                    if let preview {
                        BattleIntelPill(text: preview.matchupTitle, color: preview.matchupAccentColor)
                        BattleIntelPill(text: preview.terrainTitle, color: preview.terrainAccentColor)
                        if preview.supportUnitCount > 0 {
                            BattleIntelPill(text: preview.supportTitle, color: .green)
                        }
                        if preview.defenderIsEntrenched {
                            BattleIntelPill(text: preview.defenseTitle, color: .cyan)
                        }
                    }

                    Spacer(minLength: 6)

                    Text(isFocused ? "当前目标" : "点选预览")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(isFocused ? .black.opacity(0.82) : BattlefieldTheme.mutedInk)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isFocused ? BattlefieldTheme.brass.opacity(0.92) : Color.white.opacity(0.07), in: Capsule())
                }
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isFocused ? 0.15 : 0.08),
                        Color.black.opacity(isFocused ? 0.12 : 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? BattlefieldTheme.brass.opacity(0.85) : Color.orange.opacity(0.18), lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: .black.opacity(isFocused ? 0.22 : 0.10), radius: isFocused ? 10 : 5, x: 0, y: isFocused ? 5 : 2)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(preview: preview, counterDamage: counterDamage, isFocused: isFocused))
        .accessibilityHint("聚焦该敌军并显示攻击预览，不直接执行攻击")
    }

    private func accessibilityLabel(preview: CombatPreview?, counterDamage: Int, isFocused: Bool) -> String {
        let focusText = isFocused ? "当前攻击预览目标，" : ""
        guard let preview else {
            return "\(focusText)\(target.name)，\(target.faction.title)\(target.kind.title)，耐久 \(target.hp)/\(target.maxHP)"
        }
        let outcome = preview.willDestroyDefender ? "预计击毁" : "目标剩余 \(preview.defenderHPAfterAttack)"
        let counter = counterDamage > 0 ? "反击 \(counterDamage)" : "无反击"
        return "\(focusText)\(target.name)，造成 \(preview.damage) 伤害，\(outcome)，\(counter)"
    }
}

private struct BattleIntelPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private struct ThreatSummary: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        let threats = game.threateningEnemies(against: unit)

        if !threats.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                Label("敌方威胁", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 6) {
                    ForEach(threats.prefix(3)) { enemy in
                        UnitShapeBadge(
                            kind: enemy.kind,
                            faction: enemy.faction,
                            hasCommander: enemy.commander != nil,
                            rank: enemy.rank,
                            tacticalStatus: enemy.tacticalStatus,
                            width: 38,
                            height: 22
                        )
                            .accessibilityLabel("\(enemy.name) 可攻击当前单位")
                    }

                    Text(threats.count == 1 ? "1 支敌军覆盖当前位置" : "\(threats.count) 支敌军覆盖当前位置")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BattlefieldTheme.ink.opacity(0.78))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.14),
                        BattlefieldTheme.commandDeckDeep.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.28), lineWidth: 1)
            )
        }
    }
}

private struct CombatForecastView: View {
    let preview: CombatPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("战斗预测", systemImage: "scope")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.brass)

                Spacer(minLength: 8)

                Text(resultForecastTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(resultForecastColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(resultForecastColor.opacity(0.13), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(preview.attackerName) -> \(preview.defenderName)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("预计攻后我方 \(preview.attackerHPAfterCounter) 耐久，目标 \(preview.defenderHPAfterAttack) 耐久。")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                ForecastMetric(title: "伤害", value: "-\(preview.damage)", color: .orange)
                ForecastMetric(title: "目标剩余", value: "\(preview.defenderHPAfterAttack)", color: preview.willDestroyDefender ? .red : .white)
                ForecastMetric(title: "反击", value: preview.counterDamage > 0 ? "-\(preview.counterDamage)" : "无", color: preview.counterDamage > 0 ? .red : .white)
            }

            VStack(alignment: .leading, spacing: 6) {
                CombatForecastFactorLine(icon: preview.matchupIcon, title: preview.matchupTitle, detail: preview.matchupDetail, color: preview.matchupAccentColor)
                CombatForecastFactorLine(icon: preview.terrainIcon, title: preview.terrainTitle, detail: preview.terrainDetail, color: preview.terrainAccentColor)

                if preview.commanderSupportName != nil {
                    CombatForecastFactorLine(icon: "star.bubble.fill", title: preview.commanderSupportTitle, detail: preview.commanderSupportDetail, color: .yellow)
                }

                if preview.supportUnitCount > 0 {
                    CombatForecastFactorLine(icon: "point.3.connected.trianglepath.dotted", title: preview.supportTitle, detail: preview.supportDetail, color: .green)
                }

                if preview.defenderIsEntrenched {
                    CombatForecastFactorLine(icon: "shield.lefthalf.filled", title: preview.defenseTitle, detail: preview.defenseDetail, color: .cyan)
                }
            }

            Label(forecastSummaryText, systemImage: preview.willLoseAttacker ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(resultForecastColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.13),
                    BattlefieldTheme.commandDeckDeep.opacity(0.52)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(resultForecastColor.opacity(0.30), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 5)
    }

    private var resultForecastTitle: String {
        if preview.willDestroyDefender { return "预计击毁" }
        if preview.willLoseAttacker { return "反击危险" }
        return preview.counterDamage > 0 ? "交火" : "压制"
    }

    private var resultForecastColor: Color {
        if preview.willDestroyDefender { return .green }
        if preview.willLoseAttacker { return .red }
        if preview.counterDamage > 0 { return .orange }
        return BattlefieldTheme.brass
    }

    private var forecastSummaryText: String {
        if preview.willDestroyDefender { return "预计可击毁目标，攻击后保留 \(preview.attackerHPAfterCounter) 耐久。" }
        if preview.willLoseAttacker { return "攻击后有被反击击毁风险。" }
        return "\(preview.attackerName) 攻击后预计保留 \(preview.attackerHPAfterCounter) 耐久。"
    }
}

private struct CombatForecastFactorLine: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .frame(width: 15)

            Text("\(title)：\(detail)")
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct ForecastMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct TileDetail: View {
    @EnvironmentObject private var game: GameState

    let tile: TerrainTile
    let unit: BattleUnit?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(tile.terrain.title, systemImage: tile.isObjective ? "star.fill" : "hexagon.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tile.isObjective ? .yellow : BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Spacer(minLength: 6)
                Text("q\(tile.coordinate.q), r\(tile.coordinate.r)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            HStack(spacing: 8) {
                TileMetric(title: unit == nil ? "基础移动" : "\(unit?.kind.title ?? "")移动", value: "\(unit.map { tile.terrain.movementCost(for: $0.kind) } ?? tile.terrain.movementCost)")
                TileMetric(title: "防御", value: "+\(tile.terrain.defenseBonus)")
                TileMetric(title: "控制", value: tile.owner?.title ?? "中立")
            }

            if let unit {
                let attackMultiplier = tile.terrain.attackMultiplierPercent(for: unit.kind)
                Text("\(unit.kind.title)进入该地形消耗 \(tile.terrain.movementCost(for: unit.kind)) 移动力，攻击该格目标时攻势为 \(attackMultiplier)%。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.ink.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
            }

            if let selected = game.selectedUnit,
               selected.position != tile.coordinate,
               let route = game.movementRoute(for: selected, to: tile.coordinate) {
                Text(route.controlZonePenalty > 0
                     ? "\(selected.kind.title)到达该格总消耗 \(route.totalCost) 移动力，路线 \(route.stepCount) 格，其中敌方控制区 +\(route.controlZonePenalty)。"
                     : "\(selected.kind.title)到达该格总消耗 \(route.totalCost) 移动力，路线 \(route.stepCount) 格。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(route.controlZonePenalty > 0 ? .red.opacity(0.82) : BattlefieldTheme.ink.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
            }

            if let objectiveName = tile.objectiveName {
                Label(objectiveName, systemImage: "flag.checkered")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow.opacity(0.92))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            if let unit {
                Text("\(unit.name) 占据此格，\(unit.faction.title) \(unit.kind.title)，\(unit.actionStateText)。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.ink.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BattlefieldTheme.commandDeckDeep.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.hairline, lineWidth: 1)
                )
        )
    }
}

private struct TileMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct TerrainKey: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("地形")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.66))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                ForEach(TerrainKind.allCases) { terrain in
                    LegendItem(color: terrain.mapColor, label: terrain.title, symbol: terrain.mapSymbol)
                }
            }
        }
    }
}

struct MapLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.brass)
                Text("图例")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                Text("操作 · 风险 · 态势 · 兵种")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                Spacer(minLength: 0)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    LegendItem(color: .white.opacity(0.85), label: "左键选择")
                    LegendItem(color: .orange.opacity(0.94), label: "右键执行")
                    LegendItem(color: .yellow, label: "选中")
                    LegendItem(color: .cyan, label: "步序/消耗", symbol: "1")
                    LegendItem(color: .red.opacity(0.82), label: "路线风险", symbol: "!")
                    LegendItem(color: FireRiskLevel.high.accentColor, label: "火力风险", symbol: "HIGH")
                    LegendItem(color: .red, label: "攻击预估", symbol: "A")
                    LegendItem(color: .orange.opacity(0.86), label: "移动后目标", symbol: "NX")
                    LegendItem(color: .orange.opacity(0.76), label: "攻击位", symbol: "POS")
                    LegendItem(color: .red.opacity(0.78), label: "敌火覆盖", symbol: "TH")
                    LegendItem(color: .pink.opacity(0.86), label: "敌方意图", symbol: "INT")
                    LegendItem(color: .mint.opacity(0.9), label: "反制聚焦", symbol: "ACT")
                    LegendItem(color: .pink.opacity(0.9), label: "据点压力", symbol: "PRS")
                    LegendItem(color: .orange.opacity(0.9), label: "态势响应", symbol: "RSP")
                    LegendItem(color: .indigo.opacity(0.88), label: "AI复盘", symbol: "AI")
                    LegendItem(color: .black.opacity(0.62), label: "同格折叠", symbol: "+N")
                    LegendItem(color: .green.opacity(0.9), label: "补给线")
                    LegendItem(color: .red.opacity(0.92), label: "断补给", symbol: "CUT")
                    LegendItem(color: .white.opacity(0.85), label: "焦点")
                    LegendItem(color: Faction.allies.accentColor, label: "盟军")
                    LegendItem(color: Faction.axis.accentColor, label: "轴心国")
                    LegendItem(color: .purple.opacity(0.92), label: "压制", symbol: "PIN")
                    UnitLegendItem(kind: .infantry, faction: .allies)
                    UnitLegendItem(kind: .tank, faction: .allies)
                    UnitLegendItem(kind: .artillery, faction: .axis)
                    UnitLegendItem(kind: .recon, faction: .axis)
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
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

private struct LegendItem: View {
    let color: Color
    let label: String
    var symbol: String?

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                if let symbol {
                    Text(symbol)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .frame(width: 14, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(BattlefieldTheme.fieldGlass.opacity(0.48), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        )
    }
}

private struct UnitLegendItem: View {
    let kind: UnitKind
    let faction: Faction

    var body: some View {
        HStack(spacing: 5) {
            UnitShapeBadge(kind: kind, faction: faction, rank: .green, width: 34, height: 18)
            Text(kind.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(BattlefieldTheme.fieldGlass.opacity(0.48), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        )
    }
}

private struct CommanderView: View {
    let commander: Commander

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(commander.name, systemImage: "person.crop.square.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 6)
                Text("评分 \(commander.rating)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.90), in: Capsule())
            }
            Text("\(commander.nation) · \(commander.rank)")
                .font(.caption.weight(.medium))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(commander.trait)
                .font(.caption.weight(.medium))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.14),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct CombatResultSummaryView: View {
    let summary: CombatResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("战斗结果", systemImage: resultIcon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(resultColor)

                Spacer(minLength: 8)

                Text(resultTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(resultColor.opacity(0.90), in: Capsule())
            }

            Text(resultNarrative)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 7) {
                CombatantResultLine(title: "攻击", snapshot: summary.attacker, tint: .orange)
                CombatantResultLine(title: "防守", snapshot: summary.defender, tint: summary.didDestroyDefender ? .red : .cyan)
            }

            HStack(spacing: 7) {
                CombatResultMetric(title: "伤害", value: "-\(summary.damage)", color: .orange)
                CombatResultMetric(title: "反击", value: summary.counterDamage > 0 ? "-\(summary.counterDamage)" : "无", color: summary.counterDamage > 0 ? .red : .white.opacity(0.76))
                CombatResultMetric(title: "夹击", value: summary.hasFlankingSupport ? "+\(summary.supportDamageBonusPercent)%" : "无", color: summary.hasFlankingSupport ? .green : .white.opacity(0.76))
            }

            let details = detailRows
            if !details.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(details.enumerated()), id: \.offset) { _, row in
                        BattleResultDetailLine(row: row)
                    }
                }
            }
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    resultColor.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(resultColor.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.17), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }

    private var resultTitle: String {
        if summary.didDestroyDefender {
            return summary.didTriggerManeuverPursuit ? "击毁 · 追击" : "击毁"
        }
        if summary.hasCounterAttack {
            return "交火"
        }
        return "压制"
    }

    private var resultIcon: String {
        if summary.didDestroyDefender { return "burst.fill" }
        if summary.hasCounterAttack { return "scope" }
        return "shield.lefthalf.filled"
    }

    private var resultColor: Color {
        if summary.didDestroyDefender { return .red }
        if summary.hasCounterAttack { return .orange }
        return .yellow
    }

    private var resultNarrative: String {
        let defenderState = summary.didDestroyDefender ? "击毁 \(summary.defender.name)" : "\(summary.defender.name) 剩余 \(summary.defender.endingHP) 耐久"
        let counterState = summary.hasCounterAttack ? "，承受反击 \(summary.counterDamage) 伤害" : "，未遭反击"
        let pursuitState = summary.didTriggerManeuverPursuit ? "，触发机动追击" : ""
        return "\(summary.attacker.name) 造成 \(summary.damage) 伤害，\(defenderState)\(counterState)\(pursuitState)。"
    }

    private var detailRows: [CombatResultDetailRow] {
        var rows: [CombatResultDetailRow] = []

        if summary.didDestroyDefender {
            rows.append(.init(icon: "burst.fill", text: "\(summary.defender.name) 被击毁", color: .red))
        }

        if summary.didDestroyAttacker {
            rows.append(.init(icon: "exclamationmark.triangle.fill", text: "\(summary.attacker.name) 被反击击毁", color: .red))
        }

        if summary.didTriggerManeuverPursuit {
            rows.append(.init(icon: "arrow.forward.circle.fill", text: "\(summary.attacker.name) 可继续机动", color: .orange))
        }

        if summary.didConsumeDefenderEntrenchment {
            rows.append(.init(icon: "shield.slash.fill", text: "防御姿态已被消耗", color: .cyan))
        }

        if summary.attacker.experienceDelta > 0 {
            let promotion = summary.attacker.didPromote ? "，晋升为\(summary.attacker.endingRank.title)" : ""
            rows.append(.init(icon: "chevron.up.circle.fill", text: "\(summary.attacker.name) 经验 +\(summary.attacker.experienceDelta)\(promotion)", color: .yellow))
        }

        if summary.defender.experienceDelta > 0 {
            let promotion = summary.defender.didPromote ? "，晋升为\(summary.defender.endingRank.title)" : ""
            rows.append(.init(icon: "arrow.uturn.backward.circle.fill", text: "\(summary.defender.name) 反击经验 +\(summary.defender.experienceDelta)\(promotion)", color: .yellow))
        }

        if summary.attacker.moraleDelta != 0 {
            rows.append(.init(icon: "flag.fill", text: "\(summary.attacker.name) 士气 \(signed(summary.attacker.moraleDelta))", color: summary.attacker.moraleDelta > 0 ? .green : .red))
        }

        if summary.defender.moraleDelta != 0 {
            rows.append(.init(icon: "flag.checkered", text: "\(summary.defender.name) 士气 \(signed(summary.defender.moraleDelta))", color: summary.defender.moraleDelta > 0 ? .green : .red))
        }

        return rows
    }

    private func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }
}

private struct CombatantResultLine: View {
    let title: String
    let snapshot: CombatantResultSnapshot
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.black.opacity(0.82))
                .frame(width: 36, height: 24)
                .background(tint.opacity(0.88), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(snapshot.faction.title) · \(snapshot.kind.title) · \(snapshot.endingRank.title)")
                    .font(.caption2)
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(snapshot.startingHP) -> \(snapshot.endingHP)")
                    .font(.caption.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(snapshot.hpDelta < 0 ? .orange : BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(hpDeltaText)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(snapshot.hpDelta < 0 ? .red.opacity(0.86) : BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    private var hpDeltaText: String {
        snapshot.hpDelta < 0 ? "\(snapshot.hpDelta)" : "+\(snapshot.hpDelta)"
    }
}

private struct BattleResultDetailLine: View {
    let row: CombatResultDetailRow

    var body: some View {
        Label(row.text, systemImage: row.icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(row.color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(row.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct CombatResultMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct CombatResultDetailRow {
    let icon: String
    let text: String
    let color: Color
}

private struct TacticalCommandResultSummaryView: View {
    let summary: TacticalCommandResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label(summary.command.title, systemImage: summary.command.systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(summary.command.accentColor)

                Spacer(minLength: 8)

                Text(resultBadgeTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(summary.command.accentColor.opacity(0.90), in: Capsule())
            }

            Text(resultNarrative)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 7) {
                CombatantResultLine(title: "施放", snapshot: summary.caster, tint: summary.command.accentColor)
                CombatantResultLine(title: "目标", snapshot: summary.target, tint: summary.didDestroyTarget ? .red : .cyan)
            }

            HStack(spacing: 7) {
                CombatResultMetric(title: "伤害", value: "-\(summary.damage)", color: summary.command.accentColor)
                CombatResultMetric(title: "指令", value: "-\(summary.commandCost)", color: .yellow)
                CombatResultMetric(title: "反击", value: summary.didAvoidCounterAttack ? "无" : "--", color: .white.opacity(0.76))
            }

            let details = detailRows
            if !details.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(details.enumerated()), id: \.offset) { _, row in
                        BattleResultDetailLine(row: row)
                    }
                }
            }
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    summary.command.accentColor.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(summary.command.accentColor.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.17), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }

    private var resultBadgeTitle: String {
        if summary.didDestroyTarget {
            return "\(summary.command.shortTitle) · 击毁"
        }
        if summary.didApplyStatusEffect {
            return "\(summary.command.shortTitle) · 压制"
        }
        return summary.command.shortTitle
    }

    private var resultNarrative: String {
        let targetState = summary.didDestroyTarget ? "击毁 \(summary.target.name)" : "\(summary.target.name) 剩余 \(summary.target.endingHP) 耐久"
        let statusState = summary.didApplyStatusEffect ? "，施加 \(summary.statusEffect.title)" : ""
        return "\(summary.caster.name) 施放 \(summary.command.title)，造成 \(summary.damage) 伤害，\(targetState)\(statusState)。"
    }

    private var detailRows: [CombatResultDetailRow] {
        var rows: [CombatResultDetailRow] = []

        if summary.didDestroyTarget {
            rows.append(.init(icon: "burst.fill", text: "\(summary.target.name) 被击毁", color: .red))
        }

        if summary.didApplyStatusEffect {
            rows.append(.init(icon: "scope", text: "\(summary.target.name) \(summary.statusEffect.title)，士气 -\(summary.moraleDamage)", color: summary.command.accentColor))
        }

        if summary.didConsumeTargetEntrenchment {
            rows.append(.init(icon: "shield.slash.fill", text: "防御姿态已被消耗", color: .cyan))
        }

        if summary.caster.experienceDelta > 0 {
            let promotion = summary.caster.didPromote ? "，晋升为\(summary.caster.endingRank.title)" : ""
            rows.append(.init(icon: "chevron.up.circle.fill", text: "\(summary.caster.name) 经验 +\(summary.caster.experienceDelta)\(promotion)", color: .yellow))
        }

        if summary.target.moraleDelta != 0 {
            rows.append(.init(icon: "flag.checkered", text: "\(summary.target.name) 士气 \(signed(summary.target.moraleDelta))", color: summary.target.moraleDelta > 0 ? .green : .red))
        }

        return rows
    }

    private func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }
}

private struct ObjectiveCaptureResultSummaryView: View {
    let summary: ObjectiveCaptureResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("据点占领", systemImage: "flag.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.yellow)

                Spacer(minLength: 8)

                Text(summary.actionTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.90), in: Capsule())
            }

            Text("\(summary.capturingUnitName) 占领 \(summary.objectiveName)，据点转由 \(summary.newOwner.title) 控制。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.objectiveName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(summary.capturingUnitName) · \(summary.capturingUnitKind.title) · q\(summary.coordinate.q),r\(summary.coordinate.r)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.yellow.opacity(0.18), lineWidth: 1)
            )

            HStack(spacing: 7) {
                CombatResultMetric(title: "指令", value: "+\(summary.commandPointReward)", color: .yellow)
                CombatResultMetric(title: "士气", value: "+\(summary.moraleReward)", color: .green)
                CombatResultMetric(title: "经验", value: "+\(summary.experienceReward)", color: .cyan)
            }

            VStack(alignment: .leading, spacing: 5) {
                BattleResultDetailLine(row: .init(icon: "arrow.left.arrow.right", text: summary.ownerTransitionText, color: summary.newOwner.accentColor))
                BattleResultDetailLine(row: .init(icon: "chart.bar.fill", text: "据点进度 \(summary.progressText)，轴心 \(summary.axisScoreAfterCapture)/\(summary.totalObjectiveCount)", color: .white.opacity(0.82)))
            }
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.17), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }
}

private struct DeploymentResultSummaryView: View {
    let summary: DeploymentResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("增援部署", systemImage: "plus.square.on.square.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.cyan)

                Spacer(minLength: 8)

                Text(summary.unitKind.code)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.90), in: Capsule())
            }

            Text("在 \(summary.sourceObjectiveName) 部署 \(summary.unitName)，消耗 \(summary.commandCost) 指令点。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.unitName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(summary.faction.title) · \(summary.unitKind.title) · q\(summary.coordinate.q),r\(summary.coordinate.r)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
            )

            HStack(spacing: 7) {
                CombatResultMetric(title: "指令", value: "-\(summary.commandCost)", color: .yellow)
                CombatResultMetric(title: "剩余", value: "\(summary.commandPointsAfterDeployment)", color: .white.opacity(0.82))
                CombatResultMetric(title: "耐久", value: "\(summary.unitKind.baseHP)", color: .green)
            }

            BattleResultDetailLine(row: .init(icon: "flag.fill", text: "来源据点 \(summary.sourceObjectiveName)，新部队本回合已完成部署行动。", color: summary.faction.accentColor))
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.17), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }
}

private struct ReinforcementResultSummaryView: View {
    let summary: ReinforcementResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("整补结果", systemImage: "cross.case.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)

                Spacer(minLength: 8)

                Text("+\(summary.recoveredHP)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.90), in: Capsule())
            }

            Text("\(summary.unitName) 整补恢复 \(summary.recoveredHP) 耐久，指令消耗 \(summary.commandCost)。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.unitName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(summary.faction.title) · \(summary.unitKind.title) · q\(summary.coordinate.q),r\(summary.coordinate.r)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.green.opacity(0.18), lineWidth: 1)
            )

            HStack(spacing: 7) {
                CombatResultMetric(title: "耐久", value: "\(summary.startingHP)->\(summary.endingHP)", color: .green)
                CombatResultMetric(title: "指令", value: "-\(summary.commandCost)", color: .yellow)
                CombatResultMetric(title: "剩余", value: "\(summary.commandPointsAfterReinforcement)", color: .white.opacity(0.82))
            }

            BattleResultDetailLine(row: .init(icon: "checkmark.seal.fill", text: "整补后本回合行动已消耗，战术状态与防御姿态重置。", color: .green.opacity(0.90)))
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    Color.green.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.17), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }
}

private struct EnemyThreatIntentPanel: View {
    let previews: [EnemyThreatIntentPreview]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("敌方意图", systemImage: "eye.trianglebadge.exclamationmark.fill")
                    .font(.subheadline.weight(.bold))

                Spacer(minLength: 8)

                Text("\(min(previews.count, 3))")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.pink.opacity(0.90), in: Capsule())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(.pink)

            ForEach(Array(previews.prefix(3))) { preview in
                EnemyThreatIntentRow(preview: preview)
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.pink.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

private struct EnemyThreatIntentRow: View {
    let preview: EnemyThreatIntentPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(preview.kind.shortTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.84), in: RoundedRectangle(cornerRadius: 5))

                VStack(alignment: .leading, spacing: 2) {
                    Text(preview.enemyUnitName)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("\(preview.enemyUnitKind.title) -> \(preview.targetName)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 8)

                Text(outcomeText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(outcomeColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 7) {
                CombatResultMetric(title: "距离", value: "\(preview.currentDistance)", color: .white.opacity(0.82))
                CombatResultMetric(title: preview.kind == .objectiveCapture ? "占点" : "伤害", value: effectMetricText, color: outcomeColor)
                CombatResultMetric(title: "路线", value: routeMetricText, color: preview.routeCost == nil ? .cyan : .orange)
            }

            Label(routeDetailText, systemImage: routeIcon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(BattlefieldTheme.fieldGlass.opacity(0.40), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(accentColor.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var accentColor: Color {
        switch preview.kind {
        case .directAttack:
            return .red
        case .approachAttack:
            return .orange
        case .objectiveCapture:
            return .yellow
        }
    }

    private var outcomeColor: Color {
        if preview.willDestroyTarget { return .red }
        if preview.kind == .objectiveCapture { return .yellow }
        return .orange
    }

    private var outcomeText: String {
        switch preview.kind {
        case .objectiveCapture:
            return "占点"
        case .directAttack, .approachAttack:
            return preview.willDestroyTarget ? "击毁" : "-\(preview.projectedDamage)"
        }
    }

    private var effectMetricText: String {
        switch preview.kind {
        case .objectiveCapture:
            return preview.objectiveOwner?.shortTitle ?? "NEU"
        case .directAttack, .approachAttack:
            return "-\(preview.projectedDamage)"
        }
    }

    private var routeMetricText: String {
        guard let routeCost = preview.routeCost else { return "射程" }
        return "\(routeCost)"
    }

    private var routeDetailText: String {
        switch preview.kind {
        case .directAttack:
            return "当前位置可攻击 \(preview.targetName)，目标预计剩余 \(preview.projectedTargetHPAfterDamage ?? 0) 耐久。"
        case .approachAttack:
            let hpText = preview.projectedTargetHPAfterDamage.map { "，目标预计剩余 \($0) 耐久" } ?? ""
            return "先到 \(preview.destinationText)，消耗 \(preview.routeCost ?? 0) 移动力后攻击\(hpText)。"
        case .objectiveCapture:
            return "可推进到 \(preview.destinationText)，夺取 \(preview.targetName)。"
        }
    }

    private var routeIcon: String {
        switch preview.kind {
        case .directAttack:
            return "target"
        case .approachAttack:
            return "scope"
        case .objectiveCapture:
            return "flag.fill"
        }
    }
}

private struct EnemyThreatCountermeasurePanel: View {
    @EnvironmentObject private var game: GameState
    let previews: [EnemyThreatCountermeasurePreview]

    var body: some View {
        let visiblePreviews = Array(previews.prefix(3))
        let comparisonPreviews = game.enemyThreatCountermeasureComparisonPreviews(
            for: visiblePreviews,
            limit: visiblePreviews.count
        )

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("反制建议", systemImage: "shield.lefthalf.filled")
                    .font(.subheadline.weight(.bold))

                Spacer(minLength: 8)

                Text("\(visiblePreviews.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.90), in: Capsule())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(.cyan)

            if let topComparison = comparisonPreviews.first {
                EnemyThreatCountermeasureComparisonHint(preview: topComparison)
            }

            ForEach(visiblePreviews) { preview in
                let isFocused = game.isEnemyThreatCountermeasureFocused(preview)
                Button {
                    game.focusEnemyThreatCountermeasure(preview)
                } label: {
                    EnemyThreatCountermeasureRow(preview: preview, isFocused: isFocused)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: preview, isFocused: isFocused))
                .accessibilityHint("只聚焦该反制建议预览，不会执行移动、攻击或整补")
            }

            if let executionPreview = game.focusedEnemyThreatCountermeasureExecutionPreview {
                EnemyThreatCountermeasureExecutionHint(preview: executionPreview)
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private func accessibilityLabel(
        for preview: EnemyThreatCountermeasurePreview,
        isFocused: Bool
    ) -> String {
        let focused = isFocused ? "，当前预览" : ""
        let routeText = preview.routeCost.map { "，路线消耗 \($0)" } ?? ""
        return "\(preview.kind.title)\(focused)，\(preview.actingUnitName) 对 \(preview.targetName)\(routeText)，对照：\(preview.impactSummary)，排序：\(preview.prioritySummary)，收益：\(preview.benefitSummary)，\(preview.reason)"
    }
}

private struct EnemyThreatCountermeasureExecutionHint: View {
    let preview: EnemyThreatCountermeasureExecutionPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 7) {
                Label("下一步", systemImage: iconName)
                    .font(.caption.weight(.black))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(preview.kind.shortTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(color.opacity(preview.isExecutable ? 0.92 : 0.54), in: Capsule())

                Spacer(minLength: 6)

                Text(preview.isExecutable ? "可执行" : "暂不可用")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(preview.isExecutable ? .black.opacity(0.82) : BattlefieldTheme.mutedInk)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        (preview.isExecutable ? color : Color.white).opacity(preview.isExecutable ? 0.90 : 0.10),
                        in: Capsule()
                    )
            }

            Text(preview.entryTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Label(detailText, systemImage: preview.isExecutable ? "hand.tap.fill" : "exclamationmark.triangle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.8)

            Text(preview.isExecutable ? "请用既有 ATK/MOVE/整补入口真实执行，本卡不会自动行动。" : "当前状态无法通过该入口执行，请先调整单位或目标。")
                .font(.caption2.weight(.medium))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    color.opacity(preview.isExecutable ? 0.14 : 0.08),
                    BattlefieldTheme.commandDeckDeep.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(preview.isExecutable ? 0.40 : 0.24), lineWidth: preview.isExecutable ? 1.5 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("这只是执行入口提示，不会移动、攻击或整补")
    }

    private var detailText: String {
        if let coordinate = preview.coordinate {
            return "\(preview.unitName) -> \(preview.targetName)，q\(coordinate.q),r\(coordinate.r)。\(preview.reason)"
        }
        return "\(preview.unitName) -> \(preview.targetName)。\(preview.reason)"
    }

    private var accessibilityLabel: String {
        "\(preview.actionTitle) 下一步，\(preview.kind.shortTitle)，\(preview.entryTitle)，\(detailText)"
    }

    private var color: Color {
        switch preview.kind {
        case .attack:
            return .red
        case .move:
            return .orange
        case .reinforce:
            return .green
        case .unavailable:
            return .gray
        }
    }

    private var iconName: String {
        switch preview.kind {
        case .attack:
            return "target"
        case .move:
            return "arrow.up.right.circle.fill"
        case .reinforce:
            return "cross.case.fill"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }
}

private struct EnemyThreatCountermeasureExecutionResultSummaryView: View {
    let summary: EnemyThreatCountermeasureExecutionResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("反制回放", systemImage: iconName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)

                Spacer(minLength: 8)

                Text(summary.executionKind.shortTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.90), in: Capsule())
            }

            Text(resultNarrative)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.countermeasureKind.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(locationText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(color.opacity(0.18), lineWidth: 1)
            )

            HStack(spacing: 7) {
                ForEach(Array(summary.comparisons.prefix(3))) { comparison in
                    CombatResultMetric(
                        title: comparison.title,
                        value: comparison.actual,
                        color: metricColor(for: comparison.kind)
                    )
                    .accessibilityLabel("\(comparison.title)，预计\(comparison.expected)，实际\(comparison.actual)，\(comparison.result)")
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                if !summary.expectedSummary.isEmpty {
                    BattleResultDetailLine(row: .init(
                        icon: "arrow.left.arrow.right",
                        text: "预计：\(summary.expectedSummary)",
                        color: .white.opacity(0.78)
                    ))
                }

                BattleResultDetailLine(row: .init(
                    icon: "checkmark.seal.fill",
                    text: "实际：\(summary.actualSummary)",
                    color: color.opacity(0.92)
                ))
            }
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    color.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.17), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("反制回放，\(summary.countermeasureKind.title)，\(locationText)，预计\(summary.expectedSummary)，实际\(summary.actualSummary)")
    }

    private var resultNarrative: String {
        let expected = summary.expectedSummary.isEmpty ? "无预计摘要" : summary.expectedSummary
        return "\(summary.actingUnitName) 执行 \(summary.countermeasureKind.title)，预计 \(expected)，实际 \(summary.actualSummary)。"
    }

    private var locationText: String {
        let coordinateText = summary.coordinate.map { "，q\($0.q),r\($0.r)" } ?? ""
        return "\(summary.actingUnitName) -> \(summary.targetName)，威胁来源 \(summary.threatEnemyUnitName)\(coordinateText)"
    }

    private var color: Color {
        switch summary.countermeasureKind {
        case .firstStrike:
            return .red
        case .withdraw:
            return .cyan
        case .objectiveDefense:
            return .yellow
        case .reinforce:
            return .green
        }
    }

    private var iconName: String {
        switch summary.executionKind {
        case .attack:
            return "target"
        case .move:
            return "arrow.up.right.circle.fill"
        case .reinforce:
            return "cross.case.fill"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    private func metricColor(for kind: EnemyThreatCountermeasureExecutionResultKind) -> Color {
        switch kind {
        case .damage, .enemyHP:
            return .orange
        case .survival, .recovery:
            return .green
        case .objective:
            return .yellow
        case .route:
            return .cyan
        }
    }
}

private struct EnemyThreatCountermeasureFollowUpSummaryView: View {
    @EnvironmentObject private var game: GameState
    let summary: EnemyThreatCountermeasureFollowUpSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Label("敌方回合复核", systemImage: "checkmark.shield.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)

                Spacer(minLength: 8)

                Text(summary.outcomeLevel.shortTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(outcomeColor.opacity(0.90), in: Capsule())

                Text("T\(summary.aiTurn)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.90), in: Capsule())
            }

            Text(summary.outcomeTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.countermeasureKind.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(locationText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                if let objectiveDefenseDetail = summary.objectiveDefenseDetail {
                    Label(
                        "\(objectiveDefenseDetail.title)：\(objectiveDefenseDetail.summary)",
                        systemImage: "shield.checkered"
                    )
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.yellow.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(color.opacity(0.18), lineWidth: 1)
            )

            if !summary.relatedAIEvents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("关联AI行动", systemImage: "timeline.selection")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(BattlefieldTheme.mutedInk)

                    ForEach(summary.relatedAIEvents) { event in
                        Button {
                            game.focusAIPhaseTimelineEvent(order: event.order)
                        } label: {
                            EnemyThreatCountermeasureFollowUpAIEventRow(event: event)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("关联AI行动 \(event.order)，\(event.relation.title)，\(event.title)，\(event.summary)")
                        .accessibilityHint("只定位 AI 复盘事件，不执行命令")
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach(summary.focusTargets) { target in
                    Button {
                        game.focusEnemyThreatCountermeasureFollowUpTarget(target)
                    } label: {
                        Label(target.kind.title, systemImage: focusIcon(for: target.kind))
                            .font(.caption2.weight(.black))
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(focusColor(for: target.kind).opacity(0.16), in: RoundedRectangle(cornerRadius: 7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(focusColor(for: target.kind).opacity(0.34), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(focusColor(for: target.kind))
                    .accessibilityLabel("定位\(target.kind.title)，\(target.title)")
                    .accessibilityHint("只定位敌方回合复核目标，不执行命令")
                }
            }

            HStack(spacing: 7) {
                ForEach(Array(summary.comparisons.prefix(3))) { comparison in
                    CombatResultMetric(
                        title: comparison.title,
                        value: comparison.afterEnemyPhase,
                        color: metricColor(for: comparison.kind)
                    )
                    .accessibilityLabel("\(comparison.title)，敌方回合前\(comparison.beforeEnemyPhase)，敌方回合后\(comparison.afterEnemyPhase)，\(comparison.result)")
                }
            }

            BattleResultDetailLine(row: .init(
                icon: "list.bullet.rectangle",
                text: "复核：\(summary.detailSummary)",
                color: .white.opacity(0.82)
            ))
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    color.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.17), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("敌方回合复核，\(summary.countermeasureKind.title)，\(locationText)，\(summary.outcomeTitle)，\(summary.detailSummary)")
    }

    private var locationText: String {
        let coordinateText = summary.coordinate.map { "，q\($0.q),r\($0.r)" } ?? ""
        return "\(summary.actingUnitName) -> \(summary.targetName)，威胁来源 \(summary.threatEnemyUnitName)\(coordinateText)"
    }

    private var color: Color {
        switch summary.countermeasureKind {
        case .firstStrike:
            return .red
        case .withdraw:
            return .cyan
        case .objectiveDefense:
            return .yellow
        case .reinforce:
            return .green
        }
    }

    private var outcomeColor: Color {
        switch summary.outcomeLevel {
        case .effective:
            return .green
        case .partial:
            return .yellow
        case .failed:
            return .red
        }
    }

    private func focusIcon(for kind: EnemyThreatCountermeasureFollowUpFocusTargetKind) -> String {
        switch kind {
        case .actingUnit:
            return "scope"
        case .threatEnemy:
            return "exclamationmark.triangle.fill"
        case .threatenedTarget:
            return "flag.checkered"
        }
    }

    private func focusColor(for kind: EnemyThreatCountermeasureFollowUpFocusTargetKind) -> Color {
        switch kind {
        case .actingUnit:
            return .cyan
        case .threatEnemy:
            return .orange
        case .threatenedTarget:
            return .yellow
        }
    }

    private func metricColor(for kind: EnemyThreatCountermeasureFollowUpResultKind) -> Color {
        switch kind {
        case .enemyHP:
            return .orange
        case .survival, .recovery:
            return .green
        case .objective:
            return .yellow
        case .position:
            return .cyan
        case .aiImpact:
            return .blue
        }
    }
}

private struct EnemyThreatCountermeasureComparisonHint: View {
    let preview: EnemyThreatCountermeasureComparisonPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Label("首选依据", systemImage: "list.number")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.cyan)
                    .lineLimit(1)

                Text(preview.factor.title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.82), in: RoundedRectangle(cornerRadius: 5))

                Spacer(minLength: 6)
            }

            Text(preview.summary)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            Text("\(preview.leading.kind.title) \(preview.factor.value) \(preview.trailing.kind.title)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.54))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(8)
        .background(BattlefieldTheme.fieldGlass.opacity(0.40), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.cyan.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("首选依据，\(preview.summary)，\(preview.factor.title)：\(preview.factor.value)")
    }
}

private struct EnemyThreatCountermeasureRow: View {
    let preview: EnemyThreatCountermeasurePreview
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(preview.kind.shortTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.86), in: RoundedRectangle(cornerRadius: 5))

                VStack(alignment: .leading, spacing: 2) {
                    Text(preview.kind.title)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("\(preview.actingUnitName) -> \(preview.targetName)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(effectText)
                        .font(.caption.weight(.black))
                        .foregroundStyle(accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if isFocused {
                        Label("预览", systemImage: "scope")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.82))
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                    }
                }
            }

            HStack(spacing: 7) {
                CombatResultMetric(title: "威胁", value: preview.threatKind.shortTitle, color: .pink)
                CombatResultMetric(title: metricTitle, value: metricValue, color: accentColor)
                CombatResultMetric(title: "路线", value: routeMetricText, color: preview.routeCost == nil ? .cyan : .orange)
            }

            HStack(spacing: 7) {
                ForEach(Array(preview.benefitMetrics.prefix(3))) { metric in
                    CombatResultMetric(title: metric.title, value: metric.value, color: benefitColor(for: metric.kind))
                        .accessibilityLabel("\(metric.title)\(metric.value)，\(metric.detail)")
                }
            }

            if let impact = preview.impactComparisons.first {
                HStack(spacing: 7) {
                    CombatResultMetric(title: "当前", value: impact.before, color: .pink)
                    CombatResultMetric(title: "采纳", value: impact.after, color: accentColor)
                    CombatResultMetric(title: "改善", value: impact.impact, color: .green)
                }
                .accessibilityLabel("\(impact.title)，当前\(impact.before)，采纳后\(impact.after)，改善\(impact.impact)")
            }

            if !preview.impactSummary.isEmpty {
                Label(preview.impactSummary, systemImage: "arrow.left.arrow.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let tradeoff = preview.objectiveDefenseTradeoff {
                Label(tradeoff.summary, systemImage: "shield.lefthalf.filled")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accentColor.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("据点防守取舍，\(tradeoff.summary)，\(tradeoff.impactTitle)，\(tradeoff.impactDetail)")
            }

            Label(preview.prioritySummary, systemImage: "list.number")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            Label(preview.reason, systemImage: detailIcon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(
            (isFocused ? Color.white.opacity(0.10) : BattlefieldTheme.fieldGlass.opacity(0.40)),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isFocused ? Color.yellow.opacity(0.66) : accentColor.opacity(0.28), lineWidth: isFocused ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var accentColor: Color {
        switch preview.kind {
        case .firstStrike:
            return .red
        case .withdraw:
            return .cyan
        case .objectiveDefense:
            return .yellow
        case .reinforce:
            return .green
        }
    }

    private var effectText: String {
        switch preview.kind {
        case .firstStrike:
            return preview.willDestroyEnemy ? "击毁" : "-\(preview.projectedDamage)"
        case .withdraw:
            return preview.projectedFriendlyHPAfterAction.map { "HP \($0)" } ?? "转移"
        case .objectiveDefense:
            return preview.destinationText
        case .reinforce:
            return "+\(preview.projectedRecoveredHP)"
        }
    }

    private var metricTitle: String {
        switch preview.kind {
        case .firstStrike:
            return "伤害"
        case .withdraw, .reinforce:
            return "耐久"
        case .objectiveDefense:
            return "目标"
        }
    }

    private var metricValue: String {
        switch preview.kind {
        case .firstStrike:
            return "-\(preview.projectedDamage)"
        case .withdraw:
            return preview.projectedFriendlyHPAfterAction.map { "\($0)" } ?? "--"
        case .objectiveDefense:
            return "守点"
        case .reinforce:
            return "+\(preview.projectedRecoveredHP)"
        }
    }

    private var routeMetricText: String {
        guard let routeCost = preview.routeCost else { return preview.kind == .firstStrike ? "射程" : "即刻" }
        return "\(routeCost)"
    }

    private func benefitColor(for kind: EnemyThreatCountermeasureBenefitKind) -> Color {
        switch kind {
        case .damage:
            return .red
        case .survival:
            return .green
        case .objective:
            return .yellow
        case .recovery:
            return .green
        case .route:
            return .orange
        case .priority:
            return .white.opacity(0.82)
        }
    }

    private var detailIcon: String {
        switch preview.kind {
        case .firstStrike:
            return "target"
        case .withdraw:
            return "arrowshape.turn.up.backward.fill"
        case .objectiveDefense:
            return "shield.fill"
        case .reinforce:
            return "cross.case.fill"
        }
    }
}

private struct EnemyThreatCountermeasureFollowUpAIEventRow: View {
    let event: EnemyThreatCountermeasureFollowUpAIEvent

    var body: some View {
        HStack(alignment: .center, spacing: 7) {
            VStack(alignment: .leading, spacing: 2) {
                Text("#\(event.order)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .monospacedDigit()
                Text(event.kind.shortCode)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.yellow.opacity(0.92))
            }
            .frame(width: 34, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(event.relation.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.black.opacity(0.82))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.88), in: Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(event.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(BattlefieldTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(event.summary)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(BattlefieldTheme.fieldGlass.opacity(0.42), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.yellow.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct AIPhaseSummaryView: View {
    @EnvironmentObject private var game: GameState

    let summary: AIPhaseSummary

    private var commandPointChangeText: String {
        summary.commandPointDelta >= 0 ? "+\(summary.commandPointDelta)" : "\(summary.commandPointDelta)"
    }

    private var visibleTimeline: [AIPhaseTimelineEvent] {
        Array(summary.timeline.prefix(5))
    }

    private var hiddenTimelineCount: Int {
        max(0, summary.timeline.count - visibleTimeline.count)
    }

    private var hiddenFocusedTimelineEvent: AIPhaseTimelineEvent? {
        guard let order = game.focusedAIPhaseTimelineEventOrder else { return nil }
        guard !visibleTimeline.contains(where: { $0.order == order }) else { return nil }
        return summary.timeline.first { $0.order == order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AIPhaseSummaryHeader(summary: summary)

            AIPhaseSummaryMetricGrid(
                summary: summary,
                commandPointChangeText: commandPointChangeText
            )

            AIPhaseReplayConclusionView(
                conclusion: summary.replayConclusion,
                focusedOrder: game.focusedAIPhaseTimelineEventOrder
            ) { order in
                game.focusAIPhaseTimelineEvent(order: order)
            }

            if !visibleTimeline.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    AIPhaseReplayControls()

                    if let hiddenFocusedTimelineEvent {
                        AIPhaseCurrentTimelineEventView(event: hiddenFocusedTimelineEvent)
                    }

                    ForEach(visibleTimeline) { event in
                        let isFocusedEvent = game.focusedAIPhaseTimelineEventOrder == event.order
                        Button {
                            game.focusAIPhaseTimelineEvent(order: event.order)
                        } label: {
                            AIPhaseTimelineEventRow(event: event, isFocused: isFocusedEvent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(isFocusedEvent ? "当前复盘事件，" : "")AI 行动 \(event.order)，\(event.kind.title)，\(event.summary)")
                        .accessibilityHint("只定位地图复盘，不执行命令")
                    }

                    if hiddenTimelineCount > 0 {
                        Text("另有 \(hiddenTimelineCount) 条行动")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BattlefieldTheme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(9)
                .background(Color.black.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(summary.faction.accentColor.opacity(0.18), lineWidth: 1)
                )
            }

            AIPhaseSummaryFooter(summary: summary)
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    summary.faction.accentColor.opacity(0.12),
                    BattlefieldTheme.commandDeckDeep.opacity(0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(summary.faction.accentColor.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 11, x: 0, y: 5)
        .accessibilityElement(children: .contain)
        .onReceive(Timer.publish(every: game.aiPhaseTimelinePlaybackPace.interval, on: .main, in: .common).autoconnect()) { _ in
            if game.isAIPhaseTimelinePlaybackActive {
                game.advanceAIPhaseTimelinePlayback()
            }
        }
    }
}

private struct AIPhaseSummaryHeader: View {
    let summary: AIPhaseSummary

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.headline.weight(.bold))
                .foregroundStyle(summary.faction.accentColor)
                .frame(width: 36, height: 36)
                .background(summary.faction.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 3) {
                Text("\(summary.faction.title)回合摘要")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                Text("敌方行动已结束，可逐条定位战况回放。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text("T\(summary.turn)")
                .font(.caption.weight(.black))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(summary.faction.accentColor.opacity(0.88), in: Capsule())
        }
    }
}

private struct AIPhaseSummaryMetricGrid: View {
    let summary: AIPhaseSummary
    let commandPointChangeText: String

    private let columns = Array(repeating: GridItem(.flexible(minimum: 72), spacing: 6), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            AIPhaseMetricCell(title: "行动", value: "\(summary.totalActions)", color: BattlefieldTheme.ink)
            AIPhaseMetricCell(title: "伤害", value: "-\(summary.damageDealt)", color: .orange)
            AIPhaseMetricCell(title: "承伤", value: summary.damageTaken > 0 ? "-\(summary.damageTaken)" : "0", color: summary.damageTaken > 0 ? .red : BattlefieldTheme.mutedInk)
            AIPhaseMetricCell(title: "移动", value: "\(summary.moves)", color: .cyan)
            AIPhaseMetricCell(title: "攻击", value: "\(summary.attacks)", color: .orange)
            AIPhaseMetricCell(title: "战术", value: "\(summary.tacticalCommands)", color: .purple)
            AIPhaseMetricCell(title: "后勤", value: "\(summary.logisticsActions)", color: .green)
            AIPhaseMetricCell(title: "占点", value: "\(summary.objectivesCaptured)", color: .yellow)
            AIPhaseMetricCell(title: "指令", value: commandPointChangeText, color: summary.commandPointDelta < 0 ? .yellow : BattlefieldTheme.ink)
        }
    }
}

private struct AIPhaseMetricCell: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(1)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)，\(value)")
    }
}

private struct AIPhaseReplayControls: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Label("行动时间线", systemImage: "list.number")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 6)

                Text(game.isAIPhaseTimelinePlaybackActive ? "播放中" : "复盘")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(game.isAIPhaseTimelinePlaybackActive ? .black.opacity(0.82) : BattlefieldTheme.mutedInk)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(game.isAIPhaseTimelinePlaybackActive ? Color.yellow.opacity(0.90) : Color.white.opacity(0.08), in: Capsule())
            }

            HStack(spacing: 8) {
                AIPhaseTimelineNavigationButton(
                    title: game.isAIPhaseTimelinePlaybackActive ? "暂停AI复盘播放" : "播放AI复盘",
                    systemImage: game.isAIPhaseTimelinePlaybackActive ? "pause.fill" : "play.fill",
                    isDisabled: !game.canPlayAIPhaseTimeline && !game.isAIPhaseTimelinePlaybackActive
                ) {
                    game.toggleAIPhaseTimelinePlayback()
                }

                AIPhaseTimelinePlaybackPaceMenu()

                Spacer(minLength: 4)

                AIPhaseTimelineNavigationButton(
                    title: "上一条AI复盘",
                    systemImage: "chevron.left",
                    isDisabled: !game.canFocusPreviousAIPhaseTimelineEvent
                ) {
                    game.focusPreviousAIPhaseTimelineEvent()
                }

                AIPhaseTimelineNavigationButton(
                    title: "下一条AI复盘",
                    systemImage: "chevron.right",
                    isDisabled: !game.canFocusNextAIPhaseTimelineEvent
                ) {
                    game.focusNextAIPhaseTimelineEvent()
                }
            }
        }
        .padding(9)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(game.isAIPhaseTimelinePlaybackActive ? 0.12 : 0.06),
                    BattlefieldTheme.commandDeckDeep.opacity(0.40)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(game.isAIPhaseTimelinePlaybackActive ? 0.34 : 0.16), lineWidth: 1)
        )
    }
}

private struct AIPhaseCurrentTimelineEventView: View {
    let event: AIPhaseTimelineEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Label("当前回放", systemImage: "scope")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("#\(event.order)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .monospacedDigit()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.90), in: Capsule())

                Spacer(minLength: 6)

                Text(event.kind.shortCode)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.10), in: Capsule())
            }

            AIPhaseTimelineEventRow(event: event, isFocused: true)
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.14),
                    BattlefieldTheme.commandDeckDeep.opacity(0.46)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.36), lineWidth: 1.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("当前AI复盘事件 \(event.order)，\(event.kind.title)，\(event.summary)")
    }
}

private struct AIPhaseSummaryFooter: View {
    let summary: AIPhaseSummary

    var body: some View {
        Label("歼灭 \(summary.enemyUnitsDestroyed) 支，损失 \(summary.friendlyUnitsDestroyed) 支，指令点 \(summary.startingCommandPoints)->\(summary.endingCommandPoints)。", systemImage: "flag.checkered")
            .font(.caption.weight(.semibold))
            .foregroundStyle(BattlefieldTheme.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AIPhaseReplayConclusionView: View {
    let conclusion: AIPhaseReplayConclusion
    let focusedOrder: Int?
    let onSelectKeyEvent: (Int) -> Void

    private let metricColumns = [
        GridItem(.flexible(minimum: 72), spacing: 6),
        GridItem(.flexible(minimum: 72), spacing: 6)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Label(conclusion.title, systemImage: conclusion.kind.systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(conclusionColor)

                Spacer(minLength: 6)

                Text(conclusion.kind.shortTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(conclusionColor.opacity(0.88), in: Capsule())
            }

            Text(conclusion.summary)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 6) {
                ForEach(conclusion.metrics) { metric in
                    AIPhaseReplayMetricCell(metric: metric, color: metricColor(for: metric.kind))
                }
            }

            if !conclusion.keyEvents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("关键事件", systemImage: "star.square.on.square.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(conclusionColor)

                    ForEach(conclusion.keyEvents) { event in
                        let isFocusedEvent = focusedOrder == event.order
                        Button {
                            onSelectKeyEvent(event.order)
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: isFocusedEvent ? "scope" : "circle")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(isFocusedEvent ? .black.opacity(0.82) : conclusionColor)
                                    .frame(width: 16)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(event.title)
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(isFocusedEvent ? .black.opacity(0.86) : conclusionColor)
                                    Text(event.detail)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(isFocusedEvent ? .black.opacity(0.76) : BattlefieldTheme.mutedInk)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 4)

                                Image(systemName: "location.magnifyingglass")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(isFocusedEvent ? .black.opacity(0.72) : conclusionColor)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 7)
                            .background(
                                isFocusedEvent ? conclusionColor.opacity(0.88) : Color.white.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 7)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(isFocusedEvent ? conclusionColor.opacity(0.96) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(isFocusedEvent ? "当前复盘关键事件，" : "")关键AI事件，\(event.title)，\(event.detail)")
                        .accessibilityHint("只定位地图复盘，不执行命令")
                    }
                }
            }
        }
        .padding(9)
        .background(conclusionColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(conclusionColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private var conclusionColor: Color {
        switch conclusion.kind {
        case .objectiveBreakthrough: .yellow
        case .fireSuppression: .orange
        case .logistics: .green
        case .maneuver: .cyan
        case .quiet: .white.opacity(0.72)
        }
    }

    private func metricColor(for kind: AIPhaseReplayConclusionMetricKind) -> Color {
        switch kind {
        case .damage: .orange
        case .objectives: .yellow
        case .logistics: .green
        case .command: .white.opacity(0.82)
        }
    }
}

private struct AIPhaseReplayMetricCell: View {
    let metric: AIPhaseReplayConclusionMetric
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(metric.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                Spacer(minLength: 4)
                Text(metric.value)
                    .font(.caption.weight(.black))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            Text(metric.detail)
                .font(.caption2.weight(.medium))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.title)，\(metric.value)，\(metric.detail)")
    }
}

private struct AIPhaseTimelinePlaybackPaceMenu: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        Menu {
            ForEach(AIPhaseTimelinePlaybackPace.allCases) { pace in
                Button {
                    game.setAIPhaseTimelinePlaybackPace(pace)
                } label: {
                    Label(pace.title, systemImage: pace == game.aiPhaseTimelinePlaybackPace ? "checkmark" : "speedometer")
                }
            }
        } label: {
            Label("AI复盘速度 \(game.aiPhaseTimelinePlaybackPace.title)", systemImage: "speedometer")
                .labelStyle(.iconOnly)
                .font(.caption.weight(.black))
                .foregroundStyle(BattlefieldTheme.ink)
                .frame(width: 32, height: 32)
                .overlay(alignment: .bottomTrailing) {
                    Text(game.aiPhaseTimelinePlaybackPace.shortTitle)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.yellow.opacity(0.96))
                        .offset(x: 4, y: 4)
                }
                .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .accessibilityLabel("AI复盘速度")
        .accessibilityValue(game.aiPhaseTimelinePlaybackPace.title)
        .accessibilityHint("选择自动播放AI复盘事件的速度")
        .help("AI复盘速度")
    }
}

private struct AIPhaseTimelineNavigationButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.caption.weight(.black))
                .foregroundStyle(isDisabled ? .white.opacity(0.28) : .yellow.opacity(0.92))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(isDisabled ? 0.04 : 0.09), in: RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(isDisabled ? 0.10 : 0.26), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
        .accessibilityHint("只切换AI复盘定位，不执行命令")
        .help(title)
    }
}

private struct AIPhaseTimelineEventRow: View {
    let event: AIPhaseTimelineEvent
    let isFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isFocused ? "scope" : "circle")
                .font(.caption.weight(.bold))
                .foregroundStyle(isFocused ? .yellow : .white.opacity(0.35))
                .frame(width: 16, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("#\(event.order)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(isFocused ? BattlefieldTheme.ink : BattlefieldTheme.mutedInk)
                        .monospacedDigit()

                    Text(event.shortCode)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(isFocused ? .black.opacity(0.82) : .yellow.opacity(0.92))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(isFocused ? Color.yellow.opacity(0.88) : Color.yellow.opacity(0.10), in: Capsule())

                    Text(event.kind.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isFocused ? .yellow : BattlefieldTheme.mutedInk)
                }

                Text(event.summary)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isFocused ? BattlefieldTheme.ink : BattlefieldTheme.mutedInk)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "location.magnifyingglass")
                .font(.caption.weight(.bold))
                .foregroundStyle(isFocused ? .yellow : BattlefieldTheme.mutedInk)
                .frame(width: 20, height: 24)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(isFocused ? Color.yellow.opacity(0.09) : Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isFocused ? Color.yellow.opacity(0.52) : Color.white.opacity(0.06), lineWidth: isFocused ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct BattleLogView: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("战报", systemImage: "list.bullet.rectangle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(BattlefieldTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 6)

                Text("\(game.battleLog.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(game.battleLog.enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(BattlefieldTheme.ink.opacity(0.80))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(4)
                            .minimumScaleFactor(0.82)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .frame(minHeight: 96, maxHeight: 180)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BattlefieldTheme.commandDeckDeep.opacity(0.40))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.hairline, lineWidth: 1)
                )
        )
    }
}


extension Faction {
    var accentColor: Color {
        switch self {
        case .allies:
            Color(red: 0.12, green: 0.36, blue: 0.72)
        case .axis:
            Color(red: 0.72, green: 0.16, blue: 0.14)
        }
    }
}

private extension MoraleState {
    var accentColor: Color {
        switch self {
        case .shaken:
            Color(red: 0.86, green: 0.28, blue: 0.22)
        case .steady:
            Color(red: 0.36, green: 0.68, blue: 0.78)
        case .inspired:
            Color(red: 0.96, green: 0.68, blue: 0.24)
        }
    }
}

private extension CombatPreview {
    var matchupAccentColor: Color {
        if matchupMultiplierPercent >= 110 {
            return .green
        }
        if matchupMultiplierPercent <= 94 {
            return .red
        }
        return .white.opacity(0.68)
    }

    var matchupIcon: String {
        if matchupMultiplierPercent >= 110 {
            return "chevron.up.circle.fill"
        }
        if matchupMultiplierPercent <= 94 {
            return "chevron.down.circle.fill"
        }
        return "equal.circle.fill"
    }

    var terrainAccentColor: Color {
        if terrainAttackMultiplierPercent >= 106 {
            return .green
        }
        if terrainAttackMultiplierPercent <= 94 {
            return .orange
        }
        return .white.opacity(0.68)
    }

    var terrainIcon: String {
        if terrainAttackMultiplierPercent >= 106 {
            return "mountain.2.circle.fill"
        }
        if terrainAttackMultiplierPercent <= 94 {
            return "exclamationmark.circle.fill"
        }
        return "circle.grid.cross.fill"
    }
}

private extension TacticalCommand {
    var systemImage: String {
        switch self {
        case .artilleryBarrage:
            "burst.fill"
        case .breakthroughAssault:
            "bolt.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .artilleryBarrage:
            .orange
        case .breakthroughAssault:
            .red
        }
    }
}
