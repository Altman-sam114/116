import Foundation

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

struct RoadConnectionNetwork {
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
