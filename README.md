# Vamoose

The calm block puzzle. Tap a block, it slides the way its arrow points. Clear the board.

Android · Flutter · no backend · version 1.0.0

## Game

- 360 levels in 12 chapters, boards from 6×6 to 8×8
- Locked blocks from level 12: a block with a padlock moves only after the block with its key has left; two pairs (gold and silver) from level 76, three (with bronze) from level 181
- Every level is solvable in any order: you can never get stuck
- Stars: no bumps = 3, 1–2 bumps = 2, 3 or more = 1
- Coins: start with 100 and 3 hints; +10 for a first clear and +5 for each new star, ×2 with a video once per level
- Hints: 50 coins or a short video
- Daily streak: login coins for 7 days (+10 to +40, then a chest with 150 coins and a streak freeze), streak freezes for 60 coins (hold 2), and a daily puzzle worth +50
- Board themes: Classic (free), Wood (2,000 coins) and Night (3,000 coins)
- Settings: sound effects, music, vibration
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
| `lib/domain` | Board, tap rules, restraints (locks), stars, chapters, level generator and its features |
| `lib/data` | Local storage and level catalog |
| `lib/state` | Settings, progress, coins, hints, daily streak, themes, game session |
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
| Rewarded | Hint sheet, Level complete | A free hint, or ×2 level coins once per level; given only when the video reward is earned |
| Remove ads | Settings | One-time product `remove_ads`; Restore purchase brings it back |


## Release

1. Create an upload key once and keep a backup of the file and passwords:

```bash
keytool -genkey -v -keystore "$HOME\vamoose-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties` (git ignores it). Use forward slashes in the path; keytool uses one password for both entries:

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=C:/Users/you/vamoose-upload.jks
```

3. In AdMob, under Privacy & messaging › European regulations, publish a message; it needs the privacy policy URL.
4. Build the bundle. Release builds use the Vamoose AdMob app ID (`android/gradle.properties`) and ad units (`lib/services/ads/ad_units.dart`); debug builds use Google test ads.

```bash
flutter build appbundle
```

5. In Play Console, create the app and upload `build/app/outputs/bundle/release/app-release.aab` to Testing › Internal testing.
6. Set up a payments profile, then go to Monetize with Play › Products › One-time products and create `remove_ads` with a purchase option and price, then Activate.
7. Add tester Gmail accounts under Settings › License testing and to the internal test. Testers install from the opt-in link; purchases do not work in builds installed with `flutter run`.

## Regenerate assets

```bash
dart run tool/generate_levels.dart
python3 tool/generate_sounds.py
python3 tool/generate_music.py
python3 tool/generate_icons.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
