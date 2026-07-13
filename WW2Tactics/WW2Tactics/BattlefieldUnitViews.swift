import SwiftUI

struct MiniHealthBar: View {
    let ratio: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.42))
                Capsule()
                    .fill(ratio > 0.45 ? Color.green : Color.red)
                    .frame(width: proxy.size.width * ratio)
            }
        }
    }
}

struct UnitCounter: View {
    @EnvironmentObject private var game: GameState
    let unit: BattleUnit

    var body: some View {
        VStack(spacing: 3) {
            UnitShapeBadge(
                kind: unit.kind,
                faction: unit.faction,
                hasCommander: unit.commander != nil,
                rank: unit.rank,
                tacticalStatus: unit.tacticalStatus,
                isSpent: unit.hasAttacked,
                width: unit.kind.counterWidth,
                height: 32,
                lineWidth: unit.hasAttacked ? 1 : 2
            )
            .overlay(alignment: .topLeading) {
                if let commander = unit.commander {
                    CommanderBadge(commander: commander, faction: unit.faction)
                        .offset(x: -7, y: -8)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.42))
                    Capsule()
                        .fill(unit.hpRatio > 0.45 ? Color.green : Color.red)
                        .frame(width: proxy.size.width * unit.hpRatio)
                }
            }
            .frame(width: 46, height: 5)
        }
        .opacity(unit.hasAttacked ? 0.72 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let commanderText = unit.commander.map { "，将领\($0.name)" } ?? ""
        let supplyText = game.supplyState(for: unit).title
        return "\(unit.name)，\(unit.kind.title)，\(unit.faction.title)，生命 \(unit.hp) / \(unit.maxHP)\(commanderText)，\(unit.rank.title)，\(supplyText)，\(unit.tacticalStatus.title)，\(unit.actionStateText)"
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

            UnitMarkerShape(kind: kind)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.82, blue: 0.70),
                            Color(red: 0.28, green: 0.31, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    UnitMarkerShape(kind: kind)
                        .stroke(Color.black.opacity(0.78), lineWidth: 0.8)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 4)
                .shadow(color: .black.opacity(0.48), radius: 1, x: 0, y: 1)

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

struct CommanderBadge: View {
    let commander: Commander
    let faction: Faction

    var body: some View {
        ZStack {
            Circle()
                .fill(BattlefieldTheme.commandDeckDeep)
            Circle()
                .stroke(faction.accentColor, lineWidth: 2)
            Image(systemName: "person.crop.circle.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.88))
            Text(String(commander.name.prefix(1)))
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(.yellow)
                .offset(x: 7, y: 7)
        }
        .frame(width: 24, height: 24)
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
        let head = rect.height * 0.18
        for centerX in [0.30, 0.51, 0.70] {
            path.addEllipse(in: CGRect(x: rect.minX + rect.width * centerX - head / 2, y: rect.minY, width: head, height: head))
            path.addRoundedRect(
                in: CGRect(x: rect.minX + rect.width * centerX - head * 0.38, y: rect.minY + head * 0.86, width: head * 0.76, height: rect.height * 0.54),
                cornerSize: CGSize(width: head * 0.28, height: head * 0.28)
            )
        }
        path.addRect(CGRect(x: rect.minX + rect.width * 0.60, y: rect.minY + rect.height * 0.34, width: rect.width * 0.35, height: rect.height * 0.08))
        return path
    }

    private func tankPath(in rect: CGRect) -> Path {
        let upperTrack = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.18, width: rect.width * 0.78, height: rect.height * 0.24)
        let lowerTrack = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.60, width: rect.width * 0.78, height: rect.height * 0.24)
        let body = CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.25, width: rect.width * 0.72, height: rect.height * 0.48)
        let turret = CGRect(
            x: rect.minX + rect.width * 0.30,
            y: rect.minY + rect.height * 0.06,
            width: rect.width * 0.36,
            height: rect.height * 0.32
        )
        let barrel = CGRect(
            x: rect.minX + rect.width * 0.62,
            y: rect.minY + rect.height * 0.16,
            width: rect.width * 0.32,
            height: rect.height * 0.13
        )

        var path = Path()
        path.addRoundedRect(in: upperTrack, cornerSize: CGSize(width: rect.height * 0.10, height: rect.height * 0.10))
        path.addRoundedRect(in: lowerTrack, cornerSize: CGSize(width: rect.height * 0.10, height: rect.height * 0.10))
        path.addRoundedRect(
            in: body,
            cornerSize: CGSize(width: rect.height * 0.18, height: rect.height * 0.18)
        )
        path.addRoundedRect(
            in: turret,
            cornerSize: CGSize(width: rect.height * 0.12, height: rect.height * 0.12)
        )
        path.addRect(barrel)
        return path
    }

    private func artilleryPath(in rect: CGRect) -> Path {
        var path = Path()
        let wheel = rect.height * 0.34
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.18, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.56, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.48, width: rect.width * 0.50, height: rect.height * 0.16), cornerSize: CGSize(width: 2, height: 2))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.12, width: rect.width * 0.54, height: rect.height * 0.12), cornerSize: CGSize(width: 2, height: 2))
        path.addRect(CGRect(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.66, width: rect.width * 0.42, height: rect.height * 0.10))
        return path
    }

    private func reconPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.minY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY - rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY - rect.height * 0.22))
        path.closeSubpath()
        let wheel = rect.height * 0.25
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.18, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.62, y: rect.maxY - wheel, width: wheel, height: wheel))
        path.addEllipse(in: CGRect(x: rect.midX - wheel * 0.45, y: rect.minY + rect.height * 0.12, width: wheel * 0.9, height: wheel * 0.9))
        path.addRect(CGRect(x: rect.midX, y: rect.minY, width: rect.width * 0.04, height: rect.height * 0.24))
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
            43
        case .tank:
            49
        case .artillery:
            45
        case .recon:
            44
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
