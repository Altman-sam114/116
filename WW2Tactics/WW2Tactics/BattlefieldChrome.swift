import SwiftUI

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
            .frame(height: 72)
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
        WarLedgerSurface(cornerRadius: 7, isMapOverlay: true)
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
                        ? [BattlefieldTheme.warLedgerMapOverlay.opacity(0.88), .clear]
                        : [.clear, BattlefieldTheme.warLedgerMapOverlay.opacity(0.88)],
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
