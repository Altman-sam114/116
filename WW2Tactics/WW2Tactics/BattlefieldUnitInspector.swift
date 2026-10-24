import SwiftUI

struct UnitDetail: View {
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

struct BattleIntelPill: View {
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

extension CombatPreview {
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
