extends Node
## Holds the run in progress and talks to SaveService. Screens use this, never the files directly.

const GameState = preload("res://scripts/domain/game_state.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")
const ExplorationSystem = preload("res://scripts/domain/exploration_system.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")

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
	battle_ctx = {"scenario": str(sc.id), "from": from, "battle_id": id}
	return battle != null


## The battle ended and the player pressed Continue: medicine used is spent for real, the trigger is cleared.
func finish_battle() -> String:
	var st := ensure_state()
	if battle != null:
		var left: int = int(battle.items.get("medicine", 0))
		var have: int = st.resources.get_amount("medicine")
		if left < have:
			st.resources.spend("medicine", have - left)
	var from := str(battle_ctx.get("from", ""))
	st.exploration.pending_battle = ""
	battle = null
	battle_ctx = {}
	if from == "exploration":
		autosave()
	return "exploration" if from == "exploration" and st.exploration.active else "cultivation" if from == "exploration" else "title"
