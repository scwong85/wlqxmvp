#!/usr/bin/env python3
"""Adds story-board stage commands to the prologue dialogues and merges stage/hero loc keys (M18)."""
import json, os
G = os.path.join(os.path.dirname(__file__), "..", "game", "content")
WHO = {"story.speaker.elder": "elder", "story.speaker.villager": "villager", "story.speaker.leader": "leader"}
PLAN = {  # dialogue id -> (background, hero pose/face, extras [(who, slot, pose, face)])
 "day1_intro": ("valley_dawn", ("idle", "neutral"), []),
 "day2_path": ("valley_day", ("idle", "neutral"), []),
 "day4_battle": ("village_dusk", ("sword", "angry"), [("bandit", "far", "idle", "angry")]),
 "day4_win": ("village_dusk", ("victory", "happy"), []),
 "day4_lose": ("village_dusk", ("kneel", "sad"), []),
 "day5_faction": ("valley_day", ("idle", "neutral"), []),
 "day6_prepare": ("night_camp", ("think", "neutral"), []),
 "day7_crisis": ("village_dusk", ("idle", "surprised"), []),
 "crisis_final": ("shrine_night", ("sword", "angry"), [("bandit", "far", "idle", "angry")]),
}
p = os.path.join(G, "story", "dialogues.json"); d = json.load(open(p))
for dlg in d["dialogues"]:
    plan = PLAN.get(dlg["id"])
    if not plan:
        continue
    bg, (hp, hf), extras = plan
    who = []
    for n in dlg["nodes"]:
        w = WHO.get(n.get("speaker_key", ""))
        if w and w not in who:
            who.append(w)
    cmds = [{"c": "bg", "id": bg}, {"c": "show", "who": "hero", "slot": "left", "pose": hp, "face": hf}]
    slots = ["right", "center"]
    for w in who:
        cmds.append({"c": "show", "who": w, "slot": slots.pop(0), "pose": "idle", "face": "neutral"})
    for (w, slot, pose, face) in extras:
        cmds.append({"c": "show", "who": w, "slot": slot, "pose": pose, "face": face})
    if dlg["id"] in ("day4_battle", "crisis_final"):
        cmds.append({"c": "shake"})
    dlg["nodes"][0]["stage"] = cmds
json.dump(d, open(p, "w"), ensure_ascii=False, indent=1)

LOC = {"zh_CN": {"hero.default_name": "无名客", "hero.create.title": "创建主角", "hero.create.name": "姓名", "hero.create.gender": "性别", "hero.create.hair": "发型",
        "hero.create.hair_color": "发色", "hero.create.outfit": "衣色", "hero.create.skin": "肤色", "hero.create.confirm": "踏入江湖",
        "hero.gender.m": "男", "hero.gender.f": "女", "hero.hair.0": "束髻", "hero.hair.1": "马尾", "hero.hair.2": "短发", "hero.hair.3": "长发",
        "dialogue.log": "回顾", "dialogue.log_line": "{who}：{text}", "dialogue.log_close": "关闭", "settings.animations_on": "动画：开", "settings.animations_off": "动画：关"},
       "en": {"hero.default_name": "Wanderer", "hero.create.title": "Create your hero", "hero.create.name": "Name", "hero.create.gender": "Gender", "hero.create.hair": "Hair style",
        "hero.create.hair_color": "Hair colour", "hero.create.outfit": "Outfit colour", "hero.create.skin": "Skin tone", "hero.create.confirm": "Enter the jianghu",
        "hero.gender.m": "Male", "hero.gender.f": "Female", "hero.hair.0": "Topknot", "hero.hair.1": "Ponytail", "hero.hair.2": "Short", "hero.hair.3": "Long",
        "dialogue.log": "Log", "dialogue.log_line": "{who}: {text}", "dialogue.log_close": "Close", "settings.animations_on": "Animations: on", "settings.animations_off": "Animations: off"}}
for lang, kv in LOC.items():
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok")
