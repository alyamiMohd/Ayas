# Quran content

Read this before changing anything under `Shared/Content/`. Scripture is not ordinary app
content, and there is an **unresolved licensing question here that blocks public release**.

## What is bundled

`Shared/Content/Quran/`, added to both targets as a **folder reference** so the directory
structure survives into the bundle and new files need no project change.

| File | Size | Contents |
| --- | --- | --- |
| `surahs.json` | 16 KB | 114 records: number, Arabic name, transliteration, meaning, revelation place, ayah count |
| `ar.uthmani.txt` | 1.3 MB | 6,236 ayahs, one per line, UTF-8, LF |
| `ar.uthmani.idx` | 25 KB | 6,237 little-endian `UInt32` byte offsets |
| `en.sahih.txt` | 842 KB | English translation, same line-for-line alignment |
| `en.sahih.idx` | 25 KB | its offsets |

Total ≈ 2.2 MB, duplicated into the widget extension's bundle as well.

## Why the offset index

The widget extension runs under a hard memory limit and only ever needs **one ayah**. Parsing
a 1.3 MB file to get it is how widgets end up showing "Unable to load".

Instead: `record i` occupies bytes `[off[i], off[i+1] - 1)` — the `-1` drops the trailing
newline. `QuranLibrary.Edition.line(at:)` opens a `FileHandle`, seeks, reads a few hundred
bytes, closes. The index itself (25 KB) is decoded byte-by-byte little-endian at init, so
alignment never matters.

**This is why line endings are fatal.** A CRLF translation shifts every offset and the app
renders torn text. `.gitattributes` pins these files as binary; do not relax it. See
[CLAUDE.md](../CLAUDE.md) rule 2.

## Provenance

Generated **once, at build time** by `Tools/build_quran.py` from the
[alquran.cloud](https://alquran.cloud) API:

- Arabic: the `quran-uthmani` edition, which carries the Tanzil Uthmani text
- English: the `en.sahih` edition — Saheeh International

**Nothing is fetched at runtime.** The app makes no network calls at all. The script is
committed so the dataset is reproducible, but running it requires network and is only needed
when changing the dataset.

### The basmalah correction

The source edition prepends the basmalah to the first ayah of surahs 2–114 (surah 9 has none).
The script strips it so each record holds exactly its own ayah. Surah 1 keeps it, where it
genuinely *is* ayah 1.

Two surahs — **95 (At-Tin)** and **97 (Al-Qadr)** — spell that prefix with a stray shadda on
the opening *bāʾ* (`بِّسْمِ`). The script accepts both spellings; without that, those two
surahs would have opened with a duplicated basmalah. This was caught by an assertion, not by
reading, which is the point of the next section.

## Correctness safeguards

`Tools/build_quran.py` refuses to produce output unless:

- both editions report 114 surahs and exactly 6,236 ayahs
- surah and ayah numbering is contiguous and matches between editions
- exactly 113 surah openings carry a basmalah prefix (all but surah 9)
- no ayah is empty after cleaning
- no ayah contains a newline, which would corrupt the offset scheme

`AyasTests/SequenceTests.swift` then checks the shipped artefact:

- 114 surahs summing to 6,236
- `location(ofAyah:)` and `globalIndex(surah:ayah:)` round-trip for **every** ayah
- known anchors: 1:1 → index 1, 2:1 → 8, 2:255 (Ayat al-Kursi) → 262, 114:6 → 6,236
- text reads back non-empty and newline-free at sampled indices
- surah 2's opening does not begin with the basmalah

These tests have **never been executed** — see [CLAUDE.md](../CLAUDE.md). Running them is a
first-session priority precisely because this is the content least safe to get wrong.

### If the text looks wrong

Suspect the pipeline, never "fix" the scripture by hand. Editing a `.txt` without regenerating
its `.idx` corrupts every subsequent ayah. Change `build_quran.py` and regenerate both.

## Rendering

`ArabicText` (`Shared/Design/Typography.swift`) handles presentation:

- `.environment(\.layoutDirection, .rightToLeft)` and trailing alignment
- line spacing at **0.52 × font size** — Arabic diacritics need far more leading than Latin
  text, and the default collides
- the system font, which resolves to iOS's Arabic face and renders Uthmani diacritics
  correctly; no font is bundled
- `minimumScaleFactor(0.85)` so long ayahs shrink rather than truncate

Sizes: 25 pt in the app's detail block, 18 pt on a medium widget, 14 pt on small.

**Unverified:** nothing has rendered. Arabic layout is the single most likely place for a
visual bug, and 2:282 (the longest ayah) is the worst case to check first.

## Sequence behaviour

A `.quran(start:)` habit stores a 1-based global ayah index. Today's ayah is
`QuranLibrary.wrappedIndex(start:step:)` where `step == completions.count`.

Two consequences, both deliberate:

- **Position follows completions, not dates.** Miss three days and you resume on the next
  unread ayah, not three ayahs later. Missing a day costs the streak; it must not cost
  content.
- **It wraps.** Completing ayah 6,236 returns to 1 rather than reaching a dead end.

<a id="licensing"></a>

## Licensing — unresolved, blocks release

> This is fine for personal use and for TestFlight among people you know. It is **not**
> settled for App Store release. Resolve it before investing in store assets.

Two separate problems:

**1. The Arabic text.** Tanzil's terms require attribution and — read carefully —
restrict modification of the text. `build_quran.py` *does* modify it: it strips the basmalah
prefix and re-encodes into a custom format. Whether that counts as prohibited modification or
as permitted formatting is a question for Tanzil's terms, and possibly for them directly.

**2. The translation.** Saheeh International is copyrighted by its publisher. Many apps ship
it; not all of them have permission. Shipping it commercially without clearing it is a real
risk, not a formality.

### Options

| Option | Effort | Result |
| --- | --- | --- |
| Ship Arabic only | Low — drop `en.sahih.*`, hide the translation setting | Removes problem 2, leaves 1 |
| Swap to a public-domain translation | Medium — point `build_quran.py` at another edition | e.g. an out-of-copyright translation |
| Clear permission with both rights holders | Unknown — correspondence | Keeps the current text |
| Source Arabic from an unambiguously open edition | Medium | Addresses 1 directly |

Attribution currently appears in Settings: *"Quran text: Uthmani script with the Saheeh
International translation, bundled with the app."* That is necessary but not sufficient.

## Adding a translation

1. Add an edition to `Tools/build_quran.py` and run it.
2. Drop the resulting `<slug>.txt` / `<slug>.idx` into `Shared/Content/Quran/`.
3. Register it in `QuranLibrary.init` alongside `englishEdition`.
4. Expose it wherever `Settings.showTranslation` is read.

No project-file change is needed — the folder is a reference. Confirm the licence first.
