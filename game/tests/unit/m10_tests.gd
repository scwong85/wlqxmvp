extends RefCounted
## M10 tests: battle text for every log event in both languages, story trigger -> scenario mapping,
## starting and finishing a battle through the Game session (medicine spent, trigger cleared).

const BattleText = preload("res://scenes/battle/battle_text.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var loc: Node
var content: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	_mapping()
	_log_text()
	_session()


func _mapping() -> void:
	check.call(content.scenario_for_battle("bandit_scouts").get("id", "") == "bandit_scouts", "m10: story battle bandit_scouts maps to its scenario")
	check.call(content.scenario_for_battle("training_match").get("id", "") == "training_match", "m10: a scenario id also works as a battle id")
	check.call(content.scenario_for_battle("nope").is_empty(), "m10: unknown battle id has no scenario")
	# every battle id used by the routes has a scenario
	var ids: Array = []
	for r in content.routes:
		_collect_battles(r, ids)
	var ok := not ids.is_empty()
	for bid in ids:
		ok = ok and not content.scenario_for_battle(str(bid)).is_empty()
	check.call(ok, "m10: every battle triggered by a route has a scenario")


func _collect_battles(node: Variant, out: Array) -> void:
	if node is Dictionary:
		if node.get("type", "") == "battle":
			out.append(node.get("id", ""))
		for k in node:
			_collect_battles(node[k], out)
	elif node is Array:
		for x in node:
			_collect_battles(x, out)


func _log_text() -> void:
	var saved: String = loc.locale
	var silent := ["turn_start", "turn_end", "follow_up_offer"]
	for code in ["zh_CN", "en"]:
		loc.set_locale(code)
		var bad := 0
		var shown := 0
		var types := {}
		for sid in ["rescue_battle", "final_crisis", "bandit_scouts"]:
			var b: RefCounted = BattleSetup.build(content, sid, 5, null, ["shen_qinghe", "lu_chenzhou"])
			var g := 0
			while b.outcome == "" and g < 300:
				g += 1
				BattleAI.take_turn(b)
			for e in b.log:
				types[e.type] = true
				var line := BattleText.log_line(b, e)
				if silent.has(e.type):
					continue
				shown += 1
				if line == "" or line.contains("["):
					bad += 1
					print("    bad log line (%s): '%s'" % [e.type, line])
		check.call(bad == 0 and shown > 50, "m10: every shown log event has real text in %s (%d lines, %d types)" % [code, shown, types.size()])
	loc.set_locale(saved)
	# duplicate enemy names are numbered, single ones are not
	var b2: RefCounted = BattleSetup.build(content, "training_match", 1, null, [])
	check.call(BattleText.unit_name(b2, b2.unit("training_fighter_1")) != BattleText.unit_name(b2, b2.unit("training_fighter_2")), "m10: two units of one kind get different names")
	check.call(BattleText.unit_name(b2, b2.unit("hero")) == loc.t("combat.hero"), "m10: a single unit keeps its plain name")


func _session() -> void:
	var game: Node = Engine.get_main_loop().root.get_node("Game")
	var saves: Node = Engine.get_main_loop().root.get_node("Saves")
	var old_dir: String = saves.dir
	saves.dir = "user://m10_saves/"
	DirAccess.make_dir_recursive_absolute(saves.dir)
	game.new_game(7)
	var st: RefCounted = game.state
	st.resources.add("medicine", 3)
	st.exploration.pending_battle = "bandit_scouts"
	check.call(game.start_battle("bandit_scouts", "exploration"), "m10: a story trigger starts a battle")
	check.call(game.battle != null and game.battle.scenario_id == "bandit_scouts" and game.battle.items.get("medicine", 0) == 3, "m10: battle carries the player's medicine")
	var h1: String = game.battle.state_hash()
	game.start_battle("bandit_scouts", "exploration")
	check.call(game.battle.state_hash() == h1, "m10: the same trigger on the same day builds the same battle")
	game.battle.items["medicine"] = 1
	var dest: String = game.finish_battle()
	check.call(st.resources.get_amount("medicine") == 1 and st.exploration.pending_battle == "" and game.battle == null, "m10: finishing spends used medicine and clears the trigger")
	check.call(dest == "cultivation", "m10: with no route running the player returns to training")
	st.exploration.active = true
	game.start_battle("bandit_scouts", "exploration")
	check.call(game.finish_battle() == "exploration", "m10: with a route running the player returns to it")
	game.start_battle("training_match", "practice")
	check.call(game.finish_battle() == "title", "m10: practice returns to the title")
	check.call(not game.start_battle("nope", "practice"), "m10: unknown battle is refused")
	for f in DirAccess.get_files_at(saves.dir):
		DirAccess.remove_absolute(saves.dir.path_join(f))
	saves.dir = old_dir
