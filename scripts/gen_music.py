#!/usr/bin/env python3
"""Placeholder music (M23b): synthesises every track in the catalog to game/audio/music/<id>.ogg and writes
game/content/audio/music.json (the catalog plus the rules that choose a track). The ogg files are drop-in
replaceable: put a generated track with the same file name in game/audio/music/ and nothing else changes.
Run: python3 scripts/gen_music.py [--force] [track_id ...]   (existing files are kept unless --force or a track id is named)   (needs numpy and ffmpeg with libvorbis)"""
import json, os, subprocess, sys, tempfile
import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game")
OUT = os.path.join(ROOT, "audio", "music")
SR = 22050
SCALES = {"gong": [0, 2, 4, 7, 9], "shang": [0, 2, 5, 7, 10], "jue": [0, 3, 5, 8, 10], "zhi": [0, 2, 5, 7, 9], "yu": [0, 3, 5, 7, 10]}

# id: bpm, bars, root (midi), scale, seed, layers. Layer kinds: melody, arp, bass, drone, sparse (pitched) and drums: kick, wood, bell, tom.
T = {
 "title_theme":    dict(bpm=72, bars=8, root=62, scale="gong", seed=1, layers=[("pluck", "arp", 0, 0.55), ("flute", "melody", 1, 0.6), ("pad", "drone", -1, 0.35), ("bell", "bell", 0, 0.3)]),
 "practice_theme": dict(bpm=60, bars=8, root=60, scale="zhi", seed=2, layers=[("pluck", "sparse", 0, 0.5), ("pad", "drone", -1, 0.4), ("flute", "sparse", 1, 0.35)]),
 "valley_theme":   dict(bpm=84, bars=8, root=64, scale="gong", seed=3, layers=[("flute", "melody", 1, 0.6), ("pluck", "arp", 0, 0.45), ("pluck", "bass", -1, 0.4), ("wood", "wood", 0, 0.12)]),
 "road_theme":     dict(bpm=96, bars=8, root=62, scale="zhi", seed=4, layers=[("pluck", "melody", 1, 0.55), ("pluck", "bass", -1, 0.4), ("wood", "wood", 0, 0.2), ("pad", "drone", -1, 0.2)]),
 "linjiang_theme": dict(bpm=108, bars=8, root=65, scale="shang", seed=5, layers=[("pluck", "melody", 1, 0.6), ("pluck", "arp", 0, 0.4), ("pluck", "bass", -1, 0.4), ("kick", "kick", 0, 0.3), ("wood", "wood", 0, 0.2)]),
 "cangwu_theme":   dict(bpm=66, bars=8, root=57, scale="yu", seed=6, layers=[("pad", "drone", -1, 0.5), ("flute", "melody", 0, 0.5), ("bell", "bell", 0, 0.4), ("pluck", "bass", -1, 0.35)]),
 "marsh_theme":    dict(bpm=54, bars=6, root=58, scale="jue", seed=7, layers=[("pad", "drone", -1, 0.55), ("pluck", "sparse", 1, 0.35), ("bell", "bell", 0, 0.25), ("flute", "sparse", 0, 0.25)]),
 "night_theme":    dict(bpm=58, bars=6, root=64, scale="yu", seed=8, layers=[("pad", "drone", -1, 0.35), ("pluck", "sparse", 1, 0.35), ("flute", "sparse", 1, 0.2)]),
 "battle_theme":   dict(bpm=132, bars=8, root=57, scale="yu", seed=9, layers=[("pluck", "melody", 1, 0.55), ("pluck", "arp", 0, 0.4), ("pluck", "bass", -1, 0.5), ("kick", "kick", 0, 0.6), ("tom", "tom", 0, 0.4), ("wood", "wood", 0, 0.25)]),
 "duel_theme":     dict(bpm=120, bars=8, root=55, scale="shang", seed=10, layers=[("pluck", "melody", 1, 0.55), ("pluck", "bass", -1, 0.5), ("kick", "kick", 0, 0.5), ("wood", "wood", 0, 0.3), ("pad", "drone", -1, 0.2)]),
 "boss_theme":     dict(bpm=144, bars=8, root=52, scale="jue", seed=11, layers=[("pluck", "melody", 1, 0.6), ("pluck", "arp", 0, 0.45), ("pluck", "bass", -1, 0.55), ("kick", "kick", 0, 0.7), ("tom", "tom", 0, 0.55), ("bell", "bell", 0, 0.3), ("pad", "drone", -1, 0.3)]),
 "minigame_theme": dict(bpm=100, bars=8, root=67, scale="gong", seed=12, layers=[("pluck", "melody", 1, 0.55), ("pluck", "arp", 0, 0.35), ("wood", "wood", 0, 0.3), ("pluck", "bass", -1, 0.35)]),
 "festival_theme": dict(bpm=116, bars=8, root=65, scale="gong", seed=13, layers=[("pluck", "melody", 1, 0.6), ("flute", "melody", 1, 0.4), ("pluck", "arp", 0, 0.4), ("kick", "kick", 0, 0.35), ("wood", "wood", 0, 0.3), ("bell", "bell", 0, 0.3)]),
 "mystery_theme":  dict(bpm=50, bars=6, root=56, scale="jue", seed=14, layers=[("pad", "drone", -1, 0.55), ("bell", "bell", 0, 0.4), ("pluck", "sparse", 1, 0.3)]),
 "sorrow_theme":   dict(bpm=52, bars=6, root=57, scale="yu", seed=15, layers=[("flute", "melody", 0, 0.55), ("pad", "drone", -1, 0.4), ("pluck", "sparse", 0, 0.3)]),
 "ending_theme":   dict(bpm=66, bars=10, root=62, scale="gong", seed=16, layers=[("flute", "melody", 1, 0.6), ("pluck", "arp", 0, 0.5), ("pad", "drone", -1, 0.45), ("bell", "bell", 0, 0.3)]),
 "yanmen_theme":   dict(bpm=76, bars=8, root=55, scale="shang", seed=17, layers=[("pad", "drone", -1, 0.45), ("flute", "melody", 0, 0.5), ("tom", "tom", 0, 0.35), ("pluck", "bass", -1, 0.4)]),
 "penglai_theme":  dict(bpm=70, bars=8, root=66, scale="gong", seed=18, layers=[("pluck", "arp", 1, 0.45), ("flute", "melody", 1, 0.5), ("pad", "drone", -1, 0.35), ("bell", "bell", 0, 0.3)]),
 "victory_sting":  dict(bpm=100, bars=2, root=62, scale="gong", seed=19, loop=False, layers=[("pluck", "arp", 0, 0.6), ("flute", "melody", 1, 0.5), ("bell", "bell", 0, 0.4)]),
 "defeat_sting":   dict(bpm=60, bars=2, root=57, scale="yu", seed=20, loop=False, layers=[("pad", "drone", -1, 0.5), ("flute", "sparse", 0, 0.4), ("bell", "bell", 0, 0.3)]),
}

