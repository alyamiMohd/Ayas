# User journeys

Every flow the app supports, as sequences of real screens and controls. Screen names match
the files in `Ayas/Screens/`.

---

## J1 — First run

```
Launch  →  Today (empty state)
           "Start ridiculously small."
           ├─ [Read one ayah a day]  → Habit editor, prefilled with the Quran template
           └─ [Something else]       → Habit editor, blank
                                        ↓
                                    [Create]
                                        ↓
                                    Today, one habit
```

The quick path is the point: one tap produces a working Quran habit starting at 1:1. The
editor still opens so the choice is visible and editable, not magic.

**Code:** `EmptyStateView` → `RootView.sheetContent(.create)` → `HabitEditorView`.

---

## J2 — The daily loop, from the Home Screen

```
Home Screen
   widget shows:  QURAN · today's ayah · "6 days" · ◯
       ↓ read the ayah
   tap ◯
       ↓ (intent runs inside the widget extension; app never launches)
   widget turns green:  ✓ "Completed today" · "7 days"
```

This is the journey the product exists for. No app launch, no navigation, no confirmation.

**Code:** `HabitWidgetView.control` → `CompleteHabitIntent.perform` → `HabitStore.complete`.
Detail in [WIDGETS.md](WIDGETS.md).

---

## J3 — The daily loop, in the app

```
Today
  row:  ◯  Quran
           Read one ayah · 6 days
           AL-BAQARA · 255
   ├─ tap ◯          → fills, haptic, streak becomes 7
   └─ tap the row    → Habit detail
```

Tapping the ring and tapping the row are deliberately different targets: completing is the
common act and must not require navigating anywhere.

**Code:** `TodayView` → `HabitRow` (two sibling buttons).

---

## J4 — Reading properly

```
Today  →  tap a habit row  →  Habit detail
                              ├─ today's ayah, full, with translation
                              ├─ [◯ Mark today done]  ↔  [✓ Completed today · Undo]
                              ├─ streak, best, total, 14-day strip
                              ├─ [↑]  → J6
                              └─ [✎]  → J5
```

Undo lives here and only here — the widget cannot un-complete ([D5](DECISIONS.md#d5)).

**Code:** `HabitDetailView`.

---

## J5 — Creating or editing a habit

```
Habit editor
  ├─ Habit          "Quran"
  ├─ Tiny action    "Read one ayah"
  ├─ Colour         six accents
  ├─ Mark           twelve glyphs
  ├─ Daily content  [Nothing] [Quran] [Counting]
  │                   Quran   → Starts at → surah + ayah pickers
  │                   Counting→ Unit ("Page") + starting number
  ├─ Rhythm         Every day (fixed)
  └─ [Delete habit] → "Delete this habit and its history?" → [Delete] [Keep it]
```

Reached as a sheet from the Today screen's **Add a habit** row or the detail screen's ✎.

**Code:** `HabitEditorView`, modes `.create` / `.edit`.

---

<a id="j6"></a>

## J6 — Sharing progress

```
Habit detail  →  [↑]
                  ↓ (card already rendered off-screen)
              iOS share sheet
                  ├─ Messages / WhatsApp / Instagram / Mail
                  └─ Save Image / Copy Photo
```

There is no share *screen* — the sheet is the system's. The card is a square image carrying
the habit, streak, the last fourteen days and today's reference.

**Code:** `HabitDetailView.shareControl` → `ShareCardRenderer.image` → `ShareLink`.

---

## J7 — Multiple habits, multiple widgets

```
Today  →  Add a habit  →  …  →  three habits

Home Screen
  long-press  →  +  →  Ayas  →  size  →  Add Widget
  long-press widget  →  Edit Widget  →  pick which habit
  (repeat per habit)
```

Each widget instance carries its own `SelectHabitIntent`. An unconfigured widget shows the
first habit rather than an empty prompt.

---

## J8 — A new day

```
00:00 (or the configured boundary)
  ↓ no process runs
widget swaps to a pre-rendered entry
  ├─ completion cleared
  ├─ same ayah if yesterday was missed, next ayah if it was done
  └─ streak recomputed for the new day
```

Opening the app is never required. [WIDGETS.md](WIDGETS.md#timeline).

---

## J9 — Breaking a streak

```
Day 1-6   completed        → "6 days"
Day 7     not completed    → still "6 days" all day (grace while today is open)
Day 8     morning          → "No streak yet"
Day 8     completed        → "1 day"; best streak remembers 6
```

[D11](DECISIONS.md#d11). The content does not skip: day 8 shows the ayah day 7 would have.

---

## J10 — Settings

```
Today  →  [≡]  →  Settings
                  ├─ Appearance            System / Light / Dark
                  ├─ A new day begins at   12 / 1 / 2 / 3 / 4
                  ├─ Show translation      toggle
                  ├─ Haptics               toggle
                  └─ Erase all data        → confirm
```

Also where the app reports an unreachable App Group container.

**Code:** `SettingsView`.

---

## Journeys that do not exist

Onboarding carousel, sign-in, habit archiving, reordering, backfilling a missed day,
editing history, exporting data, a stats screen. Several are deliberate exclusions —
[FEATURE_INVENTORY.md](FEATURE_INVENTORY.md).
