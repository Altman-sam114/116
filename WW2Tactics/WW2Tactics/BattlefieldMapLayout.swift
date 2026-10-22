import CoreGraphics

/// Point-up axial projection shared by terrain, hit targets, scrolling and combat.
struct BattlefieldMapLayout {
    static let tileSize = CGSize(width: 86, height: 100)
    static let margin: CGFloat = 24

    let size: CGSize
    private let offset: CGPoint

    init(coordinates: [HexCoordinate]) {
        let frames = coordinates.map { Self.rawFrame(for: $0) }
        let bounds = frames.reduce(CGRect.null) { $0.union($1) }
        if bounds.isNull {
            offset = CGPoint(x: Self.margin, y: Self.margin)
            size = CGSize(width: Self.tileSize.width + Self.margin * 2,
                          height: Self.tileSize.height + Self.margin * 2)
        } else {
            offset = CGPoint(x: Self.margin - bounds.minX, y: Self.margin - bounds.minY)
            size = CGSize(width: bounds.width + Self.margin * 2,
                          height: bounds.height + Self.margin * 2)
        }
    }

    static func rawCenter(for coordinate: HexCoordinate) -> CGPoint {
        CGPoint(x: (CGFloat(coordinate.q) + CGFloat(coordinate.r) / 2) * tileSize.width + tileSize.width / 2,
                y: CGFloat(coordinate.r) * tileSize.height * 0.75 + tileSize.height / 2)
    }

    private static func rawFrame(for coordinate: HexCoordinate) -> CGRect {
        let center = rawCenter(for: coordinate)
        return CGRect(x: center.x - tileSize.width / 2, y: center.y - tileSize.height / 2,
                      width: tileSize.width, height: tileSize.height)
    }

    func center(for coordinate: HexCoordinate) -> CGPoint {
        let point = Self.rawCenter(for: coordinate)
        return CGPoint(x: point.x + offset.x, y: point.y + offset.y)
    }

    func frame(for coordinate: HexCoordinate) -> CGRect {
        Self.rawFrame(for: coordinate).offsetBy(dx: offset.x, dy: offset.y)
    }

    func scaledSize(_ scale: CGFloat) -> CGSize {
        let safeScale = scale.isFinite && scale > 0 ? scale : 1
        return CGSize(width: size.width * safeScale, height: size.height * safeScale)
    }

    func scaledCenter(for coordinate: HexCoordinate, scale: CGFloat) -> CGPoint {
        let safeScale = scale.isFinite && scale > 0 ? scale : 1
        let point = center(for: coordinate)
        return CGPoint(x: point.x * safeScale, y: point.y * safeScale)
    }

    func combatFocusPoint(attacker: HexCoordinate, defender: HexCoordinate, scale: CGFloat) -> CGPoint {
        let start = scaledCenter(for: attacker, scale: scale)
        let end = scaledCenter(for: defender, scale: scale)
        return CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }

    static func vertices(in rect: CGRect) -> [CGPoint] {
        [CGPoint(x: rect.midX, y: rect.minY),
         CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
         CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.75),
         CGPoint(x: rect.midX, y: rect.maxY),
         CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.75),
         CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25)]
    }
}

struct UnitReadinessPresentation: Equatable {
    let canMove: Bool
    let canAttack: Bool

    init(hasMoved: Bool, hasAttacked: Bool) {
        canMove = !hasMoved
        canAttack = !hasAttacked
    }

    var isSpent: Bool { !canMove && !canAttack }
    var moveSymbol: String { canMove ? "arrow.up.right" : "checkmark" }
    var attackSymbol: String { canAttack ? "scope" : "checkmark" }
}
