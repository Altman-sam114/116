import SwiftUI

struct BattlefieldMapTools: View {
    @Binding var scaleMode: MapScaleMode
    let showsOverview: Bool
    let condensed: Bool
    @Binding var isInspectorExpanded: Bool
    let toggleOverview: () -> Void
    var onOpenGenerals: () -> Void = {}
    var onOpenShop: () -> Void = {}

    var body: some View {
        FieldToolRail(axis: .horizontal) {
            FieldControlButton(
                title: "将领统帅部",
                icon: "person.crop.circle.badge.checkmark",
                caption: "将领",
                artworkImage: BattlefieldArtwork.emblem(.hqLaurel),
                isToggle: false,
                plated: false,
                action: onOpenGenerals
            )
            .accessibilityIdentifier("battlefield-generals-toggle")

            FieldToolDivider(axis: .horizontal)

            FieldControlButton(
                title: "军需商城",
                icon: "bag.fill",
                caption: "商城",
                artworkImage: BattlefieldArtwork.shopIcon(.warChest),
                isToggle: false,
                plated: false,
                action: onOpenShop
            )
            .accessibilityIdentifier("battlefield-shop-toggle")

            FieldToolDivider(axis: .horizontal)

            Menu {
                Picker("地图缩放", selection: $scaleMode) {
                    ForEach(MapScaleMode.allCases) { mode in Text(mode.title).tag(mode) }
                }
            } label: {
                FieldControlLabel(icon: "plus.magnifyingglass", caption: scaleMode.title)
            }
            .accessibilityLabel("地图缩放")
            .accessibilityValue(scaleMode.title)

            FieldToolDivider(axis: .horizontal)

            FieldControlButton(title: "战区总览", icon: "map", caption: "总览", selected: showsOverview,
                               plated: false, action: toggleOverview)

            FieldToolDivider(axis: .horizontal)

            FieldControlButton(title: "战场情报", icon: "binoculars.fill", caption: "情报", selected: isInspectorExpanded,
                               plated: false) { isInspectorExpanded.toggle() }
                .accessibilityIdentifier("battlefield-intelligence-toggle")

            FieldToolDivider(axis: .horizontal)

            MapRestartButton(plated: false)
        }
    }
}

/// Bottom-edge tools: full names stay on accessibility labels, captions are short field codes.
enum BattlefieldEdgeTool: CaseIterable {
    case roster, support, frontline, nextReady

    var title: String {
        switch self {
        case .roster: "编队与据点定位"
        case .support: "战术支援"
        case .frontline: "返回交战前线"
        case .nextReady: "下一支待命部队"
        }
    }

    var caption: String {
        switch self {
        case .roster: "编队"
        case .support: "支援"
        case .frontline: "前线"
        case .nextReady: "下一支"
        }
    }

    var icon: String {
        switch self {
        case .roster: "person.3.fill"
        case .support: "shippingbox.fill"
        case .frontline: "viewfinder"
        case .nextReady: "forward.fill"
        }
    }

    var drawer: BattlefieldDrawer? {
        switch self {
        case .roster: .roster
        case .support: .support
        case .frontline, .nextReady: nil
        }
    }
}

/// Compact left-anchored EasyTech command cluster — NEVER a full-width empty slab.
struct BattlefieldBottomEdge: View {
    @EnvironmentObject private var game: GameState
    let condensed: Bool
    let drawer: BattlefieldDrawer?
    let toggleRoster: () -> Void
    let toggleSupport: () -> Void
    var toggleCityProduction: () -> Void = {}
    let returnToFrontline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            BattlefieldDispatch(message: game.message, condensed: condensed)

