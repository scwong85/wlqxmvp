#!/usr/bin/env python3
"""M20b content: path skill trees, manuals, equipment, their combat techniques and text. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
zh = {}; en = {}
def L(k, z, e): zh[k] = z; en[k] = e

def load(p): return json.load(open(os.path.join(G, p)))
def dump(p, d): json.dump(d, open(os.path.join(G, p), "w"), ensure_ascii=False, indent=1)

# ---- combat techniques (merged by id)
ct = load("combat/combat_techniques.json")
def tech(id, zhn, enn, **kw):
    t = {"id": id, "name_key": "technique." + id}
    t.update(kw)
    ct["techniques"] = [x for x in ct["techniques"] if x["id"] != id] + [t]
    L("technique." + id, zhn, enn)
bleed = lambda n: {"id": "bleed", "turns": n}

# ---- skill trees: 8 nodes per path
TREES = {
 "xuan_fist": [
  ("iron_skin", "铁骨", "Iron Bones", [], 1, 0, ("hp", 6)),
  ("heavy_shoulder", "沉肩", "Heavy Shoulder", ["iron_skin"], 1, 0, ("power", 1)),
  ("steady_stance", "稳桩", "Steady Stance", ["iron_skin"], 1, 1, ("body", 1)),
  ("fist_quake", "裂山拳", "Mountain-Splitting Fist", ["heavy_shoulder"], 2, 1, ("tech", dict(kind="attack", range=1, damage=8, resolve=4, push=2, cost=3))),
  ("deep_earth", "厚土", "Deep Earth", ["steady_stance"], 1, 2, ("hp", 8)),
  ("qi_thread", "气贯", "Threaded Qi", ["fist_quake"], 2, 2, ("tp", 1)),
  ("fist_tremor", "震岳掌", "Quaking Palm", ["deep_earth"], 2, 3, ("tech", dict(kind="attack", range=2, damage=7, resolve=4, push=1, cost=3))),
  ("fist_dragon", "龙象拳", "Dragon-Elephant Fist", ["qi_thread", "fist_tremor"], 3, 4, ("tech", dict(kind="attack", range=1, damage=15, resolve=6, push=1, cost=5))),
 ],
 "green_sword": [
  ("light_body", "轻身", "Light Body", [], 1, 0, ("agility", 1)),
  ("clear_eye", "清目", "Clear Eye", ["light_body"], 1, 0, ("tp", 1)),
  ("quick_step", "疾步", "Quick Step", ["light_body"], 1, 1, ("hp", 6)),
  ("sword_cloud", "流云刺", "Drifting Cloud Thrust", ["clear_eye"], 2, 1, ("tech", dict(kind="attack", range=3, damage=6, resolve=3, cost=3, status=bleed(2)))),
  ("keen_sense", "灵犀", "Keen Sense", ["quick_step"], 1, 2, ("agility", 1)),
  ("sword_heart", "剑心", "Sword Heart", ["sword_cloud"], 2, 2, ("spirit", 1)),
  ("sword_petals", "落花式", "Falling Petals", ["keen_sense"], 2, 3, ("tech", dict(kind="attack", range=2, damage=8, resolve=3, cost=3))),
  ("sword_rainbow", "青虹贯日", "Azure Rainbow Through the Sun", ["sword_heart", "sword_petals"], 3, 4, ("tech", dict(kind="attack", range=4, damage=13, resolve=5, cost=5, status=bleed(3)))),
 ],
 "listening_rain": [
  ("still_mind", "静心", "Still Mind", [], 1, 0, ("spirit", 1)),
  ("guard_spirit", "守神", "Guarded Spirit", ["still_mind"], 1, 0, ("resolve", 3)),
  ("deep_breath", "深息", "Deep Breath", ["still_mind"], 1, 1, ("tp", 1)),
  ("rain_renew", "回春", "Spring Return", ["guard_spirit"], 2, 1, ("tech", dict(kind="support", range=3, heal=20, cost=3))),
  ("soft_earth", "润土", "Soft Earth", ["deep_breath"], 1, 2, ("hp", 8)),
  ("calm_water", "止水", "Calm Water", ["rain_renew"], 2, 2, ("spirit", 1)),
  ("rain_clarity", "清心引", "Clearing Chant", ["soft_earth"], 2, 3, ("tech", dict(kind="support", range=3, resolve_restore=12, cleanse=True, cost=3))),
  ("rain_hush", "万籁归一", "All Sounds Return to One", ["calm_water", "rain_clarity"], 3, 4, ("tech", dict(kind="support", range=3, heal=26, resolve_restore=10, cleanse=True, cost=5))),
 ],
}
nodes = []
for path, rows in TREES.items():
    for nid, z, e, req, cost, rmin, (kind, val) in rows:
        if kind == "tech":
            tech(nid, z, e, **val)
            eff = {"type": "technique", "id": nid}; name_key = "technique." + nid
        else:
            eff = {"type": "stat", "stat": kind, "amount": val}; name_key = "tree." + nid
            L(name_key, z, e)
        nodes.append({"id": nid, "path": path, "name_key": name_key, "requires": req, "cost": cost, "realm_min": rmin, "effect": eff})
dump("cultivation/skill_tree.json", {"nodes": nodes})

# ---- manuals: items that teach an outside technique; one manual per group
MANUALS = [
 ("iron_palm", "铁砂掌谱", "Iron Sand Palm Manual", "iron_palm", "铁砂掌", "Iron Sand Palm", "palm", 0, dict(kind="attack", range=1, damage=7, resolve=4, cost=2)),
 ("wind_step", "踏风步谱", "Wind-Treading Manual", "wind_step", "踏风步", "Wind-Treading Step", "palm", 0, dict(kind="attack", range=3, damage=4, resolve=2, cost=1)),
 ("herb_hymn", "百草歌", "Hundred Herbs Hymn", "herb_hymn", "百草歌诀", "Herb Hymn", "heal", 0, dict(kind="support", range=2, heal=16, cost=2)),
 ("thunder_palm", "惊雷掌谱", "Thunder Palm Manual", "thunder_palm", "惊雷掌", "Thunder Palm", "heal", 1, dict(kind="attack", range=2, damage=9, resolve=5, cost=3)),
 ("ember_fist", "赤焰拳谱", "Ember Fist Manual", "ember_fist", "赤焰拳", "Ember Fist", "rare", 3, dict(kind="attack", range=1, damage=11, resolve=5, cost=4, status=bleed(2))),
 ("jade_shield", "玉盾心经", "Jade Shield Sutra", "jade_shield", "玉盾心诀", "Jade Shield Verse", "rare", 3, dict(kind="support", range=2, heal=8, resolve_restore=10, cleanse=True, cost=3)),
]
manuals = []
for mid, mz, me, tid, tz, te, group, rmin, tdef in MANUALS:
    tech(tid, tz, te, **tdef)
    L("manual." + mid, mz, me)
    manuals.append({"id": mid, "item": "manual_" + mid, "name_key": "manual." + mid, "technique": tid, "group": group, "realm_min": rmin})
dump("cultivation/manuals.json", {"manuals": manuals})
dump("combat/combat_techniques.json", ct)

# ---- equipment: forged from ore and coins
EQ = [
 ("iron_sword", "铁剑", "Iron Sword", "weapon", 0, 3, 10, {"power": 1}),
 ("steel_blade", "百炼钢刀", "Steel Blade", "weapon", 2, 6, 25, {"power": 2}),
 ("jade_saber", "青玉宝刀", "Jade Saber", "weapon", 4, 10, 50, {"power": 3, "tp": 1}),
 ("cloth_vest", "粗布护甲", "Cloth Vest", "armor", 0, 2, 8, {"hp": 6}),
 ("leather_coat", "皮甲", "Leather Coat", "armor", 2, 5, 20, {"hp": 10, "body": 1}),
 ("scale_armor", "鱼鳞甲", "Scale Armor", "armor", 4, 9, 45, {"hp": 16, "body": 2}),
 ("jade_pendant", "玉佩", "Jade Pendant", "charm", 0, 2, 12, {"spirit": 1}),
 ("wind_charm", "御风符", "Wind Charm", "charm", 2, 5, 25, {"agility": 1, "tp": 1}),
 ("dragon_charm", "龙纹护符", "Dragon Charm", "charm", 4, 9, 50, {"resolve": 4, "tp": 1, "spirit": 1}),
]
eq = []
for eid, z, e, slot, rmin, ore, coins, bonus in EQ:
    L("equip." + eid, z, e)
    eq.append({"id": eid, "item": "eq_" + eid, "name_key": "equip." + eid, "slot": slot, "realm_min": rmin, "cost": {"ore": ore, "coins": coins}, "bonus": bonus})
dump("cultivation/equipment.json", {"equipment": eq})

# ---- manuals found in the world and in fights
areas = load("world/areas.json")
def wander(area_id, key, z, e, item):
    for a in areas["areas"]:
        if a["id"] == area_id and not any(w["text_key"] == key for w in a["wander"]):
            a["wander"].append({"text_key": key, "rewards": [{"type": "item", "id": item, "amount": 1}]})
    L(key, z, e)
wander("old_shrine", "world.area.old_shrine.m1", "神龛后的暗格里压着一册旧谱：踏风步谱。", "Behind the shrine, a hidden niche holds an old booklet: the Wind-Treading Manual.", "manual_wind_step")
wander("herb_terraces", "world.area.herb_terraces.m1", "药农送你一册手抄的《百草歌》。", "An herb farmer gives you a hand-copied Hundred Herbs Hymn.", "manual_herb_hymn")
wander("ferry_dock", "world.area.ferry_dock.m1", "老船工从行囊里翻出一册铁砂掌谱，说放着也是放着。", "The old boatman digs out an Iron Sand Palm manual: \"It only gathers dust.\"", "manual_iron_palm")
wander("river_bend", "world.area.river_bend.m1", "浅滩的淤泥里露出油布包，里面是惊雷掌谱。", "An oilcloth bundle in the mud holds a Thunder Palm manual.", "manual_thunder_palm")
dump("world/areas.json", areas)

sc = load("combat/scenarios.json")
for s in sc["scenarios"]:
    drop = {"rescue_battle": "manual_ember_fist", "final_crisis": "manual_jade_shield"}.get(s["id"])
    if drop:
        v = s.setdefault("on_victory", {}).setdefault("rewards", [])
        if not any(r.get("id") == drop for r in v):
            v.append({"type": "item", "id": drop, "amount": 1})
dump("combat/scenarios.json", sc)

# ---- text
zh.update({
 "arts.button": "功法", "arts.title": "功法与装备", "arts.back": "返回", "arts.points": "可用武学点：{n}",
 "arts.tab.tree": "武学树", "arts.tab.manuals": "秘籍", "arts.tab.gear": "装备",
 "tree.desc.stat": "战斗中 {stat} +{n}", "tree.desc.technique": "习得招式：{name}",
 "tree.learn": "修习（{cost} 点）", "tree.learned": "已修习", "tree.locked": "需先修习：{list}", "tree.realm": "需境界：{name}", "tree.points": "武学点不足",
 "tree.none": "选择门派后方可修习武学", "tree.done": "你修成了「{name}」。",
 "arts.stat.hp": "生命", "arts.stat.body": "根骨", "arts.stat.power": "力道", "arts.stat.agility": "身法", "arts.stat.spirit": "心性", "arts.stat.tp": "技力", "arts.stat.resolve": "心志",
 "manual.none": "尚未得到秘籍。探索江湖，或许能寻到。", "manual.study": "研读（{stamina} 体力，1 个时段）", "manual.known": "已习得",
 "manual.group_taken": "同类秘籍已择其一，不可兼修", "manual.realm": "需境界：{name}", "manual.done": "你研读了「{name}」，习得「{tech}」。", "manual.teaches": "习得：{name}",
 "manual.stamina": "体力不足", "manual.hint": "同类秘籍只能择一研读。",
 "equip.slot.weapon": "兵器", "equip.slot.armor": "护甲", "equip.slot.charm": "护符", "equip.none": "（未装备）",
 "equip.forge": "锻造（矿 {ore}，铜钱 {coins}）", "equip.equip": "装备", "equip.unequip": "卸下", "equip.owned": "已拥有",
 "equip.bonus": "加成：{list}", "equip.realm": "需境界：{name}", "equip.poor": "材料不足", "equip.forged": "你锻造了「{name}」。", "equip.have": "矿 {ore}，铜钱 {coins}",
})
en.update({
 "arts.button": "Arts", "arts.title": "Arts and Gear", "arts.back": "Back", "arts.points": "Skill points available: {n}",
 "arts.tab.tree": "Skill tree", "arts.tab.manuals": "Manuals", "arts.tab.gear": "Gear",
 "tree.desc.stat": "In battle: {stat} +{n}", "tree.desc.technique": "Teaches the technique {name}",
 "tree.learn": "Learn ({cost} pts)", "tree.learned": "Learned", "tree.locked": "Learn first: {list}", "tree.realm": "Needs realm: {name}", "tree.points": "Not enough skill points",
 "tree.none": "Choose a school before learning its arts", "tree.done": "You master \"{name}\".",
 "arts.stat.hp": "HP", "arts.stat.body": "Body", "arts.stat.power": "Power", "arts.stat.agility": "Agility", "arts.stat.spirit": "Spirit", "arts.stat.tp": "Technique points", "arts.stat.resolve": "Resolve",
 "manual.none": "No manuals yet. Explore the world to find some.", "manual.study": "Study ({stamina} stamina, 1 slot)", "manual.known": "Learned",
 "manual.group_taken": "You already follow a manual of this kind", "manual.realm": "Needs realm: {name}", "manual.done": "You study \"{name}\" and learn \"{tech}\".", "manual.teaches": "Teaches: {name}",
 "manual.stamina": "Not enough stamina", "manual.hint": "Only one manual of each kind can be studied.",
 "equip.slot.weapon": "Weapon", "equip.slot.armor": "Armor", "equip.slot.charm": "Charm", "equip.none": "(empty)",
 "equip.forge": "Forge (ore {ore}, coins {coins})", "equip.equip": "Equip", "equip.unequip": "Unequip", "equip.owned": "Owned",
 "equip.bonus": "Bonus: {list}", "equip.realm": "Needs realm: {name}", "equip.poor": "Not enough materials", "equip.forged": "You forge \"{name}\".", "equip.have": "Ore {ore}, coins {coins}",
})
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok", len(nodes), "nodes")
