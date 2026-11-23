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

enum BattlefieldDrawer: Equatable {
    case roster
    case support
    case cityProduction
}

enum BattlefieldModal: Equatable {
    case generals
    case shop
    case cityHQ
}

struct MapCommandCenter: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var mapScaleMode: MapScaleMode
    @Binding var isInspectorExpanded: Bool
    @State private var drawer: BattlefieldDrawer?
    @State private var activeModal: BattlefieldModal?
    @State private var overviewVisibility: Bool?
    @State private var isFrontlineCamera = true

    var body: some View {
        GeometryReader { geometry in
            let viewport = BattlefieldViewport(size: geometry.size)
            let showsOverview = overviewVisibility ?? viewport.showsOverviewByDefault
            ScrollViewReader { proxy in
                ZStack {
                    battlefield(proxy: proxy, size: geometry.size)
                        .allowsHitTesting(activeModal == nil)
                    BattlefieldEdgeShade()

                    // Floating EasyTech edge-anchored landscape HUD (zero full-width dead black slabs!)
                    VStack(spacing: viewport.isShallow ? 5 : 8) {
                        // Top Floating Row: Left Resources | Center Turn Shield | Right Tools
                        HStack(alignment: .top, spacing: 8) {
                            TopCommandBar(condensed: viewport.isShallow, onOpenShop: { activeModal = .shop })
                            Spacer(minLength: 4)
                            if geometry.size.width >= 1050 {
                                TurnObjectiveShield(condensed: viewport.isShallow)
                                Spacer(minLength: 4)
                            }
                            BattlefieldMapTools(
                                scaleMode: $mapScaleMode,
                                showsOverview: showsOverview,
                                condensed: viewport.isShallow,
                                isInspectorExpanded: $isInspectorExpanded,
                                toggleOverview: { overviewVisibility = !showsOverview },
                                onOpenGenerals: { activeModal = .generals },
                                onOpenShop: { activeModal = .shop }
                            )
                        }

                        // Open Battlefield Workspace + Optional Floating Minimap
                        Spacer(minLength: 0)
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .topLeading) {
                                if drawer == nil && showsOverview {
                                    BattlefieldOverviewMap(
                                        tiles: game.tiles, units: game.units, focusedCoordinate: game.focusedCoordinate,
                                        onFocus: { game.focus(coordinate: $0); scrollToFocus(proxy, animated: true) },
                                        onFrontline: { scrollToFrontline(proxy, animated: true) }
                                    )
                                }
                            }

                        // Bottom Floating Row: Left Command Stack | Open Map | Right Sculpted End Turn
                        HStack(alignment: .bottom, spacing: 10) {
                            VStack(alignment: .leading, spacing: viewport.isShallow ? 5 : 7) {
                                if let drawer {
                                    BattlefieldDrawerPanel(
                                        drawer: drawer,
                                        maxHeight: geometry.size.height * (viewport.isShallow ? 0.50 : 0.44),
                                        close: { self.drawer = nil },
                                        onOpenFullCityModal: {
                                            self.drawer = nil
                                            self.activeModal = .cityHQ
                                        }
                                    )
                                } else if game.selectedUnit != nil {
                                    MapActionHUD(
                                        compact: viewport.compactControls,
                                        condensed: viewport.isShallow,
                                        inlineOrders: BattlefieldHUDLayout(size: geometry.size).inlineOrders,
                                        onOpenGenerals: { activeModal = .generals }
                                    )
                                }

                                BattlefieldBottomEdge(
                                    condensed: viewport.isShallow,
                                    drawer: drawer,
                                    toggleRoster: { toggleDrawer(.roster) },
                                    toggleSupport: { toggleDrawer(.support) },
                                    toggleCityProduction: { toggleDrawer(.cityProduction) },
                                    returnToFrontline: { scrollToFrontline(proxy, animated: true) }
                                )
                            }

                            Spacer(minLength: 8)

                            EndTurnButton(condensed: viewport.isShallow, compact: geometry.size.width < 560)
                        }
                    }
                    .padding(.horizontal, viewport.isShallow ? 8 : 14)
                    .padding(.vertical, viewport.isShallow ? 6 : 10)
                    .allowsHitTesting(activeModal == nil)
                    .zIndex(1)

                    if let modal = activeModal {
                        Color.black.opacity(0.56)
                            .ignoresSafeArea()
                            .onTapGesture { activeModal = nil }
                            .zIndex(4)

                        Group {
                            switch modal {
                            case .generals:
                                BattlefieldGeneralsModal(close: { activeModal = nil })
                            case .shop:
                                BattlefieldQuartermasterModal(close: { activeModal = nil })
                            case .cityHQ:
                                BattlefieldCityHQModal(close: { activeModal = nil })
                            }
                        }
                        .frame(
                            maxWidth: min(geometry.size.width - 36, 860),
                            maxHeight: min(geometry.size.height - 28, 560)
                        )
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                        .zIndex(5)
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: activeModal)
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
            withAnimation(.easeInOut(duration: 0.22)) { proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.45)) }
        } else {
            proxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.45))
        }
    }
}

private struct BattlefieldEdgeShade: View {
    var body: some View {
        GeometryReader { geometry in
            let radius = (geometry.size.width * geometry.size.width + geometry.size.height * geometry.size.height).squareRoot() / 2
            ZStack {
                RadialGradient(colors: [.clear, .clear, Color.black.opacity(0.18)],
                               center: .center, startRadius: 0, endRadius: max(1, radius))
                VStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 64)
                    Spacer(minLength: 0)
                    LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 68)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
