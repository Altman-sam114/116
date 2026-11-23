import SwiftUI

/// Floating top-left EasyTech resource & campaign masthead (never spans dead empty width).
struct TopCommandBar: View {
    @EnvironmentObject private var game: GameState
    var condensed = false
    var onOpenShop: () -> Void = {}

    var body: some View {
        let income = game.totalTurnEconomyIncome(for: .allies)
        HStack(spacing: condensed ? 8 : 12) {
            CampaignPicker(condensed: condensed, compact: condensed)

            FieldToolDivider(axis: .horizontal)

            HStack(spacing: condensed ? 8 : 12) {
                PaintedResourceChip(
                    icon: BattlefieldArtwork.resourceIcon(.gold),
                    fallbackSystemImage: "dollarsign.circle.fill",
                    title: "金币",
                    value: "\(game.warResources.gold)",
                    delta: "+\(income.gold)",
                    accent: BattlefieldTheme.selectedPiece,
                    condensed: condensed
                )
                PaintedResourceChip(
                    icon: BattlefieldArtwork.resourceIcon(.industry),
                    fallbackSystemImage: "gearshape.fill",
                    title: "工业",
                    value: "\(game.warResources.industry)",
                    delta: "+\(income.industry)",
                    accent: Color(red: 0.72, green: 0.80, blue: 0.86),
                    condensed: condensed
                )
                PaintedResourceChip(
                    icon: BattlefieldArtwork.resourceIcon(.supply),
                    fallbackSystemImage: "shippingbox.fill",
                    title: "指令",
                    value: "\(game.activeCommandPoints)",
                    delta: nil,
                    accent: BattlefieldTheme.signal,
                    condensed: condensed
                )

                Button(action: onOpenShop) {
                    HStack(spacing: 4) {
                        PaintedResourceChip(
                            icon: BattlefieldArtwork.resourceIcon(.medal),
                            fallbackSystemImage: "medal.fill",
                            title: "勋章",
                            value: "\(game.warResources.honorMedals)",
                            delta: nil,
                            accent: Color(red: 1.0, green: 0.78, blue: 0.34),
                            condensed: condensed
                        )
                        Image(systemName: "plus")
                            .font(.system(size: condensed ? 9 : 10, weight: .black))
                            .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                            .frame(width: condensed ? 16 : 18, height: condensed ? 16 : 18)
                            .background(BattlefieldTheme.actionBrass, in: BeveledFieldShape(cornerCut: 3))
                            .overlay(BeveledFieldShape(cornerCut: 3).stroke(Color.white.opacity(0.45), lineWidth: 0.6))
                    }
                    .frame(minHeight: 40)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开军需商城补充勋章")
                .accessibilityIdentifier("battlefield-medals-shop")
            }
        }
        .padding(.horizontal, condensed ? 9 : 13)
        .frame(height: condensed ? 46 : 54)
        .background(FieldPlate(material: .gunmetal))
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(game.activeFaction.title)行动，剩余\(game.remainingTurns)回合，\(game.readyUnitCount)支部队待命")
    }
}

private struct PaintedResourceChip: View {
    let icon: CGImage?
    let fallbackSystemImage: String
    let title: String
    let value: String
    let delta: String?
    let accent: Color
    let condensed: Bool

