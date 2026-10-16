extends RefCounted
## M24a tests: Year 2 quarter 5 (weeks 61 to 75): the New Year payoff, the Gate scenes, Xia Zhi, the riot, Xie's stage 2 and the Hui-Mask letter.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
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
	_new_year()
	_chain()
	_xia()
	content.free()


func _fresh(seed_value: int) -> RefCounted:
	game.new_game(seed_value)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	s.world.add_lead("linjiang_token")
	s.world.add_lead("cangwu_invite")
	return s


func _data() -> void:
	for id in ["y2_new_year", "y2_black_banner", "y2_xia_zhi", "y2_house_replaced", "y2_barge_riot", "y2_hui_letter", "arc_xie_wujiu_2", "arc_xia_zhi_1"]:
		check.call(not content.event(id).is_empty(), "m24a: event %s exists" % id)
	for b in ["y2_barge_riot", "y2_patrol", "y2_xia_catch"]:
		check.call(not content.scenario(b).is_empty(), "m24a: scenario %s exists" % b)
	check.call(int(content.event("y2_new_year").window.from) == 61, "m24a: Year 2 starts at week 61")


func _new_year() -> void:
	for case in [["valley_kept", "live"], ["elder_retired", "adv"], ["elder_fallen", "seal"]]:
		var s: RefCounted = _fresh(80)
		s.relationships.set_flag(str(case[0]))
		s.calendar.week = 61
		var ev := _play("valley_village", "")
		check.call(ev == "y2_new_year" and s.relationships.has_flag("y2_new_year_done"), "m24a: New Year plays for %s (got '%s')" % [case[0], ev])
		if case[0] == "elder_fallen":
			check.call(s.world.has_lead("seal_inscription"), "m24a: the fallen branch gives the seal lead")


func _chain() -> void:
	var s: RefCounted = _fresh(81)
	s.calendar.week = 63
	var ev := _play("lj_market", "probe")
	check.call(ev == "y2_black_banner" and s.world.has_lead("gate_banner"), "m24a: the black banner plays (got '%s')" % ev)
	s.calendar.week = 66
	ev = _play("lj_teahouse", "")
	check.call(ev == "y2_house_replaced" and s.world.scheduled.has("y2_barge_riot"), "m24a: the guild changes hands and schedules the riot (got '%s')" % ev)
	_jump("y2_barge_riot")
	ev = _play("lj_docks", "fight")
	check.call(ev == "y2_barge_riot" and s.relationships.has_flag("riot_won"), "m24a: the riot battle is fought and won (got '%s')" % ev)
	s.calendar.week = 71
	ev = _play("cw_cave", "")
	check.call(ev == "y2_hui_letter" and s.world.has_lead("yanmen_road"), "m24a: the Hui-Mask letter opens the Yanmen lead (got '%s')" % ev)
	game.battle = null


func _xia() -> void:
	var s: RefCounted = _fresh(82)
	s.calendar.week = 60
	RelationshipRules.refresh(s, content)
	check.call(s.relationships.get_status("xia_zhi") == "unknown", "m24a: Xia Zhi is not met before week 64")
	s.calendar.week = 65
	var ev := ""
	for i in 4:
		ev = _play("lj_alleys", "bargain")
		if ev == "y2_xia_zhi":
			break
	check.call(ev == "y2_xia_zhi" and s.world.has_lead("xia_orders") and s.relationships.get_score("xia_zhi") >= 3, "m24a: the alley meeting plays (got '%s')" % ev)
	var c: Dictionary = content.companion("xia_zhi")
	check.call(not content.look_of("xia_zhi").is_empty() and c.battle_abilities.size() == 2 and not content.duo_for("xia_zhi").is_empty(), "m24a: Xia Zhi has a look, two abilities and a duo technique")
	s.relationships.add_score("xia_zhi", 2)
	var arc_ev := ""
	for i in 4:
		arc_ev = _play("lj_alleys", "")
		if arc_ev == "arc_xia_zhi_1":
			break
	check.call(arc_ev == "arc_xia_zhi_1" and ArcRules.stage(s, "xia_zhi") == 1, "m24a: her stage 1 plays (got '%s')" % arc_ev)
	check.call(ArcRules.summary(s, content, "xia_zhi").total == 4, "m24a: her arc reads 1/4")
	# Xie's stage 2
	var g: RefCounted = _fresh(83)
	g.calendar.week = 66
	g.relationships.add_score("xie_wujiu", 9)
	g.relationships.arcs["xie_wujiu"] = {"stage": 1}
	var x := ""
	for i in 3:
		x = _play("cw_courts", "")
		if x == "arc_xie_wujiu_2":
			break
	check.call(x == "arc_xie_wujiu_2" and ArcRules.stage(g, "xie_wujiu") == 2 and g.world.has_lead("grey_wax"), "m24a: Xie's stage 2 plays (got '%s')" % x)
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
