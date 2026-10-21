# Context index

Where to find anything. If a question is not answered somewhere below, it was not recorded —
say so rather than guessing.

## Start here

| If you are | Read, in order |
| --- | --- |
| A developer picking this up | [HANDOVER.md](HANDOVER.md) → [../CLAUDE.md](../CLAUDE.md) → [MAC_SETUP.md](MAC_SETUP.md) |
| A Claude Code session | [../CLAUDE.md](../CLAUDE.md) → [HANDOVER.md](HANDOVER.md) → [../NEXT_SESSION_PROMPT.md](../NEXT_SESSION_PROMPT.md) |
| Deciding what to build next | [ROADMAP.md](ROADMAP.md) → [KNOWN_ISSUES.md](KNOWN_ISSUES.md) |
| Evaluating the product | [PRODUCT_VISION.md](PRODUCT_VISION.md) → [USER_JOURNEYS.md](USER_JOURNEYS.md) |

## By question

| Question | Document |
| --- | --- |
| What is this product and who is it for? | [PRODUCT_VISION.md](PRODUCT_VISION.md) |
| What actually exists, with evidence? | [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md) |
| What are all the user flows? | [USER_JOURNEYS.md](USER_JOURNEYS.md) |
| How is the code organised? | [ARCHITECTURE.md](ARCHITECTURE.md) |
| How does the widget work? | [WIDGETS.md](WIDGETS.md) |
| Where does the Quran text come from? Can we ship it? | [QURAN_CONTENT.md](QURAN_CONTENT.md) |
| What are the colours, type, components? | [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) |
| Why is it built this way? | [DECISIONS.md](DECISIONS.md) |
| What is broken or unknown? | [KNOWN_ISSUES.md](KNOWN_ISSUES.md) |
| What should I work on? | [ROADMAP.md](ROADMAP.md) |
| How do I run it on a Mac? | [MAC_SETUP.md](MAC_SETUP.md) |
| What is needed to ship? | [IOS_RELEASE.md](IOS_RELEASE.md) |
| What is the state of the handover? | [HANDOVER.md](HANDOVER.md) |
| What rules must I follow while working? | [../CLAUDE.md](../CLAUDE.md) |
| Who owns the bundled Quran text? | [../NOTICE.md](../NOTICE.md) |

## By code area

| Topic | Source | Documented in |
| --- | --- | --- |
| Day boundaries, DST, timezones | `Shared/Model/DayKey.swift` | [ARCHITECTURE.md](ARCHITECTURE.md#time) |
| Streak calculation | `Shared/Model/Habit.swift` | [ARCHITECTURE.md](ARCHITECTURE.md#derived-never-stored), [D11](DECISIONS.md#d11) |
| Sequence / which ayah today | `Shared/Model/HabitSequence.swift` | [QURAN_CONTENT.md](QURAN_CONTENT.md#sequence-behaviour), [D6](DECISIONS.md#d6) |
| Derived view state | `Shared/Model/HabitSnapshot.swift` | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Persistence | `Shared/Store/DocumentStorage.swift` | [ARCHITECTURE.md](ARCHITECTURE.md#data-flow), [D4](DECISIONS.md#d4) |
| App group resolution | `Shared/Store/AppGroup.swift` | [MAC_SETUP.md](MAC_SETUP.md), [H2](KNOWN_ISSUES.md#h2) |
| Mutation and widget reload | `Shared/Store/HabitStore.swift` | [ARCHITECTURE.md](ARCHITECTURE.md#data-flow) |
| Quran file access | `Shared/Content/QuranLibrary.swift` | [QURAN_CONTENT.md](QURAN_CONTENT.md#why-the-offset-index) |
| Widget completion intent | `Shared/Intents/CompleteHabitIntent.swift` | [WIDGETS.md](WIDGETS.md#completing-from-the-widget), [D5](DECISIONS.md#d5) |
| Per-widget habit selection | `Shared/Intents/SelectHabitIntent.swift` | [WIDGETS.md](WIDGETS.md#per-widget-habit-selection) |
| Timeline construction | `AyasWidget/HabitTimelineProvider.swift` | [WIDGETS.md](WIDGETS.md#timeline) |
| Widget appearance / the green | `AyasWidget/HabitWidgetView.swift` | [WIDGETS.md](WIDGETS.md#the-face), [D9](DECISIONS.md#d9) |
| Colours and type | `Shared/Design/Palette.swift`, `Typography.swift` | [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) |
| Animation and spacing | `Shared/Design/Motion.swift` | [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md#space-radius-motion) |
| Navigation, deep links, scene phase | `Ayas/RootView.swift` | [USER_JOURNEYS.md](USER_JOURNEYS.md) |
| Share cards | `Ayas/Components/ShareCard.swift` | [D14](DECISIONS.md#d14), [J6](USER_JOURNEYS.md#j6) |

## Configuration and tooling

| File | Purpose | Edit it? |
| --- | --- | --- |
| `Config/Ayas.xcconfig` | Bundle prefix, app group, version | **Yes** — per developer. The only place these live. No secrets |
| `Ayas/Info.plist`, `AyasWidget/Info.plist` | Bundle metadata, URL scheme, app group key | Rarely |
| `Ayas/Ayas.entitlements`, `AyasWidget/AyasWidget.entitlements` | App Groups capability | Via Xcode's Signing & Capabilities |
| `Ayas.xcodeproj/project.pbxproj` | The project | **No** — generated |
| `.gitattributes` | Pins Quran files as binary | **No** — see [CLAUDE.md](../CLAUDE.md) rule 2 |
| `Tools/generate_xcodeproj.py` | Rebuilds the project from the file tree | When target structure changes |
| `Tools/verify_project.py` | Validates the generated project | — |
| `Tools/build_quran.py` | Regenerates the dataset. Needs network | Only to change the dataset |
| `.github/workflows/ios.yml` | CI: verify + simulator build + tests | When the build invocation changes |

There are **no secret files**: no `.env`, no API keys, no certificates, no provisioning
profiles, nothing gitignored that is needed to build. A fresh clone plus Xcode is sufficient
for the simulator.

## What is deliberately not recorded anywhere

- Conversation history from the original build session. The docs were reconstructed from the
  code in October 2026; where something could not be verified from the code, it says so.
- Screenshots. None exist — the app has never rendered
  ([L3](KNOWN_ISSUES.md#l3)).
- Performance characteristics. Nothing has been profiled.
- Any claim about what the app does at runtime. Nothing has run.
