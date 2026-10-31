import SwiftUI

struct UnitCounter: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        VStack(spacing: -2) {
            MapUnitPiece(
                kind: unit.kind, faction: unit.faction, rank: unit.rank,
                supplyState: game.supplyState(for: unit), tacticalStatus: unit.tacticalStatus,
                isSpent: readiness.isSpent, width: unit.kind.mapPieceWidth, height: 64,
                variant: BattlefieldVehicleVariant.matching(unit)
            )
            .overlay(alignment: .topLeading) {
                if let commander = unit.commander {
                    CommanderBadge(commander: commander, faction: unit.faction).offset(x: 2, y: -3)
                }
            }
            HStack(alignment: .center, spacing: 2) {
                UnitBranchMedallion(kind: unit.kind, faction: unit.faction)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 3) {
                        Text(unit.faction.shortTitle).font(BattlefieldTheme.militaryFont(9))
                            .foregroundStyle(.white).shadow(color: .black, radius: 1)
                        MiniHealthBar(ratio: unit.hpRatio, factionTint: unit.faction.accentColor)
                            .frame(height: 6)
                    }
                    .frame(height: 10)
                    HStack(spacing: 2) {
                        UnitReadinessPip(symbol: readiness.moveSymbol, available: readiness.canMove,
                                         tint: BattlefieldTheme.movement)
                        UnitReadinessPip(symbol: readiness.attackSymbol, available: readiness.canAttack,
                                         tint: BattlefieldTheme.brass)
                        Spacer(minLength: 0)
                        Text(unit.rank.insignia).font(BattlefieldTheme.militaryFont(9))
                            .foregroundStyle(BattlefieldTheme.selectedPiece).shadow(color: .black, radius: 1)
                    }
                    .frame(height: 10)
                }
                .frame(width: 45)
            }
            .frame(width: 70, height: 21)
            .accessibilityHidden(true)
        }
        .opacity(readiness.isSpent ? 0.83 : 1)
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

/// Tinted pip = action available, dark pip with a check = spent; move sits left of attack.
struct UnitReadinessPip: View {
    let symbol: String
    let available: Bool
    let tint: Color

    var body: some View {
        Image(systemName: symbol).font(.system(size: 7, weight: .heavy))
            .foregroundStyle(available ? BattlefieldTheme.commandDeckDeep : Color.white.opacity(0.62))
            .frame(width: 14, height: 9)
            .background(available ? tint : Color.black.opacity(0.55), in: Capsule())
            .overlay { Capsule().stroke(Color.white.opacity(available ? 0.38 : 0.26), lineWidth: 0.6) }
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
        .background((available ? tint : Color.white).opacity(available ? 0.16 : 0.06), in: Capsule())
        .overlay { Capsule().stroke((available ? tint : Color.white).opacity(0.30), lineWidth: 0.6) }
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

    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.26))
                .frame(width: width * 0.82, height: height * 0.30)
                .blur(radius: 2).offset(y: height * 0.26)
            Ellipse()
                .fill(faction.accentColor.opacity(isSpent ? 0.04 : 0.16))
                .overlay {
                    Ellipse().stroke(faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing,
                                     style: StrokeStyle(lineWidth: 1.5, dash: faction == .allies ? [] : [4, 2]))
                }
                .frame(width: width * 0.92, height: height * 0.38)
                .offset(y: height * 0.25)
            UnitModelView(kind: kind, faction: faction, isSpent: isSpent,
                          presentation: .mapPiece, variant: variant)
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.36), radius: 0.8, x: 1, y: 2)
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
        Text(title).font(BattlefieldTheme.militaryFont(8)).foregroundStyle(.white)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background(color.opacity(0.90), in: RoundedRectangle(cornerRadius: 1))
    }
}

struct UnitBranchMedallion: View {
    let kind: UnitKind
    let faction: Faction

    var body: some View {
        ZStack {
            Circle().fill(BattlefieldTheme.commandDeckDeep)
            Circle().stroke(faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing,
                            style: StrokeStyle(lineWidth: 2, dash: faction == .axis ? [3, 1] : []))
            UnitBranchGlyph(kind: kind).fill(BattlefieldTheme.fieldPaper).padding(5)
        }
        .frame(width: 23, height: 23)
        .shadow(color: .black.opacity(0.65), radius: 0.5, y: 1)
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
