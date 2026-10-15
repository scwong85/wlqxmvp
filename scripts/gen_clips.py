#!/usr/bin/env python3
"""Generates content/clips.json, content/minigames.json and their loc keys (M19)."""
import json, os
G = os.path.join(os.path.dirname(__file__), "..", "game", "content")
K = lambda t, p, f="neutral": {"t": t, "pose": p, "face": f}
CLIPS = {
 "training": ("valley_day", "练功中……", "Training…", [K(0, "idle"), K(0.4, "train"), K(2.0, "victory", "happy")]),
 "technique_practice": ("valley_dawn", "演练招式……", "Drilling techniques…", [K(0, "idle"), K(0.4, "sword", "angry"), K(2.0, "idle", "happy")]),
 "meditation": ("night_camp", "静坐吐纳……", "Meditating…", [K(0, "kneel"), K(2.2, "think", "happy")]),
 "fishing": ("riverside_day", "垂钓中……", "Fishing…", [K(0, "idle"), K(0.4, "fish"), K(2.0, "victory", "happy")]),
 "herb_gathering": ("terraces_green", "采药中……", "Gathering herbs…", [K(0, "walk"), K(0.8, "kneel"), K(2.0, "idle", "happy")]),
 "mining": ("shrine_night", "凿矿中……", "Mining…", [K(0, "idle"), K(0.3, "mine"), K(2.1, "victory", "happy")]),
 "hunting": ("valley_dawn", "山中狩猎……", "Hunting…", [K(0, "walk"), K(1.0, "sword", "angry"), K(2.0, "idle", "happy")]),
 "cooking": ("village_dusk", "灶前忙碌……", "Cooking…", [K(0, "idle"), K(0.5, "think", "happy"), K(2.0, "laugh", "happy")]),
 "music": ("valley_dusk" if False else "village_dusk", "抚琴吹笛……", "Playing music…", [K(0, "idle"), K(0.4, "music", "happy"), K(2.2, "bow", "happy")]),
 "chess": ("village_dusk", "对弈中……", "Playing weiqi…", [K(0, "idle"), K(0.4, "chess", "neutral"), K(1.6, "think"), K(2.1, "victory", "happy")]),
 "social_visit": ("village_dusk", "拜访乡邻……", "Visiting neighbours…", [K(0, "walk"), K(1.0, "bow", "happy"), K(1.8, "laugh", "happy")]),
 "rest": ("night_camp", "歇息片刻……", "Resting…", [K(0, "kneel", "sad"), K(1.6, "idle", "happy")]),
}
clips = []; zh = {}; en = {}
for cid, (bg, z, e, keys) in CLIPS.items():
    clips.append({"id": cid, "bg": bg, "duration": 2.4, "caption_key": f"clip.{cid}", "keys": keys})
    zh[f"clip.{cid}"] = z; en[f"clip.{cid}"] = e
mini = [{"id": "fishing", "activities": ["fishing"], "title_key": "minigame.fishing.title", "help_key": "minigame.fishing.help"}]
zh.update({"minigame.fishing.title": "垂钓", "minigame.fishing.help": "按住抬高钓竿，松开下沉。让鱼留在绿色区域内，渔获条满了就钓到了。",
  "minigame.start": "开始", "minigame.quick": "快速完成", "minigame.back": "返回", "minigame.collect": "收获", "minigame.skip_hint": "轻触跳过",
  "minigame.time": "剩余 {s} 秒", 
  "minigame.grade.perfect": "完美！", "minigame.grade.good": "不错！", "minigame.grade.ok": "尚可。", "minigame.grade.poor": "空手而归……",
  "minigame.result.mult": "收获倍率 ×{m}", "settings.minigames_on": "小游戏：开", "settings.minigames_off": "小游戏：关"})
en.update({"minigame.fishing.title": "Fishing", "minigame.fishing.help": "Hold to raise the rod, release to let it sink. Keep the fish inside the green bar until the catch meter is full.",
  "minigame.start": "Start", "minigame.quick": "Quick resolve", "minigame.back": "Back", "minigame.collect": "Collect", "minigame.skip_hint": "Tap to skip",
  "minigame.time": "{s}s left", 
  "minigame.grade.perfect": "Perfect!", "minigame.grade.good": "Nice!", "minigame.grade.ok": "Decent.", "minigame.grade.poor": "Nothing but weeds…",
  "minigame.result.mult": "Reward ×{m}", "settings.minigames_on": "Minigames: on", "settings.minigames_off": "Minigames: off"})
json.dump({"clips": clips}, open(os.path.join(G, "clips.json"), "w"), ensure_ascii=False, indent=1)
json.dump({"minigames": mini}, open(os.path.join(G, "minigames.json"), "w"), ensure_ascii=False, indent=1)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print(len(clips), "clips")
