# Release requirements

Everything needed to get from a working build to the App Store. **Do not start this before
[ROADMAP.md](ROADMAP.md) tier 1 closes** — in particular the content licence
([H1](KNOWN_ISSUES.md#h1)), which can
invalidate store assets you have already made.

No part of this has been done. Nothing is published, no account is enrolled, no identifiers
are registered.

## Accounts and cost

| | Needed for | Cost |
| --- | --- | --- |
| Apple ID (free) | Simulator, and sideloading with 7-day expiry | — |
| **Apple Developer Program** | App Groups on device, TestFlight, App Store | **$99/year** |

Enrolment approval can take 24–48 hours. Start it before you need it.

## Identifiers

All derived from `Config/Ayas.xcconfig` — the only place they are defined.

| | Value | Constraint |
| --- | --- | --- |
| App bundle ID | `$(AYAS_BUNDLE_ID_PREFIX).Ayas` | Must be globally unique and owned by you |
| Widget bundle ID | `$(AYAS_BUNDLE_ID_PREFIX).Ayas.widget` | **Must stay prefixed by the app's** |
| App Group | `$(AYAS_APP_GROUP)` | Must start `group.`, registered to your team |

The placeholder prefix is `com.ayas`. Change it before registering anything.

## Capabilities

| Capability | Targets | Notes |
| --- | --- | --- |
| **App Groups** | Ayas **and** AyasWidgetExtension | The only non-default capability. Both targets, same identifier, or the widget sees nothing |

Nothing else: no push, no iCloud, no Sign in with Apple, no HealthKit, no background modes.

## Signing

Automatic signing is configured (`CODE_SIGN_STYLE = Automatic`). Xcode manages profiles once
a team is set on both targets.

Simulator builds and CI need **no signing** — pass `CODE_SIGNING_ALLOWED=NO`. The CI workflow
already does, which is why it needs no secrets.

## Before submitting

### Required, or Apple rejects the submission

- [ ] **A unique app name.** Check availability in App Store Connect. "Ayas" may be taken
- [ ] **A support URL** — a real page. GitHub Pages or Notion is fine
- [ ] **A privacy policy URL** — also a real page
- [ ] **Screenshots**, minimum one set for 6.9" iPhone (1320 × 2868). Simulator ⌘S works
- [ ] **Age rating** questionnaire
- [ ] **Category** — Lifestyle or Health & Fitness
- [ ] **App Privacy**: answer **Data Not Collected**. Genuinely true — no network calls at
      all ([D15](DECISIONS.md#d15)), which makes this section trivial and honest

### Strongly recommended

- [ ] Add `ITSAppUsesNonExemptEncryption = false` to `Ayas/Info.plist`. The app uses no
      encryption; without the key Apple asks on every single upload
- [ ] Attribution for the Quran text in the listing as well as in Settings
- [ ] A real app icon review — the current one is generated (`Tools/`-adjacent, a ring and
      seed on warm paper) and has never been seen at device scale

### The privacy policy is unusually short

The app collects nothing, transmits nothing, and contacts no server. Habit data never leaves
the device. That is the entire policy, and it should say so plainly rather than being padded
with boilerplate about data you do not collect.

## Release sequence

1. **Enrol** in the Apple Developer Program. Wait for approval.
2. **Set identifiers** in `Config/Ayas.xcconfig`; set your team on both targets; register the
   App Group.
3. **Verify on a physical device** — the whole checklist in
   [MAC_SETUP.md](MAC_SETUP.md#verification-checklist), especially the widget.
4. **Create the app record** in App Store Connect: My Apps → + → New App. Bundle ID must
   match exactly.
5. **Archive**: destination → *Any iOS Device (arm64)* → Product → Archive.
6. **Upload**: Organizer → Distribute App → App Store Connect → Upload. Allow ~15 minutes for
   processing.
7. **TestFlight** — install through the TestFlight app and confirm a *release* build behaves
   like the debug one. Builds here do not expire in 7 days.
8. **Submit for review.** Typically 24–48 hours. Rejections cite a specific guideline and are
   usually fixable.
9. **Release**, manually or automatically.

## Review risks specific to this app

| Risk | Assessment |
| --- | --- |
| **Third-party content rights** | The real one. Apple can ask you to prove you may distribute the translation. [H1](KNOWN_ISSUES.md#h1) |
| Guideline 4.2, minimum functionality | Low. A real app with a widget and local content |
| Religious content | Low. Guidelines target offensive or inciting content, not scripture |
| Privacy declarations | Low. Nothing is collected, which is the easiest case to declare |

## Things that are *not* required

No export compliance paperwork beyond the Info.plist key, no account deletion flow (there are
no accounts), no data retention policy, no third-party SDK disclosures (there are no SDKs),
no sign-in, no subscription metadata.

## Ongoing

The $99 renews annually; if it lapses, the app is removed from sale and TestFlight builds
stop. A new Xcode major version occasionally forces a rebuild and resubmission.
