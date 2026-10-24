import SwiftUI

struct BattlefieldSituationSummaryView: View {
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
