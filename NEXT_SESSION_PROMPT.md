# Next session prompt

Paste everything in the block below into Claude Code, started from the repository root on the
MacBook. It is written to be used as-is.

---

```
You are picking up an existing iOS project. It has never been compiled — read that
sentence twice, because most of what you do first follows from it.

CONTEXT
Ayas is a native Swift + SwiftUI + WidgetKit app for iOS 17. Its whole premise is a Home
Screen widget showing one tiny daily action — the shipped example is reading one Quran
ayah a day — completed with a single tap, held together by a streak. It has no
dependencies, no backend, and makes no network calls.

It was written entirely on Windows, where no Swift or iOS toolchain exists. So the source
is complete and the Xcode project is generated and structurally validated, but no
compiler has ever read it and nothing has ever run. You are on a Mac. You can do things
the original author could not, and that is the point of this session.

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

STEP 4 — FIRST BUILD
  xcodebuild -project Ayas.xcodeproj -scheme Ayas \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    CODE_SIGNING_ALLOWED=NO build

This will almost certainly fail. That is expected and is the most valuable work available
on this project right now. docs/KNOWN_ISSUES.md section B1 lists the likely error classes.

Fix compile errors conservatively:
  - correct the error, do not redesign around it
  - do not replace architecture, swap persistence, or add dependencies
  - do not delete tests to make a build pass
  - if a fix requires a real design decision, stop and ask rather than choosing silently
Work top-down, rebuild often, and keep a note of what you changed and why.

STEP 5 — TESTS
  xcodebuild -project Ayas.xcodeproj -scheme Ayas \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    CODE_SIGNING_ALLOWED=NO test

Four suites cover day boundaries, streaks, the Quran sequence and persistence. Report
results exactly as they come out. SequenceTests validates the bundled scripture against
known references — treat a failure there as serious.

STEP 6 — RUN IT
Launch in the simulator, create a habit, add the widget, and walk the checklist in
docs/MAC_SETUP.md section 6. Specifically confirm:
  - Arabic renders right to left without clipped diacritics
  - tapping the widget ring completes without launching the app
  - the completed widget turns green
  - rolling the simulator clock forward a day clears the completion and keeps the same
    ayah (missing a day must not skip content)

STEP 7 — REPORT
Tell me plainly:
  1. Does it build? Quote the actual result.
  2. Do the tests pass? Which, and what failed.
  3. Does the core loop work end to end in the simulator?
  4. What is broken, ranked by severity.
  5. What you changed to get there.
Never describe a build or test as passing unless you ran it and can quote the output.

STEP 8 — UPDATE THE RECORD
In the same commits as your fixes:
  - docs/FEATURE_INVENTORY.md — convert WRITTEN entries to what you actually observed
  - docs/KNOWN_ISSUES.md — close B1 if it builds; add what you found
  - CLAUDE.md — the "never been compiled" section is the first thing to stop being true
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
- If the build is already green when you start, say so — the prompt assumes it is not, and
  the session should jump to [ROADMAP.md](docs/ROADMAP.md) tier 1 instead.
- For device work rather than the simulator, hand over
  [docs/MAC_SETUP.md](docs/MAC_SETUP.md) section 7 as well, and note that App Groups on a
  physical device likely needs the paid Apple Developer Program.
