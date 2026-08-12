import SwiftUI

struct TopCommandBar: View {
    var body: some View {
        HStack(spacing: 8) {
            CommandTitle()
                .layoutPriority(2)
            CampaignPicker()

            ScrollView(.horizontal, showsIndicators: false) {
                StatusStrip()
            }

            EndTurnButton()
        }
        .padding(.horizontal, 12)
        .background(
            Rectangle()
                .fill(BattlefieldTheme.commandDeckDeep.opacity(0.92))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(BattlefieldTheme.brass.opacity(0.24))
                        .frame(height: 1)
                }
        )
    }
}

struct CampaignPicker: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        Menu("切换战役", systemImage: "map.fill") {
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
        }
        .labelStyle(.iconOnly)
        .frame(width: 44, height: 44)
        .tint(.white)
        .accessibilityLabel("选择战役")
        .accessibilityValue(game.scenario.name)
    }
}

struct CommandTitle: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        HStack(spacing: 7) {
            Text("WW2")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.82))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(BattlefieldTheme.brass, in: Capsule())
            Text(game.scenario.name)
                .font(.subheadline.weight(.black))
                .foregroundStyle(BattlefieldTheme.ink)
                .lineLimit(1)
            Text("\(game.scenario.year)")
                .font(.caption.weight(.bold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("第二次世界大战，\(game.scenario.name)，\(game.scenario.year)年")
    }
}

struct StatusStrip: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        HStack(spacing: 6) {
            StatusChip(icon: "flag.fill", value: "\(game.turn)", label: "当前回合")
            StatusChip(icon: "hourglass", value: "\(game.remainingTurns)", label: "剩余回合")
            StatusChip(
                icon: "shield.lefthalf.filled",
                value: game.activeFaction.shortTitle,
                label: "当前阵营",
                accessibilityValue: game.activeFaction.title
            )
            StatusChip(
                icon: "scope",
                value: "\(game.alliedScore):\(game.axisScore)",
                label: "据点控制",
                accessibilityValue: "盟军 \(game.alliedScore)，轴心 \(game.axisScore)"
            )
            StatusChip(icon: "star.circle.fill", value: "\(game.activeCommandPoints)", label: "可用指令点")
            StatusChip(icon: "person.3.fill", value: "\(game.readyUnitCount)", label: "待命单位")
        }
    }
}

struct EndTurnButton: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        Button(action: game.endTurn) {
            Image(systemName: "forward.end.fill")
                .font(.body.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(BattlefieldTheme.alert, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(game.winner != nil)
        .accessibilityLabel("结束回合")
        .accessibilityHint("结束当前阵营行动并推进战局")
    }
}

struct StatusChip: View {
    let icon: String
    let value: String
    let label: String
    var accessibilityValue: String? = nil

    var body: some View {
        Label(value, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(BattlefieldTheme.ink)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 6)
            .frame(height: 30)
            .background(BattlefieldTheme.fieldGlass.opacity(0.62), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(BattlefieldTheme.hairline, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(accessibilityValue ?? value)
    }
}

struct BattlefieldView: View {
    @State private var mapScaleMode: MapScaleMode = .campaign
    @State private var isSupportDeckExpanded = false

    var body: some View {
        VStack(spacing: 6) {
            MapCommandCenter(mapScaleMode: $mapScaleMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            BattlefieldSupportDeck(isExpanded: $isSupportDeckExpanded)
        }
        .padding(6)
        .tacticalSurface(cornerRadius: 10, fillOpacity: 0.36, borderOpacity: 0.10, shadowOpacity: 0.18)
    }
}

struct BattlefieldSupportDeck: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 6) {
            Button(action: toggleDeck) {
                HStack(spacing: 8) {
                    Image(systemName: "square.3.layers.3d.down.right")
                        .foregroundStyle(BattlefieldTheme.brass)
                    Text("支援甲板")
                        .font(.caption.bold())
                        .foregroundStyle(BattlefieldTheme.ink)
                    Text("\(game.readyUnitCount) READY")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(BattlefieldTheme.signal)
                    Text("CMD \(game.activeCommandPoints)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(BattlefieldTheme.brass)
                    Spacer(minLength: 6)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption.bold())
                        .foregroundStyle(BattlefieldTheme.mutedInk)
                }
                .frame(minHeight: 44)
                .padding(.horizontal, 10)
                .background(BattlefieldTheme.commandDeckDeep.opacity(0.58), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.brass.opacity(0.16), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "收起支援甲板" : "展开支援甲板")

            if isExpanded {
                VStack(spacing: 6) {
                    ForceRibbon()
                    TacticalOrderStrip()
                    ReinforcementDock()
                    MapLegendView()
                }
                .transition(.opacity)
            }
        }
    }

    private func toggleDeck() {
        if reduceMotion {
            isExpanded.toggle()
        } else {
            withAnimation(.snappy) {
                isExpanded.toggle()
            }
        }
    }
}

enum MapScaleMode: String, CaseIterable, Identifiable {
    case campaign
    case tactical
    case detail

