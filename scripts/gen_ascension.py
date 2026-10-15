#!/usr/bin/env python3
"""Generates content/cultivation/realms.json and the loc keys for realms, technique levels and life skills (M20a)."""
import json, os
G = os.path.join(os.path.dirname(__file__), "..", "game", "content")
R = [("first_glimpse", "初窥门径", "First Glimpse", "刚踏入武学的门槛，一招一式尚显生涩。", "You have just crossed the threshold; every move is still stiff."),
     ("entering_hall", "登堂入室", "Entering the Hall", "招式渐成章法，内息也稳了。", "Your forms have order and your breathing is steady."),
     ("minor_mastery", "小有所成", "Minor Mastery", "在同辈之中，已无人敢轻视你。", "Among your peers, no one dares look down on you."),
     ("integrated", "融会贯通", "Integrated Understanding", "拳脚、内息与心意开始彼此呼应。", "Fists, breath and intent begin to answer one another."),
     ("pure_flame", "炉火纯青", "Pure Flame", "一举一动，皆恰到好处。", "Every move lands exactly as it should."),
     ("return_simple", "返璞归真", "Return to Simplicity", "繁复尽去，只剩最简单的一招。", "All ornament falls away; only the simplest move remains."),
     ("grandmaster", "宗师", "Grandmaster", "武道至此，已可自成一派。", "You may found a school of your own.")]
caps = [12, 16, 24, 34, 46, 60, 99]
hp = [0, 6, 12, 20, 30, 42, 56]
tp = [0, 0, 1, 1, 2, 2, 3]
pp = [0, 6, 16, 30, 50, 75, 100]
tl = [0, 0, 0, 4, 8, 14, 20]
realms = []
zh = {}; en = {}
for i, (rid, z, e, dz, de) in enumerate(R):
    req = {}
    if i > 0:
        req = {"path_progress_min": pp[i], "attr_total_min": int(5 * caps[i - 1] * 0.7)}
        if tl[i]:
            req["tech_levels_min"] = tl[i]
    realms.append({"id": rid, "name_key": f"realm.{rid}", "desc_key": f"realm.{rid}.desc", "attr_cap": caps[i], "hp_bonus": hp[i], "tp_bonus": tp[i], "requires": req})
    zh[f"realm.{rid}"] = z; en[f"realm.{rid}"] = e
    zh[f"realm.{rid}.desc"] = dz; en[f"realm.{rid}.desc"] = de
json.dump({"realms": realms}, open(os.path.join(G, "cultivation", "realms.json"), "w"), ensure_ascii=False, indent=1)
zh.update({
 "realm.req.path_progress": "路径进度 {have}/{need}", "realm.req.attr_total": "属性总和 {have}/{need}", "realm.req.tech_levels": "招式等级总和 {have}/{need}",
 "realm.blocked.path_progress": "路径进度不足", "realm.blocked.attr_total": "属性总和不足", "realm.blocked.tech_levels": "招式等级不足",
 "realm.blocked.last": "已至宗师之境", "realm.blocked.no_path": "尚未选择门派",
 "realm.cap": "属性上限 {cap}", "realm.bonus": "战斗：生命 +{hp}，技力 +{tp}",
 "sheet.button": "修为", "sheet.title": "修为", "sheet.realm": "境界", "sheet.next": "下一境界：{name}", "sheet.last": "已臻圆满", "sheet.break": "突破（{stamina} 体力，1 个时段）",
 "sheet.break_done": "突破成功！你踏入了「{name}」。", "sheet.techniques": "招式", "sheet.no_techniques": "尚未习得招式", "sheet.life": "生活技艺", "sheet.back": "返回", "sheet.realm_line": "{label}：{name}",
 "sheet.tech_line": "{name}  等级 {lv}（{xp}）", "sheet.tech_line_max": "{name}  等级 {lv}（圆满）", "sheet.life_line": "{name}  等级 {lv}  已练 {n} 次",
 "sheet.tech_bonus": "每两级：伤害/治疗 +1", "sheet.life_bonus": "每三级：首项收获 +1", "sheet.bottleneck": "属性已达上限，需突破境界",
 "cult.tech_levels": "招式升级：{list}", "result.tech_level": "{name} 升至 {lv} 级",
 "lifeskill.fishing": "垂钓", "lifeskill.mining": "采矿", "lifeskill.medicine": "医药", "lifeskill.music": "音律", "lifeskill.chess": "棋艺", "lifeskill.cooking": "烹饪"})
en.update({
 "realm.req.path_progress": "Path progress {have}/{need}", "realm.req.attr_total": "Attribute total {have}/{need}", "realm.req.tech_levels": "Technique levels {have}/{need}",
 "realm.blocked.path_progress": "Not enough path progress", "realm.blocked.attr_total": "Attributes too low", "realm.blocked.tech_levels": "Techniques not practised enough",
 "realm.blocked.last": "Already a grandmaster", "realm.blocked.no_path": "No school chosen yet",
 "realm.cap": "Attribute cap {cap}", "realm.bonus": "Battle: HP +{hp}, technique points +{tp}",
 "sheet.button": "Cultivation", "sheet.title": "Cultivation", "sheet.realm": "Realm", "sheet.next": "Next realm: {name}", "sheet.last": "Fully realised", "sheet.break": "Break through ({stamina} stamina, 1 slot)",
 "sheet.break_done": "Breakthrough! You enter \"{name}\".", "sheet.techniques": "Techniques", "sheet.no_techniques": "No techniques learned yet", "sheet.life": "Life skills", "sheet.back": "Back", "sheet.realm_line": "{label}: {name}",
 "sheet.tech_line": "{name}  Lv {lv} ({xp})", "sheet.tech_line_max": "{name}  Lv {lv} (max)", "sheet.life_line": "{name}  Lv {lv}  practised {n}x",
 "sheet.tech_bonus": "Every 2 levels: +1 damage/healing", "sheet.life_bonus": "Every 3 levels: +1 to the first reward", "sheet.bottleneck": "Attributes are at the cap: break through to grow further",
 "cult.tech_levels": "Techniques levelled: {list}", "result.tech_level": "{name} reaches level {lv}",
 "lifeskill.fishing": "Fishing", "lifeskill.mining": "Mining", "lifeskill.medicine": "Medicine", "lifeskill.music": "Music", "lifeskill.chess": "Weiqi", "lifeskill.cooking": "Cooking"})
for lang, kv in (("zh_CN", zh), ("en", en)):
    fp = os.path.join(G, "localization", lang + ".json"); x = json.load(open(fp)); x.update(kv)
    json.dump(x, open(fp, "w"), ensure_ascii=False, indent=1)
print("ok")
