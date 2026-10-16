#!/usr/bin/env python3
"""M25a: Year 3 quarter 9 (The Province Shakes, weeks 121 to 135): the new year, the Gate in the open, the houses' summons, the valley
returns, the Chi-Mask, the border burns, and stage 4 (the relationship scene) for Xie Wujiu and Xia Zhi. Run AFTER gen_year2_q8. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); arcs = load("companions/arcs.json"); looks = load("story/looks.json")

PREFIX = ("y3_", "ry9_", "arc_xie_wujiu_4", "arc_xia_zhi_4")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["y3_guild_hall", "y3_chi_duel", "y3_border_defence"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
units["units"] = [u for u in units["units"] if u["id"] not in ["chi_mask", "gate_elite"]]
looks["looks"] = [l for l in looks["looks"] if l["id"] != "mask_chi"]
looks["looks"].append({"id": "mask_chi", "gender": "m", "hair": 1, "hair_hex": "2a1a1a", "outfit_hex": "8a2030", "skin_hex": "e0c0a0", "weapon": "sword"})
for a in arcs["arcs"]:
    if a["companion"] in ("xie_wujiu", "xia_zhi"):
        a["stages"] = [s for s in a["stages"] if s["id"] != "4"]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "elder": "story.speaker.elder", "xia": "npc.xia_zhi",
       "xiao": "npc.xiao_hanchuan", "xie": "npc.xie_wujiu", "chi": "npc.mask_chi", "qian": "npc.qian_man", "afu": "npc.villager_afu", "gu": "npc.master_gu", "hui": "npc.mask_hui"}
WHO = {"wander": "wanderer", "elder": "elder", "xia": "xia_zhi", "xiao": "xiao_hanchuan", "xie": "xie_wujiu", "chi": "mask_chi", "qian": "qian_man", "afu": "villager",
       "gu": "master_gu", "hui": "mask_hui"}
L("npc.mask_chi", "赤面", "The Chi-Mask"); L("npc.villager_afu", "阿福", "A-Fu")
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
ARC_BOND = lambda c, v: {"type": "arc_bond", "id": c, "value": v}
Y9 = {"week_min": 121}


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


def branch_event(id, kind, area_id, branches, entry, title, window, ends, **kw):
    """An event whose opening depends on flags. branches: {key: [lines]}; entry: [(flag or None, key)]; ends: {key: effects on the last node}."""
    ev = {"id": id, "kind": kind, "area": area_id, "scene": {"dialogue": "ev_" + id}, "title_key": f"event.{id}.title"}
    L(ev["title_key"], *title)
    if window: ev["window"] = {"from": window[0], "to": window[1]}
    ev.update(kw); events["events"].append(ev)
    nodes = []
    for key, lines in branches.items():
        who = None
        for i, (sp, z, e) in enumerate(lines):
            k = f"event.{id}.{key}.{i+1}"; L(k, z, e)
            n = {"id": f"{key}{i+1}", "text_key": k, "speaker_key": SPK[sp]}
            if sp in WHO and who is None: who = WHO[sp]
            if i < len(lines) - 1: n["next"] = f"{key}{i+2}"
            else:
                n["next"] = ""
                if ends.get(key): n["on_enter"] = ends[key]
            if i == 0:
                cmds = [{"c": "bg", "id": BG[area_id]}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "neutral"}]
                if who: cmds.append({"c": "show", "who": who, "slot": "right", "pose": "idle", "face": "neutral"})
                n["stage"] = cmds
            nodes.append(n)
    ent = []
    for flag, key in entry:
        ent.append({"if": {"flag": flag}, "node": f"{key}1"} if flag else {"node": f"{key}1"})
    dlgs["dialogues"].append({"id": "ev_" + id, "entry": ent, "nodes": nodes})


BONDS = {"friend": ("挚友", "Close Friend", 10), "sworn": ("结义", "Sworn Sibling", 14), "romance": ("情缘", "Romance", 16), "rival": ("宿敌", "Rival", 0)}
def stage4(cid, area_id, win, red, alt, lost, ask, returns_flag):
    """Stage 4: the resolution and the relationship scene. red/alt: lines for outcomes redeemed/alternate, ending in the question `ask`;
    lost: a farewell. The relationship options are gated by bond (the rival path is always open)."""
    eid = f"arc_{cid}_4"
    ev = {"id": eid, "kind": "fixed", "area": area_id, "scene": {"dialogue": "ev_" + eid}, "title_key": f"event.{eid}.title", "window": {"from": win[0], "to": win[1]},
          "priority": 6, "requires": {"week_min": 121, "bond_min": {cid: 4}, "arc_min": {cid: 3}}, "on_miss": [ARC_STAGE(cid, 4)]}
    L(ev["title_key"], *ask["title"]); events["events"].append(ev)
    nodes = []
    for key, lines in (("r", red), ("a", alt)):
        for i, (sp, z, e) in enumerate(lines + [(ask["who"], ask["zh"], ask["en"])]):
            k = f"event.{eid}.{key}.{i+1}"; L(k, z, e)
            n = {"id": f"{key}{i+1}", "text_key": k, "speaker_key": SPK[sp]}
            if i == len(lines):
                n["choices"] = []
                for b, (bz, be, need) in BONDS.items():
                    ck = f"event.{eid}.{key}.c.{b}"; L(ck, bz, be)
                    ch = {"id": b, "label_key": ck, "next": "", "effects": [ARC_BOND(cid, b), ARC_STAGE(cid, 4), BOND(cid, 2)]}
                    if need: ch["gate"] = {"bond_min": {cid: need}}
                    n["choices"].append(ch)
            else:
                n["next"] = f"{key}{i+2}"
            if i == 0:
                n["stage"] = [{"c": "bg", "id": BG[area_id]}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "neutral"}, {"c": "show", "who": cid, "slot": "right", "pose": "idle", "face": "neutral"}]
            nodes.append(n)
    for i, (sp, z, e) in enumerate(lost):
        k = f"event.{eid}.l.{i+1}"; L(k, z, e)
        n = {"id": f"l{i+1}", "text_key": k, "speaker_key": SPK[sp]}
        if i < len(lost) - 1: n["next"] = f"l{i+2}"
        else: n["next"] = ""; n["on_enter"] = [ARC_STAGE(cid, 4), FLAG(returns_flag)]
        if i == 0:
            n["stage"] = [{"c": "bg", "id": BG[area_id]}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "sad"}, {"c": "show", "who": cid, "slot": "right", "pose": "idle", "face": "sad"}]
        nodes.append(n)
    dlgs["dialogues"].append({"id": "ev_" + eid, "entry": [{"if": {"flag": f"arcout_{cid}_redeemed"}, "node": "r1"}, {"if": {"flag": f"arcout_{cid}_alternate"}, "node": "a1"}, {"node": "l1"}], "nodes": nodes})
    for a in arcs["arcs"]:
        if a["companion"] == cid:
            a["stages"].append({"id": "4", "event": eid})


# ===================================================================== STORY
branch_event("y3_new_year", "fixed", "valley_village", {
    "orth": [("narr", "第三年的头一天，苍梧派的请柬早早就到了。字迹端正，措辞周全，每一句都像在量你的分寸。", "On the first day of the third year an invitation from Cangwu arrives early, written in a neat hand, each phrase measuring you."),
             ("elder", "「论剑台就在今年。」你仿佛听见墨老师在耳边说，「站在哪一边，都要记得自己是玉谷的人。」", "\"The platform gathering is this year.\" You seem to hear Elder Mo at your ear. \"Whatever side you stand on, remember you are of Jade Valley.\"")],
    "trade": [("narr", "第三年的头一天，漕帮的年礼装了一车，账目清清楚楚，连回礼的价码都写好了。", "On the first day of the third year the Barge Guild sends a cart of gifts, every item ledgered, even the price of a return gift noted."),
              ("elder", "「情分和账，是两本册子。」你仿佛听见墨老师在说，「别记混了。」", "\"Favour and accounts are two separate books,\" you seem to hear Elder Mo say. \"Do not mix them up.\"")],
    "free": [("narr", "第三年的头一天，没有请柬，也没有年礼。你独自守岁，竹林里只有雪压断枝的轻响。", "On the first day of the third year there is no invitation and no gift. You keep the vigil alone, the bamboo ticking as snow bends the branches."),
             ("elder", "「不认谁的账，也就没人替你记账。」你仿佛听见墨老师笑了一声，「路要自己走。」", "\"If you answer to no ledger, nobody keeps yours,\" you seem to hear Elder Mo chuckle. \"You must walk your own road.\"")]},
    [("council_orthodox", "orth"), ("council_trade", "trade"), (None, "free")], ("第三年的头一天", "The First Day of the Third Year"), (121, 123),
    {"orth": [FLAG("year3_start"), ATTR("spirit", 2)], "trade": [FLAG("year3_start"), ATTR("insight", 2)], "free": [FLAG("year3_start"), ATTR("agility", 2)]},
    priority=8, requires=Y9, on_miss=[FLAG("year3_start")])

event("y3_gate_opens", "fixed", "lj_teahouse",
      [("narr", "茶楼里的人窃窃私语。昨夜，漕帮旧会馆的门被换了锁，门楣上多了一面没有字的灰旗。", "Whispers fill the teahouse. Overnight the lock of the old Barge Guild hall was changed and a blank grey banner hangs over its lintel."),
       ("qian", "钱满压低嗓子：「无相门不再遮脸了。他们要让全城都看见。」", "Qian Man lowers his voice: \"The Faceless Gate has stopped hiding its face. They want the whole city to see it.\""),
       ("hero", "既然是摆在明处，那就在明处了结。", "If it is out in the open, it can be ended in the open.")],
      title=("灰旗压顶", "The Grey Banner"), window=(122, 128), priority=7, requires=Y9,
      choices=[("storm", "带人冲进会馆", "Storm the hall", [BATTLE("y3_guild_hall"), LEAD("gate_unmasked")]),
               ("warn", "先通知各家，再从长计议", "Warn the houses first", [ATTR("insight", 2), FLAG("guild_hall_lost"), LEAD("gate_unmasked")])],
      on_miss=[FLAG("guild_hall_lost"), LEAD("gate_unmasked")])

event("y3_house_summons", "fixed", "lj_teahouse",
      [("narr", "盟主雷震岳的令牌送到了茶楼：九家各派一位代表，开春前在苍梧山下议定论剑台的规矩。", "Alliance Head Lei Zhenyue's token reaches the teahouse: each of the nine houses is to send a delegate and settle the platform's rules at Cangwu's foot before spring."),
       ("qian", "「三张席面在摆，」钱满数着手指，「正统的，行商的，还有一张空着。你想坐哪张？」", "\"Three tables are being laid,\" Qian Man counts on his fingers. \"One orthodox, one for the traders, and one left empty. Which will you sit at?\"")],
      title=("论剑台召集令", "The Platform Summons"), window=(124, 130), priority=6, requires=Y9,
      choices=[("orthodox", "坐正统的席", "The orthodox table", [FLAG("seat_orthodox"), ATTR("spirit", 1), LEAD("platform_summons")]),
               ("trade", "坐行商的席", "The traders' table", [FLAG("seat_trade"), ATTR("insight", 1), LEAD("platform_summons")]),
               ("free", "坐那张空席", "The empty seat", [FLAG("seat_free"), ATTR("agility", 1), LEAD("platform_summons")])],
      on_miss=[FLAG("seat_free"), LEAD("platform_summons")])

branch_event("y3_valley_returns", "fixed", "valley_village", {
    "fall": [("afu", "阿福拎着一壶热茶：「少侠，墨老师的坟头我每天扫。今年竹子长得特别好。」", "A-Fu comes with a pot of hot tea: \"Hero, I sweep Elder Mo's grave every day. The bamboo grew especially well this year.\""),
             ("narr", "你在坟前站了很久。碑后压着的那片灰蜡，你至今没有勇气再看一遍。", "You stand at the grave a long while. The scrap of grey wax pressed behind the stone, you still have not the courage to look at again."),
             ("hero", "原来，第九家的名字，就刻在这里。", "So the ninth house's name is carved right here.")],
    "kept": [("afu", "阿福在新修的客栈门口吆喝：「少侠回来啦！墨老师在屋里烧茶，等你一下午了。」", "A-Fu hollers from the doorway of the rebuilt inn: \"The hero is back! Elder Mo has been brewing tea inside all afternoon waiting for you.\""),
             ("elder", "「玉谷这一脉，」老人把茶推给你，「叫第九家。这个名字，你该知道了。」", "\"Our line in Jade Valley,\" the old man says, pushing a cup to you, \"is the ninth house. You ought to know its name by now.\""),
             ("hero", "我握着热茶，手心比茶还烫。", "I hold the hot tea, my palms hotter than the cup.")],
    "away": [("afu", "阿福在村口迎你：「墨老师走了好些日子了，只托我留了一句话。」", "A-Fu meets you at the gate: \"Elder Mo has been away some time and left only a message with me.\""),
             ("elder", "「玉谷是第九家。」捎来的字条上只有这一句，「回来看看。」", "\"Jade Valley is the ninth house.\" The note carries only this line, \"Come home and see.\""),
             ("hero", "第九家。我一直是它的人，却今日才知道它的名字。", "The ninth house. I was always of it and learn its name only today.")]},
    [("elder_fallen", "fall"), ("valley_kept", "kept"), (None, "away")], ("玉谷的名字", "The Valley's Name"), (126, 132),
    {"fall": [FLAG("ninth_house_named"), LEAD("ninth_house"), ATTR("spirit", 2)], "kept": [FLAG("ninth_house_named"), LEAD("ninth_house"), ATTR("spirit", 2), STAMINA(10)],
     "away": [FLAG("ninth_house_named"), LEAD("ninth_house"), ATTR("insight", 2)]},
    priority=6, requires=Y9, on_miss=[FLAG("ninth_house_named"), LEAD("ninth_house")])

event("y3_chi_mask", "fixed", "lj_alleys",
      [("narr", "巷口的灯笼灭了一盏又一盏。一个穿暗红长袍的男子靠在墙边，脸上只有半块赤色面具。", "The lanterns at the alley mouth go out one after another. A man in dark red robes leans on the wall, wearing half a crimson mask."),
       ("chi", "「久闻玉谷传人。」他笑起来，笑声很轻，「玄面要先生，灰面要缘分，我嘛——只想要一场痛快的架。」", "\"I have long heard of the heir of Jade Valley,\" he laughs softly. \"The Xuan-Mask wants a scholar, the Hui-Mask wants fate, and I only want a good fight.\""),
       ("chi", "「接我三十招，我就告诉你，第二道门的钥匙长什么样。」", "\"Last thirty moves against me and I will tell you what the key to the second gate looks like.\"")],
      title=("赤面邀战", "The Chi-Mask's Challenge"), window=(128, 134), priority=7, requires=Y9,
      choices=[("duel", "接下这一战", "Accept the duel", [BATTLE("y3_chi_duel")]),
               ("slip", "不接，借夜色离开", "Decline and slip away", [ATTR("agility", 2), FLAG("chi_declined")])],
      on_miss=[FLAG("chi_declined")])

branch_event("y3_border_burns", "fixed", "ym_fort", {
    "held": [("xiao", "「你来得正好。」萧寒川披着甲，眼里有血丝，「我的人带着村民撤进城里，关外只剩一条路。」", "\"You come at the right moment.\" Xiao Hanchuan wears his armour, eyes red. \"My men led the villagers inside; one road is left beyond the pass.\""),
             ("narr", "烽烟从北边升起。破阵那日跟着他出关的老兵，如今自觉站到了你们身后。", "Beacon smoke rises in the north. The veterans who broke ranks with him that day now stand behind you without being asked.")],
    "plain": [("xiao", "「雁门守不住了。」萧寒川的声音很哑，「援军一道令都没有。我只有这座城，和城里这些人。」", "\"Yanmen cannot hold,\" Xiao Hanchuan says hoarsely. \"Not one order has come from the reinforcements. I have only this fort and the people in it.\""),
              ("narr", "烽烟从北边升起，一直烧到了城下的雪地。", "Beacon smoke rises in the north and burns down to the snow below the walls.")]},
    [("ranks_broken", "held"), (None, "plain")], ("烽烟再起", "The Beacons Again"), (130, 135),
    {"held": [LEAD("border_burns"), SCHED("y3_border_choice", 1, 3)], "plain": [LEAD("border_burns"), SCHED("y3_border_choice", 1, 3)]},
    priority=7, requires=Y9, on_miss=[FLAG("border_lost"), LEAD("border_burns")])
# the border scene's choices come from a second event it schedules, so that both openings share one decision
event("y3_border_choice", "fixed", "ym_fort",
      [("xiao", "「守城，还是护着村民撤。」萧寒川看着你，「我不勉强。你选哪个，我就跟着打哪个。」", "\"Hold the fort, or cover the villagers' retreat?\" Xiao Hanchuan looks at you. \"I will not press you. Whichever you choose, I fight it.\"")],
      title=("守与撤", "Hold or Withdraw"), scheduled_only=True, priority=7, requires=Y9,
      choices=[("defend", "守住城墙", "Hold the wall", [BATTLE("y3_border_defence"), BOND("xiao_hanchuan", 2)]),
               ("evacuate", "护着村民撤退", "Cover the retreat", [ATTR("spirit", 2), FLAG("border_evacuated"), BOND("xiao_hanchuan", 3)])],
      on_miss=[FLAG("border_lost")])

# ---- stage 4: the relationship scenes
stage4("xie_wujiu", "cw_courts", (124, 136),
       [("narr", "苍梧演武场上，顾行舟当着全山弟子，向谢无咎躬身一礼，递上一枚教习的令牌。", "On the Cangwu courts Gu Xingzhou bows before the whole mountain to Xie Wujiu and holds out a teacher's token."),
        ("xie", "「他们叫我回来当教习。」谢无咎把令牌在掌心转了转，「我想了很久，还是想在玉谷边上自己开个院子。」", "\"They want me back as a teacher,\" Xie Wujiu says, turning the token in his palm. \"I thought a long while and I would rather open a courtyard of my own at the valley's edge.\"")],
       [("narr", "顾行舟私下认了错，没有人知道。谢无咎站在山门外，没有进去，也没有走。", "Gu Xingzhou admitted his fault in private and nobody else knows. Xie Wujiu stands outside the mountain gate, neither going in nor leaving."),
        ("xie", "「这样也好。」他的话很轻，「真相有人记着，就够了。」", "\"This will do,\" he says quietly. \"If someone remembers the truth, that is enough.\"")],
       [("narr", "谢无咎把那身旧红袍叠好，放在苍梧山门前的石阶上。", "Xie Wujiu folds his old red robe and sets it on the stone steps before the Cangwu gate."),
        ("xie", "「我走了。」他没有回头，「哪天擂台上见，别手软。」", "\"I am leaving,\" he says without turning. \"If we meet on a platform one day, do not hold back.\"")],
       {"who": "xie", "zh": "「这一路，多谢你。」他看着你，「你想做我的什么人？」", "en": "\"Thank you for the whole road.\" He looks at you. \"What would you be to me?\"", "title": ("院中人", "The Courtyard")}, "xie_returns")
stage4("xia_zhi", "lj_alleys", (128, 140),
       [("narr", "清晨的巷子里，夏芷牵着一个瘦小的男孩，男孩手里攥着一块冷了的烧饼。", "In the morning alley Xia Zhi leads a thin little boy who clutches a cold sesame cake."),
        ("xia", "「我弟弟。」她第一次笑得没有防备，「听雨阁肯收他学医。我也……不用再替谁偷东西了。」", "\"My little brother.\" For the first time her smile has no guard. \"Listening-Rain Hall will take him to learn medicine. And I... no longer have to steal for anyone.\"")],
       [("narr", "巷子尽头，夏芷坐在屋檐上，匕首搁在膝头。三天过去了，没有人再来问那块玉符。", "At the end of the alley Xia Zhi sits on a roof edge with her dagger on her knees. Three days have passed and nobody has come asking for the tally."),
        ("xia", "「事还没完，」她朝下看你，「可我已经想好了，这一次，我选你这边。」", "\"It is not over,\" she says, looking down at you. \"But I have decided. This time I choose your side.\"")],
       [("narr", "夜巷里，夏芷站在灰衣人身后，匕首收进了袖里。她没有看你。", "In the night alley Xia Zhi stands behind the grey-clad men, her dagger gone into her sleeve. She does not look at you."),
        ("xia", "「玉符到他们手里了。」她的声音很轻，「我不求你原谅。下次见面，我不会留情。」", "\"The tally is in their hands now,\" she says softly. \"I do not ask forgiveness. Next time we meet I will not hold back.\"")],
       {"who": "xia", "zh": "「喂，别那样看我。」她跳下来，「你想做我的什么人？」", "en": "\"Hey, don't look at me like that.\" She hops down. \"What would you be to me?\"", "title": ("巷口的天光", "Daylight at the Alley Mouth")}, "xia_returns")

# ---- random templates
RANDOM = [
 ("ry9_valley_planting", "valley_village", [("narr", "春雨刚过，村里人赶着下种。阿福说，今年的竹笋会比往年都多。", "Spring rain has barely passed and villagers hurry to sow. A-Fu says there will be more bamboo shoots than ever.")], [ATTR("body", 1)], ("下种", "Planting"), 3, 6),
 ("ry9_market_grey", "lj_market", [("narr", "集市上有几个摊子挂起了灰布条。问起缘由，摊主只摇头。", "A few market stalls hang grey strips of cloth. Asked why, the owners only shake their heads.")], [ATTR("insight", 1)], ("摊上的灰布", "Grey Cloth on the Stalls"), 3, 6),
 ("ry9_docks_search", "lj_docks", [("narr", "码头上的货被一箱箱翻查，查货的人不穿官服，也不出示文书。", "Cargo on the docks is searched crate by crate by men who wear no uniform and show no papers.")], [ATTR("agility", 1)], ("翻查货箱", "Crates Searched"), 3, 6),
 ("ry9_courts_drill", "cw_courts", [("narr", "演武场上，弟子们在加练。口令一声接一声，听得出是在备战。", "On the courts disciples drill extra hours, the commands coming one after another like a muster.")], [ATTR("power", 1)], ("加练", "Extra Drill"), 3, 8),
 ("ry9_fort_supplies", "ym_fort", [("narr", "城里的粮草又少了一成，伙夫把最后一袋米倒进大锅，没吭声。", "Another tenth of the fort's stores is gone. The cook empties the last sack of rice into the pot without a word.")], [ATTR("body", 1)], ("粮草", "Supplies"), 3, 8),
 ("ry9_teahouse_song", "lj_teahouse", [("narr", "茶楼里有人在唱新编的曲子，唱的是玉契和论剑台。听的人安静得很。", "Someone in the teahouse sings a newly written song about the Accord and the platform. The listeners are very quiet.")], [ATTR("spirit", 1)], ("新曲", "A New Song"), 3, 6),
 ("ry9_alley_cat", "lj_alleys", [("narr", "夜巷里一只黑猫蹲在墙头，盯着你看了很久，然后纵身跳进了暗处。", "In the night alley a black cat crouches on a wall and watches you a long while before leaping into the dark.")], [ATTR("agility", 1)], ("墙头的黑猫", "The Cat on the Wall"), 3, 6),
 ("ry9_harbour_news", "pd_harbour", [("narr", "海船带来了岛上的消息：隐宗的弟子们已经启程去苍梧，说是要看一看这场论剑台。", "A ship brings news from the isle: the hermits' disciples have set out for Cangwu to see this platform gathering.")], [ATTR("insight", 1)], ("岛上来客", "News from the Isle"), 3, 8),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y9)

# ===================================================================== BATTLES
units["units"].append({"id": "chi_mask", "stats": {"hp": 260, "body": 15, "power": 20, "agility": 14, "spirit": 14}, "techniques": ["swift_dash"]})
units["units"].append({"id": "gate_elite", "stats": {"hp": 110, "body": 12, "power": 15, "agility": 11, "spirit": 10}, "techniques": ["club_smash"]})
L("combat.unit.chi_mask", "赤面", "The Chi-Mask"); L("combat.unit.gate_elite", "无相门精锐", "Gate Elite")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10, terrain=None):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": terrain or [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y3_guild_hall", "夺回旧会馆", "Retaking the Guild Hall", "击退守在会馆里的无相门精锐。", "Beat back the Gate elite who hold the hall.",
         ["gate_captain", "gate_elite", "gate_elite", "gate_elite"], [RES("coins", 45)], ["guild_hall_won"], ["guild_hall_lost"], 12)
scenario("y3_chi_duel", "赤面之战", "The Chi-Mask's Duel", "在赤面手下撑过三十招。", "Last out the Chi-Mask's thirty moves.", ["chi_mask", "gate_elite"],
         [RES("coins", 60), RES("ore", 2)], ["chi_duel_won"], ["chi_duel_lost"], 14)
scenario("y3_border_defence", "雁门守城", "Holding Yanmen", "守住城墙，击退来犯的敌人。", "Hold the wall and drive off the attackers.",
         ["gate_elite", "yanmen_raider", "yanmen_raider", "garrison_sabre"], [RES("coins", 50)], ["border_held"], ["border_lost"], 12,
         [[1, 3, "cover"], [4, 3, "cover"], [0, 2, "hazard"], [5, 2, "hazard"]])

LEADS = {"gate_unmasked": ("无相门现身", "The Gate Unmasked", "无相门不再遮面，灰旗已经挂在漕帮旧会馆上。", "The Faceless Gate hides its face no longer; its grey banner hangs over the old guild hall."),
         "platform_summons": ("论剑台召集令", "The Platform Summons", "雷盟主召集九家，开春前议定论剑台的规矩。", "Head Lei calls the nine houses to settle the platform's rules before spring."),
         "ninth_house": ("第九家", "The Ninth House", "玉谷这一脉，就是玉契的第九家。", "The Jade Valley line is the Accord's ninth house."),
         "border_burns": ("北境烽烟", "Beacons in the North", "雁门又起烽烟，守军在等一个决断。", "Beacons burn again at Yanmen, and the garrison waits for a decision.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/events.json", events); dump("world/event_dialogues.json", dlgs); dump("combat/scenarios.json", scen); dump("combat/units.json", units)
dump("companions/arcs.json", arcs); dump("story/looks.json", looks)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events")