RULES = {
 "scenes": {"boot": "title_theme", "title": "title_theme", "hero_creation": "title_theme", "settings": "title_theme", "cultivation": "practice_theme",
            "sheet": "practice_theme", "arts": "practice_theme", "minigame": "minigame_theme", "ending": "ending_theme", "map": "road_theme"},
 "regions": {"jade_valley": "valley_theme", "linjiang": "linjiang_theme", "cangwu": "cangwu_theme", "marsh": "marsh_theme", "yanmen": "yanmen_theme", "penglai": "penglai_theme"},
 "backgrounds": {"valley_dawn": "valley_theme", "valley_day": "valley_theme", "village_dusk": "valley_theme", "riverside_day": "valley_theme", "terraces_green": "valley_theme",
                 "shrine_night": "night_theme", "ferry_dusk": "road_theme", "bamboo_mist": "road_theme", "night_camp": "night_theme", "city_docks": "linjiang_theme",
                 "city_market": "linjiang_theme", "city_night": "night_theme", "cangwu_day": "cangwu_theme", "cangwu_night": "night_theme", "marsh_day": "marsh_theme",
                 "marsh_night": "mystery_theme", "yanmen_fort": "yanmen_theme", "yanmen_snow": "yanmen_theme", "penglai_sea": "penglai_theme", "penglai_cave": "penglai_theme", "vault_stair": "mystery_theme", "vault_hall": "mystery_theme", "default": "valley_theme"},
 "events": {"f_spring_fair": "festival_theme", "q2_dragon_boat": "festival_theme", "q3_mid_autumn": "festival_theme", "q4_solstice": "festival_theme",
            "q3_hui_mask": "mystery_theme", "q4_temple": "mystery_theme", "q4_ferryman": "mystery_theme", "q3_theft": "sorrow_theme", "q4_elder_fork": "sorrow_theme",
            "f_shrine_first": "mystery_theme", "q3_tournament_1": "duel_theme", "q3_tournament_2": "duel_theme", "q3_tournament_3": "duel_theme", "y3c_midautumn": "festival_theme", "y3c_masks_offer": "mystery_theme", "y3c_lei_head": "sorrow_theme", "y3c_vigil": "sorrow_theme"},
 "battles": {"boss": ["y3_cliff_trial", "final_crisis", "q4_ambush", "cw_bout_3", "guild_night"], "duel": ["y3_chi_duel", "xie_duel", "cw_bout_1", "cw_bout_2", "training_match"], "default": "battle_theme"},
 "stings": {"victory": "victory_sting", "defeat": "defeat_sting"},
 "fallback": "valley_theme",
}


