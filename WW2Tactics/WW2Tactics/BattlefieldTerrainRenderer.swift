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
                               with: .color(Color(red: 0.12, green: 0.20, blue: 0.12).opacity(0.20)),
                               lineWidth: 0.6)
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
        let step: CGFloat = 320
        for y in stride(from: CGFloat.zero, to: size.height, by: step) {
            for x in stride(from: CGFloat.zero, to: size.width, by: step) {
                context.draw(image, in: CGRect(x: x, y: y, width: step, height: step))
            }
        }
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.60, green: 0.65, blue: 0.45).opacity(0.12)))
    }

    private func paintSnow(context: inout GraphicsContext) {
        var drifts = Path()
        for tile in tiles where tile.terrain == .snow {
            let frame = layout.frame(for: tile.coordinate)
            drifts.addEllipse(in: frame.insetBy(dx: -7, dy: 8))
        }
        guard !drifts.isEmpty else { return }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 10))
            layer.fill(drifts, with: .color(Color(red: 0.83, green: 0.86, blue: 0.80).opacity(0.80)))
        }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 3))
            layer.fill(drifts, with: .color(Color(red: 0.91, green: 0.92, blue: 0.86).opacity(0.44)))
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
        let terrain = Dictionary(uniqueKeysWithValues: tiles.map { ($0.coordinate, $0.terrain) })
        var rivers = Path()
        var roads = Path()
        for tile in tiles {
            let directions: [Int]
            switch tile.terrain {
            case .road:
                directions = roadConnections[tile.coordinate] ?? []
            case .river:
                directions = tile.coordinate.neighbors.enumerated().compactMap { index, coordinate in
                    terrain[coordinate] == .river ? index : nil
                }
            default: continue
            }
            let curve = connectionPath(at: tile.coordinate, directions: directions)
            if tile.terrain == .river { rivers.addPath(curve) } else { roads.addPath(curve) }
        }
        context.stroke(roads, with: .color(Color(red: 0.22, green: 0.26, blue: 0.16).opacity(0.35)),
                       style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.64, green: 0.59, blue: 0.44)),
                       style: StrokeStyle(lineWidth: 3.3, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.80, green: 0.75, blue: 0.57).opacity(0.38)),
                       style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 2))
            layer.stroke(rivers, with: .color(Color.black.opacity(0.23)),
                         style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round))
        }
        context.stroke(rivers, with: .color(Color(red: 0.36, green: 0.39, blue: 0.26)),
                       style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round))
        context.stroke(rivers, with: .color(Color(red: 0.60, green: 0.58, blue: 0.42)),
                       style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
        context.stroke(rivers, with: .linearGradient(
            Gradient(colors: [Color(red: 0.31, green: 0.49, blue: 0.47), Color(red: 0.20, green: 0.35, blue: 0.38)]),
            startPoint: .zero, endPoint: CGPoint(x: layout.size.width, y: layout.size.height)),
            style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
        for tile in tiles where tile.terrain == .river {
            paintRiverDetails(tile, context: &context)
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

    private func paintRiverDetails(_ tile: TerrainTile, context: inout GraphicsContext) {
        let center = layout.center(for: tile.coordinate)
        let seed = seed(for: tile)
        for index in 0..<3 {
            let x = center.x - 4 + noise(seed, index + 3) * 8
            let y = center.y - 7 + CGFloat(index) * 6
            var ripple = Path()
            ripple.move(to: CGPoint(x: x, y: y))
            ripple.addQuadCurve(to: CGPoint(x: x + 5, y: y - 1), control: CGPoint(x: x + 2, y: y - 2))
            context.stroke(ripple, with: .color(Color.white.opacity(0.15)), lineWidth: 0.6)
        }
    }

    private func paintScenery(_ tile: TerrainTile, context: inout GraphicsContext) {
        let seed = seed(for: tile)
        let kind: BattlefieldScenery
        let size: CGSize
        switch tile.terrain {
        case .forest:
            kind = .forest
            size = CGSize(width: 102, height: 78)
        case .mountain:
            kind = .mountain
            size = CGSize(width: 113, height: 88)
        case .city:
            kind = .village
            size = CGSize(width: 89, height: 70)
        case .snow:
            guard abs(seed % 3) != 0 else { return }
            kind = .winterForest
            size = CGSize(width: 88, height: 67)
        default:
            guard tile.isObjective else { return }
            kind = .village
            size = CGSize(width: 84, height: 65)
        }
        guard let sprite = BattlefieldArtwork.scenery(kind) else { return }
        let point = layout.center(for: tile.coordinate)
        let variation = 0.94 + noise(seed, 13) * 0.12
        let width = size.width * variation
        let height = size.height * variation
        let x = point.x - width / 2 + (noise(seed, 19) - 0.5) * 7
        let y = point.y - height / 2 + 3 + (noise(seed, 23) - 0.5) * 7
        context.draw(BattlefieldArtwork.image(sprite), in: CGRect(x: x, y: y, width: width, height: height))
    }

    private func seed(for tile: TerrainTile) -> Int { tile.coordinate.q * 997 + tile.coordinate.r * 131 }

    private func noise(_ seed: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return CGFloat(value - floor(value))
    }
}
