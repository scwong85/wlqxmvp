#!/usr/bin/env python3
"""M24c: Year 2 quarter 7 (Traces on the Sea, weeks 91 to 105): Penglai, the second star fragment, the hermit trial (gate to the fifth realm),
a sea ambush and arc stage 2 for Xia Zhi and Xiao Hanchuan. Run AFTER gen_year2_q6. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); arcs = load("companions/arcs.json"); looks = load("story/looks.json"); realms = load("cultivation/realms.json")

OWN_AREAS = ["pd_harbour", "pd_cave", "pd_monastery"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
PREFIX = ("y4_", "ry7_", "arc_xia_zhi_2", "arc_xiao_hanchuan_2")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["y2_hermit_trial", "y2_sea_ambush", "y2_harbour_brawl"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
units["units"] = [u for u in units["units"] if u["id"] not in ["sea_raider", "hermit_master"]]
looks["looks"] = [l for l in looks["looks"] if l["id"] != "isle_yun"]
looks["looks"].append({"id": "isle_yun", "gender": "f", "hair": 3, "hair_hex": "3a4a5a", "outfit_hex": "9ad0cc", "skin_hex": "f0d8c4", "weapon": ""})
for a in arcs["arcs"]:
    if a["companion"] in ("xia_zhi", "xiao_hanchuan"):
        a["stages"] = [s for s in a["stages"] if s["id"] == "1"]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "yun": "npc.isle_yun", "xia": "npc.xia_zhi", "xiao": "npc.xiao_hanchuan",
       "boss": "npc.guild_master", "sailor": "npc.sailor"}
WHO = {"wander": "wanderer", "yun": "isle_yun", "xia": "xia_zhi", "xiao": "xiao_hanchuan", "boss": "guild_master", "sailor": "wanderer"}
L("npc.isle_yun", "云眠", "Yun Mian"); L("npc.sailor", "老水手", "Old Sailor")
BG = {"pd_harbour": "penglai_sea", "pd_cave": "penglai_cave", "pd_monastery": "penglai_sea", "lj_docks": "city_docks", "lj_alleys": "city_night", "ym_fort": "yanmen_fort"}
ATTR = lambda i, n=1: {"type": "attr", "id": i, "amount": n}
FLAG = lambda i: {"type": "flag", "id": i}
LEAD = lambda i: {"type": "lead", "id": i}
SCHED = lambda i, a, b: {"type": "schedule", "id": i, "min": a, "max": b}
BOND = lambda c, n: {"type": "bond", "id": c, "amount": n}
STAMINA = lambda n: {"type": "stamina", "id": "stamina", "amount": n}
BATTLE = lambda i: {"type": "battle", "id": i}
RES = lambda i, n: {"type": "resource", "id": i, "amount": n}


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



Y4 = {"week_min": 91}

# the fifth realm (pure flame) needs the hermit trial; missing the scene never blocks it (on_miss sets the flag too)
for r in realms["realms"]:
    if r["id"] == "pure_flame":
        r["requires"]["flag"] = "hermit_trial_done"

# ===================================================================== AREAS
area("pd_harbour", "蓬岛港", "Penglai Harbour", "弯月形的小港，贝壳灯在晨雾里一盏盏熄灭。", "A crescent harbour where shell lanterns go out one by one in the morning mist.",
     [("你帮渔人拉了半日网，换来一篮海货。", "You haul nets with fishermen half a day and earn a basket of catch.", [("resource", "food", 3)]),
      ("老水手教你辨认潮声，说那是海在说话。", "An old sailor teaches you to read the tide's sound, 'the sea speaking'.", [("attr", "insight", 1)])])
area("pd_cave", "珊瑚洞", "Coral Cave", "海水退去后露出的洞穴，洞顶映着粼粼的光。", "A cave bared by the ebbing tide, its ceiling rippling with light.",
     [("你在洞里静坐，听水滴在珊瑚上的声音。", "You sit in the cave listening to drops fall on coral.", [("attr", "spirit", 1)]),
      ("潮缝里卡着几颗珍珠大小的矿粒。", "A few pearl-sized ore grains are wedged in the tide cracks.", [("resource", "ore", 2)])])
area("pd_monastery", "灯塔寺", "Lighthouse Monastery", "崖顶的白塔，夜里整座岛都能看见它的灯。", "A white tower on the cliff whose lamp the whole isle sees at night.",
     [("你在廊下抄了半卷经，字里行间都是海风的盐味。", "You copy half a scroll under the eaves, salt wind in every line.", [("attr", "insight", 1)]),
      ("守塔的僧人请你喝了一杯热茶。", "The tower monk offers you a cup of hot tea.", [("stamina", "stamina", 8)])])

# ===================================================================== STORY
event("y2_guild_ship", "fixed", "lj_docks",
      [("narr", "码头尽头泊着一条没挂旗的海船。旧漕帮的老伙计压低声音：「这船明日出海，去东边的蓬岛。」", "At the end of the docks lies an unflagged sea ship. An old guild hand says quietly: \"She sails tomorrow for Penglai in the east.\""),
       ("boss", "「灰面人托人带话，说蓬岛的灯塔下面，有一颗星。」", "\"The Hui-Mask sent word through a friend: there is a star beneath Penglai's lighthouse.\"")],
      title=("东去的海船", "A Ship to the East"), window=(88, 95), priority=5, requires={"week_min": 88},
      choices=[("pay", "付船钱，坐舱", "Pay for a berth", [LEAD("penglai_route"), SCHED("y2_crossing", 1, 3), ATTR("spirit", 1)]),
               ("work", "上船当水手抵船钱", "Work your passage as a deckhand", [LEAD("penglai_route"), SCHED("y2_crossing", 1, 3), ATTR("body", 2), STAMINA(-4)])],
      on_miss=[LEAD("penglai_route"), SCHED("y2_crossing", 1, 3)])
event("y2_crossing", "fixed", "pd_harbour",
      [("narr", "海上的风向在半夜变了。桅杆吱呀作响，浪头一下下拍在甲板上。", "The wind turns at midnight. The mast creaks and waves slam the deck again and again."),
       ("sailor", "「风急了！有人去收帆，有人去舀水，剩下的，抓牢缆绳！」", "\"The gale's up! Some furl the sails, some bail, the rest hold fast to the ropes!\"")],
      title=("海上风暴", "Storm at Sea"), scheduled_only=True, priority=5,
      choices=[("sail", "上桅杆收帆", "Climb to furl the sail", [ATTR("agility", 2), STAMINA(-6), SCHED("y2_yun_mian", 1, 4), FLAG("crossing_sail")]),
               ("bail", "下舱舀水", "Go below and bail", [ATTR("body", 2), STAMINA(-6), SCHED("y2_yun_mian", 1, 4), FLAG("crossing_bail")]),
               ("rope", "守着缆绳稳住大家", "Hold the rope and steady the others", [ATTR("spirit", 2), SCHED("y2_yun_mian", 1, 4), FLAG("crossing_rope")])],
      on_miss=[SCHED("y2_yun_mian", 1, 4)])
event("y2_yun_mian", "fixed", "pd_monastery",
      [("narr", "灯塔寺的廊下，一位长发如浪的女子正望着海。她身后的灯，已经熄了。", "On the monastery porch a woman with wave-like hair watches the sea. The lamp behind her has gone out."),
       ("yun", "「云眠。蓬岛的守灯人。」她没回头，「你怀里的玉，每过七日便会亮一次。你知道为什么吗？」", "\"Yun Mian, keeper of Penglai's lamp.\" She does not turn. \"The jade at your breast glows once every seven days. Do you know why?\""),
       ("yun", "「我不问你从哪来。我只问：你若得到九颗星，要拿它做什么？」", "\"I do not ask where you came from. I ask only: if you gather all nine stars, what will you do with them?\"")],
      title=("守灯人", "The Lamp Keeper"), scheduled_only=True, priority=5,
      choices=[("protect", "守住它，不让任何人用", "Guard them so nobody can use them", [FLAG("yun_guard"), LEAD("hermit_trials"), SCHED("y2_coral_cave", 2, 5), ATTR("spirit", 2)]),
               ("mend", "用它修补被撕开的江湖", "Use them to mend the torn martial world", [FLAG("yun_mend"), LEAD("hermit_trials"), SCHED("y2_coral_cave", 2, 5), ATTR("insight", 2)]),
               ("unknown", "我还不知道", "I do not know yet", [FLAG("yun_unsure"), LEAD("hermit_trials"), SCHED("y2_coral_cave", 2, 5), BOND("su_dai", 1)])],
      on_miss=[LEAD("hermit_trials"), SCHED("y2_coral_cave", 1, 5)])
event("y2_coral_cave", "fixed", "pd_cave",
      [("narr", "潮水退到最低时，珊瑚洞深处露出一块嵌在石中的星形玉片，在黑暗里发着冷光。", "At the lowest tide a star-shaped jade fragment set in the rock shows deep in the coral cave, glowing cold in the dark."),
       ("hero", "第二颗星。玉符在怀里发烫，像是在回应它。", "The second star. The tally burns at my breast as if answering it.")],
      title=("第二颗星", "The Second Star"), scheduled_only=True, priority=6,
      choices=[("take", "取下玉片", "Take the fragment", [LEAD("fragment_two"), FLAG("fragment_two_taken"), ATTR("insight", 2), SCHED("y2_trial_breakthrough", 2, 5)]),
               ("leave", "留在原处，只拓下纹路", "Leave it and take a rubbing of its pattern", [LEAD("fragment_two"), FLAG("fragment_two_left"), ATTR("spirit", 2), SCHED("y2_trial_breakthrough", 2, 5)])],
      on_miss=[LEAD("fragment_two"), SCHED("y2_trial_breakthrough", 1, 5)])
event("y2_trial_breakthrough", "fixed", "pd_monastery",
      [("yun", "「隐宗的规矩：想跨过下一道门，先过我这一关。」云眠把灯芯拨亮，「不为输赢，只为让我看见你的火。」", "\"The hermit rule: to cross the next door, first pass me.\" Yun Mian trims the wick. \"Not for victory or defeat, only so I may see your flame.\""),
       ("hero", "我把包袱放在廊下，握紧了拳。", "I set my pack beneath the eaves and clench my fists.")],
      title=("隐宗试炼", "The Hermit Trial"), scheduled_only=True, priority=6,
      choices=[("face", "接受试炼", "Accept the trial", [BATTLE("y2_hermit_trial"), FLAG("hermit_trial_done"), LEAD("hermit_blessing")])],
      on_miss=[FLAG("hermit_trial_done"), FLAG("hermit_trial_skipped"), SCHED("y2_ship_back", 1, 4)])
event("y2_ship_back", "fixed", "pd_harbour",
      [("narr", "返程的海船刚离港，海面上就多了三条没挂旗的快船，船头站满了灰衣人。", "The ship has barely left harbour when three unflagged fast boats close in, their bows crowded with grey-clad men."),
       ("sailor", "「他们要的是你怀里的东西！」老水手把舵握得发白，「你们去甲板上，我拖住船！」", "\"They want what is at your breast!\" The old sailor whitens his knuckles on the helm. \"You to the deck, I will hold the ship!\"")],
      title=("海上拦截", "Intercepted at Sea"), scheduled_only=True, priority=6,
      choices=[("fight", "守住甲板", "Hold the deck", [BATTLE("y2_sea_ambush")])],
      on_miss=[FLAG("sea_ambush_missed")])
# the trial's follow-up is scheduled by the dialogue's battle effect; schedule the ambush when the trial ends
for e in events["events"]:
    if e["id"] == "y2_trial_breakthrough":
        pass
d = [x for x in dlgs["dialogues"] if x["id"] == "ev_y2_trial_breakthrough"][0]
for ch in d["nodes"][-1]["choices"]:
    ch["effects"].append(SCHED("y2_ship_back", 2, 5))

# arc stages
event("arc_xia_zhi_2", "fixed", "lj_alleys",
      [("xia", "「我给他们传过信。」夏芷靠在墙上，不看你，「他们给我吃的，给我屋子，也给我一个名字。」", "\"I have carried messages for them,\" Xia Zhi says, leaning on the wall without looking at you. \"They gave me food, a roof, and a name.\""),
       ("xia", "「今晚他们要我去拿一样东西。你猜，是什么？」她终于抬头，「我想让你替我选。」", "\"Tonight they want me to fetch something. Guess what.\" At last she looks up. \"I want you to choose for me.\"")],
      [{"type": "arc_stage", "id": "xia_zhi", "amount": 2}, LEAD("gate_errand"), BOND("xia_zhi", 3), ATTR("agility", 1)], title=("夜里的差事", "Tonight's Errand"),
      window=(84, 115), priority=6, requires={"bond_min": {"xia_zhi": 8}, "arc_min": {"xia_zhi": 1}},
      on_miss=[{"type": "arc_outcome", "id": "xia_zhi", "value": "lost"}, {"type": "arc_stage", "id": "xia_zhi", "amount": 4}])
event("arc_xiao_hanchuan_2", "fixed", "ym_fort",
      [("xiao", "「我写了一封信，给我父亲。」萧寒川把折好的纸压在刀鞘下，「问他，为什么按兵不动。」", "\"I wrote a letter to my father,\" Xiao Hanchuan says, pressing a folded page under his scabbard. \"Asking why we hold position.\""),
       ("xiao", "「回信只有四个字：『军令如山』。」他苦笑，「我这辈子第一次，不知道山在哪边。」", "\"The reply was four words: 'An order is a mountain.'\" He smiles wryly. \"For the first time in my life I do not know which side the mountain is on.\"")],
      [{"type": "arc_stage", "id": "xiao_hanchuan", "amount": 2}, LEAD("fathers_reply"), BOND("xiao_hanchuan", 3), ATTR("spirit", 1)], title=("四个字的回信", "A Four-Word Reply"),
      window=(88, 118), priority=6, requires={"bond_min": {"xiao_hanchuan": 8}, "arc_min": {"xiao_hanchuan": 1}},
      on_miss=[{"type": "arc_outcome", "id": "xiao_hanchuan", "value": "lost"}, {"type": "arc_stage", "id": "xiao_hanchuan", "amount": 4}])
for a in arcs["arcs"]:
    if a["companion"] == "xia_zhi":
        a["stages"].append({"id": "2", "event": "arc_xia_zhi_2"})
    if a["companion"] == "xiao_hanchuan":
        a["stages"].append({"id": "2", "event": "arc_xiao_hanchuan_2"})

RANDOM = [
 ("ry7_harbour_nets", "pd_harbour", [("narr", "渔人们拉网的号子此起彼伏，你搭了把手。", "Fishermen's hauling chants rise and fall and you lend a hand.")], [RES("food", 3), ATTR("body", 1)], ("拉网", "Hauling Nets"), 3, 5),
 ("ry7_harbour_pirates", "pd_harbour", [("narr", "码头上几个海盗打扮的人拦住了一个卖贝的孩子，正伸手去抢他的篮子。", "A few pirate-dressed men block a shell-selling child on the quay, reaching to grab his basket.")], [], ("码头劫匪", "Harbour Brawl"), 3, 6),
 ("ry7_harbour_tale", "pd_harbour", [("sailor", "老水手说：「蓬岛的灯塔，从前每一盏都是为迷路的船点的。」", "The old sailor says: \"Every lamp in Penglai's tower used to be lit for ships that had lost their way.\"")], [ATTR("spirit", 1)], ("灯塔的来历", "Why the Lamp Burns"), 3, 8),
 ("ry7_cave_pearls", "pd_cave", [("narr", "你在潮缝里摸到几颗圆润的石子，对着光一看，是上好的矿粒。", "You find smooth stones in the tide cracks; held to the light they are fine ore grains.")], [RES("ore", 2)], ("潮缝拾矿", "Ore in the Tide"), 3, 6),
 ("ry7_cave_echo", "pd_cave", [("narr", "洞里的回声带着水的味道，你对着它吐纳了一个时辰。", "The cave's echo smells of water; you breathe in rhythm with it for an hour.")], [ATTR("spirit", 1), ATTR("insight", 1)], ("洞中吐纳", "Breathing in the Cave"), 3, 6),
 ("ry7_monastery_sweep", "pd_monastery", [("narr", "守塔的僧人递给你一把竹帚，你扫了半日的落叶。", "The tower monk hands you a bamboo broom and you sweep leaves half the day.")], [ATTR("spirit", 1), STAMINA(4)], ("扫塔前", "Sweeping the Tower Court"), 3, 5),
 ("ry7_monastery_copy", "pd_monastery", [("narr", "你替僧人抄写了一段航海歌，字里行间有潮汐的记号。", "You copy a sea-chant for the monks, tide marks in the margins.")], [ATTR("insight", 1)], ("抄航海歌", "Copying the Sea-Chant"), 3, 8),
 ("ry7_monastery_tea", "pd_monastery", [("narr", "僧人煮了一壶海盐茶，味道又苦又咸，喝完却觉得精神一振。", "The monk brews salt-sea tea, bitter and briny, and you feel refreshed after it.")], [STAMINA(10)], ("海盐茶", "Sea-Salt Tea"), 3, 4),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    if id == "ry7_harbour_pirates":
        event(id, "random", ar, lines, title=title, weight=wt, cooldown=cd, requires=Y4,
              choices=[("fight", "出手", "Step in", [BATTLE("y2_harbour_brawl"), ATTR("power", 1)]), ("walk", "绕开", "Walk past", [ATTR("agility", 1)])])
    else:
        event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y4)

# ===================================================================== BATTLES
units["units"].append({"id": "sea_raider", "stats": {"hp": 56, "body": 9, "power": 12, "agility": 9, "spirit": 7}, "techniques": ["swift_dash"]})
units["units"].append({"id": "hermit_master", "stats": {"hp": 300, "body": 16, "power": 19, "agility": 11, "spirit": 16}, "techniques": ["club_smash"]})
L("combat.unit.sea_raider", "海上劫匪", "Sea Raider"); L("combat.unit.hermit_master", "隐宗试炼者", "Hermit Trial Master")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10, terrain=None):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": terrain or [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y2_hermit_trial", "隐宗试炼", "The Hermit Trial", "在云眠面前坚持到最后。", "Hold your ground before Yun Mian.", ["hermit_master"], [RES("coins", 20)], ["hermit_trial_won"], ["hermit_trial_lost"], 12)
scenario("y2_sea_ambush", "海上拦截", "Intercepted at Sea", "守住甲板，击退全部劫匪。", "Hold the deck and beat off every raider.", ["gate_captain", "sea_raider", "sea_raider", "sea_raider"],
         [RES("coins", 30), RES("ore", 2)], ["sea_ambush_won"], ["sea_ambush_lost"], 12, [[1, 3, "cover"], [4, 3, "cover"], [0, 2, "hazard"], [5, 2, "hazard"]])
scenario("y2_harbour_brawl", "码头劫匪", "Harbour Brawl", "赶跑三个海盗打扮的劫匪。", "Chase off the three pirate-dressed robbers.", ["sea_raider", "sea_raider", "sea_raider"],
         [RES("coins", 12)], ["brawl_won"], ["brawl_lost"], 10)

LEADS = {"penglai_route": ("东去的海路", "The Sea Route East", "旧漕帮有一条没挂旗的海船，去东边的蓬岛。", "An old guild ship sails unflagged for Penglai in the east."),
         "hermit_trials": ("隐宗试炼", "The Hermit Trials", "云眠要在你跨过下一道门之前，亲眼看看你的火。", "Yun Mian will see your flame before you cross the next door."),
         "fragment_two": ("第二颗星", "The Second Star", "珊瑚洞里嵌着第二块「九曜」玉片。", "A second Nine-Star fragment is set in the coral cave."),
         "hermit_blessing": ("灯下的认可", "The Lamp's Regard", "云眠在灯下认可了你的火。", "Yun Mian has acknowledged your flame by the lamp."),
         "gate_errand": ("夏芷的差事", "Xia Zhi's Errand", "无相门要夏芷在今晚拿走一件东西。", "The Faceless Gate wants Xia Zhi to fetch something tonight."),
         "fathers_reply": ("四字回信", "A Four-Word Reply", "萧将军的回信只有四个字：军令如山。", "The general's reply is four words: an order is a mountain.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)
zh["realm.req.hermit"] = "隐宗试炼 {have}/{need}"; en["realm.req.hermit"] = "Hermit trial {have}/{need}"
zh["realm.blocked.hermit"] = "尚未通过隐宗试炼"; en["realm.blocked.hermit"] = "The hermit trial is not yet passed"

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("combat/scenarios.json", scen); dump("combat/units.json", units); dump("companions/arcs.json", arcs); dump("cultivation/realms.json", realms); dump("story/looks.json", looks)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events", len(areas["areas"]), "areas")
