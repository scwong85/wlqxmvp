#!/usr/bin/env python3
"""M24a: Year 2 quarter 5 (The Undertow Surfaces, weeks 61 to 75): the Faceless Gate shows itself, Xia Zhi, the barge riot,
Xie Wujiu's stage 2 and the Hui-Mask's letter. Run AFTER gen_year1_q4. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); comps = load("companions/companions.json")
looks = load("story/looks.json"); ct = load("combat/combat_techniques.json"); duos = load("combat/duo.json"); arcs = load("companions/arcs.json")

PREFIX = ("y2_", "ry5_", "arc_xia_zhi_", "arc_xie_wujiu_2")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in ["y2_barge_riot", "y2_patrol", "y2_xia_catch"]]
units["units"] = [u for u in units["units"] if u["id"] not in ["barge_blade", "gate_patrol", "xia_foe"]]
comps["companions"] = [c for c in comps["companions"] if c["id"] != "xia_zhi"]
looks["looks"] = [l for l in looks["looks"] if l["id"] != "xia_zhi"]
NEW_TECH = ["shadow_step", "backstab", "vanish", "duo_shadow_cut"]
ct["techniques"] = [t for t in ct["techniques"] if t["id"] not in NEW_TECH]
duos["duos"] = [d for d in duos["duos"] if d["companion"] != "xia_zhi"]
arcs["arcs"] = [a for a in arcs["arcs"] if a["companion"] != "xia_zhi"]
for a in arcs["arcs"]:
    if a["companion"] == "xie_wujiu":
        a["stages"] = [s for s in a["stages"] if s["id"] == "1"]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "elder": "story.speaker.elder",
       "xia": "npc.xia_zhi", "boss": "npc.guild_master", "xie": "npc.xie_wujiu", "hui": "npc.mask_hui", "puppet": "npc.guild_puppet", "mag": "npc.magistrate"}
WHO = {"elder": "elder", "wander": "wanderer", "xia": "xia_zhi", "boss": "guild_master", "xie": "xie_wujiu", "hui": "mask_hui", "puppet": "wanderer", "mag": "wanderer"}
L("npc.xia_zhi", "夏芷", "Xia Zhi"); L("npc.guild_puppet", "新帮主", "The New Guild Master"); L("npc.magistrate", "新任县令", "The New Magistrate")
BG = {"valley_village": "village_dusk", "lj_market": "city_market", "lj_teahouse": "city_market", "lj_docks": "city_docks", "lj_alleys": "city_night", "lj_escort": "city_market",
      "lj_pawn": "city_market", "cw_cave": "cangwu_night", "cw_courts": "cangwu_day"}
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



def reg(**kw): return kw
Y2 = {"week_min": 61}

# ===================================================================== STORY
fork_lines = {
    "live": [("elder", "新年好。你们走后，村口的灯我每夜都点着。", "Happy New Year. Every night since you left, I kept the lamp at the gate lit."),
             ("elder", "拿着，一点心意。路远，别饿着。", "Take this, a small gift. The road is long; do not go hungry.")],
    "adv": [("elder", "新年了。我这把老骨头，在路上过年也不算坏事。", "A new year. These old bones do not mind seeing it in on the road."),
            ("elder", "往后遇到拿不准的事，先来问我。", "When you are unsure of something, ask me first.")],
    "seal": [("narr", "新年夜，村里的灯比往年少。你把墨长老留下的旧印握在手心。", "On New Year's night there are fewer lamps in the village than before. You hold Elder Mo's old seal in your palm."),
             ("narr", "印底刻着一行小字，笔迹和你怀里的玉符，是同一个人的。", "Under the seal runs a line of small characters, in the same hand as the one on your tally.")]}
ev = {"id": "y2_new_year", "kind": "fixed", "area": "valley_village", "scene": {"dialogue": "ev_y2_new_year"}, "title_key": "event.y2_new_year.title",
      "window": {"from": 61, "to": 63}, "priority": 6, "requires": Y2}
L(ev["title_key"], "新年", "New Year")
nodes = []
effs = {"live": [FLAG("y2_new_year_done"), ATTR("spirit", 2), RES("coins", 20)], "adv": [FLAG("y2_new_year_done"), ATTR("insight", 2)],
        "seal": [FLAG("y2_new_year_done"), ATTR("spirit", 2), LEAD("seal_inscription")]}
for key, lines in fork_lines.items():
    for i, (sp, z, e) in enumerate(lines):
        k = f"event.y2_new_year.{key}.{i+1}"; L(k, z, e)
        n = {"id": f"{key}{i+1}", "text_key": k, "speaker_key": SPK[sp], "next": "" if i == len(lines) - 1 else f"{key}{i+2}"}
        if i == len(lines) - 1: n["on_enter"] = effs[key]
        if i == 0: n["stage"] = [{"c": "bg", "id": "village_dusk"}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "neutral"}] + ([{"c": "show", "who": "elder", "slot": "right", "pose": "idle", "face": "neutral"}] if key != "seal" else [])
        nodes.append(n)
events["events"].append(ev)
dlgs["dialogues"].append({"id": "ev_y2_new_year", "entry": [{"if": {"flag": "valley_kept"}, "node": "live1"}, {"if": {"flag": "elder_retired"}, "node": "adv1"}, {"node": "seal1"}], "nodes": nodes})
ev["on_miss"] = [FLAG("y2_new_year_done")]
L("world.lead.seal_inscription.name", "印底小字", "The Inscription Under the Seal"); L("world.lead.seal_inscription.desc", "墨长老的旧印底下，刻着与玉符同一人的笔迹。", "Under Elder Mo's seal is a line in the same hand as the jade tally.")

event("y2_black_banner", "fixed", "lj_market",
      [("narr", "集市口多了一面黑底灰边的旗，旗上没有字。商贩们压低了声音，原来的县令昨夜被调走了。", "A black banner with a grey edge hangs at the market entrance, no characters on it. Vendors lower their voices: the old magistrate was transferred last night."),
       ("mag", "新来的县令站在台阶上，笑得很和气：「往后，市集上的事，都有人替大家操心。」", "The new magistrate stands on the steps, smiling pleasantly. \"From now on, someone will worry about the market on everyone's behalf.\""),
       ("hero", "他说话的方式，和那晚戴面具的人一样平静。", "He speaks in the same calm as the masked rider that night.")],
      title=("黑底旗", "The Black Banner"), window=(62, 68), priority=5, requires=Y2,
      choices=[("probe", "混进人群，看他身边的人", "Slip into the crowd and watch who stands beside him", [LEAD("gate_banner"), ATTR("insight", 2), FLAG("y2_banner_probed")]),
               ("walk", "不动声色地离开", "Leave without a word", [ATTR("agility", 1), FLAG("y2_banner_ignored")])],
      on_miss=[FLAG("y2_banner_ignored")])
event("y2_xia_zhi", "fixed", "lj_alleys",
      [("narr", "夜巷里一道灰紫色的影子从屋檐跃下，指尖已经勾住了你腰间的半块玉符。", "In the night alley a grey-purple shadow drops from the eaves, fingers already hooked on the half tally at your hip."),
       ("xia", "「别叫！」少女压低声音，手腕一翻，匕首抵在你的绳结上，「这东西，借我一晚。」", "\"Don't shout!\" the girl whispers, flipping her wrist so a dagger rests against your cord. \"Lend me that for one night.\""),
       ("hero", "我按住她的手腕：「它不是借的。」", "I clamp her wrist. \"It is not for lending.\"")],
      title=("夜巷拦路", "The Shadow in the Alley"), window=(64, 72), priority=5, requires={"week_min": 64},
      choices=[("grab", "出手拿下她", "Grab her", [BOND("xia_zhi", 2), ATTR("agility", 1), BATTLE("y2_xia_catch"), FLAG("xia_caught")]),
               ("bargain", "松开手，问她为什么要它", "Let go and ask why she wants it", [BOND("xia_zhi", 3), FLAG("xia_bargain"), LEAD("xia_orders")]),
               ("follow", "放她走，悄悄跟着", "Let her go and follow quietly", [BOND("xia_zhi", 2), ATTR("insight", 1), LEAD("xia_orders"), FLAG("xia_followed")])],
      on_miss=[LEAD("xia_orders")])
event("y2_house_replaced", "fixed", "lj_teahouse",
      [("narr", "茶楼里的议论比茶还烫：漕帮帮主昨夜称病退位，接任的是一个谁也没听说过的人。", "The talk in the teahouse is hotter than the tea: the Barge Guild master stepped down last night, ill, and his successor is someone nobody has heard of."),
       ("puppet", "新帮主在二楼拱手：「从今日起，漕帮的船，只运有凭证的货。」", "The new master bows on the upper floor. \"From today the guild's barges carry only goods with a pass.\""),
       ("hero", "凭证，是谁发的？没人答得上来。", "A pass, from whom? Nobody can say.")],
      [LEAD("guild_replaced"), SCHED("y2_barge_riot", 2, 6)], title=("漕帮换主", "A New Master for the Guild"), window=(66, 72), priority=5, requires=Y2,
      on_miss=[LEAD("guild_replaced"), SCHED("y2_barge_riot", 2, 6)])
event("y2_barge_riot", "fixed", "lj_docks",
      [("narr", "码头上没有凭证的货被扣了，脚夫们围住了新帮主的人。雇来的打手亮出了棍棒。", "Goods without a pass are seized on the docks; the porters surround the new master's men and hired thugs draw their clubs."),
       ("boss", "旧帮主的老部下在人群里朝你点头，意思很明白：这里需要你。", "The old master's loyalists nod to you from the crowd; the meaning is plain: you are needed here.")],
      title=("码头骚乱", "Riot on the Docks"), scheduled_only=True, priority=6,
      choices=[("fight", "出手制止", "Step in", [BATTLE("y2_barge_riot"), LEAD("riot_witness")])],
      on_miss=[FLAG("riot_missed")])
event("y2_hui_letter", "fixed", "cw_cave",
      [("narr", "断崖洞的石壁前，压着一封没有署名的信。封口的蜡，是灰色的。", "Before the cave wall lies an unsigned letter, sealed with grey wax."),
       ("hui", "「北边的雁门，有人在等一块玉符。不必信我，只管去看。」", "\"In Yanmen to the north, someone waits for a jade tally. You need not trust me. Only go and see.\""),
       ("hero", "字迹有些抖，像写信的人很久没有握过笔。", "The hand shakes a little, as if the writer had not held a brush in a long time.")],
      [LEAD("yanmen_road"), FLAG("hui_letter"), ATTR("insight", 1)], title=("灰色蜡封", "Grey Wax"), window=(70, 75), priority=5, requires={"week_min": 70},
      on_miss=[LEAD("yanmen_road"), FLAG("hui_letter")])

# Xie Wujiu stage 2: proof of the frame
event("arc_xie_wujiu_2", "fixed", "cw_courts",
      [("xie", "「我查到了。」谢无咎把一片烧焦的纸角放在石桌上，「那天夜里，有人在藏经阁里烧过东西。」", "\"I found something.\" Xie Wujiu sets a charred scrap on the stone table. \"That night someone burned papers in the library.\""),
       ("xie", "「灰里有一枚灰色的蜡。」他看着你，「和你说的那个戴面具的人，是不是一个路数？」", "\"There is grey wax in the ash.\" He looks at you. \"Is that the same sort as the masked one you spoke of?\""),
       ("hero", "我点头。这件事，比一个人的冤屈要大。", "I nod. This is bigger than one man's wrong.")],
      [{"type": "arc_stage", "id": "xie_wujiu", "amount": 2}, LEAD("grey_wax"), BOND("xie_wujiu", 2), ATTR("insight", 1)], title=("灰烬里的蜡", "Wax in the Ashes"),
      window=(64, 100), priority=6, requires={"bond_min": {"xie_wujiu": 8}, "arc_min": {"xie_wujiu": 1}},
      on_miss=[{"type": "arc_outcome", "id": "xie_wujiu", "value": "lost"}, {"type": "arc_stage", "id": "xie_wujiu", "amount": 4}])
for a in arcs["arcs"]:
    if a["companion"] == "xie_wujiu":
        a["stages"].append({"id": "2", "event": "arc_xie_wujiu_2"})

RANDOM = [
 ("ry5_market_patrol", "lj_market", [("narr", "市集上多了几个灰衣人，逢人就查凭证，商贩们敢怒不敢言。", "Grey-clad men check passes on the market street while traders swallow their anger.")], [ATTR("insight", 1)], ("灰衣查证", "Passes Checked"), 3, 5),
 ("ry5_market_rumor", "lj_market", [("wander", "卖糖人的老头说：「新县令上任那天，旧衙门的卷宗一夜之间全搬空了。」", "The sugar-figure seller says: \"The day the new magistrate arrived, the old records vanished overnight.\"")], [ATTR("insight", 1)], ("卷宗失踪", "The Missing Records"), 3, 8),
 ("ry5_docks_pass", "lj_docks", [("narr", "脚夫们排着长队等凭证，你替一位老人搬了半日货。", "Porters queue for passes; you spend half a day carrying goods for an old man.")], [RES("coins", 6), ATTR("body", 1)], ("排队的脚夫", "Porters in Line"), 3, 5),
 ("ry5_docks_barge", "lj_docks", [("narr", "漕帮的船空着靠岸，船夫们蹲在甲板上抽烟。", "Guild barges sit empty at the quay, boatmen smoking on deck.")], [ATTR("spirit", 1)], ("空船", "Empty Barges"), 3, 6),
 ("ry5_alley_patrol", "lj_alleys", [("narr", "巷口亮起灯笼，一队灰衣人拦住了去路：「例行盘查。」", "A lantern flares at the alley mouth and grey-clad men bar the way. \"Routine inspection.\"")], [], ("巷口盘查", "Alley Inspection"), 3, 6),
 ("ry5_alley_cat", "lj_alleys", [("narr", "屋檐上一只花猫盯着你，尾巴一甩，沿着瓦脊跑远了。", "A tabby on the eaves stares at you, flicks its tail and bolts along the roof ridge.")], [ATTR("agility", 1)], ("屋檐上的猫", "The Cat on the Roof"), 3, 5),
 ("ry5_teahouse_talk", "lj_teahouse", [("narr", "邻桌的客人谈起北边的边关，说雁门最近不太平。", "Guests at the next table talk about the northern border: Yanmen has been uneasy lately.")], [ATTR("insight", 1)], ("北边的消息", "News from the North"), 3, 8),
 ("ry5_pawn_visit", "lj_pawn", [("narr", "钱掌柜压低声音：「最近来当东西的，十个里有七个是灰衣人那边的。」", "Shopkeeper Qian lowers his voice: \"Of ten people pawning things lately, seven are on the grey men's side.\"")], [ATTR("insight", 1)], ("钱掌柜的耳语", "Qian's Whisper"), 3, 8),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    if id == "ry5_alley_patrol":
        event(id, "random", ar, lines, title=title, weight=wt, cooldown=cd, requires=Y2,
              choices=[("fight", "出手", "Fight them", [BATTLE("y2_patrol"), ATTR("power", 1)]), ("slip", "翻墙避开", "Slip over a wall", [ATTR("agility", 1)])])
    else:
        event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y2)

# ===================================================================== BATTLES
units["units"].append({"id": "barge_blade", "stats": {"hp": 46, "body": 8, "power": 10, "agility": 7, "spirit": 6}, "techniques": ["club_smash"]})
units["units"].append({"id": "gate_patrol", "stats": {"hp": 42, "body": 7, "power": 9, "agility": 8, "spirit": 7}, "techniques": ["swift_dash"]})
units["units"].append({"id": "xia_foe", "stats": {"hp": 60, "body": 7, "power": 11, "agility": 14, "spirit": 7}, "techniques": ["ambush_strike"]})
L("combat.unit.barge_blade", "漕帮打手", "Hired Barge Thug"); L("combat.unit.gate_patrol", "灰衣巡卫", "Grey Patrol"); L("combat.unit.xia_foe", "灰紫影子", "The Grey-Purple Shadow")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y2_barge_riot", "码头骚乱", "Riot on the Docks", "击退四名雇来的打手。", "Drive off the four hired thugs.", ["barge_blade", "barge_blade", "barge_blade", "barge_blade"],
         [RES("coins", 20)], ["riot_won"], ["riot_lost"])
scenario("y2_patrol", "巷口盘查", "Alley Inspection", "击退三名灰衣巡卫。", "Beat back the three grey patrolmen.", ["gate_patrol", "gate_patrol", "gate_patrol"],
         [RES("coins", 12)], ["patrol_won"], ["patrol_lost"])
scenario("y2_xia_catch", "夜巷追影", "Chasing the Shadow", "制服偷玉符的少女。", "Subdue the girl who tried to take the tally.", ["xia_foe"],
         [RES("coins", 5)], ["xia_subdued"], ["xia_escaped"], 8)

# ===================================================================== XIA ZHI
def tech(id, fields, zn, en_, dz, de):
    t = {"id": id, "name_key": "ability." + id}; t.update(fields); ct["techniques"].append(t)
    L("ability." + id, zn, en_); L("ability." + id + ".desc", dz, de)
tech("shadow_step", dict(kind="attack", range=3, damage=5, resolve=2, cost=1), "影步", "Shadow Step", "借着夜色掠过去的一击，射程3。", "A strike slipped in from the dark, range 3.")
tech("backstab", dict(kind="attack", range=1, damage=8, resolve=4, bonus_vs_broken=6, cost=2), "背刺", "Backstab", "对已破势的敌人伤害更高。", "Extra damage against a broken enemy.")
tech("vanish", dict(kind="support", range=0, mp_bonus=4, cost=0, free=True, once=True, bond=True), "隐身", "Vanish", "羁绊技（每场一次，不耗行动）：本回合多走4格。", "Bond ability (once per battle, no action): move 4 extra cells this turn.")
ct["techniques"].append({"id": "duo_shadow_cut", "name_key": "technique.duo_shadow_cut", "duo": "xia_zhi", "kind": "attack", "range": 1, "damage": 10, "resolve": 5, "push": 1, "cost": 3})
L("technique.duo_shadow_cut", "双影斩", "Twin Shadow Cut")
duos["duos"].append({"id": "duo_shadow_cut", "companion": "xia_zhi", "tech": "duo_shadow_cut", "bond_min": 12})
comps["companions"].append({"id": "xia_zhi", "name_key": "npc.xia_zhi", "bio_key": "companion.xia_zhi.bio", "portrait": "portrait_xia_zhi", "role": "striker",
    "stats": {"body": 5, "power": 7, "agility": 10, "insight": 6, "spirit": 4}, "preferred_activities": ["social_visit", "hunting", "training"],
    "recruit": {"score_min": 6, "attr_min": {"agility": 7}, "flags_block": [], "week_min": 66}, "depart": {"score_below": 0, "flags": ["xia_zhi_betrayed"]},
    "battle_abilities": ["shadow_step", "backstab"], "relationship_ability": "vanish", "meet_week": 64})
L("companion.xia_zhi.bio", "在无相门长大的少女，身手极快，嘴硬心软。", "A girl raised inside the Faceless Gate: fast, sharp-tongued and soft underneath.")
looks["looks"].append({"id": "xia_zhi", "gender": "f", "hair": 1, "hair_hex": "2a2433", "outfit_hex": "6a5a7a", "skin_hex": "ecd0b4", "weapon": "blade"})
arcs["arcs"].append({"companion": "xia_zhi", "planned": 4, "stages": [{"id": "1", "event": "arc_xia_zhi_1"}], "outcomes": ["redeemed", "alternate", "lost"], "bonds": ["friend", "sworn", "romance", "rival"]})
event("arc_xia_zhi_1", "fixed", "lj_alleys",
      [("xia", "「你为什么不揍我？」夏芷蹲在屋脊上，嚼着一块糖，「他们说，被抓住的人，不会有第二次机会。」", "\"Why didn't you hit me?\" Xia Zhi squats on the roof ridge chewing a sweet. \"They say whoever gets caught never gets a second chance.\""),
       ("xia", "「他们」，是谁？她没有说。只说：「那块玉符，有人出了很高的价。我不想拿，可我不能说不想。」", "\"They\"? She does not say who. Only: \"Someone pays a lot for that tally. I do not want to take it, but I cannot say I don't want to.\""),
       ("hero", "我伸出手：「那就先别拿。下来，吃点热的。」", "I hold out a hand. \"Then don't take it yet. Come down and eat something hot.\"")],
      [{"type": "arc_stage", "id": "xia_zhi", "amount": 1}, LEAD("gate_orders"), BOND("xia_zhi", 2)], title=("屋脊上的糖", "Sweets on the Roof Ridge"),
      window=(66, 110), priority=6, requires={"bond_min": {"xia_zhi": 4}},
      on_miss=[{"type": "arc_outcome", "id": "xia_zhi", "value": "lost"}, {"type": "arc_stage", "id": "xia_zhi", "amount": 4}])
nodes_loc = {}

LEADS = {"gate_banner": ("黑底旗", "The Black Banner", "市集口的黑旗没有字，新县令的话和戴面具的人一样平静。", "The black banner has no writing, and the new magistrate speaks as calmly as the masked man."),
         "xia_orders": ("夏芷的差事", "Xia Zhi's Orders", "有人出高价要你的玉符，派了一个少女来偷。", "Someone paid well for your tally and sent a girl to steal it."),
         "guild_replaced": ("漕帮换主", "The Guild's New Master", "漕帮帮主称病退位，接任的人无人知晓来历。", "The Barge Guild master stepped down ill; nobody knows where his successor came from."),
         "riot_witness": ("码头上的目击", "Seen on the Docks", "码头骚乱中，你看见新帮主身边有人戴着灰色的面纱。", "During the dock riot you saw a grey veil among the new master's men."),
         "yanmen_road": ("雁门之路", "The Road to Yanmen", "灰面人留信：北边的雁门有人在等一块玉符。", "The Hui-Mask's letter says someone in Yanmen waits for a jade tally."),
         "grey_wax": ("灰蜡", "Grey Wax", "藏经阁的灰烬里有灰色的蜡，与灰面人的封蜡一样。", "Grey wax in the library ashes matches the Hui-Mask's seal."),
         "gate_orders": ("无相门的差使", "Orders of the Gate", "夏芷是被无相门派来的，却不想拿走玉符。", "The Faceless Gate sent Xia Zhi, though she does not want to take the tally.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("combat/scenarios.json", scen); dump("combat/units.json", units); dump("companions/companions.json", comps)
dump("story/looks.json", looks); dump("combat/combat_techniques.json", ct); dump("combat/duo.json", duos); dump("companions/arcs.json", arcs)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events", len(comps["companions"]), "companions")
