# Notice and attribution

This repository bundles Quranic text produced by third parties. This file records where it
came from and what is unresolved about redistributing it.

**This repository is not an authoritative source of Quranic text.** It is an application
project that embeds a copy for offline use. Anyone needing a canonical text should go to the
sources named below.

---

## Arabic text — Uthmani script

**Tanzil Project — <https://tanzil.net>**

The Arabic text originates with the Tanzil Project, which produces and continuously verifies
it. It was obtained here through the [alquran.cloud](https://alquran.cloud) API, which serves
the Tanzil `quran-uthmani` edition, and is bundled under `Shared/Content/Quran/ar.uthmani.*`.

Tanzil distribute their text under terms that require the source to be clearly indicated and
a link made to tanzil.net — which this notice does — and that, as published, do not permit
the text to be changed.

### ⚠️ This project modifies that text

`Tools/build_quran.py` does two things to it:

1. **Strips the basmalah** that the source edition prepends to the first ayah of surahs
   2–114, so that each stored record holds exactly its own ayah.
2. **Re-encodes it** into a flat file plus a byte-offset index, rather than keeping the
   original file format.

Whether that counts as prohibited modification or as permitted reformatting is **unresolved**.
It has not been cleared with the Tanzil Project. See
[docs/QURAN_CONTENT.md](docs/QURAN_CONTENT.md).

---

## English translation — Saheeh International

The translation bundled under `Shared/Content/Quran/en.sahih.*` is the Saheeh International
translation, obtained through the same API.

**It is copyrighted by its publisher.** No permission has been sought or granted for its
redistribution in this repository. Its presence here is **unresolved**, and it should be
removed or replaced before this project is distributed as an application.

---

## Status of these questions

Both items above are open and are tracked as a release blocker:

- [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) — H1
- [docs/QURAN_CONTENT.md](docs/QURAN_CONTENT.md) — options for resolving them

If you represent either rights holder and object to this use, please open an issue on this
repository and it will be addressed.

---

## Application code

Everything outside `Shared/Content/Quran/` — the Swift sources, tooling and documentation —
was written for this project. No licence has been granted for it; all rights are reserved by
the repository owner by default. If you want others to be able to use the code, add a
`LICENSE` file.

## Dependencies

None. The application links no third-party packages.
