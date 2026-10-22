import SwiftUI

struct TopCommandBar: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 600
            HStack(spacing: compact ? 8 : 18) {
                CampaignPicker()
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
                EndTurnButton()
            }
            .padding(.horizontal, compact ? 10 : 18)
            .frame(height: 60)
        }
        .frame(height: 60)
        .background(BattlefieldTheme.commandDeckDeep)
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
                Image(systemName: "map.fill").foregroundStyle(BattlefieldTheme.brass)
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.scenario.name)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                    Text("\(game.scenario.year)  /  WESTERN FRONT")
                        .font(.system(size: 8, weight: .bold, design: .serif))
                        .tracking(1.2)
                        .foregroundStyle(BattlefieldTheme.brass)
                        .lineLimit(1)
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

    var body: some View {
        Button(action: game.endTurn) {
            VStack(spacing: 3) {
                Image(systemName: "forward.end.fill").font(.system(size: 16, weight: .bold))
                Text("结束回合").font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.13))
            .frame(width: 64, height: 46)
            .background(BattlefieldTheme.brass, in: RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
        .disabled(game.winner != nil)
        .accessibilityHint("结束当前阵营行动并推进战局")
    }
}

enum MapScaleMode: String, CaseIterable, Identifiable {
    case campaign, tactical, detail
    var id: String { rawValue }
    var title: String {
        switch self { case .campaign: "战役"; case .tactical: "战术"; case .detail: "细节" }
    }
    var scaleMultiplier: CGFloat {
        switch self { case .campaign: 1; case .tactical: 1.25; case .detail: 1.55 }
    }
}

struct BattlefieldView: View {
    @State private var mapScaleMode: MapScaleMode = .campaign
    var body: some View { MapCommandCenter(mapScaleMode: $mapScaleMode) }
}

struct MapCommandCenter: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var mapScaleMode: MapScaleMode
    @State private var isRosterExpanded = false
    @State private var isSupportExpanded = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 680
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        HexMapView(scaleMultiplier: mapScaleMode.scaleMultiplier, viewportHeight: geometry.size.height)
                    }
                    .onAppear { scrollToFocus(proxy, animated: false) }
                    .onChange(of: game.focusedCoordinate?.id) { _, _ in scrollToFocus(proxy, animated: true) }
                    .onChange(of: mapScaleMode) { _, _ in scrollToFocus(proxy, animated: true) }
                }

                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        objectiveBrief
                        Spacer(minLength: 6)
                        VStack(spacing: 6) {
                            scaleMenu
                            MapRestartButton()
                        }
                    }
                    .padding(10)
                    Spacer(minLength: 8)
                    VStack(spacing: 6) {
                        if isSupportExpanded {
                            supportPanel(maxHeight: geometry.size.height * 0.48)
                        }
                        if isRosterExpanded { ObjectiveJumpDock(compact: compact) }
                        if game.selectedUnit != nil { MapActionHUD(compact: compact) }
                        Text(game.message)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                            .background(BattlefieldTheme.commandDeckDeep.opacity(0.85))
                            .allowsHitTesting(false)
                        bottomTools(compact: compact)
                    }
                    .padding(.horizontal, compact ? 8 : 14)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(red: 0.46, green: 0.52, blue: 0.34))
        }
    }

    private var objectiveBrief: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "flag.fill").foregroundStyle(BattlefieldTheme.brass)
                Text("夺取战区据点").foregroundStyle(.white)
                Text("\(game.alliedScore)/\(game.objectiveTiles.count)").foregroundStyle(BattlefieldTheme.brass).monospacedDigit()
            }
            .font(.system(size: 12, weight: .bold))
            ProgressView(value: game.objectiveProgress).tint(BattlefieldTheme.brass)
        }
        .padding(10)
        .frame(width: 186)
        .background(BattlefieldTheme.commandDeckDeep.opacity(0.91), in: RoundedRectangle(cornerRadius: 3))
        .accessibilityElement(children: .combine)
    }

    private var scaleMenu: some View {
        Menu {
            Picker("地图缩放", selection: $mapScaleMode) {
                ForEach(MapScaleMode.allCases) { mode in Text(mode.title).tag(mode) }
            }
        } label: {
            Image(systemName: "plus.magnifyingglass")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(BattlefieldTheme.commandDeckDeep.opacity(0.94), in: RoundedRectangle(cornerRadius: 3))
        }
        .accessibilityLabel("地图缩放")
        .accessibilityValue(mapScaleMode.title)
    }

    private func bottomTools(compact: Bool) -> some View {
        HStack(spacing: 6) {
            edgeButton("编队 / 据点", icon: "square.grid.3x3.fill", selected: isRosterExpanded) { isRosterExpanded.toggle() }
            edgeButton("战术支援", icon: "shippingbox.fill", selected: isSupportExpanded) { isSupportExpanded.toggle() }
            Spacer(minLength: 0)
            Button(action: game.selectNextReadyUnitFromMap) {
                Label(compact ? "下一支" : "下一支待命部队", systemImage: "forward.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BattlefieldTheme.brass)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .background(BattlefieldTheme.commandDeckDeep, in: RoundedRectangle(cornerRadius: 3))
            }
            .buttonStyle(.plain)
            .disabled(game.readyUnits.isEmpty)
        }
    }

    private func edgeButton(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(selected ? BattlefieldTheme.brass : .white)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(BattlefieldTheme.commandDeckDeep, in: RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "已展开" : "已收起")
    }

    private func supportPanel(maxHeight: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForceRibbon()
                TacticalOrderStrip()
                ReinforcementDock()
                MapLegendView()
            }
            .padding(12)
        }
        .frame(maxHeight: maxHeight)
        .background(BattlefieldTheme.commandDeckDeep, in: RoundedRectangle(cornerRadius: 4))
    }

    private func scrollToFocus(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let coordinate = game.focusedCoordinate else { return }
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.22)) { proxy.scrollTo(coordinate.id, anchor: .center) }
        } else {
            proxy.scrollTo(coordinate.id, anchor: .center)
        }
    }
}

