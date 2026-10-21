# Feature inventory

Every feature, its status, and where the evidence is. Nothing here is claimed without a file
reference.

## Status vocabulary

| Status | Means |
| --- | --- |
| `WRITTEN` | Implemented in source. **Never compiled or run** — see [CLAUDE.md](../CLAUDE.md). |
| `PARTIAL` | Some of it exists; the gap is named. |
| `PLANNED` | Agreed as wanted, not started. Tracked in [ROADMAP.md](ROADMAP.md). |
| `DECLINED` | Deliberately excluded from the MVP. See [DECISIONS.md](DECISIONS.md). |

Because nothing has been compiled, **no feature in this repository is currently verified at
runtime.** `WRITTEN` is the ceiling until someone runs a build. Treat the whole table as a
list of claims to test, not a list of guarantees.

---

## App

| Feature | Status | Evidence |
| --- | --- | --- |
| Today screen listing the day's habits | `WRITTEN` | `Ayas/Screens/TodayView.swift:7` |
| Complete / un-complete from the list | `WRITTEN` | `TodayView.swift` → `toggle(_:)` → `HabitStore.toggle` |
| Habit detail with today's content in full | `WRITTEN` | `Ayas/Screens/HabitDetailView.swift:5` |
| Create a habit | `WRITTEN` | `Ayas/Screens/HabitEditorView.swift:5`, mode `.create` |
| Edit a habit | `WRITTEN` | `HabitEditorView.swift`, mode `.edit` |
| Delete a habit (with confirm step) | `WRITTEN` | `HabitEditorView.swift` → `deleteSection` |
| Multiple habits side by side | `WRITTEN` | `AyasDocument.habits` is an array throughout |
| Streak, best streak, total days | `WRITTEN` | `Shared/Model/Habit.swift:80`, `:103` |
| 14-day history strip | `WRITTEN` | `Shared/Model/Habit.swift:117`, `Ayas/Components/WeekStrip.swift` |
| Empty state with one-tap Quran habit | `WRITTEN` | `Ayas/Components/EmptyStateView.swift:5` |
| Settings: appearance (system/light/dark) | `WRITTEN` | `Ayas/Screens/SettingsView.swift:4` |
| Settings: when a new day begins (0–4am) | `WRITTEN` | `Shared/Model/AyasDocument.swift:32` |
| Settings: show translation | `WRITTEN` | `HabitDetailView.swift:33` |
| Settings: haptics | `WRITTEN` | `Ayas/Support/Haptics.swift` |
| Settings: erase all data | `WRITTEN` | `HabitStore.eraseEverything` |
| Light and dark mode | `WRITTEN` | `Shared/Design/Palette.swift` — adaptive `UIColor` pairs |
| Share a habit as an image card | `WRITTEN` | `Ayas/Components/ShareCard.swift:7`, `:100` |
| Deep link from widget to habit | `WRITTEN` | `Shared/Model/DeepLink.swift:4`, `RootView.onOpenURL` |
| Reorder habits | `DECLINED` | No UI. Array order is the display order. |
| Backfill a missed day | `DECLINED` | Only today can be toggled. [DECISIONS.md](DECISIONS.md#d7) |

## Widget

| Feature | Status | Evidence |
| --- | --- | --- |
| Home Screen widget, small + medium | `WRITTEN` | `AyasWidget/HabitWidget.swift:8` |
| Shows habit, today's ayah, streak, done state | `WRITTEN` | `AyasWidget/HabitWidgetView.swift` |
| One-tap completion without opening the app | `WRITTEN` | `Shared/Intents/CompleteHabitIntent.swift:10` |
| Whole face turns green on completion | `WRITTEN` | `Shared/Design/Palette.swift:31`, `HabitWidgetView.background` |
| Per-widget habit selection | `WRITTEN` | `Shared/Intents/SelectHabitIntent.swift:9` |
| Advances at the day boundary unaided | `WRITTEN` | `AyasWidget/HabitTimelineProvider.swift:39` — 4 pre-rendered boundaries |
| Tapping the body opens the app on that habit | `WRITTEN` | `HabitWidgetView.widgetURL` |
| Un-complete from the widget | `DECLINED` | One-way by design. [DECISIONS.md](DECISIONS.md#d5) |
| Lock Screen accessory families | `PLANNED` | `Metrics` in `HabitWidgetView.swift` is the extension point |
| Large widget family | `PLANNED` | Same place |

## Content and sequences

| Feature | Status | Evidence |
| --- | --- | --- |
| Full Quran, 6,236 ayahs, Uthmani script | `WRITTEN` | `Shared/Content/Quran/ar.uthmani.txt` |
| English translation (Saheeh International) | `WRITTEN` | `Shared/Content/Quran/en.sahih.txt` |
| Surah metadata (name, meaning, counts) | `WRITTEN` | `Shared/Content/Quran/surahs.json` |
| Byte-offset random access | `WRITTEN` | `Shared/Content/QuranLibrary.swift` |
| Choose a starting surah/ayah | `WRITTEN` | `HabitEditorView.quranStart` |
| Wraps at the end of the Quran | `WRITTEN` | `Shared/Content/QuranLibrary.swift:65` |
| Generic numbered sequences (Page 1, 2, …) | `WRITTEN` | `Shared/Model/HabitSequence.swift:8` |
| Habits with no sequence | `WRITTEN` | `HabitSequence.none` |
| Additional translations | `PLANNED` | Drop in a `.txt`/`.idx` pair; see [QURAN_CONTENT.md](QURAN_CONTENT.md) |
| Arabic UI localisation | `PLANNED` | Strings are currently English literals |
| Audio recitation | `DECLINED` | Out of MVP scope |

## Storage and correctness

| Feature | Status | Evidence |
| --- | --- | --- |
| Single JSON document in an App Group | `WRITTEN` | `Shared/Store/DocumentStorage.swift:8` |
| Cross-process coordinated atomic writes | `WRITTEN` | `DocumentStorage` — `NSFileCoordinator` + `.atomic` |
| Fallback to local sandbox if group missing | `WRITTEN` | `DocumentStorage.init`, surfaced in Settings |
| Corrupt document quarantined, not destroyed | `WRITTEN` | `DocumentStorage.quarantine` |
| Forward-compatible decoding | `WRITTEN` | `AyasDocument.init(from:)`, enum decoders |
| App picks up widget writes on foreground | `WRITTEN` | `Shared/Store/HabitStore.swift:45`, `RootView.onChange(scenePhase)` |
| Streaks correct across DST / timezones | `WRITTEN` | `Shared/Model/DayKey.swift`, `AyasTests/DayKeyTests.swift` |
| Unit tests: day, streak, sequence, persistence | `WRITTEN` | `AyasTests/` — 4 files, never executed |
| iCloud sync | `DECLINED` | Out of MVP scope |
| Notifications | `DECLINED` | The widget *is* the reminder. [DECISIONS.md](DECISIONS.md#d2) |
| Accounts / backend | `DECLINED` | Fully offline by design |

## Explicitly not built

Login, accounts, backend, social graph, friends, leaderboards, achievements, gamification
beyond the streak, AI features, push notifications, subscriptions, paywall, cloud sync,
analytics, Apple Watch app, Android. All excluded deliberately from the MVP.

---

## Known gaps between docs and reality

- Nothing in this file has been observed working. The first Mac session should convert
  `WRITTEN` entries to a verified status as it confirms them, and record failures in
  [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
- Accessibility has labels on the main controls but has not been tested with VoiceOver or
  Dynamic Type. Treat as `PARTIAL`.
- No screenshots exist, because the app has never rendered. The design intent is recorded in
  [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).
