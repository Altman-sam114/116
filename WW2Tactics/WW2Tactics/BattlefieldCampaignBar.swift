import SwiftUI

struct TopCommandBar: View {
    @EnvironmentObject private var game: GameState
    var condensed = false

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 600
            HStack(spacing: compact ? 8 : 18) {
                CampaignPicker(condensed: condensed, compact: compact)
                    .frame(maxWidth: compact ? 126 : 200)
                if !compact {
                    Rectangle().fill(BattlefieldTheme.brass.opacity(0.35)).frame(width: 1, height: 30)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: compact ? 12 : 22) {
                        resource("回合", value: "\(game.turn)/\(game.scenario.turnLimit)", color: .white)
                        resource("据点", value: "\(game.alliedScore)/\(game.objectiveTiles.count)", color: BattlefieldTheme.brass)
                        resource("指令", value: "\(game.activeCommandPoints)", color: BattlefieldTheme.signal)
                        if !compact {
                            resource("阵营", value: game.activeFaction.shortTitle, color: game.activeFaction.accentColor)
                            resource("待命", value: "\(game.readyUnitCount)", color: .white)
                        }
                    }
                }
                EndTurnButton(condensed: condensed)
            }
            .padding(.horizontal, compact ? 10 : 18)
            .frame(height: condensed ? 48 : 60)
        }
        .frame(height: condensed ? 48 : 60)
        .background(BattlefieldTheme.commandMetal)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BattlefieldTheme.brass.opacity(0.45)).frame(height: 1)
        }
        .accessibilityValue("\(game.activeFaction.title)行动，剩余\(game.remainingTurns)回合，\(game.readyUnitCount)支部队待命")
    }

    private func resource(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(BattlefieldTheme.mutedInk)
            Text(value).font(.system(size: 16, weight: .bold, design: .serif)).monospacedDigit().foregroundStyle(color)
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
                    if scenario.id == game.scenario.id {
                        Label(scenario.name, systemImage: "checkmark")
                    } else {
                        Text(scenario.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if !compact { Image(systemName: "map.fill").foregroundStyle(BattlefieldTheme.brass) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.scenario.name)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.90)
                    if !condensed {
                        Text(compact ? "\(game.scenario.year) / HEX" : "\(game.scenario.year)  /  WESTERN FRONT")
                            .font(.system(size: 8, weight: .bold, design: .serif))
                            .tracking(1.2)
                            .foregroundStyle(BattlefieldTheme.brass)
                            .lineLimit(1)
                    }
                }
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .heavy))
            }
            .foregroundStyle(.white)
            .frame(minWidth: 90, maxWidth: 200, minHeight: 44, alignment: .leading)
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
            VStack(spacing: 3) {
                if !condensed {
                    Image(systemName: "forward.end.fill").font(.system(size: 16, weight: .bold))
                }
                Text("结束回合").font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.13))
            .frame(width: 64, height: condensed ? 40 : 46)
            .background(BattlefieldTheme.actionBrass, in: RoundedRectangle(cornerRadius: 3))
            .overlay { RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.24), lineWidth: 0.8) }
        }
        .buttonStyle(.plain)
        .disabled(game.winner != nil)
        .accessibilityIdentifier("battlefield-end-turn")
        .accessibilityHint("结束当前阵营行动并推进战局")
    }
}
