import SwiftUI

enum BattlefieldTheme {
    static let backdropTop = Color(red: 0.055, green: 0.064, blue: 0.056)
    static let backdropBottom = Color(red: 0.115, green: 0.105, blue: 0.082)
    static let commandDeck = Color(red: 0.13, green: 0.145, blue: 0.12)
    static let commandDeckDeep = Color(red: 0.045, green: 0.052, blue: 0.046)
    static let fieldGlass = Color(red: 0.18, green: 0.21, blue: 0.17)
    static let brass = Color(red: 0.86, green: 0.64, blue: 0.27)
    static let selectedPiece = Color(red: 0.94, green: 0.78, blue: 0.38)
    static let supplyLine = Color(red: 0.24, green: 0.48, blue: 0.30)
    static let signal = Color(red: 0.38, green: 0.75, blue: 0.62)
    static let alert = Color(red: 0.84, green: 0.33, blue: 0.22)
    static let ink = Color.white.opacity(0.90)
    static let mutedInk = Color.white.opacity(0.62)
    static let hairline = Color.white.opacity(0.12)

    // War Ledger is deliberately scoped to the command bar and map overlays.
    // It shares the existing palette without changing the wider TacticalSurface language.
    static let warLedgerBase = Color(red: 0.052, green: 0.060, blue: 0.050)
    static let warLedgerMapOverlay = Color(red: 0.060, green: 0.070, blue: 0.058)
    static let warLedgerField = Color(red: 0.145, green: 0.162, blue: 0.132)
    static let warLedgerEtching = brass.opacity(0.22)
    static let warLedgerDivider = Color.white.opacity(0.12)
    static let warLedgerInnerHighlight = Color.white.opacity(0.055)
    static let warLedgerShadow = Color.black.opacity(0.24)

    // Map-only ground tokens. The stepped values create a restrained daylight
    // field while keeping all tactical feedback above the terrain layer.
    static let mapParchmentSoil = Color(red: 0.56, green: 0.54, blue: 0.40)
    static let mapParchmentLight = Color(red: 0.70, green: 0.67, blue: 0.50)
    static let mapParchmentShade = Color(red: 0.43, green: 0.45, blue: 0.35)
    static let mapParchmentWash = Color(red: 0.82, green: 0.72, blue: 0.50).opacity(0.08)
    static let mapParchmentEdge = Color.black.opacity(0.055)
    static let mapTileHighlight = Color.white.opacity(0.045)
    static let mapTileShade = Color.black.opacity(0.025)
    static let mapTerrainSeam = Color.black.opacity(0.055)
    static let mapTerrainSeamHighlight = Color.white.opacity(0.055)
    static let mapForestContinuity = Color(red: 0.18, green: 0.30, blue: 0.17).opacity(0.13)
    static let mapMountainContinuity = Color(red: 0.24, green: 0.23, blue: 0.20).opacity(0.13)

    // Local terrain-material tokens. They sit above the daylight ground and
    // remain below objectives, units, markers, combat feedback and chrome.
    static let terrainFieldPrimary = Color(red: 0.72, green: 0.66, blue: 0.38).opacity(0.14)
    static let terrainFieldSupport = Color(red: 0.42, green: 0.48, blue: 0.30).opacity(0.13)
    static let terrainForestCanopy = Color(red: 0.18, green: 0.34, blue: 0.19).opacity(0.16)
    static let terrainForestShadow = Color.black.opacity(0.14)
    static let terrainForestTree = Color(red: 0.22, green: 0.38, blue: 0.20)
    static let terrainForestTreeLight = Color(red: 0.30, green: 0.46, blue: 0.25)
    static let terrainCityStreet = Color(red: 0.45, green: 0.44, blue: 0.38).opacity(0.46)
    static let terrainCityStreetHighlight = Color.white.opacity(0.21)
    static let terrainCityShadow = Color.black.opacity(0.20)
    static let terrainCityWall = Color(red: 0.93, green: 0.90, blue: 0.83)
    static let terrainCityWallShade = Color(red: 0.78, green: 0.74, blue: 0.66)
    static let terrainCityRim = Color(red: 0.36, green: 0.33, blue: 0.28).opacity(0.52)
    static let terrainCityRoofWarm = Color(red: 0.70, green: 0.36, blue: 0.26)
    static let terrainCityRoofCool = Color(red: 0.52, green: 0.44, blue: 0.38)
    static let terrainMountainFoot = Color.black.opacity(0.10)
    static let terrainMountainBody = Color(red: 0.48, green: 0.47, blue: 0.43)
    static let terrainMountainLight = Color(red: 0.66, green: 0.65, blue: 0.60)
    static let terrainMountainSnow = Color.white.opacity(0.90)
    static let terrainSnowDrift = Color.blue.opacity(0.035)
    static let terrainSnowDriftHighlight = Color.white.opacity(0.26)
    static let terrainSnowConifer = Color(red: 0.24, green: 0.36, blue: 0.28)
    static let terrainSnowCap = Color.white.opacity(0.84)

    // Map-unit-only material tokens. They sit above the quiet terrain and
    // below existing selected/marker/combat feedback without changing shared
    // chrome or terrain surfaces.
    static let mapUnitContactShadow = Color.black.opacity(0.28)
    static let mapUnitBaseInset = Color.black.opacity(0.24)
    static let mapUnitBaseHighlight = Color.white.opacity(0.15)
    static let mapUnitModelShadow = Color.black.opacity(0.42)
    static let mapUnitTopHighlight = Color.white.opacity(0.18)
    static let mapUnitStatusBackdrop = Color.black.opacity(0.38)
}

struct WarLedgerSurface: View {
    var cornerRadius: CGFloat = 7
    var isMapOverlay = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(isMapOverlay ? BattlefieldTheme.warLedgerMapOverlay.opacity(0.88) : BattlefieldTheme.warLedgerBase.opacity(0.96))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(BattlefieldTheme.warLedgerInnerHighlight)
                    .frame(height: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(BattlefieldTheme.warLedgerEtching, lineWidth: 1)
            }
            .shadow(
                color: BattlefieldTheme.warLedgerShadow,
                radius: isMapOverlay ? 8 : 5,
                x: 0,
                y: isMapOverlay ? 4 : 2
            )
            .accessibilityHidden(true)
    }
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
