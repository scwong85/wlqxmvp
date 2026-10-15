#!/usr/bin/env python3
"""Generates content/world/{areas,events,event_dialogues}.json and merges loc keys (valley set, M16)."""
import json, os
G = os.path.join(os.path.dirname(__file__), "..", "game", "content")
LOC = {"zh_CN": {}, "en": {}}
def L(key, zh, en): LOC["zh_CN"][key] = zh; LOC["en"][key] = en

SP = {"narr": ("world.speaker.narrator", "旁白", "Narrator"), "vill": ("world.speaker.villager", "村民", "Villager"),
      "elder": ("story.speaker.elder", None, None), "hero": ("world.speaker.hero", "我", "Me"),
      "wander": ("world.speaker.wanderer", "过路人", "Wayfarer")}
for k, (key, zh, en) in SP.items():
    if zh: L(key, zh, en)

areas, events, dialogues = [], [], []
def area(id, zh, en, dz, de, wanders, **kw):
    a = {"id": id, "region": kw.pop("region", "jade_valley"), "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": kw.pop("cost", 1), "wander": []}
    L(a["name_key"], zh, en); L(a["desc_key"], dz, de)
    for i, (z, e, rw) in enumerate(wanders):
        k = f"world.area.{id}.w{i+1}"; L(k, z, e); a["wander"].append({"text_key": k, "rewards": [{"type": t, "id": r, "amount": n} for t, r, n in rw]})
    a.update(kw); areas.append(a)

def event(id, kind, area_id, lines, effects_end=None, choices=None, window=None, **kw):
    """lines: [(speaker, zh, en)]; choices: [(id, zh, en, effects)] attached to last line."""
    ev = {"id": id, "kind": kind, "area": area_id, "scene": {"dialogue": "ev_" + id}}
    if window: ev["window"] = {"from": window[0], "to": window[1]}
    ev.update(kw); events.append(ev)
    nodes = []
    for i, (sp, zh, en) in enumerate(lines):
        k = f"event.{id}.{i+1}"; L(k, zh, en)
        n = {"id": f"n{i+1}", "text_key": k, "speaker_key": SP[sp][0]}
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
    dialogues.append({"id": "ev_" + id, "entry": [{"node": "n1"}], "nodes": nodes})

attr = lambda i, n=1: {"type": "attr", "id": i, "amount": n}
res = lambda i, n: {"type": "resource", "id": i, "amount": n}
flag = lambda i: {"type": "flag", "id": i}

# ---- areas
area("valley_village", "玉谷村", "Jade Valley Village", "炊烟、石板路与人情，江湖的起点。", "Chimney smoke, flagstones and neighbours: where every road begins.",
     [("你在村口听老人讲了半个时辰的旧事。", "You spend half an hour at the village gate listening to an old man's tales.", [("attr", "insight", 1)]),
      ("集市上几个孩子围着你要听故事，你顺手得了几枚铜钱。", "Children crowd round for a story at the market; a few coins find your hand.", [("resource", "coins", 8)]),
      ("茶摊的热茶让你松了口气。", "A cup of hot tea at the stall lets you breathe.", [("stamina", "stamina", 6)])], open_default=True)
area("river_bend", "回龙湾", "Dragon-Return Bend", "溪水在这里拐了个弯，鱼儿最多。", "The stream turns here, and the fish gather.",
     [("你在浅滩拾到几尾落网的鱼。", "You gather a few fish stranded in the shallows.", [("resource", "food", 2)]),
      ("水声让你心神渐静。", "The sound of water settles your mind.", [("attr", "spirit", 1)])], open_default=True)
area("herb_terraces", "药圃梯田", "Herb Terraces", "山坡上一层层药圃，春夏最盛。", "Terraced herb beds climb the slope, lushest in spring and summer.",
     [("你顺手采了些寻常草药。", "You pick a handful of common herbs.", [("resource", "herbs", 2)]),
      ("山路陡峭，一趟走下来脚下生风。", "The steep path leaves your legs lighter.", [("attr", "agility", 1)])], open_default=True, seasons=[0, 1, 2])
area("old_shrine", "荒废山神庙", "Abandoned Mountain Shrine", "香火断了许多年，却仍有人影出没。", "The incense died years ago, yet someone still comes and goes.",
     [("残碑上的字迹让你若有所悟。", "The worn stele sets you thinking.", [("attr", "insight", 1)]),
      ("你在神龛前静坐片刻，气息平稳了许多。", "You sit before the altar a while; your breathing evens out.", [("stamina", "stamina", 6)])], cost=1)
