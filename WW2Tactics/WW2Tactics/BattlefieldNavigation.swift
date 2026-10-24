import SwiftUI

struct BattlefieldOverviewProjection {
    let layout: BattlefieldMapLayout
    let coordinates: [HexCoordinate]
    let scale: CGFloat
    let contentRect: CGRect

    init(coordinates: [HexCoordinate], size: CGSize) {
        self.coordinates = Set(coordinates).sorted { $0.r == $1.r ? $0.q < $1.q : $0.r < $1.r }
        layout = BattlefieldMapLayout(coordinates: coordinates)
        let width = size.width.isFinite ? max(0, size.width - 8) : 0
        let height = size.height.isFinite ? max(0, size.height - 8) : 0
        scale = coordinates.isEmpty ? 0 : min(width / layout.size.width, height / layout.size.height)
        let fitted = layout.scaledSize(scale > 0 ? scale : 1)
        contentRect = scale > 0
            ? CGRect(x: (size.width - fitted.width) / 2, y: (size.height - fitted.height) / 2,
                     width: fitted.width, height: fitted.height)
            : .zero
    }

    func point(for coordinate: HexCoordinate) -> CGPoint {
        let center = layout.center(for: coordinate)
        return CGPoint(x: contentRect.minX + center.x * scale, y: contentRect.minY + center.y * scale)
    }

    func coordinate(at point: CGPoint) -> HexCoordinate? {
        guard scale > 0, point.x.isFinite, point.y.isFinite, contentRect.contains(point) else { return nil }
        guard let nearest = coordinates.min(by: {
            distanceSquared(point, self.point(for: $0)) < distanceSquared(point, self.point(for: $1))
        }) else { return nil }
        let mapPoint = CGPoint(x: (point.x - contentRect.minX) / scale, y: (point.y - contentRect.minY) / scale)
        return Hexagon().path(in: layout.frame(for: nearest)).contains(mapPoint) ? nearest : nil
    }

    private func distanceSquared(_ left: CGPoint, _ right: CGPoint) -> CGFloat {
        let dx = left.x - right.x
        let dy = left.y - right.y
        return dx * dx + dy * dy
    }
}

struct BattlefieldOverviewMap: View {
    let tiles: [TerrainTile]
    let units: [BattleUnit]
    let focusedCoordinate: HexCoordinate?
    let onFocus: (HexCoordinate) -> Void
    let onFrontline: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("战区总览").font(.system(size: 10, weight: .bold))
                Spacer()
                Image(systemName: "location.north.fill").font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(BattlefieldTheme.brass)
            GeometryReader { geometry in
                let projection = BattlefieldOverviewProjection(coordinates: tiles.map(\.coordinate), size: geometry.size)
                Canvas { context, _ in
                    for tile in tiles {
                        let point = projection.point(for: tile.coordinate)
                        let size = BattlefieldMapLayout.tileSize
                        let rect = CGRect(x: point.x - size.width * projection.scale / 2,
                                          y: point.y - size.height * projection.scale / 2,
                                          width: size.width * projection.scale, height: size.height * projection.scale)
                        context.fill(Hexagon().path(in: rect), with: .color(terrainColor(tile.terrain)))
                        if tile.isObjective {
                            context.fill(Path(CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)),
                                         with: .color(tile.owner?.accentColor ?? BattlefieldTheme.brass))
                        }
                    }
                    for unit in units where !unit.isDestroyed {
                        let point = projection.point(for: unit.position)
                        let marker = unit.faction == .allies
                            ? Path(ellipseIn: CGRect(x: point.x - 1.8, y: point.y - 1.8, width: 3.6, height: 3.6))
                            : Path { path in
                                path.move(to: CGPoint(x: point.x, y: point.y - 2.5))
                                path.addLines([CGPoint(x: point.x + 2.5, y: point.y),
                                               CGPoint(x: point.x, y: point.y + 2.5),
                                               CGPoint(x: point.x - 2.5, y: point.y)])
                                path.closeSubpath()
                            }
                        context.fill(marker, with: .color(unit.faction.accentColor))
                        context.stroke(marker, with: .color(.black.opacity(0.65)), lineWidth: 0.5)
                    }
                    if let focusedCoordinate {
                        let point = projection.point(for: focusedCoordinate)
                        context.stroke(Path(CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)),
                                       with: .color(.white), lineWidth: 1)
                    }
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { value in
                    if let coordinate = projection.coordinate(at: value.location) { onFocus(coordinate) }
                })
            }
            .frame(height: 74)
            .background(Color.black.opacity(0.20))
            HStack(spacing: 10) {
                Label("AL", systemImage: "circle.fill").foregroundStyle(Faction.allies.accentColor)
                Label("AX", systemImage: "diamond.fill").foregroundStyle(Faction.axis.accentColor)
                Label("据点", systemImage: "square").foregroundStyle(BattlefieldTheme.brass)
                Spacer(minLength: 0)
            }
            .font(.system(size: 8, weight: .bold))
            Text("点按定位 · 不执行指令")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(BattlefieldTheme.mutedInk)
        }
        .padding(8)
        .frame(width: 186)
        .background(BattlefieldTheme.commandMetal, in: RoundedRectangle(cornerRadius: 3))
        .overlay { RoundedRectangle(cornerRadius: 3).stroke(BattlefieldTheme.brass.opacity(0.34), lineWidth: 0.8) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("战区总览，\(units.filter { !$0.isDestroyed }.count)支部队，\(tiles.filter(\.isObjective).count)个据点")
        .accessibilityHint("双击返回交战前线；总览只定位，不执行指令")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(onFrontline)
    }

    private func terrainColor(_ terrain: TerrainKind) -> Color {
        switch terrain {
        case .river: Color(red: 0.31, green: 0.53, blue: 0.58)
        case .forest: Color(red: 0.22, green: 0.31, blue: 0.21)
        case .mountain: Color(red: 0.48, green: 0.48, blue: 0.38)
        case .snow: Color(red: 0.68, green: 0.72, blue: 0.64)
        case .city: Color(red: 0.64, green: 0.57, blue: 0.41)
        case .road: Color(red: 0.55, green: 0.51, blue: 0.36)
        case .plains: Color(red: 0.40, green: 0.46, blue: 0.29)
        }
    }
}
