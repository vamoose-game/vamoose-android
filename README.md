# Vamoose

Slide every block off the board before the clock runs out. Tap a block, it slides the way its arrow points.

Android · Flutter · no backend · version 1.1.0

## Game

- 360 levels in 12 chapters, boards from 6×6 to 8×8
- Every level starts with 3 stars; each bump costs one, and the third bump fails the level
- A clock on every level: 10 s for levels 1–10, then a little more each tier of 10–20 levels, up to 38 s (see [Levels and timers](tool/levels_report.md))
- A failed level costs a life: 5 lives, one back every 20 minutes, +1 with a video, or refill all for 120 coins
- Extra time: a fifth of the level's clock (2–5 s) before the first move, one per try (start with 1, then 30 coins each)
- Locked blocks from level 11: a block with a padlock moves only after the block with its key has left; up to three pairs (gold, silver, bronze)
- Turning blocks from level 21 to the end: round 1×1 blocks that turn a quarter clockwise every time another block leaves; they share levels with locks
- Every level can be cleared in any order: you can never get stuck
- Coins: start with 100 and 3 hints; +10 for a first clear and +5 for each new star, ×2 with a video once per level
- Hints: 50 coins or a short video
- Daily streak: login coins for 7 days (+10 to +40, then a chest with 150 coins and a streak freeze), streak freezes for 60 coins (hold 2), and a timed daily puzzle worth +50
- Store: lives, extra time, streak freezes and board themes: Classic (free), Wood (2,000 coins) and Night (3,000 coins)
- Settings: sound effects, music, vibration
- AdMob ads with Google consent (UMP) and a one-time Remove ads purchase

## Levels and timers

`tool/generate_levels.dart` builds every level from a curriculum (`tool/curriculum.dart`) and times it with a player simulation (`lib/domain/pace`): 400 simulated players, with spread-out speed, accuracy and practice, look for free blocks, tap them with Fitts' law timing, misread now and then (a bump) and rush when the clock runs low. Each tier of 10–20 levels gets the fewest seconds, more than the tier before, that still let

- 60–78 % of players clear each level on the first try (gentler early on),
- 90 % clear each level within three tries, and
- the clock stop at most 5 % of the quickest players.

So a tier ends tight and the next one breathes again. About 18 % of first tries fail overall. Levels 1–10 keep 10 s, so their boards are drawn until they are fair at 10 s.

No level has fewer blocks than in build 9, or fewer locks and turning blocks together than build 9 had locks. Every level but 9 also takes the simulated players at least as long to clear with no clock as the level with its number in build 9 (`test/fixtures/levels_build9.json`). Level 9 takes 9.2 s against 9.7 s: build 9 had no clock, and its level 9 would not be fair at 10 s, so level 9 takes the hardest board that is. Turning blocks are placed only where no order of moves can lead to a dead end (`Board.isSolvable`). The daily puzzle is timed for its own board and for a new player, so that 60 % clear it on the first try and 90 % within three tries, with a small margin.

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
| `lib/domain` | Board, tap rules, restraints (locks), turning blocks, stars, chapters, level generator and its features |
| `lib/domain/pace` | Player simulation that times levels |
| `lib/data` | Local storage and level catalog |
| `lib/state` | Settings, progress, coins, hints, extra time, lives, daily streak, themes, game session and its clock |
| `lib/services` | Sound, haptics, AdMob ads, Play Billing |
| `lib/ui` | Theme, widgets and screens |
| `lib/app` | Composition root and app widget |
| `tool` | Level (with curriculum and timer report), sound, music and icon generators |

## Ads and purchases

| Placement | Where | Rule |
| --- | --- | --- |
| Consent | First launch | Google UMP form before any ad loads; Settings › Ad privacy choices reopens it |
| Banner | Levels, Game | Adaptive, at the bottom; gone after Remove ads |
| Interstitial | After Next level | Every 3rd cleared level, never before level 10, 2 minutes apart; gone after Remove ads |
| Rewarded | Hint sheet, Level complete, out of lives, Store | A free hint, ×2 level coins once per level, or +1 life; given only when the video reward is earned |
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
