#!/usr/bin/env python3
"""M20c: duo techniques (hero + companion), their content and text. Idempotent."""
import json, os
G = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")
ct = json.load(open(os.path.join(G, "combat/combat_techniques.json")))
DUOS = [
 ("duo_spring_breeze", "shen_qinghe", "春风同行", "Spring Breeze Together", dict(kind="attack", range=3, damage=6, resolve=7, cost=3)),
 ("duo_twin_dash", "lu_chenzhou", "双影疾袭", "Twin Shadow Dash", dict(kind="attack", range=1, damage=9, resolve=4, push=2, cost=3)),
 ("duo_ink_seal", "bai_yan", "墨印合击", "Ink Seal Strike", dict(kind="attack", range=2, damage=7, resolve=5, cost=3, status={"id": "weaken", "turns": 2})),
]
zh = {}; en = {}
duos = []
for tid, comp, z, e, d in DUOS:
    t = {"id": tid, "name_key": "technique." + tid, "duo": comp}
    t.update(d)
    ct["techniques"] = [x for x in ct["techniques"] if x["id"] != tid] + [t]
    zh["technique." + tid] = z; en["technique." + tid] = e
    duos.append({"id": tid, "companion": comp, "tech": tid, "bond_min": 12})
json.dump(ct, open(os.path.join(G, "combat/combat_techniques.json"), "w"), ensure_ascii=False, indent=1)
json.dump({"duos": duos}, open(os.path.join(G, "combat/duo.json"), "w"), ensure_ascii=False, indent=1)
zh.update({"combat.mod.duo": "合击", "party.leave": "暂时离队", "party.duo_line": "合击「{name}」（羁绊 {bond}）", "party.duo_ready": "合击「{name}」已可用", "party.limit": "队伍最多带两位同伴，新同伴会替换第二位"})
en.update({"combat.mod.duo": "Duo", "party.leave": "Step out", "party.duo_line": "Duo technique \"{name}\" (bond {bond})", "party.duo_ready": "Duo technique \"{name}\" ready", "party.limit": "The party holds two companions; a new one replaces the second"})
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok")
