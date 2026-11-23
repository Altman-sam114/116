import CoreGraphics
import ImageIO
import SwiftUI

enum BattlefieldScenery: Int, CaseIterable {
    case forest, mountain, village, winterForest
    case openWoodland, mixedWoodland, sparseWinterWoodland, farmstead, industrialCity, supplyDepot
    case hqCitadel, fortifiedBunker, militaryAirfield, majorMetropolis
}

enum BattlefieldVehicleVariant: Int, CaseIterable {
    case tankDestroyer, tiger, priest, panther
    case pershing, kingTiger, calliope, panzerwerfer

    /// Appearance only: a historical name never changes the unit's rule archetype.
    static func matching(_ unit: BattleUnit) -> Self? {
        if unit.faction == .allies {
            if unit.kind == .recon && unit.name.contains("M10") { return .tankDestroyer }
            if unit.kind == .artillery && unit.name.contains("M7") { return .priest }
            if unit.kind == .artillery && (unit.name.contains("火箭") || unit.name.contains("远程炮兵群")) { return .calliope }
            if unit.kind == .tank && (unit.name.contains("重装突击") || unit.name.contains("潘兴") || unit.isElite) { return .pershing }
        } else {
            if unit.kind == .tank && unit.name.contains("虎式") { return .tiger }
            if unit.kind == .tank && unit.name.contains("豹式") { return .panther }
            if unit.kind == .tank && (unit.name.contains("虎王") || unit.name.contains("党卫装甲")) { return .kingTiger }
            if unit.kind == .artillery && unit.name.contains("火箭") { return .panzerwerfer }
        }
        return nil
    }
}

enum BattlefieldVFX: Int, CaseIterable {
    case explosion, muzzleFlash, smokePlume, commandBurst
}

enum BattlefieldResourceIcon: Int, CaseIterable {
    case gold, industry, medal, supply
}

enum BattlefieldShopIcon: Int, CaseIterable {
    case heroCross, panzerShield, fieldMedkit, warChest
}

enum BattlefieldEmblem: Int, CaseIterable {
    case hourglass, alliedCrest, axisCrest, hqLaurel
}

struct BattlefieldAssetDescriptor: Equatable {
    let name: String
    let subfolder: String
    let isAtlas2x2: Bool

    var relativePath: String {
        subfolder.isEmpty ? name : "\(subfolder)/\(name)"
    }
}

/// Bundled, original artwork organized cleanly under BattlefieldArt/{Terrain,Units,Commanders,VFX,UI}.
/// Decode each sheet once; all map and HUD instances share its CGImages.
enum BattlefieldArtwork {
    static let groundResourceName = "ground-field-v2"
    static let snowGroundResourceName = "ground-snow"
    static let riverWaterResourceName = "water-river"
    static let metalPlateResourceName = "ui-metal-plate"
    static let brassPanelResourceName = "ui-brass-panel"

    static let descriptors: [BattlefieldAssetDescriptor] = [
        // Terrain
        BattlefieldAssetDescriptor(name: groundResourceName, subfolder: "Terrain", isAtlas2x2: false),
        BattlefieldAssetDescriptor(name: snowGroundResourceName, subfolder: "Terrain", isAtlas2x2: false),
        BattlefieldAssetDescriptor(name: riverWaterResourceName, subfolder: "Terrain", isAtlas2x2: false),
        BattlefieldAssetDescriptor(name: "scenery-campaign", subfolder: "Terrain", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "woodland-campaign", subfolder: "Terrain", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "industrial-city", subfolder: "Terrain", isAtlas2x2: false),
        BattlefieldAssetDescriptor(name: "supply-depot", subfolder: "Terrain", isAtlas2x2: false),
        BattlefieldAssetDescriptor(name: "city-landmarks", subfolder: "Terrain", isAtlas2x2: true),
        // Units
        BattlefieldAssetDescriptor(name: "vehicles-field-v2", subfolder: "Units", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "troops", subfolder: "Units", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "armor-detail", subfolder: "Units", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "elite-units", subfolder: "Units", isAtlas2x2: true),
        // Commanders
        BattlefieldAssetDescriptor(name: "commanders", subfolder: "Commanders", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "commanders-hq", subfolder: "Commanders", isAtlas2x2: true),
        // VFX
        BattlefieldAssetDescriptor(name: "combat-vfx", subfolder: "VFX", isAtlas2x2: true),
        // UI
        BattlefieldAssetDescriptor(name: metalPlateResourceName, subfolder: "UI", isAtlas2x2: false),
        BattlefieldAssetDescriptor(name: brassPanelResourceName, subfolder: "UI", isAtlas2x2: false),
        BattlefieldAssetDescriptor(name: "ui-icons-resources", subfolder: "UI", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "ui-items-shop", subfolder: "UI", isAtlas2x2: true),
        BattlefieldAssetDescriptor(name: "ui-emblems", subfolder: "UI", isAtlas2x2: true)
    ]

