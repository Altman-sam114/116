import SwiftUI

/// One restrained material for battle chrome, drawers and orders.
struct FieldPlate: View {
    var emphasized = false

    var body: some View {
        BeveledFieldShape()
            .fill(BattlefieldTheme.commandMetal)
            .overlay(alignment: .top) {
                Rectangle().fill(BattlefieldTheme.fieldPaper.opacity(0.15)).frame(height: 1)
                    .padding(.horizontal, 7)
            }
            .overlay {
                BeveledFieldShape()
                    .stroke(emphasized ? BattlefieldTheme.brass.opacity(0.85) : BattlefieldTheme.steelEdge.opacity(0.75), lineWidth: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(.black.opacity(0.28)).frame(height: 2).padding(.horizontal, 7)
            }
            .shadow(color: .black.opacity(0.28), radius: 5, y: 3)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct BeveledFieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cut = min(5, min(rect.width, rect.height) / 4)
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
    var caption: String? = nil
    var selected = false
    var isToggle = true
    var plated = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            FieldControlLabel(icon: icon, caption: caption, selected: selected)
                .background { if plated { FieldPlate(emphasized: selected) } }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isToggle ? (selected ? "已展开" : "已收起") : "")
    }
}

/// Icon plus optional short caption; the full name stays on the accessibility label.
struct FieldControlLabel: View {
    let icon: String
    var caption: String? = nil
    var selected = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: caption == nil ? 18 : 17, weight: .regular))
            if let caption {
                Text(caption).font(BattlefieldTheme.hudCaption).lineLimit(1).fixedSize()
            }
        }
        .foregroundStyle(selected ? BattlefieldTheme.brass : BattlefieldTheme.fieldPaper)
        .frame(minWidth: 44, minHeight: 44)
        .background {
            if selected { Rectangle().fill(BattlefieldTheme.brass.opacity(0.10)) }
        }
        .overlay(alignment: .bottom) {
            if selected { Rectangle().fill(BattlefieldTheme.brass).frame(height: 2).padding(.horizontal, 8) }
        }
        .contentShape(Rectangle())
    }
}

/// Groups related edge tools on one metal plate instead of a row of separate tiles.
struct FieldToolRail<Content: View>: View {
    var axis: Axis = .vertical
    var plated = true
    @ViewBuilder let content: Content

    var body: some View {
        let layout = axis == .vertical ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
        layout { content }
            .padding(2)
            .background { if plated { FieldPlate() } }
    }
}

/// Etched separator running across the rail axis.
struct FieldToolDivider: View {
    var axis: Axis = .vertical

    var body: some View {
        Rectangle().fill(BattlefieldTheme.brass.opacity(0.28))
            .frame(width: axis == .vertical ? 28 : 1, height: axis == .vertical ? 1 : 28)
            .accessibilityHidden(true)
    }
}
