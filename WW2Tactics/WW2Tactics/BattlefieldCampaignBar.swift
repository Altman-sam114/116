import SwiftUI

struct TopCommandBar: View {
    @EnvironmentObject private var game: GameState
    var condensed = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            campaignLine(compact: false)
            campaignLine(compact: true)
        }
        .accessibilityValue("\(game.activeFaction.title)行动，剩余\(game.remainingTurns)回合，\(game.readyUnitCount)支部队待命")
    }

    private func campaignLine(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            CampaignPicker(condensed: condensed, compact: compact)
            Spacer(minLength: 0)
            HStack(spacing: compact ? 12 : 20) {
                CampaignResource(icon: "flag.fill", title: "据点", value: "\(game.alliedScore)/\(game.objectiveTiles.count)", color: BattlefieldTheme.brass)
                CampaignResource(icon: "bolt.fill", title: "指令", value: "\(game.activeCommandPoints)", color: BattlefieldTheme.signal)
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
}

private struct CampaignResource: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 8, weight: .semibold)).foregroundStyle(BattlefieldTheme.mutedInk)
                Text(value).font(.custom("Georgia-Bold", size: 16)).monospacedDigit().foregroundStyle(color)
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
            HStack(spacing: compact ? 8 : 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: compact ? 25 : 30, weight: .regular))
                    .foregroundStyle(BattlefieldTheme.brass)
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.scenario.name)
                        .font(.system(size: compact ? 14 : 17, weight: .heavy))
                        .lineLimit(1)
                    if !condensed {
                        Text("\(game.scenario.year)  /  \(compact ? "西线战场" : "WESTERN FRONT")")
                            .font(.custom("Georgia-Bold", size: compact ? 8 : 9))
                            .tracking(compact ? 0.4 : 1.5)
                            .foregroundStyle(BattlefieldTheme.brass)
                            .lineLimit(1)
                    }
                }
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .heavy))
            }
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .padding(.horizontal, compact ? 10 : 14)
            .frame(height: condensed ? 44 : 54)
            .background(FieldPlate())
            .fixedSize()
        }
        .accessibilityLabel("选择战役")
        .accessibilityValue(game.scenario.name)
    }
}

struct EndTurnButton: View {
    @EnvironmentObject private var game: GameState
    var condensed = false

    var body: some View {
        Button(action: game.endTurn) {
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(game.turn)").font(.custom("Georgia-Bold", size: condensed ? 21 : 26))
                    Text("/\(game.scenario.turnLimit)").font(.custom("Georgia", size: 10))
                }
                HStack(spacing: 3) {
                    Text("结束回合").font(.system(size: 9, weight: .heavy))
                    Image(systemName: "forward.end.fill").font(.system(size: 8, weight: .bold))
                }
            }
            .foregroundStyle(Color(red: 0.17, green: 0.20, blue: 0.15))
            .frame(width: condensed ? 70 : 80, height: condensed ? 60 : 72)
            .background {
                BeveledFieldShape().fill(BattlefieldTheme.actionBrass)
                    .overlay { BeveledFieldShape().stroke(BattlefieldTheme.fieldPaper.opacity(0.65), lineWidth: 1) }
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
            }
        }
        .buttonStyle(.plain)
        .disabled(game.winner != nil)
        .accessibilityLabel("结束回合")
        .accessibilityValue("第\(game.turn)回合，共\(game.scenario.turnLimit)回合")
        .accessibilityIdentifier("battlefield-end-turn")
        .accessibilityHint("结束当前阵营行动并推进战局")
    }
}