area("ferry_dock", "临江渡口", "Linjiang Ferry Dock", "通往山外的渡口，消息比船来得快。", "The ferry out of the valley, where news arrives faster than boats.",
     [("船夫给你讲了几桩江湖轶事。", "The boatman tells you a few tales of the jianghu.", [("attr", "insight", 1)]),
      ("你帮着搬了几件货，得了些酬劳。", "You help carry some cargo and are paid.", [("resource", "coins", 12)])], region="linjiang", cost=2, open_default=True,
     requires={"lead": ["ferry_rumor"], "week_min": 12})

# ---- fixed
event("f_aftermath", "fixed", "valley_village",
      [("narr", "山贼退去的第二天，村口仍弥漫着焦糊味，众人默默收拾残局。", "Two days after the raid the village gate still smells of smoke, and everyone quietly clears the wreckage."),
       ("elder", "「他们不是寻常山贼。」墨长老低声道，「刀法有门路。这件事，没完。」", "\"Those were no ordinary bandits,\" Elder Mo says quietly. \"Their blades had schooling. This is not over.\""),
       ("hero", "我点点头，把话记在心里。", "I nod and keep the words close.")],
      [flag("aftermath_seen"), {"type": "schedule", "id": "f_gossip", "min": 1, "max": 4}, attr("spirit")],
      window=(6, 10), priority=5)
event("f_gossip", "fixed", "valley_village",
      [("vill", "「听说了吗？那些人撤退时往后山去了，山神庙那边夜里有火光。」", "\"Heard? When they pulled back they went up the rear hill. There've been lights at the shrine at night.\""),
       ("hero", "山神庙……荒了许多年了。值得去看看。", "The shrine… abandoned for years. Worth a look.")],
      [{"type": "lead", "id": "shrine_rumor"}, {"type": "unlock_area", "id": "old_shrine"}, {"type": "schedule", "id": "f_shrine_first", "min": 1, "max": 6}],
      priority=4)
event("f_shrine_first", "fixed", "old_shrine",
      [("narr", "神龛前灰尘上有新鲜的脚印，角落里蹲着两个可疑的人影。", "Fresh footprints cross the dust before the altar, and two shady figures crouch in a corner."),
       ("wander", "「谁？！」他们抽出短刀。", "\"Who's there?!\" They draw short blades.")],
      choices=[("fight", "出手拿下他们", "Take them on", [flag("shrine_seen"), {"type": "lead", "id": "ferry_rumor"}, {"type": "battle", "id": "bandit_scouts"}]),
               ("sneak", "悄悄退走，记下他们说的话", "Slip away and note what they say", [flag("shrine_seen"), {"type": "lead", "id": "ferry_rumor"}, attr("insight", 2)])],
      requires={"lead": ["shrine_rumor"]}, priority=3, on_miss=[flag("shrine_missed")])
event("f_spring_fair", "fixed", "valley_village",
      [("narr", "春集开张，彩绳挂满了村道，连隔壁镇的商贩都来了。", "The spring fair opens; coloured cords hang across the lane and traders have come from the next town."),
       ("vill", "「小哥，来碗热汤，沾沾喜气！」", "\"Come have a bowl of hot soup and share the cheer!\""),
       ("hero", "我帮着摆了半天摊，收获不小。", "I help set up stalls all afternoon and come away well paid.")],
      [res("coins", 25), res("food", 2)], window=(11, 15), requires={"season": [0]}, on_miss=[flag("fair_missed")])
event("f_herb_lesson", "fixed", "herb_terraces",
      [("elder", "「采药不是拔草。」墨长老蹲下身，「认根、辨时、留种，这是规矩。」", "\"Gathering herbs is not weeding,\" Elder Mo says, crouching. \"Know the root, read the season, leave the seed. Those are the rules.\"")],
      choices=[("learn", "认真跟着学", "Study carefully", [res("herbs", 3), attr("insight"), flag("herb_lesson_done")]),
               ("help", "只帮着背药篓", "Just carry the basket", [res("herbs", 1), res("coins", 6), flag("herb_lesson_done")])],
      window=(8, 20), requires={"week_min": 8}, on_miss=[flag("herb_missed")])
event("f_ferry_rumor", "fixed", "ferry_dock",
      [("wander", "渡口的老船夫压低声音：「山神庙那伙人的头目，坐过我的船，去了苍梧方向。」", "The old ferryman lowers his voice: \"The ringleader of the shrine crowd rode my boat, headed toward Cangwu.\""),
       ("hero", "苍梧……这条线索我收下了。", "Cangwu… I'll take that thread.")],
      [flag("ferry_seen"), attr("insight")], window=(20, 40), requires={"lead": ["ferry_rumor"]})