    var body: some View {
        HStack(spacing: condensed ? 4 : 6) {
            if let icon {
                BattlefieldArtwork.image(icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: condensed ? 20 : 24, height: condensed ? 20 : 24)
                    .shadow(color: .black.opacity(0.6), radius: 1.5, y: 1)
            } else {
                Image(systemName: fallbackSystemImage)
                    .font(.system(size: condensed ? 14 : 16))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 3) {
                    Text(title)
                        .font(.system(size: condensed ? 8 : 9, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                    if let delta, !condensed {
                        Text(delta)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(BattlefieldTheme.signal)
                            .monospacedDigit()
                    }
                }
                Text(value)
                    .font(BattlefieldTheme.militaryFont(condensed ? 16 : 19))
                    .monospacedDigit()
                    .foregroundStyle(accent)
                    .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
            }
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

/// Sculpted floating top-center EasyTech hourglass turn & objective shield.
struct TurnObjectiveShield: View {
    @EnvironmentObject private var game: GameState
    var condensed = false

    var body: some View {
        HStack(spacing: condensed ? 8 : 12) {
            HStack(spacing: 5) {
                if let hourglass = BattlefieldArtwork.emblem(.hourglass) {
                    BattlefieldArtwork.image(hourglass)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: condensed ? 18 : 22, height: condensed ? 18 : 22)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("回合")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.brass)
                    Text(String(format: "%02d/%d", game.turn, game.scenario.turnLimit))
                        .font(BattlefieldTheme.militaryFont(condensed ? 15 : 18))
                        .monospacedDigit()
                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                }
            }

            FieldToolDivider(axis: .horizontal)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(BattlefieldTheme.selectedPiece)
                    Text("据点")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                    Text("\(game.alliedScore)/\(game.objectiveTiles.count)")
                        .font(BattlefieldTheme.militaryFont(condensed ? 14 : 16))
                        .monospacedDigit()
                        .foregroundStyle(BattlefieldTheme.selectedPiece)
                }
                HStack(spacing: 2) {
                    let total = max(1, game.objectiveTiles.count)
                    ForEach(0..<min(total, 14), id: \.self) { index in
                        Rectangle()
                            .fill(index < game.alliedScore ? BattlefieldTheme.selectedPiece : Color.white.opacity(0.16))
                            .frame(height: 3)
                    }
                }
                .frame(width: condensed ? 76 : 112, height: 3)
            }
        }
        .padding(.horizontal, condensed ? 10 : 14)
        .frame(height: condensed ? 44 : 52)
        .background(FieldPlate(emphasized: true, material: .brassDossier, showsRivets: false))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("第\(game.turn)回合，共\(game.scenario.turnLimit)回合，已控制\(game.alliedScore)个据点，共\(game.objectiveTiles.count)个")
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
            HStack(spacing: compact ? 6 : 9) {
                if let crest = BattlefieldArtwork.emblem(game.activeFaction == .allies ? .alliedCrest : .axisCrest) {
                    BattlefieldArtwork.image(crest)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: compact ? 28 : 34, height: compact ? 28 : 34)
                        .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                } else {
                    ZStack {
                        BeveledFieldShape().fill(BattlefieldTheme.actionBrass)
                        Image(systemName: "star.fill").font(.system(size: compact ? 13 : 16))
                            .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                    }
                    .frame(width: compact ? 26 : 32, height: compact ? 28 : 34)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(game.scenario.name)
                        .font(.system(size: compact ? 12 : 15, weight: .bold, design: .serif))
                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                    HStack(spacing: 4) {
                        Text(game.scenario.year).font(BattlefieldTheme.militaryFont(11))
                        Text("·")
                        Text("\(game.activeFaction.title)").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(BattlefieldTheme.brass)
                }
                .lineLimit(1)
                .fixedSize()
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(BattlefieldTheme.brass.opacity(0.85))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("选择战役")
        .accessibilityValue(game.scenario.name)
    }
}

/// Sculpted GoG3/WC4 corner End Turn emblem button with painted antique-gold hourglass.
struct EndTurnButton: View {
    @EnvironmentObject private var game: GameState
    var condensed = false
    var compact = false

    var body: some View {
        Button(action: game.endTurn) {
            HStack(spacing: compact ? 6 : 10) {
                if let hourglass = BattlefieldArtwork.emblem(.hourglass) {
                    BattlefieldArtwork.image(hourglass)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: condensed ? 26 : 32, height: condensed ? 26 : 32)
                        .shadow(color: .black.opacity(0.65), radius: 2, y: 1)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("结束回合")
                        .font(.system(size: condensed ? 13 : 15, weight: .black))
                        .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                    Text("\(game.turn) / \(game.scenario.turnLimit) 回合")
                        .font(BattlefieldTheme.militaryFont(condensed ? 11 : 13))
                        .monospacedDigit()
                        .foregroundStyle(BattlefieldTheme.commandDeckDeep.opacity(0.82))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: condensed ? 12 : 15, weight: .black))
                    .foregroundStyle(BattlefieldTheme.commandDeckDeep.opacity(0.85))
            }
            .padding(.horizontal, condensed ? 12 : 16)
            .frame(minWidth: condensed ? 122 : 148)
            .frame(height: condensed ? 48 : 56)
            .background {
                ZStack {
                    BeveledFieldShape(cornerCut: 9)
                        .fill(BattlefieldTheme.actionBrass)
                    BeveledFieldShape(cornerCut: 9)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.32), .clear, Color.black.opacity(0.24)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    BeveledFieldShape(cornerCut: 9)
                        .stroke(Color(red: 1.0, green: 0.94, blue: 0.72), lineWidth: 1.4)
                }
                .shadow(color: .black.opacity(0.50), radius: 8, y: 4)
            }
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
