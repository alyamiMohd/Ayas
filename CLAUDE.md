# Operating instructions for Claude Code sessions on Ayas

Read this before touching anything. Then read [docs/HANDOVER.md](docs/HANDOVER.md).

## What this project is

An iOS 17 app, native Swift + SwiftUI + WidgetKit, built around a single loop: a tiny daily
action shown on the Home Screen widget, completed with one tap, held together by a streak.
The shipped example habit is reading one Quran ayah a day, but the sequence model is generic.

Full product framing: [docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md).

## The single most important fact

**This codebase has never been compiled.** It was written on Windows, where no Swift or iOS
toolchain exists. The Xcode project is generated and structurally validated, and the pure
logic is covered by unit tests, but no compiler has read a single line and no device has run it.

Consequences you must respect:

- **Never report a build or test as passing unless you actually ran it** and can quote the
  output. Not "this should compile". Not "the tests cover this".
- Treat every feature as *written but unverified* until a real build proves otherwise.
- The first real job on a Mac is `xcodebuild`, and the first findings will be compile errors.
  That is expected, not a crisis. See [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).
- Once a build succeeds, come back and update this section and
  [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md). It is the first thing that stops being true.

## Hard rules

### 1. The Xcode project is generated, not hand-edited

`Ayas.xcodeproj/project.pbxproj` is produced from the file tree by
`Tools/generate_xcodeproj.py`. After adding, renaming or deleting **any** source file:

```bash
python3 Tools/generate_xcodeproj.py
python3 Tools/verify_project.py
```

Both must pass before you commit. Generation is deterministic — regenerating without changing
files produces a byte-identical result, so a noisy diff means something really changed.

If Xcode itself writes to the project (adding a file through its UI, toggling a capability),
either redo that change in the generator or accept that the next regeneration will drop it.
Capability changes made in Xcode's Signing & Capabilities tab write to the `.entitlements`
files, which **are** hand-maintained and safe.

### 2. Never break the Quran data

`Shared/Content/Quran/*.txt` are addressed by byte offsets held in the matching `*.idx`
files. Any line-ending translation, re-encoding, or stray edit shifts every offset and the
app silently renders torn ayahs.

- `.gitattributes` pins these files as binary. Do not relax that.
- Do not open them in an editor that normalises newlines.
- To change the dataset, change `Tools/build_quran.py` and regenerate both the `.txt` and the
  `.idx` together. Never edit one alone.
- The scripture itself is not yours to correct. If text looks wrong, suspect the pipeline, and
  see [docs/QURAN_CONTENT.md](docs/QURAN_CONTENT.md).

### 3. One source of truth for habit state

All habit state lives in a single JSON document in the App Group container, written by both
the app and the widget extension. Only completion history is persisted; streaks and sequence
position are **derived** every time they are read.

Do not add a cached streak field, a denormalised "current ayah" column, or a second store.
The whole design depends on there being one fact and no way for it to disagree with itself.

### 4. Changing the app group or bundle identifier

`Config/Ayas.xcconfig` is the only place these are defined. Both Info.plists, both
entitlements files, and `AppGroup.swift` read from it. Never hardcode either value elsewhere.

### 5. Scripture and licensing are not ordinary content

Before shipping anything publicly, read [docs/QURAN_CONTENT.md](docs/QURAN_CONTENT.md). There
is an unresolved licensing question on the bundled translation that blocks App Store release.
Do not treat it as a detail to sort out later.

## Where things are

| You want | Go to |
| --- | --- |
| What exists and what does not | [docs/FEATURE_INVENTORY.md](docs/FEATURE_INVENTORY.md) |
| Why something is built the way it is | [docs/DECISIONS.md](docs/DECISIONS.md) |
| Code layout and data flow | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| How the widget works | [docs/WIDGETS.md](docs/WIDGETS.md) |
| Colours, type, components | [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) |
| What to build next | [docs/ROADMAP.md](docs/ROADMAP.md) |
| Where any given thing lives | [docs/CONTEXT_INDEX.md](docs/CONTEXT_INDEX.md) |

## Working style for this repo

- **Verify before asserting.** The docs were written from the code, but the code has never
  run. When a doc and the code disagree, the code wins — then fix the doc.
- **Prefer the existing design.** The visual identity, the one-way widget completion, the
  derived-state model and the generated project are deliberate. [docs/DECISIONS.md](docs/DECISIONS.md)
  records why. Argue with them if you have reason to, but do not quietly replace them.
- **Keep the surface small.** This is an MVP whose whole thesis is that it stays out of the
  way. A feature that makes the Today screen busier needs a strong argument.
- **Update docs in the same commit as the code.** A stale doc is worse than no doc, because
  the next session will trust it.
- **Do not add dependencies.** There are currently zero third-party packages. Keep it that way
  unless something genuinely cannot be done without one.

## Build and check commands

On macOS:

```bash
# Build for the simulator, no signing needed
xcodebuild -project Ayas.xcodeproj -scheme Ayas \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO build

# Unit tests
xcodebuild -project Ayas.xcodeproj -scheme Ayas \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test
```

Anywhere, including Windows:

```bash
python3 Tools/generate_xcodeproj.py   # rebuild the project file
python3 Tools/verify_project.py       # validate it
python3 Tools/build_quran.py <out>    # regenerate the Quran dataset (needs network)
```

CI runs the first two plus a macOS simulator build on every push:
`.github/workflows/ios.yml`.

## Platform note

The original author worked on Windows. If you are on macOS, you can do things they could not —
build, run, test, screenshot, profile. Prioritise that: a real build result is worth more to
this project right now than any amount of new code.
