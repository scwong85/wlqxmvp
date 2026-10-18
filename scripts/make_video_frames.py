"""First frames for the activity videos: the painted hero (male and female) standing in each clip's painted background,
9:16 (768x1376), ready to use as the start image in an image-to-video tool.  -> art_src/video_firstframes/<clip>_<m|f>.png
"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "game", "art", "backgrounds")
FIG = os.path.join(ROOT, "game", "art", "figures")
OUT = os.path.join(ROOT, "art_src", "video_firstframes")

# clip id -> painted background
CLIPS = {
    "training": "valley_day",
    "technique_practice": "valley_dawn",
    "meditation": "shrine_night",
    "fishing": "riverside_day",
    "herb_gathering": "riverside_day",
    "mining": "cangwu_night",
    "hunting": "valley_dawn",
    "cooking": "village_dusk",
    "music": "village_dusk",
    "chess": "village_dusk",
    "social_visit": "city_market",
    "rest": "village_dusk",
}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for clip, bg in CLIPS.items():
        base = Image.open(os.path.join(BG, bg + ".jpg")).convert("RGB").resize((768, 1376))
        for g in ("m", "f"):
            fig = Image.open(os.path.join(FIG, f"hero_{g}.png")).convert("RGBA")
            h = 800
            fig = fig.resize((round(fig.width * h / fig.height), h), Image.LANCZOS)
            frame = base.copy()
            frame.paste(fig, ((768 - fig.width) // 2, 1250 - h), fig)
            frame.save(os.path.join(OUT, f"{clip}_{g}.png"))
    print("frames:", len(CLIPS) * 2)


if __name__ == "__main__":
    main()
