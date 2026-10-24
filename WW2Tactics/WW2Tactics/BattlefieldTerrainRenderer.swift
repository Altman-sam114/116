import SwiftUI

/// Continuous materials and shared original scenery are below all tactical input and unit layers.
struct BattlefieldTerrainRenderer: View {
    let tiles: [TerrainTile]
    let layout: BattlefieldMapLayout
    let roadConnections: [HexCoordinate: [Int]]

    var body: some View {
        Canvas { context, size in
            paintGround(context: &context, size: size)
            paintSnow(context: &context)
            for tile in tiles where tile.terrain == .plains && !tile.isObjective {
                if abs(seed(for: tile) % 11) == 0 { paintField(tile, context: &context) }
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
                               with: .color(Color(red: 0.12, green: 0.20, blue: 0.12).opacity(tile.terrain == .snow ? 0.045 : 0.11)),
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
        material.opacity = 0.70
        let step: CGFloat = 320
        for y in stride(from: CGFloat.zero, to: size.height, by: step) {
            for x in stride(from: CGFloat.zero, to: size.width, by: step) {
                material.draw(image, in: CGRect(x: x, y: y, width: step, height: step))
            }
        }
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.60, green: 0.65, blue: 0.45).opacity(0.12)))
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
        let frame = CGRect(x: point.x - 32, y: point.y - 13, width: 57, height: 32)
        let field = Path { path in
            path.move(to: CGPoint(x: frame.minX, y: frame.minY + 5))
            path.addLine(to: CGPoint(x: frame.maxX - 5, y: frame.minY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY - 4))
            path.addLine(to: CGPoint(x: frame.minX + 2, y: frame.maxY))
            path.closeSubpath()
        }
        var paint = context
        paint.clip(to: field)
        paint.fill(field, with: .color(Color(red: 0.66, green: 0.60, blue: 0.36).opacity(0.18)))
        var furrows = Path()
        for index in 0..<8 {
            let y = frame.minY + CGFloat(index) * 4 + phase
            furrows.move(to: CGPoint(x: frame.minX, y: y))
            furrows.addLine(to: CGPoint(x: frame.maxX, y: y - 5))
        }
        paint.stroke(furrows, with: .color(Color(red: 0.25, green: 0.31, blue: 0.16).opacity(0.16)), lineWidth: 0.7)
    }

    private func paintConnections(context: inout GraphicsContext) {
        var roads = Path()
        for tile in tiles where tile.terrain == .road {
            roads.addPath(connectionPath(at: tile.coordinate, directions: roadConnections[tile.coordinate] ?? []))
        }
        context.stroke(roads, with: .color(Color(red: 0.22, green: 0.26, blue: 0.16).opacity(0.35)),
                       style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.64, green: 0.59, blue: 0.44)),
                       style: StrokeStyle(lineWidth: 3.3, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.80, green: 0.75, blue: 0.57).opacity(0.38)),
                       style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        paintRivers(context: &context)
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
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 3.5))
            layer.fill(shore, with: .color(Color(red: 0.18, green: 0.24, blue: 0.16).opacity(0.42)))
        }
        context.fill(bank, with: .color(Color(red: 0.49, green: 0.47, blue: 0.31)))
        context.fill(water, with: .linearGradient(
            Gradient(colors: [Color(red: 0.30, green: 0.48, blue: 0.47), Color(red: 0.18, green: 0.33, blue: 0.37)]),
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
        let seed = seed(for: tile)
        let kind: BattlefieldScenery
        let size: CGSize
        switch tile.terrain {
        case .forest:
            kind = .forest
            size = CGSize(width: 124, height: 96)
        case .mountain:
            kind = .mountain
            size = CGSize(width: 128, height: 100)
        case .city:
            kind = .village
            size = CGSize(width: 98, height: 77)
        case .snow:
            guard noise(seed, 29) > 0.38 else { return }
            kind = .winterForest
            size = CGSize(width: 115, height: 87)
        default:
            guard tile.isObjective else { return }
            kind = .village
            size = CGSize(width: 84, height: 65)
        }
        guard let sprite = BattlefieldArtwork.scenery(kind) else { return }
        let point = layout.center(for: tile.coordinate)
        let variation = 0.88 + noise(seed, 13) * 0.26
        let width = size.width * variation
        let height = size.height * variation
        let x = point.x - width / 2 + (noise(seed, 19) - 0.5) * 16
        let y = point.y - height / 2 + 3 + (noise(seed, 23) - 0.5) * 12
        context.draw(BattlefieldArtwork.image(sprite), in: CGRect(x: x, y: y, width: width, height: height))
    }

    private func seed(for tile: TerrainTile) -> Int { tile.coordinate.q * 997 + tile.coordinate.r * 131 }

    private func noise(_ seed: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return CGFloat(value - floor(value))
    }
}
