import SwiftUI

struct GameView: View {
    @StateObject private var game: Game
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(dotCount: Int) {
        // Resume the saved game for this grid size, if there is one.
        let saved = Game.load(dotCount: dotCount)
        _game = StateObject(wrappedValue: saved ?? Game(dotCount: dotCount))
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .overlay {
            if game.isOver {
                GameOverView(game: game) {
                    game.reset()
                } changeSize: {
                    dismiss()
                }
            }
        }
        .navigationTitle("Dots & Boxes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    game.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Start over")
            }
        }
    }

    // Stacked layout for narrow screens (iPhone, iPad in a split view).
    private var compactLayout: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                playerCard(.blue)
                playerCard(.red)
            }
            .padding(.horizontal, 24)

            BoardView(game: game)
                .padding(.horizontal, 24)

            turnLabel
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    // Side-by-side layout for wide screens (iPad, large iPhone in landscape).
    private var regularLayout: some View {
        HStack(spacing: 48) {
            VStack(spacing: 20) {
                playerCard(.blue)
                playerCard(.red)
                turnLabel
                Spacer(minLength: 0)
            }
            .frame(width: 260)
            .padding(.leading, 32)
            .padding(.vertical, 24)

            BoardView(game: game)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func playerCard(_ player: Player) -> some View {
        let isActive = !game.isOver && game.currentPlayer == player
        return VStack(spacing: 4) {
            Text(player.name)
                .font(.headline)
            Text("\(game.scores[player] ?? 0)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
        }
        .foregroundStyle(player.color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(player.color.opacity(isActive ? 0.16 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(player.color.opacity(isActive ? 0.9 : 0.25),
                                      lineWidth: isActive ? 2 : 1)
                )
        }
        .scaleEffect(isActive ? 1.04 : 1)
        .animation(.default, value: isActive)
    }

    private var turnLabel: some View {
        Text(game.isOver ? "Game over" : "\(game.currentPlayer.name)'s turn")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(game.isOver ? Color.secondary : game.currentPlayer.color)
            .animation(.default, value: game.currentPlayer)
    }
}

private struct GameOverView: View {
    let game: Game
    let playAgain: () -> Void
    let changeSize: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(game.winner?.color ?? .primary)
                Text("\(game.scores[.blue] ?? 0) – \(game.scores[.red] ?? 0)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
                Button("Play Again", action: playAgain)
                    .buttonStyle(.borderedProminent)
                Button("Change Size", action: changeSize)
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: 460)
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(32)
        }
    }

    private var title: String {
        if let winner = game.winner {
            return "\(winner.name) wins!"
        }
        return "It's a tie!"
    }
}

#Preview {
    NavigationStack {
        GameView(dotCount: 5)
    }
}
