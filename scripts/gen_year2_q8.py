#!/usr/bin/env python3
"""M24d: Year 2 quarter 8 (The Rift, weeks 106 to 120): the council, stage-3 tests for Xie, Su Dai, Li Shan, Xia Zhi and Xiao,
the betrayal and the rescue, the Winter Solstice, and the close of the year. Run AFTER gen_year2_q7. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); arcs = load("companions/arcs.json")

PREFIX = ("y5_", "ry8_", "arc_xie_wujiu_3", "arc_su_dai_3", "arc_li_shan_3", "arc_xia_zhi_3", "arc_xiao_hanchuan_3")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["y2_public_proof", "y2_break_ranks", "y2_rescue"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
for a in arcs["arcs"]:
    if a["companion"] in ("xie_wujiu", "su_dai", "li_shan", "xia_zhi", "xiao_hanchuan"):
        a["stages"] = [s for s in a["stages"] if s["id"] in ("1", "2")]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "elder": "story.speaker.elder", "yun": "npc.isle_yun",
       "xia": "npc.xia_zhi", "xiao": "npc.xiao_hanchuan", "xie": "npc.xie_wujiu", "su": "npc.su_dai", "li": "npc.li_shan", "boss": "npc.guild_master", "gu": "npc.master_gu",
       "hui": "npc.mask_hui", "qian": "npc.qian_man"}
WHO = {"wander": "wanderer", "elder": "elder", "yun": "isle_yun", "xia": "xia_zhi", "xiao": "xiao_hanchuan", "xie": "xie_wujiu", "su": "su_dai", "li": "li_shan",
       "boss": "guild_master", "gu": "master_gu", "hui": "mask_hui", "qian": "qian_man"}
BG = {"lj_teahouse": "city_market", "lj_market": "city_market", "lj_docks": "city_docks", "lj_alleys": "city_night", "cw_courts": "cangwu_day", "ym_fort": "yanmen_fort",
      "valley_village": "village_dusk", "pd_harbour": "penglai_sea", "ym_road": "yanmen_snow", "cw_library": "cangwu_day"}
ATTR = lambda i, n=1: {"type": "attr", "id": i, "amount": n}
FLAG = lambda i: {"type": "flag", "id": i}
LEAD = lambda i: {"type": "lead", "id": i}
SCHED = lambda i, a, b: {"type": "schedule", "id": i, "min": a, "max": b}
BOND = lambda c, n: {"type": "bond", "id": c, "amount": n}
STAMINA = lambda n: {"type": "stamina", "id": "stamina", "amount": n}
BATTLE = lambda i: {"type": "battle", "id": i}
RES = lambda i, n: {"type": "resource", "id": i, "amount": n}
ARC_STAGE = lambda c, n: {"type": "arc_stage", "id": c, "amount": n}
ARC_OUT = lambda c, v: {"type": "arc_outcome", "id": c, "value": v}


def area(id, zn, en_, dz, de, wanders, **kw):
    a = {"id": id, "region": "penglai", "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": 2, "wander": [],
         "open_default": True, "requires": {"lead": ["penglai_route"], "week_min": 91}}
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



Y5 = {"week_min": 106}

# ===================================================================== STORY
event("y2_council", "fixed", "lj_teahouse",
      [("narr", "茶楼二楼摆开了长桌，各家的使者都到了。有人拍案，有人沉默，案上的玉契残片被反复推来推去。", "Long tables fill the teahouse's upper floor and each house has sent an envoy. Some pound the table, some are silent, and the Jade Accord fragments are pushed back and forth."),
       ("qian", "钱满凑到你耳边：「这是自玉契以来头一回，九家谁也不信谁。你站哪边，往后就得认哪边的账。」", "Qian Man leans to your ear: \"For the first time since the Accord, no house trusts another. Whichever side you stand on, you will answer to that side's ledger.\"")],
      title=("九家议事", "The Council of Houses"), window=(106, 110), priority=6, requires=Y5,
      choices=[("orthodox", "与苍梧等正统门派并肩", "Stand with Cangwu and the orthodox houses", [FLAG("council_orthodox"), ATTR("spirit", 2), LEAD("houses_split")]),
               ("trade", "与漕帮、镖局等行商站一边", "Stand with the guilds and couriers", [FLAG("council_trade"), ATTR("insight", 2), LEAD("houses_split")]),
               ("neutral", "谁的账也不认", "Answer to nobody's ledger", [FLAG("council_neutral"), ATTR("agility", 2), LEAD("houses_split")])],
      on_miss=[FLAG("council_neutral"), LEAD("houses_split")])

def stage3(cid, ev_id, area, win, bond_min, zh_title, en_title, lines, choices):
    """A stage-3 test: one scene whose choices decide the outcome. choices: (id, zh, en, outcome, bond, extra_effects)."""
    ch = []
    for chid, cz, ce, outcome, bd, extra in choices:
        eff = [ARC_STAGE(cid, 3), ARC_OUT(cid, outcome), BOND(cid, bd)] + extra
        ch.append((chid, cz, ce, eff))
    event(ev_id, "fixed", area, lines, title=(zh_title, en_title), window=win, priority=6, requires={"bond_min": {cid: bond_min}, "arc_min": {cid: 2}}, choices=ch,
          on_miss=[ARC_OUT(cid, "lost"), ARC_STAGE(cid, 4)])
    for a in arcs["arcs"]:
        if a["companion"] == cid:
            a["stages"].append({"id": "3", "event": ev_id})

stage3("xie_wujiu", "arc_xie_wujiu_3", "cw_courts", (106, 114), 12, "是非当面", "Face to Face",
       [("xie", "「证据够了。」谢无咎把一叠纸放在石桌上，「我可以当着掌门和全山的面讲清楚——让顾行舟难堪。也可以悄悄交给他，让他自己改。」", "\"The proof is enough.\" Xie Wujiu lays a stack of pages on the stone table. \"I can lay it out before the master and the whole mountain, shaming Gu Xingzhou. Or I can hand it to him quietly and let him mend it himself.\""),
        ("xie", "「你说，我该怎么选？」", "\"Tell me, how should I choose?\"")],
       [("public", "当众讲清，我陪你", "Do it in public; I will stand by you", "redeemed", 10, [BATTLE("y2_public_proof")]),
        ("quiet", "悄悄交给顾掌门", "Hand it to the master quietly", "alternate", 6, []),
        ("drop", "算了，离开苍梧吧", "Let it go and leave Cangwu", "lost", -6, [])])
stage3("su_dai", "arc_su_dai_3", "lj_market", (108, 116), 12, "歌与图", "The Song and the Map",
       [("su", "「图我拼出来了。」苏黛抱着琵琶，声音很轻，「它指向第三颗星。有人愿意出一座院子，买这首曲子的全部。」", "\"I have pieced the map together,\" Su Dai says softly, holding her pipa. \"It points to the third star. Someone has offered a whole courtyard for every verse of this song.\""),
        ("su", "「我想把它藏起来。可我又想让它被人听到。你说呢？」", "\"I want to hide it. Yet I want it to be heard. What do you say?\"")],
       [("share", "教给整条街唱，谁也别想独占", "Teach it to the whole street so nobody can own it", "redeemed", 10, [FLAG("song_shared")]),
        ("hide", "藏起来，只你一人记得", "Hide it, known to you alone", "alternate", 6, []),
        ("sell", "卖给出价的人", "Sell it to the bidder", "lost", -6, [FLAG("song_sold")])])
stage3("li_shan", "arc_li_shan_3", "lj_docks", (108, 118), 12, "炉火两条路", "Two Ways to Light the Forge",
       [("li", "「有人送来一箱金子，」厉山站在新搭的炉架前，「说是无名氏，只要我替他们打一批刀。」", "\"A chest of gold arrived,\" Li Shan says before the new furnace frame. \"No name, only that I forge a batch of blades for them.\""),
        ("li", "「没有金子，炉子也能生起来。只是慢。」", "\"Without the gold the furnace can still be lit. Only slower.\"")],
       [("together", "我们一起一块砖一块砖地垒", "We build it brick by brick together", "redeemed", 10, [RES("ore", -2), FLAG("forge_rebuilt")]),
        ("small", "先开个小摊，慢慢来", "Start a small stall and go slowly", "alternate", 4, []),
        ("gold", "收下金子", "Take the gold", "lost", -6, [FLAG("forge_gold")])])
stage3("xia_zhi", "arc_xia_zhi_3", "lj_alleys", (110, 118), 12, "拿，还是不拿", "To Take or Not to Take",
       [("xia", "「今晚子时，我得把那块玉符带去。」夏芷站在你面前，匕首垂在身侧，「不然，他们会找我弟弟。」", "\"At midnight tonight I must bring the tally,\" Xia Zhi says, dagger hanging at her side. \"Or they will go after my little brother.\""),
        ("xia", "「我可以假装失手。我可以真的拿。也可以跟你走。」", "\"I could fail on purpose. I could really take it. Or I could go with you.\"")],
       [("defect", "跟我走，我们把他也接出来", "Come with me; we will bring him out too", "redeemed", 10, [FLAG("xia_defected")]),
        ("fake", "假装失手，拖几天再想办法", "Fake a failure and buy a few days", "alternate", 4, []),
        ("steal", "别勉强自己，拿走吧", "Do not force yourself; take it", "lost", -6, [FLAG("tally_stolen")])])
stage3("xiao_hanchuan", "arc_xiao_hanchuan_3", "ym_fort", (106, 116), 12, "令与人", "The Order and the People",
       [("xiao", "「命令到了。」萧寒川的声音很平，「守军继续按兵不动，违令者军法处置。」", "\"The order has come,\" Xiao Hanchuan says flatly. \"The garrison holds position. Violators face military law.\""),
        ("xiao", "「关外的村子，今晚又会烧起来。我要带人出去。你……跟我走吗？」", "\"The villages beyond the pass will burn again tonight. I mean to take men out. Will you come?\"")],
       [("break", "我跟你走，破阵而出", "I go with you; we break out", "redeemed", 10, [BATTLE("y2_break_ranks")]),
        ("petition", "联名上书，另想办法", "Draft a joint petition and find another way", "alternate", 6, []),
        ("obey", "劝他遵令，保全自己", "Urge him to obey and protect himself", "lost", -6, [])])

# the betrayal and the rescue
BET = {"xia": ("xia_caught", "xia_zhi"), "xie": ("xie_abandoned", "xie_wujiu")}
ev = {"id": "y2_betrayal", "kind": "fixed", "area": "lj_alleys", "scene": {"dialogue": "ev_y2_betrayal"}, "title_key": "event.y2_betrayal.title",
      "window": {"from": 112, "to": 116}, "priority": 7, "requires": Y5, "on_miss": [FLAG("betrayal_unseen")]}
L(ev["title_key"], "背叛", "The Betrayal")
events["events"].append(ev)
branches = {
 "xia": [("narr", "夜巷里留着一张折好的纸，字迹歪歪扭扭：「对不起，他们抓了人。——芷」", "A folded note is left in the alley in crooked writing: \"I am sorry, they took someone. - Zhi\""),
         ("hero", "我握着纸条。她没有走远，只是被人拽进了暗处。", "I clutch the note. She has not gone far; she was dragged into the dark.")],
 "xie": [("narr", "藏经阁外有人传话：谢无咎收了灰蜡封的信，已经下山。", "A messenger outside the library says Xie Wujiu received a letter sealed with grey wax and has gone down the mountain."),
         ("hero", "他被逼到了绝处。不能让他一个人走下去。", "He has been pushed to the end of his rope. I cannot let him go down alone.")],
 "gate": [("narr", "议事之后，茶楼里的账本少了一页。你认出那是自己人才能碰的那一页。", "After the council a page is missing from the teahouse ledger, one only an insider could touch."),
          ("hero", "有人在我们中间递消息。我得先把他找出来。", "Someone is passing word among us. I must find him first.")]}
nodes = []
who_of = {"xia": "xia_zhi", "xie": "xie_wujiu", "gate": None}
for key, lines in branches.items():
    for i, (sp, z, e) in enumerate(lines):
        k = f"event.y2_betrayal.{key}.{i+1}"; L(k, z, e)
        n = {"id": f"{key}{i+1}", "text_key": k, "speaker_key": SPK[sp]}
        if i == len(lines) - 1:
            cid = who_of[key]
            n["choices"] = []
            for chid, cz, ce, eff in [("chase", "追上去", "Chase", [SCHED("y2_rescue", 1, 3), FLAG("betrayal_chased")] + ([BOND(cid, 2)] if cid else [ATTR("insight", 1)])),
                                      ("release", "让他自己选", "Let them choose", [FLAG("betrayal_released")] + ([FLAG(cid + "_betrayed"), ARC_OUT(cid, "lost"), ARC_STAGE(cid, 4)] if cid else [FLAG("council_leaked")]))]:
                ck = f"event.y2_betrayal.{key}.c.{chid}"; L(ck, cz, ce)
                n["choices"].append({"id": chid, "label_key": ck, "next": "", "effects": eff})
        else:
            n["next"] = f"{key}{i+2}"
        if i == 0:
            n["stage"] = [{"c": "bg", "id": "city_night"}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "sad"}]
        nodes.append(n)
dlgs["dialogues"].append({"id": "ev_y2_betrayal", "entry": [{"if": {"flag": "xia_caught"}, "node": "xia1"}, {"if": {"flag": "xie_abandoned"}, "node": "xie1"}, {"node": "gate1"}], "nodes": nodes})
event("y2_rescue", "fixed", "lj_alleys",
      [("narr", "追到城西的废仓，门里透出一点灯火，十几个灰衣人守着一个被缚的人影。", "You track them to a ruined warehouse in the west of the city. A lamp glows within and a dozen grey-clad men guard a bound figure."),
       ("hero", "这一回，我不会再让人从身边被带走。", "This time I will not let anyone be taken from my side.")],
      title=("废仓救人", "Rescue at the Warehouse"), scheduled_only=True, priority=7,
      choices=[("fight", "冲进去", "Go in", [BATTLE("y2_rescue"), FLAG("y2_rescue_done")])],
      on_miss=[FLAG("rescue_lost")])

event("y2_solstice", "fixed", "valley_village",
      [("narr", "第二个冬至，村里的灯比去年多了几盏。你离家越远，越觉得这些灯亮得珍贵。", "A second Winter Solstice: there are a few more lamps in the village than last year. The farther you go, the more precious they seem."),
       ("narr", "这一晚，你把热汤分给了谁？", "Whom do you share the hot soup with tonight?")],
      title=("第二个冬至", "The Second Solstice"), window=(113, 114), priority=6, requires={"week_min": 113},
      choices=[("shen", "沈青禾", "Shen Qinghe", [BOND("shen_qinghe", 2), STAMINA(8)]), ("lu", "陆沉舟", "Lu Chenzhou", [BOND("lu_chenzhou", 2), STAMINA(8)]),
               ("bai", "白砚", "Bai Yan", [BOND("bai_yan", 2), STAMINA(8)]), ("friends", "大家围坐一桌", "Everyone around one table", [ATTR("spirit", 2), STAMINA(8), FLAG("solstice2_together")])])
event("y2_winter_end", "fixed", "valley_village",
      [("narr", "第二年的雪落满了玉谷。两颗星已经找到，三颗玉片的位置在地图上连成了一条线。", "The second year's snow blankets the valley. Two stars are found, and the places of three fragments now line up on the map."),
       ("hui", "雪地里压着一张灰蜡封的纸：「沉星泽的门，还有第二道。钥匙，在最后聚会的地方。」", "A paper with grey wax lies pressed in the snow: \"The marsh gate has a second door. The key is where the last gathering is held.\""),
       ("hero", "论剑台。三年一度的聚会，就在明年。", "The Sword-Debate Platform. The gathering held once in three years, next year.")],
      [FLAG("year2_done"), LEAD("vault_second_gate"), LEAD("platform_year3"), ATTR("insight", 2), ATTR("spirit", 2)], title=("第二年冬", "Winter of the Second Year"), window=(119, 120), priority=8,
      requires={"week_min": 119}, on_miss=[FLAG("year2_done"), LEAD("vault_second_gate"), LEAD("platform_year3")])

RANDOM = [
 ("ry8_village_snow", "valley_village", [("narr", "雪落在竹叶上，簌簌作响。村口的孩子们追着你喊少侠。", "Snow whispers on bamboo leaves, and children at the gate chase after you calling you hero.")], [ATTR("spirit", 1)], ("村中落雪", "Snow in the Village"), 3, 6),
 ("ry8_teahouse_split", "lj_teahouse", [("narr", "茶客们分成了两拨，各自压低声音，谁也不看对方。", "Tea drinkers split into two camps, each murmuring, neither glancing at the other.")], [ATTR("insight", 1)], ("两拨茶客", "Two Camps of Tea Drinkers"), 3, 6),
 ("ry8_courts_empty", "cw_courts", [("narr", "演武场空了大半，苍梧的弟子们被召去守山门。", "The courts are half empty; Cangwu's disciples are called to guard the gate.")], [ATTR("power", 1)], ("空荡的演武场", "Empty Courts"), 3, 8),
 ("ry8_fort_watch", "ym_fort", [("narr", "城头的哨兵换了三班，口令一夜之间改了两次。", "Sentries on the wall change three times and the password is altered twice in one night.")], [ATTR("agility", 1)], ("夜里的口令", "The Password at Night"), 3, 8),
 ("ry8_harbour_lamp", "pd_harbour", [("narr", "灯塔的灯光扫过海面，你在码头坐了很久。", "The lighthouse beam sweeps the water and you sit on the quay a long while.")], [ATTR("spirit", 1), STAMINA(6)], ("扫海的灯", "The Sweeping Lamp"), 3, 6),
 ("ry8_market_gossip", "lj_market", [("wander", "摊贩们都在议论玉契的事，说今年论剑台，怕是开不成了。", "Vendors all talk of the Accord, saying the platform gathering may not be held this year.")], [ATTR("insight", 1)], ("玉契的传闻", "Rumours of the Accord"), 3, 8),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y5)

# ===================================================================== BATTLES
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10, terrain=None):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": terrain or [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y2_public_proof", "当众对质", "Confrontation in the Courts", "击败阻拦的苍梧师兄。", "Defeat the Cangwu senior who bars the way.", ["cangwu_senior", "cangwu_disciple"],
         [RES("coins", 20)], ["public_proof_won"], ["public_proof_lost"], 10)
scenario("y2_break_ranks", "破阵出关", "Breaking Ranks", "击败拦路的守军刀手。", "Defeat the garrison sabremen who block the gate.", ["garrison_sabre", "garrison_sabre", "yanmen_raider"],
         [RES("coins", 25)], ["ranks_broken"], ["ranks_held"], 10)
scenario("y2_rescue", "废仓救人", "Rescue at the Warehouse", "击退守仓的灰衣人，救出人质。", "Beat off the grey guards and free the captive.",
         ["gate_captain", "gate_blade", "gate_blade", "gate_scout", "gate_scout", "sea_raider"], [RES("coins", 40)], ["rescued"], ["rescue_failed"], 12,
         [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"], [0, 2, "hazard"], [5, 2, "hazard"]])

LEADS = {"houses_split": ("九家离心", "The Houses Split", "九家议事不欢而散，玉契的约束已经松动。", "The council of houses broke up in discord; the Accord's hold has loosened."),
         "vault_second_gate": ("第二道门", "The Second Gate", "沉星泽的地宫还有第二道门，钥匙在论剑台。", "The marsh vault has a second gate and its key lies at the Sword-Debate Platform."),
         "platform_year3": ("论剑台之约", "The Platform Gathering", "三年一度的论剑台聚会就在明年。", "The triennial gathering at the Sword-Debate Platform comes next year.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("combat/scenarios.json", scen); dump("companions/arcs.json", arcs)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events")
