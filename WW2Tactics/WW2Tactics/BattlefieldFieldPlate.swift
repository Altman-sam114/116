import SwiftUI

enum FieldPlateMaterial {
    case gunmetal
    case brassDossier
}

/// Textured brushed-gunmetal or hammered-brass military plate rendered in a single flat Canvas
/// so zero background subviews or images ever leak into hit-testing or accessibility hierarchies.
struct FieldPlate: View {
    var emphasized = false
    var material: FieldPlateMaterial = .gunmetal
    var showsRivets = true

    var body: some View {
        Canvas { context, size in
            guard size.width > 1, size.height > 1 else { return }
            let rect = CGRect(origin: .zero, size: size)
            let bevel = BeveledFieldShape().path(in: rect)

            // 1. Base gunmetal / antique bronze substrate
            context.fill(
                bevel,
                with: .color(material == .brassDossier ? BattlefieldTheme.brassDeck : BattlefieldTheme.commandMetal)
            )

            // 2. Clipped tiled brushed-metal or hammered-brass texture
            if let texture = material == .brassDossier ? BattlefieldArtwork.brassPanel : BattlefieldArtwork.metalPlate {
                var tiled = context
                tiled.clip(to: bevel)
                tiled.opacity = material == .brassDossier ? 0.54 : 0.48
                tiled.blendMode = .overlay
                let resolved = tiled.resolve(BattlefieldArtwork.image(texture))
                let step: CGFloat = 256
                for y in stride(from: CGFloat.zero, to: size.height, by: step) {
                    for x in stride(from: CGFloat.zero, to: size.width, by: step) {
                        tiled.draw(resolved, in: CGRect(x: x, y: y, width: step, height: step))
                    }
                }
            }

            // 3. Top-to-bottom directional metallic shading
            context.fill(
                bevel,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(emphasized ? 0.14 : 0.08),
                        Color.clear,
                        Color.black.opacity(0.32)
                    ]),
                    startPoint: CGPoint(x: rect.midX, y: rect.minY),
                    endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                )
            )

            // 4. Machined top specular bevel & bottom recessed edge
            if size.width > 20 {
                let topEdge = CGRect(x: 8, y: 0.5, width: size.width - 16, height: 1)
                context.fill(
                    Path(topEdge),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.clear,
                            (emphasized ? BattlefieldTheme.selectedPiece : BattlefieldTheme.fieldPaper).opacity(emphasized ? 0.45 : 0.22),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: topEdge.minX, y: topEdge.midY),
                        endPoint: CGPoint(x: topEdge.maxX, y: topEdge.midY)
                    )
                )
                let bottomEdge = CGRect(x: 8, y: max(0, size.height - 2), width: size.width - 16, height: 2)
                context.fill(Path(bottomEdge), with: .color(Color.black.opacity(0.42)))
            }

            // 5. Outer metallic trim border
            let borderColors = emphasized
                ? [BattlefieldTheme.selectedPiece.opacity(0.95), BattlefieldTheme.brass.opacity(0.75), Color(red: 0.48, green: 0.36, blue: 0.18)]
                : [BattlefieldTheme.brass.opacity(0.58), BattlefieldTheme.steelEdge.opacity(0.65), Color.black.opacity(0.55)]
            context.stroke(
                bevel,
                with: .linearGradient(
                    Gradient(colors: borderColors),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                ),
                lineWidth: emphasized ? 1.4 : 1.0
            )

            // 6. Machined brass corner rivets
            if showsRivets, size.width >= 36, size.height >= 24 {
                let inset: CGFloat = 6.5
                let radius: CGFloat = 1.8
                let points = [
                    CGPoint(x: inset, y: inset),
                    CGPoint(x: size.width - inset, y: inset),
                    CGPoint(x: inset, y: size.height - inset),
                    CGPoint(x: size.width - inset, y: size.height - inset)
                ]
                let rivetGradient = Gradient(colors: [
                    emphasized ? BattlefieldTheme.selectedPiece : BattlefieldTheme.brass.opacity(0.88),
                    Color(red: 0.36, green: 0.28, blue: 0.16)
                ])
                for pt in points {
                    let circle = Path(ellipseIn: CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2))
                    context.fill(
                        circle,
                        with: .radialGradient(
                            rivetGradient,
                            center: CGPoint(x: pt.x - 0.5, y: pt.y - 0.5),
                            startRadius: 0,
                            endRadius: radius * 1.4
                        )
                    )
                    context.stroke(circle, with: .color(Color.black.opacity(0.65)), lineWidth: 0.5)
                }
            }
        }
        .shadow(color: .black.opacity(0.42), radius: emphasized ? 9 : 6, y: 3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct BeveledFieldShape: Shape {
    var cornerCut: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let cut = min(cornerCut, min(rect.width, rect.height) / 4)
        return Path { path in
            path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
            path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
            path.closeSubpath()
        }
    }
}

