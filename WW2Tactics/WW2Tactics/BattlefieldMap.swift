import SwiftUI
import UIKit

private struct CombatResolutionSteadyStateKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var combatResolutionSteadyState: Bool {
        get { self[CombatResolutionSteadyStateKey.self] }
        set { self[CombatResolutionSteadyStateKey.self] = newValue }
    }
}

private struct RoadDisjointSet {
    private var parent: [HexCoordinate: HexCoordinate]

    init(elements: [HexCoordinate]) {
        parent = Dictionary(uniqueKeysWithValues: elements.map { ($0, $0) })
    }

    mutating func join(_ left: HexCoordinate, _ right: HexCoordinate) -> Bool {
        let leftRoot = root(of: left)
        let rightRoot = root(of: right)
        guard leftRoot != rightRoot else { return false }
        parent[leftRoot] = rightRoot
        return true
    }

    mutating func component(of element: HexCoordinate) -> HexCoordinate {
        root(of: element)
    }

    private mutating func root(of element: HexCoordinate) -> HexCoordinate {
        guard let parentElement = parent[element], parentElement != element else {
            return element
        }
        let rootElement = root(of: parentElement)
        parent[element] = rootElement
        return rootElement
    }
}

private struct RoadConnectionNetwork {
    private struct RoadEdge: Hashable {
        let start: HexCoordinate
        let end: HexCoordinate
        let direction: Int
    }

    private struct LoopCandidate {
        let edge: RoadEdge
        let loopLength: Int
        let branchPenalty: Int
        let endpointDegreeSum: Int
    }

    let directionsByCoordinate: [HexCoordinate: [Int]]

    init(tiles: [TerrainTile]) {
        let roadCoordinates = Set(
            tiles
                .filter { $0.terrain == .road }
                .map(\.coordinate)
        )
        let sortedCoordinates = roadCoordinates.sorted { left, right in
            if left.q != right.q { return left.q < right.q }
            return left.r < right.r
        }
        let candidateEdges = Self.candidateEdges(in: roadCoordinates, sortedCoordinates: sortedCoordinates)
        let candidateDegrees = Self.candidateDegrees(for: candidateEdges)
        var directions = Dictionary(
            uniqueKeysWithValues: sortedCoordinates.map { ($0, [Int]()) }
        )
        var components = RoadDisjointSet(elements: sortedCoordinates)
        var selectedEdges = Set<RoadEdge>()

        // The spanning forest keeps every bridge and endpoint while canonical
        // directions enumerate each undirected road edge only once.
        for edge in candidateEdges where components.join(edge.start, edge.end) {
            selectedEdges.insert(edge)
        }

        // Measure each connected component from the complete canonical graph.
        // cycleRank is the number of independent edges left after a spanning
        // tree; the visual quota is deliberately capped at one per component.
        var verticesByComponent = [HexCoordinate: Set<HexCoordinate>]()
        for coordinate in sortedCoordinates {
            let component = components.component(of: coordinate)
            verticesByComponent[component, default: []].insert(coordinate)
        }

        var edgesByComponent = [HexCoordinate: [RoadEdge]]()
        for edge in candidateEdges {
            let component = components.component(of: edge.start)
            edgesByComponent[component, default: []].append(edge)
        }

        var treeNeighbors = [HexCoordinate: [HexCoordinate]]()
        let treeEdges = selectedEdges
        for edge in treeEdges {
            treeNeighbors[edge.start, default: []].append(edge.end)
            treeNeighbors[edge.end, default: []].append(edge.start)
        }
        treeNeighbors = treeNeighbors.mapValues { neighbors in
            neighbors.sorted(by: Self.coordinateSort)
        }

        for component in verticesByComponent.keys.sorted(by: Self.coordinateSort) {
            let vertexCount = verticesByComponent[component]?.count ?? 0
            let edgeCount = edgesByComponent[component]?.count ?? 0
            let cycleRank = max(0, edgeCount - vertexCount + 1)
            let backEdgeQuota = cycleRank > 0 ? 1 : 0
            guard backEdgeQuota > 0 else {
                continue
            }

            let nonTreeEdges = (edgesByComponent[component] ?? [])
                .filter { !treeEdges.contains($0) }
            let loopCandidates = nonTreeEdges
                .compactMap { edge -> LoopCandidate? in
                    guard let path = Self.treePath(
                        from: edge.start,
                        to: edge.end,
                        neighbors: treeNeighbors
                    ) else {
                        return nil
                    }

                    let internalNodes = path.dropFirst().dropLast()
                    let branchPenalty = internalNodes.reduce(into: 0) { result, node in
                        if candidateDegrees[node, default: 0] > 2 {
                            result += 1
                        }
                    }
                    let endpointDegreeSum = candidateDegrees[edge.start, default: 0]
                        + candidateDegrees[edge.end, default: 0]
                    return LoopCandidate(
                        edge: edge,
                        loopLength: path.count,
                        branchPenalty: branchPenalty,
                        endpointDegreeSum: endpointDegreeSum
                    )
                }

            if let selectedLoop = loopCandidates.min(by: Self.loopCandidateSort) {
                selectedEdges.insert(selectedLoop.edge)
            } else if let fallbackEdge = nonTreeEdges.min(by: Self.edgeSort) {
                // A connected tree should always yield a path. Keep the
                // quota invariant even if a future helper change cannot find
                // one by falling back to the stable canonical edge order.
                selectedEdges.insert(fallbackEdge)
            }
        }

        // Project the selected canonical edges to paired half-paths at both
        // endpoints. Sorting makes the resulting direction arrays stable even
        // though the selected edge set has no iteration order.
        for edge in selectedEdges.sorted(by: Self.edgeSort) {
            directions[edge.start, default: []].append(edge.direction)
            directions[edge.end, default: []].append((edge.direction + 3) % 6)
        }

        directionsByCoordinate = directions.mapValues { $0.sorted() }
    }

    private static func candidateEdges(
        in roadCoordinates: Set<HexCoordinate>,
        sortedCoordinates: [HexCoordinate]
    ) -> [RoadEdge] {
        sortedCoordinates.flatMap { coordinate in
            coordinate.neighbors.enumerated().prefix(3).compactMap { direction, neighbor in
                guard roadCoordinates.contains(neighbor) else { return nil }
                return RoadEdge(start: coordinate, end: neighbor, direction: direction)
            }
        }
    }

    private static func candidateDegrees(for edges: [RoadEdge]) -> [HexCoordinate: Int] {
        var degrees = [HexCoordinate: Int]()
        for edge in edges {
            degrees[edge.start, default: 0] += 1
            degrees[edge.end, default: 0] += 1
        }
        return degrees
    }

    private static func coordinateSort(_ left: HexCoordinate, _ right: HexCoordinate) -> Bool {
        if left.q != right.q { return left.q < right.q }
        return left.r < right.r
    }

    private static func treePath(
        from start: HexCoordinate,
        to end: HexCoordinate,
        neighbors: [HexCoordinate: [HexCoordinate]]
    ) -> [HexCoordinate]? {
        guard start != end else { return [start] }

        var queue = [start]
        var visited: Set<HexCoordinate> = [start]
        var parent = [HexCoordinate: HexCoordinate]()
        var index = 0

        while index < queue.count {
            let current = queue[index]
            index += 1
            if current == end { break }

            for neighbor in neighbors[current, default: []] {
                guard visited.insert(neighbor).inserted else { continue }
                parent[neighbor] = current
                queue.append(neighbor)
            }
        }

        guard visited.contains(end) else { return nil }

        var path = [end]
        var current = end
        while let previous = parent[current] {
            path.append(previous)
            current = previous
        }
        return current == start ? Array(path.reversed()) : nil
    }

    private static func loopCandidateSort(_ left: LoopCandidate, _ right: LoopCandidate) -> Bool {
        // Prefer a longer, more traceable loop before considering endpoint
        // degree. The remaining fields make ties independent of Set order.
        if left.loopLength != right.loopLength { return left.loopLength > right.loopLength }
        if left.branchPenalty != right.branchPenalty { return left.branchPenalty < right.branchPenalty }
        if left.endpointDegreeSum != right.endpointDegreeSum {
            return left.endpointDegreeSum < right.endpointDegreeSum
        }
        return edgeSort(left.edge, right.edge)
    }

    private static func edgeSort(_ left: RoadEdge, _ right: RoadEdge) -> Bool {
        if left.start.q != right.start.q { return left.start.q < right.start.q }
        if left.start.r != right.start.r { return left.start.r < right.start.r }
        if left.direction != right.direction { return left.direction < right.direction }
        if left.end.q != right.end.q { return left.end.q < right.end.q }
        return left.end.r < right.end.r
    }
}

struct HexMapView: View {
    @EnvironmentObject private var game: GameState
    let scaleMultiplier: CGFloat
    let viewportHeight: CGFloat

    private let tileWidth: CGFloat = 86
    private let tileHeight: CGFloat = 74

