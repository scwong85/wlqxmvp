extends RefCounted
## M24c tests: Year 2 quarter 7 (weeks 91 to 105): Penglai, the second star, the hermit trial and the fifth-realm gate, the sea ambush, stage 2 for Xia Zhi and Xiao.

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
	_chain()
	_gate()
	_arcs()
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
	return s


func _data() -> void:
	check.call(["pd_harbour", "pd_cave", "pd_monastery"].all(func(id: String) -> bool: return content.area(id).region == "penglai"), "m24c: three Penglai areas")
	var s: RefCounted = GameState.new_game(3)
	s.calendar.week = 95
	check.call(WorldRules.area_status(s, content, "pd_harbour").state == "locked", "m24c: Penglai is locked without the route lead")
	s.world.add_lead("penglai_route")
	check.call(WorldRules.area_status(s, content, "pd_harbour").state == "open", "m24c: and opens with it")
	s.calendar.week = 85
	check.call(WorldRules.area_status(s, content, "pd_harbour").state == "locked", "m24c: but not before week 91")
	for b in ["y2_hermit_trial", "y2_sea_ambush", "y2_harbour_brawl"]:
		check.call(not content.scenario(b).is_empty(), "m24c: scenario %s exists" % b)


func _chain() -> void:
	var s: RefCounted = _fresh(95)
	s.calendar.week = 89
	var ev := _play("lj_docks", "pay")
	check.call(ev == "y2_guild_ship" and s.world.has_lead("penglai_route"), "m24c: the ship scene gives the sea route (got '%s')" % ev)
	s.calendar.week = 91
	_jump("y2_crossing")
	ev = _play("pd_harbour", "rope")
	check.call(ev == "y2_crossing" and s.relationships.has_flag("crossing_rope"), "m24c: the storm crossing plays (got '%s')" % ev)
	_jump("y2_yun_mian")
	ev = _play("pd_monastery", "protect")
	check.call(ev == "y2_yun_mian" and s.relationships.has_flag("yun_guard") and s.world.has_lead("hermit_trials"), "m24c: Yun Mian asks her question (got '%s')" % ev)
	_jump("y2_coral_cave")
	ev = _play("pd_cave", "take")
	check.call(ev == "y2_coral_cave" and s.world.has_lead("fragment_two") and s.world.scheduled.has("y2_trial_breakthrough"), "m24c: the second star is found (got '%s')" % ev)
	_jump("y2_trial_breakthrough")
	ev = _play("pd_monastery", "face")
	check.call(ev == "y2_trial_breakthrough" and s.relationships.has_flag("hermit_trial_done") and s.world.scheduled.has("y2_ship_back"), "m24c: the hermit trial is fought (got '%s')" % ev)
	_jump("y2_ship_back")
	ev = _play("pd_harbour", "fight")
	check.call(ev == "y2_ship_back" and s.relationships.has_flag("sea_ambush_won"), "m24c: the sea ambush is won (got '%s')" % ev)
	game.battle = null


func _gate() -> void:
	var s: RefCounted = GameState.new_game(4)
	s.player.path_id = "xuan_fist"
	s.cultivation.realm = 3
	var lines: Array = RealmRules.requirement_lines(s, content)
	var hermit := lines.filter(func(l: Dictionary) -> bool: return str(l.key) == "hermit")
	check.call(hermit.size() == 1 and not hermit[0].met, "m24c: the fifth realm lists the hermit trial as unmet")
	s.relationships.set_flag("hermit_trial_done")
	lines = RealmRules.requirement_lines(s, content)
	hermit = lines.filter(func(l: Dictionary) -> bool: return str(l.key) == "hermit")
	check.call(hermit.size() == 1 and hermit[0].met, "m24c: and as met once the trial is done")
	# a skipped trial scene still sets the flag
	check.call(content.event("y2_trial_breakthrough").on_miss.any(func(e: Dictionary) -> bool: return str(e.get("id", "")) == "hermit_trial_done"), "m24c: missing the trial never blocks the realm")


func _arcs() -> void:
	var s: RefCounted = _fresh(96)
	s.calendar.week = 90
	s.relationships.add_score("xia_zhi", 9)
	s.relationships.arcs["xia_zhi"] = {"stage": 1}
	var ev := ""
	for i in 4:
		ev = _play("lj_alleys", "")
		if ev == "arc_xia_zhi_2":
			break
	check.call(ev == "arc_xia_zhi_2" and ArcRules.stage(s, "xia_zhi") == 2 and s.world.has_lead("gate_errand"), "m24c: Xia Zhi's stage 2 plays (got '%s')" % ev)
	s.relationships.add_score("xiao_hanchuan", 9)
	s.relationships.arcs["xiao_hanchuan"] = {"stage": 1}
	s.world.add_lead("yanmen_road")
	ev = ""
	for i in 4:
		ev = _play("ym_fort", "")
		if ev == "arc_xiao_hanchuan_2":
			break
	check.call(ev == "arc_xiao_hanchuan_2" and ArcRules.stage(s, "xiao_hanchuan") == 2 and s.world.has_lead("fathers_reply"), "m24c: Xiao's stage 2 plays (got '%s')" % ev)
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
