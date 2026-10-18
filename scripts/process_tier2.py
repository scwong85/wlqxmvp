"""Tier 2 art pipeline: art_src -> game/art.
  fullbody/<id>_full.jpg   -> game/art/figures/<id>.png      (white background cut out, cropped to the figure)
  backgrounds2/<id>.jpg    -> game/art/backgrounds/<id>.jpg
  endings/ending_<id>.jpg  -> game/art/endings/<id>.jpg
  ui/paper.jpg             -> game/art/ui/paper.jpg           (seamless tile)
  ui/brush_plate.jpg       -> game/art/ui/brush_plate.png     (ink on transparent)
Run from the repo root: python3 scripts/process_tier2.py
"""
import glob
import os
import shutil

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_src")
OUT = os.path.join(ROOT, "game", "art")
SCALE = 0.75          # 768x1376 sources -> about 576x1032, plenty for a phone


def cutout(path: str) -> Image.Image:
    img = Image.open(path).convert("RGB")
    a = np.array(img).astype(int)
    mx = a.max(axis=2)
    mn = a.min(axis=2)
    white = (mn >= 246) & ((mx - mn) <= 8)
    lab, n = ndimage.label(white)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    # Enclosed white gaps (between an arm and the body, inside a staff loop) are background too.
    sizes = ndimage.sum(white, lab, index=np.arange(1, n + 1))
    for i, s in enumerate(sizes, start=1):
        if i not in border and s >= 300:
            bg |= lab == i
    # Soft ground shadows (Xiao): light grey, low chroma, connected to the background.
    soft = (mn >= 205) & ((mx - mn) <= 14)
    lab2, _ = ndimage.label(soft | bg)
    touch = set(np.unique(lab2[bg])) - {0}
    bg |= np.isin(lab2, list(touch)) & soft
    if os.path.basename(path).startswith("xiao_hanchuan"):
        # A painted ground shadow under the boots: light pixels in the foot band are background.
        band = np.zeros_like(bg)
        band[1185:, :] = True
        bg |= band & (mn >= 170)
    bg = ndimage.binary_dilation(bg, iterations=1)       # eat the pale halo around the outline
    alpha = 1.0 - ndimage.gaussian_filter(bg.astype(float), 0.7)
    alpha = np.clip((alpha - 0.15) / 0.7, 0, 1)
    rgba = np.dstack([np.array(img), (alpha * 255).astype(np.uint8)])
    out = Image.fromarray(rgba, "RGBA")
    bbox = out.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    pad = 6
    box = (max(0, bbox[0] - pad), max(0, bbox[1] - pad), min(out.width, bbox[2] + pad), min(out.height, bbox[3] + pad))
    out = out.crop(box)
    # One scale for every figure keeps their relative heights (the game reads the texture height).
    return out.resize((max(1, round(out.width * SCALE)), max(1, round(out.height * SCALE))), Image.LANCZOS)


def main() -> None:
    for d in ("figures", "backgrounds", "endings", "ui"):
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    for p in sorted(glob.glob(os.path.join(SRC, "fullbody", "*_full.jpg"))):
        id_ = os.path.basename(p)[: -len("_full.jpg")]
        im = cutout(p)
        im.save(os.path.join(OUT, "figures", id_ + ".png"), optimize=True)
        print("figure", id_, im.size)
    for p in sorted(glob.glob(os.path.join(SRC, "backgrounds2", "*.jpg"))):
        shutil.copyfile(p, os.path.join(OUT, "backgrounds", os.path.basename(p)))
        print("background", os.path.basename(p))
    for p in sorted(glob.glob(os.path.join(SRC, "endings", "ending_*.jpg"))):
        id_ = os.path.basename(p)[len("ending_"):]
        shutil.copyfile(p, os.path.join(OUT, "endings", id_))
        print("ending", id_)
    paper = Image.open(os.path.join(SRC, "ui", "paper.jpg")).convert("RGB")
    paper.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "ui", "paper.jpg"), quality=88)
    plate = Image.open(os.path.join(SRC, "ui", "brush_plate.jpg")).convert("L")
    g = np.array(plate).astype(float) / 255.0
    alpha = np.clip((0.97 - g) / 0.6, 0, 1)
    ink = np.zeros((*g.shape, 4), dtype=np.uint8)
    ink[..., 0], ink[..., 1], ink[..., 2] = 28, 22, 18
    ink[..., 3] = (alpha * 255).astype(np.uint8)
    pim = Image.fromarray(ink, "RGBA")
    pim = pim.crop(pim.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox())
    pim = pim.resize((900, max(1, round(900 * pim.height / pim.width))), Image.LANCZOS)
    pim.save(os.path.join(OUT, "ui", "brush_plate.png"), optimize=True)
    print("ui done")


if __name__ == "__main__":
    main()
