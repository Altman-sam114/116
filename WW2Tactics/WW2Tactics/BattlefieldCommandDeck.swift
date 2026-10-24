import SwiftUI

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
    @Binding var isInspectorExpanded: Bool
    @State private var mapScaleMode: MapScaleMode = .campaign
    var body: some View {
        MapCommandCenter(mapScaleMode: $mapScaleMode, isInspectorExpanded: $isInspectorExpanded)
    }
}

struct MapCommandCenter: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var mapScaleMode: MapScaleMode
    @Binding var isInspectorExpanded: Bool
    @State private var isRosterExpanded = false
    @State private var isSupportExpanded = false
    @State private var overviewVisibility: Bool?
    @State private var isFrontlineCamera = true

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 680
            let showsOverview = overviewVisibility ?? !compact
            ScrollViewReader { proxy in
                ZStack {
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        HexMapView(scaleMultiplier: mapScaleMode.scaleMultiplier, viewportHeight: geometry.size.height)
                    }
                    .task(id: game.scenario.units.first?.id) {
                        // A reload gives the opening roster fresh IDs; ordinary movement retains them.
                        await Task.yield()
                        guard !Task.isCancelled else { return }
                        scrollToOpening(proxy)
                    }
                    .onChange(of: game.focusedCoordinate?.id) { _, _ in scrollToFocus(proxy, animated: true) }
                    .onChange(of: game.selectedUnitID) { _, selectedID in
                        if selectedID != nil { scrollToFocus(proxy, animated: true) }
                    }
                    .onChange(of: game.latestCombatResult?.id) { _, _ in scrollToFocus(proxy, animated: true) }
                    .onChange(of: mapScaleMode) { _, _ in scrollToCurrentCamera(proxy) }
                    .onChange(of: geometry.size) { _, _ in scrollToCurrentCamera(proxy) }

                    VStack(spacing: 0) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                objectiveBrief
                                if showsOverview {
                                    BattlefieldOverviewMap(
                                        tiles: game.tiles, units: game.units, focusedCoordinate: game.focusedCoordinate,
                                        onFocus: {
                                            game.focus(coordinate: $0)
                                            scrollToFocus(proxy, animated: true)
                                        },
                                        onFrontline: { scrollToFrontline(proxy, animated: true) }
                                    )
                                }
                            }
                            Spacer(minLength: 6)
                            VStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    scaleMenu
                                    mapTool("战区总览", icon: "map", selected: showsOverview) { overviewVisibility = !showsOverview }
                                }
                                HStack(spacing: 6) {
                                    MapRestartButton()
                                    mapTool("战场情报", icon: "binoculars.fill", selected: isInspectorExpanded) { isInspectorExpanded.toggle() }
                                }
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
                            bottomTools(compact: compact) { scrollToFrontline(proxy, animated: true) }
                        }
                        .padding(.horizontal, compact ? 8 : 14)
                        .padding(.bottom, 8)
                    }
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
        .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
        .overlay { RoundedRectangle(cornerRadius: 3).stroke(BattlefieldTheme.brass.opacity(0.34), lineWidth: 0.8) }
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
                .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
                .overlay { RoundedRectangle(cornerRadius: 3).stroke(BattlefieldTheme.brass.opacity(0.34), lineWidth: 0.8) }
        }
        .accessibilityLabel("地图缩放")
        .accessibilityValue(mapScaleMode.title)
    }

    private func mapTool(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(selected ? BattlefieldTheme.brass : .white)
                .frame(width: 44, height: 44)
                .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
                .overlay { RoundedRectangle(cornerRadius: 3).stroke(BattlefieldTheme.brass.opacity(0.34), lineWidth: 0.8) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(selected ? "已展开" : "已收起")
    }

    private func bottomTools(compact: Bool, returnToFrontline: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            edgeButton(compact ? "编队" : "编队 / 据点", icon: "square.grid.3x3.fill", selected: isRosterExpanded) { isRosterExpanded.toggle() }
                .accessibilityLabel("编队与据点定位")
            edgeButton(compact ? "支援" : "战术支援", icon: "shippingbox.fill", selected: isSupportExpanded) { isSupportExpanded.toggle() }
                .accessibilityLabel("战术支援")
            Spacer(minLength: 0)
            Button(action: returnToFrontline) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(BattlefieldTheme.brass)
                    .frame(width: 44, height: 44)
                    .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回交战前线")
            .accessibilityHint("只移动镜头，不改变选择或执行指令")
            Button(action: game.selectNextReadyUnitFromMap) {
                Label(compact ? "下一支" : "下一支待命部队", systemImage: "forward.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BattlefieldTheme.brass)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
                    .overlay { RoundedRectangle(cornerRadius: 3).stroke(BattlefieldTheme.brass.opacity(0.32), lineWidth: 0.8) }
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
                .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
                .overlay { RoundedRectangle(cornerRadius: 3).stroke(BattlefieldTheme.brass.opacity(0.26), lineWidth: 0.8) }
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
        isFrontlineCamera = false
        let targetID: String
        if let result = game.latestCombatResult,
           coordinate == result.attackerCoordinate || coordinate == result.defenderCoordinate {
            targetID = "combat-\(result.id)"
        } else {
            targetID = coordinate.id
        }
        scroll(to: targetID, proxy: proxy, animated: animated)
    }

    private func scrollToOpening(_ proxy: ScrollViewProxy) {
        if game.selectedUnit == nil && game.latestCombatResult == nil {
            scrollToFrontline(proxy, animated: false)
        } else {
            scrollToFocus(proxy, animated: false)
        }
    }

    private func scrollToFrontline(_ proxy: ScrollViewProxy, animated: Bool) {
        isFrontlineCamera = true
        scroll(to: "battlefield-frontline", proxy: proxy, animated: animated)
    }

    private func scrollToCurrentCamera(_ proxy: ScrollViewProxy) {
        if isFrontlineCamera {
            scrollToFrontline(proxy, animated: false)
        } else {
            scrollToFocus(proxy, animated: false)
        }
    }

    private func scroll(to targetID: String, proxy: ScrollViewProxy, animated: Bool) {
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.22)) { proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.42)) }
        } else {
            proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.42))
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
                .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
                .overlay { RoundedRectangle(cornerRadius: 3).stroke(BattlefieldTheme.brass.opacity(0.34), lineWidth: 0.8) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("重新开始当前战役")
    }
}
