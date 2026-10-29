import CoreGraphics
import Foundation

struct BattlefieldRiverBankDetail: Equatable {
    let fraction: CGFloat
    let side: CGFloat
    let center: CGPoint
    let radius: CGFloat
    let isStone: Bool
}

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

    func surfaceTrace(lane: CGFloat, from lower: CGFloat = 0, to upper: CGFloat = 1) -> CGPath {
        let path = CGMutablePath()
        let lower = min(1, max(0, lower))
        let upper = max(lower, min(1, upper))
        let lane = min(1, max(-1, lane))
        let points = (0...24).map { index in
            let fraction = lower + (upper - lower) * CGFloat(index) / 24
            let center = point(at: fraction)
            let normal = normal(at: fraction)
            return CGPoint(x: center.x + normal.x * halfWidth(at: fraction) * lane,
                           y: center.y + normal.y * halfWidth(at: fraction) * lane)
        }
        path.addLines(between: points)
        return path
    }

    /// Decorative reeds and stones follow actual banks; they never add terrain or cover rules.
    var bankDetails: [BattlefieldRiverBankDetail] {
        var details: [BattlefieldRiverBankDetail] = []
        for index in 1...6 {
            let fraction = CGFloat(index) / 7
            let center = point(at: fraction)
            let normal = normal(at: fraction)
            for side in [CGFloat(-1), 1] {
                let variation = CGFloat(abs(sin(Double(start.x * 0.17 + end.y * 0.29) + Double(index) * 13.7 + Double(side))))
                let offset = halfWidth(at: fraction) + 2.2 + variation * 3
                details.append(BattlefieldRiverBankDetail(
                    fraction: fraction, side: side,
                    center: CGPoint(x: center.x + normal.x * offset * side,
                                    y: center.y + normal.y * offset * side),
                    radius: 0.8 + variation * 0.9, isStone: variation > 0.72
                ))
            }
        }
        return details
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
    let townContinuations: Set<HexCoordinate>
    let terminalPools: [CGRect]

    init(tiles: [TerrainTile], layout: BattlefieldMapLayout) {
        let river = Set(tiles.filter { $0.terrain == .river }.map(\.coordinate))
        let continuations = Set(tiles.filter { tile in
            guard tile.terrain == .city || tile.terrain == .road else { return false }
            return (0..<3).contains { axis in
                river.contains(tile.coordinate.neighbors[axis]) && river.contains(tile.coordinate.neighbors[axis + 3])
            }
        }.map(\.coordinate))
        let coordinates = river.union(continuations)
        var ribbons: [BattlefieldRiverRibbon] = []
        var pools: [CGRect] = []
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
                pools.append(CGRect(x: center.x - 20, y: center.y - 12, width: 40, height: 24))
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
                    if neighbors.count == 1 {
                        pools.append(CGRect(x: start.x - 7, y: start.y - 6, width: 14, height: 12))
                    }
                    ribbons.append(BattlefieldRiverRibbon(
                        start: start, firstControl: Self.offset(start, along: direction, by: 15),
                        secondControl: Self.offset(end.point, along: direction, by: -18), end: end.point,
                        startHalfWidth: neighbors.count == 1 ? 5.5 : 10, endHalfWidth: end.halfWidth
                    ))
                }
            }
        }
        self.ribbons = ribbons
        townContinuations = continuations
        terminalPools = pools
    }

    static func junction(from first: HexCoordinate, to second: HexCoordinate, layout: BattlefieldMapLayout) -> BattlefieldRiverJunction {
        let a = precedes(first, second) ? first : second
        let b = a == first ? second : first
        let start = layout.center(for: a)
        let end = layout.center(for: b)
        let direction = unitVector(from: start, to: end)
        let seed = Double(a.q * 73 + a.r * 137 + b.q * 211 + b.r * 43)
        let drift = CGFloat(sin(seed * 0.71)) * 9
        return BattlefieldRiverJunction(
            point: CGPoint(x: (start.x + end.x) / 2 - direction.y * drift,
                           y: (start.y + end.y) / 2 + direction.x * drift),
            halfWidth: 8 + CGFloat((sin(seed * 0.37) + 1) / 2) * 5
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
