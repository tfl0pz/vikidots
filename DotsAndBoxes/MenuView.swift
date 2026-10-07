import SwiftUI

struct GridOption: Hashable, Identifiable {
    let dotCount: Int
    let name: String
    let detail: String

    var id: Int { dotCount }
}

let gridOptions: [GridOption] = [
    GridOption(dotCount: 5, name: "Medium", detail: "4 × 4 boxes — classic"),
    GridOption(dotCount: 6, name: "Large", detail: "5 × 5 boxes — long battle"),
]

struct MenuView: View {
    @State private var path = NavigationPath()
    @State private var customSize = 6
    @State private var savedScores: [Int: (blue: Int, red: Int)] = [:]

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Dots & Boxes")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("Two players, one device. Tap between the dots to draw a line — close a box to score and go again.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    ForEach(gridOptions) { option in
                        GridOptionCard(option: option, resume: savedScores[option.dotCount])
                            .onTapGesture { path.append(option) }
                    }
                    CustomSizeCard(size: $customSize, resume: savedScores[customSize])
                        .onTapGesture {
                            path.append(GridOption(dotCount: customSize, name: "Custom", detail: ""))
                        }
                }

                Spacer()
            }
            .frame(maxWidth: 500)
            .padding(24)
            .background(Color(.systemGroupedBackground))
            .onAppear(perform: refreshSavedGames)
            .navigationDestination(for: GridOption.self) { option in
                GameView(dotCount: option.dotCount)
            }
        }
    }

    private func refreshSavedGames() {
        var scores: [Int: (blue: Int, red: Int)] = [:]
        for dotCount in 5...20 {
            guard let game = Game.load(dotCount: dotCount) else { continue }
            scores[dotCount] = (game.scores[.blue] ?? 0, game.scores[.red] ?? 0)
        }
        savedScores = scores
        // If a custom-size game was saved, make the custom picker start there.
        if let savedCustom = scores.keys.first(where: { $0 != 5 && $0 != 6 }) {
            customSize = savedCustom
        }
    }
}

private struct GridOptionCard: View {
    let option: GridOption
    let resume: (blue: Int, red: Int)?

    var body: some View {
        HStack(spacing: 16) {
            GridPreview(dotCount: option.dotCount)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(option.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(option.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let resume {
                    ResumeLabel(resume: resume)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct CustomSizeCard: View {
    @Binding var size: Int
    let resume: (blue: Int, red: Int)?

    var body: some View {
        HStack(spacing: 16) {
            GridPreview(dotCount: size)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(size) × \(size) dots — \(size - 1) × \(size - 1) boxes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let resume {
                    ResumeLabel(resume: resume)
                }
            }
            Spacer()
            Stepper("", value: $size, in: 6...20)
                .fixedSize()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct ResumeLabel: View {
    let resume: (blue: Int, red: Int)

    var body: some View {
        Text("Resume · Blue \(resume.blue) – Red \(resume.red)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.playerBlue)
    }
}

/// A tiny preview of the dot grid with a couple of sample lines.
private struct GridPreview: View {
    let dotCount: Int

    var body: some View {
        GeometryReader { proxy in
            let step = min(proxy.size.width, proxy.size.height) / CGFloat(dotCount - 1)
            let origin = CGPoint(
                x: (proxy.size.width - step * CGFloat(dotCount - 1)) / 2,
                y: (proxy.size.height - step * CGFloat(dotCount - 1)) / 2
            )
            let dot: (Int, Int) -> CGPoint = { row, col in
                CGPoint(x: origin.x + step * CGFloat(col), y: origin.y + step * CGFloat(row))
            }

            ZStack {
                Path { path in
                    path.move(to: dot(2, 0))
                    path.addLine(to: dot(2, 1))
                }
                .stroke(Color.playerBlue,
                        style: StrokeStyle(lineWidth: max(1.5, min(3, step * 0.15)), lineCap: .round))

                Path { path in
                    path.move(to: dot(0, 2))
                    path.addLine(to: dot(1, 2))
                }
                .stroke(Color.playerRed,
                        style: StrokeStyle(lineWidth: max(1.5, min(3, step * 0.15)), lineCap: .round))

                ForEach(0..<dotCount, id: \.self) { row in
                    ForEach(0..<dotCount, id: \.self) { col in
                        Circle()
                            .fill(Color.primary.opacity(0.7))
                            .frame(width: min(6, step * 0.3), height: min(6, step * 0.3))
                            .position(dot(row, col))
                    }
                }
            }
        }
    }
}

#Preview {
    MenuView()
}
