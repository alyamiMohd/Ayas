# Known issues

Classified by severity. Severity means *blocks handover progress*, not *is embarrassing*.

---

## BLOCKER

<a id="b1"></a>

### B1 — The app has never been launched

**Impact:** no runtime behaviour is verified. The app compiles and its unit tests pass, but
nothing has ever drawn a pixel.

CI builds both targets and runs 42 unit tests on every push. It does **not** launch the app,
render a view, serve a widget timeline, or exercise a gesture. So what is currently evidenced
is: day-boundary maths, streak logic, the Quran dataset, and persistence. What is not
evidenced is everything a user would actually see.

Specifically unverified:

1. Any SwiftUI view rendering at all — layout, truncation, overflow.
2. Arabic text layout ([M2](#m2)), which is the likeliest place for a visible bug.
3. The widget appearing, refreshing, or completing in place.
4. `ImageRenderer` producing a usable share card.
5. Navigation, sheets, deep links from the widget.
6. Whether the App Group container resolves on a real device ([H2](#h2)).

**Remediation:** launch it in a simulator and walk
[MAC_SETUP.md](MAC_SETUP.md#widget-verification). Perhaps an hour of work, and it converts
most of [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md) from claim to fact. Nothing else should
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

---

## Resolved

Kept as a record of what was wrong and how it surfaced.

### R1 — The codebase had never been compiled *(closed 21 Oct 2026)*

Authored on Windows with no Swift toolchain. The first CI run on a macOS runner found
**exactly one** compile error across 39 files, and two commits closed it.

### R2 — `HabitSequence.Kind.none` could never match *(fixed 21 Oct 2026)*

`Kind` had a case named `none`, matched through an `Optional<Kind>`. Swift resolves `.none`
there to `Optional.none`, so the enum's own case was unreachable and the switch was not
exhaustive — the one compile error in the codebase. Renamed to `plain`, keeping the raw value
`"none"` so stored documents were unaffected.

### R3 — An unknown sequence kind destroyed the habit *(fixed 21 Oct 2026)*

Found while fixing R2. `decodeIfPresent(Kind.self)` **throws** on an unrecognised raw value
rather than returning nil, so a sequence kind written by a newer build would have failed the
habit's decode, then the document's, and the whole file would have been quarantined as
unreadable. Now decoded as a string and mapped leniently, which is what the comment beside it
had always claimed.

### R4 — A refresh could silently miss a cross-process write *(fixed 21 Oct 2026)*

Caught by `PersistenceTests.testStorePicksUpAWriteFromAnotherProcess` on its first ever run.
`HabitStore.refreshFromDisk()` skipped reloading when the file's modification date matched
the one it last saw, so two writes inside the same timestamp granularity looked like none.

The production consequence was worse than the red test: the app would keep a stale document
and the next mutation would clobber whatever the widget had just recorded — losing a
completion, which is the one failure this app must not have. Now it reads the file every time
and assigns only on a real change.
