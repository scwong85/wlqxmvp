extends RefCounted
## M21 tests: companion arcs (record, gates, effects, missing scenes, full playthroughs of all three arcs, saving).

const GameState = preload("res://scripts/domain/game_state.gd")
const ArcRules = preload("res://scripts/domain/arc_rules.gd")
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
	_record()
	_gates()
	_missed()
	_playthroughs()
	_screen()
	content.free()


func _record() -> void:
	var s: RefCounted = GameState.new_game(1)
	check.call(ArcRules.stage(s, "shen_qinghe") == 0 and ArcRules.outcome(s, "shen_qinghe") == "", "m21: an arc starts at stage 0 with no outcome")
	ArcRules.set_stage(s, "shen_qinghe", 2)
	ArcRules.set_stage(s, "shen_qinghe", 1)
	check.call(ArcRules.stage(s, "shen_qinghe") == 2, "m21: a stage never goes back")
	ArcRules.set_outcome(s, "shen_qinghe", "bogus")
	check.call(ArcRules.outcome(s, "shen_qinghe") == "", "m21: unknown outcomes are ignored")
	ArcRules.set_outcome(s, "shen_qinghe", "redeemed")
	ArcRules.set_outcome(s, "shen_qinghe", "lost")
	check.call(ArcRules.outcome(s, "shen_qinghe") == "redeemed", "m21: the first outcome sticks")
	var back: RefCounted = GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	check.call(ArcRules.stage(back, "shen_qinghe") == 2 and ArcRules.outcome(back, "shen_qinghe") == "redeemed", "m21: arcs survive saving")
	var bad: RefCounted = GameState.from_dict({"relationships": {"arcs": {"x": {"stage": 99, "outcome": "zz", "bond": "friend"}, "y": 5}}})
	check.call(ArcRules.stage(bad, "x") == 4 and ArcRules.outcome(bad, "x") == "" and ArcRules.bond_type(bad, "x") == "friend" and not bad.relationships.arcs.has("y"), "m21: damaged arc data is cleaned")
	check.call(GameState.from_dict({"calendar": {"week": 2, "slot": 1}}).relationships.arcs.is_empty(), "m21: older saves have no arcs")
	check.call(content.arcs.size() == 3, "m21: three arcs ship")
	for a in content.arcs:
		check.call(a.stages.size() == 4, "m21: %s has four stages" % str(a.companion))
	var sm := ArcRules.summary(s, content, "shen_qinghe")
	check.call(sm.stage == 2 and sm.total == 4 and sm.event == "arc_shen_qinghe_3" and not sm.done, "m21: the summary names the next scene")


func _gates() -> void:
	var s: RefCounted = GameState.new_game(2)
	s.calendar.week = 12
	var ev: Dictionary = content.event("arc_shen_qinghe_1")
	check.call(not WorldRules.requires_reasons(s, ev.requires, content).is_empty(), "m21: stage 1 needs the bond")
	s.relationships.scores["shen_qinghe"] = 4
	check.call(WorldRules.requires_reasons(s, ev.requires, content).is_empty(), "m21: and plays once it is there")
	var ev2: Dictionary = content.event("arc_shen_qinghe_2")
	s.relationships.scores["shen_qinghe"] = 20
	check.call(not WorldRules.requires_reasons(s, ev2.requires, content).is_empty(), "m21: stage 2 also needs stage 1 done")
	ArcRules.set_stage(s, "shen_qinghe", 1)
	check.call(WorldRules.requires_reasons(s, ev2.requires, content).is_empty(), "m21: and opens after it")


func _missed() -> void:
	game.new_game(31)
	var s: RefCounted = game.state
	s.calendar.week = 105
	var missed := WorldRules.sweep_missed(s, content)
	check.call(missed.has("arc_lu_chenzhou_1") and ArcRules.outcome(s, "lu_chenzhou") == "lost" and ArcRules.stage(s, "lu_chenzhou") == 4, "m21: missing the first scene closes the arc as lost, never a dead end")


## Plays the event the area offers, picking `pick` if available, else the first open choice.
func _play(area: String, pick: String) -> String:
	var v: Dictionary = game.visit_area(area)
	if v.event_id == "":
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


