# Product vision

## The idea

Most habit apps fail the same way: they ask for more attention than the habit does. You open
the app to record that you did a two-minute thing, and the recording costs more than the act.

Ayas inverts that. The habit lives on the Home Screen, where you already look dozens of times
a day. You see it, you do it, you tap once. The app is where you go when you want to look
back — not where the habit happens.

The shipped example is reading one Quran ayah a day. One ayah is small enough that there is no
honest excuse to skip it, and sequential enough that continuity compounds into something real.

## The loop

```
   see it on the Home Screen   →   do the tiny thing   →   tap the ring
            ↑                                                   ↓
       next day, next ayah      ←      streak holds      ←   it turns green
```

Four parts, each mapped to one mechanism:

| Behavioural part | In the app |
| --- | --- |
| Cue | The Home Screen widget — environmental, unavoidable, not a notification |
| Action | One ayah. Deliberately too small to negotiate with |
| Reward | The ring fills, the whole widget turns green |
| Continuity | The streak, and the sequence advancing to the next ayah |

## Who it is for

Someone who has decided they want a daily practice and keeps losing it to friction — not
someone shopping for a productivity system. They want one or a few tiny things, held steady,
with as little ceremony as possible.

The Quran habit implies a Muslim primary audience, but nothing in the architecture assumes it:
the sequence model handles pages of a book, numbered steps, or no sequence at all.

## Experience principles

These are the rules the product is held to. They are the reason to decline features.

1. **The tiny action is sacred.** Anything that makes the daily act feel bigger than it is —
   a longer form, an extra confirm, a nag — is a regression.
2. **The interface stays out of the way.** No dashboards, no charts, no badge economy. The
   Today screen shows what you are doing today and whether it is done. That is all.
3. **Completion is the reward.** Satisfaction comes from the ring filling and the colour
   changing, not from points, levels or streak-loss anxiety.
4. **A missed day is not a punishment.** The streak resets; the content does not skip. Miss
   three days and you resume on the next unread ayah, not three ayahs later.
5. **Calm over clever.** Warm paper and ink, generous space, a serif voice. It should feel
   like a small sanctuary, not a productivity dashboard, and it should not read as a stock
   iOS template.
6. **It works offline, always.** No account, no server, no network call anywhere.
7. **Scripture is handled with care.** The text is not content to be reflowed casually. See
   [QURAN_CONTENT.md](QURAN_CONTENT.md).

## What success looks like for the MVP

The MVP exists to validate one thing: **does a Home Screen widget plus a one-tap completion
actually sustain a daily habit better than an app you have to open?**

That means the bar is not feature count. It is:

- The widget shows the right ayah tomorrow morning without the app having been opened.
- Completing from the widget feels instant.
- A week in, the streak is still correct.
- The user has not been annoyed by the app once.

Everything in [ROADMAP.md](ROADMAP.md) is ordered behind that question.

## Deliberate non-goals

No accounts, no backend, no social features, no leaderboards, no achievements, no AI, no
subscription, no cloud sync, no analytics, no Watch app, no Android. Several of these might
be right later. None of them are needed to answer the question above, and each one would
dilute principle 2.
