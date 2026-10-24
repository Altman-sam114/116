import CoreGraphics
import Foundation

struct BattlefieldRiverJunction: Equatable {
    let point: CGPoint
    let halfWidth: CGFloat
}

struct BattlefieldRiverRibbon {
    let start: CGPoint
    let firstControl: CGPoint
    let secondControl: CGPoint
    let end: CGPoint
    let startHalfWidth: CGFloat
    let endHalfWidth: CGFloat

    func point(at fraction: CGFloat) -> CGPoint {
        let t = min(1, max(0, fraction))
        let s = 1 - t
        return CGPoint(x: s * s * s * start.x + 3 * s * s * t * firstControl.x + 3 * s * t * t * secondControl.x + t * t * t * end.x,
                       y: s * s * s * start.y + 3 * s * s * t * firstControl.y + 3 * s * t * t * secondControl.y + t * t * t * end.y)
    }

    func normal(at fraction: CGFloat) -> CGPoint {
        let t = min(1, max(0, fraction))
        let s = 1 - t
        let dx = 3 * s * s * (firstControl.x - start.x) + 6 * s * t * (secondControl.x - firstControl.x) + 3 * t * t * (end.x - secondControl.x)
        let dy = 3 * s * s * (firstControl.y - start.y) + 6 * s * t * (secondControl.y - firstControl.y) + 3 * t * t * (end.y - secondControl.y)
        let length = max(0.001, hypot(dx, dy))
        return CGPoint(x: -dy / length, y: dx / length)
    }

    func halfWidth(at fraction: CGFloat) -> CGFloat {
        let t = min(1, max(0, fraction))
        return startHalfWidth + (endHalfWidth - startHalfWidth) * t + sin(t * .pi) * 1.4
    }

    func outline(expansion: CGFloat = 0) -> CGPath {
        let path = CGMutablePath()
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        for index in 0...16 {
            let t = CGFloat(index) / 16
            let center = point(at: t)
            let normal = normal(at: t)
            let width = max(0.5, halfWidth(at: t) + expansion)
            left.append(CGPoint(x: center.x + normal.x * width, y: center.y + normal.y * width))
            right.append(CGPoint(x: center.x - normal.x * width, y: center.y - normal.y * width))
        }
        path.addLines(between: left + Array(right.reversed()))
        path.closeSubpath()
        return path
    }
}

struct BattlefieldRiverGeometry {
    let ribbons: [BattlefieldRiverRibbon]

    init(tiles: [TerrainTile], layout: BattlefieldMapLayout) {
        let coordinates = Set(tiles.filter { $0.terrain == .river }.map(\.coordinate))
        var ribbons: [BattlefieldRiverRibbon] = []
        for coordinate in coordinates.sorted(by: Self.precedes) {
            let center = layout.center(for: coordinate)
            let neighbors = coordinate.neighbors.filter { coordinates.contains($0) }
            let endpoints = neighbors.map { Self.junction(from: coordinate, to: $0, layout: layout) }
            if neighbors.count == 2 {
                let first = endpoints[0]
                let last = endpoints[1]
                let entry = Self.unitVector(from: layout.center(for: neighbors[0]), to: center)
                let exit = Self.unitVector(from: center, to: layout.center(for: neighbors[1]))
                ribbons.append(BattlefieldRiverRibbon(
                    start: first.point, firstControl: Self.offset(first.point, along: entry, by: 27),
                    secondControl: Self.offset(last.point, along: exit, by: -27), end: last.point,
                    startHalfWidth: first.halfWidth, endHalfWidth: last.halfWidth
                ))
            } else if neighbors.isEmpty {
                ribbons.append(BattlefieldRiverRibbon(
                    start: CGPoint(x: center.x - 17, y: center.y - 8), firstControl: CGPoint(x: center.x - 8, y: center.y - 12),
                    secondControl: CGPoint(x: center.x + 9, y: center.y + 12), end: CGPoint(x: center.x + 17, y: center.y + 8),
                    startHalfWidth: 2, endHalfWidth: 3
                ))
            } else {
                for (index, neighbor) in neighbors.enumerated() {
                    let end = endpoints[index]
                    let direction = Self.unitVector(from: center, to: layout.center(for: neighbor))
                    let start = neighbors.count == 1 ? Self.offset(center, along: direction, by: -16) : center
                    ribbons.append(BattlefieldRiverRibbon(
                        start: start, firstControl: Self.offset(start, along: direction, by: 15),
                        secondControl: Self.offset(end.point, along: direction, by: -18), end: end.point,
                        startHalfWidth: neighbors.count == 1 ? 1.5 : 8, endHalfWidth: end.halfWidth
                    ))
                }
            }
        }
        self.ribbons = ribbons
    }

    static func junction(from first: HexCoordinate, to second: HexCoordinate, layout: BattlefieldMapLayout) -> BattlefieldRiverJunction {
        let a = precedes(first, second) ? first : second
        let b = a == first ? second : first
        let start = layout.center(for: a)
        let end = layout.center(for: b)
        let direction = unitVector(from: start, to: end)
        let seed = Double(a.q * 73 + a.r * 137 + b.q * 211 + b.r * 43)
        let drift = CGFloat(sin(seed * 0.71)) * 6
        return BattlefieldRiverJunction(
            point: CGPoint(x: (start.x + end.x) / 2 - direction.y * drift,
                           y: (start.y + end.y) / 2 + direction.x * drift),
            halfWidth: 6.5 + CGFloat((sin(seed * 0.37) + 1) / 2) * 3.5
        )
    }

    private static func precedes(_ left: HexCoordinate, _ right: HexCoordinate) -> Bool {
        left.r == right.r ? left.q < right.q : left.r < right.r
    }

    private static func unitVector(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let length = max(0.001, hypot(end.x - start.x, end.y - start.y))
        return CGPoint(x: (end.x - start.x) / length, y: (end.y - start.y) / length)
    }

    private static func offset(_ point: CGPoint, along vector: CGPoint, by distance: CGFloat) -> CGPoint {
        CGPoint(x: point.x + vector.x * distance, y: point.y + vector.y * distance)
    }
}
