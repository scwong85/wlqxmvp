extends Node
## Holds the run in progress and talks to SaveService. Screens use this, never the files directly.

const GameState = preload("res://scripts/domain/game_state.gd")

var state: RefCounted = null


func ensure_state() -> RefCounted:
	if state == null:
		state = GameState.new_game()
	return state


func new_game() -> void:
	state = GameState.new_game()


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
