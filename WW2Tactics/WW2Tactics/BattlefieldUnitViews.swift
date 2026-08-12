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
                // Single readiness pip replaces the old move/attack chip pair:
                // green = fully ready, yellow = one action left, gray = done.
                Circle()
                    .fill(readinessColor)
                    .frame(width: 7, height: 7)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.55), lineWidth: 0.8)
                    }

                MiniHealthBar(
                    ratio: unit.hpRatio,
                    factionTint: unit.faction == .allies
                        ? Color(red: 0.30, green: 0.62, blue: 0.92)
                        : Color(red: 0.86, green: 0.26, blue: 0.22)
                )
                    .frame(width: 40, height: 6)
            }
            .frame(width: 56, height: 11)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var isActionComplete: Bool {
        unit.hasMoved && unit.hasAttacked
    }

    private var readinessColor: Color {
        switch (unit.hasMoved, unit.hasAttacked) {
        case (false, false):
            return Color.green
        case (true, true):
            return Color.white.opacity(0.55)
        default:
            return Color.yellow
        }
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
                .frame(width: width * 0.86, height: height * 0.36)
                .offset(y: height * 0.21)

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
            Text(rank.insignia)
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
        GeometryReader { proxy in
            let detailLineWidth = max(0.45, min(proxy.size.height * 0.035, 0.9))
            let depthOffset = max(1.0, proxy.size.height * (presentation == .mapPiece ? 0.060 : 0.050))
            let modelShadowOpacity = isSpent ? 0.22 : 0.50

            ZStack {
                if presentation == .compactBadge {
                    Ellipse()
                        .fill(BattlefieldTheme.mapUnitContactShadow.opacity(isSpent ? 0.60 : 1))
                        .frame(width: proxy.size.width * 0.80, height: max(2, proxy.size.height * 0.20))
                        .position(x: proxy.size.width * 0.48, y: proxy.size.height * 0.85)
                }

                ZStack {
                    UnitMarkerShape(kind: kind)
                        .fill(faction.unitModelDepthColor.opacity(isSpent ? 0.56 : 0.92))
                        .offset(y: depthOffset)

                    UnitMarkerShape(kind: kind)
                        .fill(faction.unitModelGradient(isSpent: isSpent))
                        .overlay {
                            UnitMarkerShape(kind: kind)
                                .fill(
                                    LinearGradient(
                                    colors: [
                                            BattlefieldTheme.mapUnitTopHighlight.opacity(isSpent ? 0.36 : 1),
                                            .clear,
                                            Color.black.opacity(0.22)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .overlay {
                            UnitMarkerShape(kind: kind)
                                .stroke(faction.unitModelEdgeColor.opacity(isSpent ? 0.64 : 0.92), lineWidth: detailLineWidth + 0.25)
                        }

                    UnitModelPlateShape(kind: kind)
                        .fill(faction.unitModelPlateColor.opacity(isSpent ? 0.44 : 0.78))

                    UnitModelDetailShape(kind: kind)
                        .stroke(
                            faction.unitModelDetailColor.opacity(isSpent ? 0.48 : 0.78),
                            style: StrokeStyle(lineWidth: detailLineWidth, lineCap: .round, lineJoin: .round)
                        )

                    UnitModelHighlightShape(kind: kind)
                        .stroke(
                            faction.unitModelHighlightColor.opacity(isSpent ? 0.32 : 0.70),
                            style: StrokeStyle(lineWidth: detailLineWidth * 0.72, lineCap: .round, lineJoin: .round)
                        )
                }
                .padding(.horizontal, 1)
                .padding(.bottom, 4)
                .offset(y: -2)
                .shadow(color: BattlefieldTheme.mapUnitModelShadow.opacity(modelShadowOpacity / 0.42), radius: 1.3, x: 0, y: 1.4)
            }
        }
        .accessibilityHidden(true)
    }
}

enum UnitModelPresentation: Equatable {
    case compactBadge
    case mapPiece
}

struct UnitModelPlateShape: Shape {
    let kind: UnitKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .infantry:
            infantryPlate(in: rect)
        case .tank:
            tankPlate(in: rect)
        case .artillery:
            artilleryPlate(in: rect)
        case .recon:
            reconPlate(in: rect)
        }
    }

    private func infantryPlate(in rect: CGRect) -> Path {
        var path = Path()
        let helmetSize = rect.height * 0.16
        for centerX in [0.30, 0.51, 0.70] {
            path.addEllipse(
                in: CGRect(
                    x: rect.minX + rect.width * centerX - helmetSize / 2,
                    y: rect.minY + rect.height * 0.015,
                    width: helmetSize,
                    height: helmetSize * 0.72
                )
            )
            path.addRoundedRect(
                in: CGRect(
                    x: rect.minX + rect.width * centerX - helmetSize * 0.28,
                    y: rect.minY + rect.height * 0.30,
                    width: helmetSize * 0.56,
                    height: rect.height * 0.22
                ),
                cornerSize: CGSize(width: helmetSize * 0.16, height: helmetSize * 0.16)
            )
        }
        return path
    }

    private func tankPlate(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(
                x: rect.minX + rect.width * 0.30,
                y: rect.minY + rect.height * 0.055,
                width: rect.width * 0.35,
                height: rect.height * 0.30
            ),
            cornerSize: CGSize(width: rect.height * 0.10, height: rect.height * 0.10)
        )
        path.move(to: point(x: 0.12, y: 0.34, in: rect))
        path.addLine(to: point(x: 0.76, y: 0.34, in: rect))
        path.addLine(to: point(x: 0.69, y: 0.54, in: rect))
        path.addLine(to: point(x: 0.18, y: 0.54, in: rect))
        path.closeSubpath()
        return path
    }

    private func artilleryPlate(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(x: 0.32, y: 0.38, in: rect))
        path.addLine(to: point(x: 0.61, y: 0.30, in: rect))
        path.addLine(to: point(x: 0.68, y: 0.63, in: rect))
        path.addLine(to: point(x: 0.38, y: 0.66, in: rect))
        path.closeSubpath()
        path.addEllipse(
            in: CGRect(
                x: rect.minX + rect.width * 0.46,
                y: rect.minY + rect.height * 0.42,
                width: rect.height * 0.18,
                height: rect.height * 0.18
            )
        )
        return path
    }

    private func reconPlate(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(x: 0.28, y: 0.27, in: rect))
        path.addLine(to: point(x: 0.66, y: 0.27, in: rect))
        path.addLine(to: point(x: 0.77, y: 0.49, in: rect))
        path.addLine(to: point(x: 0.20, y: 0.49, in: rect))
        path.closeSubpath()
        path.addRoundedRect(
            in: CGRect(
                x: rect.minX + rect.width * 0.52,
                y: rect.minY + rect.height * 0.49,
                width: rect.width * 0.34,
                height: rect.height * 0.16
            ),
            cornerSize: CGSize(width: rect.height * 0.04, height: rect.height * 0.04)
        )
        return path
    }

    private func point(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }
}

