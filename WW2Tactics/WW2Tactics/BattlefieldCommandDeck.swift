import SwiftUI

enum MapScaleMode: String, CaseIterable, Identifiable {
    case campaign, tactical, detail
    var id: String { rawValue }
    var title: String {
        switch self { case .campaign: "战役"; case .tactical: "战术"; case .detail: "细节" }
    }
    var scaleMultiplier: CGFloat {
        switch self { case .campaign: 0.78; case .tactical: 1; case .detail: 1.25 }
    }
}

struct BattlefieldView: View {
    @Binding var isInspectorExpanded: Bool
    @State private var mapScaleMode: MapScaleMode = .tactical

    var body: some View {
        MapCommandCenter(mapScaleMode: $mapScaleMode, isInspectorExpanded: $isInspectorExpanded)
    }
}

enum BattlefieldDrawer { case roster, support }

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
                    battlefield(proxy: proxy, size: geometry.size)
                    BattlefieldEdgeShade()
                    VStack(spacing: viewport.isShallow ? 5 : 9) {
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
                                condensed: viewport.isShallow, isInspectorExpanded: $isInspectorExpanded,
                                toggleOverview: { overviewVisibility = !showsOverview }
                            )
                        }
                        Spacer(minLength: 0)
                        if let drawer {
                            BattlefieldDrawerPanel(drawer: drawer, maxHeight: geometry.size.height * 0.45,
                                                   close: { self.drawer = nil })
                        }
                        if game.selectedUnit != nil {
                            MapActionHUD(compact: viewport.compactControls, condensed: viewport.isShallow,
                                         inlineOrders: BattlefieldHUDLayout(size: geometry.size).inlineOrders)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        BattlefieldBottomEdge(
                            condensed: viewport.isShallow, drawer: drawer,
                            toggleRoster: { toggleDrawer(.roster) }, toggleSupport: { toggleDrawer(.support) },
                            returnToFrontline: { scrollToFrontline(proxy, animated: true) }
                        )
                    }
                    .padding(.horizontal, viewport.isShallow ? 8 : 12)
                    .padding(.vertical, viewport.isShallow ? 4 : 8)
                    .zIndex(1)
                }
                .background(BattlefieldTheme.mapGround.ignoresSafeArea())
            }
        }
    }

    private func battlefield(proxy: ScrollViewProxy, size: CGSize) -> some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            HexMapView(scaleMultiplier: mapScaleMode.scaleMultiplier, viewportSize: size)
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
        .onChange(of: size) { _, _ in scrollToCurrentCamera(proxy) }
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
            withAnimation(.easeInOut(duration: 0.22)) { proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.43)) }
        } else {
            proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.43))
        }
    }
}

private struct BattlefieldEdgeShade: View {
    var body: some View {
        GeometryReader { geometry in
            let radius = (geometry.size.width * geometry.size.width + geometry.size.height * geometry.size.height).squareRoot() / 2
            ZStack {
                // Lens falloff keeps the centre untouched and settles the corners under the HUD plates.
                RadialGradient(colors: [.clear, .clear, BattlefieldTheme.mapVignette],
                               center: .center, startRadius: 0, endRadius: max(1, radius))
                VStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(0.19), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 100)
                    Spacer(minLength: 0)
                    LinearGradient(colors: [.clear, .black.opacity(0.24)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 100)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
