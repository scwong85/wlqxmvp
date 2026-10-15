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
const BattleResult = preload("res://scripts/domain/combat/battle_result.gd")

var state: RefCounted = null
## The battle on screen (not saved: a battle interrupted by closing the game restarts from its trigger).
var battle: RefCounted = null
var battle_ctx: Dictionary = {}   # {scenario, from: "exploration"|"practice", battle_id}
## Tests set this to play battle animations with no waiting.
var battle_instant: bool = false


func ensure_state() -> RefCounted:
	if state == null:
		state = GameState.new_game()
		RelationshipRules.refresh(state, Content)
	return state


func new_game(seed_value: int = -1) -> void:
	state = GameState.new_game(seed_value)
	RelationshipRules.refresh(state, Content)


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
		print("LOAD ok slot=%s day=%d slot_no=%d" % [r.slot, state.calendar.day, state.calendar.slot])
	else:
		print("LOAD failed ", r.error_key)
	return r


## Runs an activity for the current run and autosaves once if time advanced.
## Returns the rules result, plus "saved" (bool) when it succeeded.
func perform_activity(activity_id: String, option_id: String = "") -> Dictionary:
	var def: Dictionary = Content.activity(activity_id)
	if def.is_empty():
		return {"ok": false, "reasons": ["activity.blocked.unknown"]}
	var r: Dictionary = ActivityRules.perform(ensure_state(), def, Content, option_id)
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
	var active := PartySystem.active(st)
	if active != "":
		party.append(active)
	var seed_value: int = ("%d|%s|%d|%d" % [st.run_seed, str(sc.id), st.calendar.day, st.calendar.slot]).hash()
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
	var res: Dictionary = BattleResult.apply(st, sc, outcome, battle.items, Content)
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
	if has_saved_battle() and resume_battle():
		return "battle"
	if DialogueSystem.is_open(st):
		if not Content.dialogue(str(st.story.dialogue.id)).is_empty():
			return "dialogue"
		st.story.dialogue = {}
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
	if st.calendar.finished and pending_events().is_empty() and start_dialogue("crisis_final"):
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