struct UnitModelHighlightShape: Shape {
    let kind: UnitKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .infantry:
            infantryHighlight(in: rect)
        case .tank:
            tankHighlight(in: rect)
        case .artillery:
            artilleryHighlight(in: rect)
        case .recon:
            reconHighlight(in: rect)
        }
    }

    private func infantryHighlight(in rect: CGRect) -> Path {
        var path = Path()
        for centerX in [0.30, 0.51, 0.70] {
            path.move(to: point(x: centerX - 0.055, y: 0.09, in: rect))
            path.addLine(to: point(x: centerX + 0.045, y: 0.09, in: rect))
            path.move(to: point(x: centerX - 0.045, y: 0.35, in: rect))
            path.addLine(to: point(x: centerX + 0.035, y: 0.31, in: rect))
        }
        return path
    }

    private func tankHighlight(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(x: 0.11, y: 0.32, in: rect))
        path.addLine(to: point(x: 0.72, y: 0.32, in: rect))
        path.move(to: point(x: 0.34, y: 0.10, in: rect))
        path.addLine(to: point(x: 0.61, y: 0.10, in: rect))
        path.move(to: point(x: 0.63, y: 0.18, in: rect))
        path.addLine(to: point(x: 0.94, y: 0.18, in: rect))
        return path
    }

    private func artilleryHighlight(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(x: 0.43, y: 0.47, in: rect))
        path.addLine(to: point(x: 0.94, y: 0.15, in: rect))
        path.move(to: point(x: 0.35, y: 0.40, in: rect))
        path.addLine(to: point(x: 0.60, y: 0.33, in: rect))
        return path
    }

    private func reconHighlight(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(x: 0.30, y: 0.30, in: rect))
        path.addLine(to: point(x: 0.63, y: 0.30, in: rect))
        path.move(to: point(x: 0.55, y: 0.52, in: rect))
        path.addLine(to: point(x: 0.82, y: 0.52, in: rect))
        path.move(to: point(x: 0.52, y: 0.22, in: rect))
        path.addLine(to: point(x: 0.52, y: 0.05, in: rect))
        return path
    }

    private func point(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }
}

