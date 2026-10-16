#!/usr/bin/env python3
"""Slices the generated bust sheets in art_src/characters into game/art/characters/<id>/<id>_face_<face>.png.
Boxes are in sheet pixels (x0, y0, x1, y1) per panel, in the order neutral, happy, sad, angry, surprised."""
import os, sys
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "art_src", "characters")
OUT = os.path.join(ROOT, "game", "art", "characters")
FACES = ["neutral", "happy", "sad", "angry", "surprised"]
def row(y0, y1, xs): return [(a, y0, b, y1) for a, b in xs]
EQ = [(i * 205, 0, 0, 0) for i in range(5)]
SHEETS = {
 "shen_qinghe": row(335, 650, [(42, 218), (233, 408), (423, 598), (613, 788), (804, 980)]),
 "lu_chenzhou": row(393, 648, [(22, 208), (222, 408), (420, 605), (618, 803), (817, 1002)]),
 "su_dai": row(378, 652, [(0, 205), (205, 410), (410, 615), (615, 820), (819, 1024)]),
 "bai_yan": row(380, 655, [(0, 205), (205, 410), (410, 615), (615, 820), (819, 1024)]),
 "hero_f": row(383, 642, [(22, 208), (220, 407), (418, 605), (617, 803), (815, 1002)]),
 "xiao_hanchuan": row(318, 705, [(26, 205), (224, 404), (423, 602), (621, 800), (820, 999)]),
 "xia_zhi": row(397, 628, [(33, 215), (228, 408), (422, 602), (615, 796), (808, 990)]),
}
# 3x2 grids: pick panels r1c1, r1c2, r1c3, and two from row 2
GRID_X = {"li_shan": [(32, 337), (359, 665), (687, 992)], "xie_wujiu": [(30, 337), (360, 665), (690, 992)], "hero_m": [(35, 338), (360, 665), (688, 990)]}
GRID_Y = {"li_shan": [(135, 495), (527, 882)], "xie_wujiu": [(35, 500), (520, 982)], "hero_m": [(70, 502), (523, 970)]}
PICK = {"li_shan": [(0, 0), (0, 1), (0, 2), (1, 1), (1, 2)], "xie_wujiu": [(0, 0), (0, 1), (0, 2), (1, 1), (1, 2)], "hero_m": [(0, 0), (0, 1), (1, 0), (1, 1), (1, 2)]}
for cid in GRID_X:
    SHEETS[cid] = [(GRID_X[cid][c][0], GRID_Y[cid][r][0], GRID_X[cid][c][1], GRID_Y[cid][r][1]) for r, c in PICK[cid]]
PAD = 5  # trims the panel outline
def main():
    for cid, boxes in SHEETS.items():
        im = Image.open(os.path.join(SRC, cid + "_sheet.jpg")).convert("RGB")
        os.makedirs(os.path.join(OUT, cid), exist_ok=True)
        for face, (x0, y0, x1, y1) in zip(FACES, boxes):
            im.crop((x0 + PAD, y0 + PAD, x1 - PAD, y1 - PAD)).save(os.path.join(OUT, cid, "%s_face_%s.png" % (cid, face)))
    print("sliced", len(SHEETS), "sheets")
if __name__ == "__main__": main()
