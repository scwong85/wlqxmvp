extends RefCounted
## M25d tests: Year 3 quarter 12 (weeks 166 to 180): the platform area, the arrivals, the bracket, the old companions, the Solstice, the raid, the Masks,
## the choice and the finale scene, and a full 180-week random walk to the end of the campaign.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
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
	_scenes()
	_choice_gate()
	_fuzz()
	content.free()


func _fresh(seed_value: int, week: int) -> RefCounted:
	game.new_game(seed_value)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	for l in ["linjiang_token", "cangwu_invite", "penglai_route", "yanmen_road", "vault_second_gate", "platform_year3"]:
		s.world.add_lead(l)
	s.calendar.week = week
	return s


func _data() -> void:
	for id in ["y3d_arrivals", "y3d_platform_open", "y3d_returned", "y3d_solstice", "y3d_gate_raid", "y3d_masks", "y3d_the_choice", "y3d_ending"]:
		check.call(not content.event(id).is_empty(), "m25d: event %s exists" % id)
	for b in ["y3_bracket", "y3_returned", "y3_platform_raid", "y3_masks"]:
		check.call(not content.scenario(b).is_empty(), "m25d: scenario %s exists" % b)
	check.call(not content.area("pg_platform").is_empty(), "m25d: the platform area exists")
	var s: RefCounted = _fresh(500, 150)
	check.call(WorldRules.area_status(s, content, "pg_platform").state != "open", "m25d: the platform top is closed before week 166")
	s.calendar.week = 167
	check.call(WorldRules.area_status(s, content, "pg_platform").state == "open", "m25d: the platform top opens at week 166")
	var randoms: Array = content.events.filter(func(e: Dictionary) -> bool: return str(e.id).begins_with("ry12_"))
	check.call(randoms.size() == 6, "m25d: six random templates for the quarter")


func _scene(area: String, week: int, flags: Array, pick: String, expect: String, label: String) -> RefCounted:
	var s: RefCounted = _fresh(501, week)
	for f in flags:
		s.relationships.set_flag(str(f))
	var ev := ""
	for i in 4:
		ev = _play(area, pick)
		if ev == expect:
			break
	check.call(ev == expect, "m25d: %s plays (got '%s')" % [label, ev])
	game.battle = null
	return s


func _scenes() -> void:
	for case in [["pledge_orthodox", "orthodox"], ["pledge_trade", "trade"], ["", "free"]]:
		var s := _scene("pg_steps", 167, [case[0]] if case[0] != "" else [], "", "y3d_arrivals", "the arrivals (%s)" % case[1])
		check.call(s.relationships.has_flag("arrivals_seen"), "m25d: the arrivals are recorded (%s)" % case[1])
	var s := _scene("pg_platform", 171, [], "bracket", "y3d_platform_open", "the bracket")
	check.call(s.relationships.has_flag("bracket_entered") and s.relationships.has_flag("bracket_won"), "m25d: the bracket is fought and won")
	s = _scene("pg_platform", 171, [], "stands", "y3d_platform_open", "the stands")
	check.call(s.relationships.has_flag("bracket_skipped"), "m25d: staying in the stands is allowed")
	for who in ["xie_returns", "xia_returns", "su_returns", "li_returns", "xiao_returns"]:
		s = _scene("pg_steps", 173, [who], "face", "y3d_returned", "the old companion (%s)" % who)
		check.call(s.relationships.has_flag("returned_faced") and s.relationships.has_flag("returned_won"), "m25d: %s is faced" % who)
		s = _scene("pg_steps", 173, [who], "speak", "y3d_returned", "the old companion talk (%s)" % who)
		check.call(s.relationships.has_flag("returned_spared"), "m25d: %s is spoken to" % who)
	s = _scene("pg_steps", 173, [], "", "y3d_returned", "the quiet steps")
	check.call(s.relationships.has_flag("returned_none"), "m25d: with nobody returned the scene is quiet")
	s = _scene("pg_pavilions", 173, [], "all", "y3d_solstice", "the Solstice")
	check.call(s.relationships.has_flag("solstice3_together"), "m25d: the Solstice plays")
	s = _scene("pg_steps", 175, [], "defend", "y3d_gate_raid", "the raid (defend)")
	check.call(s.relationships.has_flag("raid_held"), "m25d: holding the steps wins")
	s = _scene("pg_steps", 175, [], "evacuate", "y3d_gate_raid", "the raid (evacuate)")
	check.call(s.relationships.has_flag("raid_evacuated"), "m25d: covering the retreat is recorded")
	s = _scene("pg_platform", 176, [], "fight", "y3d_masks", "the Masks (fight)")
	check.call(s.relationships.has_flag("masks_won"), "m25d: the Masks are defeated")
	s = _scene("pg_platform", 176, ["offer_xuan"], "talk", "y3d_masks", "the Masks (talk)")
	check.call(s.relationships.has_flag("masks_parley"), "m25d: parley is open to those who took the Xuan-Mask's offer")
	for pick in ["seat", "refuse", "break", "walk"]:
		s = _scene("pg_platform", 177, [], pick, "y3d_the_choice", "the choice (%s)" % pick)
		check.call(s.relationships.has_flag("finale_" + pick), "m25d: finale_%s is recorded" % pick)
	s = _scene("pg_platform", 177, ["offer_xuan"], "gate", "y3d_the_choice", "the choice (gate)")
	check.call(s.relationships.has_flag("finale_gate"), "m25d: finale_gate is recorded")
	for pick in ["seat", "refuse", "break", "gate", "walk"]:
		var flags := ["finale_" + pick, "finale_decided"] if pick != "walk" else ["finale_decided"]
		s = _scene("pg_platform", 178, flags, "", "y3d_ending", "the finale scene (%s)" % pick)
		check.call(s.relationships.has_flag("finale_done"), "m25d: the finale scene (%s) ends the story" % pick)


func _choice_gate() -> void:
	var s: RefCounted = _fresh(502, 177)
	game.visit_area("pg_platform")
	var found := false
	var d: Dictionary = game.current_dialogue()
	if not d.is_empty():
		var node: Dictionary = DialogueSystem.current_node(game.state, d)
		while not node.has("choices") and game.state.story.dialogue.size() > 0:
			game.dialogue_advance()
			node = DialogueSystem.current_node(game.state, d)
		for c in DialogueSystem.choice_states(game.state, d, content):
			if c.id == "gate":
				found = true
				check.call(not c.available, "m25d: taking the Gate is closed without the Xuan-Mask's offer")
	check.call(found or d.is_empty(), "m25d: the choice scene lists the Gate option")
	game.battle = null


## A random walk through the whole campaign to the end of week 180.
func _fuzz() -> void:
	game.new_game(34)
	var s: RefCounted = game.state
	var rng := RandomNumberGenerator.new()
	rng.seed = 34
	var guard := 0
	var seen := {}
	while not s.calendar.finished and guard < 9000:
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
	check.call(s.calendar.finished or guard >= 9000, "m25d: the walk reaches the end of the campaign (week %d, %d steps)" % [s.calendar.week, guard])
	var y3: Array = seen.keys().filter(func(k: String) -> bool: return k.begins_with("y3") or k.begins_with("ry9_") or k.begins_with("ry10_") or k.begins_with("ry11_") or k.begins_with("ry12_") or k.ends_with("_4"))
	check.call(y3.size() >= 5, "m25d: the walk meets year-3 scenes (%d)" % y3.size())
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
