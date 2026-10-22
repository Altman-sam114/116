import CoreGraphics
import ImageIO
import SwiftUI

enum BattlefieldScenery: Int, CaseIterable {
    case forest, mountain, village, winterForest
}

/// Bundled, original artwork. Decode each sheet once; all map instances share its CGImages.
enum BattlefieldArtwork {
    static let resourceNames = ["vehicles", "troops", "scenery", "ground"]

    private static let sheets: [String: CGImage] = {
        var result: [String: CGImage] = [:]
        for name in resourceNames {
            guard let url = resourceURL(name),
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { continue }
            result[name] = image
        }
        return result
    }()

    private static let sprites: [String: [CGImage]] = {
        var result: [String: [CGImage]] = [:]
        for name in ["vehicles", "troops", "scenery"] {
            guard let sheet = sheets[name] else { continue }
            let cells = (0..<4).compactMap { index in
                sheet.cropping(to: cellRect(column: index % 2, row: index / 2,
                                            width: sheet.width, height: sheet.height))
            }
            if cells.count == 4 { result[name] = cells }
        }
        return result
    }()

    static func resourceURL(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "BattlefieldArt")
    }

    static func cellRect(column: Int, row: Int, width: Int, height: Int) -> CGRect {
        CGRect(x: column * width / 2, y: row * height / 2, width: width / 2, height: height / 2)
    }

    static func unit(_ kind: UnitKind, faction: Faction) -> CGImage? {
        let column = faction == .allies ? 0 : 1
        switch kind {
        case .tank: return sprites["vehicles"]?[column]
        case .recon: return sprites["vehicles"]?[2 + column]
        case .infantry: return sprites["troops"]?[column]
        case .artillery: return sprites["troops"]?[2 + column]
        }
    }

    static func scenery(_ kind: BattlefieldScenery) -> CGImage? {
        sprites["scenery"]?[kind.rawValue]
    }

    static var ground: CGImage? { sheets["ground"] }

    static func image(_ cgImage: CGImage) -> Image {
        Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}