    var body: some View {
        let selected = game.selectedUnit
        let supplyLine = selected.map { game.supplyLineTiles(for: $0) } ?? []
        let enemyControlZones = selected.map { game.enemyControlZoneTiles(for: $0.faction) } ?? []
        let threatenedReachableTiles = selected.map { game.threatenedReachableTiles(for: $0) } ?? []
        let attackCoverage = selected.map { game.attackCoverageTiles(for: $0) } ?? []
        let postMoveAttackTargets = Set(game.focusedPostMoveAttackOpportunities.map(\.position))
        let attackPositions = Set(game.focusedAttackPositionRoutes.map(\.destination))
        let focusedRoute = game.focusedMovementRoute ?? game.focusedAttackPositionRoute
        let focusedRouteCoordinates = Set(focusedRoute?.coordinates ?? [])
        let focusedRouteSteps = Dictionary(uniqueKeysWithValues: game.focusedRouteStepPreviews.map { ($0.coordinate, $0) })
        let focusedFireExposure = game.focusedFireExposurePreview
        let guidedObjectiveCoordinate = game.guidedObjectiveCoordinate
        let latestCaptureCoordinate = game.latestObjectiveCaptureResult?.coordinate
        let enemyIntentTargets = Set(game.visibleEnemyThreatIntentPreviews.map(\.targetCoordinate))
        let countermeasureMarkersByCoordinate = Dictionary(
            grouping: game.focusedEnemyThreatCountermeasureMapMarkers,
            by: \.coordinate
        )
        let objectivePressureMarkersByCoordinate = Dictionary(
            grouping: game.focusedBattlefieldSituationObjectivePressureMapMarkers,
            by: \.coordinate
        )
        let aiPhaseMarkersByCoordinate = Dictionary(
            grouping: game.latestAIPhaseMapMarkers,
            by: \.coordinate
        )
        let focusedAIPhaseMarkersByCoordinate = Dictionary(
            grouping: game.focusedAIPhaseMapMarkers,
            by: \.coordinate
        )
        let battlefieldSituationResponseMarker = game.battlefieldSituationResponseMapMarker
        let terrainByCoordinate = Dictionary(uniqueKeysWithValues: game.tiles.map { ($0.coordinate, $0.terrain) })
        let roadConnectionDirectionsByCoordinate = RoadConnectionNetwork(tiles: game.tiles).directionsByCoordinate
        let contentWidth = CGFloat(game.scenario.mapColumns) * tileWidth * 0.78 + tileWidth
        let contentHeight = CGFloat(game.scenario.mapRows) * tileHeight * 0.78 + tileHeight
        let fillScale = max(0.86, (viewportHeight - 16) / contentHeight)
        let resolvedScale = fillScale * scaleMultiplier
        let mapTiles: [TerrainTile] = Array(game.tiles)

        ZStack(alignment: .topLeading) {
            MapGridBackdrop(width: contentWidth, height: contentHeight)

            ForEach(mapTiles, id: \.coordinate.id) { tile in
                let point = position(for: tile.coordinate)
                let unit = game.unit(at: tile.coordinate)
                let tileIsSelected = selected?.position == tile.coordinate
                let tileIsFocused = game.focusedCoordinate == tile.coordinate
                let boundaryAdjacency = HexBoundaryAdjacency(
                    tile: tile,
                    terrainByCoordinate: terrainByCoordinate
                )
                let terrainConnectionDirections: [Int] = tile.terrain == .road
                    ? roadConnectionDirectionsByCoordinate[tile.coordinate] ?? []
                    : tile.coordinate.neighbors.enumerated().compactMap { index, coordinate in
                        terrainByCoordinate[coordinate] == tile.terrain ? index : nil
                    }
                let supplyLineConnectionDirections = supplyLine.contains(tile.coordinate)
                    ? tile.coordinate.neighbors.enumerated().compactMap { index, coordinate in
                        supplyLine.contains(coordinate) ? index : nil
                    }
                    : []
                HexTileView(
                    tile: tile,
                    sharedTerrainBoundaryDirections: boundaryAdjacency.sharedTerrainDirections,
                    terrainTransitionBoundaryDirections: boundaryAdjacency.terrainTransitionDirections,
                    mapEdgeBoundaryDirections: boundaryAdjacency.mapEdgeDirections,
                    terrainConnectionDirections: terrainConnectionDirections,
                    supplyLineConnectionDirections: supplyLineConnectionDirections,
                    unit: unit,
                    isSelected: tileIsSelected,
                    isFocused: tileIsFocused,
                    isAttackFocusMode: isAttackFocusMode,
                    actionHint: game.mapActionHint(for: tile.coordinate),
                    isMovementRoute: focusedRouteCoordinates.contains(tile.coordinate),
                    isRouteDestination: focusedRoute?.destination == tile.coordinate,
                    routeStepPreview: focusedRouteSteps[tile.coordinate],
                    isSupplyLine: supplyLine.contains(tile.coordinate),
                    isAttackCoverage: attackCoverage.contains(tile.coordinate),
                    isPostMoveAttackTarget: postMoveAttackTargets.contains(tile.coordinate),
                    isAttackPosition: attackPositions.contains(tile.coordinate),
                    isEnemyControlZone: enemyControlZones.contains(tile.coordinate),
                    isThreatenedMoveTile: threatenedReachableTiles.contains(tile.coordinate),
                    fireExposurePreview: focusedFireExposure?.coordinate == tile.coordinate ? focusedFireExposure : nil,
                    isGuidedObjective: guidedObjectiveCoordinate == tile.coordinate,
                    isLatestObjectiveCapture: latestCaptureCoordinate == tile.coordinate,
                    isEnemyThreatIntentTarget: enemyIntentTargets.contains(tile.coordinate),
                    enemyThreatCountermeasureMarkers: countermeasureMarkersByCoordinate[tile.coordinate] ?? [],
                    objectivePressureMarkers: objectivePressureMarkersByCoordinate[tile.coordinate] ?? [],
                    aiPhaseMapMarkers: aiPhaseMarkersByCoordinate[tile.coordinate] ?? [],
                    focusedAIPhaseMapMarkers: focusedAIPhaseMarkersByCoordinate[tile.coordinate] ?? [],
                    battlefieldSituationResponseMarker: battlefieldSituationResponseMarker?.coordinate == tile.coordinate ? battlefieldSituationResponseMarker : nil
                )
                .frame(width: tileWidth, height: tileHeight)
                .position(x: point.x, y: point.y)
                .id(tile.coordinate.id)
                .overlay(
                    HexInputReader(
                        hitShape: Hexagon().path(in: CGRect(origin: .zero, size: CGSize(width: tileWidth, height: tileHeight))),
                        directTouchAction: {
                            game.handleTap(on: tile.coordinate)
                        },
                        primaryAction: {
                            game.handlePrimaryAction(on: tile.coordinate)
                        },
                        secondaryAction: {
                            game.handleSecondaryAction(on: tile.coordinate)
                        }
                    )
                )
                .zIndex(
                    tilePresentationLayer(
                        hasUnit: unit != nil,
                        isSelected: tileIsSelected,
                        isFocused: tileIsFocused
                    )
                )
            }

            if isAttackFocusMode,
               let attackerCoordinate = selected?.position,
               let targetCoordinate = game.focusedCoordinate {
                EngagementAxisOverlay(
                    start: position(for: attackerCoordinate),
                    end: position(for: targetCoordinate)
                )
                .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .zIndex(10)
            }

            if let combatResult = game.latestCombatResult {
                CombatResolutionOverlay(
                    summary: combatResult,
                    attackerPoint: position(for: combatResult.attackerCoordinate),
                    defenderPoint: position(for: combatResult.defenderCoordinate)
                )
                .id(combatResult.id)
                .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
                .allowsHitTesting(false)
                .zIndex(20)
            }
        }
        .frame(width: contentWidth, height: contentHeight)
        .scaleEffect(resolvedScale, anchor: .topLeading)
        .frame(
            width: contentWidth * resolvedScale,
            height: contentHeight * resolvedScale,
            alignment: .topLeading
        )
    }

    private func position(for coordinate: HexCoordinate) -> CGPoint {
        let x = CGFloat(coordinate.q) * tileWidth * 0.78 + CGFloat(coordinate.r) * tileWidth * 0.39 + tileWidth / 2
        let y = CGFloat(coordinate.r) * tileHeight * 0.76 + tileHeight / 2
        return CGPoint(x: x, y: y)
    }

    private func tilePresentationLayer(
        hasUnit: Bool,
        isSelected: Bool,
        isFocused: Bool
    ) -> Double {
        if isSelected { return 3 }
        if hasUnit && isFocused { return 2.5 }
        if hasUnit { return 2 }
        if isFocused { return 1 }
        return 0
    }

    private var isAttackFocusMode: Bool {
        guard let preview = game.focusedCommandPreview else { return false }
        if case .attack = preview { return true }
        return false
    }
}

private struct HexBoundaryAdjacency {
    let sharedTerrainDirections: [Int]
    let terrainTransitionDirections: [Int]
    let mapEdgeDirections: [Int]

    init(tile: TerrainTile, terrainByCoordinate: [HexCoordinate: TerrainKind]) {
        var sharedTerrainDirections = [Int]()
        var terrainTransitionDirections = [Int]()
        var mapEdgeDirections = [Int]()

        for (direction, coordinate) in tile.coordinate.neighbors.enumerated() {
            guard let neighboringTerrain = terrainByCoordinate[coordinate] else {
                mapEdgeDirections.append(direction)
                continue
            }

            if neighboringTerrain == tile.terrain {
                sharedTerrainDirections.append(direction)
            } else {
                terrainTransitionDirections.append(direction)
            }
        }

        self.sharedTerrainDirections = sharedTerrainDirections
        self.terrainTransitionDirections = terrainTransitionDirections
        self.mapEdgeDirections = mapEdgeDirections
    }
}

struct MapGridBackdrop: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            BattlefieldTheme.mapParchmentLight,
                            BattlefieldTheme.mapParchmentSoil,
                            BattlefieldTheme.mapParchmentShade
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Path { path in
                path.move(to: CGPoint(x: -width * 0.08, y: height * 0.24))
                path.addCurve(
                    to: CGPoint(x: width * 1.08, y: height * 0.43),
                    control1: CGPoint(x: width * 0.25, y: height * 0.06),
                    control2: CGPoint(x: width * 0.72, y: height * 0.66)
                )
                path.addLine(to: CGPoint(x: width * 1.08, y: height * 0.70))
                path.addCurve(
                    to: CGPoint(x: -width * 0.08, y: height * 0.52),
                    control1: CGPoint(x: width * 0.68, y: height * 0.90),
                    control2: CGPoint(x: width * 0.20, y: height * 0.30)
                )
                path.closeSubpath()
            }
            .fill(BattlefieldTheme.mapParchmentWash)

            Path { path in
                path.move(to: CGPoint(x: width * 0.08, y: -height * 0.04))
                path.addCurve(
                    to: CGPoint(x: width * 0.96, y: height * 1.04),
                    control1: CGPoint(x: width * 0.34, y: height * 0.31),
                    control2: CGPoint(x: width * 0.70, y: height * 0.76)
                )
            }
            .stroke(BattlefieldTheme.mapParchmentLight.opacity(0.12), lineWidth: max(width, height) * 0.045)

            LinearGradient(
                colors: [
                    BattlefieldTheme.mapParchmentEdge,
                    Color.black.opacity(0.0),
                    BattlefieldTheme.mapParchmentEdge.opacity(0.78)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum HexTileTopOverlayChip: String, Identifiable {
    case countermeasure
    case objectivePressure
    case situationResponse
    case enemyThreatIntent
    case fireRisk
    case latestCapture
    case guidedObjective

    var id: String { rawValue }

    /// Lower sortOrder is shown first in the top stack (higher visual priority).
    var sortOrder: Int {
        switch self {
        case .countermeasure: return 0
        case .objectivePressure: return 1
        case .situationResponse: return 2
        case .enemyThreatIntent: return 3
        case .fireRisk: return 4
        case .latestCapture: return 5
        case .guidedObjective: return 6
        }
    }
}

enum HexTileBottomOverlayChip: String, Identifiable {
    case aiPhase
    case attackPosition

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .aiPhase: return 0
        case .attackPosition: return 1
        }
    }
}

struct HexTileOverflowChip: View {
    let count: Int

