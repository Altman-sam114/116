import SwiftUI

struct MiniHealthBar: View {
    let ratio: CGFloat
    /// GoG3-style faction-tinted bar: allies blue / axis red. nil keeps the
    /// classic green-red readiness coloring used by HUD and side panels.
    var factionTint: Color? = nil

    var body: some View {
        GeometryReader { proxy in
            let clampedRatio = max(0, min(ratio, 1))

            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.52))
                Capsule()
                    .fill(fillColor(for: clampedRatio))
                    .frame(width: proxy.size.width * clampedRatio)
            }
            .clipShape(Capsule())
            .overlay {
                Path { path in
                    for index in 1..<5 {
                        let x = proxy.size.width * CGFloat(index) / 5
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }
                }
                .stroke(Color.black.opacity(0.34), lineWidth: 0.6)
            }
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.30), lineWidth: 0.6)
            }
        }
        .accessibilityHidden(true)
    }

    private func fillColor(for clampedRatio: CGFloat) -> Color {
        if let factionTint {
            return clampedRatio > 0.3 ? factionTint : Color.red
        }
        return clampedRatio > 0.45 ? Color.green : Color.red
    }
}

struct UnitCounter: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        VStack(spacing: 3) {
            MapUnitPiece(
                kind: unit.kind,
                faction: unit.faction,
                rank: unit.rank,
                supplyState: game.supplyState(for: unit),
                tacticalStatus: unit.tacticalStatus,
                isSpent: isActionComplete,
                width: unit.kind.mapPieceWidth,
                height: 44
            )
            .overlay(alignment: .topLeading) {
                if let commander = unit.commander {
                    CommanderBadge(commander: commander, faction: unit.faction)
                        .offset(x: -6, y: -7)
                }
            }
            .opacity(isActionComplete ? 0.78 : 1)

            HStack(spacing: 3) {
                readinessSlot(symbol: readiness.moveSymbol, available: readiness.canMove)
                MiniHealthBar(ratio: unit.hpRatio, factionTint: unit.faction.accentColor)
                    .frame(width: 38, height: 5)
                readinessSlot(symbol: readiness.attackSymbol, available: readiness.canAttack)
            }
            .frame(width: 65, height: 12)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var isActionComplete: Bool {
        unit.hasMoved && unit.hasAttacked
    }

    private var readiness: UnitReadinessPresentation {
        UnitReadinessPresentation(hasMoved: unit.hasMoved, hasAttacked: unit.hasAttacked)
    }

    private func readinessSlot(symbol: String, available: Bool) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 6, weight: .heavy))
            .foregroundStyle(available ? Color.white : Color.white.opacity(0.48))
            .frame(width: 10, height: 10)
            .background(available ? unit.faction.accentColor.opacity(0.85) : Color.black.opacity(0.55), in: Circle())
    }

    private var accessibilitySummary: String {
        let commanderText = unit.commander.map { "，将领\($0.name)" } ?? ""
        let supplyText = game.supplyState(for: unit).title
        return "\(unit.name)，\(unit.kind.title)，\(unit.faction.title)，生命 \(unit.hp) / \(unit.maxHP)\(commanderText)，\(unit.rank.title)，\(supplyText)，\(unit.tacticalStatus.title)，\(unit.actionStateText)"
    }
}

struct MapUnitPiece: View {
    let kind: UnitKind
    let faction: Faction
    let rank: UnitRank
    let supplyState: SupplyState
    let tacticalStatus: UnitTacticalStatus
    let isSpent: Bool
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            MapUnitGrounding(faction: faction, isSpent: isSpent)
                .frame(width: width * 0.98, height: height * 0.58)
                .offset(y: height * 0.12)

            UnitModelView(
                kind: kind,
                faction: faction,
                isSpent: isSpent,
                presentation: .mapPiece
            )
                .frame(width: width - 4, height: height - 4)
                .offset(y: -2)

