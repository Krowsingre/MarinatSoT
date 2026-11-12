# Marin and the Sea of Tales

A peaceful fishing and poetry game for iPhone.

© Krowsingre Publishing LLC. All rights reserved.

## How it is built

- **Swift**, as a native iPhone app.
- **SpriteKit** draws the sea. **SwiftUI** handles the screens around it.
- **2D, portrait, side view:** sky above, the boat on the waterline, the deep below.
- All artwork is currently drawn in code.

## Layout

| Path | What it holds |
|---|---|
| `App/` | The iPhone app: the sea scene, the boat, drawing helpers. |
| `MarinCore/` | The game's rules with no graphics: time of day, weather, colours. Has its own tests. |
| `project.yml` | Describes the Xcode project. The project file itself is generated from this by XcodeGen. |
| `scripts/screenshots.sh` | Runs the app in a simulator and photographs it. |
| `.github/workflows/build.yml` | Builds, tests and photographs the app on every push. |

## Building

Every push to `main` is built on GitHub's Mac machines. The run tests the game logic, builds the
app, and saves screenshots of the sea at dawn, noon, dusk, night and in a storm. The latest results
are kept on the `ci-results` branch.

On a Mac:

```bash
brew install xcodegen
xcodegen generate
open Marin.xcodeproj
```

## Looking at a particular time or weather

The app normally follows the phone's clock and the day's own weather. To override, launch with:

| Argument | Example | Effect |
|---|---|---|
| `-seaHour` | `-seaHour 19` | Start at this hour of the day. |
| `-seaWeather` | `-seaWeather storm` | `clear`, `cloudy`, `rain` or `storm`. |
| `-seaTimeScale` | `-seaTimeScale 3600` | Speed up time. 3600 shows a whole day in 24 seconds. |
