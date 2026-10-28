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

private enum BattlefieldDrawer { case roster, support }

struct MapCommandCenter: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var mapScaleMode: MapScaleMode
    @Binding var isInspectorExpanded: Bool
    @State private var drawer: BattlefieldDrawer?
    @State private var overviewVisibility: Bool?
    @State private var isFrontlineCamera = true

    var body: some View {
        GeometryReader { geometry in
            let viewport = BattlefieldViewport(size: geometry.size)
            let showsOverview = overviewVisibility ?? viewport.showsOverviewByDefault
            ScrollViewReader { proxy in
                ZStack {
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        HexMapView(scaleMultiplier: mapScaleMode.scaleMultiplier, viewportHeight: geometry.size.height)
                    }
                    .ignoresSafeArea()
                    .task(id: game.scenario.units.first?.id) {
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

                    VStack(spacing: 8) {
                        TopCommandBar(condensed: viewport.isShallow)
                        HStack(alignment: .top) {
                            if showsOverview {
                                BattlefieldOverviewMap(
                                    tiles: game.tiles, units: game.units, focusedCoordinate: game.focusedCoordinate,
                                    onFocus: { game.focus(coordinate: $0); scrollToFocus(proxy, animated: true) },
                                    onFrontline: { scrollToFrontline(proxy, animated: true) }
                                )
                            }
                            Spacer(minLength: 4)
                            BattlefieldMapTools(
                                scaleMode: $mapScaleMode, showsOverview: showsOverview,
                                condensed: viewport.isShallow,
                                isInspectorExpanded: $isInspectorExpanded,
                                toggleOverview: { overviewVisibility = !showsOverview }
                            )
                        }
                        Spacer(minLength: 0)
                        if let drawer {
                            BattlefieldDrawerPanel(drawer: drawer, maxHeight: geometry.size.height * 0.45,
                                                   close: { self.drawer = nil })
                        }
                        if game.selectedUnit != nil {
                            MapActionHUD(compact: viewport.compactControls, condensed: viewport.isShallow)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        BattlefieldBottomEdge(
                            condensed: viewport.isShallow, drawer: drawer,
                            toggleRoster: { toggleDrawer(.roster) }, toggleSupport: { toggleDrawer(.support) },
                            returnToFrontline: { scrollToFrontline(proxy, animated: true) }
                        )
                    }
                    .padding(.horizontal, viewport.isShallow ? 8 : 12)
                    .padding(.vertical, viewport.isShallow ? 6 : 10)
                }
                .background(Color(red: 0.46, green: 0.52, blue: 0.34).ignoresSafeArea())
            }
        }
    }

    private func toggleDrawer(_ requested: BattlefieldDrawer) {
        drawer = drawer == requested ? nil : requested
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
        if isFrontlineCamera { scrollToFrontline(proxy, animated: false) }
        else { scrollToFocus(proxy, animated: false) }
    }

    private func scroll(to targetID: String, proxy: ScrollViewProxy, animated: Bool) {
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.22)) { proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.42)) }
        } else {
            proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.42))
        }
    }
}

private struct BattlefieldMapTools: View {
    @Binding var scaleMode: MapScaleMode
    let showsOverview: Bool
    let condensed: Bool
    @Binding var isInspectorExpanded: Bool
    let toggleOverview: () -> Void

    var body: some View {
        let layout = condensed ? AnyLayout(HStackLayout(spacing: 4)) : AnyLayout(VStackLayout(spacing: 4))
        layout {
            Menu {
                Picker("地图缩放", selection: $scaleMode) {
                    ForEach(MapScaleMode.allCases) { mode in Text(mode.title).tag(mode) }
                }
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(BattlefieldTheme.fieldPaper)
                    .frame(width: 44, height: 44)
                    .background(FieldPlate())
            }
            .accessibilityLabel("地图缩放")
            .accessibilityValue(scaleMode.title)
            FieldControlButton(title: "战区总览", icon: "map", selected: showsOverview, action: toggleOverview)
            FieldControlButton(title: "战场情报", icon: "binoculars.fill", selected: isInspectorExpanded) { isInspectorExpanded.toggle() }
            MapRestartButton()
        }
    }
}

private struct BattlefieldBottomEdge: View {
    @EnvironmentObject private var game: GameState
    let condensed: Bool
    let drawer: BattlefieldDrawer?
    let toggleRoster: () -> Void
    let toggleSupport: () -> Void
    let returnToFrontline: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Circle().fill(BattlefieldTheme.signal).frame(width: 4, height: 4)
                    Text(game.message).font(.system(size: 10, weight: .medium)).lineLimit(1)
                }
                .foregroundStyle(BattlefieldTheme.fieldPaper)
                .padding(.horizontal, 9).padding(.vertical, condensed ? 3 : 6)
                .background(BattlefieldTheme.commandDeckDeep.opacity(0.82), in: BeveledFieldShape())
                .allowsHitTesting(false)
                HStack(spacing: 5) {
                    FieldControlButton(title: "编队与据点定位", icon: "square.grid.3x3.fill", selected: drawer == .roster, action: toggleRoster)
                    FieldControlButton(title: "战术支援", icon: "shippingbox.fill", selected: drawer == .support, action: toggleSupport)
                    FieldControlButton(title: "返回交战前线", icon: "viewfinder", isToggle: false, action: returnToFrontline)
                        .accessibilityHint("只移动镜头，不改变选择或执行指令")
                    FieldControlButton(title: "下一支待命部队", icon: "forward.fill", isToggle: false, action: game.selectNextReadyUnitFromMap)
                        .disabled(game.readyUnits.isEmpty)
                }
            }
            .frame(maxWidth: condensed ? 240 : 450, alignment: .leading)
            Spacer(minLength: 0)
            EndTurnButton(condensed: condensed)
        }
    }
}

private struct BattlefieldDrawerPanel: View {
    let drawer: BattlefieldDrawer
    let maxHeight: CGFloat
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(drawer == .roster ? "编队 / 据点" : "战术支援").font(.system(size: 12, weight: .bold))
                Spacer()
                Button(action: close) { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .buttonStyle(.plain).accessibilityLabel("收起地图面板")
            }
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .padding(.leading, 12)
            ScrollView {
                if drawer == .roster {
                    ObjectiveJumpDock(compact: false)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForceRibbon()
                        TacticalOrderStrip()
                        ReinforcementDock()
                        MapLegendView()
                    }.padding(12)
                }
            }
        }
        .frame(maxHeight: maxHeight)
        .background(FieldPlate(emphasized: true))
    }
}

struct MapRestartButton: View {
    @EnvironmentObject private var game: GameState
    var body: some View {
        FieldControlButton(title: "重新开始当前战役", icon: "arrow.clockwise", isToggle: false, action: game.restart)
    }
}
