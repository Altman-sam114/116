import SwiftUI

enum HexTileTopOverlayChip: String, Identifiable {
    case countermeasure
    case objectivePressure
    case situationResponse
    case enemyThreatIntent
    case fireRisk
    case latestCapture
    case guidedObjective

    var id: String { rawValue }

    /// Lower sortOrder is shown first in the top stack (higher visual priority).
    var sortOrder: Int {
        switch self {
        case .countermeasure: return 0
        case .objectivePressure: return 1
        case .situationResponse: return 2
        case .enemyThreatIntent: return 3
        case .fireRisk: return 4
        case .latestCapture: return 5
        case .guidedObjective: return 6
        }
    }
}

enum HexTileBottomOverlayChip: String, Identifiable {
    case aiPhase
    case attackPosition

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .aiPhase: return 0
        case .attackPosition: return 1
        }
    }
}

struct HexTileOverflowChip: View {
    let count: Int

    var body: some View {
        Text("+\(count)")
            .font(.system(size: 7, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.62), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
