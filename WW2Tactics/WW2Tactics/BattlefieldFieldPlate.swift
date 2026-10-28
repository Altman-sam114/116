import SwiftUI

/// Shared metal edge treatment keeps all map controls in one visual language.
struct FieldPlate: View {
    var emphasized = false

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(BattlefieldTheme.commandMetal)
            .overlay {
                RoundedRectangle(cornerRadius: 2).inset(by: 3)
                    .stroke(Color.black.opacity(0.45), lineWidth: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(emphasized ? BattlefieldTheme.brass : BattlefieldTheme.steelEdge, lineWidth: 1)
            }
            .overlay {
                Canvas { context, size in
                    var grain = Path()
                    for y in stride(from: CGFloat(5), to: size.height - 4, by: 3) {
                        grain.move(to: CGPoint(x: 5, y: y))
                        grain.addLine(to: CGPoint(x: size.width - 5, y: y))
                    }
                    context.stroke(grain, with: .color(.white.opacity(0.022)), lineWidth: 0.5)
                    for x in [CGFloat(5), size.width - 5] {
                        for y in [CGFloat(5), size.height - 5] {
                            context.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                                         with: .color(BattlefieldTheme.brass.opacity(0.55)))
                        }
                    }
                }
            }
            .shadow(color: .black.opacity(0.38), radius: 3, y: 3)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct BeveledFieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cut = min(6, min(rect.width, rect.height) / 4)
        return Path { path in
            path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
            path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
            path.closeSubpath()
        }
    }
}

struct FieldControlButton: View {
    let title: String
    let icon: String
    var selected = false
    var showsTitle = false
    var isToggle = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 17, weight: .medium))
                if showsTitle { Text(title).font(.system(size: 8, weight: .bold)) }
            }
            .foregroundStyle(selected ? BattlefieldTheme.brass : BattlefieldTheme.fieldPaper)
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, showsTitle ? 5 : 0)
            .contentShape(Rectangle())
            .background(FieldPlate(emphasized: selected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isToggle ? (selected ? "已展开" : "已收起") : "")
    }
}
