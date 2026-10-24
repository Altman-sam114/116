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

    init?(tile: TerrainTile, layout: BattlefieldMapLayout) {
        let coordinate = tile.coordinate
        let seed = coordinate.q * 997 + coordinate.r * 131
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
            kind = tile.isObjective ? .village : .farmstead
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
