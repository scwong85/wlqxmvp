extends RefCounted
## M6 tests: activity options, risk variance, buffs and expiry, tokens, relationship deltas,
## schema v2 -> v3 migration, and the activity matrix (every activity x every approach x several states).

const GameState = preload("res://scripts/domain/game_state.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const PlayerState = preload("res://scripts/domain/player_state.gd")
const ContentService = preload("res://scripts/services/content_service.gd")
const SaveService = preload("res://scripts/services/save_service.gd")

var check: Callable
var content: Node


func run(check_fn: Callable, loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	_option_basics()
	_risk_variance()
	_cooking_buff()
	_buff_rules()
	_chess_token()
	_relationships()
	_matrix()
	_migration_v3()
	check.call(content.validate(loc.has_key).is_empty(), "m6: content with options validates (%s)" % str(content.validate(loc.has_key)))
	content.free()


func _g(seed_value: int = 7) -> RefCounted:
	return GameState.new_game(seed_value)


func _act(id: String) -> Dictionary:
	return content.activity(id)


func _option_basics() -> void:
	var d := _act("technique_practice")
	check.call(ActivityRules.default_option(d) == "safe" and ActivityRules.default_option(_act("rest")) == "", "options: default is the first option; none for plain activities")
	var eff := ActivityRules.effective_def(d, "risky")
	check.call(int(eff.check.target) == int(d.check.target) + 2 and eff.fail_stamina == 3, "options: effective_def shifts the target and carries fail_stamina")
	check.call(int(d.check.target) == 6, "options: the stored definition is never mutated")
	check.call(ActivityRules.effective_def(d, "nope").is_empty(), "options: unknown option gives an empty definition")
	var g := _g()
	var before := JSON.stringify(g.to_dict(), "", true)
	var r: Dictionary = ActivityRules.perform(g, d, content, "nope")
	check.call(not r.ok and r.reasons == ["activity.blocked.option"] and before == JSON.stringify(g.to_dict(), "", true), "options: invalid option is refused and changes nothing")
	var rest: Dictionary = ActivityRules.perform(_g(), _act("rest"), content)
	check.call(rest.ok and rest.option_id == "", "options: plain activities still work without an option")


func _risk_variance() -> void:
	var g := _g()
	g.player.add_attr("insight", 1)
	var safe := ActivityRules.check_chance(g, _act("technique_practice"), "safe")
	var bal := ActivityRules.check_chance(g, _act("technique_practice"), "balanced")
	var risky := ActivityRules.check_chance(g, _act("technique_practice"), "risky")
	check.call(safe > bal and bal > risky, "risk: safe > balanced > risky success chance (%d/%d/%d)" % [safe, bal, risky])
	# Risky pays more on success but costs extra stamina on failure; find one of each across seeds.
	var won := false
	var lost := false
	for s in 300:
		var t := _g(s)
		t.player.add_attr("insight", 1)
		t.player.path_id = "xuan_fist"
		var res: Dictionary = ActivityRules.perform(t, _act("technique_practice"), content, "risky")
		if res.grade == "success" and not won:
			won = true
			check.call(t.cultivation.path_progress.get("xuan_fist", 0) == 4 and t.player.stamina == 15, "risk: success pays 4 progress, no extra stamina")
		if res.grade == "partial" and not lost:
			lost = true
			check.call(t.player.stamina == 12 and res.cost.size() == 2, "risk: failure also costs 3 extra stamina (20-5-3)")
			check.call(t.cultivation.path_progress.get("xuan_fist", 0) == 2, "risk: failure still pays half (2 progress)")
	check.call(won and lost, "risk: both outcomes occur across seeds")
	# Extra stamina loss cannot go below zero.
	var low := _g(3)
	low.player.stamina = 5
	for s2 in 300:
		var t2 := _g(s2)
		t2.player.stamina = 5
		var res2: Dictionary = ActivityRules.perform(t2, _act("technique_practice"), content, "risky")
		if res2.grade == "partial":
			check.call(t2.player.stamina == 0, "risk: stamina loss is clamped at zero")
			break


func _cooking_buff() -> void:
	var g := _g()
	g.resources.add("food", 3)
	g.player.stamina = 5
	var r: Dictionary = ActivityRules.perform(g, _act("cooking"), content, "porridge")
	check.call(r.ok and g.resources.get_amount("food") == 1, "cooking: porridge uses 2 food")
	check.call(g.player.buffs.size() == 1 and g.player.buffs[0].id == "hearty_porridge", "cooking: a buff is added")
	check.call(g.player.effective_attr("body") == g.player.get_attr("body") + 1, "cooking: body +1 while buffed")
	check.call(g.player.get_attr("body") == 5, "cooking: stored attribute is unchanged")
	# Lasts exactly 3 more slots after the cooking slot.
	g.player.stamina = 20
	var left: Array = []
	for i in 4:
		var rr: Dictionary = ActivityRules.perform(g, _act("rest"), content)
		left.append(g.player.buffs.size())
		if i == 2:
			check.call(rr.expired_buffs == ["hearty_porridge"], "cooking: expiry is reported when it runs out")
	check.call(left == [1, 1, 0, 0], "cooking: buff covers the next 3 slots then expires (%s)" % str(left))
	# Feast needs more food and coins.
	var poor := _g()
	poor.resources.add("food", 2)
	check.call(not ActivityRules.availability(poor, _act("cooking"), "feast").ok and ActivityRules.availability(poor, _act("cooking"), "porridge").ok, "cooking: feast needs 3 food and 5 coins, porridge only 2 food")
	check.call(ActivityRules.availability(poor, _act("cooking")).ok, "cooking: available when any recipe is affordable")


func _buff_rules() -> void:
	var p := PlayerState.new()
	p.add_buff("x", "body", 2, 2)
	p.add_buff("x", "body", 3, 5)
	check.call(p.buffs.size() == 1 and p.effective_attr("body") == 8, "buff: same id replaces, no stacking")
	p.add_buff("y", "body", 1, 1)
	check.call(p.effective_attr("body") == 9, "buff: different ids stack")
	p.add_buff("bad", "luck", 1, 1)
	p.add_buff("zero", "body", 1, 0)
	check.call(p.buffs.size() == 2, "buff: unknown attribute or zero duration is ignored")
	check.call(p.tick_buffs() == ["y"] and p.buffs.size() == 1, "buff: tick removes expired buffs only")
	var round_trip := PlayerState.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check.call(round_trip.buffs.size() == 1 and round_trip.effective_attr("body") == 8, "buff: survives a save round trip")


func _chess_token() -> void:
	var g := _g()
	g.calendar.week = 2
	var r: Dictionary = ActivityRules.perform(g, _act("chess"), content, "master")
	var tokens: int = g.resources.items.get("strategy_token", 0)
	check.call(r.ok and tokens == (2 if r.grade == "success" else 1), "chess: master match grants 2 tokens (1 on a failed check) - got %d" % tokens)
	check.call(g.player.stamina <= 17, "chess: stamina paid")


func _relationships() -> void:
	var g := _g()
	g.calendar.week = 2
	ActivityRules.perform(g, _act("music"), content, "for_lu")
	check.call(g.relationships.scores.get("lu_chenzhou", 0) == 3 and g.relationships.scores.get("shen_qinghe", 0) == 0, "music: only the chosen listener's affinity moves")
	var s := _g()
	s.calendar.week = 2
	s.resources.add("coins", 0)
	var r: Dictionary = ActivityRules.perform(s, _act("social_visit"), content, "gift_bai")
	check.call(r.ok and s.resources.get_amount("coins") == 15 and s.relationships.scores.get("bai_yan", 0) == 7, "social: a gift costs 5 coins and gives +7 affinity")
	var poor := _g()
	poor.calendar.week = 2
	poor.resources.add("coins", -20)
	check.call(not ActivityRules.availability(poor, _act("social_visit"), "gift_bai").ok and ActivityRules.availability(poor, _act("social_visit"), "chat_bai").ok, "social: gift unavailable with no coins; plain chat still works")


## M6-15: every activity x every approach, from several starting states. Must never crash, never take
## stamina or resources below zero, and an unavailable approach must change nothing.
func _matrix() -> void:
	var states := {
		"fresh": func(g: RefCounted) -> void: pass,
		"day2_rich": func(g: RefCounted) -> void:
			g.calendar.week = 2
			for k in ["food", "herbs", "ore", "medicine"]:
				g.resources.add(k, 6)
			g.resources.add("coins", 40),
		"exhausted": func(g: RefCounted) -> void:
			g.calendar.week = 3
			g.player.stamina = 1,
		"empty": func(g: RefCounted) -> void:
			g.calendar.week = 2
			g.resources.add("coins", -99),
		"pathed": func(g: RefCounted) -> void:
			g.calendar.week = 4
			g.player.path_id = "green_sword",
		"finished": func(g: RefCounted) -> void:
			g.calendar.finished = true,
	}
	var combos := 0
	var bad: Array = []
	var table: Array[String] = []
	for sname in states:
		for def in content.activities:
			var ids: Array = [""]
			if not def.get("options", []).is_empty():
				ids = def.options.map(func(o: Dictionary) -> String: return o.id)
			for oid in ids:
				var g := _g(5)
				states[sname].call(g)
				var snap := JSON.stringify(g.to_dict(), "", true)
				var av: Dictionary = ActivityRules.availability(g, def, oid)
				var r: Dictionary = ActivityRules.perform(g, def, content, oid)
				combos += 1
				if r.ok != av.ok:
					bad.append("%s/%s/%s availability disagrees with perform" % [sname, def.id, oid])
				if not r.ok and snap != JSON.stringify(g.to_dict(), "", true):
					bad.append("%s/%s/%s refused but changed state" % [sname, def.id, oid])
				if g.player.stamina < 0 or g.resources.amounts.values().any(func(v: int) -> bool: return v < 0):
					bad.append("%s/%s/%s went negative" % [sname, def.id, oid])
				table.append("%s|%s|%s|%s" % [sname, def.id, oid, r.get("grade", "refused")])
	check.call(bad.is_empty(), "matrix: %d combinations, no crashes or invariant breaks %s" % [combos, str(bad.slice(0, 3))])
	print("MATRIX_TABLE rows=", table.size())
	var f := FileAccess.open("user://m6_matrix.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(table))
		f.close()


func _migration_v3() -> void:
	var svc := SaveService.new()
	var old: Dictionary = _g(4).to_dict()
	old["player"].erase("buffs")
	var migrated := svc.migrate(old, 2)
	check.call(migrated.player.buffs == [], "migration v2->v3: buffs get an empty default")
	var s := GameState.from_dict(migrated)
	check.call(s.player.buffs.is_empty() and s.run_seed == 4, "migration v2->v3: state loads and keeps its data")
	check.call(GameState.SCHEMA_VERSION >= 3, "migration: schema version is at least 3")
	svc.free()
