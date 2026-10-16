extends RefCounted
## M24d tests: Year 2 quarter 8 (weeks 106 to 120): the council, the five stage-3 tests, the betrayal and rescue, the Solstice, the year's close and a 120-week random walk.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
const RealmRules = preload("res://scripts/domain/realm_rules.gd")
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
	_council()
	_tests()
	_betrayal()
	_close()
	_fuzz()
	content.free()


func _fresh(seed_value: int) -> RefCounted:
	game.new_game(seed_value)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	s.world.add_lead("linjiang_token")
	s.world.add_lead("cangwu_invite")
	s.world.add_lead("penglai_route")
	s.world.add_lead("yanmen_road")
	return s


func _data() -> void:
	for id in ["y2_council", "arc_xie_wujiu_3", "arc_su_dai_3", "arc_li_shan_3", "arc_xia_zhi_3", "arc_xiao_hanchuan_3", "y2_betrayal", "y2_rescue", "y2_solstice", "y2_winter_end"]:
		check.call(not content.event(id).is_empty(), "m24d: event %s exists" % id)
	for b in ["y2_public_proof", "y2_break_ranks", "y2_rescue"]:
		check.call(not content.scenario(b).is_empty(), "m24d: scenario %s exists" % b)
	var s: RefCounted = GameState.new_game(1)
	for cid in ["shen_qinghe", "lu_chenzhou", "bai_yan", "xie_wujiu", "su_dai", "li_shan", "xia_zhi", "xiao_hanchuan"]:
		check.call(ArcRules.arc_of(content, cid).stages.size() >= 3, "m24d: %s has at least three authored arc stages" % cid)


func _council() -> void:
	var s: RefCounted = _fresh(100)
	s.calendar.week = 107
	var ev := _play("lj_teahouse", "trade")
	check.call(ev == "y2_council" and s.relationships.has_flag("council_trade") and s.world.has_lead("houses_split"), "m24d: the council plays (got '%s')" % ev)


func _stage3(cid: String, area: String, pick: String, expect_outcome: String, week: int) -> void:
	var s: RefCounted = _fresh(101)
	s.calendar.week = week
	s.relationships.add_score(cid, 13)
	s.relationships.arcs[cid] = {"stage": 2, "outcome": "", "bond": ""}
	for n in [1, 2]:
		s.world.done["arc_%s_%d" % [cid, n]] = 1
	var ev := ""
	for i in 5:
		ev = _play(area, pick)
		if ev == "arc_%s_3" % cid:
			break
	var rec: Dictionary = s.relationships.arcs.get(cid, {})
	check.call(ev == "arc_%s_3" % cid and ArcRules.stage(s, cid) == 3 and str(rec.get("outcome", "")) == expect_outcome, "m24d: %s stage 3 with '%s' ends '%s' (got '%s', %s)" % [cid, pick, expect_outcome, ev, str(rec)])
	game.battle = null


func _tests() -> void:
	_stage3("xie_wujiu", "cw_courts", "public", "redeemed", 108)
	_stage3("xie_wujiu", "cw_courts", "drop", "lost", 108)
	_stage3("su_dai", "lj_market", "share", "redeemed", 110)
	_stage3("su_dai", "lj_market", "sell", "lost", 110)
	_stage3("li_shan", "lj_docks", "together", "redeemed", 110)
	_stage3("li_shan", "lj_docks", "small", "alternate", 110)
	_stage3("xia_zhi", "lj_alleys", "defect", "redeemed", 112)
	_stage3("xia_zhi", "lj_alleys", "steal", "lost", 112)
	_stage3("xiao_hanchuan", "ym_fort", "break", "redeemed", 108)
	_stage3("xiao_hanchuan", "ym_fort", "petition", "alternate", 108)
	# Missing a test closes the arc as lost, never a dead end.
	check.call(content.event("arc_su_dai_3").on_miss.any(func(e: Dictionary) -> bool: return str(e.get("type", "")) == "arc_outcome"), "m24d: a missed test resolves the arc")


func _betrayal_case(flag: String, expect_flag: String, pick: String) -> void:
	var s: RefCounted = _fresh(102)
	if flag != "":
		s.relationships.set_flag(flag)
	s.calendar.week = 113
	var ev := ""
	for i in 4:
		ev = _play("lj_alleys", pick)
		if ev == "y2_betrayal":
			break
	check.call(ev == "y2_betrayal" and s.relationships.has_flag(expect_flag), "m24d: betrayal [%s] + '%s' sets %s (got '%s')" % [flag, pick, expect_flag, ev])
	if pick == "chase":
		check.call(s.world.scheduled.has("y2_rescue"), "m24d: chasing schedules the rescue")
		_jump("y2_rescue")
		var r := _play("lj_alleys", "fight")
		check.call(r == "y2_rescue" and s.relationships.has_flag("rescued"), "m24d: the rescue is fought and won (got '%s')" % r)
	game.battle = null


func _betrayal() -> void:
	_betrayal_case("xia_caught", "betrayal_chased", "chase")
	_betrayal_case("xia_caught", "xia_zhi_betrayed", "release")
	_betrayal_case("xie_abandoned", "xie_wujiu_betrayed", "release")
	_betrayal_case("", "betrayal_chased", "chase")
	_betrayal_case("", "council_leaked", "release")


func _close() -> void:
	var s: RefCounted = _fresh(103)
	s.calendar.week = 113
	var ev := _play("valley_village", "friends")
	check.call(ev == "y2_solstice" and s.relationships.has_flag("solstice2_together"), "m24d: the second Solstice plays (got '%s')" % ev)
	s.calendar.week = 119
	ev = ""
	for i in 3:
		ev = _play("valley_village", "")
		if ev == "y2_winter_end":
			break
	check.call(ev == "y2_winter_end" and s.relationships.has_flag("year2_done") and s.world.has_lead("vault_second_gate"), "m24d: the year closes with the second-gate lead (got '%s')" % ev)


## A random walk through years 1 and 2 (120 weeks): it must reach the end without errors or dead ends.
func _fuzz() -> void:
	for seed in [21, 22]:
		game.new_game(seed)
		var s: RefCounted = game.state
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var guard := 0
		var seen := {}
		while s.calendar.week <= 120 and guard < 3000 and not s.calendar.finished:
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
		check.call(s.calendar.week > 120 or guard >= 3000, "m24d: fuzz seed %d reaches week %d (%d steps)" % [seed, s.calendar.week, guard])
		check.call(seen.size() >= 15, "m24d: fuzz seed %d saw %d different events" % [seed, seen.size()])
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
