# Setting up on a MacBook

Zero to running, assuming nothing is installed. Copy-pasteable throughout.

## 0. Requirements

| | Minimum | Notes |
| --- | --- | --- |
| macOS | Sonoma 14.5 | Whatever your Xcode needs |
| Xcode | 15.0 | 16 or later preferred. ~10 GB download |
| iOS Simulator | 17.0 | Interactive widgets need iOS 17 |
| Python | 3.8 | Preinstalled on macOS. Only for the project tools |
| Apple ID | — | **Not needed for the simulator.** Needed for a real device |

No package manager, no CocoaPods, no SPM resolution. There are zero third-party
dependencies — see [DECISIONS.md](DECISIONS.md#d13).

## 1. Install Xcode

From the Mac App Store, or [developer.apple.com/download](https://developer.apple.com/download/applications/).
Open it once and let it install additional components, then:

```bash
xcode-select --install          # command line tools, if not already present
xcodebuild -version             # confirm
```

## 2. Clone

The repository is **private**, so you need access first — the owner adds you as a
collaborator on GitHub, or gives you a token.

```bash
# Easiest: the GitHub CLI handles auth interactively
brew install gh                 # if you do not have Homebrew: https://brew.sh
gh auth login                   # choose HTTPS, authenticate in the browser
gh repo clone alyamiMohd/Ayas
cd Ayas
```

Or with plain git, once you have access:

```bash
git clone https://github.com/alyamiMohd/Ayas.git
cd Ayas
```

Confirm you have everything:

```bash
git log --oneline              # expect at least 3 commits
ls Shared/Content/Quran/       # expect 5 files, ~2.2 MB total
```

## 3. Verify the project file before opening it

```bash
python3 Tools/verify_project.py
```

Expect `OK: project is internally consistent`, listing three targets. If it fails, run
`python3 Tools/generate_xcodeproj.py` and try again.

## 4. Open and run in the simulator

```bash
open Ayas.xcodeproj
```

In Xcode:

1. Scheme dropdown (top left, next to the ▶ button) → **Ayas**.
2. Destination dropdown → any **iPhone 16** simulator.
3. Press **▶** (⌘R).

> **Expect this to fail the first time.** The code has never been compiled —
> see [KNOWN_ISSUES.md](KNOWN_ISSUES.md#b1). Errors
> appear in the Issue navigator (⌘5). This is the first real job on the project.

Or from the command line, which gives more legible errors:

```bash
xcodebuild -project Ayas.xcodeproj -scheme Ayas \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -60
```

## 5. Run the tests

```bash
xcodebuild -project Ayas.xcodeproj -scheme Ayas \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tail -40
```

Or **⌘U** in Xcode. Four test files cover day boundaries, streaks, the Quran sequence, and
persistence. They have never run — their first execution is genuinely informative, especially
`SequenceTests`, which validates the bundled scripture.

<a id="widget-verification"></a>

## 6. Widget verification

Widgets work in the simulator, and App Groups work there without a paid Apple account. Do this
pass before touching a real device.

1. Run the app, create a habit (or tap **Read one ayah a day** on the empty state).
2. **⌘⇧H** to go to the simulator Home Screen.
3. Long-press an empty area → **+** (top left) → search **Ayas** → pick **Medium** → Add Widget.
4. Check, in order:

   - [ ] The widget shows the habit name, the Arabic ayah, the reference and the streak
   - [ ] Arabic renders right-to-left with no clipped diacritics
   - [ ] Tapping the ring completes it **without launching the app**
   - [ ] The whole face turns green
   - [ ] Opening the app shows the same habit completed
   - [ ] Tapping the widget body opens the app on that habit's detail screen
   - [ ] Long-press → Edit Widget → the habit picker lists your habits
   - [ ] Two widgets pointed at different habits stay independent

5. Day rollover: in the simulator, **Settings → General → Date & Time**, turn off automatic
   and set tomorrow's date. The widget should clear its completion and keep the same ayah
   (missing a day must not skip content — [D6](DECISIONS.md#d6)). Set it two days ahead and
   the streak should drop to 0.

## 7. On a physical iPhone

Needs an Apple ID. For the widget to share data with the app you most likely need the **paid**
Apple Developer Program — see [KNOWN_ISSUES.md](KNOWN_ISSUES.md#h2).

1. Edit `Config/Ayas.xcconfig`:

   ```
   AYAS_BUNDLE_ID_PREFIX = com.yourname
   AYAS_APP_GROUP = group.com.yourname.shared
   ```

   This is the **only** place these are set. Both Info.plists, both entitlements files and
   `AppGroup.swift` read from it.

2. In Xcode: project icon → **TARGETS → Ayas → Signing & Capabilities** → tick *Automatically
   manage signing* → pick your Team.
3. Repeat for **AyasWidgetExtension**. Same team.
4. On both targets, confirm **App Groups** lists the identifier from step 1 and is ticked.
5. Plug the phone in, unlock, **Trust This Computer**. Select it as destination. ▶.
6. First run fails on signing: on the phone, **Settings → General → VPN & Device Management**
   → your Apple ID → **Trust**. Run again.

If the widget shows data but the app does not (or vice versa), the App Group is wrong — the
Settings screen says so explicitly when the container is unreachable.

## Verification checklist

Tick these and the handover is complete:

- [ ] `python3 Tools/verify_project.py` passes
- [ ] `xcodebuild … build` succeeds
- [ ] `xcodebuild … test` succeeds, all tests green
- [ ] App launches in the simulator
- [ ] A habit can be created, completed, un-completed
- [ ] Quitting and relaunching preserves state
- [ ] Widget added, shows correct content
- [ ] Widget completion works without launching the app
- [ ] Completed widget is green
- [ ] Two widgets with different habits work independently
- [ ] Rolling the clock forward one day behaves correctly
- [ ] Light and dark mode both look right (⌘⇧A in the simulator toggles appearance)
- [ ] [KNOWN_ISSUES.md](KNOWN_ISSUES.md) and [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md)
      updated with what actually happened

## Troubleshooting

**`Tools/verify_project.py` reports missing files**
Someone added a source file without regenerating. `python3 Tools/generate_xcodeproj.py`.

**Xcode cannot find a file that exists on disk**
Same cause. Regenerate, then reopen the project.

**"Signing for 'Ayas' requires a development team"**
Only relevant for device builds. For the simulator, pass `CODE_SIGNING_ALLOWED=NO`, or set a
team in Signing & Capabilities.

**App Groups option is greyed out or fails to register**
Free Apple ID limitation. See [H2](KNOWN_ISSUES.md#h2).
Use the simulator, or enrol in the paid program.

**The widget shows "One tiny thing a day" even though habits exist**
It cannot reach the App Group container. Check both targets carry the same group identifier
and that it matches `Config/Ayas.xcconfig`. The app's Settings screen reports this directly.

**The widget never updates**
Check `WidgetCenter.reloadTimelines` is being reached — `HabitStore.commit()`. In the
simulator, widget refresh is sometimes lazy; removing and re-adding the widget forces a
rebuild.

**Arabic text looks wrong, clipped or has broken diacritics**
First suspect rendering, not data — [M2](KNOWN_ISSUES.md#m2).
Run `AyasTests/SequenceTests` to confirm the data reads back correctly. If the data is wrong,
**do not edit the `.txt` files** — see [CLAUDE.md](../CLAUDE.md) rule 2.

**Tests fail with "Quran resources are not in this bundle"**
The folder reference is not in the test host's resources. Regenerate the project.

**Build succeeds, app crashes immediately on launch**
Likely `AppGroup` or `DocumentStorage`. Both are written to degrade rather than crash, so a
crash here is a real bug worth capturing in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
