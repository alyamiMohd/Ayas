# Decisions

Why things are the way they are. If you want to change one of these, the reasoning is here to
argue with — but change it deliberately, not by accident.

All decisions were made during the initial build (September 2026) by the original author
working with Claude. Anything still open is marked.

---

<a id="d1"></a>

### D1 — Native Swift + SwiftUI, not cross-platform
**Decided.** The entire product thesis is the Home Screen widget. WidgetKit, App Intents and
interactive widgets have no faithful cross-platform equivalent, and a wrapper would make the
one feature that matters the one feature that fights the framework.

---

<a id="d2"></a>

### D2 — The widget is the reminder; no notifications
**Decided.** A notification is an interruption you dismiss. A widget is an environmental cue
you glance past until you act on it. Atomic Habits calls this making the cue *obvious*, not
*loud*. Adding notifications would be the easiest way to turn this into a nagging app.

---

<a id="d3"></a>

### D3 — Shared code by dual target membership, not a framework
**Decided.** `Shared/` is compiled into both the app and the extension. A framework target
would add build complexity and a dynamic-link cost to a memory-constrained extension, for a
codebase of ~4,000 lines. Revisit if a third target appears.

---

<a id="d4"></a>

### D4 — A JSON document in an App Group, not SwiftData or Core Data
**Decided.** The state is small (habits plus a list of day/step pairs). The hard requirement
is that two processes read and write it without tearing, which `NSFileCoordinator` plus
atomic writes gives directly and legibly.

SwiftData in an app-plus-widget configuration adds a schema, migrations, and failure modes
that are hard to debug — particularly from Windows, where none of it could be run. The JSON
document can be read with `cat`.

Revisit if state grows beyond a few hundred kilobytes or needs querying.

---

<a id="d5"></a>

### D5 — Widget completion is one-way
**Decided.** The widget can complete a habit; it cannot un-complete one. The Home Screen is a
place thumbs land accidentally, and the cost of an accidental un-complete is someone's
streak — the one thing the product promises to keep safe.

Undo exists in the app, two taps away, where the gesture is intentional. Once complete, the
widget control stops being a `Button` entirely.

---

<a id="d6"></a>

### D6 — Sequence position follows completions, not the calendar
**Decided.** Today's step is `completions.count`, not days-since-start. Miss three days and
you resume on the next unread ayah rather than skipping three.

Missing a day costs the streak. It must not cost content — nobody wants an app that decides
they have "missed" three ayahs of the Quran.

---

<a id="d7"></a>

### D7 — Only today can be completed
**Decided.** No backfilling. Partly to keep the model honest (a streak you can edit is not a
streak), partly because the completion record carries a sequence step, and inserting into the
middle of that history makes step numbering ambiguous.

The known edge case: travelling west across the date line can make "today" earlier than an
already-recorded day. Insertion stays sorted by day and the streak stays correct; only the
recorded step ordering looks odd. Accepted. See [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

---

<a id="d8"></a>

### D8 — The Xcode project is generated from the file tree
**Decided — originally from necessity.** The project was authored on Windows with no Xcode, so
`project.pbxproj` had to be written by script. `Tools/generate_xcodeproj.py` hashes stable
identifiers, making regeneration byte-identical, and `Tools/verify_project.py` parses the
result back and asserts every reference resolves.

Worth keeping now that the constraint is gone: the project file cannot silently drift from
the files on disk, and project diffs stay readable. The cost is that adding a file through
Xcode's UI will be overwritten on the next regeneration.

**Open:** a Mac-based team may prefer to stop generating and let Xcode own the file. If so,
delete both tools and the CI step, and say so here.

---

<a id="d9"></a>

### D9 — One green for every completed widget
**Decided.** Habits each carry their own accent colour in the app. On the widget, completion
turns the whole face the *same* green regardless.

At Home Screen size the only question is "is today done", and one colour answers it without
being read. Per-habit completion colours would make the answer require interpretation. The
app, where there is room to tell habits apart, keeps the individual accents.

**Open:** the app's own completed states still use the habit accent, not green. Consistent
with the reasoning above, but someone may reasonably want them unified.

---

<a id="d10"></a>

### D10 — A day can begin after midnight
**Decided.** Settings offers a day boundary from midnight to 4 AM. Someone reading an ayah at
00:30 thinks of it as tonight, not tomorrow, and a tracker that disagrees is a tracker people
stop trusting.

Implemented by comparing the **wall-clock hour**, not by subtracting hours from an instant —
on a spring-forward morning those differ, and the naive version puts the boundary on the
wrong side of the date.

---

<a id="d11"></a>

### D11 — Streaks keep a one-day grace while today is open
**Decided.** `currentStreak(asOf:)` anchors on today if complete, otherwise on yesterday. So a
six-day run still reads as six at 9 AM before you have done today's, rather than collapsing
to zero at midnight and recovering when you act.

Once a full day passes unmarked, the streak is gone and the next completion starts at 1.

---

<a id="d12"></a>

### D12 — The visual identity avoids looking like a system template
**Decided.** Warm paper and ink rather than system greys; a serif (New York, via
`design: .serif`) for anything carrying meaning; no system blue anywhere; the navigation bar
hidden throughout with each screen drawing its own header; rows and hairlines instead of
grouped card lists.

The brief was explicitly that it must not read as "just another Apple app". See
[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

---

<a id="d13"></a>

### D13 — Zero third-party dependencies
**Decided.** Nothing in this app needs a package. No dependency manifest means no supply
chain, no version drift, and a clone that builds with nothing but Xcode.

---

<a id="d14"></a>

### D14 — Share produces an image, not a link
**Decided.** `ImageRenderer` draws a square card off-screen and hands it to the system share
sheet. An image survives every feed and message thread intact; a link would need a server,
which contradicts [D15](#d15).

Rendered in light mode always, so it looks the same to everyone who receives it.

---

<a id="d15"></a>

### D15 — Fully offline, no account, no backend
**Decided.** The content is bundled, the state is local, and there is no network call
anywhere in the app. Nothing about the MVP's question requires a server, and avoiding one
removes privacy obligations, infrastructure, and an entire category of failure.

---

<a id="d16"></a>

### D16 — The repository keeps its existing history
**Decided, October 2026.** The handover brief asked for a "new clean repository". The
existing one already satisfied the intent — private, complete, two meaningful commits, a
`v0.5` tag — so it was kept and documented rather than duplicated. Creating a second repo
would have split the history and orphaned the release.

**Open:** the name `Ayas` is not self-describing for someone receiving the project cold.
Renaming on GitHub preserves history and redirects the old URL, if wanted.