            FieldToolRail(axis: .horizontal, plated: true) {
                toolButton(.roster, action: toggleRoster)
                FieldToolDivider(axis: .horizontal)
                toolButton(.support, action: toggleSupport)
                FieldToolDivider(axis: .horizontal)
                FieldControlButton(
                    title: "城市建设与造兵",
                    icon: "building.2.fill",
                    caption: "造兵",
                    artworkImage: BattlefieldArtwork.resourceIcon(.industry),
                    badgeCount: game.controlledAlliedCities.count,
                    selected: drawer == .cityProduction,
                    isToggle: true,
                    plated: false,
                    action: toggleCityProduction
                )
                .accessibilityIdentifier("battlefield-city-production-toggle")
                FieldToolDivider(axis: .horizontal)
                toolButton(.frontline, action: returnToFrontline)
                    .accessibilityHint("只移动镜头，不改变选择或执行指令")
                FieldToolDivider(axis: .horizontal)
                FieldControlButton(
                    title: BattlefieldEdgeTool.nextReady.title,
                    icon: BattlefieldEdgeTool.nextReady.icon,
                    caption: BattlefieldEdgeTool.nextReady.caption,
                    badgeCount: game.readyUnitCount,
                    selected: false,
                    isToggle: false,
                    plated: false,
                    action: game.selectNextReadyUnitFromMap
                )
                .disabled(game.readyUnits.isEmpty)
                .opacity(game.readyUnits.isEmpty ? 0.4 : 1)
            }
        }
    }

    private func toolButton(_ tool: BattlefieldEdgeTool, action: @escaping () -> Void) -> some View {
        FieldControlButton(title: tool.title, icon: tool.icon, caption: tool.caption,
                           selected: tool.drawer.map { $0 == drawer } ?? false,
                           isToggle: tool.drawer != nil, plated: false, action: action)
    }
}

/// Compact floating tactical radio ticker tucked above the bottom-left cluster.
private struct BattlefieldDispatch: View {
    let message: String
    let condensed: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(BattlefieldTheme.selectedPiece)
            Text(message)
                .font(.system(size: condensed ? 10 : 11, weight: .semibold))
                .foregroundStyle(BattlefieldTheme.fieldPaper)
                .lineLimit(condensed ? 1 : 2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, condensed ? 4 : 5)
        .frame(maxWidth: condensed ? 380 : 480, alignment: .leading)
        .background(FieldPlate(material: .gunmetal, showsRivets: false))
        .allowsHitTesting(false)
    }
}

struct BattlefieldDrawerPanel: View {
    let drawer: BattlefieldDrawer
    let maxHeight: CGFloat
    let close: () -> Void
    var onOpenFullCityModal: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: headerIcon)
                    .foregroundStyle(BattlefieldTheme.selectedPiece)
                Text(headerTitle)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                Spacer()
                if drawer == .cityProduction {
                    Button(action: onOpenFullCityModal) {
                        Label("城市建设", systemImage: "hammer.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(BattlefieldTheme.actionBrass, in: BeveledFieldShape(cornerCut: 4))
                    }
                    .buttonStyle(.plain)
                }
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("收起地图面板")
            }
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .padding(.leading, 12)
            Rectangle().fill(BattlefieldTheme.brass.opacity(0.35)).frame(height: 1)

            ScrollView {
                switch drawer {
                case .roster:
                    ObjectiveJumpDock(compact: false)
                case .support:
                    VStack(alignment: .leading, spacing: 12) {
                        ForceRibbon()
                        TacticalOrderStrip()
                        ReinforcementDock()
                        MapLegendView()
                    }.padding(12)
                case .cityProduction:
                    BattlefieldCityProductionStrip(onOpenFullModal: onOpenFullCityModal)
                }
            }
        }
        .frame(maxWidth: drawer == .cityProduction ? 680 : 580, maxHeight: maxHeight)
        .background(FieldPlate(emphasized: true, material: .brassDossier))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerIcon: String {
        switch drawer {
        case .roster: "person.3.fill"
        case .support: "shippingbox.fill"
        case .cityProduction: "building.2.fill"
        }
    }

    private var headerTitle: String {
        switch drawer {
        case .roster: "前线编队与据点"
        case .support: "战术支援与增援"
        case .cityProduction: "城市造兵与整补"
        }
    }
}

struct MapRestartButton: View {
    @EnvironmentObject private var game: GameState
    @State private var isConfirming = false
    var plated = true

    var body: some View {
        FieldControlButton(title: "重新开始当前战役", icon: "arrow.counterclockwise", caption: "重开", isToggle: false, plated: plated) {
            isConfirming = true
        }
        .accessibilityHint("需要再次确认，当前进度会丢失")
        .confirmationDialog("重新开始当前战役？", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("重新开始", role: .destructive, action: game.restart)
            Button("继续作战", role: .cancel) {}
        } message: {
            Text("当前回合、战果与部队状态都会重置。")
        }
    }
}
