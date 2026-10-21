# Ayas

**One tiny thing a day, kept where you already look.**

An iOS app built around a single loop: see a small daily action on your Home Screen widget,
do it, tap once, keep the thread going. The habit it ships with is reading one Quran ayah a
day — but the sequence model is generic, and a habit can be a page of a book, ten pushups, or
nothing at all.

The widget is not an accessory here. It is the product. Everything else exists to support it.

---

## Status

> ### It builds and its tests pass — but it has never been launched.
>
> CI compiles both targets and runs all 42 unit tests on every push. What has never happened
> is the app actually running: no screen has been rendered, no Arabic text laid out, no
> widget placed on a Home Screen.
>
> **Launching it in a simulator and adding a widget is the first and most valuable job.**
> See [docs/MAC_SETUP.md](docs/MAC_SETUP.md#widget-verification).

| | |
| --- | --- |
| Stack | Swift · SwiftUI · WidgetKit · App Intents |
| Minimum | iOS 17 · Xcode 15 |
| Dependencies | **None** |
| Source | 39 Swift files, ~4,100 lines |
| Build | ✅ Passing — Xcode 15.4, iOS 17.5 SDK |
| Tests | ✅ 42 / 42 passing across 4 suites |
| Runtime | ❌ Never launched. No screenshots exist |
| Release | Nothing published |

The visual design is specified in [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) until real
screenshots exist.

---

## Quick start

```bash
git clone https://github.com/alyamiMohd/Ayas.git
cd Ayas
python3 Tools/verify_project.py     # confirms the project file is sound
open Ayas.xcodeproj                 # scheme: Ayas · destination: any iPhone simulator · ⌘R
```

Full walkthrough, including widgets, entitlements and a physical device:
**[docs/MAC_SETUP.md](docs/MAC_SETUP.md)**.

Picking this project up cold? Start with **[docs/HANDOVER.md](docs/HANDOVER.md)**.
Using Claude Code? Paste **[NEXT_SESSION_PROMPT.md](NEXT_SESSION_PROMPT.md)**.

---

## What it does

- **Today** — the day's habits as quiet rows. A ring to complete, the tiny action, the streak.
- **Habit detail** — today's ayah in full with translation, one control to complete it, and
  just enough history to show continuity.
- **The widget** — small and medium. Shows the ayah, the streak and whether today is done.
  One tap completes it **in place, without opening the app**, and the whole face turns green.
  It advances to the next day on its own, with no process running.
- **Multiple habits** — each can have its own widget, pointed at it by long-pressing and
  editing the widget.
- **Sharing** — any habit renders to a square card for Messages, WhatsApp or Instagram.
- **The Quran, offline** — all 6,236 ayahs in Uthmani script with an English translation,
  bundled locally. The app makes no network calls of any kind.

Itemised with file references: [docs/FEATURE_INVENTORY.md](docs/FEATURE_INVENTORY.md).

## How it is built

```
Shared/          compiled into BOTH the app and the widget
  Model/         DayKey, Habit, sequences, the persisted document
  Store/         app group, atomic coordinated storage, the one mutation point
  Content/       QuranLibrary + the bundled dataset
  Intents/       App Intents for completion and widget configuration
  Design/        colour, type, motion, the completion mark
Ayas/            the app — screens, components, navigation
AyasWidget/      the WidgetKit extension
AyasTests/       day boundaries, streaks, sequences, persistence
Tools/           project generator, validator, dataset builder
```

Three ideas carry most of the weight:

1. **One source of truth.** A single JSON document in an App Group, written by both the app
   and the widget through `NSFileCoordinator`, atomically.
2. **Everything derived.** Only completion history is stored. Streaks and sequence position
   are pure functions of it — which is exactly why the widget can render *tomorrow* correctly
   while nothing is running.
3. **The project file is generated** from the file tree by `Tools/generate_xcodeproj.py`, so
   it cannot silently drift from the files on disk.

More: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · [docs/WIDGETS.md](docs/WIDGETS.md)

---

## ⚠️ Before any public release

The bundled Quran text has an **unresolved licensing question** that blocks App Store
release. Fine for personal use; not settled for distribution. Read
[docs/QURAN_CONTENT.md](docs/QURAN_CONTENT.md) before investing in store assets.

---

## Documentation

| | |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | Operating rules for Claude Code sessions |
| [docs/HANDOVER.md](docs/HANDOVER.md) | Where the project stands, and the first three hours |
| [docs/CONTEXT_INDEX.md](docs/CONTEXT_INDEX.md) | Map of everything |
| [docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md) | What this is and who it is for |
| [docs/FEATURE_INVENTORY.md](docs/FEATURE_INVENTORY.md) | Every feature, with evidence |
| [docs/USER_JOURNEYS.md](docs/USER_JOURNEYS.md) | Every flow |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Code organisation and data flow |
| [docs/WIDGETS.md](docs/WIDGETS.md) | WidgetKit, timelines, deep links |
| [docs/QURAN_CONTENT.md](docs/QURAN_CONTENT.md) | Data, correctness, licensing |
| [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) | Colour, type, components |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Why things are the way they are |
| [docs/ROADMAP.md](docs/ROADMAP.md) | What to build next |
| [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) | Bugs, blockers, debt |
| [docs/MAC_SETUP.md](docs/MAC_SETUP.md) | Zero to running on a Mac |
| [docs/IOS_RELEASE.md](docs/IOS_RELEASE.md) | Signing, TestFlight, App Store |

## Working on it

```bash
python3 Tools/generate_xcodeproj.py   # after adding or removing any source file
python3 Tools/verify_project.py       # validate the result
```

Two rules that will bite you otherwise:

- **Never hand-edit `Ayas.xcodeproj`** — it is generated. Adding a file through Xcode's UI
  will be overwritten.
- **Never edit `Shared/Content/Quran/*.txt` or `*.idx`** — they are byte-offset paired, and
  any edit or line-ending change silently corrupts the scripture.

Full rules: [CLAUDE.md](CLAUDE.md).
