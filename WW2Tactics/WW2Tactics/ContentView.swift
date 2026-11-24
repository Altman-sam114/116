import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isInspectorExpanded = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                BattlefieldView(isInspectorExpanded: $isInspectorExpanded)
                if isInspectorExpanded {
                    Color.black.opacity(0.20).ignoresSafeArea()
                        .onTapGesture { isInspectorExpanded = false }
                        .accessibilityHidden(true)
                        .zIndex(2)
                    BattlefieldInspectorOverlay(
                        size: BattlefieldHUDLayout(size: geometry.size).inspectorSize,
                        close: { isInspectorExpanded = false }
                    )
                    .padding(12)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(3)
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isInspectorExpanded)
            .background(BattlefieldTheme.mapGround.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
