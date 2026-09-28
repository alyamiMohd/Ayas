"""Transform downloaded Quran editions into the app's bundled resources.

Output (all in Ayas/Shared/Content/Quran/):
  surahs.json      small metadata array, parsed fully at runtime
  <edition>.txt    UTF-8, one ayah per line, LF separated, no trailing LF issues
  <edition>.idx    little-endian UInt32 offsets, count = ayahCount + 1
                   record i occupies bytes [off[i], off[i+1] - 1)  (-1 drops the LF)

The offset index lets the widget seek straight to one ayah instead of loading a
multi-megabyte file into a memory-constrained extension.
"""
import io
import json
import os
import struct
import sys

SCRATCH = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]

def load(name):
    with io.open(os.path.join(SCRATCH, name), encoding="utf-8") as fh:
        payload = json.load(fh)
    assert payload["status"] == "OK", name
    return payload["data"]["surahs"]


def clean_arabic(surah_number, ayah_number, text):
    text = text.replace("﻿", "").strip()
    # Surahs 2-114 carry the basmalah prepended to ayah 1; strip it so each record
    # holds exactly its own ayah. Surah 1 keeps it: there it genuinely is ayah 1.
    if surah_number != 1 and ayah_number == 1:
        for variant in BASMALAH_VARIANTS:
            if text.startswith(variant):
                text = text[len(variant):].strip()
                break
    return text


def write_edition(slug, texts):
    txt_path = os.path.join(OUT, slug + ".txt")
    idx_path = os.path.join(OUT, slug + ".idx")
    offsets = []
    with io.open(txt_path, "wb") as fh:
        cursor = 0
        for text in texts:
            assert "\n" not in text and "\r" not in text, "newline inside ayah"
            offsets.append(cursor)
            encoded = (text + "\n").encode("utf-8")
            fh.write(encoded)
            cursor += len(encoded)
        offsets.append(cursor)
    with io.open(idx_path, "wb") as fh:
        fh.write(struct.pack("<%dI" % len(offsets), *offsets))
    return txt_path, idx_path, offsets


arabic = load("uthmani.json")
english = load("en_sahih.json")

assert len(arabic) == 114 and len(english) == 114

# The edition spells the basmalah exactly as surah 1 ayah 1; take it from there
# rather than hand-typing diacritics. Surahs 95 and 97 carry a stray shadda on the
# opening ba in this edition, so accept that variant too.
BASMALAH = arabic[0]["ayahs"][0]["text"].replace("﻿", "").strip()
BASMALAH_VARIANTS = (BASMALAH, BASMALAH[0] + "ّ" + BASMALAH[1:])
prefixed = sum(
    1
    for s in arabic
    for a in s["ayahs"]
    if a["numberInSurah"] == 1
    and a["text"].replace("﻿", "").strip().startswith(BASMALAH_VARIANTS)
)
# Surah 1 itself, plus surahs 2-114 except 9 (which has no basmalah) = 113.
assert prefixed == 113, "unexpected basmalah layout: %d" % prefixed

meta = []
ar_texts = []
en_texts = []

PLACE = {"meccan": "meccan", "medinan": "medinan"}

for si in range(114):
    sa, se = arabic[si], english[si]
    assert sa["number"] == se["number"] == si + 1
    assert len(sa["ayahs"]) == len(se["ayahs"])
    meta.append({
        "number": sa["number"],
        "name": sa["name"].replace("﻿", "").strip(),
        "latinName": sa["englishName"],
        "meaning": sa["englishNameTranslation"],
        "place": PLACE[sa["revelationType"].lower()],
        "ayahCount": len(sa["ayahs"]),
    })
    for ai in range(len(sa["ayahs"])):
        ar = sa["ayahs"][ai]
        en = se["ayahs"][ai]
        assert ar["numberInSurah"] == ai + 1
        ar_texts.append(clean_arabic(si + 1, ai + 1, ar["text"]))
        en_texts.append(en["text"].replace("﻿", "").strip())

assert len(ar_texts) == len(en_texts) == 6236
assert sum(s["ayahCount"] for s in meta) == 6236
assert all(t for t in ar_texts), "empty arabic ayah"
assert all(t for t in en_texts), "empty english ayah"

os.makedirs(OUT, exist_ok=True)

with io.open(os.path.join(OUT, "surahs.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(meta, fh, ensure_ascii=False, separators=(",", ":"))
    fh.write("\n")

ar_files = write_edition("ar.uthmani", ar_texts)
en_files = write_edition("en.sahih", en_texts)

report = {
    "ayahs": len(ar_texts),
    "surahs": len(meta),
    "ar_bytes": ar_files[2][-1],
    "en_bytes": en_files[2][-1],
    "fatihah_1": ar_texts[0],
    "baqarah_1": ar_texts[7],
    "baqarah_255_head": ar_texts[7 + 254][:40],
    "nas_6": ar_texts[-1],
    "en_fatihah_1": en_texts[0],
}
with io.open(os.path.join(SCRATCH, "report.json"), "w", encoding="utf-8") as fh:
    json.dump(report, fh, ensure_ascii=False, indent=2)
print("wrote", OUT)
