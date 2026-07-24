import SwiftUI

@main
struct WW2TacticsApp: App {
    @StateObject private var game: GameState

    init() {
        let game = GameState()
        if CommandLine.arguments.contains("--ci-selected-combat-result") {
            game.handleTap(on: HexCoordinate(q: 7, r: 6))
            game.handleSecondaryAction(on: HexCoordinate(q: 9, r: 6))
            game.executeFocusedCommand()
        } else if CommandLine.arguments.contains("--ci-selected-attack-preview") {
            game.handleTap(on: HexCoordinate(q: 7, r: 6))
            game.handleSecondaryAction(on: HexCoordinate(q: 9, r: 6))
        } else if CommandLine.arguments.contains("--ci-selected-approach-preview") {
            game.handleTap(on: HexCoordinate(q: 7, r: 6))
            game.focus(coordinate: HexCoordinate(q: 9, r: 6))
        }
        _game = StateObject(wrappedValue: game)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}