    var id: String { rawValue }

    var title: String {
        switch self {
        case .campaign:
            "战役"
        case .tactical:
            "战术"
        case .detail:
            "细节"
        }
    }

    var scaleMultiplier: CGFloat {
        switch self {
        case .campaign:
            1.0
        case .tactical:
            1.16
        case .detail:
            1.32
        }
    }
}

struct MapCommandCenter: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var mapScaleMode: MapScaleMode

    var body: some View {
        VStack(spacing: 0) {
            MapToolbar(mapScaleMode: $mapScaleMode)

            GeometryReader { mapProxy in
                let isCompactMapChrome = mapProxy.size.width < 680
                let isTightMapChrome = mapProxy.size.width < 820

                ZStack {
                    ScrollViewReader { proxy in
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            HexMapView(
                                scaleMultiplier: mapScaleMode.scaleMultiplier,
                                viewportHeight: mapProxy.size.height
                            )
                            .padding(8)
                        }
                        .onAppear {
                            scrollToFocusedCoordinate(with: proxy, animated: false)
                        }
                        .onChange(of: game.focusedCoordinate?.id) { _, _ in
                            scrollToFocusedCoordinate(with: proxy, animated: true)
                        }
                        .onChange(of: mapScaleMode) { _, _ in
                            scrollToFocusedCoordinate(with: proxy, animated: true)
                        }
                    }

                    VStack(spacing: 0) {
                        HStack(alignment: .top, spacing: 6) {
                            BattlefieldMessageDock(compact: isTightMapChrome)

                            Spacer(minLength: 6)

                            if game.selectedUnit != nil {
                                MapActionHUD(compact: isCompactMapChrome)
                            } else {
                                MapIdleCommandDock()
                            }
                        }
                        .padding(isCompactMapChrome ? 6 : 8)

                        Spacer(minLength: 6)

                        ObjectiveJumpDock(compact: isCompactMapChrome)
                            .padding(.horizontal, isCompactMapChrome ? 6 : 8)
                            .padding(.bottom, isCompactMapChrome ? 6 : 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    BattlefieldTheme.commandDeckDeep.opacity(0.74)
                    LinearGradient(
                        colors: [
                            BattlefieldTheme.signal.opacity(0.08),
                            .clear,
                            BattlefieldTheme.brass.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .tacticalSurface(cornerRadius: 10, fillOpacity: 0.66, borderOpacity: 0.18, shadowOpacity: 0.26)
    }

    private func scrollToFocusedCoordinate(with proxy: ScrollViewProxy, animated: Bool) {
        guard let focusedCoordinate = game.focusedCoordinate else { return }
        let action = {
            proxy.scrollTo(focusedCoordinate.id, anchor: .center)
        }

        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.24), action)
        } else {
            action()
        }
    }
}

struct MapToolbar: View {
    @EnvironmentObject private var game: GameState
    @Binding var mapScaleMode: MapScaleMode

    var body: some View {
        HStack(spacing: 10) {
            toolbarTitle
            Spacer(minLength: 8)
            scalePicker
            MapRestartButton()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background(BattlefieldTheme.commandDeck.opacity(0.80))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BattlefieldTheme.brass.opacity(0.18))
                .frame(height: 1)
        }
    }

    private var toolbarTitle: some View {
        HStack(spacing: 7) {
            Image(systemName: "map.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(BattlefieldTheme.brass)
            Text("战区 \(game.scenario.mapColumns)x\(game.scenario.mapRows)")
                .font(.caption.bold())
                .foregroundStyle(BattlefieldTheme.ink)
                .lineLimit(1)
        }
        .accessibilityLabel(toolbarAccessibilityLabel)
    }

    private var toolbarAccessibilityLabel: String {
        guard let coordinate = game.focusedCoordinate else {
            return "战区地图，\(mapScaleMode.title)缩放"
        }
        return "战区地图，\(mapScaleMode.title)缩放，焦点 q\(coordinate.q), r\(coordinate.r)"
    }

    private var scalePicker: some View {
        Picker("地图缩放", selection: $mapScaleMode) {
            ForEach(MapScaleMode.allCases) { mode in
                Text(mode.title)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 164)
        .accessibilityLabel("地图缩放")
    }
}

struct BattlefieldMessageDock: View {
    @EnvironmentObject private var game: GameState
    let compact: Bool

    var body: some View {
        Label {
            Text(game.message)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundStyle(BattlefieldTheme.signal)
                .accessibilityHidden(true)
        }
        .foregroundStyle(BattlefieldTheme.ink)
        .padding(.horizontal, 9)
        .frame(width: compact ? 180 : 420, height: 44, alignment: .leading)
        .background(BattlefieldTheme.commandDeckDeep.opacity(0.76), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(BattlefieldTheme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("战场通讯")
        .accessibilityValue(game.message)
        .allowsHitTesting(false)
    }
}

struct MapRestartButton: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        Button(action: game.restart) {
            Image(systemName: "arrow.clockwise")
                .font(.body.weight(.bold))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(BattlefieldTheme.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(BattlefieldTheme.ink)
        .accessibilityLabel("重新开始")
        .accessibilityHint("重新开始当前战役")
    }
}

struct MapCampaignHUD: View {
    @EnvironmentObject private var game: GameState
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: "flag.2.crossed.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.yellow)
                    .frame(width: 22, height: 22)
                    .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 5))

                VStack(alignment: .leading, spacing: 1) {
                    Text(game.scenario.name)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("T\(game.turn) · \(game.activeFaction.shortTitle)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer(minLength: 4)

                Text("剩\(game.remainingTurns)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.72), in: Capsule())
            }

            ProgressView(value: game.objectiveProgress)
                .tint(Faction.allies.accentColor)
                .scaleEffect(x: 1, y: 0.85, anchor: .center)

            HStack(spacing: 5) {
                MapHudMetric(
                    icon: "flag.fill",
                    label: "OBJ",
                    value: "\(game.alliedScore)/\(game.objectiveTiles.count)",
                    color: Faction.allies.accentColor
                )
                MapHudMetric(
                    icon: "star.circle.fill",
                    label: "CMD",
                    value: "\(game.activeCommandPoints)",
                    color: .yellow
                )
                MapHudMetric(
                    icon: "chart.bar.fill",
                    label: "PWR",
                    value: "\(game.alliedStrength):\(game.axisStrength)",
                    color: .white.opacity(0.76)
                )
            }

            HStack(spacing: 4) {
                ForEach(game.missionObjectives) { objective in
                    Image(systemName: objective.state.systemImage)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(objective.state.accentColor)
                        .frame(width: 16, height: 16)
                        .background(Color.black.opacity(0.18), in: Circle())
                        .accessibilityLabel(objective.title)
                }
            }
        }
        .padding(compact ? 7 : 8)
        .frame(width: compact ? 210 : 236, alignment: .leading)
        .background(MapHudBackground())
    }
}

struct MapActionHUD: View {
    @EnvironmentObject private var game: GameState
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 7) {
            if let unit = game.selectedUnit {
                let supplyState = game.supplyState(for: unit)

                HStack(spacing: 4) {
                    UnitShapeBadge(
                        kind: unit.kind,
                        faction: unit.faction,
                        hasCommander: unit.commander != nil,
                        rank: unit.rank,
                        supplyState: supplyState,
                        tacticalStatus: unit.tacticalStatus,
                        isSpent: unit.hasMoved && unit.hasAttacked,
                        width: compact ? 34 : 36,
                        height: 24
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(unit.name)
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("\(unit.kind.title) · \(unit.hp)/\(unit.maxHP)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: compact ? 48 : 72, alignment: .leading)

                    MapHudMetric(
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        label: "MOVE",
                        value: "\(game.reachableTiles(for: unit).count)",
                        color: .cyan,
                        compact: true
                    )
                    .frame(width: compact ? 24 : 27)

                    MapHudMetric(
                        icon: "target",
                        label: "ATK",
                        value: "\(game.attackableTiles(for: unit).count)",
                        color: .orange,
                        compact: true
                    )
                    .frame(width: compact ? 24 : 27)

                    MapHudMetric(
                        icon: "exclamationmark.triangle.fill",
                        label: "THR",
                        value: "\(game.threatenedReachableTiles(for: unit).count)",
                        color: .red,
                        compact: true
                    )
                    .frame(width: compact ? 24 : 27)

                    MapHudMetric(
                        icon: supplyState == .supplied ? "fuelpump.fill" : "exclamationmark.octagon.fill",
                        label: supplyState.shortTitle,
                        value: "\(max(0, game.supplyLineTiles(for: unit).count - 1))",
                        color: supplyState == .supplied ? .green : .red,
                        compact: true
                    )
                    .frame(width: compact ? 24 : 27)

                    Button(action: game.waitSelectedUnit) {
                        Image(systemName: "pause.fill")
                            .font(.caption.weight(.black))
                            .foregroundStyle(unit.hasMoved && unit.hasAttacked ? Color.white.opacity(0.34) : Color.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(unit.hasMoved && unit.hasAttacked ? 0.05 : 0.10), in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(unit.hasMoved && unit.hasAttacked ? 0.08 : 0.20), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(unit.hasMoved && unit.hasAttacked)
                    .accessibilityLabel("待命")
                }
                .frame(minHeight: 44)

                HStack(spacing: 5) {
                    MapQuickCommandButton(
                        icon: "forward.fill",
                        title: "NEXT",
                        color: .yellow,
                        isEnabled: !game.readyUnits.isEmpty
                    ) {
                        game.selectNextReadyUnitFromMap()
                    }
                    MapQuickCommandButton(
                        icon: "target",
                        title: "ATK",
                        color: .orange,
                        isEnabled: !game.attackableUnits(for: unit).isEmpty
                    ) {
                        game.focusNearestAttackTarget()
                    }
                    MapQuickCommandButton(
                        icon: "scope",
                        title: "POS",
                        color: .cyan,
                        isEnabled: game.nearestApproachTarget(for: unit) != nil
                    ) {
                        game.focusNearestApproachTarget()
                    }
                    MapQuickCommandButton(
                        icon: "flag.checkered",
                        title: "OBJ",
                        color: .green,
                        isEnabled: game.nearestObjectiveTarget(for: unit) != nil
                    ) {
                        game.focusNearestObjectiveTarget()
                    }
                }

                if game.focusedCommandPreview?.isExecutable == true {
                    InlineMapCommandPreview()
                }
            }
        }
        .padding(compact ? 7 : 8)
        .frame(width: compact ? 268 : 304, alignment: .leading)
        .background(MapHudBackground())
    }
}

struct MapIdleCommandDock: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        Button {
            game.selectNextReadyUnitFromMap()
        } label: {
            Label("NEXT", systemImage: "forward.fill")
                .font(.caption.bold())
                .foregroundStyle(game.readyUnits.isEmpty ? Color.white.opacity(0.38) : BattlefieldTheme.signal)
                .frame(minWidth: 82, minHeight: 44)
                .padding(.horizontal, 8)
                .background(MapHudBackground())
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(game.readyUnits.isEmpty ? Color.white.opacity(0.18) : BattlefieldTheme.signal)
                        .frame(width: 3)
                }
        }
        .buttonStyle(.plain)
        .disabled(game.readyUnits.isEmpty)
        .accessibilityLabel("选择下一支待命部队")
        .accessibilityHint("从地图选择下一支仍可行动的部队")
    }
}

struct MapQuickCommandButton: View {
    let icon: String
    let title: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(isEnabled ? color : Color.white.opacity(0.38))
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background((isEnabled ? color : Color.white).opacity(isEnabled ? 0.16 : 0.06), in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke((isEnabled ? color : Color.white).opacity(isEnabled ? 0.32 : 0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

struct ObjectiveJumpDock: View {
    let compact: Bool

    var body: some View {
        ObjectiveJumpStrip(compact: compact)
            .frame(height: 66)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(MapHudBackground())
    }
}

struct MapHudMetric: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var compact: Bool = false

    var body: some View {
        if compact {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .black))
                Text(value)
                    .font(.system(size: 10, weight: .black, design: .rounded))
            }
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 5))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label) \(value)")
        } else {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .black))
                Text(label)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                Text(value)
                    .font(.system(size: 10, weight: .black, design: .rounded))
            }
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 5))
        }
    }
}

