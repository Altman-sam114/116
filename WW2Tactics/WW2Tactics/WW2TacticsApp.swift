import SwiftUI

@main
struct WW2TacticsApp: App {
    @StateObject private var game: GameState
    private let combatResolutionSteadyState: Bool

    init() {
        let game = GameState()
        let arguments = CommandLine.arguments
        combatResolutionSteadyState = arguments.contains("--ci-selected-combat-impact-steady")
        if combatResolutionSteadyState || arguments.contains("--ci-selected-combat-result") {
            game.handleTap(on: HexCoordinate(q: 7, r: 6))
            game.handleSecondaryAction(on: HexCoordinate(q: 9, r: 6))
            game.executeFocusedCommand()
            if combatResolutionSteadyState,
               let attackerCoordinate = game.latestCombatResult?.attackerCoordinate {
                game.handleTap(on: attackerCoordinate)
            }
        } else if arguments.contains("--ci-selected-attack-preview") {
            game.handleTap(on: HexCoordinate(q: 7, r: 6))
            game.handleSecondaryAction(on: HexCoordinate(q: 9, r: 6))
        } else if arguments.contains("--ci-selected-approach-preview") {
            game.handleTap(on: HexCoordinate(q: 7, r: 6))
            game.focus(coordinate: HexCoordinate(q: 9, r: 6))
        }
        _game = StateObject(wrappedValue: game)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .environment(\.combatResolutionSteadyState, combatResolutionSteadyState)
        }
    }
}