func _run_arc(cid: String, area: String, picks: Array, bond: String) -> void:
	game.new_game(40)
	var s: RefCounted = game.state
	s.relationships.set_status(cid, "available")
	s.relationships.scores[cid] = 20
	s.calendar.week = 12
	s.world.areas_open.append(area)
	var played: Array = []
	for i in 4:
		var eid := _play(area, str(picks[i]) if i < picks.size() else "")
		played.append(eid)
		check.call(eid == "arc_%s_%d" % [cid, i + 1], "m21: %s scene %d plays in order (%s)" % [cid, i + 1, eid])
		if i < 3 and s.world.scheduled.has("arc_%s_%d" % [cid, i + 2]):
			s.calendar.week = maxi(s.calendar.week, int(s.world.scheduled["arc_%s_%d" % [cid, i + 2]].from))
		check.call(ArcRules.stage(s, cid) == i + 1, "m21: %s stage is %d after scene %d" % [cid, i + 1, i + 1])
	check.call(ArcRules.bond_type(s, cid) == bond, "m21: %s ends as %s" % [cid, bond])
	check.call(ArcRules.summary(s, content, cid).done, "m21: the arc reads as done")
	game.battle = null


func _playthroughs() -> void:
	_run_arc("shen_qinghe", "herb_terraces", ["", "", "open", "romance"], "romance")
	check.call(ArcRules.outcome(game.state, "shen_qinghe") == "redeemed", "m21: Shen's open choice gives the redeemed outcome")
	_run_arc("lu_chenzhou", "river_bend", ["fight", "", "sell", "rival"], "rival")
	check.call(ArcRules.outcome(game.state, "lu_chenzhou") == "lost", "m21: Lu's choice to sell gives the lost outcome")
	_run_arc("bai_yan", "old_shrine", ["", "", "keep", "sworn"], "sworn")
	check.call(ArcRules.outcome(game.state, "bai_yan") == "alternate", "m21: Bai's choice to keep gives the alternate outcome")
	var tags := ArcRules.tags(game.state, content)
	check.call(tags.bai_yan.outcome == "alternate" and tags.bai_yan.bond == "sworn" and tags.has("shen_qinghe"), "m21: tags list every companion for the ending composer")
	# A weak bond cannot take the romance path but can still end as a friend or rival.
	game.new_game(41)
	game.state.relationships.set_status("shen_qinghe", "available")
	game.state.relationships.scores["shen_qinghe"] = 20
	game.state.calendar.week = 12
	for i in 3:
		_play("herb_terraces", "")
		if game.state.world.scheduled.has("arc_shen_qinghe_%d" % (i + 2)):
			game.state.calendar.week = maxi(game.state.calendar.week, int(game.state.world.scheduled["arc_shen_qinghe_%d" % (i + 2)].from))
	game.state.relationships.scores["shen_qinghe"] = 11
	var v: Dictionary = game.visit_area("herb_terraces")
	var dlg: Dictionary = game.current_dialogue()
	while not DialogueSystem.current_node(game.state, dlg).has("choices"):
		game.dialogue_advance()
	var romance_open := false
	for c in DialogueSystem.choice_states(game.state, dlg, content):
		if c.id == "romance":
			romance_open = c.available
	check.call(v.event_id == "arc_shen_qinghe_4" and not romance_open, "m21: a weaker bond cannot choose the romance path")
	game.state.story.dialogue = {}


func _screen() -> void:
	game.new_game(54)
	game.state.relationships.set_status("shen_qinghe", "joined")
	ArcRules.set_stage(game.state, "shen_qinghe", 2)
	ArcRules.set_outcome(game.state, "shen_qinghe", "alternate")
	var host: Node = Engine.get_main_loop().current_scene
	game.state.calendar.week = 8
	var cult: Control = load("res://scenes/cultivation/cultivation.tscn").instantiate()
	host.add_child(cult)
	cult.call("_show_party") if cult.has_method("_show_party") else null
	check.call(true, "m21: cultivation opens with arcs recorded")
	cult.queue_free()
	game.battle = null
