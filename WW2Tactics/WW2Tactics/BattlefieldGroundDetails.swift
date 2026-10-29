import SwiftUI

struct BattlefieldFieldPlot: Equatable {
    let center: CGPoint
    let size: CGSize
    let angle: Double
    let isHarvested: Bool
    let corners: [CGPoint]

    init?(tile: TerrainTile, layout: BattlefieldMapLayout) {
        let seed = tile.coordinate.q * 997 + tile.coordinate.r * 131
        guard tile.terrain == .plains, !tile.isObjective,
              BattlefieldSceneryPlacement.noise(seed, 71) > 0.62 else { return nil }
        let point = layout.center(for: tile.coordinate)
        center = CGPoint(x: point.x + (BattlefieldSceneryPlacement.noise(seed, 73) - 0.5) * 18,
                         y: point.y + 9)
        size = CGSize(width: 48 + BattlefieldSceneryPlacement.noise(seed, 79) * 31,
                      height: 28 + BattlefieldSceneryPlacement.noise(seed, 83) * 20)
        angle = (Double(BattlefieldSceneryPlacement.noise(seed, 89)) - 0.5) * 44
        isHarvested = BattlefieldSceneryPlacement.noise(seed, 97) > 0.5
        let x = size.width / 2
        let y = size.height / 2
        corners = [
            CGPoint(x: -x + BattlefieldSceneryPlacement.noise(seed, 103) * 5, y: -y + 2),
            CGPoint(x: x - 2, y: -y + BattlefieldSceneryPlacement.noise(seed, 107) * 5),
            CGPoint(x: x - BattlefieldSceneryPlacement.noise(seed, 109) * 5, y: y - 1),
            CGPoint(x: -x + 1, y: y - BattlefieldSceneryPlacement.noise(seed, 113) * 5)
        ]
    }
}

/// Small-scale surface detail is deterministic and contains no gameplay state.
struct BattlefieldGroundDetails {
    let tiles: [TerrainTile]
    let layout: BattlefieldMapLayout

    func paint(context: inout GraphicsContext) {
        paintWoodlandFloor(context: &context)
        for tile in tiles {
            if let plot = BattlefieldFieldPlot(tile: tile, layout: layout) { paint(plot, context: &context) }
            if tile.terrain == .plains || tile.terrain == .forest { paintScrub(tile, context: &context) }
            if tile.terrain == .city { paintTownFootprint(tile, context: &context) }
        }
    }

    private func paintWoodlandFloor(context: inout GraphicsContext) {
        let wooded = Set(tiles.filter { $0.terrain == .forest }.map(\.coordinate))
        context.drawLayer { floor in
            floor.addFilter(.blur(radius: 8))
            var canopy = Path()
            for coordinate in wooded {
                let center = layout.center(for: coordinate)
                canopy.addEllipse(in: CGRect(x: center.x - 42, y: center.y - 24, width: 84, height: 56))
                for neighbor in coordinate.neighbors where wooded.contains(neighbor) {
                    let end = layout.center(for: neighbor)
                    canopy.addEllipse(in: CGRect(x: (center.x + end.x) / 2 - 28,
                                                y: (center.y + end.y) / 2 - 18, width: 56, height: 36))
                }
            }
            floor.fill(canopy, with: .color(Color(red: 0.21, green: 0.28, blue: 0.12).opacity(0.30)))
        }
    }

    private func paint(_ plot: BattlefieldFieldPlot, context: inout GraphicsContext) {
        var field = context
        field.translateBy(x: plot.center.x, y: plot.center.y)
        field.rotate(by: .degrees(plot.angle))
        let rect = CGRect(x: -plot.size.width / 2, y: -plot.size.height / 2,
                          width: plot.size.width, height: plot.size.height)
        var boundary = Path()
        boundary.addLines(plot.corners)
        boundary.closeSubpath()
        field.fill(boundary, with: .color(plot.isHarvested
            ? Color(red: 0.60, green: 0.49, blue: 0.29).opacity(0.30)
            : Color(red: 0.29, green: 0.38, blue: 0.18).opacity(0.32)))
        field.stroke(boundary, with: .color(Color(red: 0.24, green: 0.31, blue: 0.16).opacity(0.40)), lineWidth: 1.4)
        field.clip(to: boundary)
        var furrows = Path()
        for y in stride(from: rect.minY + 2, to: rect.maxY, by: 3) {
            furrows.move(to: CGPoint(x: rect.minX + 1, y: y))
            furrows.addLine(to: CGPoint(x: rect.maxX - 1, y: y))
        }
        field.stroke(furrows, with: .color(BattlefieldTheme.fieldPaper.opacity(0.11)), lineWidth: 0.6)
    }

    private func paintScrub(_ tile: TerrainTile, context: inout GraphicsContext) {
        let seed = tile.coordinate.q * 997 + tile.coordinate.r * 131
        let center = layout.center(for: tile.coordinate)
        for index in 0..<9 {
            let x = center.x + (BattlefieldSceneryPlacement.noise(seed, index + 101) - 0.5) * 72
            let y = center.y + (BattlefieldSceneryPlacement.noise(seed, index + 151) - 0.5) * 60
            let width: CGFloat = index.isMultiple(of: 3) ? 3.5 : 1.8
            context.fill(Path(ellipseIn: CGRect(x: x + 0.7, y: y + 1, width: width + 1, height: 1.7)),
                         with: .color(.black.opacity(0.12)))
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: width, height: width * 0.6)),
                         with: .color(Color(red: 0.32, green: 0.38, blue: 0.20).opacity(0.55)))
        }
    }

    private func paintTownFootprint(_ tile: TerrainTile, context: inout GraphicsContext) {
        let center = layout.center(for: tile.coordinate)
        context.drawLayer { floor in
            floor.addFilter(.blur(radius: 5))
            floor.fill(Path(ellipseIn: CGRect(x: center.x - 45, y: center.y - 20, width: 90, height: 48)),
                       with: .color(Color(red: 0.58, green: 0.54, blue: 0.39).opacity(0.52)))
        }
    }
}
