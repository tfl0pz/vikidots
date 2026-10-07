# Dots & Boxes

A two-player Dots and Boxes game for iPhone and iPad, written in SwiftUI. One
device, two players — pass it back and forth, tap between the dots to draw a
line, and try to claim more boxes than your opponent.

## About

Dots and Boxes is a classic pencil-and-paper game. Players take turns drawing
one line between two neighboring dots. Completing the fourth side of a box
claims it and earns another turn. When every space between dots is filled, the
player who claimed the most boxes wins.

This version includes:

- **Two players, one device** — Blue vs Red, pass-and-play
- **Tap to connect** — tap between two dots to draw a line; no dragging
- **Three grid options** — Medium (5×5 dots), Large (6×6), and a Custom size
  from 6 to 20 dots per side
- **Auto-save** — leaving the screen or quitting the app never loses a game;
  the start screen shows a "Resume" badge with the current score
- **iPhone and iPad** — adaptive layout with rotation and multitasking support
- **Dark and light mode** — follows the system appearance

## Screenshots

<img src="assets/IMG_5119.png" height="420" alt="Start screen with grid size options">
<img src="assets/IMG_5120.png" height="420" alt="Empty Medium board, Blue's turn">
<img src="assets/IMG_5121.png" height="420" alt="Mid-game with claimed boxes, score 1–1">

## Requirements

- Xcode 16 or later
- iOS 16 or later

## Getting started

1. Clone this repository.
2. Open `DotsAndBoxes.xcodeproj` in Xcode.
3. Select an iPhone or iPad simulator and press **⌘R** to run.

To run on a physical device, open the project settings, set your **Team** under
*Signing & Capabilities*, and change the bundle identifier
(`com.example.DotsAndBoxes`) to something unique.

## Deploying to the App Store

The project is a standard iOS app target, ready for distribution:

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs)
   ($99/year).
2. In Xcode, set your Team, then choose *Product → Archive* with **Any iOS
   Device** selected.
3. Use the Organizer to upload the archive to
   [App Store Connect](https://appstoreconnect.apple.com), fill in the store
   metadata and screenshots, and submit for review.

One note: the game saves its state with `UserDefaults`, which is on Apple's
"required reason" API list — include a privacy manifest
(`PrivacyInfo.xcprivacy`) when submitting, declaring on-device data storage.

## Project structure

```
DotsAndBoxes/
├── DotsAndBoxesApp.swift   App entry point
├── MenuView.swift          Grid-size picker
├── GameView.swift          Scoreboard, turn indicator, game-over panel
├── BoardView.swift         Board rendering and tap handling
└── Game.swift              Game rules and save/load persistence
```

The game logic lives in `Game.swift` and is deliberately kept separate from
the views, so the rules are easy to read and modify.

## License

MIT — do whatever you like, attribution appreciated.
