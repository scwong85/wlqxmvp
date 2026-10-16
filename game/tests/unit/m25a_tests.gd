extends RefCounted
## M25a tests: Year 3 quarter 9 (weeks 121 to 135): the new year openings, the Gate in the open, the summons, the valley, the Chi-Mask,
## the border, stage 4 for Xie Wujiu and Xia Zhi, and a 135-week random walk.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node
var game: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	game = Engine.get_main_loop().root.get_node("Game")
	_data()
	_openings()
	_stage4()
	_fuzz()
	content.free()


func _fresh(seed_value: int, week: int) -> RefCounted:
	game.new_game(seed_value)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	for l in ["linjiang_token", "cangwu_invite", "penglai_route", "yanmen_road"]:
		s.world.add_lead(l)
	s.calendar.week = week
	return s


func _data() -> void:
	for id in ["y3_new_year", "y3_gate_opens", "y3_house_summons", "y3_valley_returns", "y3_chi_mask", "y3_border_burns", "y3_border_choice", "arc_xie_wujiu_4", "arc_xia_zhi_4"]:
		check.call(not content.event(id).is_empty(), "m25a: event %s exists" % id)
	for b in ["y3_guild_hall", "y3_chi_duel", "y3_border_defence"]:
		check.call(not content.scenario(b).is_empty(), "m25a: scenario %s exists" % b)
	for cid in ["xie_wujiu", "xia_zhi"]:
		check.call(ArcRules.arc_of(content, cid).stages.size() == 4, "m25a: %s has all four arc stages" % cid)
	var randoms: Array = content.events.filter(func(e: Dictionary) -> bool: return str(e.id).begins_with("ry9_"))
	check.call(randoms.size() == 8, "m25a: eight random templates for the quarter")


## Plays one scene in `area` (picking `pick`), after setting up flags; returns the event id.
func _scene(area: String, week: int, flags: Array, pick: String, expect: String, label: String) -> RefCounted:
	var s: RefCounted = _fresh(200, week)
	for f in flags:
		s.relationships.set_flag(str(f))
	var ev := ""
	for i in 4:
		ev = _play(area, pick)
		if ev == expect:
			break
	check.call(ev == expect, "m25a: %s plays (got '%s')" % [label, ev])
	game.battle = null
	return s


func _openings() -> void:
	var s := _scene("valley_village", 121, ["council_orthodox"], "", "y3_new_year", "the new year (orthodox opening)")
	check.call(s.relationships.has_flag("year3_start"), "m25a: the new year sets year3_start")
	for case in [["council_trade", "trade"], ["", "free"]]:
		var s2 := _scene("valley_village", 121, [case[0]] if case[0] != "" else [], "", "y3_new_year", "the new year (%s)" % case[1])
		check.call(s2.relationships.has_flag("year3_start"), "m25a: %s opening ends the scene" % case[1])
	s = _scene("lj_teahouse", 123, [], "storm", "y3_gate_opens", "the grey banner")
	check.call(s.world.has_lead("gate_unmasked") and s.relationships.has_flag("guild_hall_won"), "m25a: storming the hall wins and opens the lead")
	s = _scene("lj_teahouse", 123, [], "warn", "y3_gate_opens", "the grey banner (warn)")
	check.call(s.relationships.has_flag("guild_hall_lost"), "m25a: warning the houses leaves the hall to the Gate")
	s = _scene("lj_teahouse", 126, ["year3_start", "y3_gate_opens_seen"], "orthodox", "y3_house_summons", "the summons")
	check.call(s.relationships.has_flag("seat_orthodox") and s.world.has_lead("platform_summons"), "m25a: the summons records a seat")
	for case in [["elder_fallen", "fall"], ["valley_kept", "kept"], ["", "away"]]:
		s = _scene("valley_village", 127, [case[0]] if case[0] != "" else [], "", "y3_valley_returns", "the valley (%s)" % case[1])
		check.call(s.relationships.has_flag("ninth_house_named") and s.world.has_lead("ninth_house"), "m25a: the valley names the ninth house (%s)" % case[1])
	s = _scene("lj_alleys", 130, [], "duel", "y3_chi_mask", "the Chi-Mask")
	check.call(s.relationships.has_flag("chi_duel_won"), "m25a: the Chi-Mask duel is won")
	s = _scene("lj_alleys", 130, [], "slip", "y3_chi_mask", "the Chi-Mask (slip away)")
	check.call(s.relationships.has_flag("chi_declined"), "m25a: slipping away is recorded")
	# The border: the scene schedules a choice.
	for pick in ["defend", "evacuate"]:
		s = _scene("ym_fort", 132, [], "", "y3_border_burns", "the border burns")
		check.call(s.world.scheduled.has("y3_border_choice") and s.world.has_lead("border_burns"), "m25a: the border scene schedules its choice")
		_jump("y3_border_choice")
		var ev := ""
		for i in 3:
			ev = _play("ym_fort", pick)
			if ev == "y3_border_choice":
				break
		check.call(ev == "y3_border_choice", "m25a: the border choice '%s' plays (got '%s')" % [pick, ev])
		check.call(s.relationships.has_flag("border_held") if pick == "defend" else s.relationships.has_flag("border_evacuated"), "m25a: the border choice '%s' leaves its flag" % pick)
		game.battle = null


