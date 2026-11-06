import SwiftUI

struct BattlefieldMapTools: View {
    @Binding var scaleMode: MapScaleMode
    let showsOverview: Bool
    let condensed: Bool
    @Binding var isInspectorExpanded: Bool
    let toggleOverview: () -> Void

    var body: some View {
        let axis: Axis = condensed ? .horizontal : .vertical
        FieldToolRail(axis: axis) {
            Menu {
                Picker("地图缩放", selection: $scaleMode) {
                    ForEach(MapScaleMode.allCases) { mode in Text(mode.title).tag(mode) }
                }
            } label: {
                FieldControlLabel(icon: "plus.magnifyingglass", caption: scaleMode.title)
            }
            .accessibilityLabel("地图缩放")
            .accessibilityValue(scaleMode.title)
            FieldToolDivider(axis: axis)
            FieldControlButton(title: "战区总览", icon: "map", caption: "总览", selected: showsOverview,
                               plated: false, action: toggleOverview)
            FieldToolDivider(axis: axis)
            FieldControlButton(title: "战场情报", icon: "binoculars.fill", caption: "情报", selected: isInspectorExpanded,
                               plated: false) { isInspectorExpanded.toggle() }
                .accessibilityIdentifier("battlefield-intelligence-toggle")
            FieldToolDivider(axis: axis)
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

struct BattlefieldBottomEdge: View {
    @EnvironmentObject private var game: GameState
    let condensed: Bool
    let drawer: BattlefieldDrawer?
    let toggleRoster: () -> Void
    let toggleSupport: () -> Void
    let returnToFrontline: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                BattlefieldDispatch(message: game.message, condensed: condensed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                Rectangle().fill(BattlefieldTheme.brass.opacity(0.18)).frame(height: 1)
                HStack(spacing: 6) {
                    FieldToolRail(axis: .horizontal, plated: false) {
                        toolButton(.roster, action: toggleRoster)
                        toolButton(.support, action: toggleSupport)
                        FieldToolDivider(axis: .horizontal)
                        toolButton(.frontline, action: returnToFrontline)
                            .accessibilityHint("只移动镜头，不改变选择或执行指令")
                        toolButton(.nextReady, action: game.selectNextReadyUnitFromMap)
                            .disabled(game.readyUnits.isEmpty)
                            .opacity(game.readyUnits.isEmpty ? 0.4 : 1)
                    }
                    Spacer(minLength: 0)
                    EndTurnButton(condensed: condensed, compact: geometry.size.width < 540)
                }
                .padding(.horizontal, 6).padding(.vertical, 4)
            }
            .background(FieldPlate())
        }
        .frame(height: condensed ? 80 : 96)
    }

    private func toolButton(_ tool: BattlefieldEdgeTool, action: @escaping () -> Void) -> some View {
        FieldControlButton(title: tool.title, icon: tool.icon, caption: tool.caption,
                           selected: tool.drawer.map { $0 == drawer } ?? false,
                           isToggle: tool.drawer != nil, plated: false, action: action)
    }
}

private struct BattlefieldDispatch: View {
    let message: String
    let condensed: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 11, weight: .regular))
                .foregroundStyle(BattlefieldTheme.brass)
            Text(message).font(condensed ? BattlefieldTheme.hudLabel : BattlefieldTheme.hudBody)
                .lineLimit(condensed ? 1 : 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(BattlefieldTheme.fieldPaper)
        .frame(height: condensed ? 23 : 37)
        .allowsHitTesting(false)
    }
}

struct BattlefieldDrawerPanel: View {
    let drawer: BattlefieldDrawer
    let maxHeight: CGFloat
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: drawer == .roster ? "person.3.fill" : "shippingbox.fill")
                    .foregroundStyle(BattlefieldTheme.brass)
                Text(drawer == .roster ? "编队 / 据点" : "战术支援").font(.system(size: 12, weight: .bold))
                Spacer()
                Button(action: close) { Image(systemName: "xmark").frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityLabel("收起地图面板")
            }
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .padding(.leading, 12)
            Divider().overlay(BattlefieldTheme.brass.opacity(0.4))
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
        .frame(maxWidth: 620, maxHeight: maxHeight)
        .background(FieldPlate(emphasized: true))
        .frame(maxWidth: .infinity, alignment: .leading)
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
