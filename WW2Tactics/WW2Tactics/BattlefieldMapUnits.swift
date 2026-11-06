import SwiftUI

struct UnitCounter: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        VStack(spacing: -3) {
            MapUnitPiece(
                kind: unit.kind, faction: unit.faction, rank: unit.rank,
                supplyState: game.supplyState(for: unit), tacticalStatus: unit.tacticalStatus,
                isSpent: readiness.isSpent, width: unit.kind.mapPieceWidth, height: 62,
                variant: BattlefieldVehicleVariant.matching(unit)
            )
            .overlay(alignment: .topLeading) {
                if let commander = unit.commander {
                    CommanderBadge(commander: commander, faction: unit.faction).offset(x: 3, y: -4)
                }
            }
            HStack(alignment: .center, spacing: 3) {
                UnitBranchMedallion(kind: unit.kind, faction: unit.faction)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 3) {
                        MiniHealthBar(ratio: unit.hpRatio, factionTint: unit.faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing)
                            .frame(width: 30, height: 4)
                        Text("\(unit.hp)").font(BattlefieldTheme.militaryFont(10)).foregroundStyle(BattlefieldTheme.fieldPaper)
                    }
                    .frame(height: 7)
                    HStack(spacing: 2) {
                        Text(unit.faction.shortTitle).font(BattlefieldTheme.militaryFont(8))
                            .foregroundStyle(BattlefieldTheme.fieldPaper.opacity(0.8))
                        UnitReadinessPip(symbol: readiness.moveSymbol, available: readiness.canMove,
                                         tint: BattlefieldTheme.movement)
                        UnitReadinessPip(symbol: readiness.attackSymbol, available: readiness.canAttack,
                                         tint: BattlefieldTheme.brass)
                        Spacer(minLength: 0)
                        Text(unit.rank.insignia).font(BattlefieldTheme.militaryFont(8))
                            .foregroundStyle(BattlefieldTheme.selectedPiece).shadow(color: .black, radius: 1)
                    }
                    .frame(height: 8)
                }
                .frame(width: 48)
            }
            .padding(.horizontal, 3).padding(.vertical, 2)
            .background(BattlefieldTheme.commandDeckDeep.opacity(0.88), in: BeveledFieldShape())
            .overlay { BeveledFieldShape().stroke(.white.opacity(0.16), lineWidth: 0.5) }
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
            .foregroundStyle(available ? tint : Color.white.opacity(0.38))
            .frame(width: 10, height: 8)
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
            Ellipse().fill(.black.opacity(0.21))
                .frame(width: width * 0.82, height: height * 0.30)
                .blur(radius: 1.5).offset(y: height * 0.26)
            Ellipse()
                .fill(faction.accentColor.opacity(isSpent ? 0.02 : 0.06))
                .overlay {
                    Ellipse().stroke(faction == .allies ? BattlefieldTheme.alliesRing : BattlefieldTheme.axisRing,
                                     style: StrokeStyle(lineWidth: 1, dash: faction == .allies ? [] : [4, 2]))
                }
                .frame(width: width * 0.86, height: height * 0.31)
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
                            style: StrokeStyle(lineWidth: 1, dash: faction == .axis ? [3, 1] : []))
            UnitBranchGlyph(kind: kind).fill(BattlefieldTheme.fieldPaper).padding(4)
        }
        .frame(width: 18, height: 18)
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
