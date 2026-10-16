#!/usr/bin/env python3
"""M25b: Year 3 quarter 10 (The Nine Stars Gather, weeks 136 to 150): the sunken vault, the stars of the companions, the second gate, the Xuan-Mask,
the ninth star, the collapse, and stage 4 for Su Dai, Li Shan and Xiao Hanchuan. Run AFTER gen_year3_q9. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

areas = load("world/areas.json"); events = load("world/events.json"); dlgs = load("world/event_dialogues.json")
scen = load("combat/scenarios.json"); units = load("combat/units.json"); arcs = load("companions/arcs.json"); looks = load("story/looks.json")

OWN_AREAS = ["sv_stair", "sv_hall", "sv_door"]
areas["areas"] = [a for a in areas["areas"] if a["id"] not in OWN_AREAS]
PREFIX = ("y3b_", "ry10_", "arc_su_dai_4", "arc_li_shan_4", "arc_xiao_hanchuan_4")
events["events"] = [e for e in events["events"] if not e["id"].startswith(PREFIX)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"][3:].startswith(PREFIX)]
NEW_SC = ["y3_vault_guardian", "y3_vault_collapse"]
scen["scenarios"] = [s for s in scen["scenarios"] if s["id"] not in NEW_SC]
units["units"] = [u for u in units["units"] if u["id"] not in ["vault_guardian"]]
looks["looks"] = [l for l in looks["looks"] if l["id"] != "mask_xuan"]
looks["looks"].append({"id": "mask_xuan", "gender": "m", "hair": 2, "hair_hex": "5a5a60", "outfit_hex": "2a3a5a", "skin_hex": "d8b898", "weapon": ""})
for a in arcs["arcs"]:
    if a["companion"] in ("su_dai", "li_shan", "xiao_hanchuan"):
        a["stages"] = [s for s in a["stages"] if s["id"] != "4"]

SPK = {"narr": "world.speaker.narrator", "hero": "world.speaker.hero", "wander": "world.speaker.wanderer", "elder": "story.speaker.elder", "xia": "npc.xia_zhi",
       "xiao": "npc.xiao_hanchuan", "xie": "npc.xie_wujiu", "chi": "npc.mask_chi", "qian": "npc.qian_man", "afu": "npc.villager_afu", "gu": "npc.master_gu", "hui": "npc.mask_hui", "xuan": "npc.mask_xuan", "su": "npc.su_dai", "li": "npc.li_shan", "bai": "npc.bai_yan"}
WHO = {"wander": "wanderer", "elder": "elder", "xia": "xia_zhi", "xiao": "xiao_hanchuan", "xie": "xie_wujiu", "chi": "mask_chi", "qian": "qian_man", "afu": "villager",
       "gu": "master_gu", "hui": "mask_hui", "xuan": "mask_xuan", "su": "su_dai", "li": "li_shan", "bai": "bai_yan"}
L("npc.mask_xuan", "玄面", "The Xuan-Mask")
BG = {"sv_stair": "vault_stair", "sv_hall": "vault_hall", "sv_door": "vault_hall", "lj_teahouse": "city_market", "lj_market": "city_market", "lj_docks": "city_docks", "lj_alleys": "city_night", "cw_courts": "cangwu_day", "ym_fort": "yanmen_fort",
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
Y10 = {"week_min": 136}


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
    a = {"id": id, "region": "marsh", "name_key": f"world.area.{id}.name", "desc_key": f"world.area.{id}.desc", "cost": 2, "wander": [],
         "open_default": True, "requires": {"lead": ["vault_second_gate"], "week_min": 136}}
    L(a["name_key"], zn, en_); L(a["desc_key"], dz, de)
    for i, (z, e, rw) in enumerate(wanders):
        k = f"world.area.{id}.w{i+1}"; L(k, z, e); a["wander"].append({"text_key": k, "rewards": [{"type": t, "id": r, "amount": n} for t, r, n in rw]})
    a.update(kw); areas["areas"].append(a)


# ===================================================================== AREAS
area("sv_stair", "地宫石阶", "The Vault Stair", "沉星泽下的石阶向黑暗里延伸，两侧的石壁刻满了看不懂的星图。", "A stone stair runs down under the marsh into the dark, its walls carved with star charts you cannot read.",
     [("石壁上的刻痕里嵌着一小块碎玉。", "A small chip of jade lies in a groove in the wall.", [("resource", "coins", 12)]), ("你在台阶上静坐，默记星图的走向。", "You sit on the steps and learn the chart's pattern by heart.", [("attr", "insight", 1)])])
area("sv_hall", "星宿大厅", "The Star Hall", "圆形大厅的穹顶嵌着九颗暗淡的星石，只有七颗还亮着。", "Nine star stones are set in the round hall's dome and only seven still glow.",
     [("你在星石下打坐，气息渐渐与地宫同步。", "You meditate beneath the star stones until your breath matches the vault's.", [("attr", "spirit", 1)]), ("大厅角落有一块掉落的矿石。", "A fallen lump of ore lies in a corner of the hall.", [("resource", "ore", 1)])],
     requires={"lead": ["vault_second_gate"], "week_min": 136, "flags_all": ["second_gate_open"]})
area("sv_door", "玉符之门", "The Tally Door", "大厅尽头是一道没有把手的玉门，门上有半块玉符的凹槽。", "At the end of the hall stands a jade door with no handle and a groove shaped like half a tally.",
     [("你伸手按在玉门上，门里传来极轻的回响。", "You press a hand to the jade door and a faint echo answers.", [("attr", "insight", 1)]), ("门缝里夹着一枚旧铜钱。", "An old copper coin is wedged in the door seam.", [("resource", "coins", 15)])],
     requires={"lead": ["vault_second_gate"], "week_min": 136, "flags_all": ["second_gate_open"]})

# ===================================================================== STORY
event("y3b_fragments", "fixed", "lj_teahouse",
      [("narr", "桌上摊开了九片星图的拓本。第一颗，藏在漕帮的旧账里；第二颗，在蓬岛的珊瑚洞。", "Rubbings of the nine stars lie spread across the table. The first hid in the Barge Guild's old ledgers, the second in Penglai's coral cave."),
       ("bai", "白砚推了推书页：「剩下的星，要靠你身边人的故事去找。苏黛的歌，厉山的炉印，还有我这几年读出来的那一套暗纹。」", "Bai Yan nudges a page. \"The rest must be found through the stories of those near you: Su Dai's song, Li Shan's forge mark, and the pattern I have read out of the dark script these years.\""),
       ("hero", "好。先从人开始找，再去地宫。", "Good. Start with people, then go to the vault.")],
      [FLAG("fragments_counted"), ATTR("insight", 1)], title=("星的清点", "Counting the Stars"), window=(136, 140), priority=7, requires=Y10, on_miss=[FLAG("fragments_counted")])
event("y3b_star_song", "fixed", "lj_market",
      [("su", "「最后一段谱子，我今天终于唱对了。」苏黛拨了一下琵琶，「你听，每个音，都落在一颗星的位置上。」", "\"I finally sang the last verse right today,\" Su Dai says, plucking her pipa. \"Listen: every note lands on a star's place.\""),
       ("narr", "琵琶声停下时，地图上的第三颗星亮了。", "When the pipa falls silent, the third star lights on the map.")],
      [FLAG("star_song"), ATTR("spirit", 2), BOND("su_dai", 2)], title=("歌里的星", "The Star in the Song"), window=(138, 148), priority=6,
      requires={"week_min": 136, "bond_min": {"su_dai": 8}, "flags_none": ["song_sold"]})
event("y3b_star_forge", "fixed", "lj_docks",
      [("li", "「炉底下有一块旧铁。」厉山把一块黑沉沉的铁板放到你手里，「上头的纹，和你给我看的星图一样。」", "\"There was an old iron slab under the furnace,\" Li Shan says, setting a dark plate in your hand. \"Its pattern matches the star chart you showed me.\""),
       ("narr", "铁板冰凉，纹路里藏着第四颗星的位置。", "The plate is cold, and in its grain lies the fourth star's place.")],
      [FLAG("star_forge"), ATTR("power", 2), BOND("li_shan", 2)], title=("炉底的星", "The Star Under the Furnace"), window=(138, 148), priority=6,
      requires={"week_min": 136, "bond_min": {"li_shan": 8}, "flags_none": ["forge_gold"]})
event("y3b_star_pattern", "fixed", "cw_library",
      [("bai", "「暗纹读通了。」白砚的眼睛里全是血丝，却在笑，「这一套暗纹，就是第五颗星的钥匙。」", "\"The dark script reads through,\" Bai Yan says, eyes red with strain yet smiling. \"This pattern is the fifth star's key.\""),
       ("narr", "他把一整册批注推到你面前，扉页只有一个字：星。", "He pushes a whole volume of notes across to you. The flyleaf bears a single word: star.")],
      [FLAG("star_pattern"), ATTR("insight", 2), BOND("bai_yan", 2)], title=("暗纹里的星", "The Star in the Script"), window=(138, 148), priority=6,
      requires={"week_min": 136, "bond_min": {"bai_yan": 8}})

event("y3b_second_gate", "fixed", "sv_stair",
      [("narr", "石阶的尽头，一道石门拦住了去路。门上有两个凹槽，一个形如半块玉符，一个空着。", "At the stair's end a stone door bars the way. It carries two grooves, one shaped like half a tally, the other empty."),
       ("hero", "我怀里的这半块玉符，该嵌在哪一边？", "Which groove does the half-tally in my robe belong to?"),
       ("narr", "石门后传来一声沉重的呼吸。门里，有东西醒了。", "A heavy breath sounds behind the door. Something inside has woken.")],
      title=("第二道门", "The Second Gate"), window=(138, 144), priority=7, requires={"week_min": 136},
      choices=[("tally", "把玉符嵌进去", "Fit the tally into the groove", [FLAG("second_gate_open"), FLAG("vault_tally_used"), ATTR("insight", 2)]),
               ("force", "不信这门，强行破开", "Break the door by force", [BATTLE("y3_vault_guardian"), FLAG("vault_forced")])],
      on_miss=[FLAG("second_gate_open")])
event("y3b_xuan_mask", "fixed", "sv_hall",
      [("narr", "星宿大厅里，一个穿深蓝长衫的男子正仰头看着穹顶的星石。他脸上的面具只遮住了鼻梁以上。", "In the Star Hall a man in a deep blue gown gazes up at the dome's stones. His mask covers only the part above the nose."),
       ("xuan", "「第九块星石已经暗了。」他没有回头，「乱世出玉契，玉契又乱世。你以为，是谁在维持这个循环？」", "\"The ninth star stone has gone dark,\" he says without turning. \"The Accord was born of chaos and breeds chaos in turn. Who do you think keeps the cycle going?\""),
       ("xuan", "「与我共掌这部残卷，天下可以安静三百年。你，愿意吗？」", "\"Hold this manual with me and the realm can be quiet for three hundred years. Will you?\"")],
      title=("玄面的邀请", "The Xuan-Mask's Offer"), window=(142, 148), priority=7, requires=Y10,
      choices=[("accept", "听他说完，点头", "Hear him out and nod", [FLAG("xuan_pact"), ATTR("insight", 2)]),
               ("refuse", "我不与你共事", "I will not work with you", [FLAG("xuan_refused"), ATTR("spirit", 2)]),
               ("deceive", "假意应下，看他要什么", "Pretend to agree and see what he wants", [FLAG("xuan_deceived"), ATTR("agility", 2), ATTR("insight", 1)])],
      on_miss=[FLAG("xuan_refused")])
event("y3b_ninth_star", "fixed", "sv_door",
      [("narr", "玉门应着半块玉符缓缓开启。门后只有一块石台，台上放着第九片残卷，纸页发黄却不见一丝尘。", "The jade door opens slowly to the half-tally. Beyond lies only a stone dais bearing the ninth fragment, its pages yellow yet free of any dust."),
       ("hui", "灰面不知什么时候站在了门边：「你读到的，是怎么重写玉契。可玉契写下来的那天，也同样是一次重写。」", "The Hui-Mask has appeared by the doorway. \"What you read is how to rewrite the Accord. But the day the Accord was written was also a rewriting.\""),
       ("hui", "「我曾替他们抄过无数份。现在，我想看看你会怎么抄。」", "\"I copied it for them countless times. Now I want to see how you would copy it.\"")],
      [FLAG("ninth_star_read"), LEAD("manual_truth"), ATTR("insight", 2), ATTR("spirit", 2)], title=("第九片残卷", "The Ninth Fragment"), window=(144, 150), priority=8, requires=Y10,
      on_miss=[FLAG("ninth_star_read"), LEAD("manual_truth")])
event("y3b_vault_collapse", "fixed", "sv_door",
      [("narr", "大厅的穹顶发出一声闷响。九颗星石一颗接一颗熄灭，灰衣人从来路涌了下来。", "The dome gives a dull crack. The nine star stones go out one after another and grey-clad men pour down the way you came."),
       ("hero", "门后的东西不能落到他们手里。", "What lies behind the door must not fall into their hands.")],
      title=("地宫将塌", "The Vault Collapses"), window=(146, 150), priority=8, requires=Y10,
      choices=[("hold", "守住玉门", "Hold the jade door", [BATTLE("y3_vault_collapse")]),
               ("run", "带着残卷撤退", "Carry the fragment out", [FLAG("star_lost"), ATTR("agility", 2)])],
      on_miss=[FLAG("star_lost")])

# ---- stage 4: Su Dai, Li Shan, Xiao Hanchuan
stage4("su_dai", "lj_market", (138, 150),
       [("narr", "集市口，孩子们跟着苏黛的琵琶声唱那首古歌。路人停下脚步，一个跟着一个轻轻地和。", "At the market gate children sing the old song to Su Dai's pipa. Passers-by stop, one by one, humming along softly."),
        ("su", "「它不是我一个人的了。」她的手指还在弦上，「这样也好，它终于有了很多人记着。」", "\"It is not only mine anymore,\" she says, fingers still on the strings. \"That is fine. At last many people remember it.\"")],
       [("narr", "夜深了，茶楼只剩一盏灯。苏黛抱着琵琶，只给你一个人唱了那首歌。", "Late at night only one lamp burns in the teahouse. Su Dai holds her pipa and sings the song for you alone."),
        ("su", "「谱子还在我这儿，谁也别想拿走。」她笑了，「你要保管的，是我的这份信任。」", "\"The score stays with me and nobody takes it.\" She smiles. \"What you keep is this trust of mine.\"")],
       [("narr", "集市的茶摊前，苏黛把琵琶背上肩，没有看你。", "At the market tea stall Su Dai slings her pipa over her shoulder without looking at you."),
        ("su", "「那首歌，卖了就是卖了。」她的声音很轻，「我再写一首新的。下次有人问，我会唱给他们听。」", "\"A song sold is a song sold,\" she says quietly. \"I will write a new one. When people next ask, I will sing it to them.\"")],
       {"who": "su", "zh": "「喂，别板着脸。」她把一缕碎发别到耳后，「你想做我的什么人？」", "en": "\"Hey, don't scowl.\" She tucks a loose strand behind her ear. \"What would you be to me?\"", "title": ("集市的歌", "The Song of the Market")}, "su_returns")
stage4("li_shan", "lj_docks", (134, 146),
       [("narr", "码头边的新炉子点着了。厉山一锤一锤地敲着，火星溅在围裙上，像一把碎星。", "The new furnace by the docks is lit. Li Shan hammers stroke by stroke, sparks scattering on his apron like crushed stars."),
        ("li", "「炉子是我们一起垒的。」他放下锤子，「以后每一件出炉的东西，都有你的一份。」", "\"We built the furnace together,\" he says, setting down the hammer. \"Every piece that leaves it will carry a share of you.\"")],
       [("narr", "码头旁的小摊子，炉火不旺，却很稳。厉山一边敲着铁，一边慢慢地说话。", "At the small stall by the docks the fire burns low but steady. Li Shan talks slowly as he hammers."),
        ("li", "「慢，也好。」他抬眼，「手艺是熬出来的，朋友也是。」", "\"Slow is fine,\" he says, looking up. \"Craft is something you simmer, and so are friends.\"")],
       [("narr", "新炉子点着，却不是你认识的那种火。厉山站在炉前，没有抬头。", "The new furnace is lit but the fire is not the kind you knew. Li Shan stands before it without raising his head."),
        ("li", "「刀是替别人打的。」他的声音很沉，「我不求你原谅。路，各走各的吧。」", "\"The blades are being forged for others,\" he says heavily. \"I do not ask forgiveness. Let us each walk our own road.\"")],
       {"who": "li", "zh": "「……你想，和我做什么人？」他不好意思地挠挠头，「我嘴笨，你说。」", "en": "\"...What would you want to be to me?\" He scratches his head, embarrassed. \"I am clumsy with words. You say it.\"", "title": ("炉边", "By the Furnace")}, "li_returns")
stage4("xiao_hanchuan", "ym_fort", (140, 152),
       [("narr", "雁门城头的号角换了新调。萧寒川站在城墙上，披着守军统领的黑银甲。", "A new tune sounds from Yanmen's horns. Xiao Hanchuan stands on the wall in the black-and-silver armour of the garrison's commander."),
        ("xiao", "「从今往后，没有什么令，需要我背对百姓。」他看向你，「这是你教我的。」", "\"From now on no order will have me turn my back on the people,\" he says, looking at you. \"You taught me that.\"")],
       [("narr", "雁门城的校场边，萧寒川把一份批了一半的上书折好收进怀里。", "At the edge of Yanmen's drill ground Xiao Hanchuan folds half-approved petition and tucks it into his coat."),
        ("xiao", "「半份，也是一份。」他的语气比从前松了一些，「剩下的，慢慢争。」", "\"Half is still a half,\" he says, his tone looser than before. \"The rest we shall argue for slowly.\"")],
       [("narr", "雁门城外的雪野上，萧寒川卸下了银甲，只背着那把旧刀。", "On the snow fields outside Yanmen Xiao Hanchuan has taken off his silver armour and carries only his old sabre."),
        ("xiao", "「令保住了，人没保住。」他向你一礼，「这笔账，我自己去还。」", "\"The order was kept and the people were not,\" he says, bowing to you. \"That debt I will go and pay myself.\"")],
       {"who": "xiao", "zh": "「有一件事，我想听你亲口说。」他站直了身子，「你想做我的什么人？」", "en": "\"There is one thing I want to hear from your own mouth.\" He straightens. \"What would you be to me?\"", "title": ("城头的号角", "The Horns on the Wall")}, "xiao_returns")

# ---- random templates
RANDOM = [
 ("ry10_stair_echo", "sv_stair", [("narr", "石阶深处传来一阵极轻的回响，像有人在远处翻动书页。", "A faint echo comes from deep along the stair, like someone far off turning pages.")], [ATTR("insight", 1)], ("石阶回响", "Echoes on the Stair"), 3, 6),
 ("ry10_hall_glow", "sv_hall", [("narr", "穹顶的七颗星石忽明忽暗，像在呼吸。你屏息看了很久。", "The dome's seven stones brighten and dim as if breathing. You watch them a long while, holding your breath.")], [ATTR("spirit", 1)], ("星石呼吸", "The Stones Breathe"), 3, 6),
 ("ry10_door_cold", "sv_door", [("narr", "玉门上渗着一层寒气，指尖按上去，像按在冬天的湖面上。", "A chill seeps from the jade door and your fingertip feels as if pressed to a winter lake.")], [ATTR("body", 1)], ("玉门寒气", "The Door's Chill"), 3, 6),
 ("ry10_valley_gift", "valley_village", [("narr", "阿福托人带来一篮新笋，说是论剑台前，让你养足精神。", "A-Fu sends a basket of new bamboo shoots, saying you should be well rested before the platform.")], [ATTR("body", 1), STAMINA(8)], ("新笋", "New Shoots"), 3, 6),
 ("ry10_market_stars", "lj_market", [("wander", "摊贩说近来夜里总有人在街头画星图，也不知画给谁看。", "A vendor says someone has been drawing star charts on the street at night, for who knows whom.")], [ATTR("insight", 1)], ("街头星图", "Star Charts in the Street"), 3, 8),
 ("ry10_courts_clash", "cw_courts", [("narr", "演武场上，两派弟子因论剑台的席位吵了起来，最后被师兄拉开。", "On the courts two sets of disciples quarrel over platform seats until a senior pulls them apart.")], [ATTR("power", 1)], ("为席位争吵", "Quarrel over Seats"), 3, 8),
 ("ry10_docks_quiet", "lj_docks", [("narr", "漕帮的船今天比往常少了一半，码头安静得有些不对劲。", "Half the guild's boats are missing today, and the docks are strangely quiet.")], [ATTR("agility", 1)], ("安静的码头", "The Quiet Docks"), 3, 6),
 ("ry10_fort_news", "ym_fort", [("narr", "城头的老兵说，今年北风来得晚，雁门的雪，怕是要在论剑台之后才下。", "An old soldier on the wall says the north wind came late this year and Yanmen's snow will likely fall only after the platform gathering.")], [ATTR("spirit", 1)], ("北风", "The North Wind"), 3, 8),
]
for id, ar, lines, eff, title, wt, cd in RANDOM:
    event(id, "random", ar, lines, eff, title=title, weight=wt, cooldown=cd, requires=Y10)

# ===================================================================== BATTLES
units["units"].append({"id": "vault_guardian", "stats": {"hp": 320, "body": 17, "power": 19, "agility": 8, "spirit": 12}, "techniques": ["club_smash"]})
L("combat.unit.vault_guardian", "地宫守卫", "Vault Guardian")
CELLS = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [2, 0]]
def scenario(id, zn, en_, oz, oe, enemies, win, fw, fl, rounds=10, terrain=None):
    scen["scenarios"].append({"id": id, "battle_id": id, "max_rounds": rounds, "terrain": terrain or [[1, 3, "cover"], [4, 3, "cover"], [3, 4, "hazard"]],
        "player_cells": [[2, 6], [3, 6], [1, 6]], "enemies": [{"template": t, "cells": [CELLS[i]]} for i, t in enumerate(enemies)], "objective": {"defeat_all": True},
        "on_victory": {"rewards": win + [{"type": "relationship", "id": "$active", "amount": 1}], "flags": fw},
        "on_defeat": {"rewards": [{"type": "stamina", "id": "stamina", "amount": -3}], "flags": fl}})
    L("combat.scenario." + id, zn, en_); L("combat.scenario." + id + ".objective", oz, oe); L("battle." + id, zn, en_)
scenario("y3_vault_guardian", "石门守卫", "The Door Guardian", "击败石门后苏醒的守卫。", "Defeat the guardian that woke behind the stone door.", ["vault_guardian", "gate_elite"],
         [RES("coins", 50), RES("ore", 2)], ["second_gate_open", "guardian_won"], ["second_gate_open", "guardian_lost"], 14)
scenario("y3_vault_collapse", "崩塌的地宫", "The Collapsing Vault", "守住玉门，击退涌入的灰衣人。", "Hold the jade door against the grey men flooding in.",
         ["gate_captain", "gate_elite", "gate_blade", "gate_blade", "yanmen_raider"], [RES("coins", 60)], ["star_kept"], ["star_lost"], 14,
         [[1, 3, "cover"], [4, 3, "cover"], [0, 2, "hazard"], [5, 2, "hazard"], [3, 4, "hazard"]])

LEADS = {"manual_truth": ("残卷的真相", "The Truth of the Manual", "九片残卷读完，它教的不是武功，而是怎样重写玉契。", "Read whole, the nine fragments teach not a martial art but how to rewrite the Accord.")}
for k, (zn, en_, dz, de) in LEADS.items():
    L(f"world.lead.{k}.name", zn, en_); L(f"world.lead.{k}.desc", dz, de)

dump("world/areas.json", areas); dump("world/events.json", events); dump("world/event_dialogues.json", dlgs); dump("combat/scenarios.json", scen); dump("combat/units.json", units)
dump("companions/arcs.json", arcs); dump("story/looks.json", looks)
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events")
