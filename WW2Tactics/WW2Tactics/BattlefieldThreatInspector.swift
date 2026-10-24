import SwiftUI

struct EnemyThreatIntentPanel: View {
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

struct EnemyThreatCountermeasurePanel: View {
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

struct EnemyThreatCountermeasureExecutionResultSummaryView: View {
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

struct EnemyThreatCountermeasureFollowUpSummaryView: View {
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
