#!/usr/bin/env python3
"""M22a/b: Year 1, quarters 1 and 2 (valley completion and Linjiang). Run AFTER gen_world, gen_arts, gen_arcs.
Idempotent: removes its own ids first, then appends areas, events, dialogues, battles, companions, looks and text."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); comps = load("companions/companions.json")
looks = load("story/looks.json"); ct = load("combat/combat_techniques.json"); duos = load("combat/duo.json"); arcs = load("companions/arcs.json")

OWN_AREAS = ["bamboo_pass", "lj_docks", "lj_market", "lj_teahouse", "lj_escort", "lj_pawn", "lj_alleys"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
EV_PREFIX = ("q1_", "q2_", "ry1_", "arc_su_dai_", "arc_li_shan_")
events["events"] = [e for e in events["events"] if not e["id"].startswith(EV_PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(EV_PREFIX)]
NEW_SC = ["masked_escort", "dock_scam", "caravan_escort", "guild_night"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
NEW_UNITS = ["masked_guard", "dock_thug", "guild_enforcer"]
units["units"] = [u for u in units["units"] if u["id"] not in NEW_UNITS]
NEW_COMP = ["su_dai", "li_shan"]
comps["companions"] = [c for c in comps["companions"] if c["id"] not in NEW_COMP]
looks["looks"] = [l for l in looks["looks"] if l["id"] not in ["su_dai", "li_shan", "qian_man", "guild_master", "masked_rider"]]
NEW_TECH = ["soothing_tune", "bell_strike", "pipa_crescendo", "hammer_blow", "iron_taunt", "forge_oath", "duo_pipa_duet", "duo_hammer_anvil"]
ct["techniques"] = [t for t in ct["techniques"] if t["id"] not in NEW_TECH]
duos["duos"] = [d for d in duos["duos"] if d["companion"] not in NEW_COMP]
arcs["arcs"] = [a for a in arcs["arcs"] if a["companion"] not in NEW_COMP]

# ---- the spring fair belongs to month 2 (weeks 6 to 10)
for e in events["events"]:
    if e["id"] == "f_spring_fair":
        e["window"] = {"from": 6, "to": 10}

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "elder": "story.speaker.elder", "wander": "world.speaker.wanderer",
       "su": "npc.su_dai", "li": "npc.li_shan", "qian": "npc.qian_man", "boss": "npc.guild_master", "rider": "npc.masked_rider",
       "lu": "npc.lu_chenzhou", "shen": "npc.shen_qinghe", "bai": "npc.bai_yan"}
WHO = {"elder": "elder", "wander": "wanderer", "su": "su_dai", "li": "li_shan", "qian": "qian_man", "boss": "guild_master", "rider": "masked_rider",
       "lu": "lu_chenzhou", "shen": "shen_qinghe", "bai": "bai_yan"}
L("npc.su_dai", "苏黛", "Su Dai"); L("npc.li_shan", "厉山", "Li Shan"); L("npc.qian_man", "钱满", "Qian Man")
L("npc.guild_master", "漕帮帮主", "Barge Guild Master"); L("npc.masked_rider", "蒙面骑手", "Masked Rider")

REGION = {"bamboo_pass": "jade_valley"}
BG = {"valley_village": "valley_day", "bamboo_pass": "bamboo_mist", "river_bend": "riverside_day", "lj_docks": "city_docks", "lj_market": "city_market",
      "lj_teahouse": "city_market", "lj_escort": "city_market", "lj_pawn": "city_market", "lj_alleys": "city_night"}
ATTR = lambda i, n=1: {"type": "attr", "id": i, "amount": n}
RES = lambda i, n: {"type": "resource", "id": i, "amount": n}
FLAG = lambda i: {"type": "flag", "id": i}
LEAD = lambda i: {"type": "lead", "id": i}
SCHED = lambda i, a, b: {"type": "schedule", "id": i, "min": a, "max": b}
BOND = lambda c, n: {"type": "bond", "id": c, "amount": n}
STAMINA = lambda n: {"type": "stamina", "id": "stamina", "amount": n}
BATTLE = lambda i: {"type": "battle", "id": i}

def area(id, zn, en_, dz, de, wanders, **kw):
    a = {"id": id, "region": kw.pop("region", "linjiang"), "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": kw.pop("cost", 2), "wander": []}
    L(a["name_key"], zn, en_); L(a["desc_key"], dz, de)
    for i, (z, e, rw) in enumerate(wanders):
        k = f"world.area.{id}.w{i+1}"; L(k, z, e); a["wander"].append({"text_key": k, "rewards": [{"type": t, "id": r, "amount": n} for t, r, n in rw]})
    a.update(kw); areas["areas"].append(a)

def event(id, kind, area_id, lines, effects_end=None, choices=None, title=None, window=None, who_extra=None, **kw):
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

# =====================================================================================================
# AREAS
area("bamboo_pass", "竹径关", "Bamboo Pass", "出谷的唯一山路，两侧青竹成海。", "The one road out of the valley, bamboo rising on both sides.",
     [("竹叶沙沙，你在路上随手练了几趟步法。", "Leaves whisper as you drill a few footwork patterns along the road.", [("attr", "agility", 1)]),
      ("砍竹的老汉塞给你两个热饼。", "A bamboo cutter presses two hot flatbreads into your hands.", [("resource", "food", 2)])],
     region="jade_valley", cost=1, open_default=True, requires={"week_min": 10})
LJ = {"open_default": True, "requires": {"lead": ["linjiang_token"], "week_min": 16}}
area("lj_docks", "临江码头", "Linjiang Docks", "桅杆如林，号子声从清早响到深夜。", "A forest of masts; chanting rises from dawn to midnight.",
     [("你帮着搬了几箱货，工头抛来一把铜钱。", "You haul a few crates and the foreman tosses you a handful of coins.", [("resource", "coins", 10)]),
      ("码头边的老船工教你认水纹，你看出些门道。", "An old boatman teaches you to read ripples, and you pick up the trick.", [("attr", "insight", 1)])], **LJ)
area("lj_market", "临江集市", "Linjiang Market", "吆喝声、香气与铜铃，一条街塞得满满当当。", "Shouts, aromas and bells packed into a single street.",
     [("摊主送了你一块糖糕，说这是「路过的福气」。", "A stallkeeper gives you a honey cake: \"luck of the passerby.\"", [("stamina", "stamina", 6)]),
      ("你帮着看了半天摊子，换到几个铜板。", "You mind a stall for an afternoon and earn a few coppers.", [("resource", "coins", 8)])], **LJ)
area("lj_teahouse", "清心茶楼", "Clear-Heart Teahouse", "二楼雅座常有各路人物，一壶茶能听一天的风声。", "The upstairs seats hold all sorts; one pot of tea buys a day of rumours.",
     [("邻桌的说书人讲到精彩处，你不觉入了神。", "The storyteller at the next table reaches the good part and you lose yourself in it.", [("attr", "insight", 1)]),
      ("掌柜请你尝了一盏新茶。", "The owner lets you taste a new tea.", [("stamina", "stamina", 5)])], **LJ)
area("lj_escort", "平远镖局", "Pingyuan Escort Bureau", "门口立着一对石狮，院内常有人练拳。", "A pair of stone lions guard the gate; someone is always drilling inside.",
     [("镖师们让你陪练了几招。", "The escorts let you spar a few rounds.", [("attr", "power", 1)]),
      ("账房托你送封信，赏了几文钱。", "The bookkeeper asks you to carry a letter and tips you a few coins.", [("resource", "coins", 8)])], **LJ)
area("lj_pawn", "万宝当铺", "Ten-Thousand-Treasures Pawnshop", "柜台高得过人，掌柜的眼睛比秤还准。", "The counter is taller than a man and the keeper's eye truer than his scales.",
     [("你在角落的旧箱里翻出些能用的矿石。", "You find some usable ore in an old crate in a corner.", [("resource", "ore", 2)]),
      ("掌柜闲聊间提到几条江湖旧闻。", "In idle talk the keeper mentions a few old rumours of the martial world.", [("attr", "insight", 1)])], **LJ)
area("lj_alleys", "夜巷", "Night Alleys", "白天无人，入夜才有灯。", "Empty by day; lamps only after dark.",
     [("你躲在暗处看了一场赌局，学到几分察言观色。", "You watch a gambling game from the shadows and learn to read faces.", [("attr", "insight", 1)]),
      ("巷口的野猫引你绕过了一队巡夜人。", "A stray cat leads you around a night patrol.", [("attr", "agility", 1)])], **LJ)

# =====================================================================================================
# Q1: weeks 11 to 18 in the valley
event("q1_tally", "fixed", "valley_village",
      [("narr", "夜里，墨长老把炉火拨旺，从箱底取出一块只有半边的玉符，放进你掌心。", "That night Elder Mo stokes the fire and takes a half-cut jade tally from the bottom of a chest, laying it in your palm."),
       ("elder", "「这是你被抱来那天，裹在襁褓里的东西。另一半在哪，我不知道。可袭击玉谷的人，找的就是它。」", "\"This was wrapped in your blanket the day you were brought here. Where the other half lies I do not know. But the men who raided the valley were looking for it.\""),
       ("elder", "「玉谷曾是『第九家』。这件事，我替你藏了一辈子。」", "\"Jade Valley was once the 'ninth house'. I have kept that secret for you all my life.\"")],
      title=("半块玉符", "Half a Tally"), window=(11, 15), requires={"week_min": 11}, priority=5,
      choices=[("ask", "收好玉符，追问「第九家」", "Keep the tally and ask about the 'ninth house'", [FLAG("tally_known"), ATTR("insight", 2), SCHED("q1_bamboo", 1, 6)]),
               ("rest", "先收起来，改日再问", "Put it away; ask another day", [FLAG("tally_known"), ATTR("spirit", 2), SCHED("q1_bamboo", 1, 6)])],
      on_miss=[FLAG("tally_known"), SCHED("q1_bamboo", 1, 6)])
event("q1_bamboo", "fixed", "bamboo_pass",
      [("narr", "竹径尽头，一名蒙面骑手勒住马，身后跟着两名护卫。他腰间挂着一块漕帮的木牌。", "At the end of the bamboo road a masked rider reins in, two guards behind him. A Barge Guild wooden token hangs at his belt."),
       ("rider", "「玉谷的小子，把那半块玉符留下，今天就当没见过你。」", "\"Valley kid, leave the half tally and we will call today a day we never met.\"")],
      title=("竹径拦路", "Ambush on the Bamboo Road"), scheduled_only=True, priority=5, requires={"flags_all": ["tally_known"]},
      choices=[("fight", "拔剑迎战", "Draw and fight", [LEAD("linjiang_token"), FLAG("escort_fought"), BATTLE("masked_escort")]),
               ("follow", "假意示弱，暗中跟着他们", "Feign weakness and follow them", [LEAD("linjiang_token"), ATTR("agility", 1), ATTR("insight", 1)])],
      on_miss=[LEAD("linjiang_token")])
# a few random scenes for the valley
event("ry1_bamboo_mist", "random", "bamboo_pass",
      [("narr", "晨雾锁住竹径，你索性在雾里练了一趟拳，出来时衣襟已湿。", "Morning mist seals the bamboo road, so you drill a set of forms in it and come out with a damp collar.")],
      [ATTR("spirit", 1), ATTR("power", 1)], title=("竹间晨练", "Morning in the Bamboo"), weight=3, cooldown=6)
event("ry1_bamboo_cutter", "random", "bamboo_pass",
      [("wander", "砍竹的老汉擦着汗：「近来路上多了不少生面孔，你可留心些。」", "The bamboo cutter wipes his brow: \"Plenty of strangers on the road lately. Keep your eyes open.\"")],
      [RES("food", 2), ATTR("insight", 1)], title=("砍竹老汉", "The Bamboo Cutter"), weight=3, cooldown=6)
event("ry1_bend_heron", "random", "river_bend",
      [("narr", "一只白鹭立在浅滩，一动不动。你看了很久，竟悟出几分「静」字。", "A heron stands motionless in the shallows. You watch it so long that you glimpse something of stillness.")],
      [ATTR("spirit", 1)], title=("浅滩白鹭", "Heron in the Shallows"), weight=3, cooldown=8)

# =====================================================================================================
# Q2: Linjiang, weeks 16 to 45
event("q2_arrival", "fixed", "lj_docks",
      [("narr", "临江的码头比你想象的大十倍。你刚下船，就被一名自称「向导」的汉子拦住。", "Linjiang's docks are ten times bigger than you imagined. You have barely stepped off the boat when a self-styled 'guide' blocks the way."),
       ("wander", "「外乡人，进城先交『平安钱』。三两银子，保你一路无事。」", "\"Outsider, the 'safe-passage fee' first. Three taels and nothing happens to you.\"")],
      title=("初到临江", "First Steps in Linjiang"), window=(16, 24), priority=5,
      choices=[("pay", "给钱了事", "Pay and move on", [RES("coins", -6), SCHED("q2_qian_man", 1, 6), FLAG("dock_paid")]),
               ("fight", "不吃这一套", "Refuse and fight", [SCHED("q2_qian_man", 1, 6), FLAG("dock_fought"), BATTLE("dock_scam")]),
               ("wit", "拉着他理论，引来巡丁", "Argue loudly until the watch comes", [SCHED("q2_qian_man", 1, 6), ATTR("insight", 1), FLAG("dock_outwitted")])],
      on_miss=[SCHED("q2_qian_man", 1, 6)])
event("q2_qian_man", "fixed", "lj_pawn",
      [("qian", "柜台后的钱满头也不抬：「玉谷来的？带着半块玉的那位？」", "Behind the counter Qian Man does not look up: \"From Jade Valley? The one with half a jade?\""),
       ("hero", "我心里一紧：「你怎么知道？」", "My stomach tightens. \"How do you know?\""),
       ("qian", "「临江城里，没有我不知道的事，只有我不想卖的价钱。镖局最近缺人，你去看看，兴许能打听到你要的消息。」", "\"In Linjiang there is nothing I do not know, only prices I do not care to sell at. The escort bureau is short of hands. Go there; you may hear what you want.\"")],
      [LEAD("escort_job"), SCHED("q2_escort", 1, 8), ATTR("insight", 1)], title=("钱满的柜台", "Qian Man's Counter"), scheduled_only=True, priority=5,
      on_miss=[SCHED("q2_escort", 1, 8)])
event("q2_su_dai", "fixed", "lj_market",
      [("narr", "集市拐角围了一圈人。一名背琵琶的姑娘边弹边唱，铃铛随着节拍叮当作响。", "A crowd circles a corner of the market. A girl with a pipa on her back plays and sings, bells chiming with the beat."),
       ("su", "「这位客官，听了我的曲子，不留个赏钱，也留个名字吧？」", "\"You there, you have listened to my song. If not a tip then at least leave a name?\""),
       ("hero", "我报了名字，她笑得眼睛弯弯：「我叫苏黛。下次来，给你唱新的。」", "I give my name, and her eyes crinkle with her smile. \"I am Su Dai. Next time I will sing you a new one.\"")],
      [BOND("su_dai", 3), RES("coins", 3)], title=("集市琵琶", "Pipa at the Market"), window=(18, 30), priority=4)
event("arc_su_dai_1", "fixed", "lj_market",
      [("su", "「这首曲子，是我娘留下的。」苏黛压低了声音，「可我总觉得，歌词里藏着别的东西。」", "\"My mother left me this song,\" Su Dai says quietly. \"But I keep feeling the words hide something else.\""),
       ("su", "「你听——『三更过桥，逆水寻星』。哪有人唱曲子，唱得这么具体的？」", "\"Listen: 'Cross the bridge at the third watch, seek the star against the current.' Who sings a song that specific?\""),
       ("hero", "我想起玉符与「九曜」，心头一动：「也许，它是一张图。」", "I think of the tally and the Nine Stars and feel a stir. \"Perhaps it is a map.\"")],
      [{"type": "arc_stage", "id": "su_dai", "amount": 1}, LEAD("song_map"), BOND("su_dai", 2)], title=("藏图的曲子", "The Song That Hides a Map"),
      window=(18, 100), priority=6, requires={"bond_min": {"su_dai": 4}},
      on_miss=[{"type": "arc_outcome", "id": "su_dai", "value": "lost"}])
event("q2_dragon_boat", "fixed", "lj_docks",
      [("narr", "端阳到了，江面上鼓声震天，龙舟一字排开，两岸挤满了人。", "The Dragon-Boat Festival has come: drums thunder over the river, the long boats line up, and both banks are packed."),
       ("wander", "「差一个桨手！谁来？赢了彩头，大家分！」", "\"One paddler short! Who will join? Win the prize and we all share!\"")],
      title=("端阳龙舟", "Dragon-Boat Day"), window=(21, 25), priority=4, requires={"season": [1]},
      choices=[("race", "上船划桨", "Take a paddle", [ATTR("power", 1), ATTR("agility", 1), RES("coins", 20)]),
               ("watch", "在岸边看，顺手买些吃的", "Watch from the bank and buy snacks", [ATTR("spirit", 1), RES("food", 3), STAMINA(8)])])
event("q2_li_shan", "fixed", "lj_docks",
      [("narr", "码头尽头有一间烧黑的铁匠铺，只剩半截炉子。一个高大的汉子正蹲在灰烬里翻找什么。", "At the end of the docks stands a blackened smithy, only half a furnace left. A huge man crouches in the ashes, searching."),
       ("li", "「这里……不卖东西了。」他抬头，声音很低，「炉子，被人烧了。」", "\"Nothing... sold here any more.\" He looks up, voice low. \"Somebody burned the forge.\""),
       ("hero", "我蹲下来，帮他一起扒开瓦砾。", "I crouch and help him dig through the rubble.")],
      [BOND("li_shan", 3), ATTR("power", 1)], title=("烧毁的铁匠铺", "The Burned Smithy"), window=(22, 34), priority=4)
event("arc_li_shan_1", "fixed", "lj_docks",
      [("li", "「这铁，不是自己烧坏的。」厉山捏起一块发白的铁渣，「有人往炉里倒了油，要的是烧掉账本，和那批矿。」", "\"This iron did not burn by itself,\" Li Shan says, pinching a pale slag. \"Someone poured oil in the furnace. They wanted the ledger burned, and the ore.\""),
       ("li", "「我想把炉子再生起来。需要矿，也需要……一个肯帮我的人。」", "\"I want to light this furnace again. I need ore, and... someone willing to help.\"")],
      title=("再生炉火", "Lighting the Furnace Again"), window=(22, 100), priority=6, requires={"bond_min": {"li_shan": 4}},
      choices=[("sift", "和他一起筛灰、找旧账", "Help him sift ashes for the ledger", [{"type": "arc_stage", "id": "li_shan", "amount": 1}, LEAD("burned_forge"), BOND("li_shan", 3), ATTR("body", 1)]),
               ("ore", "留下几块矿石和一句承诺", "Leave some ore and a promise", [{"type": "arc_stage", "id": "li_shan", "amount": 1}, LEAD("burned_forge"), BOND("li_shan", 2), RES("ore", -2)])],
      on_miss=[{"type": "arc_outcome", "id": "li_shan", "value": "lost"}])
event("q2_escort", "fixed", "lj_escort",
      [("narr", "平远镖局的总镖头拍了拍你的肩：「小兄弟，有一批货要走北边的商道，路上不太平，你可愿同行？」", "The head of Pingyuan Escort Bureau claps your shoulder: \"Friend, a consignment goes north along the trade road. It is not safe. Will you ride along?\""),
       ("narr", "商道走到一半，林子里窜出几个人影。", "Halfway along the road, figures leap out of the trees.")],
      [LEAD("barge_trail"), SCHED("q2_barge_guild", 2, 8)], title=("护镖北上", "Escort North"), scheduled_only=True, priority=5,
      choices=[("fight", "守住镖车，迎战", "Hold the cart and fight", [LEAD("barge_trail"), SCHED("q2_barge_guild", 2, 8), BATTLE("caravan_escort"), RES("coins", 12)]),
               ("detour", "绕小路护送，避开冲突", "Take a back path and avoid the clash", [LEAD("barge_trail"), SCHED("q2_barge_guild", 2, 8), ATTR("agility", 1), RES("coins", 6)])],
      on_miss=[LEAD("barge_trail"), SCHED("q2_barge_guild", 2, 8)])
event("q2_barge_guild", "fixed", "lj_alleys",
      [("narr", "镖车上的货箱底下，刻着一个小小的船锚——漕帮的暗记。", "Beneath the cargo crates a tiny anchor is carved: the Barge Guild's mark."),
       ("narr", "你顺着暗记摸进夜巷深处，一间不起眼的货栈门缝里漏出灯光。", "You follow the mark into the deep alleys. Lamplight leaks from the door of an unremarkable warehouse.")],
      title=("夜巷货栈", "The Alley Warehouse"), scheduled_only=True, priority=5, requires={"lead": ["barge_trail"]},
      choices=[("sneak", "潜入货栈，查看账册", "Sneak in and read the ledgers", [LEAD("fragment_one"), SCHED("q2_fragment", 1, 8), ATTR("insight", 2), FLAG("guild_sneaked")]),
               ("fight", "闯进去，逼人开口", "Burst in and force answers", [LEAD("fragment_one"), SCHED("q2_fragment", 1, 8), BATTLE("guild_night"), FLAG("guild_fought")])],
      on_miss=[LEAD("fragment_one"), SCHED("q2_fragment", 1, 8)])
event("q2_fragment", "fixed", "lj_docks",
      [("boss", "漕帮帮主坐在船头，慢悠悠地摩挲着一块暗色的石片。「听说，你在找这个。」", "The Barge Guild master sits in a prow, slowly rubbing a dark stone shard. \"I hear you are looking for this.\""),
       ("boss", "「它是『九曜』的第一枚碎片。我可以借你看，条件是——从今往后，漕帮的船，你要护着。」", "\"It is the first fragment of the Nine Stars. I can let you study it, on one condition: from now on you protect the guild's boats.\"")],
      title=("第一枚星辰", "The First Star"), scheduled_only=True, priority=6, requires={"lead": ["fragment_one"]},
      choices=[("ally", "答应，借他之力", "Agree, and borrow his strength", [FLAG("guild_ally"), LEAD("fragment_traced"), ATTR("insight", 2)]),
               ("refuse", "婉拒，自己想办法", "Decline, and find your own way", [FLAG("guild_refused"), LEAD("fragment_traced"), ATTR("spirit", 2)])],
      on_miss=[FLAG("guild_refused"), LEAD("fragment_traced")])

# random scenes, one per city area plus extras
RANDOM = [
 ("ry1_dock_porter", "lj_docks", [("wander", "搬运工笑着塞给你一碗热汤：「新来的？多歇歇，临江的活儿干不完。」", "A porter hands you a bowl of hot soup with a grin: \"New here? Rest up, Linjiang's work never ends.\"")], [STAMINA(8), RES("food", 1)], ("码头热汤", "Soup on the Dock"), 3, 5, {}),
 ("ry1_dock_fisher", "lj_docks", [("narr", "老渔夫在栈桥垂钓，教你如何看水线、找鱼窝。", "An old fisherman by the pier teaches you to read the waterline and find the fish.")], [ATTR("agility", 1), RES("food", 2)], ("栈桥垂钓", "Fishing off the Pier"), 3, 6, {}),
 ("ry1_market_haggle", "lj_market", [("wander", "你帮一位老妇讨价还价，省下的钱，她分了你一半。", "You bargain on behalf of an old woman, and she shares half the savings with you.")], [RES("coins", 10), ATTR("insight", 1)], ("集市还价", "Haggling"), 3, 5, {}),
 ("ry1_market_acrobat", "lj_market", [("narr", "街头艺人在绳上翻腾，你看得入神，悟到几分重心之理。", "Street acrobats tumble on a rope; you watch, and glimpse something about balance.")], [ATTR("agility", 1)], ("绳上翻腾", "Tumblers on a Rope"), 3, 6, {}),
 ("ry1_tea_gossip", "lj_teahouse", [("wander", "邻桌的人在谈论近来各门派的动静，你默默听了半个时辰。", "People at the next table chat about the sects' recent moves; you listen quietly for half an hour.")], [ATTR("insight", 1), LEAD("tea_rumor")], ("茶楼闲话", "Teahouse Talk"), 3, 8, {}),
 ("ry1_escort_drill", "lj_escort", [("narr", "镖师们正在练「三才阵」，你被拉进去凑了一个角。", "The escorts are drilling the 'Three Talents' formation and pull you in to fill a corner.")], [ATTR("power", 1), ATTR("body", 1)], ("镖师操练", "Escort Drill"), 3, 6, {}),
 ("ry1_pawn_curio", "lj_pawn", [("qian", "钱满懒懒地推过来一块小铁片：「当个玩意儿，不收钱。」", "Qian Man lazily pushes over a small iron plate: \"A trinket. No charge.\"")], [RES("ore", 2)], ("柜台上的小玩意", "A Trinket on the Counter"), 2, 8, {}),
 ("ry1_alley_cat", "lj_alleys", [("narr", "夜巷里，一只野猫领着你避开了几个醉汉。", "In the night alleys a stray cat leads you around a few drunks.")], [ATTR("agility", 1), ATTR("insight", 1)], ("巷中野猫", "The Alley Cat"), 2, 8, {}),
]
for id, ar, lines, eff, title, wt, cd, kw in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, **kw)

# =====================================================================================================
# BATTLES
for uid, hp, body, power, agi, spi, techs, zn, en_ in [
    ("masked_guard", 26, 4, 6, 5, 5, ["swift_dash"], "蒙面护卫", "Masked Guard"),
    ("dock_thug", 24, 5, 5, 3, 3, ["club_smash"], "码头打手", "Dock Thug"),
    ("guild_enforcer", 38, 6, 7, 4, 5, ["club_smash"], "漕帮打手", "Guild Enforcer")]:
    units["units"].append({"id": uid, "stats": {"hp": hp, "body": body, "power": power, "agility": agi, "spirit": spi}, "techniques": techs})
    L("combat.unit." + uid, zn, en_)
CELLS = [[[1, 1], [2, 1], [3, 1]], [[4, 1], [5, 1], [4, 0]], [[2, 0], [3, 0], [1, 0]]]
def scenario(id, zn, en_, oz, oe, enemies, win_rewards, flags_w, flags_l, rounds=8):
    sc = {"id": id, "battle_id": id, "max_rounds": rounds, "terrain": [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
          "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": CELLS[i % 3]} for i, t in enumerate(enemies)],
          "objective": {"defeat_all": True},
          "on_victory": {"rewards": win_rewards + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": flags_w},
          "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": flags_l}}
    scen["scenarios"].append(sc)
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("masked_escort", "竹径拦截", "Bamboo Road Ambush", "击败蒙面护卫。", "Defeat the masked guards.", ["masked_guard", "masked_guard", "bandit_archer"],
         [{"type": "resource", "id": "coins", "amount": 10}], ["escort_beaten"], ["escort_won"])
scenario("dock_scam", "码头讹钱", "Dock Shakedown", "击败码头打手。", "Defeat the dock thugs.", ["dock_thug", "dock_thug", "dock_thug"],
         [{"type": "resource", "id": "coins", "amount": 6}], ["dock_beaten"], ["dock_lost"])
scenario("caravan_escort", "商道遭袭", "Caravan Road Raid", "击败拦路的山匪。", "Defeat the road bandits.", ["bandit_scout", "bandit_brute", "bandit_archer", "bandit_archer"],
         [{"type": "resource", "id": "coins", "amount": 8}], ["caravan_saved"], ["caravan_lost"])
scenario("guild_night", "夜巷货栈", "Warehouse by Night", "击败漕帮打手。", "Defeat the guild enforcers.", ["guild_enforcer", "dock_thug", "dock_thug"],
         [{"type": "resource", "id": "ore", "amount": 3}], ["guild_beaten"], ["guild_won"], 9)

# =====================================================================================================
# COMPANIONS: Su Dai, Li Shan
def tech(id, kind_fields, zn, en_, dz, de):
    t = {"id": id, "name_key": "ability." + id}; t.update(kind_fields); ct["techniques"].append(t)
    L("ability." + id, zn, en_); L("ability." + id + ".desc", dz, de)
tech("soothing_tune", dict(kind="support", range=3, resolve_restore=6, cost=1), "安心曲", "Soothing Tune", "弹一支曲子，为友军恢复决心。", "A tune that restores an ally's resolve.")
tech("bell_strike", dict(kind="attack", range=2, damage=3, resolve=4, status={"id": "weaken", "turns": 2}, cost=1), "铃音震", "Bell Strike", "铃声震乱敌人心神，使其虚弱。", "Bells that rattle the enemy and weaken them.")
tech("pipa_crescendo", dict(kind="support", range=3, heal=8, resolve_restore=8, free=True, once=True, bond=True, cost=0), "琵琶激昂", "Pipa Crescendo", "羁绊技（每场一次，不耗行动）：为射程3内的同伴恢复8点生命和决心。", "Bond ability (once per battle, no action): restores 8 HP and resolve to an ally within range 3.")
tech("hammer_blow", dict(kind="attack", range=1, damage=8, resolve=6, push=1, cost=2), "重锤", "Heavy Hammer", "一记沉重的锤击，把敌人击退一格。", "A heavy blow that knocks the enemy back a cell.")
tech("iron_taunt", dict(kind="attack", range=2, damage=1, resolve=5, status={"id": "weaken", "turns": 2}, cost=1), "铁壁挑衅", "Iron Taunt", "用气势压住敌人，使其虚弱。", "Presence that weighs on the enemy and weakens them.")
tech("forge_oath", dict(kind="support", range=2, heal=12, resolve_restore=6, free=True, once=True, bond=True, cost=0), "炉火之誓", "Forge Oath", "羁绊技（每场一次，不耗行动）：为射程2内的同伴恢复12点生命和6点决心。", "Bond ability (once per battle, no action): restores 12 HP and 6 resolve to an ally within range 2.")
for tid, comp, zn, en_, d in [("duo_pipa_duet", "su_dai", "琴剑合鸣", "Strings and Blade in Concert", dict(kind="attack", range=3, damage=6, resolve=6, cost=3)),
                              ("duo_hammer_anvil", "li_shan", "锤砧合击", "Hammer and Anvil", dict(kind="attack", range=1, damage=10, resolve=5, push=2, cost=3))]:
    t = {"id": tid, "name_key": "technique." + tid, "duo": comp}; t.update(d); ct["techniques"].append(t)
    L("technique." + tid, zn, en_)
    duos["duos"].append({"id": tid, "companion": comp, "tech": tid, "bond_min": 12})
def companion(id, role, stats, prefs, meet, week_min, score_min, attr_min, abilities, bond_ability, bio_z, bio_e):
    comps["companions"].append({"id": id, "name_key": "npc." + id, "bio_key": f"companion.{id}.bio", "portrait": "portrait_" + id, "role": role, "stats": stats,
        "preferred_activities": prefs, "recruit": {"score_min": score_min, "attr_min": attr_min, "flags_block": [], "week_min": week_min},
        "depart": {"score_below": 0, "flags": [f"{id}_betrayed"]}, "battle_abilities": abilities, "relationship_ability": bond_ability, "meet_week": meet})
    L(f"companion.{id}.bio", bio_z, bio_e)
companion("su_dai", "support", {"body": 4, "power": 3, "agility": 6, "insight": 7, "spirit": 8}, ["music", "social_visit", "cooking"], 18, 25, 6, {"spirit": 6},
          ["soothing_tune", "bell_strike"], "pipa_crescendo", "街头乐师，琵琶为伴，擅长以曲相助。爱热闹，也爱听故事。", "A street musician with a pipa on her back who helps through song. Loves a crowd and a good story.")
companion("li_shan", "control", {"body": 8, "power": 7, "agility": 3, "insight": 4, "spirit": 6}, ["mining", "training", "cooking"], 22, 28, 6, {"body": 7},
          ["hammer_blow", "iron_taunt"], "forge_oath", "沉默的铁匠，力大如牛，守护同伴。炉火是他唯一的话题。", "A quiet smith, strong as an ox, who shields his friends. The forge is his one subject.")
for lid, g, hair, hh, oh, sh, wp in [("su_dai", "f", 2, "2b3a4a", "4fb5a8", "f0d8c0", "fan"), ("li_shan", "m", 3, "1c1c1c", "5a4a42", "c89a78", "staff"),
                                    ("qian_man", "m", 2, "3a3a3a", "8a6a3a", "e0c8a8", ""), ("guild_master", "m", 1, "4a4a50", "3a5a78", "d0a888", ""),
                                    ("masked_rider", "m", 0, "20202a", "30303c", "d8b898", "blade")]:
    looks["looks"].append({"id": lid, "gender": g, "hair": hair, "hair_hex": hh, "outfit_hex": oh, "skin_hex": sh, "weapon": wp})
for cid, z, e in [("su_dai", "琵琶一曲，铃铛响处，人群自会聚拢。", "Wherever her bells ring, a crowd gathers."), ("li_shan", "话少，手稳，锤头落处，铁也认输。", "Few words, steady hands.")]:
    pass
arcs["arcs"].append({"companion": "su_dai", "planned": 4, "stages": [{"id": "1", "event": "arc_su_dai_1"}], "outcomes": ["redeemed", "alternate", "lost"], "bonds": ["friend", "sworn", "romance", "rival"]})
arcs["arcs"].append({"companion": "li_shan", "planned": 4, "stages": [{"id": "1", "event": "arc_li_shan_1"}], "outcomes": ["redeemed", "alternate", "lost"], "bonds": ["friend", "sworn", "romance", "rival"]})

# leads: name and description for every lead the new content adds
LEADS = {"linjiang_token": ("漕帮的木牌", "The Guild Token", "蒙面骑手腰间的漕帮木牌，也许能带你找到临江城里的线索。", "The Barge Guild token at the rider's belt may lead you to answers in Linjiang."),
         "escort_job": ("镖局的活儿", "The Escort Job", "钱满说镖局缺人，去平远镖局看看。", "Qian Man says the escort bureau needs hands. Try Pingyuan."),
         "barge_trail": ("漕帮的暗记", "The Anchor Mark", "货箱下刻着漕帮的船锚暗记。", "A Barge Guild anchor is carved under the crates."),
         "fragment_one": ("夜巷货栈", "The Alley Warehouse", "漕帮在夜巷有一间货栈，也许藏着第一枚星辰的下落。", "The guild keeps a warehouse in the alleys, perhaps hiding the first star."),
         "fragment_traced": ("第一枚星辰", "The First Star", "第一枚「九曜」碎片的下落已经查明。", "The first fragment of the Nine Stars has been traced."),
         "song_map": ("苏黛的曲子", "Su Dai's Song", "曲中的歌词，好像是一张藏起来的路线图。", "The song's verses seem to hide a route."),
         "burned_forge": ("烧毁的炉子", "The Burned Forge", "厉山的铁匠铺被人故意烧毁，与一批矿石有关。", "Li Shan's smithy was burned on purpose, and it has to do with a lot of ore."),
         "tea_rumor": ("茶楼风声", "Teahouse Rumours", "茶楼里在传各门派近来的动静。", "The teahouse buzzes with news of the sects.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("combat/scenarios.json", scen); dump("combat/units.json", units); dump("companions/companions.json", comps)
dump("story/looks.json", looks); dump("combat/combat_techniques.json", ct); dump("combat/duo.json", duos); dump("companions/arcs.json", arcs)
L("arc.outcome_unused", "", "")
del zh["arc.outcome_unused"]; del en["arc.outcome_unused"]
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events", len(areas["areas"]), "areas", len(comps["companions"]), "companions")
