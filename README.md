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

Without your own IDs the app shows Google test ads.

## Release

1. Create an upload key once and keep a backup of the file and passwords:

```bash
keytool -genkey -v -keystore ~/vamoose-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties` (git ignores it):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/home/you/vamoose-upload.jks
```

3. In AdMob, add the app and three ad units (adaptive banner, interstitial, rewarded). Under Privacy & messaging › European regulations, publish a message; it needs a privacy policy URL.
4. Add the AdMob app ID to `android/gradle.properties`:

```properties
admobAppId=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

5. Build the bundle with your ad unit IDs:

```bash
flutter build appbundle --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXX/AAA --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXX/BBB --dart-define=ADMOB_REWARDED_ID=ca-app-pub-XXX/CCC
```

6. In Play Console, create the app and upload `build/app/outputs/bundle/release/app-release.aab` to Testing › Internal testing.
7. Set up a payments profile, then go to Monetize with Play › Products › One-time products and create `remove_ads` with a purchase option and price, then Activate.
8. Add tester Gmail accounts under Settings › License testing and to the internal test. Testers install from the opt-in link; purchases do not work in builds installed with `flutter run`.

## Regenerate assets

```bash
dart run tool/generate_levels.dart
python3 tool/generate_sounds.py
python3 tool/generate_icons.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
