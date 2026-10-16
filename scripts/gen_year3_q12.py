#!/usr/bin/env python3
"""M25d: Year 3 quarter 12 (The Gathering, weeks 166 to 180): the platform top, the arrivals, the bracket, those who return, the Solstice, the Gate's raid,
the Masks, the choice and the finale scene. Run AFTER gen_year3_q11. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); arcs = load("companions/arcs.json"); looks = load("story/looks.json"); realms = load("cultivation/realms.json")

OWN_AREAS = ["pg_platform"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
PREFIX = ("y3d_", "ry12_")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["y3_bracket", "y3_returned", "y3_platform_raid", "y3_masks"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
units["units"] = [u for u in units["units"] if u["id"] not in ["xuan_mask"]]
SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "elder": "story.speaker.elder", "xia": "npc.xia_zhi",
       "xiao": "npc.xiao_hanchuan", "xie": "npc.xie_wujiu", "chi": "npc.mask_chi", "qian": "npc.qian_man", "afu": "npc.villager_afu", "gu": "npc.master_gu", "hui": "npc.mask_hui", "xuan": "npc.mask_xuan", "lei": "npc.head_lei", "su": "npc.su_dai", "li": "npc.li_shan", "bai": "npc.bai_yan"}
WHO = {"wander": "wanderer", "elder": "elder", "xia": "xia_zhi", "xiao": "xiao_hanchuan", "xie": "xie_wujiu", "chi": "mask_chi", "qian": "qian_man", "afu": "villager",
       "gu": "master_gu", "hui": "mask_hui", "xuan": "mask_xuan", "lei": "head_lei", "su": "su_dai", "li": "li_shan", "bai": "bai_yan"}
L("npc.mask_xuan", "玄面", "The Xuan-Mask"); L("npc.head_lei", "雷盟主", "Head Lei"); L("npc.mask_chi", "赤面", "The Chi-Mask")
BG = {"pg_platform": "cangwu_day", "pg_steps": "cangwu_day", "pg_pavilions": "cangwu_night", "cw_cave": "cangwu_night", "lj_teahouse": "city_market", "lj_market": "city_market", "lj_docks": "city_docks", "lj_alleys": "city_night", "cw_courts": "cangwu_day", "ym_fort": "yanmen_fort",
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
Y12 = {"week_min": 166}


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
            for cid, cz, ce, ef, *gate in choices:
                ck = f"event.{id}.c.{cid}"; L(ck, cz, ce)
                ch = {"id": cid, "label_key": ck, "next": "", "effects": ef}
                if gate: ch["gate"] = gate[0]
                n["choices"].append(ch)
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
         "open_default": True, "requires": {"lead": ["platform_year3"], "week_min": 166}}
    L(a["name_key"], zn, en_); L(a["desc_key"], dz, de)
    for i, (z, e, rw) in enumerate(wanders):
        k = f"world.area.{id}.w{i+1}"; L(k, z, e); a["wander"].append({"text_key": k, "rewards": [{"type": t, "id": r, "amount": n} for t, r, n in rw]})
    a.update(kw); areas["areas"].append(a)




def branch_event2(id, kind, area_id, branches, entry, title, window, ends, choices=None, **kw):
    """Like branch_event, but a branch may end in choices: choices = {key: [(cid, zh, en, effects)]}."""
    choices = choices or {}
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
            if i < len(lines) - 1:
                n["next"] = f"{key}{i+2}"
            elif key in choices:
                n["choices"] = []
                for cid, cz, ce, ef, *gate in choices[key]:
                    ck = f"event.{id}.{key}.c.{cid}"; L(ck, cz, ce)
                    ch = {"id": cid, "label_key": ck, "next": "", "effects": ef}
                    if gate: ch["gate"] = gate[0]
                    n["choices"].append(ch)
            else:
                n["next"] = ""
                if ends.get(key): n["on_enter"] = ends[key]
            if i == 0:
                cmds = [{"c": "bg", "id": BG[area_id]}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "neutral"}]
                if who: cmds.append({"c": "show", "who": who, "slot": "right", "pose": "idle", "face": "neutral"})
                n["stage"] = cmds
            nodes.append(n)
    ent = [{"if": {"flag": flag}, "node": f"{key}1"} if flag else {"node": f"{key}1"} for flag, key in entry]
    dlgs["dialogues"].append({"id": "ev_" + id, "entry": ent, "nodes": nodes})


# ===================================================================== AREAS
area("pg_platform", "论剑台", "The Sword-Debate Platform", "一座三丈见方的白石高台，四面立着九根石柱，每一根上都刻着一家的名号。", "A white stone platform three zhang square, nine pillars at its edges, each carved with a house's name.",
     [("你立在台边，看着风把各家的旗子吹向同一个方向。", "You stand at the edge and watch the wind blow every house's banner the same way.", [("attr", "spirit", 1)]), ("石柱脚下压着一枚旧令牌，上面的字已经磨平。", "An old token lies under a pillar, its letters worn smooth.", [("resource", "coins", 18)])])

# ===================================================================== STORY
branch_event("y3d_arrivals", "fixed", "pg_steps", {
    "orth": [("narr", "苍梧山道上白袍如雪。正统门派的弟子分列两侧，向你抱拳，礼数一丝不苟。", "White robes line the Cangwu road like snow. Orthodox disciples stand to either side and salute you, every courtesy exact."),
             ("qian", "钱满在人群里挤到你身边：「正统门的票，十有八九是你的了。只是他们要的，不只是一个盟主。」", "Qian Man squeezes through the crowd to your side. \"Nine in ten orthodox votes are yours. But they want more than a Head.\"")],
    "trade": [("narr", "山道上旗帜翻飞，漕帮与镖局的车马一辆接一辆。行商们把你的名字写在了账上。", "Banners flutter along the road as the guild and courier wagons roll in one after another. The traders have written your name in their ledgers."),
              ("qian", "钱满笑着点银子：「行商的票是你的。不过，账总是要还的。」", "Qian Man counts silver, grinning. \"The traders' votes are yours. Mind you, accounts always come due.\"")],
    "free": [("narr", "各家的棚子都挂了旗，只有台阶下摆了一张没有旗的椅子。有人看它，有人绕开。", "Every house's awning flies a banner, but at the foot of the steps stands a single chair with none. Some look at it and some walk around."),
             ("qian", "钱满摊手：「你谁的票也没拿，也没人能替你拿。这一回，你全凭自己。」", "Qian Man spreads his hands. \"You took nobody's vote and nobody can take yours. This time you stand entirely alone.\"")]},
    [("pledge_orthodox", "orth"), ("pledge_trade", "trade"), (None, "free")], ("九家抵达", "The Houses Arrive"), (166, 170),
    {"orth": [FLAG("arrivals_seen"), ATTR("spirit", 2)], "trade": [FLAG("arrivals_seen"), ATTR("insight", 2)], "free": [FLAG("arrivals_seen"), ATTR("agility", 2)]},
    priority=8, requires=Y12, on_miss=[FLAG("arrivals_seen")])

event("y3d_platform_open", "fixed", "pg_platform",
      [("lei", "雷震岳站在台中央，用没有力气的声音说：「论剑台，开。」", "Lei Zhenyue stands in the middle of the platform and says, in a voice with no force left in it: \"The platform is open.\""),
       ("narr", "第一轮是擂台比试。各家推出弟子，输的下台，赢的留下。你的名字也在签上。", "The first round is a bracket. Each house sends fighters; the loser steps down, the winner stays. Your name is on the draw."),
       ("qian", "「有你那一票压着，你也可以不下场，只在台下看着。」钱满低声说，「但台下看着的人，往往看不清台上。」", "\"With your vote you may stay off the stage and watch from below,\" Qian Man murmurs. \"But those who watch from below often cannot see the stage.\"")],
      title=("论剑台开", "The Platform Opens"), window=(171, 172), priority=8, requires={"week_min": 171},
      choices=[("bracket", "下场比试", "Enter the bracket", [BATTLE("y3_bracket"), FLAG("bracket_entered")]),
               ("stands", "留在台下，看清全局", "Stay in the stands and watch the whole", [FLAG("bracket_skipped"), ATTR("insight", 2)])],
      on_miss=[FLAG("bracket_skipped")])

branch_event2("y3d_returned", "fixed", "pg_steps", {
    "xie": [("narr", "石阶下有人披着旧红袍，一枪横在膝上。是谢无咎。", "At the foot of the steps a man in an old red robe sits with a spear across his knees. It is Xie Wujiu."),
            ("xie", "「说好了，擂台上见别手软。」他站起来，枪尖指地，「来吧。」", "\"As agreed, no holding back when we meet on a platform.\" He rises, spear point to the ground. \"Come.\"")],
    "xia": [("narr", "亭廊的檐上蹲着一个灰紫色的影子，匕首在指间转。是夏芷。", "On the pavilion eaves crouches a grey-violet shadow, a dagger turning between her fingers. It is Xia Zhi."),
            ("xia", "「我说过，下次不留情。」她跳下来，没有看你的眼睛。", "\"I said next time I would not hold back.\" She drops down without meeting your eyes.")],
    "su": [("narr", "市集般的人潮里，有一段熟悉的琵琶声，唱的却是一首新曲。是苏黛。", "From the market-like crowd comes a familiar pipa, but the song is a new one. It is Su Dai."),
           ("su", "「我写了新曲，」她停了弦，「先说好，听完了，也要打一场。」", "\"I wrote a new song,\" she says, stilling the strings. \"Fair warning: when you have heard it we fight.\"")],
    "li": [("narr", "台下的铁匠铺里，传来熟悉的锤声。厉山站在炉前，身边是一排新刀。", "From the smithy below the platform comes a familiar hammering. Li Shan stands at the furnace beside a row of new blades."),
           ("li", "「刀是替别人打的。」他抬起头，「你要拦，就先过我这一关。」", "\"The blades were made for others.\" He looks up. \"If you would stop them, get past me first.\"")],
    "xiao": [("narr", "山道上走来一个只背着旧刀的人，没有甲。是萧寒川。", "A man comes up the road carrying only an old sabre and no armour. It is Xiao Hanchuan."),
             ("xiao", "「我欠的债，还没还完。」他站定，「但今天，我想先和你过一次招。」", "\"My debt is not yet paid.\" He stops. \"But today I want to cross blades with you once.\"")],
    "none": [("narr", "石阶上没有人拦你。同行过的人，要么站在你身边，要么早已走远。", "Nobody bars the steps. Those who walked with you either stand beside you or are long gone."),
             ("hero", "这样也好。心里反倒清静。", "That is fine. My mind is the clearer for it.")]},
    [("xie_returns", "xie"), ("xia_returns", "xia"), ("su_returns", "su"), ("li_returns", "li"), ("xiao_returns", "xiao"), (None, "none")], ("故人", "An Old Companion"), (172, 176),
    {"none": [FLAG("returned_none"), ATTR("spirit", 1)]},
    choices={k: [("face", "接下这一战", "Accept the fight", [BATTLE("y3_returned"), FLAG("returned_faced")]),
                 ("speak", "放下兵器，说几句话", "Lower my weapon and speak", [FLAG("returned_spared"), ATTR("spirit", 2)])] for k in ["xie", "xia", "su", "li", "xiao"]},
    priority=7, requires={"week_min": 171}, on_miss=[FLAG("returned_none")])

event("y3d_solstice", "fixed", "pg_pavilions",
      [("narr", "论剑台上的冬至，没有人放爆竹。亭廊里只有一口大锅，热汤的白气升到檐下。", "On the platform's Winter Solstice nobody sets off firecrackers. In the pavilions one great pot sends white steam up to the eaves."),
       ("narr", "你把第一碗热汤递给了谁？", "To whom do you pass the first bowl of hot soup?")],
      title=("台上冬至", "Solstice on the Platform"), window=(173, 174), priority=7, requires={"week_min": 173},
      choices=[("valley", "谷里的老朋友：沈青禾、陆沉舟、白砚", "The old friends: Shen, Lu and Bai", [BOND("shen_qinghe", 2), BOND("lu_chenzhou", 2), BOND("bai_yan", 2), STAMINA(8)]),
               ("fighters", "并肩的战友：谢无咎、厉山、萧寒川", "The comrades: Xie, Li and Xiao", [BOND("xie_wujiu", 2), BOND("li_shan", 2), BOND("xiao_hanchuan", 2), STAMINA(8)]),
               ("street", "街头的同路人：苏黛、夏芷", "The street companions: Su Dai and Xia Zhi", [BOND("su_dai", 2), BOND("xia_zhi", 2), STAMINA(8)]),
               ("all", "一锅汤，一人一碗", "One pot, one bowl for everyone", [ATTR("spirit", 2), STAMINA(8), FLAG("solstice3_together")])],
      on_miss=[FLAG("solstice3_missed")])

event("y3d_gate_raid", "fixed", "pg_steps",
      [("narr", "半夜，石阶下的火把一排排熄灭。灰衣人从四面的山坡涌上来，刀光贴着地面，一直压到各家的席棚。", "At midnight the torches below the steps go out row by row. Grey-clad men pour up the slopes from every side, blades low, pressing on the houses' awnings."),
       ("hero", "他们不要论剑台，他们要一场乱子。", "They do not want the platform. They want chaos.")],
      title=("夜袭论剑台", "The Night Raid"), window=(174, 176), priority=8, requires={"week_min": 171},
      choices=[("defend", "守住石阶", "Hold the steps", [BATTLE("y3_platform_raid")]),
               ("evacuate", "先护着各家宾客撤下山", "Cover the guests' retreat first", [FLAG("raid_evacuated"), ATTR("spirit", 2)])],
      on_miss=[FLAG("raid_ignored")])

event("y3d_masks", "fixed", "pg_platform",
      [("narr", "火光里，三个戴面具的人登上了空无一人的论剑台。", "In the firelight three masked figures step onto the empty platform."),
       ("xuan", "「这场聚会，原本是两百年前的一次重写。」玄面站在石柱之间，「今天，换一次。」", "\"This gathering was once, two hundred years ago, a rewriting,\" the Xuan-Mask says among the pillars. \"Today it is another's turn.\""),
       ("chi", "「废话少说。」赤面笑着拔剑，「打赢的人说话。」", "\"Enough talk,\" the Chi-Mask grins, drawing his sword. \"The winner speaks.\""),
       ("hui", "灰面退到石柱后，轻轻说：「我不会拦你。」", "The Hui-Mask steps back behind a pillar and says softly, \"I will not stop you.\"")],
      title=("三面登台", "The Masks Take the Platform"), window=(175, 177), priority=8, requires={"week_min": 171},
      choices=[("fight", "拔剑迎战", "Draw and fight", [BATTLE("y3_masks"), FLAG("masks_fought")]),
               ("talk", "放下兵器，听玄面把话说完", "Lower my weapon and let the Xuan-Mask finish", [FLAG("masks_parley"), ATTR("insight", 2)], {"flag": "offer_xuan"})],
      on_miss=[FLAG("masks_fought")])

event("y3d_the_choice", "fixed", "pg_platform",
      [("narr", "天亮了。台下九家，所有的目光都落在你身上。玉契残卷、盟主令、三面留下的面具，都摆在台上。", "Dawn. Below the platform the nine houses fix their eyes on you. The Accord fragments, the Head's token and the Masks' fallen masks all lie on the stone."),
       ("lei", "雷震岳把盟主令推到你面前：「接，不接，毁，都是你的事。这一回，没有人替你定。」", "Lei Zhenyue pushes the Head's token towards you. \"Take it, refuse it or break it; it is yours to decide. This time no one decides for you.\""),
       ("hero", "想了三年的事，真到了这一刻，反而很静。", "After three years of thinking, now it has come, I find it quiet.")],
      title=("最后的抉择", "The Choice"), window=(177, 178), priority=9, requires={"week_min": 171},
      choices=[("seat", "接下盟主令", "Take the Head's token", [FLAG("finale_seat"), FLAG("finale_decided")]),
               ("refuse", "辞去这一席，回玉谷", "Refuse the seat and go home to the valley", [FLAG("finale_refuse"), FLAG("finale_decided")]),
               ("break", "毁掉残卷，重新开始", "Destroy the manual and begin again", [FLAG("finale_break"), FLAG("finale_decided")]),
               ("gate", "握住玄面的手，接下无相门", "Take the Xuan-Mask's hand and the Gate", [FLAG("finale_gate"), FLAG("finale_decided")], {"flag": "offer_xuan"}),
               ("walk", "放下一切，一个人上路", "Put it all down and take the road alone", [FLAG("finale_walk"), FLAG("finale_decided")])],
      on_miss=[FLAG("finale_walk"), FLAG("finale_decided")])

branch_event("y3d_ending", "fixed", "pg_platform", {
    "seat": [("narr", "盟主令落在你掌心，比想象的轻。九家的旗在你身后同时升起。", "The Head's token settles in your palm, lighter than imagined. The nine houses' banners rise together behind you."),
             ("lei", "雷震岳笑了一声，很轻：「好，这一担子，终于有人接了。」", "Lei Zhenyue gives a soft laugh. \"Good. At last someone shoulders it.\"")],
    "refuse": [("narr", "你把令牌放回案上，向九家一揖，转身下了台阶。身后的人群安静了很久，然后才响起议论声。", "You set the token back on the table, bow to the nine houses and go down the steps. The crowd behind you is silent a long while before the murmuring begins."),
               ("hero", "玉谷的竹子，该修剪了。", "The bamboo in the valley needs trimming.")],
    "break": [("narr", "残卷在火盆里一页页卷起来。灰烬飘过石柱，飘过九家的旗，没有人出声阻止。", "The fragments curl page by page in the brazier. Ash drifts past the pillars and the banners, and nobody speaks to stop it."),
              ("hui", "灰面不知何时站到你身边：「两百年的重写，到这里为止。」", "The Hui-Mask has come to stand beside you. \"Two centuries of rewriting end here.\"")],
    "gate": [("narr", "玄面的手很凉。无相门的灰旗，在论剑台的南角，悄悄升了起来。", "The Xuan-Mask's hand is cold. The Gate's grey banner is quietly raised at the platform's south corner."),
             ("xuan", "「从今往后，天下无人需要争执。」他的声音平静得近乎温和。", "\"From now on nobody in the realm need quarrel,\" he says, so calm as to be almost gentle.")],
    "walk": [("narr", "你没有接任何东西，只把行囊背在肩上，在晨光里走下石阶。", "You take nothing, shoulder your pack, and walk down the steps in the morning light."),
             ("hero", "路很长，我才刚刚开始走。", "The road is long and I have only begun.")]},
    [("finale_seat", "seat"), ("finale_refuse", "refuse"), ("finale_break", "break"), ("finale_gate", "gate"), (None, "walk")], ("尘埃落定", "The Dust Settles"), (178, 179),
    {k: [FLAG("finale_done")] for k in ["seat", "refuse", "break", "gate", "walk"]},
    priority=9, requires={"week_min": 171, "flags_all": ["finale_decided"]}, on_miss=[FLAG("finale_done")])

# ---- random templates
RANDOM = [
 ("ry12_platform_stones", "pg_platform", [("narr", "你绕着论剑台走了一圈，九根石柱上的名号，每一个你都认得了。", "You walk once around the platform and know every house's name carved on the nine pillars.")], [ATTR("insight", 1)], ("九根石柱", "The Nine Pillars"), 3, 6),
 ("ry12_steps_crowd", "pg_steps", [("narr", "石阶上人挤人，有人认出了你，窃窃地叫着你的名字。", "The steps are packed, and some recognise you and whisper your name.")], [ATTR("spirit", 1)], ("认出你的人", "Those Who Recognise You"), 3, 6),
 ("ry12_pavilion_envoys", "pg_pavilions", [("narr", "亭廊里各家的使者互相拜访，茶一盏接一盏，话却没说几句。", "Envoys visit one another in the pavilions, cup after cup of tea and few words said.")], [ATTR("insight", 1)], ("使者往来", "Envoys Calling"), 3, 6),
 ("ry12_courts_final", "cw_courts", [("narr", "演武场上，各派弟子最后一次合练，喊声整齐，像一个人在喊。", "On the courts disciples of every sect drill together a last time, shouting as one.")], [ATTR("power", 1)], ("最后的合练", "A Last Drill"), 3, 8),
 ("ry12_valley_wait", "valley_village", [("narr", "阿福在村口挂了一盏灯，说是给论剑台上的你照路。", "A-Fu hangs a lamp at the village gate, saying it is to light your road at the platform.")], [ATTR("spirit", 1), STAMINA(8)], ("村口的灯", "The Lamp at the Gate"), 3, 6),
 ("ry12_teahouse_bets", "lj_teahouse", [("narr", "茶楼的赌局停了。没有人再押，大家都想看真的结果。", "The teahouse bets have stopped. Nobody wagers any more; everyone wants to see the truth.")], [ATTR("insight", 1)], ("停了的赌局", "The Bets Stop"), 3, 6),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y12)

# ===================================================================== BATTLES
units["units"].append({"id": "xuan_mask", "stats": {"hp": 300, "body": 16, "power": 20, "agility": 13, "spirit": 20}, "techniques": ["club_smash"]})
L("combat.unit.xuan_mask", "玄面", "The Xuan-Mask")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10, terrain=None):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": terrain or [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y3_bracket", "擂台比试", "The Bracket", "在擂台上击败各家推出的弟子。", "Defeat the fighters each house sends onto the stage.", ["cangwu_senior", "cangwu_disciple", "cangwu_disciple", "gate_blade"],
         [RES("coins", 60)], ["bracket_won"], ["bracket_lost"], 12)
scenario("y3_returned", "故人拦路", "An Old Companion Bars the Way", "击败拦路的故人与她的帮手。", "Beat the old companion and the helpers who stand with them.", ["gate_captain", "gate_elite", "gate_blade"],
         [RES("coins", 40)], ["returned_won"], ["returned_lost"], 12)
scenario("y3_platform_raid", "夜袭论剑台", "The Night Raid", "守住石阶，击退灰衣人。", "Hold the steps and drive off the grey raiders.",
         ["gate_captain", "gate_elite", "gate_blade", "gate_blade", "yanmen_raider", "sea_raider"], [RES("coins", 70)], ["raid_held"], ["raid_ignored"], 14,
         [[1, 3, "cover"], [4, 3, "cover"], [0, 2, "hazard"], [5, 2, "hazard"], [3, 4, "hazard"]])
scenario("y3_masks", "三面登台", "The Masks on the Platform", "击败玄面与赤面。", "Defeat the Xuan-Mask and the Chi-Mask.", ["xuan_mask", "chi_mask", "gate_blade"],
         [RES("coins", 100), RES("ore", 3)], ["masks_won"], ["masks_lost"], 16, [[2, 2, "hazard"], [4, 2, "hazard"], [1, 3, "cover"], [4, 4, "cover"]])

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs); dump("combat/scenarios.json", scen); dump("combat/units.json", units)
dump("companions/arcs.json", arcs)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events")
