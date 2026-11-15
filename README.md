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
- AdMob ads with Google consent (UMP) and a one-time Remove ads purchase

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
| `lib/services` | Sound, haptics, AdMob ads, Play Billing |
| `lib/ui` | Theme, widgets and screens |
| `lib/app` | Composition root and app widget |
| `tool` | Level, sound and icon generators |

## Ads and purchases

| Placement | Where | Rule |
| --- | --- | --- |
| Consent | First launch | Google UMP form before any ad loads; Settings › Ad privacy choices reopens it |
| Banner | Levels, Game | Adaptive, at the bottom; gone after Remove ads |
| Interstitial | After Next level | Every 3rd cleared level, never before level 10, 2 minutes apart; gone after Remove ads |
| Rewarded | Out of hints, Board clear | +1 hint, given only when the video reward is earned |
| Remove ads | Settings | One-time product `remove_ads`; Restore purchase brings it back |

Without your own IDs the app shows Google test ads. Before a release:

1. In AdMob, create the app and three ad units: adaptive banner, interstitial, rewarded.
2. In AdMob › Privacy & messaging, publish a GDPR message so the consent form can show.
3. Add the AdMob app ID to `android/gradle.properties`:

```properties
admobAppId=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

4. In Play Console › Monetize › In-app products, create a one-time product with ID `remove_ads`, set its price and activate it.
5. Build the release with your ad unit IDs:

```bash
flutter build appbundle --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXX/AAA --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXX/BBB --dart-define=ADMOB_REWARDED_ID=ca-app-pub-XXX/CCC
```

Purchases only work in builds installed from Google Play (for example the internal testing track) with a license tester account.

## Regenerate assets

```bash
dart run tool/generate_levels.dart
python3 tool/generate_sounds.py
python3 tool/generate_icons.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
