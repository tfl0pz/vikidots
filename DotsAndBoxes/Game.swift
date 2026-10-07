import SwiftUI

enum Player: Int, CaseIterable, Codable {
    case blue
    case red

    var name: String {
        self == .blue ? "Blue" : "Red"
    }

    var color: Color {
        self == .blue ? .playerBlue : .playerRed
    }
}

/// A possible line between two neighbouring dots.
/// Horizontal: from dot (row, col) to dot (row, col + 1)
/// Vertical:   from dot (row, col) to dot (row + 1, col)
struct Line: Hashable, Codable {
    let row: Int
    let col: Int
    let isHorizontal: Bool
}

/// A drawn line together with the player who drew it (dictionary keys can't be
/// encoded directly, so the line owners are stored as an array of these).
private struct SavedLine: Codable {
    let line: Line
    let player: Player
}

@MainActor
final class Game: ObservableObject {
    /// Number of dots on each side of the board (e.g. 5 means a 5x5 grid of dots).
    let dotCount: Int

    @Published private(set) var drawnLines = Set<Line>()
    @Published private(set) var lineOwners = [Line: Player]()
    @Published private(set) var boxOwners: [Player?]
    @Published private(set) var currentPlayer: Player = .blue

    init(dotCount: Int) {
        self.dotCount = dotCount
        boxOwners = Array(repeating: nil, count: (dotCount - 1) * (dotCount - 1))
    }

    var boxesPerRow: Int { dotCount - 1 }
    var totalLines: Int { 2 * dotCount * (dotCount - 1) }
    var isOver: Bool { drawnLines.count == totalLines }

    var scores: [Player: Int] {
        var result: [Player: Int] = [.blue: 0, .red: 0]
        for owner in boxOwners {
            if let owner { result[owner, default: 0] += 1 }
        }
        return result
    }

    var winner: Player? {
        let scores = self.scores
        guard scores[.blue] != scores[.red] else { return nil }
        return scores[.blue]! > scores[.red]! ? .blue : .red
    }

    func ownerOfBox(row: Int, col: Int) -> Player? {
        boxOwners[row * boxesPerRow + col]
    }

    func draw(_ line: Line) {
        guard !isOver, !drawnLines.contains(line) else { return }

        drawnLines.insert(line)
        lineOwners[line] = currentPlayer

        var completedBoxes = 0
        for (boxRow, boxCol) in boxesNextTo(line) {
            let index = boxRow * boxesPerRow + boxCol
            if boxOwners[index] == nil && boxIsComplete(row: boxRow, col: boxCol) {
                boxOwners[index] = currentPlayer
                completedBoxes += 1
            }
        }

        // Closing a box scores a point and earns the same player another turn.
        if completedBoxes == 0 {
            currentPlayer = (currentPlayer == .blue) ? .red : .blue
        }

        save()
    }

    func reset() {
        drawnLines.removeAll()
        lineOwners.removeAll()
        boxOwners = Array(repeating: nil, count: boxOwners.count)
        currentPlayer = .blue
        UserDefaults.standard.removeObject(forKey: saveKey)
    }

    // MARK: - Persistence

    private var saveKey: String { "savedGame-\(dotCount)" }

    /// Saves the game so it survives leaving the screen and even restarting the app.
    private func save() {
        let snapshot = SavedGame(
            savedLines: lineOwners.map { SavedLine(line: $0.key, player: $0.value) },
            boxOwners: boxOwners,
            currentPlayer: currentPlayer
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    /// The game saved for this grid size, if any.
    static func load(dotCount: Int) -> Game? {
        guard let data = UserDefaults.standard.data(forKey: "savedGame-\(dotCount)"),
              let snapshot = try? JSONDecoder().decode(SavedGame.self, from: data) else { return nil }

        let game = Game(dotCount: dotCount)
        for saved in snapshot.savedLines {
            game.drawnLines.insert(saved.line)
            game.lineOwners[saved.line] = saved.player
        }
        game.boxOwners = snapshot.boxOwners
        game.currentPlayer = snapshot.currentPlayer
        return game
    }

    private func boxesNextTo(_ line: Line) -> [(Int, Int)] {
        let candidates: [(Int, Int)]
        if line.isHorizontal {
            candidates = [(line.row - 1, line.col), (line.row, line.col)]
        } else {
            candidates = [(line.row, line.col - 1), (line.row, line.col)]
        }
        return candidates.filter {
            $0.0 >= 0 && $0.0 < boxesPerRow && $0.1 >= 0 && $0.1 < boxesPerRow
        }
    }

    private func boxIsComplete(row: Int, col: Int) -> Bool {
        let edges = [
            Line(row: row, col: col, isHorizontal: true),      // top
            Line(row: row + 1, col: col, isHorizontal: true),  // bottom
            Line(row: row, col: col, isHorizontal: false),     // left
            Line(row: row, col: col + 1, isHorizontal: false), // right
        ]
        return edges.allSatisfy { drawnLines.contains($0) }
    }
}

/// Codable snapshot of a game's state.
private struct SavedGame: Codable {
    var savedLines: [SavedLine]
    var boxOwners: [Player?]
    var currentPlayer: Player
}

extension Color {
    static let playerBlue = Color(red: 0.20, green: 0.55, blue: 1.00)
    static let playerRed = Color(red: 1.00, green: 0.32, blue: 0.36)
}