# ---- instruments (all numpy, mono) -------------------------------------------------------------------------------
def hz(m): return 440.0 * 2 ** ((m - 69) / 12.0)


def env_ad(n, a, d):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-t / d)


def pluck(f, dur):
    n = int(SR * dur); t = np.arange(n) / SR
    s = sum((1.0 / h) * np.sin(2 * np.pi * f * h * t) * np.exp(-t * (2.5 + 1.6 * h)) for h in range(1, 7))
    return s * np.minimum(1.0, t / 0.004) * 0.8


def flute(f, dur, rng):
    n = int(SR * dur); t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1.0, t / 0.4)
    s = np.sin(2 * np.pi * f * t * vib) + 0.25 * np.sin(2 * np.pi * 2 * f * t * vib) + 0.06 * rng.standard_normal(n) * np.exp(-t * 8)
    e = np.minimum(1.0, t / 0.06) * np.minimum(1.0, (dur - t) / 0.12 + 0.0)
    return s * np.clip(e, 0, 1) * 0.6


def pad(f, dur):
    n = int(SR * dur); t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * f * d * t + p) for d, p in ((1.0, 0.0), (1.003, 1.1), (0.997, 2.3), (2.0, 0.5)))
    e = np.minimum(1.0, t / (dur * 0.35)) * np.minimum(1.0, (dur - t) / (dur * 0.35))
    return s / 4.0 * np.clip(e, 0, 1)


def bell(f, dur):
    n = int(SR * dur); t = np.arange(n) / SR
    s = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * dc) for r, a, dc in ((1.0, 1.0, 1.6), (2.76, 0.5, 2.4), (5.4, 0.3, 3.2), (8.9, 0.15, 4.5)))
    return s * 0.5


def kick(dur=0.35):
    n = int(SR * dur); t = np.arange(n) / SR
    return np.sin(2 * np.pi * (50 + 90 * np.exp(-t * 30)) * t) * np.exp(-t * 9)


def tom(dur=0.4):
    n = int(SR * dur); t = np.arange(n) / SR
    return np.sin(2 * np.pi * (85 + 60 * np.exp(-t * 18)) * t) * np.exp(-t * 7) * 0.9


def wood(rng, dur=0.12):
    n = int(SR * dur); t = np.arange(n) / SR
    return (np.sin(2 * np.pi * 820 * t) * 0.7 + rng.standard_normal(n) * 0.25) * np.exp(-t * 38)


def put(buf, start, snd, gain):
    end = min(len(buf), start + len(snd))
    if start < len(buf):
        buf[start:end] += snd[:end - start] * gain