    var body: some View {
        Text("+\(count)")
            .font(.system(size: 7, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.62), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct HexTileView: View {
    let tile: TerrainTile
    let sharedTerrainBoundaryDirections: [Int]
    let terrainTransitionBoundaryDirections: [Int]
    let mapEdgeBoundaryDirections: [Int]
    let terrainConnectionDirections: [Int]
    let supplyLineConnectionDirections: [Int]
    let unit: BattleUnit?
    let isSelected: Bool
    let isFocused: Bool
    let isAttackFocusMode: Bool
    let actionHint: MapActionHint
    let isMovementRoute: Bool
    let isRouteDestination: Bool
    let routeStepPreview: RouteStepPreview?
    let isSupplyLine: Bool
    let isAttackCoverage: Bool
    let isPostMoveAttackTarget: Bool
    let isAttackPosition: Bool
    let isEnemyControlZone: Bool
    let isThreatenedMoveTile: Bool
    let fireExposurePreview: PostMoveFireExposurePreview?
    let isGuidedObjective: Bool
    let isLatestObjectiveCapture: Bool
    let isEnemyThreatIntentTarget: Bool
    let enemyThreatCountermeasureMarkers: [EnemyThreatCountermeasureMapMarker]
    let objectivePressureMarkers: [BattlefieldSituationObjectivePressureMapMarker]
    let aiPhaseMapMarkers: [AIPhaseMapMarker]
    let focusedAIPhaseMapMarkers: [AIPhaseMapMarker]
    let battlefieldSituationResponseMarker: BattlefieldSituationResponseMapMarker?

    var body: some View {
        ZStack {
            Hexagon()
                .fill(tile.terrain.mapGradient)
                .overlay(
                    Hexagon()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BattlefieldTheme.mapTileHighlight,
                                    Color.clear,
                                    BattlefieldTheme.mapTileShade
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    HexEtchedBoundaryLayer(
                        sharedTerrainDirections: sharedTerrainBoundaryDirections,
                        terrainTransitionDirections: terrainTransitionBoundaryDirections,
                        mapEdgeDirections: mapEdgeBoundaryDirections
                    )
                )
                .overlay(
                    Hexagon()
                        .stroke(borderColor, lineWidth: borderWidth)
                )

            if let owner = tile.owner {
                Hexagon()
                    .fill(owner.accentColor.opacity(tile.isObjective ? 0.10 : 0.035))
                    .overlay(
                        Hexagon()
                            .stroke(owner.accentColor.opacity(tile.isObjective ? 0.38 : 0.10), lineWidth: 0.8)
                    )
            }

            // GoG3-style soft range tinting: threatened / control-zone tiles
            // read as a translucent wash instead of hard red outlines.
            if !isAttackFocusMode {
                if isThreatenedMoveTile {
                    Hexagon().fill(Color.red.opacity(0.10))
                } else if isEnemyControlZone {
                    Hexagon().fill(Color.red.opacity(0.06))
                }
                if actionHint.isMove {
                    Hexagon().fill(Color.cyan.opacity(0.10))
                }
            }

            TerrainTexture(tile: tile, connectionDirections: terrainConnectionDirections)

            if isSupplyLine && !isAttackFocusMode {
                SupplyLineMarker(connectionDirections: supplyLineConnectionDirections)
            }

            if isMovementRoute && !isAttackFocusMode {
                MovementRouteMarker(step: routeStepPreview, isDestination: isRouteDestination)
            }

            // Unified top stack: focus / situation chips with overflow collapse.
            if !isAttackFocusMode && (!visibleTopOverlayChips.isEmpty || topOverlayOverflowCount > 0) {
                VStack(spacing: 2) {
                    ForEach(visibleTopOverlayChips) { chip in
                        topOverlayChipView(chip)
                    }
                    if topOverlayOverflowCount > 0 {
                        HexTileOverflowChip(count: topOverlayOverflowCount)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 4)
                .padding(.horizontal, 4)
            }

            // Unified bottom stack: AI replay / attack position with overflow collapse.
            if !isAttackFocusMode && (!visibleBottomOverlayChips.isEmpty || bottomOverlayOverflowCount > 0) {
                VStack(spacing: 2) {
                    if bottomOverlayOverflowCount > 0 {
                        HexTileOverflowChip(count: bottomOverlayOverflowCount)
                    }
                    ForEach(visibleBottomOverlayChips) { chip in
                        bottomOverlayChipView(chip)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 5)
                .padding(.horizontal, 4)
            }

            // Attack coverage reads from the soft orange border alone; the
            // per-tile scope chip repeated the same signal on every enemy hex.

            if isPostMoveAttackTarget && !isAttackFocusMode {
                PostMoveAttackMarker()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }

            // Threatened / control-zone tiles rely on the red hex wash alone —
            // per-tile "!" and triangle chips doubled the same signal.

            if shouldShowActionMarker {
                ActionMarker(actionHint: actionHint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 5)
                    .padding(.trailing, 8)
            }

            if shouldShowUnavailableTargetMarker {
                UnavailableTargetMarker(actionHint: actionHint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 5)
                    .padding(.trailing, 8)
            }

            if isSelected && unit != nil {
                SelectedUnitGroundHalo()
                    .frame(width: 58, height: 24)
                    .offset(y: 13)
            }

            VStack(spacing: 3) {
                HStack(alignment: .top, spacing: 3) {
                    if tile.isObjective {
                        ObjectiveFlagMarker(owner: tile.owner)
                        if let objectiveName = tile.objectiveName, unit != nil {
                            ObjectiveNamePlate(
                                name: objectiveName,
                                owner: tile.owner,
                                compact: true
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 1)
                        }
                    } else if isFocused && unit == nil {
                        TerrainCodeBadge(code: tile.terrain.code)
                    }
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                if let unit {
                    UnitCounter(unit: unit)
                        .offset(y: isSelected ? -3 : 0)
                        .shadow(
                            color: isSelected ? BattlefieldTheme.selectedPiece.opacity(0.34) : .clear,
                            radius: isSelected ? 4 : 0,
                            y: isSelected ? 4 : 0
                        )
                } else if let objectiveName = tile.objectiveName {
                    ObjectiveNamePlate(name: objectiveName, owner: tile.owner)
                } else {
                    Spacer(minLength: 32)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            if let reticleColor {
                TacticalCornerReticle(color: reticleColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Hexagon())
        .accessibilityLabel(accessibilityLabel)
    }

    private var borderColor: Color {
        if isAttackFocusMode {
            if isSelected { return BattlefieldTheme.selectedPiece }
            if isFocused && actionHint.isAttack { return .red }
            if tile.isObjective { return (tile.owner?.accentColor ?? .yellow).opacity(0.72) }
            return .clear
        }
        if isSelected { return BattlefieldTheme.selectedPiece }
        if actionHint.isAttack { return .red }
        if actionHint.isApproachAttack { return .orange.opacity(0.92) }
        if actionHint.isMove { return .cyan }
        if isPostMoveAttackTarget { return .orange.opacity(0.9) }
        if isAttackPosition { return .orange.opacity(0.78) }
        if let fireExposurePreview { return fireExposurePreview.riskLevel.accentColor.opacity(0.95) }
        if isLatestObjectiveCapture { return .yellow.opacity(0.96) }
        if isGuidedObjective { return .green.opacity(0.96) }
        if !enemyThreatCountermeasureMarkers.isEmpty { return .mint.opacity(0.96) }
        if !objectivePressureMarkers.isEmpty { return .pink.opacity(0.96) }
        if !focusedAIPhaseMapMarkers.isEmpty { return .white.opacity(0.96) }
        if let battlefieldSituationResponseMarker { return battlefieldSituationResponseColor(for: battlefieldSituationResponseMarker.kind).opacity(0.96) }
        if isEnemyThreatIntentTarget { return .pink.opacity(0.92) }
        if isMovementRoute { return .cyan.opacity(0.88) }
        if isAttackCoverage { return .orange.opacity(0.40) }
        if isThreatenedMoveTile { return .red.opacity(0.34) }
        if isEnemyControlZone { return .red.opacity(0.26) }
        if isSupplyLine { return BattlefieldTheme.supplyLine.opacity(0.38) }
        if isFocused { return .white.opacity(0.9) }
        if tile.isObjective { return (tile.owner?.accentColor ?? .yellow).opacity(0.9) }
        if !aiPhaseMapMarkers.isEmpty { return .indigo.opacity(0.86) }
        return .clear
    }

    private var borderWidth: CGFloat {
        if isAttackFocusMode {
            if isSelected { return 1.5 }
            if isFocused && actionHint.isAttack { return 3 }
            if tile.isObjective { return 1.5 }
            return 0.45
        }
        if isSelected { return 1.5 }
        if actionHint.isAttack || actionHint.isApproachAttack || actionHint.isMove { return 3 }
        if isPostMoveAttackTarget { return 3 }
        if isAttackPosition { return 3 }
        if fireExposurePreview?.riskLevel.sortRank ?? 0 >= FireRiskLevel.high.sortRank { return 3 }
        if isLatestObjectiveCapture { return 3 }
        if isGuidedObjective { return 3 }
        if !enemyThreatCountermeasureMarkers.isEmpty { return 3 }
        if !objectivePressureMarkers.isEmpty { return 3 }
        if !focusedAIPhaseMapMarkers.isEmpty { return 3 }
        if battlefieldSituationResponseMarker != nil { return 3 }
        if isEnemyThreatIntentTarget { return 2 }
        if isMovementRoute { return 2 }
        if isAttackCoverage { return 1 }
        if isThreatenedMoveTile { return 1 }
        if isEnemyControlZone { return 1 }
        if isSupplyLine { return 0.75 }
        if isFocused { return 2 }
        if tile.isObjective { return 2 }
        if !aiPhaseMapMarkers.isEmpty { return 2 }
        return 0.45
    }

    private var reticleColor: Color? {
        if isSelected { return BattlefieldTheme.selectedPiece }
        guard isFocused else { return nil }
        if actionHint.isAttack { return .red }
        if actionHint.isApproachAttack { return .orange }
        return nil
    }

    private var shouldShowActionMarker: Bool {
        guard actionHint.isCommandable else { return false }
        return !isAttackFocusMode || (isFocused && actionHint.isAttack)
    }

    private var shouldShowUnavailableTargetMarker: Bool {
        if isAttackFocusMode { return false }
        // Only explain out-of-range/unavailable on the tile the player is
        // actually inspecting — ambient "7>1" chips on every enemy read as
        // noise (GoG3 keeps the field clean until you ask).
        guard isFocused else { return false }
        switch actionHint {
        case .enemyOutOfRange, .enemyUnavailable:
            return true
        case .none, .selectedUnit, .selectableUnit, .move, .attack, .approachAttack, .friendlyOccupied:
            return false
        }
    }

    private static let maxStackChips = 2

    private var topOverlayChips: [HexTileTopOverlayChip] {
        var chips: [HexTileTopOverlayChip] = []
        if !enemyThreatCountermeasureMarkers.isEmpty {
            chips.append(.countermeasure)
        }
        if !objectivePressureMarkers.isEmpty {
            chips.append(.objectivePressure)
        }
        if battlefieldSituationResponseMarker != nil {
            chips.append(.situationResponse)
        }
        if isEnemyThreatIntentTarget {
            chips.append(.enemyThreatIntent)
        }
        if fireExposurePreview != nil {
            chips.append(.fireRisk)
        }
        if isLatestObjectiveCapture {
            chips.append(.latestCapture)
        }
        if isGuidedObjective {
            chips.append(.guidedObjective)
        }
        return chips.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleTopOverlayChips: [HexTileTopOverlayChip] {
        Array(topOverlayChips.prefix(Self.maxStackChips))
    }

    private var topOverlayOverflowCount: Int {
        max(0, topOverlayChips.count - Self.maxStackChips)
    }

    private var bottomOverlayChips: [HexTileBottomOverlayChip] {
        var chips: [HexTileBottomOverlayChip] = []
        if !aiPhaseMapMarkers.isEmpty {
            chips.append(.aiPhase)
        }
        if isAttackPosition {
            chips.append(.attackPosition)
        }
        return chips.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleBottomOverlayChips: [HexTileBottomOverlayChip] {
        Array(bottomOverlayChips.prefix(Self.maxStackChips))
    }

    private var bottomOverlayOverflowCount: Int {
        max(0, bottomOverlayChips.count - Self.maxStackChips)
    }

    @ViewBuilder
    private func topOverlayChipView(_ chip: HexTileTopOverlayChip) -> some View {
        switch chip {
        case .countermeasure:
            EnemyThreatCountermeasureFocusMarker(markers: enemyThreatCountermeasureMarkers)
        case .objectivePressure:
            BattlefieldSituationObjectivePressureMapMarkerView(markers: objectivePressureMarkers)
        case .situationResponse:
            if let battlefieldSituationResponseMarker {
                BattlefieldSituationResponseMapMarkerView(marker: battlefieldSituationResponseMarker)
            }
        case .enemyThreatIntent:
            EnemyThreatIntentMarker()
        case .fireRisk:
            if let fireExposurePreview {
                FireRiskMarker(preview: fireExposurePreview)
            }
        case .latestCapture:
            ObjectiveCaptureMarker()
        case .guidedObjective:
            GuidedObjectiveMarker()
        }
    }

    @ViewBuilder
    private func bottomOverlayChipView(_ chip: HexTileBottomOverlayChip) -> some View {
        switch chip {
        case .aiPhase:
            AIPhaseMapReplayMarker(
                markers: focusedAIPhaseMapMarkers.isEmpty ? aiPhaseMapMarkers : focusedAIPhaseMapMarkers,
                isFocused: !focusedAIPhaseMapMarkers.isEmpty
            )
        case .attackPosition:
            AttackPositionMarker()
        }
    }

    private var accessibilityLabel: String {
        let unitText = unit.map { "\($0.faction.title)\($0.kind.title)\($0.name)" } ?? "空地"
        let objectiveText = tile.objectiveName.map { "据点\($0)" } ?? ""
        let controlZoneText = isEnemyControlZone ? "敌方控制区" : ""
        let threatText = isThreatenedMoveTile ? "敌方火力覆盖" : ""
        let attackCoverageText = isAttackCoverage ? "射程覆盖" : ""
        let postMoveAttackText = isPostMoveAttackTarget ? "移动后可攻击" : ""
        let attackPositionText = isAttackPosition ? "可进入攻击位" : ""
        let guidedObjectiveText = isGuidedObjective ? "当前目标据点" : ""
        let latestCaptureText = isLatestObjectiveCapture ? "最新占领据点" : ""
        let enemyThreatIntentText = isEnemyThreatIntentTarget ? "敌方意图目标" : ""
        let countermeasureText = enemyThreatCountermeasureMarkers.isEmpty
            ? ""
            : enemyThreatCountermeasureMarkers
                .sorted { $0.role.sortOrder < $1.role.sortOrder }
                .map(\.role.title)
                .joined(separator: "，")
        let battlefieldSituationResponseText = battlefieldSituationResponseMarker.map {
            "态势响应，\($0.shortTitle)，\($0.summary)"
        } ?? ""
        let objectivePressureText = objectivePressureMarkers.isEmpty
            ? ""
            : objectivePressureMarkers
                .sorted { $0.role.sortOrder < $1.role.sortOrder }
                .map { "据点压力，\($0.summary)" }
                .joined(separator: "，")
        let aiPhaseMapText = aiPhaseMapAccessibilityText
        let fireRiskText = fireExposurePreview.map { preview in
            let sourceText = preview.sources.prefix(2).map(\.sourceName).joined(separator: "、")
            let sourceSummary = sourceText.isEmpty ? "无敌火来源" : "来源\(sourceText)"
            return "\(preview.riskLevel.title)，潜在伤害\(preview.totalPotentialDamage)，预计剩余\(preview.projectedHPAfterExposure)，\(sourceSummary)"
        } ?? ""
        return "\(tile.terrain.title) \(objectiveText) \(controlZoneText) \(threatText) \(routeAccessibilityText) \(attackCoverageText) \(postMoveAttackText) \(attackPositionText) \(guidedObjectiveText) \(latestCaptureText) \(enemyThreatIntentText) \(countermeasureText) \(objectivePressureText) \(battlefieldSituationResponseText) \(aiPhaseMapText) \(fireRiskText) \(unitText) \(actionAccessibilityText)"
    }

    private func battlefieldSituationResponseColor(
        for kind: BattlefieldSituationResponseKind
    ) -> Color {
        switch kind {
        case .countermeasureFollowUp:
            return Color.blue
        case .countermeasure:
            return Color.mint
        case .objectiveCapture:
            return Color.yellow
        case .combat:
            return Color.orange
        case .tacticalCommand:
            return Color.purple
        case .deployment:
            return Color.green
        case .reinforcement:
            return Color.cyan
        }
    }

    private var aiPhaseMapAccessibilityText: String {
        guard !aiPhaseMapMarkers.isEmpty else { return "" }
        let markers = aiPhaseMapMarkers.sorted { left, right in
            let leftFocused = focusedAIPhaseMapMarkers.contains { $0.id == left.id }
            let rightFocused = focusedAIPhaseMapMarkers.contains { $0.id == right.id }
            if leftFocused != rightFocused {
                return leftFocused
            }
            if left.eventOrder != right.eventOrder {
                return left.eventOrder < right.eventOrder
            }
            return left.role.sortOrder < right.role.sortOrder
        }
        let visibleText = markers.prefix(2).map { marker in
            let focusedText = focusedAIPhaseMapMarkers.contains { $0.id == marker.id } ? "当前" : ""
            return "\(focusedText)AI复盘第\(marker.eventOrder)步，\(marker.eventKind.title)，\(marker.role.title)，\(marker.summary)"
        }.joined(separator: "；")
        let hiddenCount = markers.count - min(markers.count, 2)
        let hiddenText = hiddenCount > 0 ? "；另有\(hiddenCount)条AI复盘标记" : ""
        return "\(visibleText)\(hiddenText)"
    }

    private var routeAccessibilityText: String {
        guard let routeStepPreview else { return "" }
        let destinationText = routeStepPreview.isDestination ? "，终点" : ""
        let controlZoneText = routeStepPreview.controlZonePenalty > 0 ? "，控制区+\(routeStepPreview.controlZonePenalty)" : ""
        let threatText = routeStepPreview.threatCount > 0 ? "，受\(routeStepPreview.threatNames.joined(separator: "、"))火力威胁" : ""
        return "路线第\(routeStepPreview.stepIndex)步，消耗\(routeStepPreview.movementCost)\(controlZoneText)\(threatText)\(destinationText)"
    }

    private var actionAccessibilityText: String {
        switch actionHint {
        case .none:
            return ""
        case .selectedUnit:
            return "当前选中"
        case .selectableUnit:
            return "可左键选择"
        case let .move(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "可右键移动，消耗\(cost)，含敌方控制区+\(controlZonePenalty)" : "可右键移动，消耗\(cost)"
        case let .attack(damage, counterDamage, willDestroy):
            let destroyText = willDestroy ? "，预计击毁" : ""
            return "可右键攻击，伤害\(damage)，反击\(counterDamage)\(destroyText)"
        case let .approachAttack(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "可右键接敌移动，消耗\(cost)，含敌方控制区+\(controlZonePenalty)" : "可右键接敌移动，消耗\(cost)"
        case .friendlyOccupied:
            return "友军占据"
        case let .enemyOutOfRange(distance, range):
            return "敌军距离\(distance)，超过射程\(range)"
        case .enemyUnavailable:
            return "敌军当前不可攻击"
        }
    }
}

struct SelectedUnitGroundHalo: View {
    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.34),
                        BattlefieldTheme.selectedPiece.opacity(0.26),
                        BattlefieldTheme.selectedPiece.opacity(0.08)
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: 26
                )
            )
            .overlay {
                Ellipse()
                    .stroke(Color.black.opacity(0.52), lineWidth: 3)
            }
            .overlay {
                Ellipse()
                    .stroke(BattlefieldTheme.selectedPiece.opacity(0.94), lineWidth: 1.5)
            }
            .shadow(color: BattlefieldTheme.selectedPiece.opacity(0.58), radius: 5, y: 2)
            .accessibilityHidden(true)
    }
}

struct EngagementAxisOverlay: View {
    let start: CGPoint
    let end: CGPoint

    var body: some View {
        let angle = Angle(radians: Double(atan2(end.y - start.y, end.x - start.x)))
        let points = trimmedPoints

        ZStack {
            Path { path in
                path.move(to: points.start)
                path.addLine(to: points.end)
            }
            .stroke(Color.black.opacity(0.78), style: StrokeStyle(lineWidth: 5, lineCap: .round))

            Path { path in
                path.move(to: points.start)
                path.addLine(to: points.end)
            }
            .stroke(
                Color.orange.opacity(0.94),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [7, 4])
            )

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .padding(3)
                .background(Color.red.opacity(0.92), in: Circle())
                .rotationEffect(angle)
                .position(points.end)
        }
    }

    private var trimmedPoints: (start: CGPoint, end: CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = max(1, hypot(dx, dy))
        let inset = min(22, distance * 0.28)
        let unitX = dx / distance
        let unitY = dy / distance
        return (
            CGPoint(x: start.x + unitX * inset, y: start.y + unitY * inset),
            CGPoint(x: end.x - unitX * inset, y: end.y - unitY * inset)
        )
    }
}

struct CombatResolutionOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.combatResolutionSteadyState) private var isSteadyState
    @ScaledMetric(relativeTo: .caption) private var outcomeFontSize: CGFloat = 9

    let summary: CombatResultSummary
    let attackerPoint: CGPoint
    let defenderPoint: CGPoint

    @State private var phase: CombatResolutionPhase = .impact

    var body: some View {
        GeometryReader { proxy in
            let layout = CombatResolutionLayout(
                attackerPoint: attackerPoint,
                defenderPoint: defenderPoint,
                bounds: proxy.size
            )
            let conclusion = combatConclusion

            ZStack {
                Path { path in
                    path.move(to: layout.trimmedStart)
                    path.addLine(to: layout.trimmedEnd)
                }
                .stroke(Color.black.opacity(0.74), style: StrokeStyle(lineWidth: 5, lineCap: .round))

                Path { path in
                    path.move(to: layout.trimmedStart)
                    path.addLine(to: layout.trimmedEnd)
                }
                .stroke(
                    conclusion.color.opacity(activePhase == .impact ? 0.84 : 0.66),
                    style: StrokeStyle(
                        lineWidth: activePhase == .impact ? 2.8 : 2.1,
                        lineCap: .round,
                        dash: [5, 4]
                    )
                )

                CombatImpactMarker(
                    color: conclusion.color,
                    isImpactPhase: activePhase == .impact,
                    reduceMotion: reduceMotion || isSteadyState
                )
                .frame(width: 58, height: 58)
                .position(defenderPoint)

                CombatDamagePlate(
                    systemImage: "burst.fill",
                    title: "HIT -\(summary.damage)",
                    hpText: "\(summary.defender.startingHP) -> \(summary.defender.endingHP)",
                    color: summary.didDestroyDefender ? BattlefieldTheme.alert : BattlefieldTheme.brass
                )
                .position(layout.hitPlatePoint)
                .opacity(showsPrimaryDamage ? 1 : 0)
                .scaleEffect(plateScale(isVisible: showsPrimaryDamage))
                .offset(y: plateOffset(isVisible: showsPrimaryDamage))

                if summary.hasCounterAttack {
                    CombatDamagePlate(
                        systemImage: "arrow.uturn.backward.circle.fill",
                        title: "RET -\(summary.counterDamage)",
                        hpText: "\(summary.attacker.startingHP) -> \(summary.attacker.endingHP)",
                        color: summary.didDestroyAttacker ? BattlefieldTheme.alert : .orange
                    )
                    .position(layout.retPlatePoint)
                    .opacity(showsCounterDamage ? 1 : 0)
                    .scaleEffect(plateScale(isVisible: showsCounterDamage))
                    .offset(y: plateOffset(isVisible: showsCounterDamage))
                }

                CombatResolutionConclusionView(
                    title: conclusion.title,
                    systemImage: conclusion.systemImage,
                    qualifier: conclusion.qualifier,
                    qualifierSystemImage: conclusion.qualifierSystemImage,
                    color: conclusion.color,
                    fontSize: outcomeFontSize
                )
                .position(layout.conclusionPoint)
                .opacity(showsResolution ? 1 : 0)
                .scaleEffect(plateScale(isVisible: showsResolution))
                .offset(y: plateOffset(isVisible: showsResolution))
            }
        }
        .opacity(overlayOpacity)
        .animation(presentationAnimation, value: phase)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHidden(activePhase == .hidden)
        .task(id: summary.id) {
            await playPresentationSequence()
        }
    }

    private var activePhase: CombatResolutionPhase {
        isSteadyState ? .resolved : phase
    }

    private var showsPrimaryDamage: Bool {
        activePhase.rawValue >= CombatResolutionPhase.damage.rawValue
    }

    private var showsCounterDamage: Bool {
        activePhase.rawValue >= CombatResolutionPhase.counterDamage.rawValue
    }

    private var showsResolution: Bool {
        activePhase.rawValue >= CombatResolutionPhase.resolved.rawValue
    }

    private var overlayOpacity: Double {
        switch activePhase {
        case .dismissing, .hidden:
            return 0
        default:
            return 1
        }
    }

    private var presentationAnimation: Animation? {
        guard !isSteadyState else { return nil }
        if phase == .dismissing {
            return .easeOut(duration: 0.22)
        }
        return reduceMotion ? nil : .easeOut(duration: 0.11)
    }

    private func plateScale(isVisible: Bool) -> CGFloat {
        guard !reduceMotion && !isSteadyState else { return 1 }
        return isVisible ? 1 : 0.96
    }

    private func plateOffset(isVisible: Bool) -> CGFloat {
        guard !reduceMotion && !isSteadyState else { return 0 }
        return isVisible ? 0 : 4
    }

    @MainActor
    private func playPresentationSequence() async {
        if isSteadyState {
            phase = .resolved
            return
        }

        phase = reduceMotion ? .resolved : .impact
        do {
            if !reduceMotion {
                try await Task.sleep(for: .milliseconds(130))
                try Task.checkCancellation()
                phase = .damage

                if summary.hasCounterAttack {
                    try await Task.sleep(for: .milliseconds(90))
                    try Task.checkCancellation()
                    phase = .counterDamage
                }

                try await Task.sleep(for: .milliseconds(110))
                try Task.checkCancellation()
                phase = .resolved
            }

            try await Task.sleep(for: .milliseconds(2400))
            try Task.checkCancellation()
            phase = .dismissing

            try await Task.sleep(for: .milliseconds(220))
            try Task.checkCancellation()
            phase = .hidden
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private var combatConclusion: CombatResolutionConclusion {
        CombatResolutionConclusion(summary: summary)
    }

    private var accessibilitySummary: String {
        let conclusion = combatConclusion
        let qualifierText = conclusion.qualifier.map { "，\($0)" } ?? ""
        let counterText = summary.hasCounterAttack
            ? "，真实 RET -\(summary.counterDamage)，攻击方 HP 从 \(summary.attacker.startingHP) 降至 \(summary.attacker.endingHP)"
            : "，无反击（没有 RET）"
        let attackerDestroyedText = summary.didDestroyAttacker ? "，攻击方被反击击毁" : ""
        return "\(conclusion.title)\(qualifierText)。\(summary.attacker.name) 发起 HIT -\(summary.damage)，防守方 HP 从 \(summary.defender.startingHP) 降至 \(summary.defender.endingHP)\(counterText)\(attackerDestroyedText)。"
    }
}

private struct CombatResolutionConclusion {
    let title: String
    let systemImage: String
    let qualifier: String?
    let qualifierSystemImage: String?
    let color: Color

    init(summary: CombatResultSummary) {
        if summary.didDestroyDefender && summary.didDestroyAttacker {
            title = "双方击毁"
            systemImage = "burst.fill"
            qualifier = "反击击毁"
            qualifierSystemImage = "arrow.uturn.backward.circle.fill"
            color = BattlefieldTheme.alert
        } else if summary.didDestroyDefender {
            title = "击毁防守方"
            systemImage = "target"
            qualifier = nil
            qualifierSystemImage = nil
            color = BattlefieldTheme.alert
        } else if summary.didDestroyAttacker {
            title = "反击击毁"
            systemImage = "arrow.uturn.backward.circle.fill"
            qualifier = nil
            qualifierSystemImage = nil
            color = BattlefieldTheme.alert
        } else if summary.hasCounterAttack {
            title = "交火"
            systemImage = "arrow.left.arrow.right"
            qualifier = nil
            qualifierSystemImage = nil
            color = .orange
        } else {
            title = "压制"
            systemImage = "shield.lefthalf.filled"
            qualifier = "无反击"
            qualifierSystemImage = "shield.slash.fill"
            color = BattlefieldTheme.brass
        }
    }
}

private struct CombatResolutionConclusionView: View {
    let title: String
    let systemImage: String
    let qualifier: String?
    let qualifierSystemImage: String?
    let color: Color
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .black))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: fontSize, weight: .black, design: .rounded))

            if let qualifier, let qualifierSystemImage {
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 1, height: 11)

                Image(systemName: qualifierSystemImage)
                    .font(.system(size: max(7, fontSize - 1), weight: .bold))
                    .foregroundStyle(color.opacity(0.76))

                Text(qualifier)
                    .font(.system(size: max(7, fontSize - 1), weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))
            }
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .allowsTightening(true)
        .minimumScaleFactor(0.72)
        .frame(minWidth: 82, maxWidth: 198)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            BattlefieldTheme.commandDeckDeep.opacity(0.88),
            in: RoundedRectangle(cornerRadius: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(color.opacity(0.78), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct CombatResolutionLayout {
    let trimmedStart: CGPoint
    let trimmedEnd: CGPoint
    let hitPlatePoint: CGPoint
    let retPlatePoint: CGPoint
    let conclusionPoint: CGPoint

    init(attackerPoint: CGPoint, defenderPoint: CGPoint, bounds: CGSize) {
        let dx = defenderPoint.x - attackerPoint.x
        let dy = defenderPoint.y - attackerPoint.y
        let rawDistance = hypot(dx, dy)
        let unitX = rawDistance > 0.001 ? dx / rawDistance : 1
        let unitY = rawDistance > 0.001 ? dy / rawDistance : 0
        let midpoint = CGPoint(
            x: (attackerPoint.x + defenderPoint.x) / 2,
            y: (attackerPoint.y + defenderPoint.y) / 2
        )
        var normal = CGPoint(x: -unitY, y: unitX)
        let towardCenter = CGPoint(
            x: bounds.width / 2 - midpoint.x,
            y: bounds.height / 2 - midpoint.y
        )
        let shouldPointDown = bounds.height > 0 && midpoint.y < bounds.height * 0.24

        if shouldPointDown {
            if normal.y < 0 || (abs(normal.y) < 0.08 && normal.x * towardCenter.x < 0) {
                normal = CGPoint(x: -normal.x, y: -normal.y)
            }
        } else if normal.y > 0 || (abs(normal.y) < 0.08 && normal.x * towardCenter.x < 0) {
            normal = CGPoint(x: -normal.x, y: -normal.y)
        }

        let inset = min(25, rawDistance * 0.30)
        let closeEngagement = rawDistance < 132
        let outwardOffset: CGFloat = closeEngagement ? 28 : 22
        let plateNormalOffset: CGFloat = closeEngagement ? 30 : 24
        let conclusionNormalOffset: CGFloat = closeEngagement ? 70 : 54

        trimmedStart = CGPoint(
            x: attackerPoint.x + unitX * inset,
            y: attackerPoint.y + unitY * inset
        )
        trimmedEnd = CGPoint(
            x: defenderPoint.x - unitX * inset,
            y: defenderPoint.y - unitY * inset
        )
        hitPlatePoint = Self.offset(
            from: defenderPoint,
            axisX: unitX,
            axisY: unitY,
            axisDistance: outwardOffset,
            normal: normal,
            normalDistance: plateNormalOffset
        )
        retPlatePoint = Self.offset(
            from: attackerPoint,
            axisX: -unitX,
            axisY: -unitY,
            axisDistance: outwardOffset,
            normal: normal,
            normalDistance: plateNormalOffset
        )
        conclusionPoint = Self.offset(
            from: midpoint,
            axisX: 0,
            axisY: 0,
            axisDistance: 0,
            normal: normal,
            normalDistance: conclusionNormalOffset
        )
    }

    private static func offset(
        from point: CGPoint,
        axisX: CGFloat,
        axisY: CGFloat,
        axisDistance: CGFloat,
        normal: CGPoint,
        normalDistance: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: point.x + axisX * axisDistance + normal.x * normalDistance,
            y: point.y + axisY * axisDistance + normal.y * normalDistance
        )
    }
}

private enum CombatResolutionPhase: Int {
    case impact
    case damage
    case counterDamage
    case resolved
    case dismissing
    case hidden
}

private struct CombatImpactMarker: View {
    let color: Color
    let isImpactPhase: Bool
    let reduceMotion: Bool

    var body: some View {
        CombatImpactShape()
            .stroke(
                color.opacity(isImpactPhase ? 0.92 : 0.34),
                style: StrokeStyle(lineWidth: isImpactPhase ? 2.2 : 1.2, lineCap: .square)
            )
            .scaleEffect(reduceMotion ? 1 : (isImpactPhase ? 1.08 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isImpactPhase)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct CombatImpactShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let ringInset = min(rect.width, rect.height) * 0.20
        let innerRadius = min(rect.width, rect.height) * 0.32
        let outerRadius = min(rect.width, rect.height) * 0.47
        var path = Path()

        path.addEllipse(in: rect.insetBy(dx: ringInset, dy: ringInset))
        for angle in stride(from: 0.0, to: 360.0, by: 45.0) {
            let radians = angle * .pi / 180
            let directionX = CGFloat(cos(radians))
            let directionY = CGFloat(sin(radians))
            path.move(to: CGPoint(
                x: center.x + directionX * innerRadius,
                y: center.y + directionY * innerRadius
            ))
            path.addLine(to: CGPoint(
                x: center.x + directionX * outerRadius,
                y: center.y + directionY * outerRadius
            ))
        }
        return path
    }
}

struct CombatDamagePlate: View {
    @ScaledMetric(relativeTo: .caption) private var iconFontSize: CGFloat = 7
    @ScaledMetric(relativeTo: .caption) private var titleFontSize: CGFloat = 8
    @ScaledMetric(relativeTo: .caption) private var hpFontSize: CGFloat = 7

    let systemImage: String
    let title: String
    let hpText: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: iconFontSize, weight: .black))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: titleFontSize, weight: .black, design: .rounded))
                .allowsTightening(true)
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            Rectangle()
                .fill(Color.white.opacity(0.24))
                .frame(width: 1, height: 10)

            Text(hpText)
                .font(.system(size: hpFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .allowsTightening(true)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .frame(minWidth: 118, maxWidth: 184)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            LinearGradient(
                colors: [
                    BattlefieldTheme.fieldGlass.opacity(0.86),
                    BattlefieldTheme.commandDeckDeep.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.26), radius: 1.5, y: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct TacticalCornerReticle: View {
    let color: Color

    var body: some View {
        ZStack {
            CornerReticleShape()
                .stroke(Color.black.opacity(0.78), style: StrokeStyle(lineWidth: 5, lineCap: .square, lineJoin: .miter))
            CornerReticleShape()
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .square, lineJoin: .miter))
        }
        .shadow(color: color.opacity(0.48), radius: 3)
        .accessibilityHidden(true)
    }
}

struct CornerReticleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = min(rect.width, rect.height) * 0.22
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))

        return path
    }
}

struct TerrainTexture: View {
    let tile: TerrainTile
    let connectionDirections: [Int]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                connectionLayer(in: size)

