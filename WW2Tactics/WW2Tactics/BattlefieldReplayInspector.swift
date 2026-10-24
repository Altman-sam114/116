import SwiftUI

struct AIPhaseSummaryView: View {
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
