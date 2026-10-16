#!/usr/bin/env python3
"""M25c: Year 3 quarter 11 (Eve of the Platform, weeks 151 to 165): the platform grounds, the alliances, the Gate's agents, Mid-Autumn, Head Lei,
the Masks' offers, the cliff trial (gate to the sixth realm) and the vigil. Run AFTER gen_year3_q10. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); arcs = load("companions/arcs.json"); looks = load("story/looks.json"); realms = load("cultivation/realms.json")

OWN_AREAS = ["pg_steps", "pg_pavilions"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
PREFIX = ("y3c_", "ry11_")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["y3_cliff_trial", "y3_gate_agents"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
units["units"] = [u for u in units["units"] if u["id"] not in ["cliff_master"]]
looks["looks"] = [l for l in looks["looks"] if l["id"] != "head_lei"]
looks["looks"].append({"id": "head_lei", "gender": "m", "hair": 2, "hair_hex": "b8b8b8", "outfit_hex": "4a3a2a", "skin_hex": "d0b090", "weapon": "staff"})
for r in realms["realms"]:
    if r["id"] == "return_simple":
        r["requires"]["flag"] = "cliff_trial_done"; r["requires"]["flag_key"] = "cliff"

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "elder": "story.speaker.elder", "xia": "npc.xia_zhi",
       "xiao": "npc.xiao_hanchuan", "xie": "npc.xie_wujiu", "chi": "npc.mask_chi", "qian": "npc.qian_man", "afu": "npc.villager_afu", "gu": "npc.master_gu", "hui": "npc.mask_hui", "xuan": "npc.mask_xuan", "lei": "npc.head_lei", "su": "npc.su_dai", "li": "npc.li_shan", "bai": "npc.bai_yan"}
WHO = {"wander": "wanderer", "elder": "elder", "xia": "xia_zhi", "xiao": "xiao_hanchuan", "xie": "xie_wujiu", "chi": "mask_chi", "qian": "qian_man", "afu": "villager",
       "gu": "master_gu", "hui": "mask_hui", "xuan": "mask_xuan", "lei": "head_lei", "su": "su_dai", "li": "li_shan", "bai": "bai_yan"}
L("npc.mask_xuan", "玄面", "The Xuan-Mask"); L("npc.head_lei", "雷盟主", "Head Lei"); L("npc.mask_chi", "赤面", "The Chi-Mask")
BG = {"pg_steps": "cangwu_day", "pg_pavilions": "cangwu_night", "cw_cave": "cangwu_night", "lj_teahouse": "city_market", "lj_market": "city_market", "lj_docks": "city_docks", "lj_alleys": "city_night", "cw_courts": "cangwu_day", "ym_fort": "yanmen_fort",
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
Y11 = {"week_min": 151}


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



def area(id, zn, en_, dz, de, wanders, **kw):
    a = {"id": id, "region": "cangwu", "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": 2, "wander": [],
         "open_default": True, "requires": {"lead": ["platform_year3"], "week_min": 151}}
    L(a["name_key"], zn, en_); L(a["desc_key"], dz, de)
    for i, (z, e, rw) in enumerate(wanders):
        k = f"world.area.{id}.w{i+1}"; L(k, z, e); a["wander"].append({"text_key": k, "rewards": [{"type": t, "id": r, "amount": n} for t, r, n in rw]})
    a.update(kw); areas["areas"].append(a)


# ===================================================================== AREAS
area("pg_steps", "论剑台石阶", "The Platform Steps", "苍梧山腰的白石长阶，直通山顶的论剑台，两侧已经搭起了各家的席棚。", "Long white steps climb Cangwu's flank to the Sword-Debate Platform, each house's awning already raised along them.",
     [("你在石阶上看各家弟子来来往往，记下了不少面孔。", "You watch disciples of every house come and go on the steps and memorise many faces.", [("attr", "insight", 1)]), ("石阶旁的茶摊在卖冷糕，你吃了两块。", "A tea stall by the steps sells cold cakes and you eat two.", [("resource", "food", 2)])])
area("pg_pavilions", "论剑台亭廊", "The Platform Pavilions", "论剑台下的一排亭廊，九家各占一间，灯笼夜夜不灭。", "Below the platform a row of pavilions, one for each of the nine houses, their lanterns never out.",
     [("你在亭廊下听各家使者低声议事。", "You overhear envoys murmuring in the pavilions.", [("attr", "insight", 1)]), ("亭廊角落的香炉里还留着半截好香。", "A half-burnt fine incense stick still smoulders in a corner censer.", [("resource", "coins", 14)])])

# ===================================================================== STORY
event("y3c_alliances", "fixed", "pg_pavilions",
      [("narr", "亭廊里，三方人马都在拉票。正统门派要你的名字，行商要你的钱路，也有人只想知道你到底站不站队。", "In the pavilions all three camps are canvassing. The orthodox houses want your name, the traders want your road of coin, and some only want to know whether you will take a side at all."),
       ("qian", "钱满笑得很客气：「论剑台选盟主，是九家投票。你手里那一票，是玉谷的，可不是你自己的。」", "Qian Man smiles courteously. \"The platform's Head is chosen by the nine houses' votes. The one in your hand belongs to Jade Valley, not to you alone.\"")],
      title=("拉票", "Canvassing"), window=(151, 155), priority=7, requires=Y11,
      choices=[("orthodox", "与正统门派同进退", "Pledge with the orthodox houses", [FLAG("pledge_orthodox"), ATTR("spirit", 2)]),
               ("trade", "与行商同进退", "Pledge with the traders", [FLAG("pledge_trade"), ATTR("insight", 2)]),
               ("free", "谁也不许，保留这一票", "Pledge to none and keep the vote", [FLAG("pledge_free"), ATTR("agility", 2)])],
      on_miss=[FLAG("pledge_free")])
event("y3c_gate_agents", "fixed", "pg_steps",
      [("narr", "石阶下方，几个扮成杂役的人正往席棚的梁上塞东西。你认得那个手势，是无相门的。", "Below the steps, several men dressed as labourers are stuffing something into an awning's beams. You know the gesture; it is the Faceless Gate's."),
       ("hero", "论剑台还没开，他们就想动手脚。", "The platform has not even opened and they already want to tamper.")],
      title=("梁上的手脚", "Tampering in the Beams"), window=(152, 158), priority=7, requires=Y11,
      choices=[("fight", "当场拿人", "Seize them on the spot", [BATTLE("y3_gate_agents")]),
               ("report", "报告雷盟主，暗中盯着", "Report to Head Lei and watch quietly", [ATTR("insight", 2), FLAG("agents_reported")])],
      on_miss=[FLAG("agents_free")])
event("y3c_midautumn", "fixed", "valley_village",
      [("narr", "第三年的中秋，月亮大得像一面铜镜。村口摆了一桌月饼，阿福说，今年是论剑台前最后一个团圆夜。", "Mid-Autumn of the third year: the moon is big as a bronze mirror. A table of mooncakes is set at the village gate, and A-Fu says this is the last reunion night before the platform."),
       ("narr", "你把第一块月饼，递给了谁？", "To whom do you hand the first mooncake?")],
      title=("第三个中秋", "The Third Mid-Autumn"), window=(157, 158), priority=7, requires={"week_min": 156},
      choices=[("valley", "谷里的老朋友：沈青禾、陆沉舟、白砚", "The old friends: Shen, Lu and Bai", [BOND("shen_qinghe", 2), BOND("lu_chenzhou", 2), BOND("bai_yan", 2), STAMINA(8)]),
               ("fighters", "并肩的战友：谢无咎、厉山、萧寒川", "The comrades: Xie, Li and Xiao", [BOND("xie_wujiu", 2), BOND("li_shan", 2), BOND("xiao_hanchuan", 2), STAMINA(8)]),
               ("street", "街头的同路人：苏黛、夏芷", "The street companions: Su Dai and Xia Zhi", [BOND("su_dai", 2), BOND("xia_zhi", 2), STAMINA(8)]),
               ("all", "大家围坐，一人一块", "Everyone around one table, one each", [ATTR("spirit", 2), STAMINA(8), FLAG("midautumn3_together")])],
      on_miss=[FLAG("midautumn3_missed")])
event("y3c_lei_head", "fixed", "pg_pavilions",
      [("narr", "盟主雷震岳坐在亭廊尽头，鬓角全白了。他的茶凉了很久，却一直没有喝。", "Head Lei Zhenyue sits at the pavilions' far end, his temples gone white. His tea has been cold a long time and he has not touched it."),
       ("lei", "「老夫不会再争这一席了。」他看着你，「玉契守了我二十年，我也被玉契困了二十年。」", "\"I will not contend for the seat again,\" he says, looking at you. \"The Accord was mine to keep for twenty years, and for twenty years it kept me.\""),
       ("lei", "「你可以接，也可以替它找一个更好的人。只是别学我，把它当作自己的命。」", "\"You may take it, or find a better hand for it. Only do not do as I did and mistake it for your fate.\"")],
      title=("雷盟主的话", "Head Lei's Word"), window=(156, 160), priority=7, requires=Y11,
      choices=[("endorse", "我会接下这一席", "I will take the seat", [FLAG("lei_endorse"), ATTR("spirit", 2)]),
               ("stay", "请他再撑一程", "Ask him to hold on a while longer", [FLAG("lei_stays"), ATTR("insight", 1), BOND("shen_qinghe", 1)]),
               ("other", "我替它另找一个人", "I will find someone else for it", [FLAG("lei_other"), ATTR("agility", 2)])],
      on_miss=[FLAG("lei_other")])
event("y3c_masks_offer", "fixed", "pg_steps",
      [("narr", "黄昏的石阶上，三个人先后站在你面前，各自只说了一句话。", "On the dusk steps three people stand before you one after another, each saying only a single sentence."),
       ("xuan", "玄面：「我给你一个没有战乱的天下，代价是它不再属于任何人。」", "Xuan-Mask: \"I offer you a realm without war. The price is that it belongs to no one.\""),
       ("chi", "赤面：「我给你一把足够锋利的刀，其余的，谁拦你就砍谁。」", "Chi-Mask: \"I offer you a blade sharp enough, and whoever stands in your way, cut them down.\""),
       ("hui", "灰面：「我给你一扇门，门后没有任何人等你，你可以直接走。」", "Hui-Mask: \"I offer you a door with nobody waiting behind it. You can simply walk away.\"")],
      title=("三面的最后邀请", "The Masks' Last Offers"), window=(158, 162), priority=7, requires=Y11,
      choices=[("xuan", "接玄面的天下", "Take the Xuan-Mask's realm", [FLAG("offer_xuan"), ATTR("insight", 2)]),
               ("chi", "接赤面的刀", "Take the Chi-Mask's blade", [FLAG("offer_chi"), ATTR("power", 2)]),
               ("hui", "走灰面的门", "Take the Hui-Mask's door", [FLAG("offer_hui"), ATTR("agility", 2)]),
               ("none", "三个都不要", "Take none of them", [FLAG("offer_none"), ATTR("spirit", 2)])],
      on_miss=[FLAG("offer_none")])
event("y3c_cliff_trial", "fixed", "cw_cave",
      [("narr", "苍梧后山的断崖边，顾行舟独自站在风里。他身后的崖壁上，刻着历代论剑台之前的试剑。", "On the broken cliff behind Cangwu Gu Xingzhou stands alone in the wind. The wall behind him bears the trial marks made before every platform gathering."),
       ("gu", "「论剑台之前，我要先看你的剑。」他把长剑抛在地上，「不是比谁快，是看你在悬崖边还能不能站稳。」", "\"Before the platform I must see your sword,\" he says, dropping his blade to the ground. \"Not who is faster, but whether you can still stand firm on the cliff's edge.\"")],
      title=("断崖试剑", "The Cliff Trial"), window=(160, 165), priority=8, requires=Y11,
      choices=[("trial", "接下试剑", "Take the trial", [BATTLE("y3_cliff_trial"), FLAG("cliff_trial_done")]),
               ("sit", "在崖边静坐一夜", "Sit on the cliff edge a whole night", [FLAG("cliff_trial_done"), ATTR("spirit", 3)])],
      on_miss=[FLAG("cliff_trial_done")])
event("y3c_vigil", "fixed", "pg_pavilions",
      [("narr", "论剑台开幕的前夜，亭廊里难得没人说话。同行的人一个接一个走来，坐在了你身边。", "The night before the platform opens the pavilions are, for once, silent. Those who walked with you come one by one and sit beside you."),
       ("narr", "有人在擦刀，有人在调弦，有人只是看着星星。", "Someone wipes a blade, someone tunes a string, someone only watches the stars.")],
      title=("开幕前夜", "The Night Before"), window=(162, 165), priority=8, requires=Y11,
      choices=[("together", "围坐一处，不多说话", "Sit together without many words", [FLAG("vigil_together"), ATTR("spirit", 2), STAMINA(10)]),
               ("alone", "独自走到台下，看一眼月亮", "Walk alone beneath the platform and look at the moon", [FLAG("vigil_alone"), ATTR("insight", 2), STAMINA(10)])],
      on_miss=[FLAG("vigil_alone")])

# ---- random templates
RANDOM = [
 ("ry11_steps_vendors", "pg_steps", [("narr", "石阶旁摆起了临时的摊子，卖茶的卖糕的卖旗子的，叫卖声一路传到山腰。", "Temporary stalls line the steps selling tea, cakes and pennants, hawkers' cries rolling up the slope.")], [ATTR("insight", 1)], ("山道的摊子", "Stalls on the Steps"), 3, 6),
 ("ry11_pavilion_lanterns", "pg_pavilions", [("narr", "亭廊的灯笼一盏盏挂上去，每一盏都写着各家的名号。", "Lanterns are hung in the pavilions one after another, each carrying a house's name.")], [ATTR("spirit", 1)], ("挂灯笼", "Hanging the Lanterns"), 3, 6),
 ("ry11_courts_ranks", "cw_courts", [("narr", "演武场上有各派弟子在报名，登记的长桌排了老远。", "Disciples of every sect are registering on the courts and the long table's queue stretches far.")], [ATTR("power", 1)], ("报名的长队", "The Registration Queue"), 3, 8),
 ("ry11_teahouse_odds", "lj_teahouse", [("narr", "茶客们在押注谁会当盟主，赔率写在一块小黑板上。", "Tea drinkers lay bets on who will be Head, the odds chalked on a small blackboard.")], [ATTR("insight", 1)], ("盟主的赔率", "Odds on the Head"), 3, 6),
 ("ry11_valley_letters", "valley_village", [("narr", "阿福收到一摞来自各处的信，都是祝你论剑台顺利的。", "A-Fu receives a stack of letters from everywhere, all wishing you well at the platform.")], [ATTR("spirit", 1)], ("各处来信", "Letters from Everywhere"), 3, 6),
 ("ry11_docks_pilgrims", "lj_docks", [("narr", "码头挤满了去苍梧的香客和镖师，渡船一趟接一趟。", "The docks are crowded with pilgrims and escorts heading for Cangwu, ferry after ferry.")], [ATTR("agility", 1)], ("赶路的人", "The Travellers"), 3, 6),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y11)

# ===================================================================== BATTLES
units["units"].append({"id": "cliff_master", "stats": {"hp": 460, "body": 20, "power": 25, "agility": 13, "spirit": 20}, "techniques": ["club_smash"]})
L("combat.unit.cliff_master", "断崖试剑者", "Cliff Trial Swordsman")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10, terrain=None):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": terrain or [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y3_gate_agents", "石阶捉人", "Seizing the Agents", "拿下破坏席棚的无相门杂役。", "Seize the Gate's agents tampering with the awnings.",
         ["gate_captain", "gate_elite", "gate_elite", "gate_blade"], [RES("coins", 55)], ["agents_caught"], ["agents_free"], 12)
scenario("y3_cliff_trial", "断崖试剑", "The Cliff Trial", "在断崖边撑住试剑者的全部招式。", "Withstand all of the trial swordsman's moves on the cliff's edge.", ["cliff_master"],
         [RES("coins", 40)], ["cliff_trial_won"], ["cliff_trial_lost"], 14, [[2, 2, "hazard"], [4, 2, "hazard"], [1, 3, "cover"], [4, 4, "hazard"]])

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs); dump("combat/scenarios.json", scen); dump("combat/units.json", units)
dump("companions/arcs.json", arcs); dump("story/looks.json", looks); dump("cultivation/realms.json", realms)
zh["realm.req.cliff"] = "断崖试剑 {have}/{need}"; en["realm.req.cliff"] = "Cliff trial {have}/{need}"
zh["realm.blocked.cliff"] = "尚未通过断崖试剑"; en["realm.blocked.cliff"] = "The cliff trial is not yet passed"
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events")
