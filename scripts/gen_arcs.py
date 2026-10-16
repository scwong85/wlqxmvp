#!/usr/bin/env python3
"""M21: companion arcs for the three current companions (template for the other five).
Each arc is four world events: stage 1 (meet), stage 2 (trust), stage 3 (test, decides the outcome), and a closing
scene that fixes the relationship type. Run AFTER gen_world.py and gen_arts.py (it merges into their output)."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

events = load("world/events.json")
dlgs = load("world/event_dialogues.json")
OWN = ("arc_shen_qinghe_", "arc_lu_chenzhou_", "arc_bai_yan_")
events["events"] = [e for e in events["events"] if not e["id"].startswith(OWN)]
dlgs["dialogues"] = [d for d in dlgs["dialogues"] if not d["id"].startswith(tuple("ev_" + o for o in OWN))]

BG = {"river_bend": "riverside_day", "herb_terraces": "terraces_green", "ferry_dock": "ferry_dusk", "old_shrine": "shrine_night"}
OUTCOMES = {"redeemed": ("圆满", "Redeemed"), "alternate": ("另寻出路", "Another Way"), "lost": ("失之交臂", "Slipped Away")}
BONDS = {"friend": ("挚友", "Close Friend"), "sworn": ("结义", "Sworn Sibling"), "romance": ("情缘", "Romance"), "rival": ("宿敌", "Rival")}
BOND_NEED = {"friend": 10, "sworn": 14, "romance": 16, "rival": 6}

# (companion, area, [stage specs]) ; a stage: id, zh title, en title, bond_min, lines [(who, zh, en)], choices?
ARCS = {
 "shen_qinghe": {"area": "herb_terraces", "stages": [
  ("1", "药篓里的旧方", "The Old Prescription", 4,
   [("c", "沈青禾把一张泛黄的药方摊在药篓盖上，指尖停在最后一味药旁。「这是我师父病倒前最后开的方子。」", "Shen Qinghe spreads a yellowed prescription across the basket lid, a fingertip resting beside the last herb. \"My master wrote this just before falling ill.\""),
    ("c", "「方子没错。错的，是他喝的那碗药。」她抬眼看你，「你愿意帮我查吗？」", "\"The prescription is sound. The bowl he drank was not.\" She looks up. \"Will you help me find out?\""),
    ("h", "我点头：「需要我做什么，开口便是。」", "I nod. \"Whatever you need, just ask.\"")], None),
  ("2", "师父的病榻", "The Master's Sickbed", 8,
   [("n", "山腰的小屋里，药味苦得发涩。老人躺在榻上，呼吸浅得几乎看不见起伏。", "In the hillside cottage the medicine smells bitter and thick. The old man lies still, his breathing barely stirring the blanket."),
    ("c", "「药渣里有一味不该有的东西，」沈青禾低声说，「是盟约里才会用的秘药。」", "\"There is something in the dregs that should not be,\" Shen Qinghe says quietly. \"A secret medicine only the Accord uses.\""),
    ("h", "我帮她把药渣一点点分开，直到天色擦黑。", "I help her sort the dregs bit by bit until the light goes.")], None),
  ("3", "盟约的秘药", "The Accord's Secret Medicine", 12,
   [("c", "「秘药的来路我查到了。」沈青禾捏紧了衣角，「若公开，盟约不会放过我；若不说，师父就得不到解药。」", "\"I traced the secret medicine,\" Shen Qinghe says, twisting her sleeve. \"If I expose it, the Accord will hunt me. If I stay silent, my master gets no cure.\""),
    ("c", "「你说，我该怎么办？」", "\"Tell me. What should I do?\"")],
   [("open", "劝她公开真相", "Urge her to tell the truth", "redeemed", 10),
    ("quiet", "陪她暗中寻解药", "Help her find the cure in secret", "alternate", 6),
    ("leave", "劝她先保全自己，放手", "Tell her to protect herself and let go", "lost", -6)]),
  ("4", "月下药圃", "Moonlit Herb Beds", 6,
   [("n", "夜里的药圃静得能听见露水落地。沈青禾坐在田埂上，抬头望着月亮。", "The herb beds are so quiet at night that dew can be heard falling. Shen Qinghe sits on the ridge, looking up at the moon."),
    ("c", "「这一路，多谢你。」她笑了笑，「你想做我的什么人？」", "\"Thank you, for all of this,\" she smiles. \"What would you like to be to me?\"")], None)]},
 "lu_chenzhou": {"area": "river_bend", "stages": [
  ("1", "码头的无名信", "The Unsigned Letter", 4,
   [("n", "回龙湾渡口的石阶上，陆沉舟蹲着，手里捏着一封没有署名的信，神情少见地认真。", "On the ferry steps of the Bend, Lu Chenzhou crouches over an unsigned letter, unusually serious."),
    ("c", "「我是跑腿的，从不拆信。」他把信翻过来，「可这封信，寄信人的字迹我认得，他三年前就死了。」", "\"I'm a courier. I never open letters,\" he says, turning it over. \"But I know this handwriting, and the man died three years ago.\""),
    ("h", "我看着那封信：「那它是谁寄的？」", "I look at the letter. \"Then who sent it?\"")], None),
  ("2", "追信", "Chasing the Letter", 8,
   [("c", "「有人在抢这封信。」陆沉舟压低声音，「昨夜我的包袱被翻过，今天还有人跟着我。」", "\"Someone wants this letter,\" Lu Chenzhou says, keeping his voice low. \"My pack was searched last night, and today I was followed.\""),
    ("w", "「站住！把信交出来！」芦苇丛里窜出几个人影。", "\"Stop! Hand over the letter!\" Figures burst from the reeds.")],
   [("fight", "并肩迎战", "Fight beside him", "", 6), ("slip", "拉着他绕路甩开", "Pull him round a back path", "", 3)]),
  ("3", "信里的真相", "What the Letter Said", 12,
   [("c", "信拆开了。里面是一份账，证明渡口的一位大人物出卖了同伴。陆沉舟盯着它，久久没说话。", "The letter is open. Inside is a ledger proving a ferry-side bigwig sold out his comrades. Lu Chenzhou stares at it, silent."),
    ("c", "「有人出十倍价钱买它。」他低声说，「我这辈子没见过这么多钱。」", "\"Someone offered ten times my fee for it,\" he says softly. \"I have never seen so much money.\"")],
   [("deliver", "劝他把信交给能主持公道的人", "Urge him to give it to someone who will see justice done", "redeemed", 10),
    ("burn", "烧掉它，让两边都有台阶下", "Burn it, so both sides can step down", "alternate", 4),
    ("sell", "随他去，钱是实在的", "Let him go; the money is real", "lost", -6)]),
  ("4", "渡口夜话", "Night Talk at the Ferry", 6,
   [("n", "夜渡无人，灯笼在水面上晃出一道长长的光。", "The night ferry is empty, its lantern drawing a long streak of light on the water."),
    ("c", "「你问我，是想跟我做什么人？」陆沉舟挠了挠头，「我倒是都想过。」", "\"You ask what I'd like to be to you?\" Lu Chenzhou scratches his head. \"I've thought about all of it.\"")], None)]},
 "bai_yan": {"area": "old_shrine", "stages": [
  ("1", "断碑拓本", "Rubbings of the Broken Stele", 4,
   [("c", "白砚把一叠拓本摊在供桌上，墨香盖过了尘味。「这座碑上，刻的不是祭文，而是一部残卷。」", "Bai Yan lays a stack of rubbings on the altar, ink drowning the smell of dust. \"The stele does not hold prayers. It holds a fragment of a manual.\""),
    ("h", "「残卷？谁会把武学刻在庙碑上？」", "\"A manual? Who carves martial arts on a shrine stele?\""),
    ("c", "「想藏起来的人。」他推了推眼前的灯，「我想把它读完。」", "\"Someone who wanted it hidden.\" He nudges the lamp closer. \"I want to finish reading it.\"")], None),
  ("2", "拓本里的暗纹", "Hidden Marks in the Rubbings", 8,
   [("c", "「你看这里，」白砚指着字缝，「笔画之间还有一层暗纹，是另一种文字。」", "\"Look here,\" Bai Yan says, pointing between the strokes. \"Another script hides in the gaps.\""),
    ("h", "我们对着灯火，一笔一笔地描，直到灯油见底。", "We trace stroke by stroke beside the lamp until the oil runs dry.")], None),
  ("3", "知与险", "Knowledge and Danger", 12,
   [("c", "残卷读通了。它记的是一门足以让人失去理智的功法，也是盟约一直想要的东西。", "The fragment is read through. It records a technique that can unhinge a mind, the very thing the Accord has long sought."),
    ("c", "「公开它，会有人为它流血；毁掉它，这世上就少了一种可能。」白砚看着你，「你怎么看？」", "\"Publish it and people will bleed for it; destroy it and one possibility vanishes from the world.\" Bai Yan looks at you. \"What do you think?\"")],
   [("share", "劝他把前半卷公开，让人知道它的害处", "Urge him to publish the first half so people know its harm", "redeemed", 10),
    ("keep", "只留一份，由他亲自保管", "Keep one copy, in his own hands", "alternate", 6),
    ("burn", "劝他烧掉拓本", "Urge him to burn the rubbings", "lost", -6)]),
  ("4", "庙中灯", "Lamp in the Shrine", 6,
   [("n", "灯火安静地烧着，白砚正在整理最后一页笔记。", "The lamp burns quietly as Bai Yan sorts the last page of notes."),
    ("c", "「这些日子，你教会我一件事：有些东西，不必读懂才算数。」他抬起头，「你想跟我做什么人？」", "\"These days you taught me something: some things count without being understood.\" He looks up. \"What would you be to me?\"")], None)],
 },
}
SPK = lambda c, who: {"c": f"npc.{c}", "h": "world.speaker.hero", "n": "world.speaker.narrator", "w": "world.speaker.wanderer"}[who]
arcs = []
for cid, a in ARCS.items():
    stages = []
    area = a["area"]
    for i, (sid, tz, te, bmin, lines, choices) in enumerate(a["stages"]):
        eid = f"arc_{cid}_{sid}"
        n = int(sid)
        ev = {"id": eid, "kind": "fixed", "area": area, "scene": {"dialogue": "ev_" + eid}, "title_key": f"event.{eid}.title",
              "requires": {"bond_min": {cid: bmin}}, "priority": 6}
        if n == 1:
            ev["window"] = {"from": 10, "to": 100}
        else:
            ev["scheduled_only"] = True
            ev["requires"]["arc_min"] = {cid: n - 1}
        ev["on_miss"] = [{"type": "arc_outcome", "id": cid, "value": "lost"}, {"type": "arc_stage", "id": cid, "amount": 4}] if n < 4 else [{"type": "arc_bond", "id": cid, "value": "friend"}, {"type": "arc_stage", "id": cid, "amount": 4}]
        events["events"].append(ev)
        L(f"event.{eid}.title", tz, te)
        nodes = []
        for j, (who, z, e) in enumerate(lines):
            k = f"event.{eid}.{j+1}"; L(k, z, e)
            nd = {"id": f"n{j+1}", "text_key": k, "speaker_key": SPK(cid, who)}
            last = j == len(lines) - 1
            if not last:
                nd["next"] = f"n{j+2}"
            nodes.append(nd)
        after = [{"type": "arc_stage", "id": cid, "amount": n}]
        if n < 4:
            after.append({"type": "schedule", "id": f"arc_{cid}_{n+1}", "min": 4 if n < 3 else 2, "max": 26 if n < 3 else 16})
        if n == 4:
            # closing scene: relationship type, gated by bond
            nodes[-1]["choices"] = []
            for b, (bz, be) in BONDS.items():
                ck = f"event.{eid}.c.{b}"; L(ck, bz, be)
                ch = {"id": b, "label_key": ck, "next": "", "effects": [{"type": "arc_bond", "id": cid, "value": b}] + after}
                if b != "rival":   # the rival path is always open; the others need a strong bond
                    ch["gate"] = {"bond_min": {cid: BOND_NEED[b]}}
                nodes[-1]["choices"].append(ch)
        elif choices:
            nodes[-1]["choices"] = []
            for (chid, cz, ce, outcome, bd) in choices:
                ck = f"event.{eid}.c.{chid}"; L(ck, cz, ce)
                eff = list(after)
                if outcome:
                    eff.append({"type": "arc_outcome", "id": cid, "value": outcome})
                if chid == "fight":
                    eff.append({"type": "battle", "id": "bandit_scouts"})
                eff.append({"type": "bond", "id": cid, "amount": bd})
                nodes[-1]["choices"].append({"id": chid, "label_key": ck, "next": "", "effects": eff})
        else:
            nodes[-1]["next"] = ""
            nodes[-1]["on_enter"] = after
        cmds = [{"c": "bg", "id": BG[area]}, {"c": "show", "who": "hero", "slot": "left", "pose": "idle", "face": "neutral"},
                {"c": "show", "who": cid, "slot": "right", "pose": "idle", "face": "neutral"}]
        nodes[0]["stage"] = cmds
        dlgs["dialogues"].append({"id": "ev_" + eid, "entry": [{"node": "n1"}], "nodes": nodes})
        stages.append({"id": sid, "event": eid})
    arcs.append({"companion": cid, "stages": stages, "outcomes": list(OUTCOMES), "bonds": list(BONDS)})
dump("world/events.json", events); dump("world/event_dialogues.json", dlgs)
dump("companions/arcs.json", {"arcs": arcs})   # gen_year1.py appends the later companions
for o, (z, e) in OUTCOMES.items(): L("arc.outcome." + o, z, e)
for b, (z, e) in BONDS.items(): L("arc.bond." + b, z, e)
zh.update({"arc.progress": "羁绊故事 {stage}/{total}", "arc.result": "结局：{outcome}", "arc.relation": "关系：{bond}", "arc.gate.stage": "需先经历此前的故事"})
en.update({"arc.progress": "Bond story {stage}/{total}", "arc.result": "Outcome: {outcome}", "arc.relation": "Bond: {bond}", "arc.gate.stage": "Earlier chapters of the story come first"})
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(events["events"]), "events")
