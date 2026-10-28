import SwiftUI

struct BattlefieldMapTools: View {
    @Binding var scaleMode: MapScaleMode
    let showsOverview: Bool
    let condensed: Bool
    @Binding var isInspectorExpanded: Bool
    let toggleOverview: () -> Void

    var body: some View {
        let layout = condensed ? AnyLayout(HStackLayout(spacing: 3)) : AnyLayout(VStackLayout(spacing: 5))
        layout {
            Menu {
                Picker("地图缩放", selection: $scaleMode) {
                    ForEach(MapScaleMode.allCases) { mode in Text(mode.title).tag(mode) }
                }
            } label: {
                VStack(spacing: 1) {
                    Image(systemName: "plus.magnifyingglass").font(.system(size: 17, weight: .medium))
                    Text(scaleMode.title).font(.system(size: 7, weight: .bold))
                }
                .foregroundStyle(BattlefieldTheme.fieldPaper)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .background(FieldPlate())
            }
            .accessibilityLabel("地图缩放")
            .accessibilityValue(scaleMode.title)
            FieldControlButton(title: "战区总览", icon: "map", selected: showsOverview, action: toggleOverview)
            FieldControlButton(title: "战场情报", icon: "binoculars.fill", selected: isInspectorExpanded) { isInspectorExpanded.toggle() }
                .accessibilityIdentifier("battlefield-intelligence-toggle")
            MapRestartButton()
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
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                BattlefieldDispatch(message: game.message, condensed: condensed)
                HStack(spacing: 4) {
                    FieldControlButton(title: "编队与据点定位", icon: "person.3.fill", selected: drawer == .roster, action: toggleRoster)
                    FieldControlButton(title: "战术支援", icon: "shippingbox.fill", selected: drawer == .support, action: toggleSupport)
                    FieldControlButton(title: "返回交战前线", icon: "viewfinder", isToggle: false, action: returnToFrontline)
                        .accessibilityHint("只移动镜头，不改变选择或执行指令")
                    FieldControlButton(title: "下一支待命部队", icon: "forward.fill", isToggle: false, action: game.selectNextReadyUnitFromMap)
                        .disabled(game.readyUnits.isEmpty)
                }
            }
            .frame(maxWidth: condensed ? 310 : 480, alignment: .leading)
            Spacer(minLength: 0)
            EndTurnButton(condensed: condensed)
        }
    }
}

private struct BattlefieldDispatch: View {
    let message: String
    let condensed: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform.path").font(.system(size: 10, weight: .bold))
                .foregroundStyle(BattlefieldTheme.brass)
            Text(message).font(.system(size: condensed ? 9 : 10, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(BattlefieldTheme.fieldPaper)
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(BattlefieldTheme.commandDeckDeep.opacity(0.90), in: RoundedRectangle(cornerRadius: 2))
        .overlay(alignment: .leading) { Rectangle().fill(BattlefieldTheme.brass).frame(width: 2) }
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
    var body: some View {
        FieldControlButton(title: "重新开始当前战役", icon: "arrow.clockwise", isToggle: false, action: game.restart)
    }
}
