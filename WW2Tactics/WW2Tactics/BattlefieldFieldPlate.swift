import SwiftUI

enum FieldPlateMaterial {
    case gunmetal
    case brassDossier
}

/// Textured brushed-gunmetal or hammered-brass military plate rendered purely with SwiftUI Shapes
/// and ImagePaint — zero Canvas/UIView backing, zero blendMode compositing traps, and zero
/// accessibility or hit-testing leakage.
struct FieldPlate: View {
    var emphasized = false
    var material: FieldPlateMaterial = .gunmetal
    var showsRivets = true

    var body: some View {
        BeveledFieldShape()
            .fill(material == .brassDossier ? BattlefieldTheme.brassDeck : BattlefieldTheme.commandMetal)
            .overlay {
                if let texture = material == .brassDossier ? BattlefieldArtwork.brassPanel : BattlefieldArtwork.metalPlate {
                    BeveledFieldShape()
                        .fill(ImagePaint(image: BattlefieldArtwork.image(texture), scale: 0.45))
                        .opacity(material == .brassDossier ? 0.36 : 0.30)
                }
            }
            .overlay {
                BeveledFieldShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(emphasized ? 0.14 : 0.08),
                                Color.clear,
                                Color.black.opacity(0.32)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                (emphasized ? BattlefieldTheme.selectedPiece : BattlefieldTheme.fieldPaper).opacity(emphasized ? 0.48 : 0.24),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 8)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.black.opacity(0.42))
                    .frame(height: 2)
                    .padding(.horizontal, 8)
            }
            .overlay {
                BeveledFieldShape()
                    .stroke(
                        LinearGradient(
                            colors: emphasized
                                ? [BattlefieldTheme.selectedPiece.opacity(0.95), BattlefieldTheme.brass.opacity(0.76), Color(red: 0.48, green: 0.36, blue: 0.18)]
                                : [BattlefieldTheme.brass.opacity(0.60), BattlefieldTheme.steelEdge.opacity(0.65), Color.black.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: emphasized ? 1.4 : 1.0
                    )
            }
            .overlay {
                if showsRivets {
                    FieldPlateRivetsShape()
                        .fill(emphasized ? BattlefieldTheme.selectedPiece.opacity(0.90) : BattlefieldTheme.brass.opacity(0.84))
                        .overlay {
                            FieldPlateRivetsShape()
                                .stroke(Color.black.opacity(0.68), lineWidth: 0.5)
                        }
                }
            }
            .shadow(color: .black.opacity(0.42), radius: emphasized ? 8 : 5, y: 3)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct FieldPlateRivetsShape: Shape {
    func path(in rect: CGRect) -> Path {
        guard rect.width >= 36, rect.height >= 24 else { return Path() }
        let inset: CGFloat = 6.5
        let radius: CGFloat = 1.8
        let points = [
            CGPoint(x: rect.minX + inset, y: rect.minY + inset),
            CGPoint(x: rect.maxX - inset, y: rect.minY + inset),
            CGPoint(x: rect.minX + inset, y: rect.maxY - inset),
            CGPoint(x: rect.maxX - inset, y: rect.maxY - inset)
        ]
        var path = Path()
        for pt in points {
            path.addEllipse(in: CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2))
        }
        return path
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
