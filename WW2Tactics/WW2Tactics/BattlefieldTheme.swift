import SwiftUI

enum BattlefieldTheme {
    static let backdropTop = Color(red: 0.055, green: 0.064, blue: 0.056)
    static let backdropBottom = Color(red: 0.115, green: 0.105, blue: 0.082)
    static let commandDeck = Color(red: 0.13, green: 0.145, blue: 0.12)
    static let commandDeckDeep = Color(red: 0.045, green: 0.052, blue: 0.046)
    static let fieldGlass = Color(red: 0.18, green: 0.21, blue: 0.17)
    static let brass = Color(red: 0.86, green: 0.64, blue: 0.27)
    static let signal = Color(red: 0.38, green: 0.75, blue: 0.62)
    static let alert = Color(red: 0.84, green: 0.33, blue: 0.22)
    static let ink = Color.white.opacity(0.90)
    static let mutedInk = Color.white.opacity(0.62)
    static let hairline = Color.white.opacity(0.12)
}

struct TacticalSurface: ViewModifier {
    var cornerRadius: CGFloat = 8
    var fillOpacity: Double = 0.74
    var borderOpacity: Double = 0.14
    var shadowOpacity: Double = 0.22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(BattlefieldTheme.commandDeck.opacity(fillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        BattlefieldTheme.brass.opacity(borderOpacity + 0.06),
                                        Color.white.opacity(borderOpacity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(shadowOpacity), radius: 14, x: 0, y: 7)
            )
    }
}

extension View {
    func tacticalSurface(
        cornerRadius: CGFloat = 8,
        fillOpacity: Double = 0.74,
        borderOpacity: Double = 0.14,
        shadowOpacity: Double = 0.22
    ) -> some View {
        modifier(
            TacticalSurface(
                cornerRadius: cornerRadius,
                fillOpacity: fillOpacity,
                borderOpacity: borderOpacity,
                shadowOpacity: shadowOpacity
            )
        )
    }
}

extension FireRiskLevel {
    var accentColor: Color {
        switch self {
        case .none:
            Color(red: 0.42, green: 0.74, blue: 0.56)
        case .low:
            Color(red: 0.32, green: 0.68, blue: 0.86)
        case .medium:
            Color(red: 0.95, green: 0.68, blue: 0.24)
        case .high:
            Color(red: 0.88, green: 0.34, blue: 0.18)
        case .critical:
            Color(red: 0.78, green: 0.10, blue: 0.14)
        }
    }

    var systemImage: String {
        switch self {
        case .none:
            "shield.checkered"
        case .low:
            "shield"
        case .medium:
            "exclamationmark.triangle.fill"
        case .high:
            "flame.fill"
        case .critical:
            "burst.fill"
        }
    }
}

extension MissionObjectiveState {
    var systemImage: String {
        switch self {
        case .pending:
            "circle"
        case .complete:
            "checkmark.circle.fill"
        case .failed:
            "xmark.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .pending:
            Color.white.opacity(0.48)
        case .complete:
            Color(red: 0.42, green: 0.78, blue: 0.40)
        case .failed:
            Color(red: 0.86, green: 0.28, blue: 0.22)
        }
    }
}
