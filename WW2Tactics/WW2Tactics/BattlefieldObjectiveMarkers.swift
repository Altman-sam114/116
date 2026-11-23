import SwiftUI

/// EasyTech GoG3 / WC4 metallic painted faction city roundel.
struct ObjectiveFlagMarker: View {
    let owner: Faction?

    var body: some View {
        ZStack {
            if let owner, let crest = BattlefieldArtwork.emblem(owner == .allies ? .alliedCrest : .axisCrest) {
                BattlefieldArtwork.image(crest)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 21, height: 21)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.42, green: 0.41, blue: 0.36), Color(red: 0.18, green: 0.18, blue: 0.15)],
                                center: .topLeading,
                                startRadius: 1,
                                endRadius: 11
                            )
                        )
                    Circle()
                        .stroke(BattlefieldTheme.brass, lineWidth: 1.4)
                    Image(systemName: "star.fill")
                        .font(.system(size: 8.5, weight: .black))
                        .foregroundStyle(BattlefieldTheme.fieldPaper.opacity(0.9))
                }
                .frame(width: 19, height: 19)
            }
        }
        .shadow(color: .black.opacity(0.55), radius: 2, y: 1.2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A small banner with a gently waving fly edge.
struct WavingFlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12),
            control1: CGPoint(x: rect.width * 0.4, y: rect.minY - rect.height * 0.18),
            control2: CGPoint(x: rect.width * 0.7, y: rect.minY + rect.height * 0.24)
        )
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY - rect.height * 0.10))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.62, y: rect.maxY + rect.height * 0.14),
            control2: CGPoint(x: rect.width * 0.34, y: rect.maxY - rect.height * 0.26)
        )
        path.closeSubpath()
        return path
    }
}

struct TerrainCodeBadge: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(BattlefieldTheme.fieldPaper.opacity(0.88))
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(BattlefieldTheme.commandDeckDeep.opacity(0.68), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(BattlefieldTheme.brass.opacity(0.45), lineWidth: 0.7)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// EasyTech city nameplate with live City Tier stars & upgraded facility indicators.
struct ObjectiveNamePlate: View {
    @ScaledMetric(relativeTo: .caption) private var nameFontSize: CGFloat = 9

    let name: String
    let owner: Faction?
    var compact = false
    var facility: CityFacilityState? = nil

    var body: some View {
        let rimColor: Color = {
            switch owner {
            case .allies: BattlefieldTheme.alliesRing
            case .axis: BattlefieldTheme.axisRing
            case nil: BattlefieldTheme.brass
            }
        }()

        HStack(spacing: 3) {
            Text(name)
                .font(.system(size: nameFontSize, weight: .bold))
                .foregroundStyle(BattlefieldTheme.fieldPaper)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.75)

            if let facility, !compact {
                Text(String(repeating: "★", count: max(1, min(4, facility.visualTier))))
                    .font(.system(size: 6.5))
                    .foregroundStyle(BattlefieldTheme.selectedPiece)
            }
        }
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, compact ? 1.5 : 2.5)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.16, blue: 0.14).opacity(0.92),
                    Color(red: 0.07, green: 0.09, blue: 0.08).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: BeveledFieldShape(cornerCut: 3)
        )
        .overlay(
            BeveledFieldShape(cornerCut: 3)
                .stroke(rimColor.opacity(0.85), lineWidth: 0.9)
        )
        .shadow(color: .black.opacity(compact ? 0.35 : 0.48), radius: compact ? 1.5 : 2.5, x: 0, y: 1.2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
