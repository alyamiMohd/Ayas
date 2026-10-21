# Design system

The brief was explicit: minimal, warm, calm, intentional — a small digital sanctuary, and
specifically **not** something that reads as a stock iOS template. Every choice below follows
from that. See [D12](DECISIONS.md#d12).

A rendered specimen of all screens and widget states in both modes exists as a published
artifact; ask the project owner for the link. **No real screenshots exist** — the app has
never rendered ([L3](KNOWN_ISSUES.md#l3)).

## Colour

All tokens are adaptive `UIColor` pairs, so mode changes cross-fade naturally. Defined in
`Shared/Design/Palette.swift`. **Both modes were drawn deliberately — dark is not an
inversion.**

### Ground and ink

| Token | Light | Dark | Used for |
| --- | --- | --- | --- |
| `canvas` | `#F7F3ED` | `#121110` | The page |
| `canvasLow` | `#EFE8DD` | `#0B0A09` | Recessed wash, control fills |
| `surface` | `#FFFCF8` | `#1C1A18` | Raised surfaces, widget ground |
| `ink` | `#211E1A` | `#F4EFE8` | Primary text |
| `inkSoft` | `#5D564D` | `#A9A099` | Secondary text |
| `inkFaint` | `#9A9188` | `#6D645D` | Tertiary, eyebrows |
| `line` | `#E4DBCE` | `#2B2825` | Hairlines |
| `lineStrong` | `#D2C7B7` | `#3B3733` | Empty rings, outlined buttons |
| `onAccent` | `#FFFDFA` | `#17140F` | Sits on a filled accent |

Warm paper and warm near-black. No system blue appears anywhere in the app.

### Habit accents

Each habit picks one. Every accent has a `color` and a soft `wash`.

| Key | Light | Dark | Wash (light / dark) |
| --- | --- | --- | --- |
| `ember` | `#BE6136` | `#E08C5F` | `#F3E5DB` / `#2A1F19` |
| `olive` | `#5F7A50` | `#9BB884` | `#E7EBE0` / `#1B211A` |
| `indigo` | `#4B5A7C` | `#8C9DC4` | `#E3E6EF` / `#1A1D26` |
| `rose` | `#A4505F` | `#D4818E` | `#F2E2E4` / `#261A1D` |
| `sand` | `#8F7040` | `#C8A469` | `#F1E8D7` / `#241F16` |
| `teal` | `#3B7269` | `#7DB3A8` | `#DFEAE7` / `#16211F` |

### Completion green — widget only

| Token | Light | Dark |
| --- | --- | --- |
| `doneGround` | `#4C7A4F` | `#2B5136` |
| `doneGroundEdge` | `#3E6742` | `#1D3826` |
| `onDone` | `#F5F9F2` | `#E2EFDE` |
| `onDoneSoft` | `#DCE9D7` | `#B6CFB1` |
| `onDoneFaint` | `#C0D6BC` | `#9BB899` |

One green for every habit on the widget, whatever its accent — [D9](DECISIONS.md#d9). The
app's own completed states still use the habit accent ([L5](KNOWN_ISSUES.md#l5)).

## Typography

Two voices, in `Shared/Design/Typography.swift`. The serif is what stops the app reading as a
system template; it is iOS's **New York**, reached via `design: .serif` — nothing is bundled.

| Role | Face | Size |
| --- | --- | --- |
| `screenTitle` | serif | 34 |
| `sectionTitle` | serif | 22 |
| `habitName` | serif | 21 |
| `habitNameCompact` | serif | 17 |
| `numeral(_:)` | serif | 44 for streaks, 76 on the share card |
| `body` | sans | 15 |
| `bodySmall` | sans | 13 |
| `caption` | sans | 12 |
| eyebrow | sans | 10–11, semibold, `tracking 1.3`, uppercase |
| Arabic | system | 25 app / 18 medium widget / 14 small |

**Rule:** serif carries meaning (names, scripture, numbers you care about); sans carries
mechanics (labels, captions, controls). Eyebrows are locators, used sparingly — never as
decoration.

Arabic gets `lineSpacing = size × 0.52`. Diacritics need far more leading than Latin text and
the default collides.

Sizes are fixed points, not Dynamic Type — a deliberate choice with a real accessibility cost
([M3](KNOWN_ISSUES.md#m3)).

## Space, radius, motion

`Shared/Design/Motion.swift`.

```
Space   tight 6 · snug 12 · regular 18 · roomy 28 · generous 44 · gutter 26
Radius  medium 18 · large 26
```

The 26 pt page gutter is wide on purpose. Breathing room *is* the design.

| Curve | Spring | Used for |
| --- | --- | --- |
| `complete` | `0.38 / 0.68` | Completing. Enough overshoot to feel like a stamp |
| `undo` | `0.3 / 0.9` | Un-completing. Flatter, deliberately less rewarding |
| `soft` | `easeInOut 0.26` | State cross-fades, layout settles |
| `settle` | `0.5 / 0.86` | Rows arriving, sheets resolving |

That `complete` and `undo` differ is intentional: the reward is in the motion, and undoing
should not feel like an achievement.

## Components

| Component | File | Notes |
| --- | --- | --- |
| `CompletionMark` | `Shared/Design/CompletionMark.swift` | The ring → filled check. Shared app/widget so completion looks identical everywhere. Takes an optional `MarkPalette` to stay legible on a filled ground |
| `AddMark` | same | Dashed ring with a plus, same rhythm as habit rows |
| `ScreenHeader` | `Ayas/Components/Chrome.swift` | Eyebrow + title + optional trailing control |
| `Hairline` | same | 0.75 pt, inset 46 to align under row text |
| `CircleControl` / `CircleControlFace` | same | Face is split out so `ShareLink` wears the same look |
| `PressableStyle` | same | Scale + opacity on press. Nothing in the app is inert |
| `FilledButtonStyle` / `OutlineButtonStyle` | same | One filled button per screen, at most |
| `UnderlinedField` | same | Hairline underline that takes the accent on focus. No boxed form rows anywhere |
| `HabitRow` | `Ayas/Components/HabitRow.swift` | Two sibling buttons: ring and body |
| `AyahBlock` | `Ayas/Components/AyahBlock.swift` | The only filled surface in the app |
| `WeekStrip` | `Ayas/Components/WeekStrip.swift` | 14 capsules. Stitches, not a chart |
| `ShareCard` | `Ayas/Components/ShareCard.swift` | 340 pt square, rendered at 3× |

## Layout rules

- **Rows, not cards.** Hairlines separate; the page shows through. Cards would make the Today
  screen a dashboard.
- **The system navigation bar is hidden throughout.** Each screen draws its own header. This
  is most of what keeps the app from looking generic.
- **One filled surface per screen, at most.** In practice only `AyahBlock` earns it, because
  it is the one place you are meant to stop and stay.
- **No charts, no badges, no stat tiles.** History is 14 capsules. The streak is a numeral.
- **Generous vertical rhythm.** Space is the main compositional tool.

## When adding UI

Ask whether it makes the daily act feel bigger. If so, it is probably wrong —
[PRODUCT_VISION.md](PRODUCT_VISION.md#experience-principles). Reach for an existing token;
if a new colour or size seems necessary, add it to the token files rather than inline.
