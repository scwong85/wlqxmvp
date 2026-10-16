extends Node
## Holds the run in progress and talks to SaveService. Screens use this, never the files directly.

const GameState = preload("res://scripts/domain/game_state.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")
const ExplorationSystem = preload("res://scripts/domain/exploration_system.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const EndingRules = preload("res://scripts/domain/ending_rules.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const LookRules = preload("res://scripts/domain/look_rules.gd")
const RealmRules = preload("res://scripts/domain/realm_rules.gd")
const SkillTree = preload("res://scripts/domain/skill_tree.gd")
const ManualRules = preload("res://scripts/domain/manual_rules.gd")
const EquipmentRules = preload("res://scripts/domain/equipment_rules.gd")
const DayRules = preload("res://scripts/domain/day_rules.gd")
const BattleResult = preload("res://scripts/domain/combat/battle_result.gd")

var state: RefCounted = null
## The battle on screen (not saved: a battle interrupted by closing the game restarts from its trigger).
var battle: RefCounted = null
var battle_ctx: Dictionary = {}   # {scenario, from: "exploration"|"practice", battle_id}
## Tests set this to play battle animations with no waiting.
var battle_instant: bool = false
## A minigame about to start: {activity, option}. A finished activity result waiting to be shown on the training screen.
var pending_play: Dictionary = {}
var pending_result: Dictionary = {}


## Story-board and clip animations (settings option; tests turn them off through battle_instant).
## A URL query parameter (web builds only, used by the browser test): returns "" when absent.
func web_param(name: String) -> String:
	if not OS.has_feature("web"):
		return ""
	var v: Variant = JavaScriptBridge.eval("(new URLSearchParams(window.location.search)).get('%s') || ''" % name)
	return str(v) if v != null else ""


func animations_enabled() -> bool:
	if battle_instant or web_param("noanim") == "1":
		return false
	return bool(Saves.load_settings().get("animations", true))


func minigames_enabled() -> bool:
	if battle_instant or web_param("noanim") == "1":
		return false
	return bool(Saves.load_settings().get("minigames", true))


## Tries the next realm breakthrough. Autosaves on success.
func attempt_breakthrough() -> Dictionary:
	var r: Dictionary = RealmRules.break_through(ensure_state(), Content)
	if r.ok:
		RelationshipRules.refresh(state, Content)
		r["saved"] = autosave().ok
	return r


## Arts and gear (M20b). Each autosaves when it changes the game.
func learn_node(id: String) -> Dictionary:
	var r: Dictionary = SkillTree.learn(ensure_state(), id, Content)
	if r.ok:
		r["saved"] = autosave().ok
	return r


func study_manual(id: String) -> Dictionary:
	var r: Dictionary = ManualRules.study(ensure_state(), id, Content)
	if r.ok:
		r["saved"] = autosave().ok
	return r


func forge_piece(id: String) -> Dictionary:
	var r: Dictionary = EquipmentRules.forge(ensure_state(), id, Content)
	if r.ok:
		r["saved"] = autosave().ok
	return r


func equip_piece(slot: String, id: String) -> bool:
	var ok := EquipmentRules.equip(ensure_state(), slot, id, Content)
	if ok:
		autosave()
	return ok


func hero_name() -> String:
	var st := ensure_state()
	return st.player.hero_name if st.player.hero_name != "" else Loc.t("hero.default_name")


## Sets the player's name and look (hero creation) and refreshes the {hero} text variable.
func set_hero(raw_name: String, look: Dictionary) -> void:
	var st := ensure_state()
	st.player.hero_name = LookRules.clean_name(raw_name)
	st.player.look = LookRules.sanitize(look)
	sync_text_globals()


func sync_text_globals() -> void:
	Loc.globals["hero"] = hero_name()


func ensure_state() -> RefCounted:
	if state == null:
		state = GameState.new_game()
		RelationshipRules.refresh(state, Content)
		sync_text_globals()
	return state


func new_game(seed_value: int = -1) -> void:
	state = GameState.new_game(seed_value)
	RelationshipRules.refresh(state, Content)
	sync_text_globals()


func save_manual() -> Dictionary:
	var r: Dictionary = Saves.write_slot(Saves.MANUAL, ensure_state(), Loc.locale)
	print("SAVE manual ok=%s" % r.ok)
	return r


func autosave() -> Dictionary:
	var r: Dictionary = Saves.write_slot(Saves.AUTO, ensure_state(), Loc.locale)
	print("SAVE auto ok=%s" % r.ok)
	return r


## Loads the newest save. Returns {ok} or {ok:false, error_key}; state is replaced only on success.
func load_latest() -> Dictionary:
	var r: Dictionary = Saves.load_latest()
	if r.ok:
		state = r.state
		RelationshipRules.refresh(state, Content)
		sync_text_globals()
		print("LOAD ok slot=%s week=%d slot_no=%d" % [r.slot, state.calendar.week, state.calendar.slot])
	else:
		print("LOAD failed ", r.error_key)
	return r


## Runs an activity for the current run and autosaves once if time advanced.
## Returns the rules result, plus "saved" (bool) when it succeeded.
func perform_activity(activity_id: String, option_id: String = "", play: Dictionary = {}) -> Dictionary:
	var def: Dictionary = Content.activity(activity_id)
	if def.is_empty():
		return {"ok": false, "reasons": ["activity.blocked.unknown"]}
	var r: Dictionary = ActivityRules.perform(ensure_state(), def, Content, option_id, play)
	if r.ok and r.time.autosave_due:
		r["saved"] = autosave().ok
	return r


## Story hooks that are due and not yet acknowledged.
func pending_events() -> Array:
	return EventRules.pending(ensure_state(), Content)


func acknowledge_event(hook_id: String) -> void:
	if EventRules.mark_fired(ensure_state(), hook_id):
		autosave()


## Chooses the cultivation path once. Returns false if one is already chosen or the id is unknown.
func choose_path(path_id: String) -> bool:
	var st := ensure_state()
	if st.player.path_id != "" or Content.path(path_id).is_empty():
		return false
	st.player.path_id = path_id
	autosave()
	return true


## Companion actions. Each autosaves when it changes something.
func recruit_companion(npc_id: String) -> Dictionary:
	var r: Dictionary = RelationshipRules.recruit(ensure_state(), npc_id, Content)
	if r.ok:
		autosave()
	return r


func decline_companion(npc_id: String) -> void:
	RelationshipRules.decline(ensure_state(), npc_id)
	autosave()


func set_active_companion(npc_id: String) -> bool:
	var ok := PartySystem.set_active(ensure_state(), npc_id)
	if ok:
		autosave()
	return ok


func leave_party(npc_id: String) -> bool:
	var ok := PartySystem.leave(ensure_state(), npc_id)
	if ok:
		autosave()
	return ok


func dismiss_companion(npc_id: String) -> bool:
	var ok := PartySystem.dismiss(ensure_state(), npc_id)
	if ok:
		autosave()
	return ok


## Exploration. Every node change autosaves, so a reload resumes on the same node.
func start_exploration(route_id: String) -> Dictionary:
	var route: Dictionary = Content.route(route_id)
	if route.is_empty():
		return {"ok": false, "reasons": [{"key": "explore.blocked.inactive", "params": {}}]}
	var r: Dictionary = ExplorationSystem.start(ensure_state(), route, Content)
	if r.ok:
		autosave()
	return r


func current_route() -> Dictionary:
	return Content.route(ensure_state().exploration.route)


func explore_choose(choice_id: String) -> Dictionary:
	var r: Dictionary = ExplorationSystem.choose(ensure_state(), current_route(), choice_id, Content)
	if r.ok:
		autosave()
	return r


## The invitation prompt for the current node was shown and answered.
func clear_pending_recruit() -> void:
	ensure_state().exploration.pending_recruit = ""


## Starts a battle for a story trigger (battle id) or a practice scenario. Returns false if there is no such scenario.
func start_battle(id: String, from: String) -> bool:
	var st := ensure_state()
	var sc: Dictionary = Content.scenario_for_battle(id)
	if sc.is_empty():
		return false
	var party: Array = []
	party.append_array(PartySystem.party(st))
	var seed_value: int = ("%d|%s|%d|%d" % [st.run_seed, str(sc.id), st.calendar.week, st.calendar.slot]).hash()
	battle = BattleSetup.build(Content, str(sc.id), seed_value, st, party)
	battle_ctx = {"scenario": str(sc.id), "from": from, "battle_id": id, "applied": false}
	if battle != null and (from == "exploration" or from == "story"):
		save_battle_progress()
	return battle != null


## Story battles are saved after every action so closing the game never loses or re-rolls a fight.
func save_battle_progress() -> void:
	if battle == null or not ["exploration", "story"].has(str(battle_ctx.get("from", ""))) or battle.outcome != "":
		return
	var snap: Dictionary = battle.to_dict()
	snap["ctx"] = battle_ctx.duplicate()
	ensure_state().battle = snap
	autosave()


func has_saved_battle() -> bool:
	return battle == null and not ensure_state().battle.is_empty()


## Restores a battle saved by save_battle_progress. False (and the snapshot is dropped) if it cannot be rebuilt.
func resume_battle() -> bool:
	var st := ensure_state()
	var snap: Dictionary = st.battle
	var b: RefCounted = BattleSetup.rebuild(Content, snap)
	if b == null:
		st.battle = {}
		return false
	battle = b
	battle_ctx = (snap.get("ctx", {}) as Dictionary).duplicate()
	battle_ctx["applied"] = false
	return true


## Settles the finished (or abandoned) battle once: rewards/penalties, flags, medicine, trigger and snapshot cleared.
## Returns {deltas, flags}. Practice battles change nothing except medicine used.
func apply_battle_result() -> Dictionary:
	var st := ensure_state()
	if battle == null or bool(battle_ctx.get("applied", false)):
		return {"deltas": [], "flags": []}
	var from := str(battle_ctx.get("from", ""))
	var sc: Dictionary = Content.scenario(str(battle_ctx.get("scenario", "")))
	var outcome: String = battle.outcome if from != "practice" else ""
	var hero_unit: RefCounted = battle.unit("hero")
	var uses: Dictionary = hero_unit.tech_uses if hero_unit != null else {}
	var res: Dictionary = BattleResult.apply(st, sc, outcome, battle.items, Content, uses)
	battle_ctx["applied"] = true
	st.battle = {}
	if from != "practice":
		if from == "exploration" and battle.outcome != "":
			st.exploration.pending_battle = ""
		autosave()
	return res


## The player pressed Continue: leaves the battle and returns the scene to go to.
func finish_battle() -> String:
	var st := ensure_state()
	apply_battle_result()
	var from := str(battle_ctx.get("from", ""))
	if from == "exploration" and battle != null and battle.outcome == "":
		pass  # abandoned: the trigger stays pending so the fight is offered again
	battle = null
	battle_ctx = {}
	if st.story.ending != "" and from != "practice":
		return "ending"
	if from == "exploration" and st.exploration.active:
		return "exploration"
	return "title" if from == "practice" else "cultivation"


# --- Story: dialogues, endings ------------------------------------------------------------------

## Which story scene (if any) must be shown now: an interrupted battle, an open dialogue, the ending, a queued
## dialogue, a day-start dialogue, or the final crisis once the week is over. "" means play on as normal.
func next_story_scene() -> String:
	var st := ensure_state()
	WorldRules.sweep_missed(st, Content)
	if has_saved_battle() and resume_battle():
		return "battle"
	if DialogueSystem.is_open(st):
		if not Content.dialogue(str(st.story.dialogue.id)).is_empty():
			return "dialogue"
		st.story.dialogue = {}
	if st.calendar.finished and st.story.ending == "":
		st.story.ending = EndingRules.evaluate(st, Content)  # the three years are over
		autosave()
	if st.story.ending != "":
		return "ending"
	if st.story.pending_dialogue != "":
		var id: String = st.story.pending_dialogue
		st.story.pending_dialogue = ""
		if start_dialogue(id):
			return "dialogue"
	var pending := pending_events()
	if not pending.is_empty() and pending[0].has("dialogue") and start_dialogue(str(pending[0].dialogue), str(pending[0].id)):
		return "dialogue"
	if EventRules.crisis_pending(st) and pending_events().is_empty() and start_dialogue("crisis_final", EventRules.PROLOGUE_CRISIS):
		return "dialogue"
	return ""


func start_dialogue(dialogue_id: String, hook_id: String = "") -> bool:
	var st := ensure_state()
	var r: Dictionary = DialogueSystem.start(st, Content.dialogue(dialogue_id), hook_id, Content)
	if r.ok:
		autosave()
	return r.ok


func current_dialogue() -> Dictionary:
	var st := ensure_state()
	return Content.dialogue(str(st.story.dialogue.get("id", ""))) if DialogueSystem.is_open(st) else {}


func dialogue_choose(choice_id: String) -> Dictionary:
	var r: Dictionary = DialogueSystem.choose(ensure_state(), current_dialogue(), choice_id, Content)
	if r.ok:
		autosave()
	return r


func dialogue_advance() -> Dictionary:
	var r: Dictionary = DialogueSystem.advance(ensure_state(), current_dialogue(), Content)
	if r.ok:
		autosave()
	return r


## The scene ended (result.ended): returns the next scene key. A fight starts right away; a queued dialogue opens.
func after_dialogue(result: Dictionary) -> String:
	if str(result.get("battle", "")) != "":
		if start_battle(str(result.battle), "story"):
			return "battle"
	if str(result.get("queue", "")) != "":
		ensure_state().story.pending_dialogue = str(result.queue)
	var dest := next_story_scene()
	return dest if dest != "" else "cultivation"


## Starts over: a fresh run replaces the finished one.
func restart_run() -> void:
	new_game()


# --- The world: areas and events (M16) ----------------------------------------------------------

## Goes to an area: spends its travel cost in slots, then plays a due fixed event, a random one, or a short wander.
## Returns {ok, reasons, event_id, wander, deltas, time, scene} where scene is "dialogue" when an event scene opened.
func visit_area(area_id: String) -> Dictionary:
	var st := ensure_state()
	var p: Dictionary = WorldRules.pick(st, Content, area_id)
	if not p.ok:
		return {"ok": false, "reasons": p.reasons, "event_id": "", "wander": {}, "deltas": [], "time": {}, "scene": ""}
	var time: Dictionary = {}
	for i in int(p.cost):
		if st.calendar.finished:
			break
		var t: Dictionary = DayRules.end_slot(st)
		if time.is_empty():
			time = t
		else:
			time["finished"] = t.finished
			time["new_week"] = bool(time.get("new_week", false)) or bool(t.new_week)
			time["recovered"] = int(time.get("recovered", 0)) + int(t.recovered)
	st.world.last_area = area_id
	RelationshipRules.refresh(st, Content)
	var result := {"ok": true, "reasons": [], "event_id": "", "wander": p.wander, "deltas": [], "time": time, "scene": ""}
	if not (p.event as Dictionary).is_empty():
		result.event_id = str(p.event.id)
		var r: Dictionary = DialogueSystem.start(st, Content.dialogue(str(p.event.scene.dialogue)), "event:" + result.event_id, Content)
		if r.ok:
			result.scene = "dialogue"
	else:
		WorldRules.note_visit(st, area_id)
		for rw in (p.wander as Dictionary).get("rewards", []):
			result.deltas.append_array(ActivityRules.apply_reward(st, {"type": str(rw.type), "id": str(rw.id)}, int(rw.amount), Content))
	autosave()
	return result
