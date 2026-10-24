import SwiftUI

struct CombatResultSummaryView: View {
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

struct BattleResultDetailLine: View {
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

struct CombatResultMetric: View {
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

struct CombatResultDetailRow {
    let icon: String
    let text: String
    let color: Color
}

struct TacticalCommandResultSummaryView: View {
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

struct ObjectiveCaptureResultSummaryView: View {
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

struct DeploymentResultSummaryView: View {
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

struct ReinforcementResultSummaryView: View {
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
