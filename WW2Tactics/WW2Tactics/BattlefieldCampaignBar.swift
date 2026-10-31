import SwiftUI

struct TopCommandBar: View {
    @EnvironmentObject private var game: GameState
    var condensed = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 600
            HStack(alignment: .top, spacing: 8) {
                CampaignPicker(condensed: condensed, compact: compact)
                Spacer(minLength: 0)
                HStack(spacing: compact ? 10 : 18) {
                    CampaignResource(icon: "flag.fill", title: "据点", value: "\(game.alliedScore)/\(game.objectiveTiles.count)", color: BattlefieldTheme.brass)
                    CampaignResource(icon: "shippingbox.fill", title: "指令", value: "\(game.activeCommandPoints)", color: BattlefieldTheme.signal)
                    if !compact {
                        CampaignResource(icon: "person.3.fill", title: "待命", value: "\(game.readyUnitCount)", color: BattlefieldTheme.fieldPaper)
                    }
                }
                .padding(.horizontal, compact ? 12 : 16)
                .frame(height: condensed ? 44 : 54)
                .background(FieldPlate())
                .fixedSize()
            }
        }
        .frame(height: condensed ? 44 : 54)
        .accessibilityValue("\(game.activeFaction.title)行动，剩余\(game.remainingTurns)回合，\(game.readyUnitCount)支部队待命")
    }
}

private struct CampaignResource: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .medium)).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(BattlefieldTheme.hudCaption).foregroundStyle(BattlefieldTheme.mutedInk)
                Text(value).font(BattlefieldTheme.militaryFont(22)).monospacedDigit().foregroundStyle(BattlefieldTheme.fieldPaper)
            }
        }
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
                    if scenario.id == game.scenario.id {
                        Label(scenario.name, systemImage: "checkmark")
                    } else {
                        Text(scenario.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 9) {
                CampaignInsignia()
                    .frame(width: condensed ? 28 : 34, height: condensed ? 32 : 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.scenario.name)
                        .font(.system(size: compact ? 13 : 16, weight: .heavy))
                        .lineLimit(1).minimumScaleFactor(0.8)
                    if !condensed {
                        Text("\(game.scenario.year)  ·  WESTERN FRONT")
                            .font(BattlefieldTheme.militaryFont(compact ? 9 : 11))
                            .tracking(1)
                            .foregroundStyle(BattlefieldTheme.brass)
                            .lineLimit(1)
                    }
                }
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(BattlefieldTheme.brass)
            }
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .padding(.leading, 6).padding(.trailing, 12)
            .frame(height: condensed ? 44 : 54)
            .contentShape(Rectangle())
            .background(FieldPlate())
        }
        .accessibilityLabel("选择战役")
        .accessibilityValue(game.scenario.name)
    }
}

private struct CampaignInsignia: View {
    var body: some View {
        ZStack {
            BeveledFieldShape().fill(BattlefieldTheme.actionBrass)
                .overlay { BeveledFieldShape().stroke(.black.opacity(0.45), lineWidth: 1).padding(2) }
            Image(systemName: "star.fill").font(.system(size: 17, weight: .black))
                .foregroundStyle(BattlefieldTheme.commandDeckDeep)
        }
        .accessibilityHidden(true)
    }
}

struct EndTurnButton: View {
    @EnvironmentObject private var game: GameState
    var condensed = false

    var body: some View {
        Button(action: game.endTurn) {
            VStack(spacing: -6) {
                ZStack {
                    Circle().fill(BattlefieldTheme.commandMetal)
                    Circle().stroke(BattlefieldTheme.brass.opacity(0.50), lineWidth: 4)
                    Circle().inset(by: 5).stroke(.black.opacity(0.55), lineWidth: 2)
                    Circle().trim(from: 0, to: progress)
                        .stroke(BattlefieldTheme.actionBrass, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: -2) {
                        Text("\(game.turn)").font(BattlefieldTheme.militaryFont(condensed ? 29 : 34))
                        Text("/ \(game.scenario.turnLimit)").font(BattlefieldTheme.militaryFont(11))
                            .foregroundStyle(BattlefieldTheme.mutedInk)
                    }
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                }
                .frame(width: condensed ? 55 : 65, height: condensed ? 55 : 65)
                HStack(spacing: 4) {
                    Text("结束回合").font(.system(size: 9, weight: .heavy))
                    Image(systemName: "chevron.right").font(.system(size: 8, weight: .heavy))
                }
                .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                .frame(width: condensed ? 75 : 84, height: 23)
                .background(BattlefieldTheme.actionBrass, in: BeveledFieldShape())
            }
            .padding(2)
            .contentShape(Rectangle())
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(game.winner != nil)
        .accessibilityLabel("结束回合")
        .accessibilityValue("第\(game.turn)回合，共\(game.scenario.turnLimit)回合")
        .accessibilityIdentifier("battlefield-end-turn")
        .accessibilityHint("结束当前阵营行动并推进战局")
    }

    private var progress: CGFloat {
        min(1, max(0, CGFloat(game.turn) / CGFloat(max(1, game.scenario.turnLimit))))
    }
}