func _stage4_case(cid: String, area: String, week: int, outcome: String, pick: String, expect_bond: String, bond_score: int) -> void:
	var s: RefCounted = _fresh(201, week)
	s.relationships.add_score(cid, bond_score)
	s.relationships.arcs[cid] = {"stage": 3, "outcome": outcome, "bond": ""}
	if outcome != "":
		s.relationships.set_flag("arcout_%s_%s" % [cid, outcome])
	for n in [1, 2, 3]:
		s.world.done["arc_%s_%d" % [cid, n]] = 1
	var ev := ""
	for i in 4:
		ev = _play(area, pick)
		if ev == "arc_%s_4" % cid:
			break
	var rec: Dictionary = s.relationships.arcs.get(cid, {})
	check.call(ev == "arc_%s_4" % cid and ArcRules.stage(s, cid) == 4 and str(rec.get("bond", "")) == expect_bond, "m25a: %s stage 4 (%s, '%s') records bond '%s' (got '%s', %s)" % [cid, outcome, pick, expect_bond, ev, str(rec)])
	game.battle = null


func _stage4() -> void:
	_stage4_case("xie_wujiu", "cw_courts", 126, "redeemed", "romance", "romance", 20)
	_stage4_case("xie_wujiu", "cw_courts", 126, "alternate", "sworn", "sworn", 20)
	_stage4_case("xie_wujiu", "cw_courts", 126, "alternate", "rival", "rival", 8)
	_stage4_case("xie_wujiu", "cw_courts", 126, "redeemed", "romance", "friend", 10)   # a weak bond cannot take the romance branch; friend is the first open choice
	_stage4_case("xia_zhi", "lj_alleys", 130, "redeemed", "sworn", "sworn", 20)
	_stage4_case("xia_zhi", "lj_alleys", 130, "alternate", "friend", "friend", 12)
	for cid in ["xie_wujiu", "xia_zhi"]:
		var area := "cw_courts" if cid == "xie_wujiu" else "lj_alleys"
		var s: RefCounted = _fresh(202, 132)
		s.relationships.add_score(cid, 8)
		s.relationships.arcs[cid] = {"stage": 3, "outcome": "lost", "bond": ""}
		s.relationships.set_flag("arcout_%s_lost" % cid)
		for n in [1, 2, 3]:
			s.world.done["arc_%s_%d" % [cid, n]] = 1
		var ev := ""
		for i in 4:
			ev = _play(area, "")
			if ev == "arc_%s_4" % cid:
				break
		var returns := "xie_returns" if cid == "xie_wujiu" else "xia_returns"
		check.call(ev == "arc_%s_4" % cid and ArcRules.stage(s, cid) == 4 and s.relationships.has_flag(returns) and ArcRules.bond_type(s, cid) == "", "m25a: %s's farewell closes a lost arc and may return (got '%s')" % [cid, ev])
		game.battle = null
	check.call(content.event("arc_xie_wujiu_4").on_miss.any(func(e: Dictionary) -> bool: return str(e.get("type", "")) == "arc_stage"), "m25a: a missed stage 4 still closes the arc")


## A random walk through years 1 to 3 up to week 135.
func _fuzz() -> void:
	game.new_game(31)
	var s: RefCounted = game.state
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var guard := 0
	var seen := {}
	while s.calendar.week <= 135 and guard < 4000 and not s.calendar.finished:
		guard += 1
		if s.player.stamina < 8:
			game.perform_activity("rest")
			continue
		var open: Array = []
		for a in content.areas:
			if WorldRules.area_status(s, content, str(a.id)).state == "open":
				open.append(str(a.id))
		if open.is_empty() or rng.randf() < 0.25:
			game.perform_activity("training")
			continue
		var ev := _play(str(open[rng.randi() % open.size()]), "")
		if ev != "":
			seen[ev] = true
	check.call(s.calendar.week > 135 or guard >= 4000, "m25a: fuzz reaches week %d (%d steps)" % [s.calendar.week, guard])
	var y3: Array = seen.keys().filter(func(k: String) -> bool: return k.begins_with("y3_") or k.begins_with("ry9_") or k.ends_with("_4"))
	check.call(y3.size() >= 3, "m25a: the walk meets some year-3 scenes (%d)" % y3.size())
	game.battle = null


## Visits an area and plays whatever event is offered, picking `pick` where there is a choice. Returns the event id.
func _play(area: String, pick: String) -> String:
	var v: Dictionary = game.visit_area(area)
	if not v.ok or v.event_id == "":
		return ""
	var guard := 0
	while guard < 30 and game.state.story.dialogue.size() > 0:
		guard += 1
		var dlg: Dictionary = game.current_dialogue()
		var node: Dictionary = DialogueSystem.current_node(game.state, dlg)
		var res: Dictionary
		if node.has("choices"):
			var choice := ""
			var first := ""
			for c in DialogueSystem.choice_states(game.state, dlg, content):
				if c.available and first == "":
					first = c.id
				if c.available and c.id == pick:
					choice = c.id
			res = game.dialogue_choose(choice if choice != "" else first)
		else:
			res = game.dialogue_advance()
		if res.get("ended", false):
			var nxt: String = game.after_dialogue(res)
			if nxt == "battle":
				game.battle.outcome = "victory"
				game.finish_battle()
			break
	return str(v.event_id)


func _jump(event_id: String) -> void:
	var sch: Variant = game.state.world.scheduled.get(event_id)
	if sch != null:
		game.state.calendar.week = maxi(game.state.calendar.week, int(sch.from))