# ---- random
event("r_village_chat", "random", "valley_village",
      [("vill", "「听说山外不太平，你学艺可得上心啊。」", "\"They say it's rough outside the valley. Take your training seriously.\""),
       ("hero", "我笑着应下，心里却记住了这句话。", "I smile and agree, but the words stick.")],
      [attr("spirit")], weight=3, cooldown=4)
event("r_herb_find", "random", "herb_terraces",
      [("narr", "石缝里长着一丛少见的草药，色泽鲜亮。", "A rare herb grows bright in a rock crevice.")],
      [res("herbs", 3)], weight=3, cooldown=3, requires={"season": [0, 1, 2]})
event("r_fish_tale", "random", "river_bend",
      [("vill", "一位老渔夫递来半尾烤鱼：「年轻人，水急的地方，鱼才有劲。」", "An old fisherman hands you half a grilled fish: \"Young one, the fish are strong where the water runs fast.\"")],
      [res("food", 2), {"type": "stamina", "id": "stamina", "amount": 5}], weight=3, cooldown=3)
event("r_bandit_stray", "random", "river_bend",
      [("wander", "「站住！把钱留下！」落单的山贼从芦苇里蹿出来。", "\"Halt! Leave your coins!\" A straggling bandit leaps from the reeds.")],
      choices=[("fight", "迎战", "Fight", [{"type": "battle", "id": "bandit_scouts"}]),
               ("pay", "破财消灾", "Pay him off", [res("coins", -10)])],
      weight=2, cooldown=8, requires={"week_min": 6})
event("r_shrine_dream", "random", "old_shrine",
      [("narr", "你在残垣边打了个盹，梦见一位披甲武人在院中练剑。", "You doze by the broken wall and dream of an armoured swordsman drilling in the courtyard."),
       ("hero", "醒来时，手心竟有些发烫。", "I wake with my palms oddly warm.")],
      [attr("spirit"), attr("power")], weight=2, cooldown=10)
event("r_elder_lesson", "random", "valley_village",
      [("elder", "「出手前先看脚。」墨长老随口点拨了你一句，你听得入神。", "\"Watch the feet before you strike,\" Elder Mo remarks in passing, and you listen closely.")],
      [attr("agility")], weight=2, cooldown=15)
event("r_winter_frost", "random", "valley_village",
      [("narr", "霜重如雪，村民们围着火塘取暖，邀你同坐。", "Frost lies thick as snow; villagers gather round the hearth and invite you to sit.")],
      [{"type": "stamina", "id": "stamina", "amount": 8}], weight=4, cooldown=6, requires={"season": [3]})

for k,z,e in [("world.gate.week","需第 {need} 周之后","Not before week {need}"),("world.gate.too_late","时机已过","Too late"),("world.gate.season","此季节无法前往","Not in this season"),("world.gate.event","需先经历某件事","Something must happen first"),("world.gate.event_done","此事已了结","Already settled"),("world.gate.lead","还没有相关线索","No lead yet"),("world.gate.path","需要特定门派","Needs a specific school"),("world.area.unknown","未知之地","Unknown place"),("world.area.closed","此地已无法进入","This place is closed"),("world.area.locked","尚未发现此处","Not discovered yet"),("world.area.season","此季节不宜前往","Not the season for it")]: L(k,z,e)
TITLES = {"f_aftermath": ("劫后余波", "Aftermath"), "f_gossip": ("村中风声", "Village Gossip"), "f_shrine_first": ("荒庙人影", "Figures at the Shrine"),
  "f_spring_fair": ("春集", "Spring Fair"), "f_herb_lesson": ("采药课", "Herb Lesson"), "f_ferry_rumor": ("渡口传闻", "Ferry Rumour"),
  "r_village_chat": ("村口闲谈", "Gate Talk"), "r_herb_find": ("奇草", "A Rare Herb"), "r_fish_tale": ("渔夫的话", "The Fisherman's Word"),
  "r_bandit_stray": ("落单山贼", "Straggling Bandit"), "r_shrine_dream": ("庙中梦", "Dream at the Shrine"), "r_elder_lesson": ("长老点拨", "Elder's Hint"),
  "r_winter_frost": ("霜夜火塘", "Frosty Hearth")}
for ev in events:
    ev["title_key"] = f"event.{ev['id']}.title"; L(ev["title_key"], *TITLES[ev["id"]])