            // Faction ring + tinted HP bar carry allegiance; rank shows as a
            // bare gold insignia (GoG3-style chevron) without a dark capsule.
            Text(faction.shortTitle + " " + rank.insignia)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.98, green: 0.83, blue: 0.36))
                .shadow(color: .black.opacity(0.85), radius: 0.6, x: 0.5, y: 0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            if supplyState == .isolated {
                Text("CUT")
                    .font(.system(size: 6, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.red.opacity(0.82), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(BattlefieldTheme.mapUnitStatusBackdrop, lineWidth: 0.6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if tacticalStatus != .normal {
                Text(tacticalStatus.shortTitle)
                    .font(.system(size: 6, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(tacticalStatus.mapColor.opacity(0.82), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(BattlefieldTheme.mapUnitStatusBackdrop, lineWidth: 0.6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

private struct MapUnitGrounding: View {
    let faction: Faction
    let isSpent: Bool

    var body: some View {
        GeometryReader { proxy in
            let contactOpacity = isSpent ? 0.16 : 0.28
            let baseOpacity = isSpent ? 0.20 : 0.36
            let rimOpacity = isSpent ? 0.34 : 0.62

            ZStack {
                Ellipse()
                    .fill(BattlefieldTheme.mapUnitContactShadow.opacity(contactOpacity / 0.28))
                    .frame(width: proxy.size.width * 0.94, height: proxy.size.height * 0.38)
                    .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.75)

                // GoG3-inspired faction halo: shape and HP remain readable
                // even when color differentiation is disabled.
                Ellipse()
                    .fill(faction.accentColor.opacity(isSpent ? 0.12 : 0.20))
                    .overlay {
                        Ellipse()
                            .stroke(
                                faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing,
                                style: StrokeStyle(lineWidth: isSpent ? 0.9 : 1.5, dash: faction == .allies ? [] : [4, 2])
                            )
                    }
                    .overlay {
                        Ellipse()
                            .stroke(Color.white.opacity(isSpent ? 0.08 : 0.24), lineWidth: 0.55)
                            .scaleEffect(0.86)
                    }
                    .frame(width: proxy.size.width * 0.96, height: proxy.size.height * 0.66)
                    .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.53)

                RoundedRectangle(cornerRadius: proxy.size.height * 0.34)
                    .fill(
                        LinearGradient(
                            colors: [
                                faction.accentColor.opacity(baseOpacity),
                                BattlefieldTheme.mapUnitBaseInset.opacity(isSpent ? 0.46 : 0.72)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: proxy.size.height * 0.34)
                            .stroke(faction.accentColor.opacity(rimOpacity), lineWidth: 0.9)
                    }
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: proxy.size.height * 0.34)
                            .stroke(BattlefieldTheme.mapUnitBaseHighlight.opacity(isSpent ? 0.35 : 0.72), lineWidth: 0.55)
                            .mask(alignment: .top) {
                                Rectangle().frame(height: proxy.size.height * 0.42)
                            }
                    }
                    .frame(width: proxy.size.width * 0.82, height: proxy.size.height * 0.57)
                    .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.57)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct UnitShapeBadge: View {
    let kind: UnitKind
    let faction: Faction
    var hasCommander = false
    var rank: UnitRank = .green
    var supplyState: SupplyState = .supplied
    var tacticalStatus: UnitTacticalStatus = .normal
    var isSpent = false
    var width: CGFloat = 44
    var height: CGFloat = 24
    var lineWidth: CGFloat = 1

    var body: some View {
        ZStack {
            FactionBaseShape(faction: faction)
                .fill(
                    LinearGradient(
                        colors: [
                            faction.accentColor.opacity(isSpent ? 0.66 : 0.96),
                            faction.accentColor.opacity(isSpent ? 0.42 : 0.72),
                            Color.black.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    FactionBaseShape(faction: faction)
                        .stroke(
                            faction == .allies ? Color.white.opacity(0.72) : BattlefieldTheme.brass.opacity(0.82),
                            style: StrokeStyle(lineWidth: lineWidth, dash: faction == .axis ? [3, 2] : [])
                        )
                }
                .shadow(color: .black.opacity(0.42), radius: 2, x: 0, y: 2)

            UnitModelView(kind: kind, faction: faction, isSpent: isSpent)
                .padding(.horizontal, 5)
                .padding(.vertical, 4)

            Text(rank.insignia)
                .font(.system(size: 6, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(BattlefieldTheme.commandDeckDeep.opacity(0.58), in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 2)
                .padding(.bottom, 1)

            if supplyState == .isolated {
                Text("CUT")
                    .font(.system(size: 6, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.red.opacity(0.92), in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 3)
                    .padding(.top, 2)
            }

            if tacticalStatus != .normal {
                Text(tacticalStatus.shortTitle)
                    .font(.system(size: 6, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(tacticalStatus.mapColor.opacity(0.95), in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 3)
                    .padding(.top, 2)
            }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rank.title)\(kind.title)\(hasCommander ? "，有将领" : "")，\(supplyState.title)，\(tacticalStatus.title)")
    }
}

struct UnitModelView: View {
    let kind: UnitKind
    let faction: Faction
    let isSpent: Bool
    var presentation: UnitModelPresentation = .compactBadge

    var body: some View {
        BattlefieldUnitRenderer(kind: kind, faction: faction, isSpent: isSpent)
    }
}

enum UnitModelPresentation: Equatable {
    case compactBadge
    case mapPiece
}

struct CommanderBadge: View {
    let commander: Commander
    let faction: Faction

    var body: some View {
        // GoG3-style portrait plaque: warm parchment tile with a gold frame.
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.93, green: 0.87, blue: 0.72),
                            Color(red: 0.78, green: 0.70, blue: 0.54)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(red: 0.85, green: 0.66, blue: 0.30), lineWidth: 1.4)
            Image(systemName: "person.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 0.32, green: 0.26, blue: 0.18))
            Circle()
                .fill(faction.accentColor)
                .frame(width: 6, height: 6)
                .offset(x: 7, y: 7)
        }
        .frame(width: 20, height: 20)
        .shadow(color: .black.opacity(0.4), radius: 1.5, y: 1)
        .accessibilityHidden(true)
    }
}

struct FactionBaseShape: Shape {
    let faction: Faction

    func path(in rect: CGRect) -> Path {
        if faction == .allies {
            return Path(roundedRect: rect, cornerRadius: rect.height * 0.48)
        }

        var path = Path()
        let bevel = rect.height * 0.22
        path.move(to: CGPoint(x: rect.minX + bevel, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - bevel, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - bevel, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bevel, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

extension UnitTacticalStatus {
    var mapColor: Color {
        switch self {
        case .normal:
            .white.opacity(0.36)
        case .suppressed:
            .purple
        case .disrupted:
            .orange
        }
    }
}

extension UnitKind {
    var tacticalSymbol: String {
        switch self {
        case .infantry:
            "■"
        case .tank:
            "▰"
        case .artillery:
            "▲"
        case .recon:
            "◆"
        }
    }

    var counterWidth: CGFloat {
        switch self {
        case .infantry:
            52
        case .tank:
            58
        case .artillery:
            55
        case .recon:
            53
        }
    }

    var mapPieceWidth: CGFloat {
        switch self {
        case .infantry:
            68
        case .tank:
            74
        case .artillery:
            71
        case .recon:
            70
        }
    }
}

extension Faction {
    func unitModelGradient(isSpent: Bool) -> LinearGradient {
        let opacity = isSpent ? 0.72 : 1.0
        return LinearGradient(
            colors: unitModelColors.map { $0.opacity(opacity) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var unitModelEdgeColor: Color {
        switch self {
        case .allies:
            Color(red: 0.12, green: 0.16, blue: 0.10)
        case .axis:
            Color(red: 0.13, green: 0.12, blue: 0.11)
        }
    }

    var unitModelDetailColor: Color {
        switch self {
        case .allies:
            Color(red: 0.10, green: 0.15, blue: 0.08)
        case .axis:
            Color(red: 0.16, green: 0.13, blue: 0.11)
        }
    }

    var unitModelDepthColor: Color {
        switch self {
        case .allies:
            Color(red: 0.09, green: 0.12, blue: 0.07)
        case .axis:
            Color(red: 0.10, green: 0.09, blue: 0.08)
        }
    }

    var unitModelPlateColor: Color {
        switch self {
        case .allies:
            Color(red: 0.66, green: 0.68, blue: 0.43)
        case .axis:
            Color(red: 0.60, green: 0.61, blue: 0.70)
        }
    }

    var unitModelHighlightColor: Color {
        switch self {
        case .allies:
            Color(red: 0.91, green: 0.90, blue: 0.65)
        case .axis:
            Color(red: 0.83, green: 0.85, blue: 0.93)
        }
    }

    private var unitModelColors: [Color] {
        switch self {
        case .allies:
            [
                Color(red: 0.76, green: 0.76, blue: 0.54),
                Color(red: 0.43, green: 0.47, blue: 0.30),
                Color(red: 0.22, green: 0.27, blue: 0.17)
            ]
        case .axis:
            // GoG3-style German field-blue armor plate.
            [
                Color(red: 0.68, green: 0.70, blue: 0.79),
                Color(red: 0.42, green: 0.44, blue: 0.54),
                Color(red: 0.22, green: 0.23, blue: 0.30)
            ]
        }
    }
}

extension BattleUnit {
    var hpRatio: CGFloat {
        CGFloat(max(0, min(hp, maxHP))) / CGFloat(maxHP)
    }

    var actionStateText: String {
        if isEntrenched {
            return "防御"
        }

        return switch (hasMoved, hasAttacked) {
        case (false, false):
            "待命"
        case (true, false):
            "已移动"
        case (false, true):
            "已攻击"
        case (true, true):
            "完成"
        }
    }
}
