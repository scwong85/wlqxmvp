extends RefCounted
## M22c tests: Cangwu (weeks 31 to 50): areas, tournament chain, Xie Wujiu, the theft and the Hui-Mask.

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
	_chain()
	_xie()
	content.free()


func _data() -> void:
	var ids := ["cw_gate", "cw_courts", "cw_library", "cw_cave", "cw_spring"]
	check.call(ids.all(func(id: String) -> bool: return content.area(id).region == "cangwu"), "m22c: five Cangwu areas")
	var s: RefCounted = GameState.new_game(3)
	s.calendar.week = 35
	check.call(WorldRules.area_status(s, content, "cw_gate").state == "locked", "m22c: Cangwu is locked without the invitation")
	s.world.add_lead("cangwu_invite")
	check.call(WorldRules.area_status(s, content, "cw_gate").state == "open", "m22c: and opens with it")
	s.calendar.week = 30
	check.call(WorldRules.area_status(s, content, "cw_gate").state == "locked", "m22c: but not before week 31")
	for b in ["xie_duel", "cw_bout_1", "cw_bout_2", "cw_bout_3"]:
		check.call(not content.scenario(b).is_empty(), "m22c: scenario %s exists" % b)
	check.call(content.scenario("cw_bout_3").on_victory.rewards.any(func(r: Dictionary) -> bool: return str(r.get("id", "")) == "manual_pine_sutra"), "m22c: the champion gets the rare manual")


func _chain() -> void:
	game.new_game(72)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	s.world.add_lead("fragment_traced")
	s.world.add_lead("linjiang_token")
	s.calendar.week = 31
	var ev := _play("lj_teahouse", "")
	check.call(ev == "q3_invitation" and s.world.has_lead("cangwu_invite") and s.world.scheduled.has("q3_gate_steps"), "m22c: the invitation plays and opens Cangwu (got '%s')" % ev)
	_jump("q3_gate_steps")
	check.call(_play("cw_gate", "steady") == "q3_gate_steps" and s.relationships.has_flag("gate_steady"), "m22c: the gate trial plays")
	_jump("q3_library")
	check.call(_play("cw_library", "") == "q3_library" and s.world.has_lead("library_files"), "m22c: the library scene plays and gives the files lead")
	s.calendar.week = 39
	s.cultivation.realm = 2
	for step in [["q3_tournament_1", "fight"], ["q3_tournament_2", "fight"], ["q3_tournament_3", "fight"]]:
		_jump(str(step[0]))
		var got := ""
		for i in 3:
			got = _play("cw_courts", str(step[1]))
			if got == str(step[0]):
				break
		check.call(got == str(step[0]), "m22c: %s plays (got '%s')" % [step[0], got])
	check.call(s.relationships.has_flag("champion"), "m22c: winning all three bouts makes the champion")
	s.calendar.week = 44
	var theft := ""
	for i in 3:
		theft = _play("cw_library", "public")
		if theft == "q3_theft":
			break
	check.call(theft == "q3_theft" and s.relationships.has_flag("xie_defended_public"), "m22c: the theft plays and the public defense is recorded (got '%s')" % theft)
	var mask := ""
	for i in 3:
		mask = _play("cw_cave", "")
		if mask == "q3_hui_mask":
			break
	check.call(mask == "q3_hui_mask" and s.world.has_lead("hui_mask_seen"), "m22c: the Hui-Mask is seen")
	game.battle = null


func _xie() -> void:
	var c: Dictionary = content.companion("xie_wujiu")
	check.call(not c.is_empty() and not content.look_of("xie_wujiu").is_empty() and c.battle_abilities.size() == 2, "m22c: Xie Wujiu has data, a look and two abilities")
	check.call(not content.duo_for("xie_wujiu").is_empty(), "m22c: Xie Wujiu has a duo technique")
	var s: RefCounted = GameState.new_game(5)
	s.calendar.week = 30
	RelationshipRules.refresh(s, content)
	check.call(s.relationships.get_status("xie_wujiu") == "unknown", "m22c: Xie is not met before week 35")
	s.calendar.week = 36
	RelationshipRules.refresh(s, content)
	check.call(s.relationships.get_status("xie_wujiu") == "available", "m22c: Xie is met by week 36")
	check.call(ArcRules.summary(s, content, "xie_wujiu").total == 4, "m22c: Xie's arc reads 0/4")


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
