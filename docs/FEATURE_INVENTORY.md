# Feature inventory

Every feature, its status, and where the evidence is. Nothing here is claimed without a file
reference.

## Status vocabulary

| Status | Means |
| --- | --- |
| `TESTED` | Covered by a unit test that passes on CI. Evidenced. |
| `WRITTEN` | Implemented and compiles, but **never seen running**. |
| `PARTIAL` | Some of it exists; the gap is named. |
| `PLANNED` | Agreed as wanted, not started. Tracked in [ROADMAP.md](ROADMAP.md). |
| `DECLINED` | Deliberately excluded from the MVP. See [DECISIONS.md](DECISIONS.md). |

Everything here compiles — the build passes on CI. The 42 unit tests cover day boundaries,
streak logic, the Quran dataset and persistence, and those entries are marked `TESTED`.

**Nothing marked `WRITTEN` has ever been seen running.** No view has rendered, no widget has
appeared on a Home Screen. Treat those rows as claims to confirm in a simulator, not as
guarantees — [B1](KNOWN_ISSUES.md#b1).

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
| Streak, best streak, total days | `TESTED` | `Shared/Model/Habit.swift:80`, `:103`; `AyasTests/StreakTests.swift` |
| 14-day history strip | `PARTIAL` | Data `TESTED` (`Habit.swift:117`); the view never rendered |
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
| Full Quran, 6,236 ayahs, Uthmani script | `TESTED` | `AyasTests/SequenceTests.swift` round-trips every ayah |
| English translation (Saheeh International) | `TESTED` | same suite |
| Surah metadata (name, meaning, counts) | `TESTED` | same suite |
| Byte-offset random access | `TESTED` | same suite, plus a CI integrity check on the index |
| Choose a starting surah/ayah | `WRITTEN` | `HabitEditorView.quranStart` |
| Wraps at the end of the Quran | `TESTED` | `Shared/Content/QuranLibrary.swift:65` |
| Generic numbered sequences (Page 1, 2, …) | `TESTED` | `Shared/Model/HabitSequence.swift:8` |
| Habits with no sequence | `WRITTEN` | `HabitSequence.none` |
| Additional translations | `PLANNED` | Drop in a `.txt`/`.idx` pair; see [QURAN_CONTENT.md](QURAN_CONTENT.md) |
| Arabic UI localisation | `PLANNED` | Strings are currently English literals |
| Audio recitation | `DECLINED` | Out of MVP scope |

## Storage and correctness

| Feature | Status | Evidence |
| --- | --- | --- |
| Single JSON document in an App Group | `TESTED` | `AyasTests/PersistenceTests.swift` |
| Cross-process coordinated atomic writes | `TESTED` | same suite, two stores over one file |
| Fallback to local sandbox if group missing | `WRITTEN` | `DocumentStorage.init`, surfaced in Settings |
| Corrupt document quarantined, not destroyed | `TESTED` | same suite |
| Forward-compatible decoding | `TESTED` | same suite — unknown enums and missing keys |
| App picks up widget writes on foreground | `TESTED` | same suite; the bug it caught is [R4](KNOWN_ISSUES.md) |
| Streaks correct across DST / timezones | `TESTED` | `AyasTests/DayKeyTests.swift` |
| Unit tests: day, streak, sequence, persistence | `TESTED` | 42 tests, 4 suites, green on CI |
| iCloud sync | `DECLINED` | Out of MVP scope |
| Notifications | `DECLINED` | The widget *is* the reminder. [DECISIONS.md](DECISIONS.md#d2) |
| Accounts / backend | `DECLINED` | Fully offline by design |

## Explicitly not built

Login, accounts, backend, social graph, friends, leaderboards, achievements, gamification
beyond the streak, AI features, push notifications, subscriptions, paywall, cloud sync,
analytics, Apple Watch app, Android. All excluded deliberately from the MVP.

---

## Known gaps between docs and reality

- **No `WRITTEN` row has been observed working.** That covers every screen, every gesture and
  the whole widget. Converting them is the next session's main job
  ([B1](KNOWN_ISSUES.md#b1)).
- Accessibility has labels on the main controls but has not been tested with VoiceOver or
  Dynamic Type. Treat as `PARTIAL`.
- No screenshots exist, because the app has never rendered. The design intent is recorded in
  [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).
