import SwiftUI

/// EasyTech World Conqueror 4 / Glory of Generals 3 Quartermaster Store:
/// Offline simulated supply packs, honor medal equipment, and usable battlefield consumables.
struct BattlefieldQuartermasterModal: View {
    @EnvironmentObject private var game: GameState
    let close: () -> Void
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            header
                .zIndex(2)
            Rectangle().fill(BattlefieldTheme.brass.opacity(0.4)).frame(height: 1)

            HStack(spacing: 8) {
                tabButton(0, title: "战备礼盒 · 补给", icon: "gift.fill")
                tabButton(1, title: "将领勋章装备", icon: "medal.fill")
                tabButton(2, title: "野战补给物品", icon: "cross.case.fill")
                Spacer()
                Text("原型离线模拟军需 · 无真实扣费")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(BattlefieldTheme.brass)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(BattlefieldTheme.brass.opacity(0.14), in: Capsule())
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.black.opacity(0.24))

            ScrollView {
                switch selectedTab {
                case 0:
                    offersGrid
                case 1:
                    medalsShopGrid
                default:
                    itemsShopGrid
                }
            }
            .padding(12)
        }
        .background { FieldPlate(emphasized: true, material: .brassDossier) }
        .clipShape(BeveledFieldShape())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("battlefield-shop-modal")
    }

    private var header: some View {
        HStack(spacing: 10) {
            if let chest = BattlefieldArtwork.shopIcon(.warChest) {
                BattlefieldArtwork.image(chest).resizable().interpolation(.high).scaledToFit()
                    .frame(width: 34, height: 34)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("军需商城与战备仓库")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                Text("QUARTERMASTER EXCHANGE & FIELD ARMORY")
                    .font(BattlefieldTheme.militaryFont(10)).tracking(1.4)
                    .foregroundStyle(BattlefieldTheme.brass)
            }
            Spacer()
            HStack(spacing: 8) {
                currencyChip(icon: .gold, value: game.warResources.gold, color: BattlefieldTheme.selectedPiece)
                currencyChip(icon: .industry, value: game.warResources.industry, color: Color(red: 0.74, green: 0.82, blue: 0.88))
                currencyChip(icon: .medal, value: game.warResources.honorMedals, color: Color(red: 1.0, green: 0.78, blue: 0.34))
            }
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭军需商城")
            .accessibilityIdentifier("battlefield-shop-close")
        }
        .padding(.leading, 14).padding(.trailing, 6)
        .frame(height: 54)
    }

    private func currencyChip(icon: BattlefieldResourceIcon, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            if let img = BattlefieldArtwork.resourceIcon(icon) {
                BattlefieldArtwork.image(img).resizable().scaledToFit().frame(width: 16, height: 16)
            }
            Text("\(value)").font(BattlefieldTheme.militaryFont(16)).foregroundStyle(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.black.opacity(0.32), in: BeveledFieldShape(cornerCut: 4))
    }

    private func tabButton(_ index: Int, title: String, icon: String) -> some View {
        let active = selectedTab == index
        return Button { selectedTab = index } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(active ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.fieldPaper)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(active ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                            in: BeveledFieldShape(cornerCut: 4))
        }
        .buttonStyle(.plain)
    }

    private var offersGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 10)], spacing: 10) {
            ForEach(QuartermasterOffer.catalog) { offer in
                let disabled = offer.isDailyFree && game.claimedDailySupply
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        if let art = BattlefieldArtwork.shopIcon(offer.isDailyFree ? .fieldMedkit : .warChest) {
                            BattlefieldArtwork.image(art).resizable().interpolation(.high).scaledToFit()
                                .frame(width: 52, height: 52)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(offer.title)
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                                Text(offer.tag)
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(BattlefieldTheme.selectedPiece, in: Capsule())
                            }
                            Text(offer.subtitle)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(BattlefieldTheme.mutedInk)
                                .lineLimit(2)
                        }
                    }

                    HStack(spacing: 10) {
                        rewardLabel("勋章 +\(offer.honorMedals)", color: BattlefieldTheme.selectedPiece)
                        rewardLabel("金币 +\(offer.gold)", color: BattlefieldTheme.fieldPaper)
                        rewardLabel("工业 +\(offer.industry)", color: Color(red: 0.74, green: 0.82, blue: 0.88))
                        if let bonusMedal = offer.bonusMedal {
                            rewardLabel("+\(bonusMedal.title)", color: BattlefieldTheme.signal)
                        }
                    }

                    Button {
                        game.claimQuartermasterOffer(offer)
                    } label: {
                        Text(disabled ? "本场战役已领取" : offer.priceLabel)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(disabled ? BattlefieldTheme.mutedInk : BattlefieldTheme.commandDeckDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(disabled ? AnyShapeStyle(Color.white.opacity(0.08)) : AnyShapeStyle(BattlefieldTheme.actionBrass),
                                        in: BeveledFieldShape(cornerCut: 5))
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                }
                .padding(11)
                .background(FieldPlate(emphasized: !disabled && !offer.isDailyFree, material: .gunmetal, showsRivets: false))
            }
        }
    }

    private var medalsShopGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], spacing: 10) {
            ForEach(EquipmentMedal.allCases) { medal in
                let owned = game.ownedMedals[medal, default: 0]
                let affordable = game.warResources.honorMedals >= medal.medalCost
                HStack(spacing: 10) {
                    if let art = BattlefieldArtwork.shopIcon(medal == .panzerShield ? .panzerShield : .heroCross) {
                        BattlefieldArtwork.image(art).resizable().scaledToFit().frame(width: 48, height: 48)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(medal.title).font(.system(size: 13, weight: .bold)).foregroundStyle(BattlefieldTheme.fieldPaper)
                            Spacer()
                            Text("已拥有 \(owned)").font(.system(size: 10, weight: .bold)).foregroundStyle(BattlefieldTheme.signal)
                        }
                        Text(medal.effectText).font(.system(size: 10, weight: .semibold)).foregroundStyle(BattlefieldTheme.selectedPiece)
                        HStack(spacing: 6) {
                            Button {
                                game.buyMedal(medal)
                            } label: {
                                Text("兑换 \(medal.medalCost) 勋章")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(affordable ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.mutedInk)
                                    .padding(.horizontal, 9).padding(.vertical, 5)
                                    .background(affordable ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                                in: BeveledFieldShape(cornerCut: 4))
                            }
                            .buttonStyle(.plain)
                            .disabled(!affordable)

                            if owned > 0, let unit = game.selectedUnit, unit.faction == .allies {
                                Button {
                                    game.equipMedal(medal, to: unit.id)
                                } label: {
                                    Text("立即佩戴")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                                        .padding(.horizontal, 8).padding(.vertical, 5)
                                        .background(BattlefieldTheme.alliesRing.opacity(0.32), in: BeveledFieldShape(cornerCut: 4))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(10)
                .background(FieldPlate(material: .gunmetal, showsRivets: false))
            }
        }
    }

    private var itemsShopGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], spacing: 10) {
            ForEach(FieldSupplyItem.allCases) { item in
                let owned = game.ownedFieldItems[item, default: 0]
                let affordable = game.warResources.gold >= item.goldCost
                HStack(spacing: 10) {
                    if let art = BattlefieldArtwork.shopIcon(item == .fieldMedkit ? .fieldMedkit : .warChest) {
                        BattlefieldArtwork.image(art).resizable().scaledToFit().frame(width: 46, height: 46)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(item.title).font(.system(size: 13, weight: .bold)).foregroundStyle(BattlefieldTheme.fieldPaper)
                            Spacer()
                            Text("库存 \(owned)").font(.system(size: 10, weight: .bold)).foregroundStyle(BattlefieldTheme.signal)
                        }
                        Text(item.effectText).font(.system(size: 10, weight: .medium)).foregroundStyle(BattlefieldTheme.mutedInk)
                        HStack(spacing: 6) {
                            Button {
                                game.buyFieldItem(item)
                            } label: {
                                Text("购买 \(item.goldCost) 金币")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(affordable ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.mutedInk)
                                    .padding(.horizontal, 9).padding(.vertical, 5)
                                    .background(affordable ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                                in: BeveledFieldShape(cornerCut: 4))
                            }
                            .buttonStyle(.plain)
                            .disabled(!affordable)

                            if owned > 0 {
                                Button {
                                    game.useFieldItem(item)
                                } label: {
                                    Text("战地使用")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                                        .padding(.horizontal, 8).padding(.vertical, 5)
                                        .background(Color.green.opacity(0.32), in: BeveledFieldShape(cornerCut: 4))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(10)
                .background(FieldPlate(material: .gunmetal, showsRivets: false))
            }
        }
    }

    private func rewardLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
    }
}
