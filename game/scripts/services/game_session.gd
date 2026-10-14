extends Node
## Holds the run in progress and talks to SaveService. Screens use this, never the files directly.

const GameState = preload("res://scripts/domain/game_state.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")

var state: RefCounted = null


func ensure_state() -> RefCounted:
	if state == null:
		state = GameState.new_game()
	return state


func new_game(seed_value: int = -1) -> void:
	state = GameState.new_game(seed_value)


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
		print("LOAD ok slot=%s day=%d slot_no=%d" % [r.slot, state.calendar.day, state.calendar.slot])
	else:
		print("LOAD failed ", r.error_key)
	return r


## Runs an activity for the current run and autosaves once if time advanced.
## Returns the rules result, plus "saved" (bool) when it succeeded.
func perform_activity(activity_id: String) -> Dictionary:
	var def: Dictionary = Content.activity(activity_id)
	if def.is_empty():
		return {"ok": false, "reasons": ["activity.blocked.unknown"]}
	var r: Dictionary = ActivityRules.perform(ensure_state(), def, Content)
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
