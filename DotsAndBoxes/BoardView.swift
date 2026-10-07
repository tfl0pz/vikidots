import SwiftUI

struct BoardView: View {
    @ObservedObject var game: Game

    var body: some View {
        GeometryReader { proxy in
            let layout = BoardLayout(size: proxy.size, dotCount: game.dotCount)
            ZStack {
                boxesLayer(layout)
                availableSlots(layout)
                drawnLines(layout)
                dots(layout)
            }
            .animation(.spring(response: 0.25), value: game.drawnLines.count)
            .animation(.spring(response: 0.3), value: game.boxOwners)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    if let line = layout.lineNearest(to: value.location) {
                        game.draw(line)
                    }
                }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Layers

    private func boxesLayer(_ layout: BoardLayout) -> some View {
        ForEach(0..<game.boxesPerRow, id: \.self) { row in
            ForEach(0..<game.boxesPerRow, id: \.self) { col in
                if let owner = game.ownerOfBox(row: row, col: col) {
                    let corner = layout.dot(row, col)
                    RoundedRectangle(cornerRadius: layout.step * 0.12)
                        .fill(owner.color.opacity(0.30))
                        .frame(width: layout.step, height: layout.step)
                        .position(x: corner.x + layout.step / 2, y: corner.y + layout.step / 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    /// Faint guides showing where a line can still be drawn.
    private func availableSlots(_ layout: BoardLayout) -> some View {
        ForEach(layout.allLines, id: \.self) { line in
            if !game.drawnLines.contains(line) {
                Segment(layout.ends(of: line))
                    .stroke(.secondary.opacity(0.25),
                            style: StrokeStyle(lineWidth: max(2, layout.step * 0.04), lineCap: .round))
                    .transition(.opacity)
            }
        }
    }

    private func drawnLines(_ layout: BoardLayout) -> some View {
        ForEach(Array(game.drawnLines), id: \.self) { line in
            Segment(layout.ends(of: line))
                .stroke(game.lineOwners[line]?.color ?? .secondary,
                        style: StrokeStyle(lineWidth: layout.step * 0.09, lineCap: .round))
                .transition(.opacity)
        }
    }

    private func dots(_ layout: BoardLayout) -> some View {
        ForEach(0..<game.dotCount, id: \.self) { row in
            ForEach(0..<game.dotCount, id: \.self) { col in
                Circle()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: layout.step * 0.13, height: layout.step * 0.13)
                    .position(layout.dot(row, col))
            }
        }
    }
}

/// A straight line drawn between two absolute points of the view.
private struct Segment: Shape {
    var from: CGPoint
    var to: CGPoint

    init(_ ends: (CGPoint, CGPoint)) {
        from = ends.0
        to = ends.1
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

/// Grid geometry: where every dot sits and which line a tap belongs to.
private struct BoardLayout {
    let step: CGFloat
    let origin: CGPoint
    let dotCount: Int

    init(size: CGSize, dotCount: Int) {
        self.dotCount = dotCount
        step = min(size.width, size.height) / CGFloat(dotCount - 1)
        origin = CGPoint(
            x: (size.width - step * CGFloat(dotCount - 1)) / 2,
            y: (size.height - step * CGFloat(dotCount - 1)) / 2
        )
    }

    func dot(_ row: Int, _ col: Int) -> CGPoint {
        CGPoint(x: origin.x + step * CGFloat(col), y: origin.y + step * CGFloat(row))
    }

    var allLines: [Line] {
        var lines = [Line]()
        for row in 0..<dotCount {
            for col in 0..<(dotCount - 1) {
                lines.append(Line(row: row, col: col, isHorizontal: true))
            }
        }
        for row in 0..<(dotCount - 1) {
            for col in 0..<dotCount {
                lines.append(Line(row: row, col: col, isHorizontal: false))
            }
        }
        return lines
    }

    func ends(of line: Line) -> (CGPoint, CGPoint) {
        line.isHorizontal
            ? (dot(line.row, line.col), dot(line.row, line.col + 1))
            : (dot(line.row, line.col), dot(line.row + 1, line.col))
    }

    /// The line closest to the tap, unless the tap is too far from every line
    /// (e.g. the middle of a box), in which case nothing is drawn.
    func lineNearest(to point: CGPoint) -> Line? {
        var nearest: (line: Line, distance: CGFloat)?
        for line in allLines {
            let (a, b) = ends(of: line)
            let distance = point.distance(toSegmentFrom: a, to: b)
            if distance < step * 0.33, distance < (nearest?.distance ?? .infinity) {
                nearest = (line, distance)
            }
        }
        return nearest?.line
    }
}

private extension CGPoint {
    func distance(toSegmentFrom a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(x - a.x, y - a.y) }

        // Project the point onto the segment, clamped between its end points.
        let t = max(0, min(1, ((x - a.x) * dx + (y - a.y) * dy) / lengthSquared))
        let projection = CGPoint(x: a.x + t * dx, y: a.y + t * dy)
        return hypot(x - projection.x, y - projection.y)
    }
}
