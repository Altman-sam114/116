import SwiftUI

/// Continuous materials and shared original scenery are below all tactical input and unit layers.
struct BattlefieldTerrainRenderer: View {
    let tiles: [TerrainTile]
    let layout: BattlefieldMapLayout
    let roadConnections: [HexCoordinate: [Int]]

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
                               with: .color(Color(red: 0.12, green: 0.20, blue: 0.12).opacity(tile.terrain == .snow ? 0.07 : 0.14)),
                               lineWidth: 0.55)
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
        material.opacity = 0.56
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
            let point = layout.center(for: tile.coordinate)
            let seed = seed(for: tile)
            let width = 126 + noise(seed, 7) * 18
            let height = 102 + noise(seed, 11) * 14
            drifts.addEllipse(in: CGRect(x: point.x - width / 2 + (noise(seed, 2) - 0.5) * 14,
                                        y: point.y - height / 2 + (noise(seed, 5) - 0.5) * 12,
                                        width: width, height: height))
        }
        guard !drifts.isEmpty else { return }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 19))
            layer.fill(drifts, with: .color(Color(red: 0.76, green: 0.81, blue: 0.74).opacity(0.68)))
        }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 10))
            layer.fill(drifts, with: .color(Color(red: 0.87, green: 0.89, blue: 0.83).opacity(0.20)))
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
        for tile in tiles where infrastructure.directionsByCoordinate[tile.coordinate] != nil {
            roads.addPath(connectionPath(at: tile.coordinate, directions: infrastructure.directionsByCoordinate[tile.coordinate] ?? []))
        }
        context.stroke(roads, with: .color(Color(red: 0.22, green: 0.26, blue: 0.16).opacity(0.35)),
                       style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.64, green: 0.59, blue: 0.44)),
                       style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.80, green: 0.75, blue: 0.57).opacity(0.38)),
                       style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
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

    private func connectionPath(at coordinate: HexCoordinate, directions: [Int]) -> Path {
        let center = layout.center(for: coordinate)
        let points = directions.map { direction -> CGPoint in
            let neighbor = layout.center(for: coordinate.neighbors[direction])
            return CGPoint(x: (center.x + neighbor.x) / 2, y: (center.y + neighbor.y) / 2)
        }
        return Path { path in
            if points.count == 2 {
                path.move(to: points[0])
                path.addQuadCurve(to: points[1], control: center)
            } else if points.isEmpty {
                path.move(to: CGPoint(x: center.x - 15, y: center.y - 6))
                path.addQuadCurve(to: CGPoint(x: center.x + 15, y: center.y + 6), control: center)
            } else {
                for point in points {
                    path.move(to: center)
                    path.addLine(to: point)
                }
            }
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
        context.stroke(water, with: .color(Color(red: 0.67, green: 0.70, blue: 0.54).opacity(0.36)), lineWidth: 0.65)
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
        context.draw(BattlefieldArtwork.image(sprite), in: placement.rect)
    }

    private func seed(for tile: TerrainTile) -> Int { tile.coordinate.q * 997 + tile.coordinate.r * 131 }

    private func noise(_ seed: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return CGFloat(value - floor(value))
    }
}
