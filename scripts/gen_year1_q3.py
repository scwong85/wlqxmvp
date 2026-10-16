#!/usr/bin/env python3
"""M22c: Year 1 quarter 3 (Mount Cangwu: weeks 31 to 50). Run AFTER gen_world, gen_arts, gen_arcs, gen_year1. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); comps = load("companions/companions.json")
looks = load("story/looks.json"); ct = load("combat/combat_techniques.json"); duos = load("combat/duo.json"); arcs = load("companions/arcs.json")
manuals = load("cultivation/manuals.json")

OWN_AREAS = ["cw_gate", "cw_courts", "cw_library", "cw_cave", "cw_spring"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
PREFIX = ("q3_", "ry3_", "arc_xie_wujiu_")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["xie_duel", "cw_bout_1", "cw_bout_2", "cw_bout_3"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
units["units"] = [u for u in units["units"] if u["id"] not in ["cangwu_disciple", "cangwu_senior"]]
comps["companions"] = [c for c in comps["companions"] if c["id"] != "xie_wujiu"]
looks["looks"] = [l for l in looks["looks"] if l["id"] not in ["xie_wujiu", "master_gu", "mask_hui"]]
NEW_TECH = ["spear_sweep", "proud_stance", "spear_oath", "duo_spear_wind", "pine_strike"]
ct["techniques"] = [t for t in ct["techniques"] if t["id"] not in NEW_TECH]
duos["duos"] = [d for d in duos["duos"] if d["companion"] != "xie_wujiu"]
arcs["arcs"] = [a for a in arcs["arcs"] if a["companion"] != "xie_wujiu"]
manuals["manuals"] = [m for m in manuals["manuals"] if m["id"] != "pine_sutra"]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "xie": "npc.xie_wujiu", "gu": "npc.master_gu",
       "hui": "npc.mask_hui", "bai": "npc.bai_yan", "shen": "npc.shen_qinghe", "lu": "npc.lu_chenzhou", "disc": "npc.cangwu_disciple"}
WHO = {"xie": "xie_wujiu", "gu": "master_gu", "hui": "mask_hui", "bai": "bai_yan", "wander": "wanderer", "disc": "wanderer", "shen": "shen_qinghe", "lu": "lu_chenzhou"}
L("npc.xie_wujiu", "谢无咎", "Xie Wujiu"); L("npc.master_gu", "顾行舟掌门", "Master Gu Xingzhou"); L("npc.mask_hui", "灰面", "The Hui-Mask"); L("npc.cangwu_disciple", "苍梧弟子", "Cangwu Disciple")
BG = {"cw_gate": "cangwu_day", "cw_courts": "cangwu_day", "cw_library": "cangwu_day", "cw_cave": "cangwu_night", "cw_spring": "cangwu_night", "lj_teahouse": "city_market"}
ATTR = lambda i, n=1: {"type": "attr", "id": i, "amount": n}
RES = lambda i, n: {"type": "resource", "id": i, "amount": n}
FLAG = lambda i: {"type": "flag", "id": i}
LEAD = lambda i: {"type": "lead", "id": i}
SCHED = lambda i, a, b: {"type": "schedule", "id": i, "min": a, "max": b}
BOND = lambda c, n: {"type": "bond", "id": c, "amount": n}
STAMINA = lambda n: {"type": "stamina", "id": "stamina", "amount": n}
BATTLE = lambda i: {"type": "battle", "id": i}

def area(id, zn, en_, dz, de, wanders, **kw):
    a = {"id": id, "region": "cangwu", "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": 2, "wander": [],
         "open_default": True, "requires": {"lead": ["cangwu_invite"], "week_min": 31}}
    L(a["name_key"], zn, en_); L(a["desc_key"], dz, de)
    for i, (z, e, rw) in enumerate(wanders):
        k = f"world.area.{id}.w{i+1}"; L(k, z, e); a["wander"].append({"text_key": k, "rewards": [{"type": t, "id": r, "amount": n} for t, r, n in rw]})
    a.update(kw); areas["areas"].append(a)

def event(id, kind, area_id, lines, effects_end=None, choices=None, title=None, window=None, **kw):
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
    dlgs["dialogues"].append({"id": "ev_" + id, "entry": [{"node": "n1"}], "nodes": nodes})

# ===================================================================== AREAS
area("cw_gate", "苍梧山门", "Cangwu Gate Steps", "九百级石阶通向云里，两侧古松如卫。", "Nine hundred stone steps climb into cloud, guarded by old pines.",
     [("你沿着石阶一级级走上去，腿酸了，心却静了。", "You climb the steps one by one; the legs ache but the mind settles.", [("attr", "spirit", 1)]),
      ("守门弟子见你有礼，指点了你几句入门的规矩。", "A gate disciple sees your manners and passes on a few house rules.", [("attr", "insight", 1)])])
area("cw_courts", "演武场", "Training Courts", "青石铺成的场地，从清晨起就有弟子对练。", "Blue-stone courts where disciples spar from dawn.",
     [("你在场边观摩了半个时辰的对练。", "You watch half an hour of sparring from the edge.", [("attr", "power", 1)]),
      ("一位师兄陪你拆了几招，赏了你一壶水。", "A senior brother trades a few moves and hands you a flask of water.", [("stamina", "stamina", 6)])])
area("cw_library", "藏经阁", "Scripture Library", "三层木阁，墨香与旧纸味混在一处。", "Three storeys of timber, ink and old paper mingled.",
     [("你在角落里翻到一本残缺的《松风注》。", "In a corner you find a damaged copy of the Pine-Wind Notes.", [("attr", "insight", 1)]),
      ("管阁的老僧请你帮忙晾书，赏了你几文钱。", "The old keeper asks you to air the books and tips you a few coins.", [("resource", "coins", 8)])])
area("cw_cave", "断崖洞", "Cliff Cave", "悬崖腰上的天然洞穴，传说从前有人在此闭关。", "A natural cave halfway up the cliff, once a place of seclusion.",
     [("洞里冷得刺骨，你在黑暗里打坐了一阵。", "The cave is bitterly cold; you sit in the dark for a while.", [("attr", "spirit", 1)]),
      ("岩缝里嵌着几块泛光的矿石。", "A few glinting ore chunks sit in the rock crevices.", [("resource", "ore", 2)])])
area("cw_spring", "温泉", "Hot Spring", "山腰的天然温泉，水汽氤氲，弟子们常在此疗伤。", "A natural hot spring on the slope, steaming; disciples come here to mend.",
     [("泡了一会儿温泉，浑身的疲惫都化开了。", "A soak in the spring melts the tiredness out of you.", [("stamina", "stamina", 10)]),
      ("雾气里有人低声说话，你只听到几句便离开了。", "Voices murmur in the steam; you catch a few words and leave.", [("attr", "insight", 1)])])

# ===================================================================== STORY
event("q3_invitation", "fixed", "lj_teahouse",
      [("narr", "茶楼的伙计递来一封烫着松纹的请柬：「苍梧派请各路少年豪杰，赴三年一度的山门比武。」", "A teahouse waiter hands you an invitation stamped with a pine crest: \"Cangwu School invites young talents to its triennial tournament.\""),
       ("narr", "请柬末尾，另有一行小字：「请携半块玉符。」", "At the bottom is a line in small characters: \"Please bring the half tally.\""),
       ("hero", "他们怎么知道我有玉符？我把请柬收进怀里。", "How do they know about the tally? I tuck the invitation away.")],
      [LEAD("cangwu_invite"), SCHED("q3_gate_steps", 1, 6)], title=("苍梧请柬", "The Cangwu Invitation"), window=(31, 44), priority=5, requires={"lead": ["fragment_traced"]},
      on_miss=[LEAD("cangwu_invite"), SCHED("q3_gate_steps", 1, 6)])
event("q3_gate_steps", "fixed", "cw_gate",
      [("gu", "山门前，一位面色严肃的中年人负手而立。「我是顾行舟。苍梧的规矩只有一条：上了山，先学会等。」", "Before the gate a stern man stands with hands behind his back. \"I am Gu Xingzhou. Cangwu has one rule: once you climb, learn first to wait.\""),
       ("gu", "「入门试炼：九百级石阶，一口气走上来，不许借力。」", "\"Admission trial: nine hundred steps in one breath, no help allowed.\"")],
      title=("山门试炼", "The Gate Trial"), scheduled_only=True, priority=5,
      choices=[("steady", "稳住呼吸，一步一阶", "Steady the breath, one step at a time", [SCHED("q3_library", 1, 5), ATTR("spirit", 2), STAMINA(-4), FLAG("gate_steady")]),
               ("swift", "运起轻功，一路冲上", "Rush up with light feet", [SCHED("q3_library", 1, 5), ATTR("agility", 2), STAMINA(-4), FLAG("gate_swift")])],
      on_miss=[SCHED("q3_library", 1, 5)])
event("q3_library", "fixed", "cw_library",
      [("narr", "藏经阁二楼，白砚正伏案抄书，墨汁沾了半只袖子。", "On the library's second floor Bai Yan is bent over a copying desk, one sleeve stained with ink."),
       ("bai", "「啊，你也来了！这里的藏书……比我想象的更全，也更危险。」他压低声音，「有人动过《九曜》相关的卷宗。」", "\"Ah, you came too! The collection is bigger than I imagined, and more dangerous.\" He lowers his voice. \"Someone has tampered with the Nine-Star files.\""),
       ("hero", "我陪他把可疑的卷宗一一记下来。", "I help him list the suspicious files one by one.")],
      [LEAD("library_files"), BOND("bai_yan", 2), ATTR("insight", 1)], title=("藏经阁的旧卷", "Old Scrolls in the Library"), scheduled_only=True, priority=4)
event("q3_xie_wujiu", "fixed", "cw_courts",
      [("narr", "演武场边，一名身披暗红旧袍的青年倚着长枪，冷眼看着场中比试。弟子们经过他时，都下意识绕开。", "At the edge of the courts a young man in a faded dark-red robe leans on a long spear, watching the bouts coldly. Disciples step around him as they pass."),
       ("xie", "「新来的？山门试炼走得不错。」他挑眉，「敢不敢跟我过两招？我可不是来客气的。」", "\"New? You did well on the gate trial.\" He raises an eyebrow. \"Care to trade a few moves? I am not here to be polite.\"")],
      title=("红袍长枪", "The Dark-Red Spear"), window=(35, 45), priority=4,
      choices=[("duel", "应战", "Accept the challenge", [BOND("xie_wujiu", 3), BATTLE("xie_duel"), FLAG("xie_dueled")]),
               ("polite", "婉拒，请教他的名字", "Decline and ask his name", [BOND("xie_wujiu", 3), ATTR("insight", 1)])])
event("arc_xie_wujiu_1", "fixed", "cw_courts",
      [("xie", "「我曾是苍梧最年轻的内门弟子。」谢无咎望着远处的松林，「三年前，藏经阁丢了一件东西，所有人都说，是我拿的。」", "\"I was Cangwu's youngest inner disciple,\" Xie Wujiu says, gazing at the distant pines. \"Three years ago something vanished from the library, and everyone said I took it.\""),
       ("xie", "「我没有。可我找不到证据。」他握紧了枪杆，「你信不信，我不在乎。」", "\"I did not. But I cannot find proof.\" His grip tightens on the shaft. \"Whether you believe me, I do not care.\""),
       ("hero", "我看着他的眼睛：「我信。如果你愿意，我帮你查。」", "I look into his eyes. \"I believe you. If you want, I will help you look.\"")],
      [{"type": "arc_stage", "id": "xie_wujiu", "amount": 1}, LEAD("frame_whisper"), BOND("xie_wujiu", 2)], title=("三年前的冤", "The Wrong of Three Years Ago"),
      window=(35, 100), priority=6, requires={"bond_min": {"xie_wujiu": 4}},
      on_miss=[{"type": "arc_outcome", "id": "xie_wujiu", "value": "lost"}])
event("q3_mid_autumn", "fixed", "cw_spring",
      [("narr", "中秋夜，温泉边的松林里挂满了灯笼，弟子们和客人围坐赏月。", "On Mid-Autumn night lanterns hang in the pines by the spring, disciples and guests sitting round to watch the moon."),
       ("narr", "月亮升得很高，你不知该与谁说话。", "The moon climbs high, and you wonder whom to sit with.")],
      title=("中秋夜", "Mid-Autumn Night"), window=(37, 39), priority=4, requires={"season": [2]},
      choices=[("shen", "去找沈青禾", "Find Shen Qinghe", [BOND("shen_qinghe", 2), STAMINA(6)]),
               ("lu", "去找陆沉舟", "Find Lu Chenzhou", [BOND("lu_chenzhou", 2), STAMINA(6)]),
               ("bai", "去找白砚", "Find Bai Yan", [BOND("bai_yan", 2), STAMINA(6)]),
               ("alone", "独自看月", "Watch the moon alone", [ATTR("spirit", 2), STAMINA(8)])])
event("q3_tournament_1", "fixed", "cw_courts",
      [("gu", "擂台上，顾行舟宣布：「初赛，两人对两人。胜者进入复赛。」", "On the platform Gu Xingzhou announces: \"First round, two against two. Winners advance.\""),
       ("disc", "对面的两名弟子抱拳行礼，眼神却毫不含糊。", "Two disciples across the ring salute, their eyes anything but soft.")],
      [SCHED("q3_tournament_2", 1, 3)], title=("山门比武：初赛", "Tournament: First Round"), window=(39, 43), priority=5, requires={"realm_min": 2},
      choices=[("fight", "上场", "Step into the ring", [SCHED("q3_tournament_2", 1, 3), BATTLE("cw_bout_1")])],
      on_miss=[SCHED("q3_tournament_2", 1, 3)])
event("q3_tournament_2", "fixed", "cw_courts",
      [("gu", "「复赛。三人对三人，鼓声一响，不得停手。」", "\"Second round. Three against three; once the drum sounds, no stopping.\"")],
      title=("山门比武：复赛", "Tournament: Second Round"), scheduled_only=True, priority=5,
      choices=[("fight", "上场", "Step into the ring", [SCHED("q3_tournament_3", 1, 3), BATTLE("cw_bout_2")])],
      on_miss=[SCHED("q3_tournament_3", 1, 3)])
event("q3_tournament_3", "fixed", "cw_courts",
      [("gu", "「决赛。」顾行舟指向场中那位沉默的师兄，「他是苍梧近十年最强的外门弟子。胜负，皆是荣誉。」", "\"The final.\" Gu Xingzhou gestures at the silent senior in the ring. \"The strongest outer disciple in ten years. Win or lose, it is an honour.\"")],
      title=("山门比武：决赛", "Tournament: The Final"), scheduled_only=True, priority=5,
      choices=[("fight", "上场", "Step into the ring", [BATTLE("cw_bout_3")])])
event("q3_theft", "fixed", "cw_library",
      [("narr", "比武刚散，藏经阁里传来惊呼：镇阁的那卷《松风残谱》不见了。", "The tournament has barely ended when a cry rises from the library: the pine-wind score that guards the hall is gone."),
       ("gu", "「谁最后进过阁楼？」弟子们不约而同看向角落里的谢无咎。", "\"Who was last in the loft?\" Every disciple's eyes turn to Xie Wujiu in the corner."),
       ("xie", "「又是我？」他冷笑，「你们倒是从来没换过一句话。」", "\"Me again?\" He sneers. \"You have never once changed your line.\"")],
      [], title=("失窃", "The Theft"), window=(43, 50), priority=6,
      choices=[("public", "当众为他作证", "Stand up for him in public", [FLAG("xie_defended_public"), BOND("xie_wujiu", 4), LEAD("theft_clue")]),
               ("quiet", "私下替他查，不当场出头", "Quietly look into it for him", [FLAG("xie_defended_quiet"), BOND("xie_wujiu", 2), LEAD("theft_clue")]),
               ("stay", "不插手", "Stay out of it", [FLAG("xie_abandoned"), BOND("xie_wujiu", -3)])],
      on_miss=[FLAG("xie_abandoned")])
event("q3_hui_mask", "fixed", "cw_cave",
      [("narr", "断崖洞深处，一个戴着灰色面具的人影背对着你，在石壁前驻足。", "Deep in the cliff cave a figure in a grey mask stands with his back to you before the rock wall."),
       ("hui", "「玉谷的孩子。」他没有回头，「有些事，知道得越少，越安全。回去吧。」", "\"Child of Jade Valley.\" He does not turn. \"The less you know, the safer you are. Go back.\""),
       ("hero", "我想追问，可他像烟一样散进了黑暗。", "I want to press him, but he dissolves into the dark like smoke.")],
      [LEAD("hui_mask_seen"), FLAG("hui_seen"), ATTR("insight", 1)], title=("灰面", "The Grey Mask"), window=(44, 52), priority=5)

RANDOM = [
 ("ry3_gate_pines", "cw_gate", [("narr", "古松下，一位老僧正在扫落叶。他笑着递给你一把竹帚。", "Beneath an old pine a monk sweeps leaves. He smiles and hands you a bamboo broom.")], [ATTR("spirit", 1), STAMINA(4)], ("扫叶", "Sweeping Leaves"), 3, 6),
 ("ry3_courts_spar", "cw_courts", [("disc", "一位弟子邀你陪练：「别手下留情！」", "A disciple invites you to spar: \"Do not hold back!\"")], [ATTR("power", 1), ATTR("agility", 1)], ("陪练", "Sparring Partner"), 3, 5),
 ("ry3_courts_drill", "cw_courts", [("narr", "鼓声里，弟子们列队练「松涛十三式」，你在队尾跟着比划。", "To drumbeats the disciples drill the Thirteen Pine-Wave Forms, and you follow at the tail.")], [ATTR("body", 1)], ("松涛十三式", "Thirteen Pine-Wave Forms"), 3, 8),
 ("ry3_library_read", "cw_library", [("narr", "你找到一卷讲吐纳的旧书，一读就是一个下午。", "You find an old book on breathing and read it through the afternoon.")], [ATTR("insight", 1), ATTR("spirit", 1)], ("吐纳旧书", "A Book on Breath"), 3, 6),
 ("ry3_library_keeper", "cw_library", [("wander", "管阁的老僧低声提醒：「近日阁里，夜里常有脚步声。」", "The old keeper murmurs: \"Lately there are footsteps in the hall at night.\"")], [ATTR("insight", 1), LEAD("library_footsteps")], ("夜里的脚步", "Footsteps at Night"), 2, 10),
 ("ry3_cave_echo", "cw_cave", [("narr", "洞中回声极长，你对着黑暗喊了一声，听着它一层层远去。", "The cave's echo runs long; you call into the dark and listen to it recede.")], [ATTR("spirit", 1)], ("洞中回声", "Echo in the Cave"), 3, 6),
 ("ry3_spring_soak", "cw_spring", [("narr", "泉水温热，你闭上眼，听着远处的松涛。", "The spring is warm; you close your eyes and listen to the pines.")], [STAMINA(10)], ("泉边小憩", "A Rest by the Spring"), 4, 4),
 ("ry3_spring_gossip", "cw_spring", [("wander", "两位师姐边泡边聊：「听说这次比武，掌门另有安排。」", "Two senior sisters chat as they soak: \"They say the master has other plans for this tournament.\"")], [ATTR("insight", 1)], ("泉边闲话", "Talk by the Spring"), 3, 8),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd)

# ===================================================================== BATTLES
units["units"].append({"id": "cangwu_disciple", "stats": {"hp": 50, "body": 7, "power": 9, "agility": 7, "spirit": 5}, "techniques": ["swift_dash"]})
units["units"].append({"id": "cangwu_senior", "stats": {"hp": 120, "body": 11, "power": 14, "agility": 9, "spirit": 9}, "techniques": ["club_smash"]})
L("combat.unit.cangwu_disciple", "苍梧弟子", "Cangwu Disciple"); L("combat.unit.cangwu_senior", "苍梧师兄", "Cangwu Senior")
CELLS = [[[1, 1], [2, 1], [3, 1]], [[4, 1], [5, 1], [4, 0]], [[2, 0], [3, 0], [1, 0]]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=8):
    sc = {"id": id, "battle_id": id, "max_rounds": rounds, "terrain": [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
          "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": CELLS[i % 3]} for i, t in enumerate(enemies)],
          "objective": {"defeat_all": True},
          "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
          "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}}
    scen["scenarios"].append(sc)
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("xie_duel", "红袍切磋", "Duel with the Spear", "击败谢无咎的陪练弟子。", "Defeat the disciple Xie sets against you.", ["cangwu_disciple", "cangwu_disciple"],
         [{"type": "resource", "id": "coins", "amount": 6}], ["xie_duel_won"], ["xie_duel_lost"])
scenario("cw_bout_1", "比武初赛", "Tournament Round One", "击败两名苍梧弟子。", "Defeat the two Cangwu disciples.", ["cangwu_disciple", "cangwu_disciple"],
         [{"type": "resource", "id": "coins", "amount": 8}], ["bout1_won"], ["bout1_lost"])
scenario("cw_bout_2", "比武复赛", "Tournament Round Two", "击败三名苍梧弟子。", "Defeat the three Cangwu disciples.", ["cangwu_disciple", "cangwu_disciple", "cangwu_disciple"],
         [{"type": "resource", "id": "coins", "amount": 12}], ["bout2_won"], ["bout2_lost"])
scenario("cw_bout_3", "比武决赛", "Tournament Final", "击败苍梧师兄。", "Defeat the Cangwu senior.", ["cangwu_senior"],
         [{"type": "resource", "id": "coins", "amount": 20}, {"type": "item", "id": "manual_pine_sutra", "amount": 1}], ["champion"], ["bout3_lost"], 10)

# champion manual
ct["techniques"].append({"id": "pine_strike", "name_key": "technique.pine_strike", "kind": "attack", "range": 2, "damage": 10, "resolve": 5, "cost": 4})
L("technique.pine_strike", "松涛击", "Pine-Wave Strike"); L("manual.pine_sutra", "松涛心经", "Pine-Wave Sutra")
manuals["manuals"].append({"id": "pine_sutra", "item": "manual_pine_sutra", "name_key": "manual.pine_sutra", "technique": "pine_strike", "group": "champion", "realm_min": 2})

# ===================================================================== XIE WUJIU
def tech(id, fields, zn, en_, dz, de):
    t = {"id": id, "name_key": "ability." + id}; t.update(fields); ct["techniques"].append(t)
    L("ability." + id, zn, en_); L("ability." + id + ".desc", dz, de)
tech("spear_sweep", dict(kind="attack", range=2, damage=6, resolve=4, push=1, cost=1), "横枪扫", "Spear Sweep", "长枪横扫，把敌人击退一格。", "A sweeping spear that knocks the enemy back.")
tech("proud_stance", dict(kind="attack", range=1, damage=9, resolve=5, cost=2), "傲骨一击", "Proud Strike", "毫不留情的近身重击。", "A merciless close strike.")
tech("spear_oath", dict(kind="attack", range=2, damage=6, resolve=4, free=True, once=True, bond=True, cost=0), "枪誓", "Spear Oath", "羁绊技（每场一次，不耗行动）：射程2内追加一记攻击。", "Bond ability (once per battle, no action): an extra strike within range 2.")
t = {"id": "duo_spear_wind", "name_key": "technique.duo_spear_wind", "duo": "xie_wujiu", "kind": "attack", "range": 2, "damage": 9, "resolve": 5, "cost": 3}
ct["techniques"].append(t); L("technique.duo_spear_wind", "枪风合击", "Spear and Wind")
duos["duos"].append({"id": "duo_spear_wind", "companion": "xie_wujiu", "tech": "duo_spear_wind", "bond_min": 12})
comps["companions"].append({"id": "xie_wujiu", "name_key": "npc.xie_wujiu", "bio_key": "companion.xie_wujiu.bio", "portrait": "portrait_xie_wujiu", "role": "striker",
    "stats": {"body": 6, "power": 9, "agility": 6, "insight": 5, "spirit": 4}, "preferred_activities": ["training", "technique_practice", "meditation"],
    "recruit": {"score_min": 8, "attr_min": {"power": 8}, "flags_block": [], "week_min": 46}, "depart": {"score_below": 0, "flags": ["xie_abandoned", "xie_wujiu_betrayed"]},
    "battle_abilities": ["spear_sweep", "proud_stance"], "relationship_ability": "spear_oath", "meet_week": 35})
L("companion.xie_wujiu.bio", "被逐出苍梧的天才弟子，长枪凌厉，外冷内热。", "A prodigy cast out of Cangwu, sharp with the spear, cold outside and warm within.")
for lid, g, hair, hh, oh, sh, wp in [("xie_wujiu", "m", 1, "1c1414", "8a2a2a", "d8b090", "staff"), ("master_gu", "m", 2, "3a3a3a", "3a4a5a", "d8b898", ""), ("mask_hui", "m", 0, "6a6a70", "5a5a62", "d8b898", "")]:
    looks["looks"].append({"id": lid, "gender": g, "hair": hair, "hair_hex": hh, "outfit_hex": oh, "skin_hex": sh, "weapon": wp})
arcs["arcs"].append({"companion": "xie_wujiu", "planned": 4, "stages": [{"id": "1", "event": "arc_xie_wujiu_1"}], "outcomes": ["redeemed", "alternate", "lost"], "bonds": ["friend", "sworn", "romance", "rival"]})

LEADS = {"cangwu_invite": ("苍梧请柬", "The Cangwu Invitation", "苍梧派邀你参加山门比武，并要你带上半块玉符。", "Cangwu School invites you to its tournament and asks for the half tally."),
         "library_files": ("被动过的卷宗", "Tampered Files", "藏经阁里有人动过与「九曜」有关的卷宗。", "Someone has tampered with the Nine-Star files in the library."),
         "frame_whisper": ("谢无咎的冤屈", "Xie Wujiu's Wrong", "三年前藏经阁失窃，谢无咎被指为窃贼，他说那是冤枉。", "A theft three years ago was pinned on Xie Wujiu; he says he is innocent."),
         "theft_clue": ("松风残谱失窃", "The Stolen Pine Score", "镇阁的《松风残谱》再度失窃，谢无咎又成了嫌疑人。", "The pine-wind score is stolen again, and Xie Wujiu is the suspect once more."),
         "hui_mask_seen": ("灰面人", "The Grey Mask", "断崖洞里有个戴灰面具的人，知道你来自玉谷。", "A grey-masked man in the cliff cave knows you come from Jade Valley."),
         "library_footsteps": ("阁中的脚步声", "Footsteps in the Library", "藏经阁夜里常有脚步声，也许与失窃有关。", "Footsteps sound in the library at night, perhaps connected to the theft.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("combat/scenarios.json", scen); dump("combat/units.json", units); dump("companions/companions.json", comps)
dump("story/looks.json", looks); dump("combat/combat_techniques.json", ct); dump("combat/duo.json", duos); dump("companions/arcs.json", arcs)
dump("cultivation/manuals.json", manuals)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events", len(areas["areas"]), "areas", len(comps["companions"]), "companions")
