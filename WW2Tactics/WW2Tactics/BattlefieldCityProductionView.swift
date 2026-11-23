import SwiftUI

/// GoG3-style horizontal troop production strip embedded inside the bottom City Production drawer.
struct BattlefieldCityProductionStrip: View {
    @EnvironmentObject private var game: GameState
    @State private var selectedCityCoordinate: HexCoordinate?
    let onOpenFullModal: () -> Void

    private var activeCity: TerrainTile? {
        if let coord = selectedCityCoordinate,
           let match = game.controlledAlliedCities.first(where: { $0.coordinate == coord }) {
            return match
        }
        if let focused = game.focusedTile, focused.isObjective, focused.owner == .allies {
            return focused
        }
        return game.controlledAlliedCities.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if game.controlledAlliedCities.isEmpty {
                Text("暂无己方控制城市，请先占领地图战略据点。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BattlefieldTheme.mutedInk)
                    .padding(12)
            } else {
                // Controlled City selector ribbon
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(game.controlledAlliedCities) { city in
                            let selected = city.coordinate == activeCity?.coordinate
                            let facility = game.cityFacility(at: city.coordinate)
                            let income = game.cityIncome(at: city.coordinate)
                            Button {
                                selectedCityCoordinate = city.coordinate
                                game.focus(coordinate: city.coordinate)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(selected ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.selectedPiece)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("\(city.objectiveName ?? "据点") Lv.\(facility.visualTier)")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("+\(income.gold)金 +\(income.industry)工")
                                            .font(.system(size: 9, weight: .semibold))
                                            .opacity(0.85)
                                    }
                                }
                                .foregroundStyle(selected ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.fieldPaper)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(selected ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                            in: BeveledFieldShape(cornerCut: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // GoG3-style horizontal production cards with painted unit artwork
                if let city = activeCity {
                    let hasSpawnSpace = game.productionSpawnCoordinate(for: city.coordinate) != nil
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CityProductionOption.alliedCatalog) { option in
                                ProductionUnitCard(option: option, city: city, hasSpawnSpace: hasSpawnSpace)
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
    }
}

private struct ProductionUnitCard: View {
    @EnvironmentObject private var game: GameState
    let option: CityProductionOption
    let city: TerrainTile
    let hasSpawnSpace: Bool

    var body: some View {
        let affordable = game.warResources.gold >= option.goldCost && game.warResources.industry >= option.industryCost
        let enabled = affordable && hasSpawnSpace && game.winner == nil

        Button {
            game.produceUnit(option: option, at: city.coordinate)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    UnitModelView(
                        kind: option.kind,
                        faction: .allies,
                        isSpent: !enabled,
                        variant: variantForOption
                    )
                    .frame(width: 78, height: 48)

                    if option.isElite {
                        Text("王牌")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(BattlefieldTheme.selectedPiece, in: Capsule())
                    }
                }

                Text(option.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    costBadge(icon: BattlefieldArtwork.resourceIcon(.gold), value: option.goldCost, color: BattlefieldTheme.selectedPiece)
                    costBadge(icon: BattlefieldArtwork.resourceIcon(.industry), value: option.industryCost, color: Color(red: 0.74, green: 0.82, blue: 0.88))
                }
            }
            .padding(7)
            .frame(width: 112)
            .background(FieldPlate(emphasized: option.isElite && enabled, material: .gunmetal, showsRivets: false))
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel("在\(city.objectiveName ?? "城市")生产\(option.title)，消耗\(option.goldCost)金币和\(option.industryCost)工业")
    }

    private var variantForOption: BattlefieldVehicleVariant? {
        if option.title.contains("M10") { return .tankDestroyer }
        if option.title.contains("M7") { return .priest }
        if option.title.contains("重装突击") { return .pershing }
        return nil
    }

    private func costBadge(icon: CGImage?, value: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            if let icon {
                BattlefieldArtwork.image(icon).resizable().scaledToFit().frame(width: 11, height: 11)
            }
            Text("\(value)")
                .font(BattlefieldTheme.militaryFont(12))
                .foregroundStyle(color)
        }
    }
}

/// Full-landscape EasyTech City Construction & Production Command Modal.
struct BattlefieldCityHQModal: View {
    @EnvironmentObject private var game: GameState
    let close: () -> Void
    @State private var selectedCityCoordinate: HexCoordinate?

    private var activeCity: TerrainTile? {
        if let coord = selectedCityCoordinate,
           let match = game.controlledAlliedCities.first(where: { $0.coordinate == coord }) {
            return match
        }
        return game.controlledAlliedCities.first
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if let gear = BattlefieldArtwork.resourceIcon(.industry) {
                    BattlefieldArtwork.image(gear).resizable().scaledToFit().frame(width: 30, height: 30)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("战略城市建设与兵工厂")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                    Text("CITY INFRASTRUCTURE & ARMORED PRODUCTION")
                        .font(BattlefieldTheme.militaryFont(10)).tracking(1.4)
                        .foregroundStyle(BattlefieldTheme.brass)
                }
                Spacer()
                HStack(spacing: 10) {
                    resourcePill(icon: .gold, value: game.warResources.gold, color: BattlefieldTheme.selectedPiece)
                    resourcePill(icon: .industry, value: game.warResources.industry, color: Color(red: 0.74, green: 0.82, blue: 0.88))
                }
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(BattlefieldTheme.fieldPaper)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭城市建设")
            }
            .padding(.leading, 14).padding(.trailing, 6)
            .frame(height: 54)

            Rectangle().fill(BattlefieldTheme.brass.opacity(0.4)).frame(height: 1)

            if let city = activeCity {
                let facility = game.cityFacility(at: city.coordinate)
                let income = game.cityIncome(at: city.coordinate)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // City switcher
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(game.controlledAlliedCities) { item in
                                    let isSelected = item.coordinate == city.coordinate
                                    Button {
                                        selectedCityCoordinate = item.coordinate
                                        game.focus(coordinate: item.coordinate)
                                    } label: {
                                        Text("\(item.objectiveName ?? "据点") (Lv.\(game.cityFacility(at: item.coordinate).visualTier))")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(isSelected ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.fieldPaper)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(isSelected ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                                        in: BeveledFieldShape(cornerCut: 4))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // City Facilities Upgrade Row
                        HStack(spacing: 8) {
                            Text("当前产能：每回合 +\(income.gold) 金币 · +\(income.industry) 工业 · 工事防御 +\(facility.fortificationDefenseBonus)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(BattlefieldTheme.selectedPiece)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(CityFacilityKind.allCases) { kind in
                                facilityCard(kind: kind, city: city, facility: facility)
                            }
                        }

                        Text("前线兵工厂造兵")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BattlefieldTheme.brass)

                        let hasSpawnSpace = game.productionSpawnCoordinate(for: city.coordinate) != nil
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(CityProductionOption.alliedCatalog) { option in
                                    ProductionUnitCard(option: option, city: city, hasSpawnSpace: hasSpawnSpace)
                                }
                            }
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background { FieldPlate(emphasized: true, material: .brassDossier) }
        .clipShape(BeveledFieldShape())
    }

    private func facilityCard(kind: CityFacilityKind, city: TerrainTile, facility: CityFacilityState) -> some View {
        let level = facility.level(for: kind)
        let isMax = level >= CityFacilityState.maxLevel
        let cost = kind.upgradeCost(from: level)
        let affordable = !isMax && game.warResources.gold >= cost.gold && game.warResources.industry >= cost.industry

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(kind.title).font(.system(size: 13, weight: .bold)).foregroundStyle(BattlefieldTheme.fieldPaper)
                Spacer()
                Text("Lv.\(level)/\(CityFacilityState.maxLevel)")
                    .font(BattlefieldTheme.militaryFont(14))
                    .foregroundStyle(BattlefieldTheme.selectedPiece)
            }
            Text(kind.effectSummary)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(2)

            Spacer(minLength: 2)

            Button {
                game.upgradeCityFacility(kind, at: city.coordinate)
            } label: {
                Text(isMax ? "已升至满级" : "升级（\(cost.gold)金 \(cost.industry)工）")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(affordable ? BattlefieldTheme.commandDeckDeep : BattlefieldTheme.mutedInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(affordable ? AnyShapeStyle(BattlefieldTheme.actionBrass) : AnyShapeStyle(Color.white.opacity(0.08)),
                                in: BeveledFieldShape(cornerCut: 4))
            }
            .buttonStyle(.plain)
            .disabled(!affordable)
        }
        .padding(10)
        .background(FieldPlate(material: .gunmetal, showsRivets: false))
    }

    private func resourcePill(icon: BattlefieldResourceIcon, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            if let img = BattlefieldArtwork.resourceIcon(icon) {
                BattlefieldArtwork.image(img).resizable().scaledToFit().frame(width: 16, height: 16)
            }
            Text("\(value)").font(BattlefieldTheme.militaryFont(16)).foregroundStyle(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.black.opacity(0.32), in: BeveledFieldShape(cornerCut: 4))
    }
}
