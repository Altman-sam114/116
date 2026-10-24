import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isInspectorExpanded = false

    var body: some View {
        GeometryReader { proxy in
            let viewport = BattlefieldViewport(size: proxy.size)
            let isRegular = proxy.size.width >= 760
            ZStack(alignment: .trailing) {
                VStack(spacing: 0) {
                    TopCommandBar(condensed: viewport.isShallow)
                    BattlefieldView(isInspectorExpanded: $isInspectorExpanded)
                }
                if isInspectorExpanded {
                    inspector(isRegular: isRegular, height: proxy.size.height)
                }
            }
            .background(BattlefieldTheme.commandDeckDeep)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        #if DEBUG
        .background(CloudOrientationRequest().frame(width: 0, height: 0))
        #endif
    }

    @ViewBuilder private func inspector(isRegular: Bool, height: CGFloat) -> some View {
        if isRegular {
            inspectorContent
                .frame(width: 338)
                .padding(8)
                .padding(.top, 58)
        } else {
            VStack(spacing: 0) {
                Spacer(minLength: 70)
                inspectorContent
                    .frame(height: max(240, height * 0.58))
            }
            .padding(6)
        }
    }

    private var inspectorContent: some View {
        VStack(spacing: 0) {
            HStack {
                Label("战场情报", systemImage: "binoculars.fill")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button { isInspectorExpanded = false } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("收起战场情报")
            }
            .padding(.leading, 14)
            .foregroundStyle(BattlefieldTheme.ink)
            .background(BattlefieldTheme.commandMetal)
            InspectorPanel()
        }
    }
}

#if DEBUG
/// Ask iOS for a real landscape scene in cloud evidence; never rotate screenshot pixels.
private struct CloudOrientationRequest: UIViewRepresentable {
    func makeUIView(context: Context) -> OrientationView { OrientationView() }
    func updateUIView(_ uiView: OrientationView, context: Context) {}

    final class OrientationView: UIView {
        private var didRequest = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard !didRequest, CommandLine.arguments.contains("--ci-landscape"),
                  let scene = window?.windowScene else { return }
            didRequest = true
            DispatchQueue.main.async {
                scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { error in
                    print("Cloud landscape request failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
#endif