struct FieldControlButton: View {
    let title: String
    let icon: String
    var caption: String? = nil
    var artworkImage: CGImage? = nil
    var badgeCount: Int? = nil
    var selected = false
    var isToggle = true
    var plated = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            FieldControlLabel(icon: icon, caption: caption, artworkImage: artworkImage, badgeCount: badgeCount, selected: selected)
                .background { if plated { FieldPlate(emphasized: selected, showsRivets: false) } }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isToggle ? (selected ? "已展开" : "已收起") : "")
    }
}

/// Icon (or painted game emblem) plus optional short caption; full name stays on the accessibility label.
struct FieldControlLabel: View {
    let icon: String
    var caption: String? = nil
    var artworkImage: CGImage? = nil
    var badgeCount: Int? = nil
    var selected = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 3) {
                if let artworkImage {
                    BattlefieldArtwork.image(artworkImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: caption == nil ? 22 : 20, height: caption == nil ? 22 : 20)
                        .shadow(color: .black.opacity(0.65), radius: 1.5, y: 1)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: caption == nil ? 17 : 15, weight: .semibold))
                }
                if let caption {
                    Text(caption)
                        .font(BattlefieldTheme.hudCaption)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .foregroundStyle(selected ? BattlefieldTheme.selectedPiece : BattlefieldTheme.fieldPaper)
            .frame(minWidth: 44, minHeight: 44)
            .background {
                if selected {
                    BeveledFieldShape(cornerCut: 4)
                        .fill(BattlefieldTheme.brass.opacity(0.18))
                }
            }
            .overlay(alignment: .bottom) {
                if selected {
                    Rectangle().fill(BattlefieldTheme.selectedPiece).frame(height: 2).padding(.horizontal, 6)
                }
            }

            if let badgeCount, badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(BattlefieldTheme.militaryFont(9))
                    .foregroundStyle(BattlefieldTheme.commandDeckDeep)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(BattlefieldTheme.selectedPiece, in: Capsule())
                    .overlay(Capsule().stroke(Color.black.opacity(0.65), lineWidth: 0.6))
                    .offset(x: -2, y: 2)
            }
        }
        .contentShape(Rectangle())
    }
}

/// Groups related edge tools on one riveted brushed-metal plate.
struct FieldToolRail<Content: View>: View {
    var axis: Axis = .vertical
    var plated = true
    var material: FieldPlateMaterial = .gunmetal
    @ViewBuilder let content: Content

    var body: some View {
        let layout = axis == .vertical ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
        layout { content }
            .padding(3)
            .background { if plated { FieldPlate(material: material, showsRivets: false) } }
    }
}

/// Etched brass separator running across the rail axis.
struct FieldToolDivider: View {
    var axis: Axis = .vertical

    var body: some View {
        Rectangle().fill(BattlefieldTheme.brass.opacity(0.32))
            .frame(width: axis == .vertical ? 26 : 1, height: axis == .vertical ? 1 : 26)
            .accessibilityHidden(true)
    }
}
