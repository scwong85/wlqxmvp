extends RefCounted
## M22d tests: the marsh, the ambush, the Elder Mo fork (three outcomes) and a year-1 random-walk fuzz over 60 weeks.

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
	_fork()
	_fuzz()
	content.free()


func _data() -> void:
	check.call(["ms_flats", "ms_reeds", "ms_temple"].all(func(id: String) -> bool: return content.area(id).region == "marsh"), "m22d: three marsh areas")
	var s: RefCounted = GameState.new_game(3)
	s.calendar.week = 48
	check.call(WorldRules.area_status(s, content, "ms_flats").state == "locked", "m22d: the marsh is locked without the rumor lead")
	s.world.add_lead("marsh_open")
	check.call(WorldRules.area_status(s, content, "ms_flats").state == "open" and WorldRules.area_status(s, content, "ms_temple").state == "locked", "m22d: the flats open and the temple waits for the ferryman")
	s.world.add_lead("temple_path")
	check.call(WorldRules.area_status(s, content, "ms_temple").state == "open", "m22d: the temple opens with the path lead")
	check.call(content.scenario("q4_ambush").enemies.size() == 5, "m22d: the ambush has five enemies")


func _chain() -> void:
	game.new_game(73)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	s.world.add_lead("linjiang_token")
	s.calendar.week = 47
	check.call(_play("lj_docks", "") == "q4_marsh_rumor" and s.world.has_lead("marsh_open"), "m22d: the rumor opens the marsh")
	_jump("q4_ferryman")
	check.call(_play("ms_flats", "water") == "q4_ferryman" and s.world.has_lead("temple_path"), "m22d: the ferryman shows the way")
	_jump("q4_reeds")
	check.call(_play("ms_reeds", "wind") == "q4_reeds" and s.relationships.has_flag("reeds_wind"), "m22d: the reed maze plays")
	s.calendar.week = 53
	check.call(_play("valley_village", "shen") == "q4_solstice", "m22d: the Solstice feast plays")
	_jump("q4_temple")
	check.call(_play("ms_temple", "") == "q4_temple" and s.world.has_lead("vault_gate"), "m22d: the temple reacts to the tally")
	_jump("q4_ambush")
	check.call(_play("ms_flats", "fight") == "q4_ambush" and s.relationships.has_flag("ambush_won"), "m22d: the ambush is fought and won")
	game.battle = null


func _fork_case(flags: Array, expect: String) -> void:
	game.new_game(74)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	for f in flags:
		s.relationships.set_flag(str(f))
	s.calendar.week = 59
	var ev := _play("valley_village", "")
	check.call(ev == "q4_elder_fork" and s.relationships.has_flag(expect) and s.relationships.has_flag("fork_done"), "m22d: fork %s -> %s (got '%s')" % [str(flags), expect, ev])


func _fork() -> void:
	_fork_case(["ambush_won", "villager_saved"], "valley_kept")
	_fork_case(["ambush_won"], "elder_retired")
	_fork_case(["ambush_lost", "villager_saved"], "elder_fallen")
	game.battle = null


## A random walk through year 1: every step picks a random open area or an activity; the run must never hang, error or dead-end.
func _fuzz() -> void:
	for seed in [11, 12]:
		game.new_game(seed)
		var s: RefCounted = game.state
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var guard := 0
		var events_seen := {}
		while s.calendar.week <= 60 and guard < 1500 and not s.calendar.finished:
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
				events_seen[ev] = true
		check.call(s.calendar.week > 60 or guard >= 1500, "m22d: fuzz seed %d walks to week %d without error (%d steps)" % [seed, s.calendar.week, guard])
		check.call(events_seen.size() >= 8, "m22d: fuzz seed %d saw %d different events" % [seed, events_seen.size()])
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
