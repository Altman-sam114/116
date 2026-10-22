import SwiftUI

struct ContentView: View {
    @State private var isInspectorExpanded = false

    var body: some View {
        GeometryReader { proxy in
            let isRegular = proxy.size.width >= 760
            ZStack(alignment: .trailing) {
                VStack(spacing: 0) {
                    TopCommandBar()
                    BattlefieldView()
                }
                if isInspectorExpanded {
                    inspector(isRegular: isRegular, height: proxy.size.height)
                }
                Button {
                    isInspectorExpanded.toggle()
                } label: {
                    Image(systemName: isInspectorExpanded ? "xmark" : "binoculars.fill")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 46, height: 46)
                        .foregroundStyle(BattlefieldTheme.ink)
                        .background(BattlefieldTheme.commandDeckDeep, in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(BattlefieldTheme.brass.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isInspectorExpanded ? "收起战场情报" : "展开战场情报")
                .accessibilityValue(isInspectorExpanded ? "已展开" : "已收起")
                .padding(.trailing, isInspectorExpanded && isRegular ? 354 : 10)
                .offset(y: -40)
            }
            .background(BattlefieldTheme.commandDeckDeep)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private func inspector(isRegular: Bool, height: CGFloat) -> some View {
        if isRegular {
            InspectorPanel()
                .frame(width: 338)
                .padding(8)
                .padding(.top, 58)
        } else {
            VStack(spacing: 0) {
                Spacer(minLength: 70)
                InspectorPanel()
                    .frame(height: max(240, height * 0.58))
            }
            .padding(6)
        }
    }
}
