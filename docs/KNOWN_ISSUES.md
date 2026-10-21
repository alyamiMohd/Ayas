# Known issues

Classified by severity. Severity means *blocks handover progress*, not *is embarrassing*.

---

## BLOCKER

<a id="b1"></a>

### B1 — The codebase has never been compiled

**Impact:** nothing in this repository is verified. Every feature in
[FEATURE_INVENTORY.md](FEATURE_INVENTORY.md) is a claim, not a guarantee.

**Cause:** authored on Windows, where no Swift or iOS toolchain exists. The project file is
generated and structurally validated; the logic has unit tests; none of it has met a
compiler.

**Expect:** a batch of compile errors on the first build. Most likely candidates, in order:

1. SwiftUI API signature drift — modifier argument labels, `onChange` arity, `ShareLink`
   initialiser shapes.
2. `ImageRenderer` / `MainActor` isolation in `HabitDetailView.task(id:)`.
3. App Intents conformance details — `TypeDisplayRepresentation`, `EntityQuery` requirements.
4. `@Observable` + `@Environment(HabitStore.self)` wiring.
5. Ambiguity between the `eyebrow` property and the `.eyebrow()` view modifier in
   `ScreenHeader`.

**Remediation:** on a Mac, `xcodebuild … build` (command in [CLAUDE.md](../CLAUDE.md)), fix
top-down, re-run. Then `… test`. Then update this entry and
[FEATURE_INVENTORY.md](FEATURE_INVENTORY.md). This is the first job and nothing else should
start before it.

---

## HIGH

<a id="h1"></a>

### H1 — Licensing of the bundled Quran text is unresolved

**Impact:** blocks App Store release. Does not block personal use or TestFlight among people
you know.

Two problems: Tanzil's terms restrict modification and `build_quran.py` modifies the text;
and the Saheeh International translation is separately copyrighted. Full detail and the four
options in [QURAN_CONTENT.md](QURAN_CONTENT.md#licensing).

**Remediation:** pick an option before investing in store assets. Cheapest path is shipping
Arabic only.

<a id="h2"></a>

### H2 — App Groups likely requires a paid Apple Developer account

**Impact:** on a **physical device** with a free Apple ID, the App Groups capability is
generally unavailable. The app falls back to its own sandbox and keeps working, but the widget
cannot see habit data — which is the core feature.

**Not a problem in the simulator**, where entitlements are not enforced the same way. Verify
there first.

**Remediation:** use the simulator for verification; a paid account ($99/yr) for real device
use. The fallback and its warning are in `DocumentStorage.init` and `SettingsView.footer`.

---

## MEDIUM

<a id="m1"></a>

### M1 — Pre-rendered widget entries are computed in one timezone

A timeline is built with the timezone current at build time. Flying across zones can leave
pre-rendered entries briefly wrong until iOS reports a significant time change or the app is
opened — `RootView` listens for `significantTimeChangeNotification` and reloads. The app
itself is always correct immediately, because it recomputes on read.

**Remediation if it matters:** shorten the lookahead, or have the provider compare the stored
timezone identifier and rebuild.

<a id="m2"></a>

### M2 — Arabic rendering is entirely unverified

No text has rendered. Line spacing (0.52 × size), `minimumScaleFactor`, and the right-to-left
environment are reasoned but untested. The worst case to check first is **2:282**, the longest
ayah, on a small widget.

<a id="m3"></a>

### M3 — Accessibility is partial

Completion controls have labels and traits. Not tested with VoiceOver; Dynamic Type is
unhandled — the app uses fixed point sizes throughout, so large accessibility sizes will
clip rather than reflow.

**Remediation:** audit after the first build. Fixed sizes were a deliberate design choice;
supporting Dynamic Type properly means revisiting `TypeScale`.

<a id="m4"></a>

### M4 — The `v0.5` tag predates the share and green-widget work

`v0.5` points at the first commit. The green completion state and sharing landed after it.
Anyone checking out the tag gets neither.

**Remediation:** tag a `v0.6` once a build passes, so the first tag with verified status is
meaningful.

---

## LOW

<a id="l1"></a>

### L1 — Travelling west can record completions out of step order

Crossing the date line westward can make "today" earlier than an already-recorded day. The
completion array stays sorted by day and streaks stay correct; only the recorded sequence
*step* ordering looks odd in history. Accepted — see [DECISIONS.md](DECISIONS.md#d7).

<a id="l2"></a>

### L2 — The share card is reachable only from habit detail

Two taps from the Today screen. A row context menu would make it one. Deliberate for now, to
keep the Today screen uncluttered.

<a id="l3"></a>

### L3 — No screenshots exist

Because the app has never rendered. The design intent is recorded in
[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md); take real screenshots as soon as a build runs and add
them to the README.

<a id="l4"></a>

### L4 — Adding a file through Xcode's UI will be lost

The project file is generated. Use `Tools/generate_xcodeproj.py` instead. See
[DECISIONS.md](DECISIONS.md#d8).

<a id="l5"></a>

### L5 — The app's own completed states are not green

Only the widget turns green. In the app, completion uses each habit's own accent. Consistent
with [D9](DECISIONS.md#d9), but an obvious thing to want unified.

<a id="l6"></a>

### L6 — CI will be red until the first build is fixed

`.github/workflows/ios.yml` runs a real simulator build. It is expected to fail initially —
that is the point. Its first green run is the moment B1 closes.
