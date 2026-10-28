import SwiftUI

/// Continuous materials and shared original scenery are below all tactical input and unit layers.
struct BattlefieldTerrainRenderer: View, Equatable {
    let tiles: [TerrainTile]
    let layout: BattlefieldMapLayout
    let roadConnections: [HexCoordinate: [Int]]

    static func == (left: Self, right: Self) -> Bool {
        left.tiles == right.tiles && left.layout == right.layout && left.roadConnections == right.roadConnections
    }

    var body: some View {
        Canvas { context, size in
            paintGround(context: &context, size: size)
            paintRelief(context: &context)
            paintSnow(context: &context)
            for tile in tiles where tile.terrain == .plains && !tile.isObjective {
                if abs(seed(for: tile) % 5) == 0 { paintField(tile, context: &context) }
            }
            paintConnections(context: &context)
            for tile in tiles.sorted(by: { left, right in
                let a = layout.center(for: left.coordinate)
                let b = layout.center(for: right.coordinate)
                return a.y == b.y ? a.x < b.x : a.y < b.y
            }) {
                paintScenery(tile, context: &context)
            }
            for tile in tiles {
                context.stroke(Hexagon().path(in: layout.frame(for: tile.coordinate)),
                               with: .color(Color(red: 0.12, green: 0.20, blue: 0.12).opacity(tile.terrain == .snow ? 0.055 : 0.10)),
                               lineWidth: 0.45)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func paintGround(context: inout GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.43, green: 0.49, blue: 0.31)))
        guard let ground = BattlefieldArtwork.ground else { return }
        let image = context.resolve(BattlefieldArtwork.image(ground))
        var material = context
        material.opacity = 0.36
        let step: CGFloat = 512
        for y in stride(from: CGFloat.zero, to: size.height, by: step) {
            for x in stride(from: CGFloat.zero, to: size.width, by: step) {
                material.draw(image, in: CGRect(x: x, y: y, width: step, height: step))
            }
        }
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.60, green: 0.65, blue: 0.45).opacity(0.12)))
    }

    private func paintRelief(context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 27))
            for tile in tiles where tile.terrain != .river {
                let seed = seed(for: tile)
                guard noise(seed, 41) > 0.60 else { continue }
                let center = layout.center(for: tile.coordinate)
                let rect = CGRect(x: center.x - 95, y: center.y - 46, width: 190, height: 92)
                let shade = tile.terrain == .forest || tile.terrain == .mountain
                layer.fill(Path(ellipseIn: rect), with: .color(
                    shade ? Color(red: 0.24, green: 0.31, blue: 0.18).opacity(0.20)
                          : Color(red: 0.72, green: 0.68, blue: 0.43).opacity(0.16)
                ))
            }
        }
    }

    private func paintSnow(context: inout GraphicsContext) {
        var drifts = Path()
        for tile in tiles where tile.terrain == .snow {
            drifts.addPath(Hexagon().path(in: layout.frame(for: tile.coordinate).insetBy(dx: -9, dy: -9)))
        }
        guard !drifts.isEmpty else { return }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 15))
            layer.fill(drifts, with: .color(Color(red: 0.79, green: 0.83, blue: 0.77).opacity(0.76)))
        }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 6))
            layer.fill(drifts, with: .color(Color(red: 0.87, green: 0.89, blue: 0.83).opacity(0.16)))
        }
    }

    private func paintField(_ tile: TerrainTile, context: inout GraphicsContext) {
        let point = layout.center(for: tile.coordinate)
        let phase = noise(seed(for: tile), 17)
        let frame = CGRect(x: point.x - 42, y: point.y - 22, width: 80, height: 49)
        let field = Path { path in
            path.move(to: CGPoint(x: frame.minX, y: frame.minY + 5))
            path.addLine(to: CGPoint(x: frame.maxX - 5, y: frame.minY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY - 4))
            path.addLine(to: CGPoint(x: frame.minX + 2, y: frame.maxY))
            path.closeSubpath()
        }
        var paint = context
        paint.clip(to: field)
        paint.fill(field, with: .color(Color(red: 0.64, green: 0.58, blue: 0.35).opacity(0.25)))
        var furrows = Path()
        for index in 0..<13 {
            let y = frame.minY + CGFloat(index) * 4 + phase
            furrows.move(to: CGPoint(x: frame.minX, y: y))
            furrows.addLine(to: CGPoint(x: frame.maxX, y: y - 5))
        }
        paint.stroke(furrows, with: .color(Color(red: 0.25, green: 0.31, blue: 0.16).opacity(0.16)), lineWidth: 0.7)
        context.stroke(field, with: .color(Color(red: 0.29, green: 0.35, blue: 0.20).opacity(0.24)), lineWidth: 1.2)
    }

    private func paintConnections(context: inout GraphicsContext) {
        let infrastructure = BattlefieldInfrastructure(tiles: tiles, roadConnections: roadConnections)
        paintRivers(context: &context)
        var roads = Path()
        for segment in BattlefieldRoadGeometry(infrastructure: infrastructure, layout: layout).segments {
            var path = Path()
            path.move(to: segment.start)
            path.addCurve(to: segment.end, control1: segment.firstControl, control2: segment.secondControl)
            roads.addPath(path)
        }
        context.stroke(roads, with: .color(Color(red: 0.22, green: 0.26, blue: 0.16).opacity(0.35)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.65, green: 0.60, blue: 0.45).opacity(0.88)),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
        for bridge in infrastructure.bridges { paintBridge(bridge, context: &context) }
    }

    private func paintBridge(_ bridge: BattlefieldBridge, context: inout GraphicsContext) {
        let center = layout.center(for: bridge.coordinate)
        let neighbor = layout.center(for: bridge.coordinate.neighbors[bridge.direction])
        var deck = context
        deck.translateBy(x: center.x, y: center.y)
        deck.rotate(by: .radians(atan2(neighbor.y - center.y, neighbor.x - center.x)))
        deck.fill(Path(CGRect(x: -28, y: -5, width: 56, height: 14)), with: .color(.black.opacity(0.30)))
        deck.fill(Path(CGRect(x: -28, y: -6, width: 56, height: 11)), with: .color(Color(red: 0.58, green: 0.54, blue: 0.43)))
        var planks = Path()
        for x in stride(from: CGFloat(-25), through: 25, by: 4) {
            planks.move(to: CGPoint(x: x, y: -4))
            planks.addLine(to: CGPoint(x: x, y: 3))
        }
        deck.stroke(planks, with: .color(.black.opacity(0.27)), lineWidth: 0.6)
        for y in [CGFloat(-6), 5] {
            let rail = Path(CGRect(x: -29, y: y, width: 58, height: 1.8))
            deck.fill(rail, with: .color(Color(red: 0.76, green: 0.72, blue: 0.60)))
        }
        for x in [CGFloat(-30), 25] {
            deck.fill(Path(CGRect(x: x, y: -9, width: 5, height: 17)), with: .color(Color(red: 0.45, green: 0.45, blue: 0.37)))
        }
    }

    private func paintRivers(context: inout GraphicsContext) {
        let geometry = BattlefieldRiverGeometry(tiles: tiles, layout: layout)
        var shore = Path()
        var bank = Path()
        var water = Path()
        for ribbon in geometry.ribbons {
            shore.addPath(Path(ribbon.outline(expansion: 5)))
            bank.addPath(Path(ribbon.outline(expansion: 2.5)))
            water.addPath(Path(ribbon.outline()))
        }
        for pool in geometry.terminalPools {
            shore.addEllipse(in: pool.insetBy(dx: -5, dy: -5))
            bank.addEllipse(in: pool.insetBy(dx: -2.5, dy: -2.5))
            water.addEllipse(in: pool)
        }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 3.5))
            layer.fill(shore, with: .color(Color(red: 0.18, green: 0.24, blue: 0.16).opacity(0.42)))
        }
        context.fill(bank, with: .color(Color(red: 0.46, green: 0.46, blue: 0.32)))
        context.fill(water, with: .linearGradient(
            Gradient(colors: [Color(red: 0.32, green: 0.48, blue: 0.47), Color(red: 0.19, green: 0.34, blue: 0.36)]),
            startPoint: .zero, endPoint: CGPoint(x: layout.size.width, y: layout.size.height)))
        for ribbon in geometry.ribbons {
            for fraction in [CGFloat(0.28), 0.57, 0.82] {
                let center = ribbon.point(at: fraction)
                let normal = ribbon.normal(at: fraction)
                var ripple = Path()
                ripple.move(to: CGPoint(x: center.x - normal.x * 2, y: center.y - normal.y * 2))
                ripple.addQuadCurve(to: CGPoint(x: center.x + normal.x * 3, y: center.y + normal.y * 3),
                                    control: CGPoint(x: center.x + 1.3, y: center.y - 1.3))
                context.stroke(ripple, with: .color(Color.white.opacity(0.14)), lineWidth: 0.65)
            }
        }
    }

    private func paintScenery(_ tile: TerrainTile, context: inout GraphicsContext) {
        guard let placement = BattlefieldSceneryPlacement(tile: tile, layout: layout),
              let sprite = BattlefieldArtwork.scenery(placement.kind) else { return }
        var scenery = context
        if placement.mirrored {
            scenery.translateBy(x: placement.rect.midX * 2, y: 0)
            scenery.scaleBy(x: -1, y: 1)
        }
        scenery.draw(BattlefieldArtwork.image(sprite), in: placement.rect)
    }

    private func seed(for tile: TerrainTile) -> Int { tile.coordinate.q * 997 + tile.coordinate.r * 131 }

    private func noise(_ seed: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return CGFloat(value - floor(value))
    }
}
