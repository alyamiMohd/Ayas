# Widgets

The widget is not an accessory to this app — it is the product. Everything else exists to
support it. [PRODUCT_VISION.md](PRODUCT_VISION.md) explains why.

## What ships

| | |
| --- | --- |
| Kind | `AyasHabitWidget` (`WidgetKinds.habit`, defined in `HabitStore.swift`) |
| Families | `.systemSmall`, `.systemMedium` |
| Configuration | `AppIntentConfiguration` with `SelectHabitIntent` |
| Interaction | `Button(intent:)` running `CompleteHabitIntent` |
| Content margins | Disabled — the face draws its own padding |
| Minimum OS | iOS 17 (interactive widgets require it) |

Files: `AyasWidget/HabitWidget.swift`, `HabitTimelineProvider.swift`, `HabitWidgetView.swift`.

## Per-widget habit selection

Each widget instance carries a `SelectHabitIntent` naming its habit, so three habits can sit
on the Home Screen as three widgets. Long-press → Edit Widget → pick.

The parameter is **optional** on purpose (`@Parameter var habit: HabitEntity?`). A freshly
dropped widget therefore shows the first habit immediately rather than an unconfigured
placeholder, and a widget whose habit was deleted falls back rather than erroring. The
fallback lives in `HabitTimelineProvider.resolveHabit(for:in:)`.

`HabitQuery` populates the picker by reading `DocumentStorage.shared.load()` directly, not
through `HabitStore`, so the list always reflects what is on disk right now.

## Completing from the widget

`CompleteHabitIntent.perform()` runs **inside the widget extension process**. It calls
`HabitStore.shared.complete(id:)`, which refreshes from disk, mutates, writes atomically
through `NSFileCoordinator`, and asks WidgetKit to reload. The app is never launched.

Two deliberate properties:

- **It is idempotent.** `Habit.markComplete(on:)` returns `false` and changes nothing if the
  day is already complete, so a double tap cannot inflate a streak or advance the sequence
  twice.
- **It is one-way.** The widget can complete but never un-complete. A stray thumb on the Home
  Screen must not be able to cost someone a streak. Undo lives in the app, where the gesture
  is intentional. See [DECISIONS.md](DECISIONS.md#d5).

Once complete, the control stops being a `Button` at all and renders as a static mark.

<a id="timeline"></a>

## The timeline — how the day advances unaided

This is the part worth understanding before changing anything.

`HabitTimelineProvider.timeline(for:in:)` does **not** emit a single entry. It emits:

1. one entry for *now*, and
2. one entry for each of the next **four** day boundaries,

each pre-rendered with the state as it will stand on that day: completion cleared, the next
ayah resolved, the streak recomputed. Policy is `.atEnd`.

```
 now ──────────▶ boundary+1 ──────▶ boundary+2 ──────▶ boundary+3 ──────▶ boundary+4
 today's state   tomorrow:          day after:          streak now         ...
 (maybe done)    not done,          not done,           reads 0
                 same ayah,         streak still
                 streak holds       holds (grace)
```

WidgetKit swaps entries as each boundary passes. So:

- The ayah is correct tomorrow morning whether or not the app was opened.
- A streak that breaks over a missed weekend **visibly breaks on its own**, at the right
  moment, with no process running.

This works only because streak and sequence are pure functions of `(history, day)` — see
[ARCHITECTURE.md](ARCHITECTURE.md#derived-never-stored). If anyone caches a streak, this
breaks silently.

Note the sequence does **not** advance across those future entries: step is
`completions.count`, so an uncompleted day shows the same ayah tomorrow. That is correct —
missing a day must not skip content.

## Refresh triggers

| Trigger | Mechanism |
| --- | --- |
| User completes in the app | `HabitStore.commit()` → `reloadTimelines(ofKind:)` |
| User completes on the widget | intent writes, then WidgetKit reloads the widget |
| Any habit/settings edit | same `commit()` path |
| A day boundary passes | pre-rendered entries, no process needed |
| Midnight / timezone change | `RootView` observes `significantTimeChangeNotification` → `reloadAllTimelines` |
| Data erased | `HabitStore.eraseEverything()` → `reloadAllTimelines` |

WidgetKit budgets refreshes. The design leans on pre-rendered entries precisely so it does
not need to spend that budget to be correct.

## The face

`HabitWidgetView` with a `Metrics` struct per family — one `switch` in one place, which is
where a new family gets added.

Incomplete: habit name as an eyebrow, the Arabic ayah (2 lines on medium, 3 on small),
translation on medium only, the reference, the streak, and the ring.

Complete: **the whole face turns green** — `Palette.doneGround` → `doneGroundEdge` as the
container background, with `onDone` / `onDoneSoft` / `onDoneFaint` inks and a `MarkPalette`
override so the mark stays legible on a filled ground. Every habit uses the same green
regardless of its own accent: at Home Screen size the only question is whether today is done,
and one colour answers it without being read. See [DECISIONS.md](DECISIONS.md#d9).

## Deep linking

`widgetURL(DeepLink.habitURL(id))` on the habit face; `DeepLink.rootURL` on the empty face.
`RootView.onOpenURL` refreshes from disk, checks the habit still exists, and sets the
navigation path. Scheme `ayas` is registered in `Ayas/Info.plist`.

## App Group dependency

The widget can only see habit data through the App Group container. If the capability is
missing or mismatched, `DocumentStorage` falls back to the app's own sandbox: the app keeps
working, the widget shows the empty face, and Settings says so plainly. This is the single
most likely setup failure — see [MAC_SETUP.md](MAC_SETUP.md).

## Testing the widget

Unit tests cannot cover WidgetKit. What *is* testable is already covered: the snapshot
builder, streak and sequence logic in `AyasTests/`. The widget itself needs manual checks —
the list is in [MAC_SETUP.md](MAC_SETUP.md#widget-verification).

Simulator note: you can add widgets in the iOS Simulator, and App Groups work there without a
paid Apple account. Use the simulator for the first verification pass.

## Extension points

- **New family**: add a case to `Metrics.init(family:)` and to `supportedFamilies`.
- **Lock Screen accessories**: same, but they render monochrome/vibrant — the green state and
  the wash will need a separate treatment.
- **A multi-habit widget**: would need a new entry type; the timeline shape carries over.
