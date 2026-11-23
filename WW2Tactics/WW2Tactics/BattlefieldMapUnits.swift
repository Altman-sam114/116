import SwiftUI

/// GoG3-style sleek battlefield unit piece:
/// Luminous radial ground aura + crisp vehicle/troop sprite + ornate floating commander medallion +
/// attached micro enameled branch medallion & segmented HP bar (eliminating bulky black boxes).
struct UnitCounter: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        VStack(spacing: -6) {
            MapUnitPiece(
                kind: unit.kind, faction: unit.faction, rank: unit.rank,
                supplyState: game.supplyState(for: unit), tacticalStatus: unit.tacticalStatus,
                isSpent: readiness.isSpent, width: unit.kind.mapPieceWidth, height: 64,
                variant: BattlefieldVehicleVariant.matching(unit),
                isElite: unit.isElite
            )
            .overlay(alignment: .top) {
                if let commander = unit.commander {
                    CommanderBadge(commander: commander, faction: unit.faction)
                        .offset(x: unit.faction == .allies ? -10 : 10, y: -12)
                }
            }
            .overlay(alignment: .topTrailing) {
                if unit.equippedMedal != nil, let medal = BattlefieldArtwork.shopIcon(.heroCross) {
                    BattlefieldArtwork.image(medal)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.8), radius: 1.5)
                        .offset(x: -2, y: 0)
                }
            }

            // Sleek GoG3-style circular branch medallion overlapping a slim segmented HP bar
            HStack(spacing: -4) {
                UnitBranchMedallion(kind: unit.kind, faction: unit.faction, isElite: unit.isElite)
                    .zIndex(2)

                VStack(alignment: .leading, spacing: 1.5) {
                    HStack(spacing: 3) {
                        MiniHealthBar(
                            ratio: unit.hpRatio,
                            factionTint: unit.faction == .allies
                                ? Color(red: 0.28, green: 0.76, blue: 0.98)
                                : Color(red: 0.94, green: 0.26, blue: 0.22)
                        )
                        .frame(width: 38, height: 5)
                        Text("\(unit.hp)")
                            .font(BattlefieldTheme.militaryFont(10))
                            .foregroundStyle(Color.white)
                            .shadow(color: .black, radius: 1.2, y: 0.6)
                    }
                    HStack(spacing: 2.5) {
                        UnitReadinessPip(symbol: readiness.moveSymbol, available: readiness.canMove,
                                         tint: BattlefieldTheme.movement)
                        UnitReadinessPip(symbol: readiness.attackSymbol, available: readiness.canAttack,
                                         tint: BattlefieldTheme.selectedPiece)
                        Spacer(minLength: 0)
                        Text(unit.rank.insignia)
                            .font(BattlefieldTheme.militaryFont(8.5))
                            .foregroundStyle(BattlefieldTheme.selectedPiece)
                            .shadow(color: .black, radius: 1)
                    }
                    .frame(width: 48, height: 7)
                }
                .padding(.leading, 7)
                .padding(.trailing, 4)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.76), Color.black.opacity(0.54)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            (unit.faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing).opacity(0.52),
                            lineWidth: 0.6
                        )
                )
            }
            .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
            .accessibilityHidden(true)
        }
        .opacity(readiness.isSpent ? 0.84 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var readiness: UnitReadinessPresentation {
        UnitReadinessPresentation(hasMoved: unit.hasMoved, hasAttacked: unit.hasAttacked)
    }

    private var accessibilitySummary: String {
        let commanderText = unit.commander.map { "，将领\($0.name)" } ?? ""
        return "\(unit.name)，\(unit.kind.title)，\(unit.faction.title)，生命 \(unit.hp) / \(unit.maxHP)\(commanderText)，\(unit.rank.title)，\(game.supplyState(for: unit).title)，\(unit.tacticalStatus.title)，\(unit.actionStateText)"
    }
}

/// Luminous pip = action available, dimmed check = spent; move sits left of attack.
struct UnitReadinessPip: View {
    let symbol: String
    let available: Bool
    let tint: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 7, weight: .black))
            .foregroundStyle(available ? tint : Color.white.opacity(0.32))
            .frame(width: 9, height: 7)
            .shadow(color: available ? tint.opacity(0.65) : .clear, radius: 1.5)
            .accessibilityHidden(true)
    }
}

