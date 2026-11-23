import SwiftUI

/// EasyTech World Conqueror 4 / Glory of Generals 3 style Generals HQ & Medal Equipment Dossier.
struct BattlefieldGeneralsModal: View {
    @EnvironmentObject private var game: GameState
    let close: () -> Void
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            modalHeader
                .zIndex(2)
            Rectangle().fill(BattlefieldTheme.brass.opacity(0.4)).frame(height: 1)

            HStack(spacing: 8) {
                tabButton(index: 0, title: "名将招募与委任", icon: "star.circle.fill")
                tabButton(index: 1, title: "勋章佩戴（仓库）", icon: "medal.fill")
                Spacer()
                if let unit = game.selectedUnit, unit.faction == .allies {
                    HStack(spacing: 5) {
                        Image(systemName: "scope").foregroundStyle(BattlefieldTheme.selectedPiece)
                        Text("当前选中：\(unit.name)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(BattlefieldTheme.fieldPaper)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.32), in: BeveledFieldShape(cornerCut: 4))
                } else {
                    Text("提示：在地图点选己方部队后可直接委任将领或佩戴勋章")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.22))

            ScrollView {
                if selectedTab == 0 {
                    generalsGrid
                } else {
                    medalsGrid
                }
            }
            .padding(12)
        }
        .background { FieldPlate(emphasized: true, material: .brassDossier) }
        .clipShape(BeveledFieldShape())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("battlefield-generals-modal")
    }

    private var modalHeader: some View {
        HStack(spacing: 10) {
            if let crest = BattlefieldArtwork.emblem(.hqLaurel) {
                BattlefieldArtwork.image(crest)
                    .resizable().interpolation(.high).scaledToFit()
                    .frame(width: 34, height: 34)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("最高统帅部 · 名将名录")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                Text("SUPREME COMMAND HEADQUARTERS")
                    .font(BattlefieldTheme.militaryFont(10)).tracking(1.6)
                    .foregroundStyle(BattlefieldTheme.brass)
            }
            Spacer()
            HStack(spacing: 6) {
                if let icon = BattlefieldArtwork.resourceIcon(.medal) {
                    BattlefieldArtwork.image(icon).resizable().scaledToFit().frame(width: 20, height: 20)
                }
                Text("\(game.warResources.honorMedals)")
                    .font(BattlefieldTheme.militaryFont(18))
                    .foregroundStyle(BattlefieldTheme.selectedPiece)
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.black.opacity(0.35), in: BeveledFieldShape(cornerCut: 4))

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭将领统帅部")
            .accessibilityIdentifier("battlefield-generals-close")
        }
        .padding(.leading, 14).padding(.trailing, 6)
        .frame(height: 54)
    }

    private func tabButton(index: Int, title: String, icon: String) -> some View {
        let active = selectedTab == index
        return Button { selectedTab = index } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(active ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.fieldPaper)
                .padding(.horizontal, 11).padding(.vertical, 6)
                .background(active ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                            in: BeveledFieldShape(cornerCut: 4))
        }
        .buttonStyle(.plain)
    }

    private var generalsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 248), spacing: 10)], spacing: 10) {
            ForEach(Commander.hqAlliedCatalog) { commander in
                GeneralDossierCard(commander: commander)
            }
        }
    }

    private var medalsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
            ForEach(EquipmentMedal.allCases) { medal in
                MedalEquipCard(medal: medal)
            }
        }
    }
}

private struct GeneralDossierCard: View {
    @EnvironmentObject private var game: GameState
    let commander: Commander