struct MapHudBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(BattlefieldTheme.commandDeckDeep.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(BattlefieldTheme.brass.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)
    }
}

struct FrontlineStrip: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                MapIntelPill(
                    icon: "flag.fill",
                    title: "盟军据点",
                    value: "\(game.alliedScore)",
                    color: Faction.allies.accentColor
                )
                MapIntelPill(
                    icon: "flag.slash.fill",
                    title: "轴心据点",
                    value: "\(game.axisScore)",
                    color: Faction.axis.accentColor
                )
                MapIntelPill(
                    icon: "circle.dashed",
                    title: "中立",
                    value: "\(game.objectiveTiles.filter { $0.owner == nil }.count)",
                    color: .white.opacity(0.72)
                )
                MapIntelPill(
                    icon: "scope",
                    title: "焦点",
                    value: focusedText,
                    color: .yellow
                )
            }
        }
    }

    private var focusedText: String {
        guard let coordinate = game.focusedCoordinate else { return "--" }
        return "q\(coordinate.q),r\(coordinate.r)"
    }
}

struct ObjectiveJumpStrip: View {
    @EnvironmentObject private var game: GameState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let compact: Bool

    var body: some View {
        let friendlyUnits = game.mapFriendlyFocusUnits
        let objectives = game.objectiveTiles.sorted(by: objectiveSort)
        let enemyUnits = game.mapEnemyFocusUnits

        GeometryReader { proxy in
            let spacing: CGFloat = 4
            let availableWidth = max(0, proxy.size.width - spacing * 2)

            HStack(spacing: spacing) {
                ObjectiveJumpSection(
                    icon: "shield.fill",
                    code: "AL",
                    title: "友军编队",
                    count: friendlyUnits.count,
                    color: Faction.allies.accentColor,
                    largeType: usesLargeTypeLayout,
                    itemIDs: friendlyUnits.map { $0.id.uuidString },
                    focusedItemID: game.focusedUnit?.id.uuidString
                ) {
                    ForEach(friendlyUnits) { unit in
                        UnitFocusButton(unit: unit, compact: compact, largeType: usesLargeTypeLayout)
                            .id(unit.id.uuidString)
                    }
                }
                .frame(width: availableWidth * friendlySectionRatio)

                ObjectiveJumpSection(
                    icon: "flag.fill",
                    code: "OBJ",
                    title: "战役据点",
                    count: objectives.count,
                    color: BattlefieldTheme.brass,
                    largeType: usesLargeTypeLayout,
                    itemIDs: objectives.map { $0.coordinate.id },
                    focusedItemID: game.focusedCoordinate?.id
                ) {
                    ForEach(objectives) { tile in
                        ObjectiveJumpButton(tile: tile, compact: compact, largeType: usesLargeTypeLayout)
                            .id(tile.coordinate.id)
                    }
                }
                .frame(width: availableWidth * objectiveSectionRatio)

                ObjectiveJumpSection(
                    icon: "scope",
                    code: "AX",
                    title: "敌军编队",
                    count: enemyUnits.count,
                    color: Faction.axis.accentColor,
                    largeType: usesLargeTypeLayout,
                    itemIDs: enemyUnits.map { $0.id.uuidString },
                    focusedItemID: game.focusedUnit?.id.uuidString
                ) {
                    ForEach(enemyUnits) { unit in
                        UnitFocusButton(unit: unit, compact: compact, largeType: usesLargeTypeLayout)
                            .id(unit.id.uuidString)
                    }
                }
                .frame(width: availableWidth * enemySectionRatio)
            }
        }
    }