LEADS = {"shrine_rumor": ("山神庙的火光", "Lights at the Shrine", "后山的山神庙夜里有人出没，也许与袭击村子的人有关。", "Someone moves around the hill shrine at night, perhaps the raiders."),
  "ferry_rumor": ("渡口的去向", "Where the Ferry Went", "袭击者的头目向苍梧方向去了，渡口的船夫也许知道更多。", "The raiders' leader went toward Cangwu; the ferryman may know more.")}
for k, (zn, en, zd, ed) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en); L(f"world.lead.{k}.desc", zd, ed)

for k,z,e in [("map.title","江湖地图","Map"),("map.tab.map","地图","Map"),("map.tab.journal","手记","Journal"),("map.back","返回","Back"),
 ("map.go","前往 · {cost} 个时段","Go · {cost} slot(s)"),("map.state.due","有要事","Something due"),("map.state.open","可前往","Open"),("map.state.locked","未开启","Locked"),("map.state.closed","已封闭","Closed"),
 ("map.cost","路程：{cost} 个时段","Travel: {cost} slot(s)"),("map.pick","选择一处前往。","Pick a place to go."),("map.region.jade_valley","玉谷","Jade Valley"),("map.region.linjiang","临江","Linjiang"),
 ("map.region.cangwu","苍梧","Cangwu"),("map.region.marsh","云泽","The Marsh"),("map.region.yanmen","雁门","Yanmen"),("map.region.penglai","蓬莱","Penglai"),
 ("map.journal.leads","线索","Leads"),("map.journal.none","暂无","None yet"),
 ("map.journal.done","已经历","Happened"),("map.journal.missed","错过了","Missed"),("map.journal.week","第 {week} 周","Week {week}"),("map.button","地图","Map"),
 ("map.week","第 {week} 周 · 第 {slot} 时段","Week {week} · slot {slot}")]: L(k,z,e)

BG = {"valley_village": "valley_day", "river_bend": "riverside_day", "herb_terraces": "terraces_green", "old_shrine": "shrine_night", "ferry_dock": "ferry_dusk"}
WHO = {"story.speaker.elder": "elder", "world.speaker.villager": "villager", "world.speaker.wanderer": "wanderer"}
OVERRIDE = {"f_shrine_first": {"who": {"world.speaker.wanderer": "bandit"}, "hero": ("sword", "angry"), "extra": [("bandit", "far", "idle", "angry")]},
            "r_bandit_stray": {"who": {"world.speaker.wanderer": "bandit"}, "hero": ("sword", "angry"), "extra": []},
            "f_ferry_rumor": {"hero": ("think", "neutral")}, "r_shrine_dream": {"hero": ("think", "neutral")},
            "f_spring_fair": {"hero": ("laugh", "happy")}, "r_herb_find": {"hero": ("idle", "happy")}, "f_aftermath": {"hero": ("idle", "sad")},
            "r_fish_tale": {"hero": ("fish", "neutral")}, "f_herb_lesson": {"hero": ("bow", "neutral")}, "r_elder_lesson": {"hero": ("bow", "neutral")}}
area_of = {e["id"]: e["area"] for e in events}
for dlg in dialogues:
    eid = dlg["id"][3:]
    ov = OVERRIDE.get(eid, {})
    hp, hf = ov.get("hero", ("idle", "neutral"))
    cmds = [{"c": "bg", "id": BG[area_of[eid]]}, {"c": "show", "who": "hero", "slot": "left", "pose": hp, "face": hf}]
    who = []
    for n in dlg["nodes"]:
        w = ov.get("who", {}).get(n.get("speaker_key", ""), WHO.get(n.get("speaker_key", "")))
        if w and w not in who:
            who.append(w)
    for w in who:
        cmds.append({"c": "show", "who": w, "slot": "right", "pose": "idle", "face": "neutral"})
    for (w, slot, pose, face) in ov.get("extra", []):
        cmds.append({"c": "show", "who": w, "slot": slot, "pose": pose, "face": face})
    dlg["nodes"][0]["stage"] = cmds

def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
dump("world/areas.json", {"areas": areas}); dump("world/events.json", {"events": events}); dump("world/event_dialogues.json", {"dialogues": dialogues})
for lang in LOC:
    p = os.path.join(G, "localization", lang + ".json"); d = json.load(open(p)); d.update(LOC[lang]); dump("localization/" + lang + ".json", d)
print(len(areas), len(events), len(dialogues), len(LOC["zh_CN"]))