    var body: some View {
        let recruited = game.isCommanderRecruited(commander)
        let deployedUnit = game.assignedUnit(for: commander)
        let canAssign = recruited && deployedUnit == nil && game.selectedUnit?.faction == .allies && game.selectedUnit?.commander == nil

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                CommanderPortrait(commander: commander, faction: .allies)
                    .frame(width: 54, height: 62)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(commander.name)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundStyle(BattlefieldTheme.fieldPaper)
                        Text(commander.rank)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(BattlefieldTheme.selectedPiece)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(BattlefieldTheme.brass.opacity(0.18), in: Capsule())
                    }
                    Text("\(commander.nation) · \(commander.specialtyTitle)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.mutedInk)

                    HStack(spacing: 8) {
                        statPill("装甲", value: commander.armor)
                        statPill("战术", value: commander.tactics)
                        statPill("士气", value: commander.morale)
                    }
                }
                Spacer(minLength: 0)
            }

            Text(commander.trait)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BattlefieldTheme.fieldPaper.opacity(0.9))
                .lineLimit(2)

            HStack {
                if let deployedUnit {
                    Label("在阵：\(deployedUnit.name)", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(BattlefieldTheme.signal)
                    Spacer()
                } else if recruited {
                    Label("已招募 · 待委任", systemImage: "person.fill.checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(BattlefieldTheme.selectedPiece)
                    Spacer()
                    Button {
                        if let unit = game.selectedUnit {
                            game.assignCommander(commander, to: unit.id)
                        }
                    } label: {
                        Text(canAssign ? "委任上阵" : "先选无将部队")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(canAssign ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.mutedInk)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(canAssign ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                        in: BeveledFieldShape(cornerCut: 4))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAssign)
                } else {
                    HStack(spacing: 4) {
                        if let icon = BattlefieldArtwork.resourceIcon(.medal) {
                            BattlefieldArtwork.image(icon).resizable().scaledToFit().frame(width: 15, height: 15)
                        }
                        Text("\(commander.recruitMedalCost)")
                            .font(BattlefieldTheme.militaryFont(15))
                            .foregroundStyle(BattlefieldTheme.selectedPiece)
                    }
                    Spacer()
                    let affordable = game.warResources.honorMedals >= commander.recruitMedalCost
                    Button {
                        game.recruitCommander(commander)
                    } label: {
                        Text("招募名将")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(affordable ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.mutedInk)
                            .padding(.horizontal, 11).padding(.vertical, 6)
                            .background(affordable ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                        in: BeveledFieldShape(cornerCut: 4))
                    }
                    .buttonStyle(.plain)
                    .disabled(!affordable)
                }
            }
        }
        .padding(10)
        .background(FieldPlate(emphasized: recruited, material: .gunmetal, showsRivets: false))
    }

    private func statPill(_ title: String, value: Int) -> some View {
        HStack(spacing: 2) {
            Text(title).font(.system(size: 8, weight: .semibold)).foregroundStyle(BattlefieldTheme.mutedInk)
            Text(String(repeating: "★", count: min(5, max(1, value))))
                .font(.system(size: 8))
                .foregroundStyle(BattlefieldTheme.selectedPiece)
        }
    }
}

private struct MedalEquipCard: View {
    @EnvironmentObject private var game: GameState
    let medal: EquipmentMedal

    var body: some View {
        let count = game.ownedMedals[medal, default: 0]
        let canEquip = count > 0 && game.selectedUnit?.faction == .allies

        HStack(spacing: 10) {
            if let icon = BattlefieldArtwork.shopIcon(medal == .panzerShield ? .panzerShield : .heroCross) {
                BattlefieldArtwork.image(icon).resizable().interpolation(.high).scaledToFit()
                    .frame(width: 44, height: 44)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(medal.title).font(.system(size: 13, weight: .bold)).foregroundStyle(BattlefieldTheme.fieldPaper)
                    Spacer()
                    Text("库存 \(count)").font(BattlefieldTheme.militaryFont(13))
                        .foregroundStyle(count > 0 ? BattlefieldTheme.signal : BattlefieldTheme.mutedInk)
                }
                Text(medal.effectText).font(.system(size: 10, weight: .semibold)).foregroundStyle(BattlefieldTheme.selectedPiece)
                Button {
                    if let unit = game.selectedUnit {
                        game.equipMedal(medal, to: unit.id)
                    }
                } label: {
                    Text(canEquip ? "佩戴给选中部队" : (count == 0 ? "商城可兑换" : "请先选择己方部队"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(canEquip ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.mutedInk)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(canEquip ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                    in: BeveledFieldShape(cornerCut: 4))
                }
                .buttonStyle(.plain)
                .disabled(!canEquip)
            }
        }
        .padding(10)
        .background(FieldPlate(emphasized: count > 0, material: .gunmetal, showsRivets: false))
    }
}