    private var friendlySectionRatio: CGFloat { compact ? 1.0 / 3.0 : 0.40 }
    private var objectiveSectionRatio: CGFloat { compact ? 1.0 / 3.0 : 0.26 }
    private var enemySectionRatio: CGFloat { compact ? 1.0 / 3.0 : 0.34 }

    private var usesLargeTypeLayout: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    private func objectiveSort(_ left: TerrainTile, _ right: TerrainTile) -> Bool {
        let leftOwnerRank = ownerRank(left.owner)
        let rightOwnerRank = ownerRank(right.owner)
        if leftOwnerRank == rightOwnerRank {
            return (left.objectiveName ?? left.id) < (right.objectiveName ?? right.id)
        }
        return leftOwnerRank < rightOwnerRank
    }

    private func ownerRank(_ owner: Faction?) -> Int {
        switch owner {
        case .axis:
            0
        case nil:
            1
        case .allies:
            2
        }
    }
}

struct ObjectiveJumpSection<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let icon: String
    let code: String
    let title: String
    let count: Int
    let color: Color
    let largeType: Bool
    let itemIDs: [String]
    let focusedItemID: String?
    @ViewBuilder let content: Content

    @State private var viewportWidth: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var contentMinX: CGFloat = 0
    @State private var lastAutoScrolledItemID: String?

    var body: some View {
        VStack(spacing: largeType ? 1 : 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                Text(code)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 2)
                Text("\(count)")
                    .monospacedDigit()
            }
            .font(largeType ? .caption.weight(.black) : .system(size: 9, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(height: largeType ? 16 : 14)
            .padding(.horizontal, 4)
            .dynamicTypeSize(visualDynamicTypeRange)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title)，共 \(count) 项")
            .accessibilityHint(scrollAccessibilityHint)

            ScrollViewReader { scrollProxy in
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 4) {
                            content
                        }
                        .padding(.horizontal, 3)
                        .background {
                            GeometryReader { metrics in
                                Color.clear.preference(
                                    key: ObjectiveJumpRailContentMetricsKey.self,
                                    value: ObjectiveJumpRailContentMetrics(
                                        width: metrics.size.width,
                                        minX: metrics.frame(in: .named(scrollCoordinateSpace)).minX
                                    )
                                )
                            }
                        }
                    }
                    .coordinateSpace(name: scrollCoordinateSpace)
                    .background {
                        GeometryReader { metrics in
                            Color.clear.preference(
                                key: ObjectiveJumpRailViewportWidthKey.self,
                                value: metrics.size.width
                            )
                        }
                    }
                    .onPreferenceChange(ObjectiveJumpRailViewportWidthKey.self) { width in
                        viewportWidth = width
                    }
                    .onPreferenceChange(ObjectiveJumpRailContentMetricsKey.self) { metrics in
                        contentWidth = metrics.width
                        contentMinX = metrics.minX
                    }
                    .onAppear {
                        scrollToFocusedItem(with: scrollProxy, animated: false)
                    }
                    .onChange(of: focusedItemID) { _, _ in
                        scrollToFocusedItem(with: scrollProxy, animated: true)
                    }
                    .onChange(of: itemIDs) { _, _ in
                        lastAutoScrolledItemID = nil
                        scrollToFocusedItem(with: scrollProxy, animated: false)
                    }

                    ObjectiveJumpRailOverflowCue(
                        showLeading: canScrollLeading,
                        showTrailing: canScrollTrailing
                    )
                    .allowsHitTesting(false)
                }
            }
            .frame(height: largeType ? 48 : 50)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(color.opacity(0.24))
                .frame(width: 1)
                .padding(.vertical, 3)
        }
    }

    private var visualDynamicTypeRange: ClosedRange<DynamicTypeSize> {
        largeType ? (.xSmall ... .large) : (.xSmall ... .accessibility5)
    }

    private var scrollCoordinateSpace: String {
        "objective-jump-rail-\(code)"
    }

    private var overflowWidth: CGFloat {
        max(0, contentWidth - viewportWidth)
    }

    private var scrollOffset: CGFloat {
        min(overflowWidth, max(0, -contentMinX))
    }

    private var canScrollLeading: Bool {
        overflowWidth > scrollEpsilon && scrollOffset > scrollEpsilon
    }

    private var canScrollTrailing: Bool {
        overflowWidth > scrollEpsilon && scrollOffset < overflowWidth - scrollEpsilon
    }

    private var scrollAccessibilityHint: String {
        switch (canScrollLeading, canScrollTrailing) {
        case (true, true):
            "可向左或向右滑动查看更多项目"
        case (true, false):
            "可向左滑动查看更多项目"
        case (false, true):
            "可向右滑动查看更多项目"
        case (false, false):
            ""
        }
    }

    private func scrollToFocusedItem(with proxy: ScrollViewProxy, animated: Bool) {
        guard let focusedItemID, itemIDs.contains(focusedItemID) else {
            lastAutoScrolledItemID = nil
            return
        }
        guard lastAutoScrolledItemID != focusedItemID else { return }

        lastAutoScrolledItemID = focusedItemID
        let scroll = {
            proxy.scrollTo(focusedItemID, anchor: .center)
        }

        if animated && !reduceMotion {
            withAnimation(.easeOut(duration: 0.18), scroll)
        } else {
            scroll()
        }
    }

    private var scrollEpsilon: CGFloat { 0.75 }
}

private struct ObjectiveJumpRailViewportWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ObjectiveJumpRailContentMetrics: Equatable {
    let width: CGFloat
    let minX: CGFloat
}

private struct ObjectiveJumpRailContentMetricsKey: PreferenceKey {
    static var defaultValue = ObjectiveJumpRailContentMetrics(width: 0, minX: 0)

    static func reduce(value: inout ObjectiveJumpRailContentMetrics, nextValue: () -> ObjectiveJumpRailContentMetrics) {
        value = nextValue()
    }
}

private struct ObjectiveJumpRailOverflowCue: View {
    let showLeading: Bool
    let showTrailing: Bool

    var body: some View {
        HStack(spacing: 0) {
            cue(edge: .leading, isVisible: showLeading)
            Spacer(minLength: 0)
            cue(edge: .trailing, isVisible: showTrailing)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func cue(edge: HorizontalEdge, isVisible: Bool) -> some View {
        if isVisible {
            ZStack(alignment: edge == .leading ? .leading : .trailing) {
                LinearGradient(
                    colors: edge == .leading
                        ? [BattlefieldTheme.commandDeckDeep.opacity(0.82), .clear]
                        : [.clear, BattlefieldTheme.commandDeckDeep.opacity(0.82)],
                    startPoint: edge == .leading ? .leading : .trailing,
                    endPoint: edge == .leading ? .trailing : .leading
                )

                Image(systemName: edge == .leading ? "chevron.left" : "chevron.right")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(BattlefieldTheme.mutedInk.opacity(0.62))
                    .padding(.horizontal, 3)
            }
            .frame(width: 15)
        }
    }
}

struct ObjectiveJumpButton: View {
    @EnvironmentObject private var game: GameState
    let tile: TerrainTile
    let compact: Bool
    let largeType: Bool

    var body: some View {
        Button(action: focusObjective) {
            VStack(spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14, weight: .black))
                    Text(ownerCode)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .padding(.horizontal, 4)
                        .frame(minHeight: 16)
                        .background(ownerColor.opacity(0.18), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(ownerColor.opacity(0.52), style: ownerStrokeStyle)
                        }
                }

                Text(largeType ? "OBJ" : (tile.objectiveName ?? "据点"))
                    .font(largeType ? .caption.weight(.bold) : .system(size: 9, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text("q\(tile.coordinate.q),r\(tile.coordinate.r)")
                    .font(largeType ? .caption.weight(.black) : .system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .foregroundStyle(ownerColor)
            .padding(.horizontal, 3)
            .dynamicTypeSize(visualDynamicTypeRange)
            .frame(width: itemWidth, height: itemHeight)
            .background(
                Color.white.opacity(isFocused ? 0.14 : 0),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow.opacity(isFocused ? 1 : 0), lineWidth: isFocused ? 2 : 0)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(ownerColor.opacity(isFocused ? 0.92 : 0.28))
                    .frame(height: isFocused ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("定位据点，\(tile.objectiveName ?? "据点")")
        .accessibilityValue("\(ownerTitle)，坐标 q\(tile.coordinate.q), r\(tile.coordinate.r)\(isFocused ? "，当前焦点" : "")")
        .accessibilityHint("在地图上定位该据点，不执行命令")
    }

    private var itemWidth: CGFloat { compact ? 72 : 84 }

    private var itemHeight: CGFloat { largeType ? 48 : 50 }

    private var visualDynamicTypeRange: ClosedRange<DynamicTypeSize> {
        largeType ? (.xSmall ... .large) : (.xSmall ... .accessibility5)
    }

    private var isFocused: Bool {
        game.focusedCoordinate == tile.coordinate
    }

    private var ownerColor: Color {
        tile.owner?.accentColor ?? Color.white.opacity(0.74)
    }

    private var ownerCode: String {
        tile.owner?.shortTitle ?? "NEU"
    }

    private var ownerTitle: String {
        tile.owner?.title ?? "中立"
    }

    private var ownerStrokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: 1, dash: tile.owner == .axis ? [3, 2] : [])
    }

    private func focusObjective() {
        game.focus(coordinate: tile.coordinate)
    }
}

struct UnitFocusButton: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit
    let compact: Bool
    let largeType: Bool

    var body: some View {
        Button(action: focusUnit) {
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    UnitShapeBadge(
                        kind: unit.kind,
                        faction: unit.faction,
                        hasCommander: unit.commander != nil,
                        rank: unit.rank,
                        supplyState: supplyState,
                        tacticalStatus: unit.tacticalStatus,
                        isSpent: isActionComplete,
                        width: compact ? 30 : 34,
                        height: 20
                    )

                    VStack(alignment: .leading, spacing: 0) {
                        Text(largeType ? unit.kind.code : unit.name)
                            .font(largeType ? .caption.weight(.bold) : .system(size: 9, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                        Text("\(unit.hp)/\(unit.maxHP)")
                            .font(largeType ? .caption.weight(.black) : .system(size: 9, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 2) {
                    CompactUnitActionState(
                        code: "M",
                        readyIcon: "arrow.up.right",
                        isConsumed: unit.hasMoved,
                        readyColor: .cyan
                    )
                    MiniHealthBar(ratio: unit.hpRatio)
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                    CompactUnitActionState(
                        code: "A",
                        readyIcon: "scope",
                        isConsumed: unit.hasAttacked,
                        readyColor: .orange
                    )
                }
            }
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 3)
            .dynamicTypeSize(visualDynamicTypeRange)
            .frame(width: itemWidth, height: itemHeight)
            .background(
                Color.white.opacity(isFocused ? 0.14 : 0),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow.opacity(isFocused ? 1 : 0), lineWidth: isFocused ? 2 : 0)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(unit.faction.accentColor.opacity(isFocused ? 0.92 : 0.28))
                    .frame(height: isFocused ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(actionTitle)，\(unit.name)")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("在地图上\(actionTitle)该单位，不执行命令")
    }

    private var itemWidth: CGFloat { compact ? 72 : 84 }

    private var itemHeight: CGFloat { largeType ? 48 : 50 }

    private var visualDynamicTypeRange: ClosedRange<DynamicTypeSize> {
        largeType ? (.xSmall ... .large) : (.xSmall ... .accessibility5)
    }

    private var isActionComplete: Bool {
        unit.hasMoved && unit.hasAttacked
    }

    private var supplyState: SupplyState {
        game.supplyState(for: unit)
    }

    private var actionTitle: String {
        unit.faction == game.activeFaction ? "选择" : "定位"
    }

    private var accessibilityValue: String {
        let moveText = unit.hasMoved ? "移动已用" : "移动可用"
        let attackText = unit.hasAttacked ? "攻击已用" : "攻击可用"
        let commanderText = unit.commander.map { "，将领\($0.name)" } ?? "，无将领"
        return "\(unit.faction.title)，\(unit.kind.title)，生命 \(unit.hp) / \(unit.maxHP)，\(moveText)，\(attackText)，\(supplyState.title)，\(unit.tacticalStatus.title)，\(unit.rank.title)\(commanderText)"
    }

    private var isFocused: Bool {
        game.focusedUnit?.id == unit.id
    }

    private func focusUnit() {
        if unit.faction == game.activeFaction {
            game.select(unitID: unit.id)
        } else {
            game.focus(unitID: unit.id)
        }
    }
}

struct CompactUnitActionState: View {
    let code: String
    let readyIcon: String
    let isConsumed: Bool
    let readyColor: Color

    var body: some View {
        HStack(spacing: 1) {
            Text(code)
            Image(systemName: isConsumed ? "checkmark" : readyIcon)
        }
        .font(.system(size: 9, weight: .black, design: .rounded))
        .foregroundStyle(isConsumed ? Color.white.opacity(0.72) : readyColor)
        .frame(width: 22, height: 13)
        .background(Color.black.opacity(0.52), in: Capsule())
        .overlay {
            Capsule()
                .stroke(isConsumed ? Color.white.opacity(0.30) : readyColor.opacity(0.62), lineWidth: 0.6)
        }
        .accessibilityHidden(true)
    }
}

struct MapIntelPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.black))
            Text(title)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Spacer(minLength: 3)
            Text(value)
                .font(.caption.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .foregroundStyle(color)
        .frame(minWidth: 104)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.20), lineWidth: 1)
        )
    }
}
