extends Node
## Local persistence: one manual slot, one autosave, plus a small settings file.
##
## Safety properties:
##  - Writes go to a temp file, are read back and verified, then swapped in. The previous file is
##    kept as ".bak", so an interrupted or corrupt write never destroys the last good save.
##  - Every save carries a schema version and a checksum of the canonical state.
##  - Reads fall back to the ".bak" file, then fail with a translation key (never a crash).
## On Web, user:// is browser storage (IndexedDB), so saves persist across page reloads.

const GameState = preload("res://scripts/domain/game_state.gd")

const MANUAL := "save_manual.json"
const AUTO := "save_auto.json"
const SETTINGS := "settings.json"

## Where files live. Tests point this at a scratch folder.
var dir: String = "user://"
## Number of successful writes since start (used by tests to prove autosave fires once per transition).
var write_count: int = 0
## Injectable clock (unix seconds) so tests can order saves deterministically.
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())


func _path(slot: String) -> String:
	return dir.path_join(slot)


func _ensure_dir() -> void:
	if dir != "user://":
		DirAccess.make_dir_recursive_absolute(dir)


# --- Saves ------------------------------------------------------------------------------------

func write_slot(slot: String, state: RefCounted, locale: String = "") -> Dictionary:
	_ensure_dir()
	var path := _path(slot)
	var tmp := path + ".tmp"
	var bak := path + ".bak"
	var envelope := {
		"schema_version": GameState.SCHEMA_VERSION,
		"saved_at": int(clock.call()),
		"locale": locale,
		"checksum": checksum_of_dict(state.to_dict()),
		"state": state.to_dict(),
	}
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error_key": "save.error.write"}
	f.store_string(JSON.stringify(envelope, "\t", true))
	f.flush()
	f.close()

	# Verify what we just wrote before it replaces anything.
	if not parse_envelope(FileAccess.get_file_as_string(tmp)).ok:
		DirAccess.remove_absolute(tmp)
		return {"ok": false, "error_key": "save.error.write"}

	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(path, bak)
	if DirAccess.rename_absolute(tmp, path) != OK:
		if FileAccess.file_exists(bak):
			DirAccess.rename_absolute(bak, path)  # put the old save back
		return {"ok": false, "error_key": "save.error.write"}
	write_count += 1
	return {"ok": true}


## Reads one slot: main file first, then its backup. Returns
## {ok, state, saved_at, recovered} or {ok:false, error_key}.
func read_slot(slot: String) -> Dictionary:
	var path := _path(slot)
	var last_error := ""
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var r := parse_envelope(FileAccess.get_file_as_string(candidate))
		if r.ok:
			r["recovered"] = candidate != path
			return r
		last_error = r.error_key
	return {"ok": false, "error_key": last_error if last_error != "" else "save.error.missing"}


func slot_exists(slot: String) -> bool:
	var path := _path(slot)
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


func has_any() -> bool:
	return slot_exists(MANUAL) or slot_exists(AUTO)


## Newest readable save across both slots. If saves exist but none can be read, reports corruption.
func load_latest() -> Dictionary:
	var best: Dictionary = {}
	var error_key := ""
	for slot in [MANUAL, AUTO]:
		if not slot_exists(slot):
			continue
		var r := read_slot(slot)
		if r.ok:
			r["slot"] = slot
			if best.is_empty() or int(r.saved_at) > int(best.saved_at):
				best = r
		else:
			error_key = r.error_key
	if not best.is_empty():
		return best
	return {"ok": false, "error_key": error_key if error_key != "" else "save.error.missing"}


func delete_slot(slot: String) -> void:
	var path := _path(slot)
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Parses and validates raw file text. Pure: touches no files.
func parse_envelope(text: String) -> Dictionary:
	if text.strip_edges() == "":
		return {"ok": false, "error_key": "save.error.corrupt"}
	var parsed: Variant = _parse_json(text)
	if not (parsed is Dictionary):
		return {"ok": false, "error_key": "save.error.corrupt"}
	var version := int(parsed.get("schema_version", 0))
	if version < 1 or version > GameState.SCHEMA_VERSION:
		return {"ok": false, "error_key": "save.error.version"}
	if not (parsed.get("state") is Dictionary):
		return {"ok": false, "error_key": "save.error.corrupt"}
	if str(parsed.get("checksum", "")) != checksum_of_dict(parsed.state):
		return {"ok": false, "error_key": "save.error.corrupt"}
	var state: RefCounted = GameState.from_dict(migrate(parsed.state, version))
	return {"ok": true, "state": state, "saved_at": int(parsed.get("saved_at", 0)),
			"locale": str(parsed.get("locale", ""))}


## Upgrades an older state dictionary to the current schema, one version step at a time.
## v1 -> v2: adds current stamina (-1 = full), fired story events, and a run seed.
## v2 -> v3: adds temporary buffs on the player.
## v3 -> v4: adds exploration progress (route, node, clues).
## v4 -> v5: adds the snapshot of a battle in progress (empty by default).
## v5 -> v6: adds story progress (open dialogue, queued dialogue, ending).
func migrate(state_dict: Dictionary, from_version: int) -> Dictionary:
	var d: Dictionary = state_dict.duplicate(true)
	if from_version < 2:
		if d.get("player") is Dictionary:
			d["player"]["stamina"] = -1
		if d.get("calendar") is Dictionary:
			d["calendar"]["events_fired"] = []
		d["run_seed"] = 1
	if from_version < 3:
		if d.get("player") is Dictionary:
			d["player"]["buffs"] = []
	if from_version < 4:
		d["exploration"] = {"active": false, "route": "", "node": "", "history": [], "clues": [], "completed": [],
				"pending_recruit": "", "pending_battle": ""}
	if from_version < 5:
		d["battle"] = {}
	if from_version < 6:
		d["story"] = {"dialogue": {}, "pending_dialogue": "", "ending": ""}
	return d


## Like JSON.parse_string but quiet: damaged files are expected input, not engine errors.
func _parse_json(text: String) -> Variant:
	var j := JSON.new()
	if j.parse(text) != OK:
		return null
	return j.data


## Checksum over a canonical form: sorted keys, whole-number floats turned back into ints (JSON text
## has no int/float distinction). Runs on the raw stored dictionary, so it is valid for any schema version.
func checksum_of_dict(d: Dictionary) -> String:
	return str(JSON.stringify(_canonical(d), "", true).hash())


func _canonical(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k in v:
			out[str(k)] = _canonical(v[k])
		return out
	if v is Array:
		return v.map(func(e: Variant) -> Variant: return _canonical(e))
	if v is float and v == floorf(v) and absf(v) < 9.0e15:
		return int(v)
	return v


# --- Settings (language etc.) -----------------------------------------------------------------

func load_settings() -> Dictionary:
	var path := _path(SETTINGS)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = _parse_json(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func save_settings(settings: Dictionary) -> bool:
	_ensure_dir()
	var f := FileAccess.open(_path(SETTINGS), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(settings, "\t", true))
	f.close()
	return true
