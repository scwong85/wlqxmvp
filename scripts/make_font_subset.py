import sys
from fontTools.ttLib import TTCollection
from fontTools import subset

import glob, json
src, out = sys.argv[1], sys.argv[2]
loc_dir = sys.argv[3] if len(sys.argv) > 3 else None
coll = TTCollection(src)
idx = None
for i, f in enumerate(coll.fonts):
    names = f["name"].getDebugName(1) or ""
    if "SC" in names:
        idx = i
        break
if idx is None:
    sys.exit("SC face not found")
print("SC face index", idx)

chars = set()
for hi in range(0xB0, 0xD8):
    for lo in range(0xA1, 0xFF):
        try:
            chars.add(bytes([hi, lo]).decode("gb2312"))
        except UnicodeDecodeError:
            pass
chars |= set("，。！？、：；（）《》“”‘’—…·×") | {chr(c) for c in range(0x20, 0x7F)}
if loc_dir:
    # Every character used by any locale string must be in the font (web has no system fallback).
    for path in glob.glob(loc_dir + "/*.json"):
        for v in json.load(open(path, encoding="utf-8")).values():
            chars |= set(v)
    # The spike deliberately shows two out-of-subset glyphs to demonstrate missing-glyph behavior.
    chars -= set("𠮷䶮")
print("chars:", len(chars))

opts = subset.Options()
opts.layout_features = ["*"]
opts.notdef_outline = True
opts.name_IDs = ["*"]
opts.flavor = None
font = coll.fonts[idx]
s = subset.Subsetter(opts)
s.populate(text="".join(sorted(chars)))
s.subset(font)
font.save(out)
print("wrote", out)