                switch tile.terrain {
                case .plains:
                    fieldLines(in: size)
                case .forest:
                    forestClusters(in: size)
                case .city:
                    cityBlocks(in: size)
                case .mountain:
                    mountainRidges(in: size)
                case .snow:
                    snowDrifts(in: size)
                case .river:
                    waterHighlight(in: size)
                case .road:
                    EmptyView()
                }

                if tile.isObjective {
                    ObjectiveLandmark(tile: tile, size: size)
                }
            }
        }
        .clipShape(Hexagon())
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func connectionLayer(in size: CGSize) -> some View {
        let path = connectionPath(in: size)

        return Group {
            terrainContinuityLayer(path)

            if tile.terrain == .river {
                riverConnectionLayer(path)
            } else if tile.terrain.showsMapConnections {
                ZStack {
                    path
                        .stroke(
                            connectionShadowColor,
                            style: StrokeStyle(
                                lineWidth: tile.terrain.connectionWidth + connectionShadowWidth,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )

                    path
                        .stroke(
                            tile.terrain.connectionColor,
                            style: StrokeStyle(
                                lineWidth: tile.terrain.connectionWidth,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )

                    if tile.terrain == .river || tile.terrain == .road {
                        path
                            .stroke(
                                connectionHighlightColor,
                                style: StrokeStyle(
                                    lineWidth: tile.terrain == .river ? 1.3 : 0.7,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                    }
                }
            }
        }
    }

    private func riverConnectionLayer(_ path: Path) -> some View {
        ZStack {
            path
                .stroke(
                    BattlefieldTheme.riverCorridorBank,
                    style: StrokeStyle(
                        lineWidth: riverCorridorBankWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            path
                .stroke(
                    BattlefieldTheme.riverCorridorChannel,
                    style: StrokeStyle(
                        lineWidth: riverCorridorChannelWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            path
                .stroke(
                    connectionHighlightColor,
                    style: StrokeStyle(
                        lineWidth: riverCorridorHighlightWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        }
    }

    @ViewBuilder
    private func terrainContinuityLayer(_ path: Path) -> some View {
        switch tile.terrain {
        case .forest:
            // A quiet canopy shadow reaches the existing neighbouring edges
            // before individual trees are painted above it.
            path
                .stroke(
                    BattlefieldTheme.mapForestContinuity,
                    style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round)
                )
        case .mountain:
            // Existing same-terrain directions extend the massif's foot, not
            // a new route or marker system.
            path
                .stroke(
                    BattlefieldTheme.mapMountainContinuity,
                    style: StrokeStyle(lineWidth: 23, lineCap: .round, lineJoin: .round)
                )
        case .plains, .city, .snow, .river, .road:
            EmptyView()
        }
    }

    private func fieldLines(in size: CGSize) -> some View {
        // Keep the field material to one dominant patch and an optional
        // supporting patch so neighbouring plains read as a shared surface.
        let patchCount = terrainSeed % 4 == 0 ? 1 : 2

        return ZStack {
            ForEach(0..<patchCount, id: \.self) { index in
                let patchWidth = size.width * (index == 0 ? 0.42 : 0.28)
                    + size.width * seededFraction(index: index, multiplier: 17, offset: 5) * 0.12
                let patchHeight = size.height * (index == 0 ? 0.20 : 0.15)
                    + size.height * seededFraction(index: index, multiplier: 29, offset: 13) * 0.07
                let x = size.width * (0.24 + seededFraction(index: index, multiplier: 37, offset: 23) * 0.52)
                let y = size.height * (0.22 + seededFraction(index: index, multiplier: 43, offset: 31) * 0.54)
                let angle = -14 + Double((terrainSeed + index * 19) % 22)

                RoundedRectangle(cornerRadius: 2)
                    .fill(index == 0 ? BattlefieldTheme.terrainFieldPrimary : BattlefieldTheme.terrainFieldSupport)
                    .frame(width: patchWidth, height: patchHeight)
                    .rotationEffect(.degrees(angle))
                    .position(x: x, y: y)
            }
        }
    }

    private func forestClusters(in size: CGSize) -> some View {
        let treeCount = terrainSeed % 3 == 0 ? 2 : 3

        return ZStack {
            Ellipse()
                .fill(BattlefieldTheme.terrainForestCanopy)
                .frame(width: size.width * 0.72, height: size.height * 0.48)
                .rotationEffect(.degrees(Double((terrainSeed % 17) - 8)))
                .position(
                    x: size.width * (0.43 + seedFraction(multiplier: 13, offset: 7) * 0.16),
                    y: size.height * (0.46 + seedFraction(multiplier: 19, offset: 11) * 0.12)
                )

            ForEach(0..<treeCount, id: \.self) { index in
                let x = size.width * (0.25 + seededFraction(index: index, multiplier: 37, offset: 17) * 0.48)
                let y = size.height * (0.26 + seededFraction(index: index, multiplier: 23, offset: 41) * 0.42)
                let treeSize = 13 + CGFloat((terrainSeed + index * 5) % 7)

                Ellipse()
                    .fill(BattlefieldTheme.terrainForestShadow)
                    .frame(width: treeSize * 0.92, height: treeSize * 0.30)
                    .position(x: x + 1.5, y: y + treeSize * 0.44)

                Image(systemName: "tree.fill")
                    .font(.system(size: treeSize, weight: .bold))
                    .foregroundStyle(
                        index == 0
                            ? BattlefieldTheme.terrainForestTreeLight
                            : BattlefieldTheme.terrainForestTree
                    )
                    .shadow(color: BattlefieldTheme.terrainForestShadow, radius: 0.7, x: 1, y: 1.2)
                    .position(x: x, y: y)
            }
        }
    }

    private func cityBlocks(in size: CGSize) -> some View {
        let buildingCount = terrainSeed % 4 == 0 ? 3 : 4

        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * 0.62))
                path.addLine(to: CGPoint(x: size.width, y: size.height * 0.38))
                path.move(to: CGPoint(x: size.width * 0.46, y: 0))
                path.addLine(to: CGPoint(x: size.width * 0.56, y: size.height))
            }
            .stroke(BattlefieldTheme.terrainCityStreet, lineWidth: 5)

            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * 0.62))
                path.addLine(to: CGPoint(x: size.width, y: size.height * 0.38))
                path.move(to: CGPoint(x: size.width * 0.46, y: 0))
                path.addLine(to: CGPoint(x: size.width * 0.56, y: size.height))
            }
            .stroke(BattlefieldTheme.terrainCityStreetHighlight, lineWidth: 2)

            // Sparse blocks keep the street direction visible as the city
            // material instead of repeating a full building grid per tile.
            ForEach(0..<buildingCount, id: \.self) { index in
                let blockWidth = 10 + CGFloat((terrainSeed + index * 3) % 7)
                let blockHeight = 10 + CGFloat((terrainSeed + index * 7) % 7)
                let x = size.width * (0.22 + seededFraction(index: index, multiplier: 31, offset: 7) * 0.58)
                let y = size.height * (0.22 + seededFraction(index: index, multiplier: 19, offset: 29) * 0.56)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(BattlefieldTheme.terrainCityShadow)
                    .frame(width: blockWidth, height: blockHeight)
                    .position(x: x + 2, y: y + 2.5)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(BattlefieldTheme.terrainCityWall)
                    .overlay {
                        RoundedRectangle(cornerRadius: 1.5)
                            .stroke(BattlefieldTheme.terrainCityRim, lineWidth: 0.6)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(BattlefieldTheme.terrainCityWallShade)
                            .frame(height: blockHeight * 0.28)
                            .padding(.horizontal, 0.7)
                            .padding(.bottom, 0.7)
                    }
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                index == 0
                                    ? BattlefieldTheme.terrainCityRoofWarm
                                    : BattlefieldTheme.terrainCityRoofCool
                            )
                            .frame(height: blockHeight * 0.42)
                            .padding(.horizontal, 0.6)
                            .padding(.top, 0.6)
                    }
                    .frame(width: blockWidth, height: blockHeight)
                    .position(x: x, y: y)
            }
        }
    }

    private func mountainRidges(in size: CGSize) -> some View {
        let peakX = 0.28 + seedFraction(multiplier: 11, offset: 3) * 0.22
        let peakY = 0.14 + seedFraction(multiplier: 23, offset: 13) * 0.14
        let hasSupportRidge = terrainSeed % 3 != 0

        return ZStack {
            Ellipse()
                .fill(BattlefieldTheme.terrainMountainFoot)
                .frame(width: size.width * 0.82, height: size.height * 0.18)
                .position(x: size.width * 0.52, y: size.height * 0.78)

            // One broad massif is the primary mountain material; an optional
            // low ridge supplies deterministic variation without twin peaks
            // on every tile.
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.02, y: size.height * 0.84))
                path.addLine(to: CGPoint(x: size.width * peakX, y: size.height * peakY))
                path.addLine(to: CGPoint(x: size.width * 0.60, y: size.height * 0.50))
                path.addLine(to: CGPoint(x: size.width * 0.97, y: size.height * 0.82))
                path.closeSubpath()
            }
            .fill(BattlefieldTheme.terrainMountainBody)

            Path { path in
                path.move(to: CGPoint(x: size.width * 0.02, y: size.height * 0.84))
                path.addLine(to: CGPoint(x: size.width * peakX, y: size.height * peakY))
                path.addLine(to: CGPoint(x: size.width * (peakX + 0.12), y: size.height * 0.84))
                path.closeSubpath()
            }
            .fill(BattlefieldTheme.terrainMountainLight)

            Path { path in
                path.move(to: CGPoint(x: size.width * (peakX - 0.08), y: size.height * (peakY + 0.16)))
                path.addLine(to: CGPoint(x: size.width * peakX, y: size.height * peakY))
                path.addLine(to: CGPoint(x: size.width * (peakX + 0.08), y: size.height * (peakY + 0.16)))
                path.closeSubpath()
            }
            .fill(BattlefieldTheme.terrainMountainSnow)

            if hasSupportRidge {
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.52, y: size.height * 0.78))
                    path.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * (0.38 + seedFraction(multiplier: 29, offset: 31) * 0.14)))
                    path.addLine(to: CGPoint(x: size.width * 0.94, y: size.height * 0.80))
                    path.closeSubpath()
                }
                .fill(BattlefieldTheme.terrainMountainBody.opacity(0.72))
            }
        }
    }

    private func snowDrifts(in size: CGSize) -> some View {
        let startY = 0.48 + seedFraction(multiplier: 13, offset: 23) * 0.16
        let endY = 0.36 + seedFraction(multiplier: 19, offset: 37) * 0.18

        return ZStack {
            // Drift shading.
            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * startY))
                path.addCurve(
                    to: CGPoint(x: size.width, y: size.height * endY),
                    control1: CGPoint(x: size.width * 0.28, y: size.height * (startY - 0.22)),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * (endY + 0.24))
                )
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            .fill(BattlefieldTheme.terrainSnowDrift)

            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * startY))
                path.addCurve(
                    to: CGPoint(x: size.width, y: size.height * endY),
                    control1: CGPoint(x: size.width * 0.28, y: size.height * (startY - 0.22)),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * (endY + 0.24))
                )
            }
            .stroke(BattlefieldTheme.terrainSnowDriftHighlight, lineWidth: 1.4)

            // Leave most of the snowfield open; only some tiles carry one or
            // two conifers as a low-density support shape.
            if terrainSeed % 3 == 0 {
                let coniferCount = terrainSeed % 5 == 0 ? 1 : 2
                ForEach(0..<coniferCount, id: \.self) { index in
                    let x = size.width * (0.28 + seededFraction(index: index, multiplier: 41, offset: 11) * 0.46)
                    let y = size.height * (0.30 + seededFraction(index: index, multiplier: 27, offset: 47) * 0.38)
                    let treeHeight = 11 + CGFloat((terrainSeed + index * 7) % 5)

                    SnowConiferShape()
                        .fill(BattlefieldTheme.terrainSnowConifer)
                        .overlay {
                            SnowConiferCapShape()
                                .fill(BattlefieldTheme.terrainSnowCap)
                        }
                        .frame(width: treeHeight * 0.72, height: treeHeight)
                        .shadow(color: Color.black.opacity(0.16), radius: 0.7, x: 0.8, y: 1)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func waterHighlight(in size: CGSize) -> some View {
        let angle = Double((terrainSeed % 19) - 9)
        let centerX = size.width * (0.45 + seedFraction(multiplier: 7, offset: 3) * 0.10)
        let centerY = size.height * (0.47 + seedFraction(multiplier: 11, offset: 17) * 0.10)

        return ZStack {
            // Connected rivers use the shared path only. An isolated river
            // keeps a small deterministic surface so it remains identifiable.
            if connectionDirections.isEmpty {
                Capsule()
                    .fill(BattlefieldTheme.riverCorridorChannel.opacity(0.62))
                    .overlay {
                        Capsule()
                            .stroke(connectionHighlightColor, lineWidth: riverCorridorHighlightWidth)
                    }
                    .frame(width: size.width * 0.26, height: size.height * 0.07)
                    .rotationEffect(.degrees(angle))
                    .position(x: centerX, y: centerY)
            }
        }
    }

    private func connectionPath(in size: CGSize) -> Path {
        Path { path in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            if connectionDirections.isEmpty, tile.terrain == .road {
                // Keep an isolated road tile legible without rebuilding the
                // removed per-tile horizontal road grid.
                let direction = terrainSeed % 3 == 0 ? 0 : (terrainSeed % 3 == 1 ? 1 : 4)
                let edge = endpoint(for: direction, in: size)
                let dx = edge.x - center.x
                let dy = edge.y - center.y
                let distance = max(1, hypot(dx, dy))
                let halfLength = min(size.width, size.height) * 0.12
                let unitX = dx / distance
                let unitY = dy / distance
                path.move(
                    to: CGPoint(
                        x: center.x - unitX * halfLength,
                        y: center.y - unitY * halfLength
                    )
                )
                path.addLine(
                    to: CGPoint(
                        x: center.x + unitX * halfLength,
                        y: center.y + unitY * halfLength
                    )
                )
                return
            }
            for direction in connectionDirections {
                path.move(to: center)
                path.addLine(to: endpoint(for: direction, in: size))
            }
        }
    }

    private var connectionShadowColor: Color {
        switch tile.terrain {
        case .river:
            Color(red: 0.08, green: 0.19, blue: 0.29).opacity(0.17)
        case .road:
            Color.black.opacity(0.045)
        case .forest, .city, .mountain, .snow, .plains:
            Color.black.opacity(0.035)
        }
    }

    private var connectionHighlightColor: Color {
        tile.terrain == .river ? BattlefieldTheme.riverCorridorHighlight : Color.white.opacity(0.14)
    }

    private var riverCorridorBankWidth: CGFloat { 8 }
    private var riverCorridorChannelWidth: CGFloat { 5.8 }
    private var riverCorridorHighlightWidth: CGFloat { 0.9 }

    private var connectionShadowWidth: CGFloat {
        switch tile.terrain {
        case .river: 1.5
        case .road: 0.5
        case .forest, .city, .mountain, .snow, .plains: 0.5
        }
    }

    private var terrainSeed: Int {
        abs(tile.coordinate.q * 73 + tile.coordinate.r * 151 + 97)
    }

    private func seedFraction(multiplier: Int, offset: Int) -> CGFloat {
        CGFloat((terrainSeed * multiplier + offset) % 100) / 100
    }

    private func seededFraction(index: Int, multiplier: Int, offset: Int) -> CGFloat {
        CGFloat((terrainSeed + index * multiplier + offset) % 100) / 100
    }

    private func endpoint(for direction: Int, in size: CGSize) -> CGPoint {
        switch direction {
        case 0: CGPoint(x: size.width, y: size.height * 0.5)
        case 1: CGPoint(x: size.width * 0.75, y: 0)
        case 2: CGPoint(x: size.width * 0.25, y: 0)
        case 3: CGPoint(x: 0, y: size.height * 0.5)
        case 4: CGPoint(x: size.width * 0.25, y: size.height)
        default: CGPoint(x: size.width * 0.75, y: size.height)
        }
    }
}

private struct ObjectiveLandmark: View {
    let tile: TerrainTile
    let size: CGSize

    var body: some View {
        let isUrban = tile.terrain == .city
        let center = CGPoint(
            x: size.width * (isUrban ? 0.50 : 0.56),
            y: size.height * (isUrban ? 0.49 : 0.51)
        )
        let landmarkWidth = size.width * (isUrban ? 0.34 : 0.29)
        let landmarkHeight = size.height * (isUrban ? 0.28 : 0.26)

        ZStack {
            Ellipse()
                .fill(Color.black.opacity(isUrban ? 0.20 : 0.16))
                .frame(width: landmarkWidth * 0.92, height: landmarkHeight * 0.28)
                .position(x: center.x + size.width * 0.025, y: center.y + landmarkHeight * 0.38)

            ObjectiveLandmarkShape(isUrban: isUrban)
                .fill(
                    LinearGradient(
                        colors: isUrban
                            ? [Color(red: 0.83, green: 0.79, blue: 0.67), Color(red: 0.54, green: 0.50, blue: 0.39)]
                            : [Color(red: 0.63, green: 0.59, blue: 0.45), Color(red: 0.37, green: 0.35, blue: 0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    ObjectiveLandmarkShape(isUrban: isUrban)
                        .stroke(Color.black.opacity(0.46), lineWidth: 0.7)
                }
                .overlay {
                    ObjectiveLandmarkDetailShape(isUrban: isUrban)
                        .stroke(Color.white.opacity(0.36), lineWidth: 0.65)
                }
                .frame(width: landmarkWidth, height: landmarkHeight)
                .position(center)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ObjectiveLandmarkShape: Shape {
    let isUrban: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let body = rect.insetBy(dx: rect.width * 0.16, dy: rect.height * 0.18)
        let roofY = rect.minY + rect.height * 0.28

        if isUrban {
            path.addRoundedRect(in: body, cornerSize: CGSize(width: 1.5, height: 1.5))
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: roofY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.04))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: roofY))
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.03))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.minY + rect.height * 0.36))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.maxY - rect.height * 0.12))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY - rect.height * 0.12))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.36))
            path.closeSubpath()
        }

        return path
    }
}

