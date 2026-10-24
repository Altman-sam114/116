import SwiftUI

struct ObjectiveAdvancePlanPanel: View {
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

struct SafeEngagementOptionsPanel: View {
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

struct TacticalCommandPanel: View {
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

struct FocusedCommandPreviewPanel: View {
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

struct AttackTargetsView: View {
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
