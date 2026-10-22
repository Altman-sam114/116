import SwiftUI

/// Original three-quarter miniatures, painted in a single normalized canvas.
struct BattlefieldUnitRenderer: View {
    let kind: UnitKind
    let faction: Faction
    let isSpent: Bool

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 100, y: size.height / 70)
            context.opacity = isSpent ? 0.72 : 1
            context.fill(Path(ellipseIn: CGRect(x: 19, y: 47, width: 69, height: 14)),
                         with: .color(.black.opacity(0.25)))
            switch kind {
            case .tank: tank(context: &context)
            case .artillery: artillery(context: &context)
            case .infantry: infantry(context: &context)
            case .recon: recon(context: &context)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var paint: Color {
        faction == .allies ? Color(red: 0.43, green: 0.48, blue: 0.29) : Color(red: 0.48, green: 0.53, blue: 0.53)
    }
    private var light: Color {
        faction == .allies ? Color(red: 0.67, green: 0.69, blue: 0.43) : Color(red: 0.69, green: 0.73, blue: 0.70)
    }
    private var shade: Color {
        faction == .allies ? Color(red: 0.24, green: 0.29, blue: 0.18) : Color(red: 0.26, green: 0.32, blue: 0.32)
    }

    private func tank(context: inout GraphicsContext) {
        track([(18, 33), (61, 18), (67, 26), (24, 43)], context: &context)
        track([(35, 49), (79, 33), (87, 43), (43, 59)], context: &context)
        plate([(25, 32), (65, 19), (83, 35), (42, 50)], color: paint, context: &context)
        plate([(42, 50), (83, 35), (82, 43), (43, 57)], color: shade, context: &context)
        plate([(25, 32), (42, 50), (43, 57), (25, 41)], color: shade.opacity(0.9), context: &context)
        plate([(29, 31), (64, 21), (74, 31), (40, 42)], color: light.opacity(0.70), context: &context)
        line([(35, 30), (43, 38), (51, 35), (44, 27)], color: shade, width: 1, context: &context)
        for index in 0..<5 {
            let x = 29 + CGFloat(index) * 3
            line([(x, 35), (x + 7, 42)], color: shade.opacity(0.8), width: 1, context: &context)
        }
        let turret = CGRect(x: 40, y: 23, width: 29, height: 19)
        context.fill(Path(ellipseIn: turret.offsetBy(dx: 0, dy: 4)), with: .color(shade))
        context.fill(Path(ellipseIn: turret), with: .linearGradient(Gradient(colors: [light, paint]),
                     startPoint: turret.origin, endPoint: CGPoint(x: 65, y: 40)))
        context.stroke(Path(ellipseIn: turret), with: .color(shade), lineWidth: 0.8)
        context.fill(Path(ellipseIn: CGRect(x: 46, y: 25, width: 10, height: 6)), with: .color(shade))
        context.stroke(Path(ellipseIn: CGRect(x: 46, y: 24, width: 10, height: 6)), with: .color(light), lineWidth: 1)
        line([(61, 28), (87, 13)], color: shade, width: 6, context: &context)
        line([(61, 26.5), (87, 11.5)], color: light, width: 3, context: &context)
        line([(86, 10), (89, 14)], color: Color(red: 0.16, green: 0.20, blue: 0.17), width: 3.5, context: &context)
        insignia(at: CGPoint(x: 64, y: 36), context: &context)
    }

    private func track(_ points: [(CGFloat, CGFloat)], context: inout GraphicsContext) {
        plate(points, color: Color(red: 0.16, green: 0.20, blue: 0.17), context: &context)
        guard points.count == 4 else { return }
        for index in 0..<9 {
            let t = CGFloat(index) / 9
            let x = points[0].0 + (points[1].0 - points[0].0) * t
            let y = points[0].1 + (points[1].1 - points[0].1) * t
            line([(x + 1, y + 1), (x + 6, y + 7)], color: Color(red: 0.46, green: 0.47, blue: 0.37), width: 1.5, context: &context)
        }
    }

    private func artillery(context: inout GraphicsContext) {
        line([(49, 39), (22, 62)], color: shade, width: 5, context: &context)
        line([(53, 40), (57, 64)], color: shade, width: 5, context: &context)
        line([(49, 37), (23, 60)], color: light, width: 2, context: &context)
        line([(54, 40), (57, 62)], color: paint, width: 3, context: &context)
        wheel(at: CGPoint(x: 34, y: 47), radius: 10, context: &context)
        wheel(at: CGPoint(x: 68, y: 39), radius: 10, context: &context)
        plate([(32, 31), (53, 20), (69, 31), (49, 44)], color: light, context: &context)
        plate([(49, 44), (69, 31), (69, 39), (49, 50)], color: shade, context: &context)
        plate([(34, 32), (40, 21), (58, 20), (65, 30), (47, 39)], color: paint, context: &context)
        line([(48, 32), (88, 8)], color: shade, width: 7, context: &context)
        line([(48, 30), (89, 6)], color: light, width: 3.5, context: &context)
        line([(86, 5), (91, 11)], color: shade, width: 4, context: &context)
        line([(41, 27), (55, 23)], color: light, width: 1.2, context: &context)
        insignia(at: CGPoint(x: 45, y: 34), context: &context)
    }

    private func recon(context: inout GraphicsContext) {
        for point in [CGPoint(x: 27, y: 40), CGPoint(x: 48, y: 25), CGPoint(x: 53, y: 52), CGPoint(x: 77, y: 37)] {
            wheel(at: point, radius: 7, context: &context)
        }
        plate([(24, 32), (63, 18), (84, 34), (44, 51)], color: paint, context: &context)
        plate([(44, 51), (84, 34), (83, 42), (46, 58)], color: shade, context: &context)
        plate([(46, 25), (64, 19), (77, 28), (59, 35)], color: light, context: &context)
        plate([(31, 31), (48, 25), (59, 35), (42, 42)], color: shade, context: &context)
        plate([(31, 28), (47, 22), (58, 31), (41, 38)], color: paint, context: &context)
        plate([(46, 24), (52, 28), (41, 32), (36, 28)], color: Color(red: 0.36, green: 0.50, blue: 0.50), context: &context)
        line([(63, 20), (65, 9)], color: shade, width: 1, context: &context)
        line([(68, 32), (75, 29)], color: light, width: 1.2, context: &context)
        insignia(at: CGPoint(x: 57, y: 42), context: &context)
    }

    private func infantry(context: inout GraphicsContext) {
        soldier(at: CGPoint(x: 60, y: 34), context: &context)
        soldier(at: CGPoint(x: 31, y: 42), context: &context)
        soldier(at: CGPoint(x: 47, y: 54), context: &context)
    }

    private func soldier(at p: CGPoint, context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y + 4, width: 19, height: 5)), with: .color(.black.opacity(0.24)))
        line([(p.x - 2, p.y - 5), (p.x - 6, p.y + 8)], color: shade, width: 4.5, context: &context)
        line([(p.x + 3, p.y - 5), (p.x + 7, p.y + 5)], color: shade, width: 4.5, context: &context)
        plate([(p.x - 6, p.y - 19), (p.x + 4, p.y - 21), (p.x + 8, p.y - 6), (p.x - 4, p.y - 3)], color: paint, context: &context)
        plate([(p.x - 6, p.y - 19), (p.x - 1, p.y - 20), (p.x, p.y - 5), (p.x - 4, p.y - 3)], color: light, context: &context)
        context.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 27, width: 8, height: 9)),
                     with: .color(Color(red: 0.77, green: 0.62, blue: 0.43)))
        context.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 29, width: 11, height: 7)), with: .color(paint))
        line([(p.x - 5, p.y - 26), (p.x + 2, p.y - 28)], color: light, width: 1, context: &context)
        line([(p.x + 2, p.y - 8), (p.x + 13, p.y - 25)], color: Color(red: 0.25, green: 0.22, blue: 0.17), width: 2.5, context: &context)
        line([(p.x + 10, p.y - 22), (p.x + 17, p.y - 32)], color: Color(red: 0.19, green: 0.23, blue: 0.21), width: 1.5, context: &context)
        line([(p.x + 6, p.y - 16), (p.x + 10, p.y - 14)], color: light, width: 3, context: &context)
    }

    private func wheel(at p: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        let rect = CGRect(x: p.x - radius * 0.75, y: p.y - radius, width: radius * 1.5, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.12, green: 0.16, blue: 0.14)))
        context.stroke(Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)), with: .color(paint), lineWidth: 2)
        context.fill(Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)), with: .color(light))
    }

    private func insignia(at p: CGPoint, context: inout GraphicsContext) {
        if faction == .allies {
            let points = (0..<10).map { index -> (CGFloat, CGFloat) in
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let radius: CGFloat = index.isMultiple(of: 2) ? 3.5 : 1.4
                return (p.x + cos(angle) * radius, p.y + sin(angle) * radius)
            }
            plate(points, color: .white.opacity(0.85), context: &context)
        } else {
            line([(p.x - 3, p.y), (p.x + 3, p.y)], color: .white.opacity(0.8), width: 2, context: &context)
            line([(p.x, p.y - 3), (p.x, p.y + 3)], color: .white.opacity(0.8), width: 2, context: &context)
        }
    }

    private func plate(_ points: [(CGFloat, CGFloat)], color: Color, context: inout GraphicsContext) {
        let path = Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.0, y: first.1))
            for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
            path.closeSubpath()
        }
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(shade.opacity(0.65)), lineWidth: 0.65)
    }

    private func line(_ points: [(CGFloat, CGFloat)], color: Color, width: CGFloat, context: inout GraphicsContext) {
        let path = Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.0, y: first.1))
            for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
        }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}
