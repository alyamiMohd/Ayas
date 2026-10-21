# Roadmap

Ordered by what unblocks the most. Everything in tier 0 must finish before anything else
starts — until the app compiles, no other work can be verified.

Status vocabulary matches [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md).

---

## Tier 0 — Make it real

Nothing else matters until these are done. The build and tests are green on CI; what remains
is everything that needs the app actually running.

| # | Work | Why | Est. |
| --- | --- | --- | --- |
| ~~0.1~~ | ~~Get it to compile~~ | ✅ Done 21 Oct 2026. One compile error in 39 files | — |
| ~~0.2~~ | ~~Run the unit tests~~ | ✅ Done. 42 / 42 green, and they found a real data-loss bug | — |
| 0.3 | **Run in the simulator, add a widget** | **Start here.** First proof the core loop exists | ~1 hour |
| 0.4 | **Walk the verification checklist** | [MAC_SETUP.md](MAC_SETUP.md#verification-checklist) | ~1 hour |
| 0.5 | **Update docs with what is actually true** | Convert `WRITTEN` to verified; record real failures | Ongoing |
| 0.6 | **Take screenshots, add to README** | [L3](KNOWN_ISSUES.md#l3) | ~30 min |
| 0.7 | **Tag `v0.6`** | First tag with a verified build — [M4](KNOWN_ISSUES.md#m4) | Minutes |

## Tier 1 — Make it trustworthy

Once it runs, these are the things that decide whether it survives real use.

| # | Work | Why |
| --- | --- | --- |
| 1.1 | **Live with it for a week on a real device** | The only way to test the day rollover, the streak and the widget's refresh budget honestly. Not simulable |
| 1.2 | **Verify Arabic rendering properly** | [M2](KNOWN_ISSUES.md#m2). Check 2:282 on a small widget, long surah names, the share card |
| 1.3 | **Resolve the content licence** | [H1](KNOWN_ISSUES.md#h1). Blocks release. Decide before investing in store assets |
| 1.4 | **Fix whatever a week of use surfaces** | — |
| 1.5 | **Accessibility pass** | [M3](KNOWN_ISSUES.md#m3). VoiceOver first; Dynamic Type is a bigger design question |

## Tier 2 — Fill the obvious gaps

Small, well-understood work that makes the app feel finished.

| # | Work | Notes |
| --- | --- | --- |
| 2.1 | Green completion in the app, not just the widget | [L5](KNOWN_ISSUES.md#l5). Or decide the accents are right and close it |
| 2.2 | Share from a Today row | [L2](KNOWN_ISSUES.md#l2). Context menu, one tap instead of two |
| 2.3 | Lock Screen accessory widgets | `Metrics` in `HabitWidgetView` is the extension point. Needs a monochrome treatment |
| 2.4 | Large widget family | Same place. Room for several days of context |
| 2.5 | Reorder habits | `HabitStore` would need `move`; it was removed as unused. Drag on the Today list |
| 2.6 | `ITSAppUsesNonExemptEncryption` in Info.plist | Saves answering the export question on every upload — [IOS_RELEASE.md](IOS_RELEASE.md) |

## Tier 3 — Product questions

Not obviously right. Each needs a decision before code.

| # | Idea | The question |
| --- | --- | --- |
| 3.1 | Additional translations | Which, and licensed how? [QURAN_CONTENT.md](QURAN_CONTENT.md) |
| 3.2 | Arabic UI localisation | Full RTL layout, not just RTL text. Significant work |
| 3.3 | Non-daily rhythms | Weekly, or n-times-a-week. Contradicts "not up for negotiation" — [PRODUCT_VISION.md](PRODUCT_VISION.md) |
| 3.4 | Backfilling a missed day | Contradicts [D7](DECISIONS.md#d7). Users will ask for it |
| 3.5 | Notifications | Explicitly declined — [D2](DECISIONS.md#d2). Revisit only with evidence the widget is not enough |
| 3.6 | iCloud sync | Means a second source of truth and conflict resolution. Only if people want it across devices |

## Tier 4 — Release

Sequenced in [IOS_RELEASE.md](IOS_RELEASE.md). Do not start before tier 1 closes, especially
1.3.

---

## Explicitly not planned

Accounts, backend, social features, friends, leaderboards, achievements, gamification beyond
the streak, AI, subscriptions, paywall, analytics, Apple Watch app, Android. See
[PRODUCT_VISION.md](PRODUCT_VISION.md#deliberate-non-goals).

## How to use this file

Work top-down. When you finish something, move it out and record the outcome in
[FEATURE_INVENTORY.md](FEATURE_INVENTORY.md) or [KNOWN_ISSUES.md](KNOWN_ISSUES.md). When you
add something, say which tier and why it belongs there.
