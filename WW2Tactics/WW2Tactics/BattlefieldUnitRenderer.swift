import SwiftUI

struct BattlefieldUnitRenderer: View {
    let kind: UnitKind
    let faction: Faction
    let isSpent: Bool

    var body: some View {
        Group {
            if let sprite = BattlefieldArtwork.unit(kind, faction: faction) {
                BattlefieldArtwork.image(sprite)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .saturation(isSpent ? 0.6 : 1)
                    .opacity(isSpent ? 0.88 : 1)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(BattlefieldTheme.alert)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