    static let resourceNames: [String] = descriptors.map(\.name)

    private static let descriptorByName: [String: BattlefieldAssetDescriptor] = Dictionary(
        uniqueKeysWithValues: descriptors.map { ($0.name, $0) }
    )

    private static let sheets: [String: CGImage] = {
        var result: [String: CGImage] = [:]
        for item in descriptors {
            guard let url = resourceURL(item.name),
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { continue }
            result[item.name] = image
        }
        return result
    }()

    private static let sprites: [String: [CGImage]] = {
        var result: [String: [CGImage]] = [:]
        for item in descriptors where item.isAtlas2x2 {
            guard let sheet = sheets[item.name] else { continue }
            let cells = (0..<4).compactMap { index in
                sheet.cropping(to: cellRect(column: index % 2, row: index / 2,
                                            width: sheet.width, height: sheet.height))
            }
            if cells.count == 4 { result[item.name] = cells }
        }
        return result
    }()

    static func resourceURL(_ name: String) -> URL? {
        if let desc = descriptorByName[name] {
            let sub = desc.subfolder.isEmpty ? "BattlefieldArt" : "BattlefieldArt/\(desc.subfolder)"
            if let url = Bundle.main.url(forResource: desc.name, withExtension: "png", subdirectory: sub) {
                return url
            }
        }
        return Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "BattlefieldArt")
    }

    static func cellRect(column: Int, row: Int, width: Int, height: Int) -> CGRect {
        CGRect(x: column * width / 2, y: row * height / 2, width: width / 2, height: height / 2)
    }

    static func unit(_ kind: UnitKind, faction: Faction) -> CGImage? {
        let column = faction == .allies ? 0 : 1
        switch kind {
        case .tank: return sprites["vehicles-field-v2"]?[column]
        case .recon: return sprites["vehicles-field-v2"]?[2 + column]
        case .infantry: return sprites["troops"]?[column]
        case .artillery: return sprites["troops"]?[2 + column]
        }
    }

    static func scenery(_ kind: BattlefieldScenery) -> CGImage? {
        switch kind {
        case .industrialCity:
            return sheets["industrial-city"]
        case .supplyDepot:
            return sheets["supply-depot"]
        case .hqCitadel:
            return sprites["city-landmarks"]?[0]
        case .fortifiedBunker:
            return sprites["city-landmarks"]?[1]
        case .militaryAirfield:
            return sprites["city-landmarks"]?[2]
        case .majorMetropolis:
            return sprites["city-landmarks"]?[3]
        default:
            let index = kind.rawValue
            return index < 4 ? sprites["scenery-campaign"]?[index] : sprites["woodland-campaign"]?[index - 4]
        }
    }

    static func vehicle(_ variant: BattlefieldVehicleVariant) -> CGImage? {
        let index = variant.rawValue
        return index < 4 ? sprites["armor-detail"]?[index] : sprites["elite-units"]?[index - 4]
    }

    static func commander(_ commander: Commander) -> CGImage? {
        if let index = ["巴顿", "蒙哥马利", "古德里安", "曼施坦因"].firstIndex(of: commander.name) {
            return sprites["commanders"]?[index]
        }
        if let index = ["艾森豪威尔", "布莱德雷", "隆美尔", "朱可夫"].firstIndex(of: commander.name) {
            return sprites["commanders-hq"]?[index]
        }
        return nil
    }

    static func vfx(_ effect: BattlefieldVFX) -> CGImage? {
        sprites["combat-vfx"]?[effect.rawValue]
    }

    static func resourceIcon(_ icon: BattlefieldResourceIcon) -> CGImage? {
        sprites["ui-icons-resources"]?[icon.rawValue]
    }

    static func shopIcon(_ icon: BattlefieldShopIcon) -> CGImage? {
        sprites["ui-items-shop"]?[icon.rawValue]
    }

    static func emblem(_ emblem: BattlefieldEmblem) -> CGImage? {
        sprites["ui-emblems"]?[emblem.rawValue]
    }

    static var ground: CGImage? { sheets[groundResourceName] }
    static var snowGround: CGImage? { sheets[snowGroundResourceName] }
    static var riverWater: CGImage? { sheets[riverWaterResourceName] }
    static var metalPlate: CGImage? { sheets[metalPlateResourceName] }
    static var brassPanel: CGImage? { sheets[brassPanelResourceName] }

    static func image(_ cgImage: CGImage) -> Image {
        Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}
