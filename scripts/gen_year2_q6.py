#!/usr/bin/env python3
"""M24b: Year 2 quarter 6 (Border Fire, weeks 76 to 90): Yanmen, Xiao Hanchuan, the battle for the pass, and arc stage 2 for Su Dai and Li Shan.
Run AFTER gen_year2_q5. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); comps = load("companions/companions.json")
looks = load("story/looks.json"); ct = load("combat/combat_techniques.json"); duos = load("combat/duo.json"); arcs = load("companions/arcs.json")

OWN_AREAS = ["ym_fort", "ym_road", "ym_pass", "ym_field"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
PREFIX = ("y3_", "ry6_", "arc_xiao_hanchuan_", "arc_su_dai_2", "arc_li_shan_2")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["y2_xiao_spar", "y2_snow_pass", "y2_pass_battle"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
units["units"] = [u for u in units["units"] if u["id"] not in ["yanmen_raider", "garrison_sabre"]]
comps["companions"] = [c for c in comps["companions"] if c["id"] != "xiao_hanchuan"]
looks["looks"] = [l for l in looks["looks"] if l["id"] != "xiao_hanchuan"]
NEW_TECH = ["rally_cry", "sabre_counter", "garrison_order", "duo_command_charge"]
ct["techniques"] = [t for t in ct["techniques"] if t["id"] not in NEW_TECH]
duos["duos"] = [d for d in duos["duos"] if d["companion"] != "xiao_hanchuan"]
arcs["arcs"] = [a for a in arcs["arcs"] if a["companion"] != "xiao_hanchuan"]
for a in arcs["arcs"]:
    if a["companion"] in ("su_dai", "li_shan"):
        a["stages"] = [s for s in a["stages"] if s["id"] == "1"]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "xiao": "npc.xiao_hanchuan", "gar": "npc.garrison_soldier",
       "su": "npc.su_dai", "li": "npc.li_shan", "hui": "npc.mask_hui"}
WHO = {"wander": "wanderer", "xiao": "xiao_hanchuan", "gar": "wanderer", "su": "su_dai", "li": "li_shan", "hui": "mask_hui"}
L("npc.xiao_hanchuan", "萧寒川", "Xiao Hanchuan"); L("npc.garrison_soldier", "雁门守军", "Garrison Soldier")
BG = {"ym_fort": "yanmen_fort", "ym_road": "yanmen_snow", "ym_pass": "yanmen_snow", "ym_field": "yanmen_fort", "lj_docks": "city_docks", "lj_market": "city_market"}
ATTR = lambda i, n=1: {"type": "attr", "id": i, "amount": n}
FLAG = lambda i: {"type": "flag", "id": i}
LEAD = lambda i: {"type": "lead", "id": i}
SCHED = lambda i, a, b: {"type": "schedule", "id": i, "min": a, "max": b}
BOND = lambda c, n: {"type": "bond", "id": c, "amount": n}
STAMINA = lambda n: {"type": "stamina", "id": "stamina", "amount": n}
BATTLE = lambda i: {"type": "battle", "id": i}
RES = lambda i, n: {"type": "resource", "id": i, "amount": n}


def area(id, zn, en_, dz, de, wanders, **kw):
    a = {"id": id, "region": "yanmen", "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": 2, "wander": [],
         "open_default": True, "requires": {"lead": ["yanmen_road"], "week_min": 76}}
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



Y3 = {"week_min": 76}

# ===================================================================== AREAS
area("ym_fort", "雁门关", "Yanmen Fort", "灰石垒成的关城，城头的红旗被风扯得笔直。", "A fort of grey stone, its red banners snapped straight by the wind.",
     [("你在城下看守军换岗，鼓点整齐得像一个人。", "You watch the garrison change at the foot of the wall, drumbeats in perfect unison.", [("attr", "spirit", 1)]),
      ("一位老兵请你喝了一碗热酒。", "An old soldier shares a bowl of hot wine with you.", [("stamina", "stamina", 8)])])
area("ym_road", "商道", "Caravan Road", "通往关城的商道，车辙里结着薄冰。", "The caravan road to the fort, ice thin in the wheel ruts.",
     [("你替一支商队推了半日车，赚了几个铜板。", "You push wagons for a caravan half a day and earn a few coppers.", [("resource", "coins", 8)]),
      ("路边的驿站里，有人在低声谈论关外的动静。", "In a roadside post-house men murmur about movements beyond the pass.", [("attr", "insight", 1)])])
area("ym_pass", "雪岭隘口", "Snow Pass", "两山之间的窄道，积雪没到小腿。", "A narrow cut between two peaks, snow to the shin.",
     [("你在风口站了一会儿，把呼吸练得绵长。", "You stand a while in the wind, drawing long steady breaths.", [("attr", "body", 1)]),
      ("雪地里露出一块旧箭头，是上个冬天留下的。", "An old arrowhead shows in the snow, left from last winter.", [("resource", "ore", 1)])])
area("ym_field", "古战场", "Old Battlefield", "城外的旷野，枯草下还能看见旧日的断矛。", "Open ground beyond the walls; broken spears still show beneath the dead grass.",
     [("你在断矛之间走了一圈，心里沉甸甸的。", "You walk among the broken spears, heavy at heart.", [("attr", "spirit", 1)]),
      ("风里有人唱着古老的军歌，听不真切。", "Someone sings an old marching song in the wind, too faint to follow.", [("attr", "insight", 1)])],
     requires={"lead": ["yanmen_road"], "week_min": 76})

# ===================================================================== STORY
event("y2_road_north", "fixed", "ym_road",
      [("narr", "商道上的风雪来得极快，前面的车队停了下来。车夫们在雪里喊着号子，勉强把车从沟里拖出来。", "The storm on the caravan road comes fast. The wagons ahead halt and drivers heave their carts out of a ditch with shouted rhythms."),
       ("wander", "「这位少侠，往关里去？雁门最近不太平，守军连商队都要查三遍。」", "\"Heading into the fort, friend? Yanmen is uneasy lately; the garrison checks even caravans three times.\""),
       ("hero", "玉符在怀里发凉。灰面人信里说的，应该就是这里。", "The tally grows cold in my coat. This must be the place the Hui-Mask's letter meant.")],
      title=("商道风雪", "Storm on the Caravan Road"), window=(76, 80), priority=5, requires={"lead": ["yanmen_road"], "week_min": 76},
      choices=[("shelter", "帮商队扎营躲风", "Help the caravan make camp", [LEAD("fort_road"), ATTR("spirit", 1), STAMINA(4), SCHED("y2_xiao_hanchuan", 1, 4)]),
               ("push", "顶着风雪赶到关下", "Push on to the fort through the storm", [LEAD("fort_road"), ATTR("body", 2), STAMINA(-6), SCHED("y2_xiao_hanchuan", 1, 4)])],
      on_miss=[LEAD("fort_road"), SCHED("y2_xiao_hanchuan", 1, 4)])
event("y2_xiao_hanchuan", "fixed", "ym_fort",
      [("narr", "关门的石阶上，一名穿黑底银甲的青年拦住了你。他腰间的重刀没有出鞘，目光却比刀更冷。", "On the gate steps a young man in black-and-silver mail bars your way. His heavy sabre stays sheathed, yet his gaze is colder than steel."),
       ("xiao", "「萧寒川。雁门军职责所在，凡带兵器入关者，须验明来历。」", "\"Xiao Hanchuan. Duty of the Yanmen garrison: anyone entering with arms must show where they come from.\""),
       ("xiao", "「你怀里那半块玉，是怎么回事？」", "\"And that half jade at your breast: what is it?\"")],
      title=("关门盘查", "Questioned at the Gate"), scheduled_only=True, priority=5,
      choices=[("show", "取出玉符给他看", "Show him the tally", [BOND("xiao_hanchuan", 3), LEAD("fort_trust"), SCHED("y2_fort_orders", 2, 5)]),
               ("plain", "实话实说，不亮底牌", "Answer plainly without showing it", [BOND("xiao_hanchuan", 3), ATTR("insight", 1), SCHED("y2_fort_orders", 2, 5)]),
               ("spar", "「想验，就手底下见真章」", "\"If you want proof, test me with your hands\"", [BOND("xiao_hanchuan", 4), BATTLE("y2_xiao_spar"), SCHED("y2_fort_orders", 2, 5)])],
      on_miss=[SCHED("y2_fort_orders", 1, 5)])
event("y2_fort_orders", "fixed", "ym_fort",
      [("narr", "军营里的鼓声半夜响了三遍，却没有一队人马出营。", "The camp drums sound three times at midnight, yet no company leaves the barracks."),
       ("xiao", "「上面有令：关外三个村子遭劫，守军原地待命，不得出关。」他攥着刀鞘，指节发白。", "\"Orders from above: three villages beyond the pass are being raided and the garrison is to hold position, not to leave the fort.\" His knuckles whiten on the scabbard."),
       ("xiao", "「我不明白。你说，这是什么道理？」", "\"I do not understand it. Tell me, what sense is there in this?\"")],
      title=("按兵不动", "Hold Position"), scheduled_only=True, priority=5,
      choices=[("tell", "告诉他灰面人信里的事", "Tell him what the Hui-Mask's letter said", [BOND("xiao_hanchuan", 3), FLAG("orders_exposed"), LEAD("field_raids"), SCHED("y2_snow_pass", 2, 5)]),
               ("watch", "先不表态，自己去关外看看", "Say nothing and go look beyond the pass yourself", [ATTR("insight", 2), LEAD("field_raids"), SCHED("y2_snow_pass", 2, 5)])],
      on_miss=[LEAD("field_raids"), SCHED("y2_snow_pass", 1, 5)])
event("y2_snow_pass", "fixed", "ym_pass",
      [("narr", "雪岭隘口里的风像刀一样。前面的山坳里，一队灰衣人正在给商队的雪橇套绳。", "The wind in the snow pass cuts like a knife. In the hollow ahead, grey-clad men are tying ropes onto a caravan's sleds."),
       ("wander", "「救命！他们要抢走整支商队的货！」", "\"Help! They mean to take the whole caravan's goods!\"")],
      title=("雪岭护送", "Escort Through the Snow"), scheduled_only=True, priority=6,
      choices=[("fight", "出手拦下", "Step in", [BATTLE("y2_snow_pass"), LEAD("pass_raiders"), SCHED("y2_pass_battle", 2, 5)])],
      on_miss=[FLAG("pass_raid_missed"), SCHED("y2_pass_battle", 1, 5)])
event("y2_pass_battle", "fixed", "ym_field",
      [("narr", "黎明前，关外的号角响了三声。灰色的人潮从雪岭涌下，目标直指关门。", "Before dawn the horn beyond the fort sounds three times. A grey tide pours down from the snow ridge, aimed straight at the gate."),
       ("xiao", "「守军不得出关。」萧寒川看着你，缓缓拔出重刀，「可没人说，我不能站在你身边。」", "\"The garrison may not leave the fort.\" Xiao Hanchuan draws his heavy sabre, looking at you. \"No one said I could not stand beside you.\"")],
      title=("雁门一战", "The Battle for the Pass"), scheduled_only=True, priority=7,
      choices=[("fight", "并肩迎战", "Stand together", [BATTLE("y2_pass_battle"), BOND("xiao_hanchuan", 3)])],
      on_miss=[FLAG("pass_lost")])

# arc stages
event("arc_xiao_hanchuan_1", "fixed", "ym_fort",
      [("xiao", "「我父亲是这关的主将。」萧寒川站在城头，雪落在甲片上，「他教我：军令如山。可山下，有人在流血。」", "\"My father commands this fort,\" Xiao Hanchuan says on the wall, snow settling on his mail. \"He taught me an order is a mountain. But below the mountain, people are bleeding.\""),
       ("xiao", "「你为什么愿意帮我？」", "\"Why would you help me?\""),
       ("hero", "「因为你的刀，该为守护的人出鞘。」", "\"Because your blade should be drawn for the people it guards.\"")],
      [{"type": "arc_stage", "id": "xiao_hanchuan", "amount": 1}, LEAD("garrison_orders"), BOND("xiao_hanchuan", 2)], title=("军令与山下", "Orders and the Valley Below"),
      window=(80, 120), priority=6, requires={"bond_min": {"xiao_hanchuan": 4}},
      on_miss=[{"type": "arc_outcome", "id": "xiao_hanchuan", "value": "lost"}, {"type": "arc_stage", "id": "xiao_hanchuan", "amount": 4}])
event("arc_su_dai_2", "fixed", "ym_road",
      [("su", "「你听！」苏黛停下琵琶，「车队里的老乐师，会唱我娘那首曲子的第二段。」", "\"Listen!\" Su Dai stills her pipa. \"The old musician in the caravan knows the second verse of my mother's song.\""),
       ("su", "「『雁归关外，灯下寻星』……这是一个地方。」她抬头看你，眼睛亮得像雪地反光，「你陪我去找吗？」", "\"'Geese return beyond the pass, seek the star by lamplight'... that is a place.\" She looks up, her eyes bright as snow-glare. \"Will you come with me?\"")],
      [{"type": "arc_stage", "id": "su_dai", "amount": 2}, LEAD("song_second_verse"), BOND("su_dai", 3)], title=("第二段歌词", "The Second Verse"),
      window=(80, 110), priority=6, requires={"bond_min": {"su_dai": 8}, "arc_min": {"su_dai": 1}},
      on_miss=[{"type": "arc_outcome", "id": "su_dai", "value": "lost"}, {"type": "arc_stage", "id": "su_dai", "amount": 4}])
event("arc_li_shan_2", "fixed", "ym_road",
      [("li", "「北边的铁，好。」厉山蹲在一辆矿车旁，用指节敲了敲矿石，「我那炉子里的矿，是从这里运去的。」", "\"Northern iron is good,\" Li Shan says, crouched by an ore cart, knocking a chunk with his knuckle. \"The ore in my furnace came from here.\""),
       ("li", "「那场火，是为了不让人看见这批矿。」他把矿石放回车里，「有人在北边挖不该挖的东西。」", "\"The fire was lit so nobody would see this ore.\" He sets the chunk back. \"Someone in the north is digging what should not be dug.\"")],
      [{"type": "arc_stage", "id": "li_shan", "amount": 2}, LEAD("northern_ore"), BOND("li_shan", 3), ATTR("body", 1)], title=("北边的铁", "Northern Iron"),
      window=(78, 110), priority=6, requires={"bond_min": {"li_shan": 8}, "arc_min": {"li_shan": 1}},
      on_miss=[{"type": "arc_outcome", "id": "li_shan", "value": "lost"}, {"type": "arc_stage", "id": "li_shan", "amount": 4}])
for a in arcs["arcs"]:
    if a["companion"] == "su_dai":
        a["stages"].append({"id": "2", "event": "arc_su_dai_2"})
    if a["companion"] == "li_shan":
        a["stages"].append({"id": "2", "event": "arc_li_shan_2"})

RANDOM = [
 ("ry6_fort_drill", "ym_fort", [("narr", "操场上守军列阵操练，刀光在雪地上闪成一条线。", "On the drill ground the garrison trains, blades flashing in a line over the snow.")], [ATTR("power", 1)], ("守军操练", "Garrison Drill"), 3, 5),
 ("ry6_fort_mess", "ym_fort", [("gar", "伙房的老兵递来一碗热汤：「喝吧，打仗前最要紧的是不饿。」", "The mess veteran passes a hot bowl: \"Drink. Before a fight the main thing is not to be hungry.\"")], [STAMINA(10)], ("伙房热汤", "Hot Soup in the Mess"), 4, 4),
 ("ry6_road_wagon", "ym_road", [("narr", "一辆货车陷在雪里，你和车夫合力把它推了出来。", "A wagon is stuck in the snow; you and the driver heave it clear.")], [RES("coins", 6), ATTR("body", 1)], ("推车", "Pushing the Wagon"), 3, 5),
 ("ry6_road_tale", "ym_road", [("wander", "老车夫讲起雁门的旧事：「这关墙，是用战死兄弟的名字垒起来的。」", "An old driver tells of Yanmen's past: \"This wall was built on the names of fallen brothers.\"")], [ATTR("spirit", 1)], ("老车夫的话", "The Old Driver's Tale"), 3, 8),
 ("ry6_pass_wind", "ym_pass", [("narr", "山风吹得人站不稳，你顺着风势练了一套身法。", "The mountain wind can barely be stood against, and you work a footwork set along with it.")], [ATTR("agility", 1)], ("风口练步", "Footwork in the Wind"), 3, 5),
 ("ry6_pass_hunt", "ym_pass", [("narr", "雪地里有野兔的脚印，你追了半日，带回了一只。", "Hare tracks cross the snow; you follow them half a day and bring one back.")], [RES("food", 3)], ("雪地追兔", "Hunting a Hare"), 3, 6),
 ("ry6_field_spears", "ym_field", [("narr", "你把几根断矛插回土里，替无名的人立了一圈碑。", "You push broken spears back into the earth, a ring of markers for the nameless.")], [ATTR("spirit", 1)], ("立矛为碑", "Spears for Markers"), 3, 6),
 ("ry6_field_song", "ym_field", [("narr", "风里的军歌近了些，你听清了一句：「同袍不弃。」", "The marching song comes nearer, and you catch one line: 'Never abandon a comrade.'")], [ATTR("insight", 1)], ("风中军歌", "Song on the Wind"), 3, 8),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y3)

# ===================================================================== BATTLES
units["units"].append({"id": "yanmen_raider", "stats": {"hp": 48, "body": 8, "power": 11, "agility": 8, "spirit": 6}, "techniques": ["swift_dash"]})
units["units"].append({"id": "garrison_sabre", "stats": {"hp": 130, "body": 12, "power": 15, "agility": 8, "spirit": 9}, "techniques": ["club_smash"]})
L("combat.unit.yanmen_raider", "关外劫匪", "Border Raider"); L("combat.unit.garrison_sabre", "守军刀手", "Garrison Sabreman")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10, terrain=None):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": terrain or [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y2_xiao_spar", "关门切磋", "Sparring at the Gate", "胜过守军刀手。", "Best the garrison sabreman.", ["garrison_sabre"], [RES("coins", 8)], ["xiao_spar_won"], ["xiao_spar_lost"], 8)
scenario("y2_snow_pass", "雪岭护送", "Escort Through the Snow", "击退四名劫匪。", "Drive off the four raiders.", ["yanmen_raider", "yanmen_raider", "yanmen_raider", "yanmen_raider"],
         [RES("coins", 20), RES("ore", 2)], ["pass_raid_won"], ["pass_raid_lost"], 10, [[1, 3, "hazard"], [4, 3, "hazard"], [2, 4, "cover"], [3, 2, "hazard"]])
scenario("y2_pass_battle", "雁门一战", "The Battle for the Pass", "击退关外的全部敌人。", "Beat back every attacker beyond the fort.",
         ["gate_captain", "gate_blade", "yanmen_raider", "yanmen_raider", "gate_scout", "gate_scout"], [RES("coins", 40), RES("ore", 3)], ["pass_won"], ["pass_lost"], 12,
         [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"], [0, 2, "hazard"], [5, 2, "hazard"]])

# ===================================================================== XIAO HANCHUAN
def tech(id, fields, zn, en_, dz, de):
    t = {"id": id, "name_key": "ability." + id}; t.update(fields); ct["techniques"].append(t)
    L("ability." + id, zn, en_); L("ability." + id + ".desc", dz, de)
tech("rally_cry", dict(kind="support", range=3, resolve_restore=5, cost=1), "军令", "Rally Cry", "一声军令，让友方恢复5点气势，射程3。", "A command that restores 5 resolve to an ally, range 3.")
tech("sabre_counter", dict(kind="attack", range=1, damage=9, resolve=5, push=1, cost=2), "横刀", "Sabre Counter", "近身重击，把敌人击退一格。", "A heavy close strike that knocks the enemy back.")
tech("garrison_order", dict(kind="support", range=0, mp_bonus=2, resolve_restore=6, cost=0, free=True, once=True, bond=True), "整军", "Garrison Order", "羁绊技（每场一次，不耗行动）：多走2格，并恢复6点气势。", "Bond ability (once per battle, no action): 2 extra cells and 6 resolve restored.")
ct["techniques"].append({"id": "duo_command_charge", "name_key": "technique.duo_command_charge", "duo": "xiao_hanchuan", "kind": "attack", "range": 2, "damage": 11, "resolve": 6, "cost": 3})
L("technique.duo_command_charge", "令出如山", "Command Like a Mountain")
duos["duos"].append({"id": "duo_command_charge", "companion": "xiao_hanchuan", "tech": "duo_command_charge", "bond_min": 12})
comps["companions"].append({"id": "xiao_hanchuan", "name_key": "npc.xiao_hanchuan", "bio_key": "companion.xiao_hanchuan.bio", "portrait": "portrait_xiao_hanchuan", "role": "control",
    "stats": {"body": 9, "power": 8, "agility": 5, "insight": 6, "spirit": 7}, "preferred_activities": ["training", "hunting", "meditation"],
    "recruit": {"score_min": 8, "attr_min": {"body": 8}, "flags_block": [], "week_min": 80}, "depart": {"score_below": 0, "flags": ["xiao_hanchuan_betrayed"]},
    "battle_abilities": ["rally_cry", "sabre_counter"], "relationship_ability": "garrison_order", "meet_week": 78})
L("companion.xiao_hanchuan.bio", "雁门主将之子，军令如山，外冷内热，肩上扛着整座边关。", "The garrison commander's son: duty like a mountain, cold outside and warm within, with a border on his shoulders.")
looks["looks"].append({"id": "xiao_hanchuan", "gender": "m", "hair": 2, "hair_hex": "1c1c22", "outfit_hex": "34383f", "skin_hex": "d8b494", "weapon": "blade"})
arcs["arcs"].append({"companion": "xiao_hanchuan", "planned": 4, "stages": [{"id": "1", "event": "arc_xiao_hanchuan_1"}], "outcomes": ["redeemed", "alternate", "lost"], "bonds": ["friend", "sworn", "romance", "rival"]})

LEADS = {"fort_road": ("通往雁门之路", "The Road to the Fort", "商道尽头就是雁门关，守军盘查很严。", "The caravan road ends at Yanmen Fort, where the garrison checks everyone."),
         "fort_trust": ("萧寒川的信任", "Xiao's Trust", "你向萧寒川亮出了玉符，他没有声张。", "You showed Xiao Hanchuan the tally and he kept it quiet."),
         "field_raids": ("关外劫村", "Raids Beyond the Pass", "守军奉命不出关，关外三个村子接连遭劫。", "The garrison is ordered to stay in the fort while three villages beyond are raided in turn."),
         "pass_raiders": ("雪岭劫匪", "Raiders in the Snow", "雪岭劫匪的腰间系着灰色的布条，与无相门的人一样。", "The raiders in the snow wear grey cloth bands like the Faceless Gate."),
         "garrison_orders": ("军令之谜", "The Mystery of the Orders", "是谁在压着雁门守军不许出关？", "Who is keeping the Yanmen garrison from leaving the fort?"),
         "song_second_verse": ("第二段歌词", "The Second Verse", "「雁归关外，灯下寻星」，苏黛的曲子指向一个地方。", "'Geese return beyond the pass, seek the star by lamplight': Su Dai's song points to a place."),
         "northern_ore": ("北边的铁", "Northern Iron", "那批被烧毁的矿，原来是从北边运来的。", "The burned ore came from the north.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("combat/scenarios.json", scen); dump("combat/units.json", units); dump("companions/companions.json", comps)
dump("story/looks.json", looks); dump("combat/combat_techniques.json", ct); dump("combat/duo.json", duos); dump("companions/arcs.json", arcs)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events", len(areas["areas"]), "areas", len(comps["companions"]), "companions")
