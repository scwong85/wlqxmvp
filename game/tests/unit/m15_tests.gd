extends RefCounted
## M15 tests: the 3-year calendar in the story flow (opening month, its climax, the ending at the end of year 3)
## and migration of seven-day saves.

const GameState = preload("res://scripts/domain/game_state.gd")
const SaveService = preload("res://scripts/services/save_service.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node
var game: Node
var saves: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	game = Engine.get_main_loop().root.get_node("Game")
	saves = Engine.get_main_loop().root.get_node("Saves")
	_migration()
	_hooks()
	_gates()
	var old_dir: String = saves.dir
	saves.dir = "user://m15_saves/"
	DirAccess.make_dir_recursive_absolute(saves.dir)
	_story_flow()
	for f in DirAccess.get_files_at(saves.dir):
		DirAccess.remove_absolute(saves.dir.path_join(f))
	saves.dir = old_dir
	game.battle = null


func _migration() -> void:
	var svc: Node = SaveService.new()
	var expect := [1, 1, 2, 3, 4, 5, 5]
	for d in range(1, 8):
		var m: Dictionary = svc.migrate({"calendar": {"day": d, "slot": 2, "finished": false, "events_fired": ["day1_intro"]}}, 6)
		check.call(m.calendar.week == expect[d - 1] and m.calendar.slot == 2 and not m.calendar.has("day") and m.calendar.events_fired == ["day1_intro"], "m15: a seven-day save on day %d becomes week %d" % [d, expect[d - 1]])
	var fin: Dictionary = svc.migrate({"calendar": {"day": 7, "slot": 2, "finished": true}}, 6)
	check.call(fin.calendar.week == 5 and fin.calendar.slot == 2 and not fin.calendar.finished, "m15: a finished seven-day run returns to the end of the opening month, so its climax still happens")
	var st: RefCounted = GameState.from_dict(svc.migrate({"calendar": {"day": 4, "slot": 1}}, 6))
	check.call(st.calendar.week == 3 and st.calendar.year() == 1 and st.calendar.month() == 1, "m15: a migrated state loads on the new calendar")
	check.call(GameState.SCHEMA_VERSION == 7, "m15: schema version is 7")
	svc.free()


func _hooks() -> void:
	var last := 0
	for h in content.day_hooks:
		check.call(int(h.week) >= 1 and int(h.week) <= 5, "m15: hook %s falls inside the opening month (week %d)" % [h.id, int(h.week)])
		check.call(int(h.week) >= last, "m15: hooks are listed in time order (%s)" % h.id)
		last = int(h.week)


func _gates() -> void:
	var g: RefCounted = GameState.new_game(1)
	var mining: Dictionary = content.activity("mining")
	check.call(not ActivityRules.availability(g, mining).ok, "m15: mining is closed in week 1")
	g.calendar.week = 2
	check.call(ActivityRules.availability(g, mining).reasons.has("activity.blocked.day_gate") == false, "m15: mining's week gate opens in week 2")


## The opening month ends with its climax, the game then goes on, and only the end of year 3 gives an ending.
func _story_flow() -> void:
	game.new_game(11)
	game.battle = null
	var guard := 0
	var seen: Array = []
	while guard < 60 and game.state.calendar.slots_used() < 10:
		guard += 1
		var dest: String = game.next_story_scene()
		if dest == "dialogue":
			var dlg: Dictionary = game.current_dialogue()
			seen.append(str(dlg.id))
			var res: Dictionary = {}
			var inner := 0
			while inner < 20:
				inner += 1
				var node: Dictionary = preload("res://scripts/domain/dialogue_system.gd").current_node(game.state, dlg)
				if node.has("choices"):
					var pick := ""
					for c in preload("res://scripts/domain/dialogue_system.gd").choice_states(game.state, dlg, content):
						if c.available and pick == "":
							pick = c.id
					res = game.dialogue_choose(pick)
				else:
					res = game.dialogue_advance()
				if res.get("ended", false):
					break
			var nxt: String = game.after_dialogue(res)
			if nxt == "battle":
				game.battle.outcome = "victory"
				game.finish_battle()
			continue
		if dest == "battle":
			game.battle.outcome = "defeat"
			game.finish_battle()
			continue
		var pending: Array = game.pending_events()
		if not pending.is_empty():
			game.acknowledge_event(str(pending[0].id))
			continue
		game.perform_activity("rest")
	check.call(game.state.calendar.week == 6 and game.state.calendar.slot == 1, "m15: ten slots fill the opening month (now week 6)")
	var climax: String = game.next_story_scene()
	check.call(climax == "dialogue" and game.state.story.dialogue.id == "crisis_final", "m15: the climax opens as soon as the opening month is over")
	var r: Dictionary = game.dialogue_advance()
	while not r.ended:
		var dlg2: Dictionary = game.current_dialogue()
		var node2: Dictionary = preload("res://scripts/domain/dialogue_system.gd").current_node(game.state, dlg2)
		r = game.dialogue_choose("fight") if node2.has("choices") else game.dialogue_advance()
	check.call(game.after_dialogue(r) == "battle", "m15: the climax leads into the battle")
	game.battle.outcome = "victory"
	var back: String = game.finish_battle()
	check.call(back == "cultivation" and game.state.story.ending == "", "m15: winning the climax does not end the run")
	check.call(game.state.relationships.has_flag("bandits_defeated") and game.next_story_scene() == "", "m15: the result is remembered and month 2 starts quietly")
	check.call(EventRules.crisis_pending(game.state) == false, "m15: the climax cannot repeat")
	# The end of year 3.
	game.state.calendar.week = 180
	game.state.calendar.slot = 2
	game.perform_activity("rest")
	check.call(game.state.calendar.finished, "m15: the last slot finishes the three years")
	check.call(game.next_story_scene() == "ending" and game.state.story.ending != "", "m15: the end of year 3 opens the ending (%s)" % game.state.story.ending)
	check.call(game.state.story.ending == "valley_guardian" or game.state.story.ending == "lone_victor" or game.state.story.ending == "valley_sage" or game.state.story.ending == "valley_falls", "m15: the ending is one of the known endings")
