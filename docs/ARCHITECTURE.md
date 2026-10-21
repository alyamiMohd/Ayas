# Architecture

Native Swift + SwiftUI + WidgetKit. iOS 17 minimum. Swift 5 language mode. **Zero third-party
dependencies** — no SPM packages, no CocoaPods, no Carthage.

## Targets

| Target | Product | Purpose |
| --- | --- | --- |
| `Ayas` | `.app` | The application |
| `AyasWidgetExtension` | `.appex` | WidgetKit extension, embedded into the app's `PlugIns/` |
| `AyasTests` | `.xctest` | Unit tests, hosted by the app |

`Shared/` is compiled into **both** the app and the widget — membership in two targets, not a
framework. At this size a framework target would add build complexity and a dynamic-link cost
to a memory-constrained extension for no benefit. See [DECISIONS.md](DECISIONS.md#d3).

## Layout

```
Config/Ayas.xcconfig     bundle prefix + app group. The only file to edit per developer.

Shared/                  compiled into app AND widget
  Model/
    DayKey.swift         a civil day (yyyymmdd) + DayClock for day boundaries
    Habit.swift          the habit, its completions, and all derived state
    HabitSequence.swift  what today's step is; SequenceResolver turns it into text
    HabitSnapshot.swift  one habit rendered for one day — the shared view model
    AyasDocument.swift   the persisted root: habits + settings
    HabitPresets.swift   starting templates
    DeepLink.swift       ayas:// URL shapes
  Store/
    AppGroup.swift       reads the group id from Info.plist
    DocumentStorage.swift  coordinated atomic JSON read/write
    HabitStore.swift     @Observable; the only place state is mutated
  Content/
    QuranLibrary.swift   byte-offset random access to the bundled text
    Quran/               the dataset (folder reference, bundled as-is)
  Intents/
    HabitEntity.swift        the habit as App Intents sees it
    CompleteHabitIntent.swift  what the widget button runs
    SelectHabitIntent.swift    per-widget habit configuration
  Design/
    Palette.swift        adaptive colour tokens
    Typography.swift     type scale, eyebrow style, Arabic text view
    Motion.swift         animation curves, radii, spacing scale
    CompletionMark.swift the ring that becomes a check

Ayas/                    app only
  AyasApp.swift          @main, owns the store
  RootView.swift         navigation stack, sheets, deep links, scene phase
  Screens/               Today, HabitDetail, HabitEditor, Settings
  Components/            HabitRow, AyahBlock, WeekStrip, EmptyState, ShareCard, Chrome
  Support/Haptics.swift

AyasWidget/              widget only
  AyasWidgetBundle.swift @main for the extension
  HabitWidget.swift      the Widget + its configuration
  HabitTimelineProvider.swift  timeline construction
  HabitWidgetView.swift  the face

AyasTests/               DayKey, Streak, Sequence, Persistence
Tools/                   generate_xcodeproj.py, verify_project.py, build_quran.py
```

## Data flow

```
                    ┌──────────────────────────────┐
                    │  App Group container         │
                    │  habits.json                 │
                    │  (the only persisted state)  │
                    └──────────────────────────────┘
                         ▲                    ▲
          NSFileCoordinator              NSFileCoordinator
          atomic write                   atomic write
                         │                    │
              ┌──────────┴───────┐   ┌────────┴────────────┐
              │ HabitStore       │   │ CompleteHabitIntent │
              │ (app process)    │   │ (widget process)    │
              └──────────┬───────┘   └────────┬────────────┘
                         │                    │
                   @Observable          WidgetCenter.reload
                         │                    │
              ┌──────────▼───────┐   ┌────────▼────────────┐
              │ SwiftUI screens  │   │ HabitTimelineProvider│
              └──────────────────┘   └─────────────────────┘
```

Two processes, one file. Neither holds authoritative state in memory:

- `HabitStore.refreshFromDisk()` runs before every mutation and on every foreground, so the
  app cannot clobber a write the widget made while it was backgrounded.
- Every mutation writes through immediately and calls `WidgetCenter.reloadTimelines`.
- The widget extension reads through `DocumentStorage.shared.load()` directly rather than
  holding a long-lived store, because extension processes are short-lived and may be stale.

## Derived, never stored

This is the load-bearing idea. The document persists **only**:

- the list of habits and their configuration
- for each habit, an array of `(day, step)` completions

Everything else is computed on read:

| Derived | From | Where |
| --- | --- | --- |
| Current streak | the set of completion days + today | `Habit.currentStreak(asOf:)` |
| Best streak | the sorted completion days | `Habit.bestStreak()` |
| Total completions | `completions.count` | `Habit.totalCompletions` |
| Today's sequence step | `completions.count` | `Habit.nextStep` |
| Whether today is done | membership test | `Habit.isComplete(on:)` |
| Everything a view needs | all of the above | `HabitSnapshot.init` |

Because the derivation is a pure function of `(history, day)`, the widget can render a
*future* day correctly — which is exactly how the timeline advances without the app running.
It also means there is no cached value that can drift out of sync with the truth.

**Do not add a stored streak field.** See [CLAUDE.md](../CLAUDE.md) rule 3.

## Time

A completion is a **civil day** (`20260928`), never an instant. Timezone travel cannot move a
past completion into another day, because the day was recorded as a name, not a moment.

`DayKey(date, calendar:dayStartHour:)` compares the wall-clock hour rather than subtracting
hours from an instant — on a spring-forward morning those differ, and the naive version puts
the boundary on the wrong side of the date. `DayClock.nextBoundary` finds the next transition
and guards against a boundary landing on or before now.

See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for the one residual timezone gap in the widget.

## Project generation

`Ayas.xcodeproj` is generated from the file tree by `Tools/generate_xcodeproj.py` with
identifiers hashed from stable keys, so regeneration is byte-identical and diffs stay
readable. `Tools/verify_project.py` parses the result back and asserts every reference
resolves and every target is shaped correctly.

This exists because the project was authored on Windows without Xcode. It has turned out to be
worth keeping: the project file can never silently drift from the files on disk. See
[DECISIONS.md](DECISIONS.md#d8).
