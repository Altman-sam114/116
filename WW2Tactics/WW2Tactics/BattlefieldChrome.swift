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

            EndTurnButton(iconOnly: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
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
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 7) {
                Text("WW2")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(BattlefieldTheme.brass, in: Capsule())
                Text(game.scenario.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(BattlefieldTheme.ink)
            }
            Text("\(game.scenario.year) · 战区指挥台")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BattlefieldTheme.mutedInk)
        }
    }
}

struct StatusStrip: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        HStack(spacing: 6) {
            StatusChip(icon: "flag.fill", label: "回合 \(game.turn)")
            StatusChip(icon: "hourglass", label: "剩余 \(game.remainingTurns)")
            StatusChip(icon: "shield.lefthalf.filled", label: game.activeFaction.title)
            StatusChip(icon: "scope", label: "据点 \(game.alliedScore):\(game.axisScore)")
            StatusChip(icon: "star.circle.fill", label: "指令 \(game.activeCommandPoints)")
            StatusChip(icon: "person.3.fill", label: "待命 \(game.readyUnitCount)")
        }
    }
}

struct EndTurnButton: View {
    @EnvironmentObject private var game: GameState
    var iconOnly = false

    var body: some View {
        Button {
            game.endTurn()
        } label: {
            if iconOnly {
                Image(systemName: "forward.end.fill")
                    .font(.body.weight(.bold))
                    .frame(width: 44, height: 44)
            } else {
                Label("结束回合", systemImage: "forward.end.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(BattlefieldTheme.alert)
        .disabled(game.winner != nil)
        .accessibilityLabel("结束回合")
    }
}

struct StatusChip: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(BattlefieldTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(BattlefieldTheme.fieldGlass.opacity(0.62), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(BattlefieldTheme.hairline, lineWidth: 1)
            )
    }
}

struct BattlefieldView: View {
    @EnvironmentObject private var game: GameState
    @State private var mapScaleMode: MapScaleMode = .campaign
    @State private var isSupportDeckExpanded = false

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Label {
                    Text(game.message)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(BattlefieldTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } icon: {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundStyle(BattlefieldTheme.signal)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(BattlefieldTheme.commandDeckDeep.opacity(0.56), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BattlefieldTheme.hairline, lineWidth: 1)
                )

                Button {
                    game.restart()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityLabel("重新开始")
            }

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

    var scale: CGFloat {
        switch self {
        case .campaign:
            0.86
        case .tactical:
            1.0
        case .detail:
            1.14
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

            ZStack {
                ScrollViewReader { proxy in
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        HexMapView(tileScale: mapScaleMode.scale)
                            .padding(22)
                    }
                    .onAppear {
                        scrollToFocusedCoordinate(with: proxy, animated: false)
                    }
                    .onChange(of: game.focusedCoordinate?.id) { _, _ in
                        scrollToFocusedCoordinate(with: proxy, animated: true)
                    }
                }

                GeometryReader { mapProxy in
                    let isCompactMapChrome = mapProxy.size.width < 680

                    VStack(spacing: 0) {
                        HStack(alignment: .top) {
                            Spacer(minLength: 8)
                            MapActionHUD(compact: isCompactMapChrome)
                        }
                        .padding(isCompactMapChrome ? 6 : 8)

                        Spacer(minLength: 6)

                        ObjectiveJumpDock()
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
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
                HStack(spacing: 7) {
                    UnitShapeBadge(
                        kind: unit.kind,
                        faction: unit.faction,
                        hasCommander: unit.commander != nil,
                        rank: unit.rank,
                        supplyState: game.supplyState(for: unit),
                        tacticalStatus: unit.tacticalStatus,
                        isSpent: unit.hasMoved && unit.hasAttacked,
                        width: 48,
                        height: 28
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(unit.name)
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("\(unit.kind.title) · HP \(unit.hp)/\(unit.maxHP)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer(minLength: 4)

                    Button {
                        game.waitSelectedUnit()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.caption.weight(.black))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .disabled(unit.hasMoved && unit.hasAttacked)
                    .accessibilityLabel("待命")
                }

                HStack(spacing: 5) {
                    MapHudMetric(icon: "point.topleft.down.curvedto.point.bottomright.up", label: "MOVE", value: "\(game.reachableTiles(for: unit).count)", color: .cyan)
                    MapHudMetric(icon: "target", label: "ATK", value: "\(game.attackableTiles(for: unit).count)", color: .orange)
                    MapHudMetric(icon: "exclamationmark.triangle.fill", label: "THR", value: "\(game.threatenedReachableTiles(for: unit).count)", color: .red)
                    MapHudMetric(icon: game.supplyState(for: unit) == .supplied ? "fuelpump.fill" : "exclamationmark.octagon.fill", label: game.supplyState(for: unit).shortTitle, value: "\(max(0, game.supplyLineTiles(for: unit).count - 1))", color: game.supplyState(for: unit) == .supplied ? .green : .red)
                }

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
            } else {
                HStack(spacing: 7) {
                    Image(systemName: "scope")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.yellow)
                        .frame(width: 24, height: 24)
                        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 5))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(focusTitle)
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(game.message)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                }

                MapQuickCommandButton(
                    icon: "forward.fill",
                    title: "NEXT",
                    color: .yellow,
                    isEnabled: !game.readyUnits.isEmpty
                ) {
                    game.selectNextReadyUnitFromMap()
                }
            }
        }
        .padding(compact ? 7 : 8)
        .frame(width: compact ? 268 : 304, alignment: .leading)
        .background(MapHudBackground())
    }

    private var focusTitle: String {
        if let unit = game.focusedUnit {
            return "\(unit.faction.title) \(unit.name)"
        }
        if let tile = game.focusedTile {
            return tile.objectiveName ?? tile.terrain.title
        }
        return "战场焦点"
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
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
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
    var body: some View {
        ObjectiveJumpStrip()
            .padding(8)
            .background(MapHudBackground())
    }
}

struct MapHudMetric: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(game.mapFriendlyFocusUnits) { unit in
                    UnitFocusButton(unit: unit)
                }

                Divider()
                    .frame(height: 30)
                    .overlay(Color.white.opacity(0.16))

                ForEach(game.objectiveTiles.sorted(by: objectiveSort)) { tile in
                    ObjectiveJumpButton(tile: tile)
                }

                Divider()
                    .frame(height: 30)
                    .overlay(Color.white.opacity(0.16))

                ForEach(game.mapEnemyFocusUnits) { unit in
                    UnitFocusButton(unit: unit)
                }
            }
            .padding(.vertical, 1)
        }
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

struct ObjectiveJumpButton: View {
    @EnvironmentObject private var game: GameState
    let tile: TerrainTile

    var body: some View {
        Button {
            game.focus(coordinate: tile.coordinate)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.caption2.weight(.black))
                Text(tile.objectiveName ?? "据点")
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text(ownerCode)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(ownerColor.opacity(0.18), in: Capsule())
            }
            .foregroundStyle(ownerColor)
            .frame(minHeight: 40)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(isFocused ? 0.14 : 0.07), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isFocused ? Color.yellow : ownerColor.opacity(0.22), lineWidth: isFocused ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("定位据点\(tile.objectiveName ?? "据点")")
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
}

struct UnitFocusButton: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        Button {
            if unit.faction == game.activeFaction {
                game.select(unitID: unit.id)
            } else {
                game.focus(unitID: unit.id)
            }
        } label: {
            HStack(spacing: 6) {
                UnitShapeBadge(
                    kind: unit.kind,
                    faction: unit.faction,
                    hasCommander: unit.commander != nil,
                    rank: unit.rank,
                    supplyState: game.supplyState(for: unit),
                    tacticalStatus: unit.tacticalStatus,
                    isSpent: unit.hasMoved && unit.hasAttacked,
                    width: 34,
                    height: 20
                )
                Text(unit.name)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .foregroundStyle(.white.opacity(0.82))
            .frame(minHeight: 40)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(isFocused ? 0.14 : 0.07), in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isFocused ? Color.yellow : unit.faction.accentColor.opacity(0.22), lineWidth: isFocused ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unit.faction == game.activeFaction ? "选择\(unit.name)" : "定位\(unit.name)")
    }

    private var isFocused: Bool {
        game.focusedUnit?.id == unit.id
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
