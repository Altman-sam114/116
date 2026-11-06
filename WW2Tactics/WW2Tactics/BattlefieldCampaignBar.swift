import SwiftUI

/// One battle masthead: campaign, objective progress and real command resources.
struct TopCommandBar: View {
    @EnvironmentObject private var game: GameState
    var condensed = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 600
            HStack(spacing: compact ? 12 : 24) {
                CampaignPicker(condensed: condensed, compact: compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if geometry.size.width >= 1000 {
                    objectiveProgress
                    Spacer(minLength: 0)
                } else {
                    CampaignResource(icon: "flag.fill", title: "据点", value: "\(game.alliedScore)/\(game.objectiveTiles.count)", color: BattlefieldTheme.brass)
                }
                if !compact {
                    CampaignResource(icon: "clock", title: "回合", value: String(format: "%02d", game.turn) + "/\(game.scenario.turnLimit)", color: BattlefieldTheme.fieldPaper)
                }
                CampaignResource(icon: "shippingbox", title: "指令", value: "\(game.activeCommandPoints)", color: BattlefieldTheme.signal)
                if !compact {
                    CampaignResource(icon: "person.2", title: "待命", value: "\(game.readyUnitCount)", color: BattlefieldTheme.fieldPaper)
                }
            }
            .padding(.horizontal, compact ? 12 : 18)
            .frame(height: condensed ? 50 : 60)
            .background(FieldPlate())
        }
        .frame(height: condensed ? 50 : 60)
        .accessibilityValue("\(game.activeFaction.title)行动，剩余\(game.remainingTurns)回合，\(game.readyUnitCount)支部队待命")
    }

    private var objectiveProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill").foregroundStyle(BattlefieldTheme.brass)
                Text("夺取全部据点").foregroundStyle(BattlefieldTheme.fieldPaper)
                Text("\(game.alliedScore) / \(game.objectiveTiles.count)").foregroundStyle(BattlefieldTheme.brass)
            }
            .font(BattlefieldTheme.hudLabel)
            HStack(spacing: 3) {
                ForEach(0..<game.objectiveTiles.count, id: \.self) { index in
                    Rectangle().fill(index < game.alliedScore ? BattlefieldTheme.brass : .white.opacity(0.13))
                }
            }
            .frame(width: 190, height: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("夺取全部据点，已控制\(game.alliedScore)，共\(game.objectiveTiles.count)")
    }
}

private struct CampaignResource: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: icon).font(BattlefieldTheme.hudCaption)
                .foregroundStyle(BattlefieldTheme.mutedInk)
            Text(value).font(BattlefieldTheme.militaryFont(22)).monospacedDigit()
                .foregroundStyle(color)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

struct CampaignPicker: View {
    @EnvironmentObject private var game: GameState
    var condensed = false
    var compact = false

    var body: some View {
        Menu {
            ForEach(game.campaignCatalog) { scenario in
                Button {
                    game.selectScenario(id: scenario.id)
                } label: {
                    if scenario.id == game.scenario.id { Label(scenario.name, systemImage: "checkmark") }
                    else { Text(scenario.name) }
                }
            }
        } label: {
            HStack(spacing: compact ? 8 : 12) {
                ZStack {
                    BeveledFieldShape().fill(BattlefieldTheme.actionBrass)
                    Image(systemName: "star.fill").font(.system(size: compact ? 14 : 18))
                        .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                }
                .frame(width: compact ? 27 : 34, height: compact ? 33 : 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.scenario.name)
                        .font(.system(size: compact ? 14 : 18, weight: .bold, design: .serif))
                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                    HStack(spacing: 5) {
                        Text("\(game.scenario.year)").font(BattlefieldTheme.militaryFont(12))
                        Rectangle().fill(BattlefieldTheme.brass.opacity(0.5)).frame(width: 9, height: 1)
                        Text("\(game.activeFaction.title)行动").font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(BattlefieldTheme.brass)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("选择战役")
        .accessibilityValue(game.scenario.name)
    }
}

struct EndTurnButton: View {
    @EnvironmentObject private var game: GameState
    var condensed = false
    var compact = false

    var body: some View {
        Button(action: game.endTurn) {
            HStack(spacing: compact ? 6 : 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("结束回合").font(.system(size: compact ? 12 : 14, weight: .bold))
                    Text("\(game.turn) / \(game.scenario.turnLimit) 回合")
                        .font(.system(size: 9, weight: .semibold)).monospacedDigit().opacity(0.7)
                }
                Image(systemName: "chevron.right").font(.system(size: compact ? 12 : 17, weight: .medium))
            }
            .foregroundStyle(BattlefieldTheme.commandDeckDeep)
            .frame(width: compact ? 100 : 140, height: condensed ? 44 : 48)
            .background(BattlefieldTheme.actionBrass, in: BeveledFieldShape())
            .overlay { BeveledFieldShape().stroke(BattlefieldTheme.fieldPaper.opacity(0.35), lineWidth: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(game.winner != nil)
        .accessibilityLabel("结束回合")
        .accessibilityValue("第\(game.turn)回合，共\(game.scenario.turnLimit)回合")
        .accessibilityIdentifier("battlefield-end-turn")
        .accessibilityHint("结束当前阵营行动并推进战局")
    }
}
