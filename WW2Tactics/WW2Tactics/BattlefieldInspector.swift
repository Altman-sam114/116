import SwiftUI

struct InspectorSectionHeader: View {
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

struct InspectorPanel: View {
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