private struct ObjectiveLandmarkDetailShape: Shape {
    let isUrban: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let doorWidth = rect.width * (isUrban ? 0.14 : 0.18)
        let doorHeight = rect.height * 0.34
        let doorRect = CGRect(
            x: rect.midX - doorWidth / 2,
            y: rect.maxY - doorHeight - rect.height * 0.10,
            width: doorWidth,
            height: doorHeight
        )
        path.addRoundedRect(in: doorRect, cornerSize: CGSize(width: 0.8, height: 0.8))

        if isUrban {
            let windowY = rect.minY + rect.height * 0.48
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: windowY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: windowY))
            path.move(to: CGPoint(x: rect.maxX - rect.width * 0.40, y: windowY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.28, y: windowY))
        } else {
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.midY))
        }

        return path
    }
}

struct ObjectiveFlagMarker: View {
    @ScaledMetric(relativeTo: .caption) private var ownerFontSize: CGFloat = 5.5

    let owner: Faction?

    var body: some View {
        // GoG3-style banner on a pole instead of a pill chip.
        ZStack(alignment: .topLeading) {
            // Pole.
            RoundedRectangle(cornerRadius: 0.75)
                .fill(Color(red: 0.35, green: 0.30, blue: 0.24))
                .frame(width: 1.8, height: 21)
                .offset(x: 1, y: 0)

            // Waving banner.
            WavingFlagShape()
                .fill(
                    LinearGradient(
                        colors: [
                            (owner?.accentColor ?? Color(white: 0.55)),
                            (owner?.accentColor ?? Color(white: 0.55)).opacity(0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    WavingFlagShape()
                        .stroke(Color.black.opacity(0.30), lineWidth: 0.7)
                )
                .frame(width: 15, height: 10)
                .offset(x: 2.6, y: 1)

            Text(owner?.shortTitle ?? "NEU")
                .font(.system(size: ownerFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 0.5)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.52)
                .offset(x: 4.6, y: 3)
        }
        .frame(width: 18, height: 22, alignment: .topLeading)
        .shadow(color: .black.opacity(0.35), radius: 1, x: 0.5, y: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A small banner with a gently waving fly edge.
struct WavingFlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12),
            control1: CGPoint(x: rect.width * 0.4, y: rect.minY - rect.height * 0.18),
            control2: CGPoint(x: rect.width * 0.7, y: rect.minY + rect.height * 0.24)
        )
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY - rect.height * 0.10))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.62, y: rect.maxY + rect.height * 0.14),
            control2: CGPoint(x: rect.width * 0.34, y: rect.maxY - rect.height * 0.26)
        )
        path.closeSubpath()
        return path
    }
}

