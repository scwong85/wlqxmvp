#!/usr/bin/env python3
"""M22d: Year 1 quarter 4 (the sinking-star marsh, weeks 46 to 60) and the Elder Mo fork. Run AFTER gen_year1_q3. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json")

OWN_AREAS = ["ms_flats", "ms_reeds", "ms_temple"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
PREFIX = ("q4_", "ry4_")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] != "q4_ambush"]
units["units"] = [u for u in units["units"] if u["id"] not in ["gate_scout", "gate_blade", "gate_captain"]]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "elder": "story.speaker.elder",
       "ferry": "npc.ferryman", "shen": "npc.shen_qinghe", "lu": "npc.lu_chenzhou", "bai": "npc.bai_yan", "capt": "npc.gate_captain"}
WHO = {"elder": "elder", "wander": "wanderer", "ferry": "wanderer", "shen": "shen_qinghe", "lu": "lu_chenzhou", "bai": "bai_yan", "capt": "bandit"}
L("npc.ferryman", "老摆渡人", "The Old Ferryman"); L("npc.gate_captain", "门下头目", "The Gate's Captain")
BG = {"ms_flats": "marsh_day", "ms_reeds": "marsh_day", "ms_temple": "marsh_night", "lj_docks": "city_docks", "valley_village": "village_dusk"}
ATTR = lambda i, n=1: {"type": "attr", "id": i, "amount": n}
FLAG = lambda i: {"type": "flag", "id": i}
LEAD = lambda i: {"type": "lead", "id": i}
SCHED = lambda i, a, b: {"type": "schedule", "id": i, "min": a, "max": b}
BOND = lambda c, n: {"type": "bond", "id": c, "amount": n}
STAMINA = lambda n: {"type": "stamina", "id": "stamina", "amount": n}
BATTLE = lambda i: {"type": "battle", "id": i}
RES = lambda i, n: {"type": "resource", "id": i, "amount": n}


def area(id, zn, en_, dz, de, wanders, **kw):
    a = {"id": id, "region": "marsh", "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": 2, "wander": [],
         "open_default": True, "requires": {"lead": ["marsh_open"], "week_min": 46}}
    L(a["name_key"], zn, en_); L(a["desc_key"], dz, de)
    for i, (z, e, rw) in enumerate(wanders):
        k = f"world.area.{id}.w{i+1}"; L(k, z, e); a["wander"].append({"text_key": k, "rewards": [{"type": t, "id": r, "amount": n} for t, r, n in rw]})
    a.update(kw); areas["areas"].append(a)


def event(id, kind, area_id, lines, effects_end=None, choices=None, title=None, window=None, entry=None, **kw):
    ev = {"id": id, "kind": kind, "area": area_id, "scene": {"dialogue": "ev_" + id}, "title_key": f"event.{id}.title"}
    L(ev["title_key"], *title)
    if window: ev["window"] = {"from": window[0], "to": window[1]}
    ev.update(kw); events["events"].append(ev)
    nodes = []; who = []
    for i, (sp, z, e) in enumerate(lines):
        k = f"event.{id}.{i+1}"; L(k, z, e)
        n = {"id": f"n{i+1}", "text_key": k, "speaker_key": SPK[sp]}
        if sp in WHO and WHO[sp] not in who: who.append(WHO[sp])
        last = i == len(lines) - 1
        if not last: n["next"] = f"n{i+2}"
        elif choices:
            n["choices"] = []
            for cid, cz, ce, ef in choices:
                ck = f"event.{id}.c.{cid}"; L(ck, cz, ce)
                n["choices"].append({"id": cid, "label_key": ck, "next": "", "effects": ef})
        else:
            n["next"] = ""
            if effects_end: n["on_enter"] = effects_end
        nodes.append(n)
    cmds = [{"c": "bg", "id": BG[area_id]}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "neutral"}]
    for w in who[:1]:
        cmds.append({"c": "show", "who": w, "slot": "right", "pose": "idle", "face": "neutral"})
    nodes[0]["stage"] = cmds
    dlgs["dialogues"].append({"id": "ev_" + id, "entry": entry or [{"node": "n1"}], "nodes": nodes})
    return nodes


# ===================================================================== AREAS
area("ms_flats", "钓滩", "Fishing Flats", "浅水与泥滩连成一片，雾里传来桨声。", "Shallows and mudflats run together; oars knock somewhere in the fog.",
     [("你在滩边坐了半日，钓上来几尾肥鱼。", "You sit at the flats half a day and land a few fat fish.", [("resource", "coins", 8)]),
      ("泥地里留着不知谁的脚印，你顺着看了一会儿。", "Someone's footprints cross the mud; you follow them a while.", [("attr", "insight", 1)])])
area("ms_reeds", "芦苇迷阵", "Reed Maze", "高过人头的芦苇，一转弯就忘了来路。", "Reeds taller than a man; one turn and the way back is lost.",
     [("你在芦苇间辨着风向，慢慢走出一条路。", "You read the wind among the reeds and slowly pick a way.", [("attr", "agility", 1)]),
      ("苇丛里藏着几块被水冲出的矿石。", "A few ore chunks, washed out by the water, lie hidden in the reeds.", [("resource", "ore", 2)])])
area("ms_temple", "沉星古庙", "Sunken Star Temple", "半截沉在水里的石庙，墙上刻满星图。", "A stone temple half-sunk in water, its walls carved with star charts.",
     [("你对着残墙上的星图看了许久。", "You study the star charts on the broken walls for a long time.", [("attr", "insight", 1)]),
      ("庙里静得出奇，你借机调息了一阵。", "The temple is eerily quiet; you use it to steady your breath.", [("stamina", "stamina", 8)])],
     requires={"lead": ["temple_path"], "week_min": 46})

# ===================================================================== STORY
event("q4_marsh_rumor", "fixed", "lj_docks",
      [("wander", "码头上的船夫们都在低声议论：「沉星泽里夜夜有星光，从水里往天上冒。」", "Boatmen at the docks mutter: \"In the Sunken-Star Marsh a light climbs from the water to the sky every night.\""),
       ("hero", "玉符在怀里微微发热。也许该去看看。", "The tally warms faintly in my coat. Perhaps it is time to look.")],
      [LEAD("marsh_open"), SCHED("q4_ferryman", 1, 4)], title=("沉星泽的传闻", "Rumors of the Marsh"), window=(46, 52), priority=5, requires={"week_min": 46},
      on_miss=[LEAD("marsh_open"), SCHED("q4_ferryman", 1, 4)])
event("q4_ferryman", "fixed", "ms_flats",
      [("ferry", "钓滩尽头，一位老人撑着小舟：「去沉星庙的路，只有星星知道。你怎么问？」", "At the end of the flats an old man poles a small boat: \"Only the stars know the way to the temple. How do you ask?\""),
       ("ferry", "「用耳朵听水，还是用眼睛看天？」", "\"Do you listen to the water, or watch the sky?\"")],
      title=("老摆渡人", "The Old Ferryman"), scheduled_only=True, priority=5,
      choices=[("water", "听水", "Listen to the water", [LEAD("temple_path"), ATTR("spirit", 2), SCHED("q4_reeds", 1, 4)]),
               ("sky", "看天", "Watch the sky", [LEAD("temple_path"), ATTR("insight", 2), SCHED("q4_reeds", 1, 4)])],
      on_miss=[LEAD("temple_path"), SCHED("q4_reeds", 1, 4)])
event("q4_reeds", "fixed", "ms_reeds",
      [("narr", "芦苇间起了雾。你听见有人在不远处喊你的名字，声音很熟，又不太对。", "Fog rises among the reeds. Someone calls your name nearby, familiar but not quite right."),
       ("hero", "我停下脚步，分辨着声音的方向。", "I stop and try to place where the voice is coming from.")],
      title=("芦苇迷阵", "The Reed Maze"), scheduled_only=True, priority=5,
      choices=[("follow", "循声而去", "Follow the voice", [FLAG("reeds_followed"), STAMINA(-6), SCHED("q4_temple", 1, 5), BOND("lu_chenzhou", 1)]),
               ("wind", "顺着风向走", "Follow the wind", [FLAG("reeds_wind"), ATTR("agility", 2), SCHED("q4_temple", 1, 5), BOND("shen_qinghe", 1)]),
               ("mark", "折苇作记，一步步探", "Bend reeds to mark the way", [FLAG("reeds_marked"), ATTR("insight", 2), SCHED("q4_temple", 1, 5), BOND("bai_yan", 1)])],
      on_miss=[SCHED("q4_temple", 1, 5)])
event("q4_solstice", "fixed", "valley_village",
      [("narr", "冬至夜，村里家家蒸着汤圆，祠堂前点起了长明灯。", "On Winter Solstice night every house steams dumplings and the shrine lamp is lit."),
       ("elder", "墨长老递给你一碗热汤：「走得再远，也别忘了回来过节。」", "Elder Mo hands you a hot bowl. \"However far you go, come home for the feast.\""),
       ("narr", "你想把这碗汤分一半给谁？", "Whom do you want to share the bowl with?")],
      title=("冬至夜", "Winter Solstice"), window=(53, 54), priority=6, requires={"week_min": 53},
      choices=[("shen", "沈青禾", "Shen Qinghe", [BOND("shen_qinghe", 2), STAMINA(8)]),
               ("lu", "陆沉舟", "Lu Chenzhou", [BOND("lu_chenzhou", 2), STAMINA(8)]),
               ("bai", "白砚", "Bai Yan", [BOND("bai_yan", 2), STAMINA(8)]),
               ("elder", "墨长老", "Elder Mo", [FLAG("solstice_elder"), ATTR("spirit", 2), STAMINA(8)])])
event("q4_temple", "fixed", "ms_temple",
      [("narr", "石庙深处，一面石门嵌在墙里。你怀里的玉符忽然发烫，门缝中透出星光。", "Deep in the temple a stone door is set into the wall. The tally burns warm and starlight seeps through the seam."),
       ("narr", "门没有开。可石壁上的星图，亮起了其中一颗。", "The door stays shut. But one star on the carved chart lights up."),
       ("hero", "第一颗星……原来这就是九曜门。", "The first star... so this is the Nine-Star Gate.")],
      [LEAD("vault_gate"), FLAG("temple_seen"), ATTR("insight", 2), SCHED("q4_ambush", 1, 3)], title=("沉星古庙", "The Sunken Temple"),
      scheduled_only=True, priority=5, on_miss=[SCHED("q4_ambush", 1, 3)])
event("q4_ambush", "fixed", "ms_flats",
      [("capt", "归途的滩涂上，十几个灰衣人从芦苇里站起。头目冷笑：「玉符留下，人可以走。」", "On the flats back, a dozen grey-clad figures rise from the reeds. Their captain sneers: \"Leave the tally and you may walk.\""),
       ("hero", "这就是九曜门的探子。我握紧了拳。", "These are the Gate's probes. I clench my fists.")],
      title=("滩涂伏击", "Ambush on the Flats"), scheduled_only=True, priority=6,
      choices=[("fight", "迎战", "Stand and fight", [BATTLE("q4_ambush")])],
      on_miss=[FLAG("ambush_lost")])

# ---- the Elder Mo fork: one scene, three openings chosen by flags
fork_lines = {
    "live": [("elder", "你们回来了。村口的灯，我一直没熄。", "You are back. I never let the lamp at the gate go out."),
             ("elder", "村子没事，你也没事。这是三年来，我第一次睡得安稳。", "The village is safe and so are you. For the first time in years I slept soundly."),
             ("elder", "玉谷我来守。你们去走你们的路。", "I will keep Jade Valley. You go and walk your road.")],
    "retire": [("elder", "你们赢了，可村里……失去了人。", "You won, but the village lost someone."),
               ("elder", "我守不住这里了。让我跟着你们吧，我这把老骨头，还能出主意。", "I cannot hold this place any more. Let me follow you; these old bones can still give counsel.")],
    "fall": [("narr", "你们赶回玉谷时，祠堂前的灯已经熄了。", "By the time you reach Jade Valley, the lamp before the shrine has gone out."),
             ("elder", "墨长老倚在门槛上，将一枚旧印放进你手里：「别回头。九曜……不止一道门。」", "Elder Mo leans in the doorway and presses an old seal into your hand: \"Do not look back. The Nine Stars are more than one gate.\""),
             ("narr", "他的手松开了。", "His hand loosens.")]}
ev = {"id": "q4_elder_fork", "kind": "fixed", "area": "valley_village", "scene": {"dialogue": "ev_q4_elder_fork"}, "title_key": "event.q4_elder_fork.title",
      "window": {"from": 59, "to": 60}, "priority": 9, "requires": {"week_min": 59}}
L(ev["title_key"], "墨长老的归处", "Elder Mo's Fate")
effects = {"live": [FLAG("valley_kept"), FLAG("fork_done"), ATTR("spirit", 2)], "retire": [FLAG("elder_retired"), FLAG("fork_done"), LEAD("elder_advisor")],
           "fall": [FLAG("elder_fallen"), FLAG("fork_done"), FLAG("elder_seal"), LEAD("elder_seal_lead")]}
nodes = []; entry = []
for key, lines in fork_lines.items():
    for i, (sp, z, e) in enumerate(lines):
        nid = f"{key}{i+1}"; k = f"event.q4_elder_fork.{key}.{i+1}"; L(k, z, e)
        n = {"id": nid, "text_key": k, "speaker_key": SPK[sp], "next": "" if i == len(lines) - 1 else f"{key}{i+2}"}
        if i == len(lines) - 1: n["on_enter"] = effects[key]
        if i == 0: n["stage"] = [{"c": "bg", "id": "village_dusk"}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "neutral"}, {"c": "show", "who": "elder", "slot": "right", "pose": "idle", "face": "neutral"}]
        nodes.append(n)
entry = [{"if": {"flag": "ambush_lost"}, "node": "fall1"}, {"if": {"flag": "villager_saved"}, "node": "live1"}, {"node": "retire1"}]
events["events"].append(ev)
dlgs["dialogues"].append({"id": "ev_q4_elder_fork", "entry": entry, "nodes": nodes})
# a missed fork resolves as the safest outcome so the year always closes
ev["on_miss"] = [FLAG("fork_done"), FLAG("elder_retired"), LEAD("elder_advisor")]

RANDOM = [
 ("ry4_flats_fish", "ms_flats", [("narr", "浮标一沉，你提起一条肥鱼。", "The float dips and you lift a fat fish.")], [RES("coins", 6), ATTR("body", 1)], ("钓滩小憩", "A Quiet Cast"), 3, 5),
 ("ry4_flats_mist", "ms_flats", [("narr", "雾里传来桨声，却始终看不见船。", "Oars sound in the mist but no boat appears.")], [ATTR("spirit", 1)], ("雾中桨声", "Oars in the Mist"), 3, 6),
 ("ry4_reeds_birds", "ms_reeds", [("narr", "一群白鹭从苇间惊起，你顺着它们飞的方向走了一段。", "Egrets burst from the reeds and you follow where they fly.")], [ATTR("agility", 1)], ("惊起白鹭", "Startled Egrets"), 3, 5),
 ("ry4_reeds_ore", "ms_reeds", [("narr", "你在泥里踩到一块硬物，是矿石。", "Your boot strikes something hard in the mud: ore.")], [RES("ore", 2)], ("泥里的矿石", "Ore in the Mud"), 2, 8),
 ("ry4_temple_chart", "ms_temple", [("narr", "你照着星图的线条，在掌心画了一遍又一遍。", "You trace the chart's lines on your palm over and over.")], [ATTR("insight", 1), ATTR("spirit", 1)], ("临摹星图", "Tracing the Chart"), 3, 6),
 ("ry4_temple_rest", "ms_temple", [("narr", "庙里的石阶干燥，你坐下来休息。", "The temple steps are dry; you sit and rest.")], [STAMINA(10)], ("庙中小憩", "A Rest in the Temple"), 3, 4),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd)

# ===================================================================== AMBUSH BATTLE
units["units"].append({"id": "gate_scout", "stats": {"hp": 30, "body": 5, "power": 6, "agility": 6, "spirit": 4}, "techniques": ["swift_dash"]})
units["units"].append({"id": "gate_blade", "stats": {"hp": 44, "body": 7, "power": 9, "agility": 6, "spirit": 5}, "techniques": ["club_smash"]})
units["units"].append({"id": "gate_captain", "stats": {"hp": 72, "body": 9, "power": 11, "agility": 7, "spirit": 7}, "techniques": ["club_smash"]})
L("combat.unit.gate_scout", "九曜探子", "Gate Scout"); L("combat.unit.gate_blade", "九曜刀手", "Gate Blade"); L("combat.unit.gate_captain", "九曜头目", "Gate Captain")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
scen["scenarios"].append({"id": "q4_ambush", "battle_id": "q4_ambush", "max_rounds": 12, "terrain": [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"], [0, 2, "hazard"]],
    "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(["gate_captain", "gate_blade", "gate_blade", "gate_scout", "gate_scout"])],
    "objective": {"defeat_all": True},
    "on_victory": {"rewards": [{"type": "resource", "id": "coins", "amount": 25}, {"type": "relationship", "id": "$active", "amount": 2}], "flags": ["ambush_won"]},
    "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -4}], "flags": ["ambush_lost"]}})
L("combat.scenario.q4_ambush", "滩涂伏击", "Ambush on the Flats"); L("combat.scenario.q4_ambush.objective", "击败九曜门的全部伏兵。", "Defeat every Gate ambusher."); L("battle.q4_ambush", "滩涂伏击", "Ambush on the Flats")

LEADS = {"marsh_open": ("沉星泽", "The Sunken-Star Marsh", "传闻沉星泽夜夜有星光自水中升起。", "Rumor says starlight rises from the Sunken-Star Marsh each night."),
         "temple_path": ("通往古庙的路", "The Way to the Temple", "老摆渡人指了去沉星庙的路。", "The old ferryman has shown the way to the sunken temple."),
         "vault_gate": ("九曜门", "The Nine-Star Gate", "沉星庙里的石门对玉符有反应，其中一颗星亮了。", "The temple's stone door answered the tally and one star lit."),
         "elder_advisor": ("墨长老同行", "Elder Mo Travels With You", "墨长老卸下守村之责，随你同行出主意。", "Elder Mo has laid down the village watch and travels with you as an advisor."),
         "elder_seal_lead": ("墨长老的旧印", "Elder Mo's Seal", "墨长老留下一枚旧印，玉谷的将来待你决断。", "Elder Mo left an old seal; the valley's future is yours to decide.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("combat/scenarios.json", scen); dump("combat/units.json", units)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events", len(areas["areas"]), "areas")