struct UnitModelDetailShape: Shape {
    let kind: UnitKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .infantry:
            infantryDetails(in: rect)
        case .tank:
            tankDetails(in: rect)
        case .artillery:
            artilleryDetails(in: rect)
        case .recon:
            reconDetails(in: rect)
        }
    }

    private func infantryDetails(in rect: CGRect) -> Path {
        var path = Path()
        for centerX in [0.30, 0.51, 0.70] {
            path.move(to: point(x: centerX, y: 0.29, in: rect))
            path.addLine(to: point(x: centerX, y: 0.72, in: rect))
        }
        path.move(to: point(x: 0.16, y: 0.70, in: rect))
        path.addLine(to: point(x: 0.91, y: 0.33, in: rect))
        return path
    }

    private func tankDetails(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(x: 0.06, y: 0.28, in: rect))
        path.addLine(to: point(x: 0.76, y: 0.28, in: rect))
        path.move(to: point(x: 0.06, y: 0.72, in: rect))
        path.addLine(to: point(x: 0.76, y: 0.72, in: rect))

        let wheelSize = rect.height * 0.13
        for centerX in [0.17, 0.35, 0.53, 0.70] {
            path.addEllipse(
                in: CGRect(
                    x: rect.minX + rect.width * centerX - wheelSize / 2,
                    y: rect.minY + rect.height * 0.72 - wheelSize / 2,
                    width: wheelSize,
                    height: wheelSize
                )
            )
        }

        path.addRoundedRect(
            in: CGRect(
                x: rect.minX + rect.width * 0.31,
                y: rect.minY + rect.height * 0.08,
                width: rect.width * 0.33,
                height: rect.height * 0.27
            ),
            cornerSize: CGSize(width: rect.height * 0.08, height: rect.height * 0.08)
        )
        // Commander hatch on the turret roof.
        let hatchSize = rect.height * 0.12
        path.addEllipse(
            in: CGRect(
                x: rect.minX + rect.width * 0.41 - hatchSize / 2,
                y: rect.minY + rect.height * 0.15 - hatchSize / 2,
                width: hatchSize,
                height: hatchSize
            )
        )
        path.move(to: point(x: 0.61, y: 0.20, in: rect))
        path.addLine(to: point(x: 0.96, y: 0.20, in: rect))
        // Muzzle brake tick at the barrel tip.
        path.move(to: point(x: 0.93, y: 0.15, in: rect))
        path.addLine(to: point(x: 0.93, y: 0.25, in: rect))
        return path
    }

    private func artilleryDetails(in rect: CGRect) -> Path {
        var path = Path()
        let wheelSize = rect.height * 0.19
        for centerX in [0.35, 0.73] {
            path.addEllipse(
                in: CGRect(
                    x: rect.minX + rect.width * centerX - wheelSize / 2,
                    y: rect.minY + rect.height * 0.78 - wheelSize / 2,
                    width: wheelSize,
                    height: wheelSize
                )
            )
        }
        path.move(to: point(x: 0.20, y: 0.72, in: rect))
        path.addLine(to: point(x: 0.49, y: 0.52, in: rect))
        path.addLine(to: point(x: 0.82, y: 0.72, in: rect))
        path.move(to: point(x: 0.39, y: 0.51, in: rect))
        path.addLine(to: point(x: 0.95, y: 0.17, in: rect))
        return path
    }

    private func reconDetails(in rect: CGRect) -> Path {
        var path = Path()
        let wheelSize = rect.height * 0.13
        for centerX in [0.28, 0.72] {
            path.addEllipse(
                in: CGRect(
                    x: rect.minX + rect.width * centerX - wheelSize / 2,
                    y: rect.minY + rect.height * 0.76 - wheelSize / 2,
                    width: wheelSize,
                    height: wheelSize
                )
            )
        }
        path.move(to: point(x: 0.28, y: 0.34, in: rect))
        path.addLine(to: point(x: 0.72, y: 0.34, in: rect))
        path.addLine(to: point(x: 0.82, y: 0.52, in: rect))
        path.move(to: point(x: 0.52, y: 0.25, in: rect))
        path.addLine(to: point(x: 0.52, y: 0.05, in: rect))
        return path
    }

    private func point(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }
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

