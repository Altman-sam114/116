import SwiftUI

struct BattlefieldInspectorOverlay: View {
    let size: CGSize
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "binoculars.fill").foregroundStyle(BattlefieldTheme.brass)
                VStack(alignment: .leading, spacing: 2) {
                    Text("战场情报").font(.system(size: 13, weight: .heavy))
                    Text("FIELD INTELLIGENCE").font(BattlefieldTheme.militaryFont(10)).tracking(1.8)
                        .foregroundStyle(BattlefieldTheme.brass)
                }
                Spacer(minLength: 0)
                Button(action: close) {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("收起战场情报")
                .accessibilityIdentifier("battlefield-intelligence-close")
            }
            .padding(.leading, 14)
            .foregroundStyle(BattlefieldTheme.fieldPaper)
            .frame(height: 54)
            Rectangle().fill(BattlefieldTheme.brass.opacity(0.5)).frame(height: 1)
            InspectorPanel()
        }
        .frame(width: size.width, height: size.height)
        .background(FieldPlate(emphasized: true))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { close() }
    }
}
