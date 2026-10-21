# Next session prompt

Paste everything in the block below into Claude Code, started from the repository root on the
MacBook. It is written to be used as-is.

---

```
You are picking up an existing iOS project. It compiles and its 42 unit tests pass on
CI, but it has never actually been launched — no view has ever rendered and no widget has
ever appeared on a Home Screen. Most of what you do first follows from that distinction.

CONTEXT
Ayas is a native Swift + SwiftUI + WidgetKit app for iOS 17. Its whole premise is a Home
Screen widget showing one tiny daily action — the shipped example is reading one Quran
ayah a day — completed with a single tap, held together by a streak. It has no
dependencies, no backend, and makes no network calls.

It was written entirely on Windows, where no Swift or iOS toolchain exists. CI has since
closed the build and unit-test half of that gap. What is still completely unverified is
the running app: every screen, Arabic text layout, the widget, deep links, the share card.
You are on a Mac, so you can do what the original author could not. That is the point of
this session.

STEP 1 — ORIENT
Read, in this order:
  CLAUDE.md                   operating rules for this repo — follow them exactly
  docs/HANDOVER.md            where the project actually stands
  docs/CONTEXT_INDEX.md       map of everything else
Then skim docs/ARCHITECTURE.md, docs/WIDGETS.md and docs/KNOWN_ISSUES.md.

Do not take the documentation on trust. It was written from the code, but the code has
never run. Where a doc and the code disagree, the code wins — then fix the doc.

STEP 2 — INSPECT
Check the actual repository and the local environment:
  - git log, git status, the file tree
  - xcodebuild -version, available simulators, Python 3
  - confirm Shared/Content/Quran/ holds 5 files, ~2.2 MB
Report anything that contradicts the docs.

STEP 3 — VALIDATE THE PROJECT FILE
  python3 Tools/verify_project.py
Expect "OK: project is internally consistent" and three targets. If it fails, run
Tools/generate_xcodeproj.py and re-verify. Do not hand-edit the .xcodeproj — it is
generated from the file tree.

STEP 4 — BUILD
  xcodebuild -project Ayas.xcodeproj -scheme Ayas \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    CODE_SIGNING_ALLOWED=NO build

This passes on CI (Xcode 15.4, iOS 17.5 SDK). If it fails for you, something about this
machine differs — report that rather than working around it.

If you do need to fix anything, fix it conservatively:
  - correct the error, do not redesign around it
  - do not replace architecture, swap persistence, or add dependencies
  - do not delete tests to make a build pass
  - if a fix requires a real design decision, stop and ask rather than choosing silently

STEP 5 — TESTS
  xcodebuild -project Ayas.xcodeproj -scheme Ayas \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    CODE_SIGNING_ALLOWED=NO test

Four suites cover day boundaries, streaks, the Quran sequence and persistence. Report
results exactly as they come out. SequenceTests validates the bundled scripture against
known references — treat a failure there as serious.

STEP 6 — RUN IT  <<< THIS IS THE REAL WORK OF THIS SESSION
Nobody has ever launched this app. Everything up to here is already green on CI; this step
is entirely new ground. Launch in the simulator, create a habit, add the widget, and walk
the checklist in docs/MAC_SETUP.md section 6. Specifically confirm:
  - Arabic renders right to left without clipped diacritics
  - tapping the widget ring completes without launching the app
  - the completed widget turns green
  - rolling the simulator clock forward a day clears the completion and keeps the same
    ayah (missing a day must not skip content)

STEP 7 — REPORT
Tell me plainly:
  1. Does it still build here? Quote the actual result.
  2. Do the tests pass? Which, and what failed.
  3. Does the core loop work end to end in the simulator? This is the new information.
  4. How does the Arabic actually look?
  5. What is broken, ranked by severity.
  6. What you changed to get there.
Never describe anything as working unless you ran it and can quote or describe what you
actually saw. Screenshots are welcome — none exist yet.

STEP 8 — UPDATE THE RECORD
In the same commits as your fixes:
  - docs/FEATURE_INVENTORY.md — convert WRITTEN rows to what you actually observed
  - docs/KNOWN_ISSUES.md — close B1 once you have run it; add what you found
  - CLAUDE.md — the "it has never run" section is the next thing to stop being true
  - README.md — add real screenshots
  - docs/DECISIONS.md — only if you made a real decision, with the reasoning

STEP 9 — CONTINUE
Work from docs/ROADMAP.md, top-down. Do not redesign the product, invent requirements, or
add features that are not on it. The existing decisions in docs/DECISIONS.md are
deliberate; argue with them explicitly if you disagree, but do not quietly replace them.

CONSTRAINTS
  - Preserve the existing stack and architecture unless something genuinely cannot work.
  - Add no third-party dependencies.
  - Never edit Shared/Content/Quran/*.txt or *.idx — they are byte-offset paired and any
    edit or line-ending change silently corrupts the scripture.
  - Never add a cached streak or current-ayah field; all derived state is computed from
    completion history on read, and the widget depends on that being a pure function.
  - Bundle ID and app group live only in Config/Ayas.xcconfig.
  - Do not publish, deploy, or submit anything.
  - There is an unresolved licensing question on the bundled Quran translation that blocks
    public release — see docs/QURAN_CONTENT.md. Do not treat it as a detail.

Start with Step 1.
```

---

## Notes for whoever pastes this

- Run Claude Code from the repository root, so it can read the files the prompt names.
- The build is green as of 21 October 2026. If it is not for you, that is itself the first
  finding worth reporting.
- For device work rather than the simulator, hand over
  [docs/MAC_SETUP.md](docs/MAC_SETUP.md) section 7 as well, and note that App Groups on a
  physical device likely needs the paid Apple Developer Program.