struct UnitMarkerShape: Shape {
    let kind: UnitKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .infantry:
            return infantryPath(in: rect)
        case .tank:
            return tankPath(in: rect)
        case .artillery:
            return artilleryPath(in: rect)
        case .recon:
            return reconPath(in: rect)
        }
    }

    private func infantryPath(in rect: CGRect) -> Path {
        var path = Path()
        let head = rect.height * 0.17
        for centerX in [0.30, 0.51, 0.70] {
            path.addEllipse(in: CGRect(x: rect.minX + rect.width * centerX - head / 2, y: rect.minY + rect.height * 0.07, width: head, height: head * 0.78))
            path.addRoundedRect(
                in: CGRect(x: rect.minX + rect.width * centerX - head * 0.42, y: rect.minY + rect.height * 0.28, width: head * 0.84, height: rect.height * 0.46),
                cornerSize: CGSize(width: head * 0.28, height: head * 0.28)
            )
        }
        path.move(to: point(x: 0.12, y: 0.72, in: rect))
        path.addLine(to: point(x: 0.90, y: 0.34, in: rect))
        path.addLine(to: point(x: 0.93, y: 0.40, in: rect))
        path.addLine(to: point(x: 0.15, y: 0.78, in: rect))
        path.closeSubpath()
        return path
    }

    private func tankPath(in rect: CGRect) -> Path {
        let track = CGRect(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.62, width: rect.width * 0.76, height: rect.height * 0.22)
        let turret = CGRect(
            x: rect.minX + rect.width * 0.31,
            y: rect.minY + rect.height * 0.12,
            width: rect.width * 0.31,
            height: rect.height * 0.28
        )

        var path = Path()
        path.addRoundedRect(in: track, cornerSize: CGSize(width: rect.height * 0.11, height: rect.height * 0.11))
        path.move(to: point(x: 0.12, y: 0.60, in: rect))
        path.addLine(to: point(x: 0.22, y: 0.36, in: rect))
        path.addLine(to: point(x: 0.69, y: 0.36, in: rect))
        path.addLine(to: point(x: 0.80, y: 0.60, in: rect))
        path.closeSubpath()
        path.addRoundedRect(
            in: turret,
            cornerSize: CGSize(width: rect.height * 0.12, height: rect.height * 0.12)
        )
        path.addRoundedRect(
            in: CGRect(x: rect.minX + rect.width * 0.59, y: rect.minY + rect.height * 0.20, width: rect.width * 0.34, height: rect.height * 0.10),
            cornerSize: CGSize(width: rect.height * 0.04, height: rect.height * 0.04)
        )
        return path
    }

    private func artilleryPath(in rect: CGRect) -> Path {
        var path = Path()
        let wheel = rect.height * 0.31
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.18, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.57, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.move(to: point(x: 0.29, y: 0.68, in: rect))
        path.addLine(to: point(x: 0.45, y: 0.40, in: rect))
        path.addLine(to: point(x: 0.67, y: 0.58, in: rect))
        path.addLine(to: point(x: 0.75, y: 0.68, in: rect))
        path.closeSubpath()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.34, width: rect.width * 0.25, height: rect.height * 0.25), cornerSize: CGSize(width: rect.height * 0.05, height: rect.height * 0.05))
        path.move(to: point(x: 0.49, y: 0.42, in: rect))
        path.addLine(to: point(x: 0.95, y: 0.10, in: rect))
        path.addLine(to: point(x: 0.98, y: 0.17, in: rect))
        path.addLine(to: point(x: 0.53, y: 0.48, in: rect))
        path.closeSubpath()
        return path
    }

    private func reconPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(x: 0.10, y: 0.48, in: rect))
        path.addLine(to: point(x: 0.24, y: 0.30, in: rect))
        path.addLine(to: point(x: 0.65, y: 0.30, in: rect))
        path.addLine(to: point(x: 0.84, y: 0.49, in: rect))
        path.addLine(to: point(x: 0.77, y: 0.69, in: rect))
        path.addLine(to: point(x: 0.16, y: 0.69, in: rect))
        path.closeSubpath()
        let wheel = rect.height * 0.25
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.19, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.60, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.16, width: rect.width * 0.24, height: rect.height * 0.22), cornerSize: CGSize(width: rect.height * 0.07, height: rect.height * 0.07))
        path.addRect(CGRect(x: rect.minX + rect.width * 0.50, y: rect.minY + rect.height * 0.02, width: rect.width * 0.035, height: rect.height * 0.20))
        return path
    }

    private func point(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
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
