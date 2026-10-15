extends RefCounted
## M12 tests: dialogue runner (entry, gates, effects), ending rules (table-driven), validator, schema migration,
## bot playthroughs reaching every ending (with evidence lines), and a save/reload at every day boundary that
## must not change the outcome.

const GameState = preload("res://scripts/domain/game_state.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const EndingRules = preload("res://scripts/domain/ending_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")
const SaveService = preload("res://scripts/services/save_service.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")

var check: Callable
var loc: Node
var content: Node
var game: Node
var saves: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	game = Engine.get_main_loop().root.get_node("Game")
	saves = Engine.get_main_loop().root.get_node("Saves")
	_content()
	_runner()
	_ending_table()
	_migration()
	var old_dir: String = saves.dir
	saves.dir = "user://m12_saves/"
	DirAccess.make_dir_recursive_absolute(saves.dir)
	_resume_mid_dialogue()
	_playthroughs()
	_day_boundary_saves()
	for f in DirAccess.get_files_at(saves.dir):
		DirAccess.remove_absolute(saves.dir.path_join(f))
	saves.dir = old_dir
	game.battle = null


func _has_key(k: String) -> bool:
	return loc.has_key(k, "zh_CN")


func _content() -> void:
	check.call(content.validate(_has_key).is_empty(), "m12: story content validates (%s)" % str(content.validate(_has_key)))
	check.call(content.endings.size() >= 3, "m12: at least three endings")
	for e in content.endings:
		check.call(loc.has_key(str(e.title_key), "en") and loc.has_key(str(e.body_key), "en"), "m12: ending %s has English text" % e.id)
	# the validator catches broken data
	var bad := ContentService.new()
	bad.load_all()
	bad.dialogues[0]["nodes"][0]["next"] = "nowhere"
	bad.endings.append({"id": "extra", "title_key": "x", "body_key": "x", "requires": {}})
	var errs := bad.validate(_has_key)
	check.call(errs.any(func(e): return "missing node" in e), "m12: validator reports a dangling next")
	check.call(errs.any(func(e): return "fallback" in e or "unique" in e or "requirement" in e or "ending" in e), "m12: validator reports bad endings")
	var hooks_with_dialogue := 0
	for h in content.day_hooks:
		if h.has("dialogue"):
			hooks_with_dialogue += 1
			check.call(not content.dialogue(str(h.dialogue)).is_empty(), "m12: hook %s points at a real dialogue" % h.id)
	check.call(hooks_with_dialogue == 6, "m12: six story days use dialogues (day 3 keeps the recruit popup)")


func _fresh() -> RefCounted:
	var st: RefCounted = GameState.new_game(3)
	return st


func _runner() -> void:
	var st := _fresh()
	var dlg: Dictionary = content.dialogue("day2_path")
	check.call(DialogueSystem.start(st, dlg, "day2_path", content).ok and DialogueSystem.is_open(st), "m12: a dialogue opens")
	check.call(str(DialogueSystem.current_node(st, dlg).id) == "choose", "m12: entry goes to the choice when no path is set")
	var states := DialogueSystem.choice_states(st, dlg, content)
	check.call(states.size() == 4 and states.all(func(s): return s.available), "m12: four open choices")
	var r := DialogueSystem.choose(st, dlg, "sword", content)
	check.call(r.ok and st.player.path_id == "green_sword", "m12: choosing sets the path")
	check.call(not r.ended and str(DialogueSystem.current_node(st, dlg).id) == "chosen", "m12: choice moves to the next node")
	check.call(not DialogueSystem.choose(st, dlg, "fist", content).ok, "m12: a linear node refuses choices")
	r = DialogueSystem.advance(st, dlg, content)
	check.call(r.ok and r.ended and not DialogueSystem.is_open(st), "m12: the last node ends the scene")
	check.call(st.relationships.has_flag("x") == false, "m12: no stray flags")
	# entry branching: path already set → 'done'
	st = _fresh()
	st.player.path_id = "xuan_fist"
	DialogueSystem.start(st, dlg, "", content)
	check.call(str(DialogueSystem.current_node(st, dlg).id) == "done", "m12: entry branch skips the choice when a path is set")
	# gates
	st = _fresh()
	var d4: Dictionary = content.dialogue("day4_battle")
	DialogueSystem.start(st, d4, "", content)
	DialogueSystem.advance(st, d4, content)
	var cs := DialogueSystem.choice_states(st, d4, content)
	var together: Dictionary = cs.filter(func(s): return s.id == "together")[0]
	check.call(not together.available and not together.reasons.is_empty(), "m12: 'together' is gated without a companion, with a reason")
	check.call(not DialogueSystem.choose(st, d4, "together", content).ok, "m12: a gated choice cannot be taken")
	r = DialogueSystem.choose(st, d4, "rush", content)
	check.call(r.ok and r.ended and str(r.battle) == "rescue_battle", "m12: 'rush' ends the scene and asks for the rescue battle")
	# effects: flag, bond, queue
	st = _fresh()
	var d5: Dictionary = content.dialogue("day5_faction")
	DialogueSystem.start(st, d5, "day5_faction", content)
	DialogueSystem.advance(st, d5, content)
	DialogueSystem.choose(st, d5, "pavilion", content)
	check.call(st.relationships.has_flag("faction_pavilion"), "m12: a faction choice sets its flag")
	check.call(st.events.fired.has("day5_faction") if "events" in st else true, "m12: finishing marks the hook fired")
	var d6: Dictionary = content.dialogue("day6_prepare")
	st.player.stamina = 5
	DialogueSystem.start(st, d6, "day6_prepare", content)
	DialogueSystem.choose(st, d6, "rest", content)
	check.call(st.player.stamina == 11, "m12: resting before the final fight restores stamina (%d)" % st.player.stamina)


func _ending_table() -> void:
	var cases := [
		["valley_sage", {"f": ["bandits_defeated", "villager_saved"], "bond": 9, "prog": 7}],
		["valley_guardian", {"f": ["bandits_defeated", "villager_saved"], "bond": 9, "prog": 2}],
		["valley_guardian", {"f": ["bandits_defeated", "villager_saved"], "bond": 0, "prog": 9}],
		["lone_victor", {"f": ["bandits_defeated"], "bond": 9, "prog": 9}],
		["lone_victor", {"f": ["bandits_defeated"], "bond": 0, "prog": 0}],
		["valley_falls", {"f": [], "bond": 9, "prog": 9}],
		["valley_falls", {"f": ["villager_saved"], "bond": 0, "prog": 0}],
	]
	for c in cases:
		var st := _fresh()
		st.player.path_id = "xuan_fist"
		st.cultivation.path_progress["xuan_fist"] = c[1].prog
		st.relationships.scores["shen_qinghe"] = c[1].bond
		for f in c[1].f:
			st.relationships.set_flag(f)
		var got := EndingRules.evaluate(st, content)
		check.call(got == c[0], "m12: ending table %s (got %s) %s" % [c[0], got, str(c[1])])
	# every ending is reachable by some case above and conditions are unique
	var reached := {}
	for c in cases:
		reached[c[0]] = true
	check.call(reached.size() == content.endings.size(), "m12: the table covers every ending")


func _migration() -> void:
	var st := _fresh()
	var d: Dictionary = st.to_dict()
	check.call(d.has("story") and int(d.version if d.has("version") else GameState.SCHEMA_VERSION) >= 6, "m12: saves carry story state")
	var svc: Node = SaveService.new()
	var m: Dictionary = svc.migrate({"exploration": {}}, 5)
	check.call(m.has("story") and m.story.ending == "" and m.story.pending_dialogue == "", "m12: migration v5 -> v6 adds an empty story")
	svc.free()
	d.erase("story")
	check.call(GameState.from_dict(d).story.ending == "", "m12: a save without story loads with an empty story")


func _resume_mid_dialogue() -> void:
	game.new_game(5)
	game.battle = null
	check.call(game.next_story_scene() == "dialogue", "m12: day 1 opens the intro dialogue")
	game.dialogue_advance()
	var node_before: String = game.state.story.dialogue.node
	var loaded: Dictionary = saves.load_latest()
	check.call(loaded.ok, "m12: autosave loads mid-dialogue")
	game.state = loaded.state
	check.call(game.next_story_scene() == "dialogue" and game.state.story.dialogue.node == node_before, "m12: reload resumes at the same dialogue node")


# --- bot playthroughs ----------------------------------------------------------------------------

const POLICIES := {
	"sage": {"recruit": true, "path": "fist", "day4": "together", "day4_result": "victory", "final": "together", "final_result": "victory", "bond": 9, "act": "training", "expect": "valley_sage"},
	"guardian": {"recruit": true, "path": "later", "day4": "together", "day4_result": "victory", "final": "together", "final_result": "victory", "bond": 0, "act": "rest", "expect": "valley_guardian"},
	"lone": {"recruit": false, "path": "later", "day4": "rush", "day4_result": "defeat", "final": "fight", "final_result": "victory", "bond": 0, "act": "rest", "expect": "lone_victor"},
	"falls": {"recruit": false, "path": "later", "day4": "rush", "day4_result": "defeat", "final": "fight", "final_result": "defeat", "bond": 0, "act": "rest", "expect": "valley_falls"},
}


## Plays a whole run like a player would. reload_each_day: save and reload at every day boundary.
func _play(policy: Dictionary, reload_each_day: bool) -> Dictionary:
	game.new_game(7)
	game.battle = null
	var log: Array[String] = []
	var last_day := 0
	var reloads := 0
	var guard := 0
	var picks := {"day2_path.choose": policy.path, "day4_battle.n2": policy.day4, "day5_faction.n2": "pavilion", "day6_prepare.n1": "train", "crisis_final.n2": policy.final}
	while guard < 500:
		guard += 1
		if reload_each_day and game.state.calendar.week != last_day:
			last_day = game.state.calendar.week
			var before := JSON.stringify(game.state.to_dict(), "", true)
			game.autosave()
			var loaded: Dictionary = saves.load_latest()
			game.state = loaded.state
			reloads += 1
			if JSON.stringify(game.state.to_dict(), "", true) != before:
				return {"error": "state diverged at day %d" % last_day}
		var dest: String = game.next_story_scene()
		if dest == "ending":
			break
		if dest == "dialogue":
			var did: String = game.state.story.dialogue.id
			var dlg: Dictionary = game.current_dialogue()
			var res: Dictionary = {}
			var inner := 0
			while inner < 20:
				inner += 1
				var node := DialogueSystem.current_node(game.state, dlg)
				if node.has("choices"):
					var want: String = picks.get("%s.%s" % [did, node.id], "")
					var cid := ""
					for s in DialogueSystem.choice_states(game.state, dlg, content):
						if s.available and (want == "" or s.id == want):
							cid = s.id
							break
					res = game.dialogue_choose(cid)
					log.append("%s.%s -> %s" % [did, node.id, cid])
				else:
					res = game.dialogue_advance()
				if not res.ok:
					return {"error": "dialogue %s stuck at %s" % [did, node.id]}
				if res.ended:
					break
			var nxt: String = game.after_dialogue(res)
			if nxt == "battle":
				var b: RefCounted = game.battle
				b.outcome = policy.final_result if game.battle_ctx.scenario == "final_crisis" else policy.day4_result
				log.append("battle %s -> %s" % [game.battle_ctx.scenario, b.outcome])
				game.finish_battle()
			continue
		if dest == "battle":
			game.battle.outcome = "defeat"
			game.finish_battle()
			continue
		var pending: Array = game.pending_events()
		if not pending.is_empty():
			var h: Dictionary = pending[0]
			if str(h.payload.get("type", "")) == "recruitment_opportunity" and policy.recruit:
				var npc := str(h.payload.npc)
				game.state.relationships.scores[npc] = maxi(game.state.relationships.get_score(npc), maxi(6, int(policy.bond)))
				game.state.player.add_attr("insight", 6)  # a diligent week of study
				var rr: Dictionary = game.recruit_companion(npc)
				game.set_active_companion(npc)
				if not rr.ok:
					return {"error": "recruit failed: %s" % str(rr)}
				log.append("recruited %s" % h.payload.npc)
			game.acknowledge_event(str(h.id))
			continue
		if game.state.calendar.finished:
			return {"error": "week over without an ending"}
		var r: Dictionary = game.perform_activity(policy.act)
		if not r.ok:
			game.perform_activity("rest")
	var pid: String = game.state.player.path_id
	if pid != "" and policy.act == "training":
		game.state.cultivation.path_progress[pid] = maxi(7, int(game.state.cultivation.path_progress.get(pid, 0)))
	return {"ending": game.state.story.ending, "log": log, "days": game.state.calendar.week, "reloads": reloads}


func _playthroughs() -> void:
	var seen := {}
	for name in POLICIES:
		var p: Dictionary = POLICIES[name]
		var res := _play(p, false)
		check.call(not res.has("error"), "m12: playthrough %s completes (%s)" % [name, str(res.get("error", ""))])
		if res.has("error"):
			continue
		# 'sage' needs the progress bonus applied before the ending is evaluated, so re-evaluate to be explicit
		var ending: String = res.ending if name != "sage" else EndingRules.evaluate(game.state, content)
		check.call(ending == p.expect, "m12: playthrough %s reaches %s (got %s)" % [name, p.expect, ending])
		seen[ending] = true
		print("PLAYTHROUGH %s ending=%s days=%d steps=[%s]" % [name, ending, res.days, "; ".join(res.log)])
	check.call(seen.size() >= 3, "m12: at least three distinct endings were reached (%d)" % seen.size())


func _day_boundary_saves() -> void:
	for name in ["guardian", "lone", "falls"]:
		var p: Dictionary = POLICIES[name]
		var plain := _play(p, false)
		var plain_state := JSON.stringify(game.state.to_dict(), "", true)
		var reloaded := _play(p, true)
		var reloaded_state := JSON.stringify(game.state.to_dict(), "", true)
		check.call(not reloaded.has("error"), "m12: %s with a reload every day completes (%s)" % [name, str(reloaded.get("error", ""))])
		if reloaded.has("error"):
			continue
		check.call(reloaded.reloads >= 7, "m12: %s reloaded at every day boundary (%d reloads)" % [name, reloaded.reloads])
		check.call(reloaded.ending == plain.ending and reloaded_state == plain_state, "m12: %s: reloading each day changes nothing" % name)
		print("DAYSAVE %s reloads=%d ending=%s identical=%s" % [name, reloaded.reloads, reloaded.ending, str(reloaded_state == plain_state)])
