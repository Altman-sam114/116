import SwiftUI

struct ObjectiveFlagMarker: View {
    @ScaledMetric(relativeTo: .caption) private var ownerFontSize: CGFloat = 5.5

    let owner: Faction?

    var body: some View {
        // GoG3-style banner on a pole instead of a pill chip.
        ZStack(alignment: .topLeading) {
            // Pole.
            RoundedRectangle(cornerRadius: 0.75)
                .fill(Color(red: 0.35, green: 0.30, blue: 0.24))
                .frame(width: 1.8, height: 21)
                .offset(x: 1, y: 0)

            // Waving banner.
            WavingFlagShape()
                .fill(
                    LinearGradient(
                        colors: [
                            (owner?.accentColor ?? Color(white: 0.55)),
                            (owner?.accentColor ?? Color(white: 0.55)).opacity(0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    WavingFlagShape()
                        .stroke(Color.black.opacity(0.30), lineWidth: 0.7)
                )
                .frame(width: 15, height: 10)
                .offset(x: 2.6, y: 1)

            Text(owner?.shortTitle ?? "NEU")
                .font(.system(size: ownerFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 0.5)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.52)
                .offset(x: 4.6, y: 3)
        }
        .frame(width: 18, height: 22, alignment: .topLeading)
        .shadow(color: .black.opacity(0.35), radius: 1, x: 0.5, y: 1)
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

/// Two stacked triangles forming a stylized conifer silhouette.
struct TerrainCodeBadge: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(BattlefieldTheme.commandDeckDeep.opacity(0.72))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.22), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.16), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ObjectiveNamePlate: View {
    @ScaledMetric(relativeTo: .caption) private var nameFontSize: CGFloat = 8

    let name: String
    let owner: Faction?
    var compact = false

    var body: some View {
        // Parchment nameplate under objective settlements, GoG3 city-label style.
        Text(name)
            .font(.system(size: nameFontSize, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 0.24, green: 0.20, blue: 0.13))
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(compact ? 0.46 : 0.52)
            .padding(.horizontal, compact ? 3 : 5)
            .padding(.vertical, compact ? 1.5 : 2.5)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.89, blue: 0.76),
                        Color(red: 0.85, green: 0.78, blue: 0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke((owner?.accentColor ?? BattlefieldTheme.brass).opacity(0.78), lineWidth: 1)
            )
            .shadow(color: .black.opacity(compact ? 0.20 : 0.28), radius: compact ? 1 : 2, x: 0, y: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