# ---- composition -----------------------------------------------------------------------------------------------
def degree_to_midi(root, scale, deg, octave):
    sc = SCALES[scale]
    return root + sc[deg % 5] + 12 * (deg // 5) + 12 * octave


def render(name, p):
    rng = np.random.default_rng(p["seed"])
    bpm, bars, root, scale = p["bpm"], p["bars"], p["root"], p["scale"]
    beat = 60.0 / bpm; step = beat / 2; steps = bars * 8
    loop = p.get("loop", True)
    total = int(SR * step * steps)
    tail = int(SR * 4.0)
    buf = np.zeros(total + tail)
    # motif: 8 eighth-note degrees, varied each bar (random walk on the pentatonic degrees)
    motif = [int(x) for x in np.cumsum(rng.integers(-2, 3, 8)) % 8 + 3]
    for inst, kind, octv, gain in p["layers"]:
        for bar in range(bars):
            b0 = bar * 8
            vary = bar % 4 == 3
            if kind == "melody":
                notes = list(motif)
                if vary:
                    notes = [(d + int(rng.integers(-2, 3))) for d in notes]
                if bar % 2 == 1:
                    notes = notes[::-1] if bar % 4 == 1 else [d + 2 for d in notes]
                i = 0
                while i < 8:
                    ln = int(rng.choice([1, 2, 2, 4]))
                    ln = min(ln, 8 - i)
                    if rng.random() < 0.18:
                        i += ln; continue
                    f = hz(degree_to_midi(root, scale, notes[i], octv))
                    dur = ln * step * (1.0 if inst == "flute" else 1.4)
                    snd = flute(f, dur, rng) if inst == "flute" else pluck(f, dur)
                    put(buf, int(SR * (b0 + i) * step), snd, gain)
                    i += ln
            elif kind == "arp":
                cyc = [0, 2, 4, 2] if bar % 2 == 0 else [0, 3, 4, 3]
                for i in range(8):
                    f = hz(degree_to_midi(root, scale, cyc[i % 4] + (2 if vary else 0), octv))
                    put(buf, int(SR * (b0 + i) * step), pluck(f, step * 2.4), gain * 0.8)
            elif kind == "bass":
                for i, d in ((0, 0), (4, 3 if bar % 2 else 2)):
                    put(buf, int(SR * (b0 + i) * step), pluck(hz(degree_to_midi(root, scale, d, octv)), step * 3.5), gain)
            elif kind == "drone":
                if bar % 2 == 0:
                    dd = 0 if bar % 4 == 0 else 3
                    dur = step * 16
                    put(buf, int(SR * b0 * step), pad(hz(degree_to_midi(root, scale, dd, octv)), dur), gain)
                    put(buf, int(SR * b0 * step), pad(hz(degree_to_midi(root, scale, dd + 2, octv)), dur), gain * 0.6)
            elif kind == "sparse":
                for i in range(0, 8, 2):
                    if rng.random() < 0.45:
                        d = int(rng.integers(0, 8))
                        f = hz(degree_to_midi(root, scale, d, octv))
                        dur = step * 4
                        snd = flute(f, dur, rng) if inst == "flute" else pluck(f, dur)
                        put(buf, int(SR * (b0 + i) * step), snd, gain)
            elif kind == "bell":
                if bar % 2 == 0:
                    put(buf, int(SR * b0 * step), bell(hz(degree_to_midi(root, scale, 4 if bar % 4 else 0, octv + 1)), 3.5), gain)
            elif kind == "kick":
                for i in (0, 4) if bpm < 110 else (0, 3, 4, 6):
                    put(buf, int(SR * (b0 + i) * step), kick(), gain)
            elif kind == "tom":
                for i in (2, 7) if bar % 2 == 0 else (3, 6, 7):
                    put(buf, int(SR * (b0 + i) * step), tom(), gain)
            elif kind == "wood":
                for i in (2, 6) if bpm < 100 else (1, 3, 5, 7):
                    put(buf, int(SR * (b0 + i) * step), wood(rng), gain)
    if loop:
        buf[:tail] += buf[total:total + tail]      # let the tail ring into the start: a seamless loop
    out = buf[:total] if loop else buf[:total + int(SR * 1.5)]
    peak = np.max(np.abs(out)) or 1.0
    out = out / peak * 0.7
    if not loop:
        out *= np.minimum(1.0, np.linspace(1, 0, len(out)) * 6)
    return out


def write_ogg(name, samples):
    pcm = (np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes()
    with tempfile.NamedTemporaryFile(suffix=".raw", delete=False) as f:
        f.write(pcm); raw = f.name
    os.makedirs(OUT, exist_ok=True)
    dst = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", raw, "-c:a", "libvorbis", "-q:a", "1", dst], check=True)
    os.unlink(raw)
    return os.path.getsize(dst)


def main():
    force = "--force" in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    total = 0
    catalog = []
    for name, p in T.items():
        catalog.append({"id": name, "file": f"res://audio/music/{name}.ogg", "loop": p.get("loop", True), "bpm": p["bpm"], "bars": p["bars"]})
        if only and name not in only:
            continue
        if not force and not only and os.path.exists(os.path.join(OUT, name + ".ogg")):
            continue          # never overwrite a finished track unless asked
        size = write_ogg(name, render(name, p))
        total += size
        print(f"{name}: {size // 1024} KB")
    os.makedirs(os.path.join(ROOT, "content", "audio"), exist_ok=True)
    json.dump({"tracks": catalog, "rules": RULES}, open(os.path.join(ROOT, "content", "audio", "music.json"), "w"), indent=1)
    print("total", total // 1024, "KB")


if __name__ == "__main__":
    main()