/// Two stacked triangles forming a stylized conifer silhouette.
struct SnowConiferShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Upper canopy.
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY))
        path.closeSubpath()
        // Lower canopy.
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.14))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.14))
        path.closeSubpath()
        // Trunk.
        path.addRect(CGRect(
            x: rect.midX - rect.width * 0.07,
            y: rect.maxY - rect.height * 0.16,
            width: rect.width * 0.14,
            height: rect.height * 0.16
        ))
        return path
    }
}

/// Snow highlight covering the conifer's top canopy.
struct SnowConiferCapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.22, y: rect.minY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.22, y: rect.minY + rect.height * 0.30))
        path.closeSubpath()
        return path
    }
}

struct TerrainCodeBadge: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(BattlefieldTheme.commandDeckDeep.opacity(0.72))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.22), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.16), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ObjectiveNamePlate: View {
    @ScaledMetric(relativeTo: .caption) private var nameFontSize: CGFloat = 8

    let name: String
    let owner: Faction?
    var compact = false

    var body: some View {
        // Parchment nameplate under objective settlements, GoG3 city-label style.
        Text(name)
            .font(.system(size: nameFontSize, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 0.24, green: 0.20, blue: 0.13))
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(compact ? 0.46 : 0.52)
            .padding(.horizontal, compact ? 3 : 5)
            .padding(.vertical, compact ? 1.5 : 2.5)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.89, blue: 0.76),
                        Color(red: 0.85, green: 0.78, blue: 0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke((owner?.accentColor ?? BattlefieldTheme.brass).opacity(0.78), lineWidth: 1)
            )
            .shadow(color: .black.opacity(compact ? 0.20 : 0.28), radius: compact ? 1 : 2, x: 0, y: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ControlZoneMarker: View {
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .padding(4)
            .background(Color.red.opacity(0.88), in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct SupplyLineMarker: View {
    let connectionDirections: [Int]

    var body: some View {
        GeometryReader { proxy in
            let path = connectionPath(in: proxy.size)
            ZStack {
                path
                    .stroke(
                        Color.black.opacity(0.10),
                        style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
                    )
                path
                    .stroke(
                        BattlefieldTheme.supplyLine.opacity(0.48),
                        style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func connectionPath(in size: CGSize) -> Path {
        Path { path in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            if connectionDirections.isEmpty {
                path.move(to: CGPoint(x: size.width * 0.43, y: center.y))
                path.addLine(to: CGPoint(x: size.width * 0.57, y: center.y))
                return
            }

            for direction in connectionDirections {
                path.move(to: center)
                path.addLine(to: endpoint(for: direction, in: size))
            }
        }
    }

    private func endpoint(for direction: Int, in size: CGSize) -> CGPoint {
        switch direction {
        case 0: CGPoint(x: size.width, y: size.height * 0.5)
        case 1: CGPoint(x: size.width * 0.75, y: 0)
        case 2: CGPoint(x: size.width * 0.25, y: 0)
        case 3: CGPoint(x: 0, y: size.height * 0.5)
        case 4: CGPoint(x: size.width * 0.25, y: size.height)
        default: CGPoint(x: size.width * 0.75, y: size.height)
        }
    }
}

struct AttackCoverageMarker: View {
    var body: some View {
        Image(systemName: "scope")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.9))
            .padding(4)
            .background(Color.orange.opacity(0.72), in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct PostMoveAttackMarker: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 7, weight: .black))
            Text("NEXT")
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.86), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct AttackPositionMarker: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "scope")
                .font(.system(size: 7, weight: .black))
            Text("POS")
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.76), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ThreatenedMoveMarker: View {
    var body: some View {
        HStack(spacing: 1) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 7, weight: .black))
            Text("!")
                .font(.system(size: 6, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(Color.red.opacity(0.78), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.30), lineWidth: 0.8)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct FireRiskMarker: View {
    let preview: PostMoveFireExposurePreview

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: preview.riskLevel.systemImage)
                .font(.system(size: 7, weight: .black))
            Text(preview.riskLevel.shortTitle)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(preview.riskLevel.accentColor.opacity(0.86), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.36), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct GuidedObjectiveMarker: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 8, weight: .black))
            Text("OBJ")
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.green.opacity(0.82), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ObjectiveCaptureMarker: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flag.fill")
                .font(.system(size: 8, weight: .black))
            Text("CAP")
                .font(.system(size: 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(.black.opacity(0.82))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.yellow.opacity(0.88), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct EnemyThreatIntentMarker: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                .font(.system(size: 7, weight: .black))
            Text("INT")
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.pink.opacity(0.86), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.36), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct EnemyThreatCountermeasureFocusMarker: View {
    let markers: [EnemyThreatCountermeasureMapMarker]

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "scope")
                .font(.system(size: 7, weight: .black))
            Text(displayText)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.black.opacity(0.84))
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.mint.opacity(0.9), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var displayText: String {
        let roles = uniqueRoles
        if roles.count == 1 {
            return roles[0].shortTitle
        }
        return roles.map(\.compactTitle).joined(separator: "+")
    }

    private var uniqueRoles: [EnemyThreatCountermeasureMapMarkerRole] {
        var seen: Set<EnemyThreatCountermeasureMapMarkerRole> = []
        return markers
            .map(\.role)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { role in
                if seen.contains(role) { return false }
                seen.insert(role)
                return true
            }
    }
}

struct BattlefieldSituationResponseMapMarkerView: View {
    let marker: BattlefieldSituationResponseMapMarker

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: marker.iconName)
                .font(.system(size: 7, weight: .black))
            Text(marker.shortTitle)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(markerColor.opacity(0.9), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var markerColor: Color {
        switch marker.kind {
        case .countermeasureFollowUp:
            return Color.blue
        case .countermeasure:
            return Color.mint
        case .objectiveCapture:
            return Color.yellow
        case .combat:
            return Color.orange
        case .tacticalCommand:
            return Color.purple
        case .deployment:
            return Color.green
        case .reinforcement:
            return Color.cyan
        }
    }

    private var foregroundColor: Color {
        switch marker.kind {
        case .countermeasure, .objectiveCapture, .deployment, .reinforcement:
            return Color.black.opacity(0.84)
        case .countermeasureFollowUp, .combat, .tacticalCommand:
            return Color.white
        }
    }
}

struct BattlefieldSituationObjectivePressureMapMarkerView: View {
    let markers: [BattlefieldSituationObjectivePressureMapMarker]

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 7, weight: .black))
            Text(displayText)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.pink.opacity(0.9), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var displayText: String {
        let roles = uniqueRoles
        if roles.count == 1 {
            return roles[0].shortTitle
        }
        return roles.map(\.compactTitle).joined(separator: "+")
    }

