# Handover

For the developer picking this up, and for the first Claude Code session on their machine.
Read this, then [CLAUDE.md](../CLAUDE.md), then start at
[MAC_SETUP.md](MAC_SETUP.md).

## Where the project stands, honestly

**Ayas is a complete iOS MVP in source form that has never been compiled.**

~4,100 lines of Swift across 39 files, three Xcode targets, the full Quran bundled locally,
unit tests, and a generated-and-validated project file. Also: zero evidence that any of it
runs, because it was written on Windows where no Swift or iOS toolchain exists.

That is the whole situation. Everything below follows from it.

| | |
| --- | --- |
| Stack | Native Swift + SwiftUI + WidgetKit, iOS 17, Swift 5 mode |
| Dependencies | **None.** No SPM, CocoaPods or Carthage |
| Targets | `Ayas` (app), `AyasWidgetExtension` (widget), `AyasTests` (unit tests) |
| Repository | `alyamiMohd/Ayas`, private, branch `main` |
| Build status | **Never attempted.** See [B1](KNOWN_ISSUES.md#b1) |
| Test status | **Never executed.** 4 test files exist |
| Release status | Nothing published. No Apple account enrolled |

### What is written

The whole core loop. A Today screen, habit detail, create/edit, settings, empty state. A
Home Screen widget in two sizes that completes in place with one tap, turns green when done,
and advances to the next day without the app running. Multiple habits, each with its own
widget. Streaks that survive midnight, timezone changes and DST. The complete Quran, 6,236
ayahs, read by byte offset so the widget never parses a megabyte. Shareable progress cards.

Itemised with file references in [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md).

### What is not

No screenshots, because nothing has rendered. No verified behaviour of any kind. An
unresolved licence on the bundled translation that blocks public release. Accessibility only
partially addressed. Full list in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## The first three hours

In this order. Do not skip ahead — the rest of the project is unverifiable until step 3.

1. **Set up and clone** — [MAC_SETUP.md](MAC_SETUP.md) sections 1–3. Confirm
   `python3 Tools/verify_project.py` passes before opening Xcode.
2. **Attempt a build.** It will fail; that is expected and is the single most valuable thing
   you can do to this project. The likely error classes are listed in
   [B1](KNOWN_ISSUES.md#b1).
3. **Run the tests** (⌘U). `SequenceTests` validates the bundled scripture, which is the
   content least safe to get wrong.
4. **Run in the simulator and add a widget** — [MAC_SETUP.md](MAC_SETUP.md#widget-verification).
5. **Update the docs** with what actually happened. Convert `WRITTEN` entries, record real
   failures. A stale doc is worse than none, because the next session will trust it.

Then [ROADMAP.md](ROADMAP.md) tier 1.

## What you must not do

These are load-bearing. Each has a reason recorded in [DECISIONS.md](DECISIONS.md).

- **Do not hand-edit `Ayas.xcodeproj`.** It is generated from the file tree. Add a file, then
  run `python3 Tools/generate_xcodeproj.py`. Editing through Xcode's UI will be overwritten.
- **Do not touch `Shared/Content/Quran/*.txt` or `*.idx`.** They are byte-offset paired. Any
  edit or line-ending change silently corrupts every subsequent ayah.
- **Do not add a cached streak or current-ayah field.** All derived state is computed from
  completion history on read. The widget's ability to render a future day correctly depends
  on that being a pure function.
- **Do not hardcode the bundle ID or app group.** `Config/Ayas.xcconfig` is the only place.
- **Do not report a build or test as passing without running it.** The previous author could
  not, and said so everywhere. Keep that standard.

## What the previous author could not do

Everything that requires macOS: compile, run, test, screenshot, profile, use Instruments,
check Arabic rendering, verify the widget, touch a real device.

So the balance of value is unusual. Right now a single real build result is worth more to
this project than a week of new features.

## Decisions you may want to revisit

Not bugs — judgement calls where a reasonable person could differ. Full reasoning in
[DECISIONS.md](DECISIONS.md):

- Widget completion is **one-way**; undo only exists in the app ([D5](DECISIONS.md#d5))
- Only **today** can be completed; no backfilling ([D7](DECISIONS.md#d7))
- The Xcode project is **generated**, not Xcode-owned ([D8](DECISIONS.md#d8))
- Every habit completes in the **same green** on the widget ([D9](DECISIONS.md#d9))
- The app's own completed states are **not** green ([L5](KNOWN_ISSUES.md#l5))
- State is a **JSON document**, not SwiftData ([D4](DECISIONS.md#d4))

## Open questions needing the owner, not the developer

1. **The content licence** — ship Arabic only, swap the translation, or seek permission?
   [H1](KNOWN_ISSUES.md#h1). This blocks
   release and should be decided early.
2. **Is release the goal**, or is this for personal use? Changes whether the $99 program and
   tier 4 matter at all.
3. **The repository name.** `Ayas` is not self-describing cold. Renaming on GitHub preserves
   history ([D16](DECISIONS.md#d16)).

## Provenance

Built in a single session in September 2026 by the project owner working with Claude, on
Windows. Two commits plus a `v0.5` tag; this handover adds a third. There is no older
repository, no prior codebase, and no earlier history that was lost — `a84040d` is genuinely
the first commit.

All documentation in `docs/` was written in October 2026 from the code itself, not from
memory of conversations. Where something could not be verified from the code, it says so.

## Everything else

[CONTEXT_INDEX.md](CONTEXT_INDEX.md) maps every topic to the file that covers it.
