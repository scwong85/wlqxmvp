extends RefCounted
## M20a tests: realms and breakthroughs, attribute caps, technique levels (practice and battle use), life skills,
## battle bonuses, saving, and the hero sheet screen.

const GameState = preload("res://scripts/domain/game_state.gd")
const RealmRules = preload("res://scripts/domain/realm_rules.gd")
const TechniqueLevels = preload("res://scripts/domain/technique_levels.gd")
const LifeSkillRules = preload("res://scripts/domain/life_skill_rules.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const BattleResult = preload("res://scripts/domain/combat/battle_result.gd")
const Battle = preload("res://scripts/domain/combat/battle.gd")
const CombatUnit = preload("res://scripts/domain/combat/combat_unit.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	_realms()
	_technique_levels()
	_life_skills()
	_battle()
	_save()
	_screen()
	content.free()


func _ready_state() -> RefCounted:
	var s: RefCounted = GameState.new_game(6)
	s.player.path_id = "xuan_fist"
	s.player.stamina = 30
	return s


func _realms() -> void:
	check.call(content.realms.size() == 7 and content.realms[0].attr_cap == 12 and content.realms[6].attr_cap == 99, "m20: seven realms from cap 12 to 99")
	var s := _ready_state()
	check.call(int(s.cultivation.realm) == 0 and RealmRules.attr_cap(s, content) == 12, "m20: a new hero starts in the first realm")
	var c: Dictionary = RealmRules.can_break(s, content)
	check.call(not c.ok and c.reasons.has("realm.blocked.path_progress") and c.reasons.has("realm.blocked.attr_total"), "m20: the first breakthrough lists what is missing")
	check.call(not RealmRules.break_through(s, content).ok and int(s.cultivation.realm) == 0, "m20: a refused breakthrough changes nothing")
	# Meet the requirements of realm 1.
	s.cultivation.path_progress["xuan_fist"] = 6
	for a in s.player.ATTRS:
		s.player.attributes[a] = 9
	var slot0: int = s.calendar.slot
	var week0: int = s.calendar.week
	var stamina0: int = s.player.stamina
	var r: Dictionary = RealmRules.break_through(s, content)
	check.call(r.ok and int(s.cultivation.realm) == 1 and r.realm_id == "entering_hall", "m20: meeting the requirements breaks through")
	check.call(s.player.stamina == stamina0 - RealmRules.BREAKTHROUGH_STAMINA and (s.calendar.slot != slot0 or s.calendar.week != week0), "m20: a breakthrough costs stamina and a slot")
	check.call(s.player.attr_cap == 16 and RealmRules.hp_bonus(s, content) == 6, "m20: the cap and battle bonus rise")
	check.call(s.player.add_attr("power", 50) == 7 and s.player.get_attr("power") == 16, "m20: attributes now stop at the new cap")
	var s2 := _ready_state()
	s2.player.path_id = ""
	check.call(RealmRules.can_break(s2, content).reasons.has("realm.blocked.no_path"), "m20: a school is needed")
	var s3 := _ready_state()
	s3.cultivation.realm = 6
	check.call(RealmRules.is_last(s3, content) and RealmRules.can_break(s3, content).reasons.has("realm.blocked.last") and RealmRules.requirement_lines(s3, content).is_empty(), "m20: the last realm has no further breakthrough")
	# Requirements are reachable: each realm's attribute total fits under the previous cap.
	for i in range(1, 7):
		var need: int = content.realms[i].requires.attr_total_min
		check.call(need <= 5 * int(content.realms[i - 1].attr_cap), "m20: realm %d attribute total %d fits under the previous cap" % [i, need])
	var s4 := _ready_state()
	s4.cultivation.realm = 2
	s4.cultivation.path_progress["xuan_fist"] = 99
	for a in s4.player.ATTRS:
		s4.player.attributes[a] = 24
	check.call(RealmRules.can_break(s4, content).reasons.has("realm.blocked.tech_levels"), "m20: later realms also need technique levels")


func _technique_levels() -> void:
	check.call(TechniqueLevels.level_for_xp(0) == 1 and TechniqueLevels.level_for_xp(3) == 2 and TechniqueLevels.level_for_xp(129) == 9 and TechniqueLevels.level_for_xp(999) == 10, "m20: experience maps to levels 1 to 10")
	var s := _ready_state()
	s.player.techniques = ["fist_wave"]
	var r: Dictionary = TechniqueLevels.add_xp(s, "fist_wave", 3)
	check.call(r.level_before == 1 and r.level_after == 2 and TechniqueLevels.xp_to_next(s, "fist_wave") == 5, "m20: experience raises the level")
	check.call(TechniqueLevels.add_xp(s, "sword_flash", 5).level_after == 1 and not s.cultivation.technique_xp.has("sword_flash"), "m20: unknown techniques gain nothing")
	# Practising trains every known technique.
	var s2 := _ready_state()
	s2.calendar.week = 2
	s2.player.techniques = ["fist_wave", "fist_counter"]
	var res: Dictionary = ActivityRules.perform(s2, content.activity("technique_practice"), content, "balanced")
	check.call(res.ok and int(s2.cultivation.technique_xp.get("fist_wave", 0)) == 1 and int(s2.cultivation.technique_xp.get("fist_counter", 0)) == 1, "m20: technique practice trains every known technique")
	var s3 := _ready_state()
	s3.calendar.week = 2
	s3.player.techniques = ["fist_wave"]
	ActivityRules.perform(s3, content.activity("technique_practice"), content, "risky")
	check.call(int(s3.cultivation.technique_xp.get("fist_wave", 0)) == 2, "m20: the risky approach trains twice as much")
	# Levelled techniques hit harder.
	var t: Dictionary = content.combat_tech("fist_wave")
	check.call(Battle.leveled(t, 1) == t and int(Battle.leveled(t, 5).damage) == int(t.damage) + 2 and int(Battle.leveled(t, 10).damage) == int(t.damage) + 4, "m20: every two levels add 1 damage")
	var heal: Dictionary = content.combat_tech("rain_heal")
	check.call(int(Battle.leveled(heal, 7).heal) == int(heal.heal) + 3, "m20: healing grows with level too")
	check.call(not Battle.leveled(content.combat_tech("basic_attack"), 9).is_empty() and int(Battle.leveled(content.combat_tech("basic_attack"), 9).damage) == int(content.combat_tech("basic_attack").damage) + 4, "m20: levels apply to any technique with damage")


func _life_skills() -> void:
	var s := _ready_state()
	check.call(LifeSkillRules.level(s, "fishing") == 1 and LifeSkillRules.level_for_count(65) == 10 and LifeSkillRules.level_for_count(2) == 2, "m20: life skill levels come from practice counts")
	check.call(LifeSkillRules.skill_of_activity("herb_gathering") == "medicine" and LifeSkillRules.skill_of_activity("rest") == "", "m20: activities map to skills")
	check.call(LifeSkillRules.reward_bonus(s, "fishing") == 0, "m20: no bonus at level 1")
	s.cultivation.practice_counts["fishing"] = 9    # level 4
	check.call(LifeSkillRules.level(s, "fishing") == 4 and LifeSkillRules.reward_bonus(s, "fishing") == 1, "m20: level 4 pays +1")
	s.calendar.week = 2
	var base: RefCounted = _ready_state()
	base.calendar.week = 2
	var food := func(st: RefCounted) -> int:
		var r: Dictionary = ActivityRules.perform(st, content.activity("fishing"), content, "still_water", {"grade": "ok", "mult": 1.0})
		var n := 0
		for d in r.deltas:
			if d.type == "resource" and d.id == "food":
				n += int(d.delta)
		return n
	check.call(food.call(s) == food.call(base) + 1, "m20: a practised hobby pays one more on its first reward")


func _battle() -> void:
	var s := _ready_state()
	s.player.techniques = ["fist_wave"]
	s.cultivation.technique_xp["fist_wave"] = 15   # level 4
	var plain: RefCounted = BattleSetup.build(content, "training_match", 1, _ready_state())
	var b: RefCounted = BattleSetup.build(content, "training_match", 1, s)
	check.call(b.unit("hero").tech_levels.get("fist_wave", 0) == 4, "m20: the hero enters battle with technique levels")
	var s2 := _ready_state()
	s2.cultivation.realm = 3
	s2.player.attr_cap = 34
	var b2: RefCounted = BattleSetup.build(content, "training_match", 1, s2)
	check.call(b2.unit("hero").max_hp == plain.unit("hero").max_hp + 20 and b2.unit("hero").tp == plain.unit("hero").tp + 1, "m20: the realm adds hit points and technique points")
	# Use counts feed experience.
	var hero: RefCounted = b.unit("hero")
	hero.tech_uses["fist_wave"] = 3
	var back: RefCounted = CombatUnit.from_dict(JSON.parse_string(JSON.stringify(hero.to_dict())))
	check.call(back.tech_levels.get("fist_wave", 0) == 4 and back.tech_uses.get("fist_wave", 0) == 3, "m20: levels and uses survive a battle snapshot")
	var res: Dictionary = BattleResult.apply(s, content.scenario("training_match"), "", {}, content, {"fist_wave": 3, "basic_attack": 9, "sword_flash": 2})
	check.call(int(s.cultivation.technique_xp["fist_wave"]) == 18 and not s.cultivation.technique_xp.has("sword_flash") and not s.cultivation.technique_xp.has("basic_attack"), "m20: using a technique in battle trains it (unknown ones do not)")
	var s5 := _ready_state()
	s5.player.techniques = ["fist_wave"]
	BattleResult.apply(s5, content.scenario("training_match"), "victory", {}, content, {"fist_wave": 50})
	check.call(int(s5.cultivation.technique_xp["fist_wave"]) == 4, "m20: battle experience is limited to 4 per technique per fight")
	var s6 := _ready_state()
	s6.player.techniques = ["fist_wave"]
	s6.cultivation.technique_xp["fist_wave"] = 2
	var res2: Dictionary = BattleResult.apply(s6, content.scenario("training_match"), "victory", {}, content, {"fist_wave": 1})
	check.call(res2.levels.size() == 1 and res2.levels[0].level == 2, "m20: a level gained in battle is reported")


func _save() -> void:
	var s := _ready_state()
	s.cultivation.realm = 2
	s.player.attr_cap = 24
	s.cultivation.technique_xp["fist_wave"] = 20
	var back: RefCounted = GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	check.call(back.cultivation.realm == 2 and back.player.attr_cap == 24 and back.cultivation.technique_xp.get("fist_wave", 0) == 20, "m20: realm, cap and technique experience survive saving")
	var old: RefCounted = GameState.from_dict({"calendar": {"week": 2, "slot": 1}})
	check.call(old.cultivation.realm == 0 and old.player.attr_cap == 12, "m20: older saves start in the first realm")
	var bad: RefCounted = GameState.from_dict({"cultivation": {"realm": 99, "technique_xp": {"x": -5}}, "player": {"attr_cap": 5000}})
	check.call(bad.cultivation.realm == 6 and bad.cultivation.technique_xp.get("x", 0) == 0 and bad.player.attr_cap == 99, "m20: damaged values are clamped")


func _screen() -> void:
	var root: Node = Engine.get_main_loop().root
	var game: Node = root.get_node("Game")
	var host: Node = Engine.get_main_loop().current_scene
	game.new_game(51)
	for h in content.day_hooks:
		game.state.calendar.events_fired.append(str(h.id))
	game.state.calendar.events_fired.append("prologue_crisis")
	game.state.calendar.week = 8
	game.state.player.path_id = "xuan_fist"
	game.state.player.stamina = 30
	var scene: Control = load("res://scenes/menus/hero_sheet.tscn").instantiate()
	host.add_child(scene)
	check.call(scene.break_button != null and scene.break_button.disabled, "m20: the sheet shows a disabled breakthrough button while requirements are missing")
	scene.queue_free()
	game.state.cultivation.path_progress["xuan_fist"] = 6
	for a in game.state.player.ATTRS:
		game.state.player.attributes[a] = 9
	var scene2: Control = load("res://scenes/menus/hero_sheet.tscn").instantiate()
	host.add_child(scene2)
	check.call(not scene2.break_button.disabled, "m20: it enables when they are met")
	scene2.break_button.pressed.emit()
	check.call(game.state.cultivation.realm == 1 and scene2.notice_label.text != "", "m20: pressing it breaks through and says so")
	scene2.queue_free()
	game.battle = null
