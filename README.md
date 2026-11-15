# Vamoose

The calm block puzzle. Tap a block, it slides the way its arrow points. Clear the board.

Android · Flutter · no backend · version 1.0.0

## Game

- 360 levels in 12 chapters, boards from 5×5 to 8×8
- Every level is solvable in any order: you can never get stuck
- Stars: no bumps = 3, 1–2 bumps = 2, 3 or more = 1
- 3 starting hints, 1 free hint every day, +1 hint for each daily puzzle
- Daily puzzle with streaks
- Settings: easy mode, bigger text, sound effects, vibration
- Ads and purchases are placeholders (`PlaceholderAdService`, `PlaceholderPurchaseService`)

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter analyze
flutter test
```

## Project

| Path | What |
| --- | --- |
| `lib/domain` | Board, tap rules, stars, chapters, level generator |
| `lib/data` | Local storage and level catalog |
| `lib/state` | Settings, progress, hints, daily streak, game session |
| `lib/services` | Sound, haptics, ad and purchase interfaces |
| `lib/ui` | Theme, widgets and screens |
| `lib/app` | Composition root and app widget |
| `tool` | Level, sound and icon generators |

## Regenerate assets

```bash
dart run tool/generate_levels.dart
python3 tool/generate_sounds.py
python3 tool/generate_icons.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