    private var uniqueRoles: [BattlefieldSituationObjectivePressureMapMarkerRole] {
        var seen: Set<BattlefieldSituationObjectivePressureMapMarkerRole> = []
        return markers
            .map(\.role)
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { role in
                if seen.contains(role) { return false }
                seen.insert(role)
                return true
            }
    }
}

struct AIPhaseMapReplayMarker: View {
    let markers: [AIPhaseMapMarker]
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isFocused ? "scope" : "clock.arrow.circlepath")
                .font(.system(size: 7, weight: .black))
            Text(displayText)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(isFocused ? .black : .white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background((isFocused ? Color.yellow.opacity(0.88) : Color.indigo.opacity(0.88)), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(isFocused ? 0.72 : 0.36), lineWidth: isFocused ? 1.5 : 1)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var displayText: String {
        let orderedMarkers = markers.sorted {
            if $0.eventOrder != $1.eventOrder {
                return $0.eventOrder < $1.eventOrder
            }
            if $0.role.sortOrder != $1.role.sortOrder {
                return $0.role.sortOrder < $1.role.sortOrder
            }
            return $0.coordinate.id < $1.coordinate.id
        }
        guard let firstMarker = orderedMarkers.first else { return "AI" }
        if orderedMarkers.count == 1 {
            return "\(isFocused ? "SEL " : "")\(firstMarker.shortCode)-\(firstMarker.role.shortTitle)"
        }
        let roleText = orderedMarkers.prefix(2).map(\.role.compactTitle).joined(separator: "+")
        return "\(isFocused ? "SEL " : "")\(firstMarker.shortCode)+\(roleText)"
    }
}

