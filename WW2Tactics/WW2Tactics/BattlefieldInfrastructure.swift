import CoreGraphics
import Foundation

struct BattlefieldBridge: Equatable {
    let coordinate: HexCoordinate
    let direction: Int
}

/// Visual connectivity only. Neither bridges nor town streets change movement costs.
struct BattlefieldInfrastructure {
    let directionsByCoordinate: [HexCoordinate: [Int]]
    let bridges: [BattlefieldBridge]

    init(tiles: [TerrainTile], roadConnections: [HexCoordinate: [Int]]) {
        let terrain = Dictionary(uniqueKeysWithValues: tiles.map { ($0.coordinate, $0.terrain) })
        var directions = roadConnections.mapValues { Set($0) }
        var bridges: [BattlefieldBridge] = []
        let sorted = tiles.sorted {
            $0.coordinate.r == $1.coordinate.r ? $0.coordinate.q < $1.coordinate.q : $0.coordinate.r < $1.coordinate.r
        }
        func isStreet(_ coordinate: HexCoordinate) -> Bool {
            terrain[coordinate] == .road || terrain[coordinate] == .city
        }
        for tile in sorted {
            let coordinate = tile.coordinate
            if tile.terrain == .city {
                for (index, neighbor) in coordinate.neighbors.enumerated() where isStreet(neighbor) {
                    directions[coordinate, default: []].insert(index)
                    directions[neighbor, default: []].insert((index + 3) % 6)
                }
            } else if tile.terrain == .river {
                // A crossing requires actual streets on BOTH opposite banks, never a guessed shortcut.
                if let axis = (0..<3).first(where: {
                    isStreet(coordinate.neighbors[$0]) && isStreet(coordinate.neighbors[$0 + 3])
                }) {
                    bridges.append(BattlefieldBridge(coordinate: coordinate, direction: axis))
                    for index in [axis, axis + 3] {
                        let neighbor = coordinate.neighbors[index]
                        directions[coordinate, default: []].insert(index)
                        directions[neighbor, default: []].insert((index + 3) % 6)
                    }
                }
            }
        }
        self.directionsByCoordinate = directions.mapValues { $0.sorted() }
        self.bridges = bridges
    }
}

struct BattlefieldSceneryPlacement: Equatable {
    let kind: BattlefieldScenery
    let rect: CGRect
    let mirrored: Bool

    init?(tile: TerrainTile, layout: BattlefieldMapLayout) {
        let coordinate = tile.coordinate
        let seed = coordinate.q * 997 + coordinate.r * 131
        mirrored = Self.noise(seed, 43) > 0.5
        let width: CGFloat
        let height: CGFloat
        switch tile.terrain {
        case .forest:
            let variants: [BattlefieldScenery] = [.forest, .openWoodland, .mixedWoodland]
            kind = variants[Int(Self.noise(seed, 31) * 3) % 3]
            width = 103; height = 84
        case .mountain:
            kind = .mountain
            width = 125; height = 96
        case .city:
            kind = tile.isObjective && Self.noise(seed, 47) > 0.35 ? .village : .farmstead
            width = 101; height = 79
        case .snow:
            guard Self.noise(seed, 29) > 0.50 else { return nil }
            kind = Self.noise(seed, 37) > 0.30 ? .sparseWinterWoodland : .winterForest
            width = 104; height = 82
        default:
            guard tile.isObjective else { return nil }
            kind = .farmstead
            width = 85; height = 67
        }
        let point = layout.center(for: coordinate)
        let variation = 0.86 + Self.noise(seed, 13) * 0.27
        let size = CGSize(width: width * variation, height: height * variation)
        rect = CGRect(x: point.x - size.width / 2 + (Self.noise(seed, 19) - 0.5) * 13,
                      y: point.y - size.height / 2 + 2 + (Self.noise(seed, 23) - 0.5) * 10,
                      width: size.width, height: size.height)
    }

    static func noise(_ seed: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return CGFloat(value - floor(value))
    }
}

struct BattlefieldRoadSegment: Equatable {
    let first: HexCoordinate
    let second: HexCoordinate
    let start: CGPoint
    let firstControl: CGPoint
    let secondControl: CGPoint
    let end: CGPoint
}

/// One curve per real paired edge. Endpoints stay attached to towns, junctions and bridges.
struct BattlefieldRoadGeometry {
    let segments: [BattlefieldRoadSegment]

    init(infrastructure: BattlefieldInfrastructure, layout: BattlefieldMapLayout) {
        let connections = infrastructure.directionsByCoordinate
        var result: [BattlefieldRoadSegment] = []
        let coordinates = connections.keys.sorted { $0.r == $1.r ? $0.q < $1.q : $0.r < $1.r }
        for coordinate in coordinates {
            for direction in connections[coordinate] ?? [] where (0..<6).contains(direction) {
                let neighbor = coordinate.neighbors[direction]
                let isOrdered = coordinate.r == neighbor.r ? coordinate.q < neighbor.q : coordinate.r < neighbor.r
                guard isOrdered, connections[neighbor]?.contains((direction + 3) % 6) == true else { continue }
                let start = layout.center(for: coordinate)
                let end = layout.center(for: neighbor)
                let dx = end.x - start.x
                let dy = end.y - start.y
                let length = max(1, hypot(dx, dy))
                let seed = coordinate.q * 997 + coordinate.r * 131 + neighbor.q * 61 + neighbor.r * 37
                let bend = (BattlefieldSceneryPlacement.noise(seed, 53) - 0.5) * 12
                let shift = CGPoint(x: -dy / length * bend, y: dx / length * bend)
                result.append(BattlefieldRoadSegment(
                    first: coordinate, second: neighbor, start: start,
                    firstControl: CGPoint(x: start.x + dx / 3 + shift.x, y: start.y + dy / 3 + shift.y),
                    secondControl: CGPoint(x: start.x + dx * 2 / 3 + shift.x, y: start.y + dy * 2 / 3 + shift.y),
                    end: end
                ))
            }
        }
        segments = result
    }
}
