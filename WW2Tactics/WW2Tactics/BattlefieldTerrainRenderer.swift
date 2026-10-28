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
            BattlefieldGroundDetails(tiles: tiles, layout: layout).paint(context: &context)
            paintSnow(context: &context)
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
                               with: .color(Color(red: 0.15, green: 0.20, blue: 0.13).opacity(tile.terrain == .snow ? 0.24 : 0.18)),
                               lineWidth: 0.55)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func paintGround(context: inout GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(BattlefieldTheme.mapGround))
        guard let ground = BattlefieldArtwork.ground else { return }
        let image = context.resolve(BattlefieldArtwork.image(ground))
        var material = context
        material.opacity = 0.64
        let step: CGFloat = 384
        for y in stride(from: CGFloat.zero, to: size.height, by: step) {
            for x in stride(from: CGFloat.zero, to: size.width, by: step) {
                material.draw(image, in: CGRect(x: x, y: y, width: step, height: step))
            }
        }
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [.yellow.opacity(0.035), .black.opacity(0.06)]),
                                           startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
    }

    private func paintRelief(context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 18))
            for tile in tiles where tile.terrain != .river {
                let seed = seed(for: tile)
                guard noise(seed, 41) > 0.60 else { continue }
                let center = layout.center(for: tile.coordinate)
                let rect = CGRect(x: center.x - 95, y: center.y - 46, width: 190, height: 92)
                let shade = tile.terrain == .forest || tile.terrain == .mountain
                layer.fill(Path(ellipseIn: rect), with: .color(
                    shade ? Color(red: 0.17, green: 0.24, blue: 0.11).opacity(0.30)
                          : Color(red: 0.72, green: 0.68, blue: 0.43).opacity(0.20)
                ))
            }
        }
    }

    private func paintSnow(context: inout GraphicsContext) {
        var drifts = Path()
        for tile in tiles where tile.terrain == .snow {
            drifts.addPath(Hexagon().path(in: layout.frame(for: tile.coordinate).insetBy(dx: -1, dy: -1)))
        }
        guard !drifts.isEmpty else { return }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 8))
            layer.fill(drifts, with: .color(Color(red: 0.84, green: 0.87, blue: 0.82).opacity(0.84)))
        }
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
                       style: StrokeStyle(lineWidth: 6.2, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.70, green: 0.64, blue: 0.47).opacity(0.94)),
                       style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
        context.stroke(roads, with: .color(Color(red: 0.36, green: 0.32, blue: 0.22).opacity(0.32)),
                       style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round, dash: [3, 2]))
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
        context.fill(bank, with: .color(Color(red: 0.62, green: 0.60, blue: 0.41)))
        context.fill(water, with: .linearGradient(
            Gradient(colors: [Color(red: 0.32, green: 0.49, blue: 0.51), Color(red: 0.15, green: 0.30, blue: 0.34)]),
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

extension TerrainKind {
    var showsMapConnections: Bool {
        switch self {
        case .river, .road, .forest:
            true
        case .plains, .city, .mountain, .snow:
            false
        }
    }

    var connectionColor: Color {
        switch self {
        case .river:
            Color(red: 0.26, green: 0.50, blue: 0.68).opacity(0.90)
        case .road:
            // Dirt-tan road band; slimmer + softer so clustered road hexes
            // read as winding paths instead of a heavy triangle lattice.
            Color(red: 0.55, green: 0.46, blue: 0.30).opacity(0.64)
        case .forest:
            Color(red: 0.30, green: 0.44, blue: 0.26).opacity(0.20)
        case .city:
            Color.black.opacity(0.10)
        case .mountain:
            Color.white.opacity(0.08)
        case .snow:
            Color.white.opacity(0.12)
        case .plains:
            Color.yellow.opacity(0.06)
        }
    }

    var connectionWidth: CGFloat {
        switch self {
        case .river: 11
        case .road: 4.5
        case .forest: 8
        case .city: 12
        case .mountain, .snow, .plains: 7
        }
    }

    var mapGradient: LinearGradient {
        LinearGradient(
            colors: [
                mapHighlightColor,
                mapColor,
                mapShadowColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // EasyTech GoG3-style continuous ground: neighbours share one pale
    // field tone so the battlefield reads as a single painted landscape,
    // with terrain identity carried mostly by the painted texture layer.
    var mapColor: Color {
        switch self {
        case .plains:
            Color(red: 0.66, green: 0.68, blue: 0.50)
        case .forest:
            Color(red: 0.58, green: 0.65, blue: 0.46)
        case .city:
            Color(red: 0.67, green: 0.67, blue: 0.57)
        case .mountain:
            Color(red: 0.64, green: 0.64, blue: 0.55)
        case .snow:
            Color(red: 0.90, green: 0.92, blue: 0.92)
        case .river:
            // Land-toned fill: the winding blue connection band carries the
            // water so rivers read as a channel, not a solid blue hex.
            Color(red: 0.62, green: 0.68, blue: 0.56)
        case .road:
            Color(red: 0.67, green: 0.68, blue: 0.50)
        }
    }

    private var mapHighlightColor: Color {
        switch self {
        case .plains:
            Color(red: 0.70, green: 0.72, blue: 0.54)
        case .forest:
            Color(red: 0.63, green: 0.70, blue: 0.50)
        case .city:
            Color(red: 0.71, green: 0.72, blue: 0.62)
        case .mountain:
            Color(red: 0.68, green: 0.68, blue: 0.59)
        case .snow:
            Color(red: 0.94, green: 0.96, blue: 0.96)
        case .river:
            Color(red: 0.67, green: 0.72, blue: 0.61)
        case .road:
            Color(red: 0.71, green: 0.72, blue: 0.54)
        }
    }

    private var mapShadowColor: Color {
        switch self {
        case .plains:
            Color(red: 0.61, green: 0.64, blue: 0.46)
        case .forest:
            Color(red: 0.53, green: 0.60, blue: 0.42)
        case .city:
            Color(red: 0.62, green: 0.63, blue: 0.52)
        case .mountain:
            Color(red: 0.59, green: 0.60, blue: 0.50)
        case .snow:
            Color(red: 0.87, green: 0.89, blue: 0.89)
        case .river:
            Color(red: 0.58, green: 0.64, blue: 0.52)
        case .road:
            Color(red: 0.62, green: 0.63, blue: 0.46)
        }
    }

    var mapSymbol: String {
        switch self {
        case .plains:
            "·"
        case .forest:
            "♣"
        case .city:
            "▦"
        case .mountain:
            "△"
        case .snow:
            "*"
        case .river:
            "≈"
        case .road:
            "="
        }
    }

    var symbolColor: Color {
        switch self {
        case .forest, .mountain, .river:
            Color.white.opacity(0.38)
        case .snow:
            Color.black.opacity(0.32)
        default:
            Color.black.opacity(0.28)
        }
    }
}