struct MapRestartButton: View {
    @EnvironmentObject private var game: GameState
    var body: some View {
        Button(action: game.restart) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(BattlefieldTheme.commandDeckDeep.opacity(0.94), in: RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("重新开始当前战役")
    }
}

struct MapActionHUD: View {
    @EnvironmentObject private var game: GameState
    let compact: Bool

    var body: some View {
        if let unit = game.selectedUnit {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    UnitModelView(kind: unit.kind, faction: unit.faction, isSpent: unit.hasMoved && unit.hasAttacked)
                        .frame(width: 58, height: 38)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(unit.name).font(.system(size: 13, weight: .bold)).lineLimit(1)
                        HStack(spacing: 8) {
                            Text("HP \(unit.hp)/\(unit.maxHP)").monospacedDigit()
                            Text(unit.hasMoved ? "移动已用" : "可移动").foregroundStyle(unit.hasMoved ? BattlefieldTheme.mutedInk : .cyan)
                            Text(unit.hasAttacked ? "攻击已用" : "可攻击").foregroundStyle(unit.hasAttacked ? BattlefieldTheme.mutedInk : BattlefieldTheme.brass)
                        }
                        .font(.system(size: 10, weight: .semibold))
                    }
                    Spacer(minLength: 0)
                    Button(action: game.waitSelectedUnit) {
                        Image(systemName: "pause.fill").frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("待命防御")
                    .disabled(unit.hasMoved && unit.hasAttacked)
                }
                HStack(spacing: 6) {
                    quick("攻击", icon: "scope", enabled: !game.attackableUnits(for: unit).isEmpty, action: game.focusNearestAttackTarget)
                    quick("接敌", icon: "arrow.up.right", enabled: game.nearestApproachTarget(for: unit) != nil, action: game.focusNearestApproachTarget)
                    quick("据点", icon: "flag.fill", enabled: game.nearestObjectiveTarget(for: unit) != nil, action: game.focusNearestObjectiveTarget)
                    if game.focusedCommandPreview?.isExecutable == true {
                        Button(action: game.executeFocusedCommand) {
                            Label("执行", systemImage: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(BattlefieldTheme.brass, in: RoundedRectangle(cornerRadius: 3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let preview = game.focusedCommandPreview, preview.isExecutable {
                    Text(MapCommandPreviewChrome.compactTitle(for: preview) + " · " + commandDetail(preview))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BattlefieldTheme.brass)
                        .lineLimit(2)
                }
            }
            .padding(10)
            .foregroundStyle(.white)
            .frame(maxWidth: compact ? .infinity : 520)
            .background(BattlefieldTheme.commandDeckDeep.opacity(0.96), in: RoundedRectangle(cornerRadius: 4))
            .overlay(alignment: .top) { Rectangle().fill(unit.faction.accentColor).frame(height: 2) }
        }
    }

    private func quick(_ title: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func commandDetail(_ preview: MapCommandPreview) -> String {
        switch preview {
        case let .attack(_, defender, damage, counter, hp, _):
            return "\(defender) −\(damage)，剩余 \(hp) HP，反击 −\(counter)"
        case let .move(_, _, route):
            return "移动消耗 \(route.totalCost)"
        default:
            return "预览不消耗行动，确认后执行"
        }
    }
}
