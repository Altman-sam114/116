import SwiftUI

/// Static cartography is one drawing pass; interactive hexes remain separate views.
struct BattlefieldTerrainRenderer: View {
    let tiles: [TerrainTile]
    let layout: BattlefieldMapLayout
    let roadConnections: [HexCoordinate: [Int]]

    var body: some View {
        Canvas { context, size in
            paintGround(context: &context, size: size)
            let terrain = Dictionary(uniqueKeysWithValues: tiles.map { ($0.coordinate, $0.terrain) })
            for tile in tiles {
                paintLand(tile, context: &context)
            }
            paintConnections(terrain: terrain, context: &context)
            // North-to-south order gives scenery consistent overlapping shadows.
            for tile in tiles.sorted(by: { $0.coordinate.r < $1.coordinate.r }) {
                paintScenery(tile, context: &context)
            }
            for tile in tiles {
                let hex = Hexagon().path(in: layout.frame(for: tile.coordinate))
                context.stroke(hex, with: .color(Color(red: 0.18, green: 0.25, blue: 0.14).opacity(0.14)), lineWidth: 0.65)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func paintGround(context: inout GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.56, green: 0.59, blue: 0.40),
                              Color(red: 0.43, green: 0.49, blue: 0.32)]),
            startPoint: .zero, endPoint: CGPoint(x: size.width * 0.7, y: size.height)))
        // Fixed, low-frequency grain; no time-based or random state.
        for index in 0..<10000 {
            let x = noise(index, 7) * size.width
            let y = noise(index, 19) * size.height
            let width = 1 + noise(index, 41) * 5
            let rect = CGRect(x: x, y: y, width: width, height: 0.7)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.045)))
        }
    }

    private func paintLand(_ tile: TerrainTile, context: inout GraphicsContext) {
        let rect = layout.frame(for: tile.coordinate)
        let seed = tile.coordinate.q * 997 + tile.coordinate.r * 131
        let center = layout.center(for: tile.coordinate)
        let wash = CGRect(x: center.x - 70, y: center.y - 48, width: 140, height: 96)
        context.fill(Path(ellipseIn: wash), with: .color(
            noise(seed, 17) > 0.5 ? Color.yellow.opacity(0.025) : Color.black.opacity(0.025)))

        if tile.terrain == .snow {
            context.fill(Hexagon().path(in: rect), with: .linearGradient(
                Gradient(colors: [Color(red: 0.84, green: 0.87, blue: 0.82),
                                  Color(red: 0.72, green: 0.78, blue: 0.74)]),
                startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
        } else if tile.terrain == .forest {
            context.fill(Path(ellipseIn: rect.insetBy(dx: -8, dy: 1)),
                         with: .color(Color(red: 0.23, green: 0.35, blue: 0.20).opacity(0.18)))
        } else if tile.terrain == .mountain {
            context.fill(Path(ellipseIn: rect.insetBy(dx: -4, dy: 2)),
                         with: .color(Color(red: 0.42, green: 0.43, blue: 0.31).opacity(0.25)))
        } else if tile.terrain == .plains && !tile.isObjective && noise(seed, 23) > 0.4 {
            paintFields(rect: rect, seed: seed, context: &context)
        }
    }

    private func paintFields(rect: CGRect, seed: Int, context: inout GraphicsContext) {
        var fieldContext = context
        fieldContext.clip(to: Hexagon().path(in: rect.insetBy(dx: 1, dy: 1)))
        let x = rect.minX + 8 + noise(seed, 13) * 12
        let y = rect.minY + 25
        let w = 28 + noise(seed, 31) * 25
        let field = polygon([CGPoint(x: x, y: y), CGPoint(x: x + w, y: y - 8),
                             CGPoint(x: x + w + 8, y: y + 24), CGPoint(x: x + 5, y: y + 33)])
        fieldContext.fill(field, with: .color(Color(red: 0.72, green: 0.66, blue: 0.39).opacity(0.24)))
        fieldContext.stroke(field, with: .color(Color(red: 0.34, green: 0.42, blue: 0.24).opacity(0.18)), lineWidth: 1)
        var furrows = Path()
        for line in 0..<6 {
            let dy = CGFloat(line) * 4
            furrows.move(to: CGPoint(x: x + 4, y: y + dy))
            furrows.addLine(to: CGPoint(x: x + w - 2, y: y - 6 + dy))
        }
        fieldContext.stroke(furrows, with: .color(Color(red: 0.36, green: 0.43, blue: 0.23).opacity(0.25)), lineWidth: 0.6)
    }

    private func paintConnections(terrain: [HexCoordinate: TerrainKind], context: inout GraphicsContext) {
        var rivers = Path()
        var roads = Path()
        for tile in tiles {
            let origin = layout.center(for: tile.coordinate)
            let directions: [Int]
            if tile.terrain == .road {
                directions = roadConnections[tile.coordinate] ?? []
            } else if tile.terrain == .river {
                directions = tile.coordinate.neighbors.enumerated().compactMap { index, coordinate in
                    terrain[coordinate] == .river ? index : nil
                }
            } else {
                continue
            }
            var connection = Path()
            if directions.isEmpty {
                connection.move(to: CGPoint(x: origin.x - 17, y: origin.y - 9))
                connection.addQuadCurve(to: CGPoint(x: origin.x + 17, y: origin.y + 9), control: origin)
            }
            for direction in directions {
                let neighbor = layout.center(for: tile.coordinate.neighbors[direction])
                connection.move(to: origin)
                connection.addLine(to: CGPoint(x: (origin.x + neighbor.x) / 2, y: (origin.y + neighbor.y) / 2))
            }
            if tile.terrain == .river { rivers.addPath(connection) } else { roads.addPath(connection) }
        }
        context.stroke(roads, with: .color(Color(red: 0.30, green: 0.34, blue: 0.21).opacity(0.24)),
                       style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.72, green: 0.65, blue: 0.46)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.88, green: 0.80, blue: 0.59).opacity(0.55)),
                       style: StrokeStyle(lineWidth: 0.65, lineCap: .round, dash: [2, 4]))
        context.stroke(rivers, with: .color(Color(red: 0.28, green: 0.36, blue: 0.28).opacity(0.50)),
                       style: StrokeStyle(lineWidth: 19, lineCap: .round, lineJoin: .round))
        context.stroke(rivers, with: .color(Color(red: 0.56, green: 0.60, blue: 0.43)),
                       style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
        context.stroke(rivers, with: .color(Color(red: 0.25, green: 0.43, blue: 0.47)),
                       style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round))
        context.stroke(rivers, with: .color(Color(red: 0.53, green: 0.68, blue: 0.65).opacity(0.50)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    private func paintScenery(_ tile: TerrainTile, context: inout GraphicsContext) {
        let rect = layout.frame(for: tile.coordinate)
        let seed = tile.coordinate.q * 997 + tile.coordinate.r * 131
        switch tile.terrain {
        case .forest:
            for index in 0..<(8 + abs(seed % 5)) {
                let x = rect.minX + 9 + noise(seed, index * 11 + 1) * 64
                let y = rect.minY + 21 + noise(seed, index * 13 + 5) * 59
                let h = 13 + noise(seed, index * 17 + 3) * 14
                tree(at: CGPoint(x: x, y: y), height: h, snow: false, context: &context)
            }
        case .mountain:
            for index in 0..<3 {
                let point = CGPoint(x: rect.minX + 22 + CGFloat(index) * 20,
                                    y: rect.midY + 18 + noise(seed, index + 8) * 11)
                mountain(at: point, width: 43 + noise(seed, index + 11) * 15,
                         height: 29 + noise(seed, index + 9) * 19, context: &context)
            }
        case .city:
            settlement(rect: rect, seed: seed, fortified: tile.isObjective, context: &context)
        case .snow:
            if abs(seed % 3) != 0 {
                for index in 0..<3 {
                    tree(at: CGPoint(x: rect.minX + 22 + CGFloat(index) * 16,
                                     y: rect.midY + noise(seed, index + 33) * 20),
                         height: 16 + noise(seed, index + 37) * 9, snow: true, context: &context)
                }
            }
        default:
            if tile.isObjective {
                settlement(rect: rect, seed: seed, fortified: true, context: &context)
            } else if abs(seed % 7) == 0 {
                for index in 0..<3 {
                    let p = CGPoint(x: rect.minX + 24 + CGFloat(index) * 10, y: rect.midY + 14)
                    context.fill(Path(ellipseIn: CGRect(x: p.x, y: p.y, width: 5, height: 3)),
                                 with: .color(Color(red: 0.30, green: 0.39, blue: 0.22).opacity(0.60)))
                }
            }
        }
    }

    private func tree(at point: CGPoint, height: CGFloat, snow: Bool, context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 2, width: height * 0.85, height: 5)),
                     with: .color(.black.opacity(0.18)))
        context.fill(Path(CGRect(x: point.x - 0.9, y: point.y - 8, width: 1.8, height: 9)),
                     with: .color(Color(red: 0.28, green: 0.26, blue: 0.15)))
        for tier in 0..<3 {
            let top = point.y - height + CGFloat(tier) * height * 0.23
            let halfWidth = height * (0.20 + CGFloat(tier) * 0.045)
            let foot = top + height * 0.56
            let left = CGPoint(x: point.x - halfWidth, y: foot)
            let peak = CGPoint(x: point.x, y: top)
            let right = CGPoint(x: point.x + halfWidth, y: foot)
            context.fill(polygon([left, peak, right]), with: .color(Color(red: 0.19, green: 0.32, blue: 0.20)))
            context.fill(polygon([left, peak, CGPoint(x: point.x + 1, y: foot)]),
                         with: .color(snow ? Color(red: 0.88, green: 0.91, blue: 0.85) : Color(red: 0.34, green: 0.45, blue: 0.24)))
        }
    }

    private func mountain(at point: CGPoint, width: CGFloat, height: CGFloat, context: inout GraphicsContext) {
        let left = CGPoint(x: point.x - width / 2, y: point.y)
        let peak = CGPoint(x: point.x - width * 0.10, y: point.y - height)
        let ridge = CGPoint(x: point.x + width * 0.06, y: point.y - height * 0.30)
        let right = CGPoint(x: point.x + width / 2, y: point.y + 3)
        context.fill(polygon([left, peak, right, CGPoint(x: right.x + 8, y: right.y + 6)]),
                     with: .color(.black.opacity(0.16)))
        context.fill(polygon([left, peak, ridge, CGPoint(x: point.x - 5, y: point.y + 3)]),
                     with: .color(Color(red: 0.67, green: 0.66, blue: 0.51)))
        context.fill(polygon([peak, right, ridge]), with: .color(Color(red: 0.34, green: 0.39, blue: 0.30)))
        context.fill(polygon([ridge, right, CGPoint(x: point.x - 5, y: point.y + 3)]),
                     with: .color(Color(red: 0.49, green: 0.51, blue: 0.38)))
        let snowLine = point.y - height * 0.72
        context.fill(polygon([peak, CGPoint(x: peak.x - 8, y: snowLine),
                              CGPoint(x: peak.x - 1, y: snowLine - 3),
                              CGPoint(x: peak.x + 5, y: snowLine + 4),
                              CGPoint(x: peak.x + 8, y: snowLine - 1)]),
                     with: .color(Color(red: 0.91, green: 0.90, blue: 0.78).opacity(0.88)))
        var ridgeLine = Path()
        ridgeLine.move(to: peak)
        ridgeLine.addLine(to: ridge)
        ridgeLine.addLine(to: CGPoint(x: point.x + 2, y: point.y + 1))
        context.stroke(ridgeLine, with: .color(Color.white.opacity(0.25)), lineWidth: 0.75)
    }

    private func settlement(rect: CGRect, seed: Int, fortified: Bool, context: inout GraphicsContext) {
        let street = Path(CGRect(x: rect.midX - 23, y: rect.midY + 2, width: 51, height: 4))
        context.fill(street, with: .color(Color(red: 0.67, green: 0.64, blue: 0.49)))
        for index in 0..<(fortified ? 7 : 5) {
            let column = index % 3
            let row = index / 3
            let origin = CGPoint(x: rect.midX - 25 + CGFloat(column) * 16,
                                 y: rect.midY - 17 + CGFloat(row) * 18)
            let w: CGFloat = 10 + noise(seed, index + 61) * 4
            let h: CGFloat = 7 + noise(seed, index + 67) * 4
            house(at: origin, width: w, height: h, warmRoof: index % 3 != 0, context: &context)
        }
    }

    private func house(at p: CGPoint, width: CGFloat, height: CGFloat, warmRoof: Bool, context: inout GraphicsContext) {
        context.fill(polygon([CGPoint(x: p.x + 3, y: p.y + 6), CGPoint(x: p.x + width + 5, y: p.y + 5),
                              CGPoint(x: p.x + width + 8, y: p.y + height + 6), CGPoint(x: p.x + 6, y: p.y + height + 8)]),
                     with: .color(.black.opacity(0.22)))
        context.fill(Path(CGRect(x: p.x, y: p.y + 2, width: width, height: height)),
                     with: .color(Color(red: 0.82, green: 0.78, blue: 0.63)))
        context.fill(polygon([p, CGPoint(x: p.x + width * 0.55, y: p.y - 4),
                              CGPoint(x: p.x + width + 2, y: p.y + height * 0.2),
                              CGPoint(x: p.x + width, y: p.y + height * 0.55),
                              CGPoint(x: p.x - 1, y: p.y + height * 0.55)]),
                     with: .color(warmRoof ? Color(red: 0.56, green: 0.30, blue: 0.20) : Color(red: 0.37, green: 0.41, blue: 0.35)))
        context.fill(Path(CGRect(x: p.x + 2, y: p.y + height - 1, width: 2, height: 3)),
                     with: .color(Color(red: 0.23, green: 0.28, blue: 0.23)))
    }

    private func polygon(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
    }

    private func noise(_ seed: Int, _ salt: Int) -> CGFloat {
        let value = UInt64(bitPattern: Int64(seed &* 73856093 ^ salt &* 19349663))
        return CGFloat((value &* 1664525 &+ 1013904223) % 10007) / 10007
    }
}