/// Dock-sized readiness tag; the title keeps state readable without relying on colour.
struct UnitReadinessTag: View {
    let symbol: String
    let title: String
    let available: Bool
    let tint: Color
    var showsTitle = true

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 8, weight: .heavy))
            if showsTitle { Text(title).font(BattlefieldTheme.hudCaption) }
        }
        .lineLimit(1).fixedSize()
        .foregroundStyle(available ? tint : BattlefieldTheme.mutedInk)
        .padding(.horizontal, 5).frame(height: 16)
        .background((available ? tint : Color.white).opacity(available ? 0.18 : 0.06), in: Capsule())
        .overlay { Capsule().stroke((available ? tint : Color.white).opacity(0.36), lineWidth: 0.6) }
        .accessibilityHidden(true)
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
    var variant: BattlefieldVehicleVariant? = nil
    var isElite = false

    var body: some View {
        let ringColor = faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing
        ZStack {
            // GoG3 luminous tactical ground base disc
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            ringColor.opacity(isSpent ? 0.12 : 0.30),
                            ringColor.opacity(isSpent ? 0.05 : 0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: width * 0.44
                    )
                )
                .frame(width: width * 0.88, height: height * 0.36)
                .offset(y: height * 0.24)

            // Soft ground contact shadow under tracks/wheels
            Ellipse()
                .fill(Color.black.opacity(0.34))
                .frame(width: width * 0.72, height: height * 0.24)
                .blur(radius: 2)
                .offset(y: height * 0.26)

            // Crisp glowing tactical perimeter ring
            Ellipse()
                .stroke(
                    isElite ? BattlefieldTheme.selectedPiece : ringColor.opacity(isSpent ? 0.55 : 0.92),
                    style: StrokeStyle(lineWidth: isElite ? 1.6 : 1.2, dash: faction == .allies ? [] : [5, 2.5])
                )
                .frame(width: width * 0.84, height: height * 0.32)
                .offset(y: height * 0.25)

            UnitModelView(kind: kind, faction: faction, isSpent: isSpent,
                          presentation: .mapPiece, variant: variant)
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.42), radius: 1.2, x: 1, y: 2.2)

            if supplyState == .isolated {
                status("CUT", color: BattlefieldTheme.alert)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            if tacticalStatus != .normal {
                status(tacticalStatus.shortTitle, color: tacticalStatus.mapColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    private func status(_ title: String, color: Color) -> some View {
        Text(title)
            .font(BattlefieldTheme.militaryFont(8))
            .foregroundStyle(.white)
            .padding(.horizontal, 3.5)
            .padding(.vertical, 1)
            .background(color.opacity(0.92), in: RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.65), lineWidth: 0.5))
    }
}

/// GoG3-style enameled circular branch badge with metallic faction rim.
struct UnitBranchMedallion: View {
    let kind: UnitKind
    let faction: Faction
    var isElite = false

    var body: some View {
        let rim = isElite ? BattlefieldTheme.selectedPiece : (faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing)
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            faction == .allies ? Color(red: 0.14, green: 0.34, blue: 0.62) : Color(red: 0.58, green: 0.14, blue: 0.13),
                            BattlefieldTheme.commandDeckDeep
                        ],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 12
                    )
                )
            Circle()
                .stroke(rim, lineWidth: isElite ? 1.8 : 1.3)
            UnitBranchGlyph(kind: kind)
                .fill(Color.white)
                .padding(4.2)
        }
        .frame(width: 20, height: 20)
        .shadow(color: .black.opacity(0.72), radius: 1.5, y: 1)
        .accessibilityHidden(true)
    }
}

private struct UnitBranchGlyph: Shape {
    let kind: UnitKind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch kind {
        case .infantry:
            path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY, width: rect.width * 0.64, height: rect.height * 0.68))
            path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height * 0.25), cornerSize: CGSize(width: 2, height: 2))
        case .tank:
            path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height * 0.42), cornerSize: CGSize(width: 2, height: 2))
            path.addRect(CGRect(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.2, width: rect.width * 0.45, height: rect.height * 0.4))
            path.addRect(CGRect(x: rect.midX, y: rect.minY + rect.height * 0.14, width: rect.width * 0.5, height: rect.height * 0.15))
        case .artillery:
            path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.25, y: rect.midY, width: rect.width * 0.4, height: rect.height * 0.4))
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.30))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.20))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.50))
            path.closeSubpath()
        case .recon:
            path.addRect(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.35, width: rect.width, height: rect.height * 0.4))
            for x in [rect.width * 0.2, rect.width * 0.65] {
                path.addEllipse(in: CGRect(x: rect.minX + x, y: rect.minY + rect.height * 0.65, width: rect.width * 0.22, height: rect.height * 0.22))
            }
            path.addRect(CGRect(x: rect.minX + rect.width * 0.3, y: rect.minY + rect.height * 0.1, width: rect.width * 0.4, height: rect.height * 0.3))
        }
        return path
    }
}
