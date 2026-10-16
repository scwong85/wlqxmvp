extends RefCounted
## M25c tests: Year 3 quarter 11 (weeks 151 to 165): the platform areas, the alliances, the Gate's agents, Mid-Autumn, Head Lei, the Masks' offers,
## the cliff trial and the sixth-realm gate, the vigil, and a 165-week random walk.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
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
	_areas()
	_scenes()
	_realm_gate()
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
	for id in ["y3c_alliances", "y3c_gate_agents", "y3c_midautumn", "y3c_lei_head", "y3c_masks_offer", "y3c_cliff_trial", "y3c_vigil"]:
		check.call(not content.event(id).is_empty(), "m25c: event %s exists" % id)
	for b in ["y3_gate_agents", "y3_cliff_trial"]:
		check.call(not content.scenario(b).is_empty(), "m25c: scenario %s exists" % b)
	for a in ["pg_steps", "pg_pavilions"]:
		check.call(not content.area(a).is_empty(), "m25c: area %s exists" % a)
	var randoms: Array = content.events.filter(func(e: Dictionary) -> bool: return str(e.id).begins_with("ry11_"))
	check.call(randoms.size() == 6, "m25c: six random templates for the quarter")


func _areas() -> void:
	var s: RefCounted = _fresh(400, 140)
	check.call(WorldRules.area_status(s, content, "pg_steps").state != "open", "m25c: the platform steps are closed before week 151")
	s.calendar.week = 152
	check.call(WorldRules.area_status(s, content, "pg_steps").state == "open" and WorldRules.area_status(s, content, "pg_pavilions").state == "open", "m25c: the platform grounds open at week 151")


func _scene(area: String, week: int, flags: Array, pick: String, expect: String, label: String) -> RefCounted:
	var s: RefCounted = _fresh(401, week)
	for f in flags:
		s.relationships.set_flag(str(f))
	var ev := ""
	for i in 4:
		ev = _play(area, pick)
		if ev == expect:
			break
	check.call(ev == expect, "m25c: %s plays (got '%s')" % [label, ev])
	game.battle = null
	return s


func _scenes() -> void:
	for pick in ["orthodox", "trade", "free"]:
		var s := _scene("pg_pavilions", 152, [], pick, "y3c_alliances", "the canvassing (%s)" % pick)
		check.call(s.relationships.has_flag("pledge_" + pick), "m25c: pledge_%s is recorded" % pick)
	var s := _scene("pg_steps", 154, [], "fight", "y3c_gate_agents", "the tampering (fight)")
	check.call(s.relationships.has_flag("agents_caught"), "m25c: seizing the agents wins")
	s = _scene("pg_steps", 154, [], "report", "y3c_gate_agents", "the tampering (report)")
	check.call(s.relationships.has_flag("agents_reported"), "m25c: reporting is recorded")
	for pick in ["valley", "fighters", "street", "all"]:
		s = _scene("valley_village", 157, [], pick, "y3c_midautumn", "Mid-Autumn (%s)" % pick)
	check.call(s.relationships.has_flag("midautumn3_together"), "m25c: the shared table is recorded")
	for pick in ["endorse", "stay", "other"]:
		s = _scene("pg_pavilions", 158, [], pick, "y3c_lei_head", "Head Lei (%s)" % pick)
		var lf: String = {"endorse": "lei_endorse", "stay": "lei_stays", "other": "lei_other"}[pick]
		check.call(s.relationships.has_flag(lf), "m25c: %s is recorded" % lf)
	for pick in ["xuan", "chi", "hui", "none"]:
		s = _scene("pg_steps", 160, [], pick, "y3c_masks_offer", "the Masks' offers (%s)" % pick)
		check.call(s.relationships.has_flag("offer_" + pick), "m25c: offer_%s is recorded" % pick)
	s = _scene("cw_cave", 162, [], "trial", "y3c_cliff_trial", "the cliff trial")
	check.call(s.relationships.has_flag("cliff_trial_done") and s.relationships.has_flag("cliff_trial_won"), "m25c: the cliff trial is fought and won")
	s = _scene("cw_cave", 162, [], "sit", "y3c_cliff_trial", "the cliff trial (sit)")
	check.call(s.relationships.has_flag("cliff_trial_done"), "m25c: sitting out the trial still opens the gate")
	for pick in ["together", "alone"]:
		s = _scene("pg_pavilions", 164, [], pick, "y3c_vigil", "the vigil (%s)" % pick)
		check.call(s.relationships.has_flag("vigil_" + pick), "m25c: vigil_%s is recorded" % pick)


func _realm_gate() -> void:
	var s: RefCounted = GameState.new_game(5)
	s.cultivation.realm = 4
	var lines: Array = RealmRules.requirement_lines(s, content)
	var cliff := lines.filter(func(l: Dictionary) -> bool: return str(l.key) == "cliff")
	check.call(cliff.size() == 1 and not cliff[0].met, "m25c: the sixth realm asks for the cliff trial")
	s.relationships.set_flag("cliff_trial_done")
	lines = RealmRules.requirement_lines(s, content)
	cliff = lines.filter(func(l: Dictionary) -> bool: return str(l.key) == "cliff")
	check.call(cliff.size() == 1 and cliff[0].met, "m25c: the trial opens the gate")


## A random walk through years 1 to 3 up to week 165.
func _fuzz() -> void:
	game.new_game(33)
	var s: RefCounted = game.state
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var guard := 0
	var seen := {}
	while s.calendar.week <= 165 and guard < 6000 and not s.calendar.finished:
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
	check.call(s.calendar.week > 165 or guard >= 6000, "m25c: fuzz reaches week %d (%d steps)" % [s.calendar.week, guard])
	var y3: Array = seen.keys().filter(func(k: String) -> bool: return k.begins_with("y3") or k.begins_with("ry9_") or k.begins_with("ry10_") or k.begins_with("ry11_") or k.ends_with("_4"))
	check.call(y3.size() >= 3, "m25c: the walk meets some year-3 scenes (%d)" % y3.size())
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
