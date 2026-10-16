#!/usr/bin/env python3
"""M23: registers the mining and music minigames. Run after the other generators. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
mp = os.path.join(G, "minigames.json"); m = json.load(open(mp))
m["minigames"] = [x for x in m["minigames"] if x["id"] not in ("mining", "music")]
for mid, act in (("mining", "mining"), ("music", "music")):
    m["minigames"].append({"id": mid, "activities": [act], "title_key": f"minigame.{mid}.title", "help_key": f"minigame.{mid}.help"})
json.dump(m, open(mp, "w"), ensure_ascii=False, indent=1)
T = {"minigame.mining.title": ("挖矿", "Mining"), "minigame.mining.help": ("游标扫过岩壁，在它经过发光矿脉时点按。共五锤，越准越好。", "A marker sweeps the rock face. Tap as it crosses the glowing vein. Five strikes; the closer the better."),
     "world.gate.realm": ("需要境界 {need}", "Needs realm {need}"),
     "minigame.music.title": ("抚琴", "Music"), "minigame.music.help": ("音符漂向金线，在它到达时点按。越准越好。", "Notes drift toward the gold line. Tap as each one arrives; the closer the better.")}
for lang, i in (("zh_CN", 0), ("en", 1)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update({k: v[i] for k, v in T.items()})
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok")