struct MovementRouteMarker: View {
    let step: RouteStepPreview?
    let isDestination: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(markerFill)
                .frame(width: 62, height: 14)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isDestination ? 0.46 : 0.28), lineWidth: 1)
                )
                .rotationEffect(.degrees(-18))

            if let step {
                HStack(spacing: 2) {
                    if step.isThreatened {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 7, weight: .black))
                    }
                    Text("\(step.stepIndex):\(step.movementCost)")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(markerBadgeFill, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.38), lineWidth: 1)
                )
            } else if isDestination {
                RouteDestinationIcon()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var markerFill: Color {
        guard step?.isThreatened == true else {
            return Color.cyan.opacity(isDestination ? 0.28 : 0.20)
        }
        return Color.red.opacity(isDestination ? 0.26 : 0.20)
    }

    private var markerBadgeFill: Color {
        guard step?.isThreatened == true else {
            return Color.cyan.opacity(isDestination ? 0.92 : 0.78)
        }
        return Color.red.opacity(isDestination ? 0.94 : 0.82)
    }
}

struct RouteDestinationIcon: View {
    var body: some View {
        Image(systemName: "location.fill")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .padding(4)
            .background(Color.cyan.opacity(0.88), in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.38), lineWidth: 1)
            )
    }
}

struct TerrainSymbol: View {
    let tile: TerrainTile

    var body: some View {
        VStack(spacing: 2) {
            Text(tile.terrain.mapSymbol)
                .font(.system(size: tile.isObjective ? 18 : 22, weight: .black, design: .rounded))
                .foregroundStyle(tile.terrain.symbolColor)
                .shadow(color: .black.opacity(tile.terrain == .snow ? 0.0 : 0.18), radius: 1, x: 0, y: 1)
            Spacer(minLength: 0)
        }
        .padding(.top, tile.isObjective ? 24 : 19)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ActionMarker: View {
    let actionHint: MapActionHint

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .black))
            Text(label)
                .font(.system(size: 7, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(backgroundColor, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.30), lineWidth: 0.8)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var icon: String {
        switch actionHint {
        case .move:
            return "arrow.turn.up.right"
        case .attack:
            return "target"
        case .approachAttack:
            return "scope"
        case .none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable:
            return "circle"
        }
    }

    private var label: String {
        switch actionHint {
        case let .move(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "\(cost)+" : "\(cost)"
        case let .attack(damage, counterDamage, willDestroy):
            let counterText = counterDamage > 0 ? "/C\(counterDamage)" : ""
            return willDestroy ? "K" : "\(damage)\(counterText)"
        case let .approachAttack(cost, controlZonePenalty):
            return controlZonePenalty > 0 ? "P\(cost)+" : "P\(cost)"
        case .none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable:
            return ""
        }
    }

    private var backgroundColor: Color {
        switch actionHint {
        case .move:
            return Color.cyan.opacity(0.86)
        case .attack(_, _, let willDestroy):
            return willDestroy ? Color.orange.opacity(0.94) : Color.red.opacity(0.92)
        case .approachAttack:
            return Color.orange.opacity(0.88)
        case .none, .selectedUnit, .selectableUnit, .friendlyOccupied, .enemyOutOfRange, .enemyUnavailable:
            return Color.white.opacity(0.3)
        }
    }
}

struct UnavailableTargetMarker: View {
    let actionHint: MapActionHint

    var body: some View {
        Text(label)
            .font(.system(size: 7, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.46), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.red.opacity(0.38), lineWidth: 1)
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var label: String {
        switch actionHint {
        case let .enemyOutOfRange(distance, range):
            return "\(distance)>\(range)"
        case .enemyUnavailable:
            return "NO"
        case .none, .selectedUnit, .selectableUnit, .move, .attack, .approachAttack, .friendlyOccupied:
            return ""
        }
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let points = [
            CGPoint(x: width * 0.25, y: 0),
            CGPoint(x: width * 0.75, y: 0),
            CGPoint(x: width, y: height * 0.5),
            CGPoint(x: width * 0.75, y: height),
            CGPoint(x: width * 0.25, y: height),
            CGPoint(x: 0, y: height * 0.5)
        ]

        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct HexBoundarySegments: Shape {
    let directions: [Int]

    func path(in rect: CGRect) -> Path {
        let vertices = [
            CGPoint(x: rect.maxX, y: rect.midY),
            CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY),
            CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.midY),
            CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY),
            CGPoint(x: rect.minX + rect.width * 0.75, y: rect.maxY)
        ]

        return Path { path in
            for direction in directions where vertices.indices.contains(direction) {
                let vertex = vertices[direction]
                let previous = vertices[(direction + vertices.count - 1) % vertices.count]
                let next = vertices[(direction + 1) % vertices.count]
                path.move(to: midpoint(previous, vertex))
                path.addLine(to: vertex)
                path.addLine(to: midpoint(vertex, next))
            }
        }
    }

    private func midpoint(_ start: CGPoint, _ end: CGPoint) -> CGPoint {
        CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }
}

private struct HexEtchedBoundaryLayer: View {
    let sharedTerrainDirections: [Int]
    let terrainTransitionDirections: [Int]
    let mapEdgeDirections: [Int]

    var body: some View {
        ZStack {
            HexBoundarySegments(directions: sharedTerrainDirections)
                .stroke(
                    BattlefieldTheme.mapEtchedSharedBoundary,
                    lineWidth: BattlefieldTheme.mapEtchedSharedBoundaryWidth
                )
            HexBoundarySegments(directions: terrainTransitionDirections)
                .stroke(
                    BattlefieldTheme.mapEtchedTerrainBoundary,
                    lineWidth: BattlefieldTheme.mapEtchedTerrainBoundaryWidth
                )
            HexBoundarySegments(directions: mapEdgeDirections)
                .stroke(
                    BattlefieldTheme.mapEtchedOuterBoundary,
                    lineWidth: BattlefieldTheme.mapEtchedOuterBoundaryWidth
                )
        }
        .clipShape(Hexagon())
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HexInputReader: UIViewRepresentable {
    let hitShape: Path
    let directTouchAction: () -> Void
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            directTouchAction: directTouchAction,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )
    }

    func makeUIView(context: Context) -> HexInputView {
        let view = HexInputView(hitShape: hitShape)
        let directTouchRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDirectTouchTap(_:))
        )
        directTouchRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        directTouchRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(directTouchRecognizer)

        let primaryRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePrimaryTap)
        )
        primaryRecognizer.buttonMaskRequired = .primary
        primaryRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(primaryRecognizer)

        let secondaryRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSecondaryTap)
        )
        secondaryRecognizer.buttonMaskRequired = .secondary
        secondaryRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(secondaryRecognizer)

        return view
    }

    func updateUIView(_ uiView: HexInputView, context: Context) {
        uiView.hitShape = hitShape
        context.coordinator.directTouchAction = directTouchAction
        context.coordinator.primaryAction = primaryAction
        context.coordinator.secondaryAction = secondaryAction
    }

    final class Coordinator: NSObject {
        var directTouchAction: () -> Void
        var primaryAction: () -> Void
        var secondaryAction: () -> Void

        init(
            directTouchAction: @escaping () -> Void,
            primaryAction: @escaping () -> Void,
            secondaryAction: @escaping () -> Void
        ) {
            self.directTouchAction = directTouchAction
            self.primaryAction = primaryAction
            self.secondaryAction = secondaryAction
        }

        @objc func handleDirectTouchTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            directTouchAction()
        }

        @objc func handlePrimaryTap() {
            primaryAction()
        }

        @objc func handleSecondaryTap() {
            secondaryAction()
        }
    }
}

final class HexInputView: UIView {
    var hitShape: Path

    init(hitShape: Path) {
        self.hitShape = hitShape
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return hitShape.contains(point)
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
