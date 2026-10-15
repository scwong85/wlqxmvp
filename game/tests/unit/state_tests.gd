extends RefCounted
## State and persistence tests (M2). Called from run_unit.gd with its `_check` callable.

const GameState = preload("res://scripts/domain/game_state.gd")
const PlayerState = preload("res://scripts/domain/player_state.gd")
const CalendarState = preload("res://scripts/domain/calendar_state.gd")
const ResourceState = preload("res://scripts/domain/resource_state.gd")
const CultivationState = preload("res://scripts/domain/cultivation_state.gd")
const RelationshipState = preload("res://scripts/domain/relationship_state.gd")
const SaveService = preload("res://scripts/services/save_service.gd")

const TEST_DIR := "user://unit_test_saves/"

var check: Callable


func run(check_fn: Callable) -> void:
	check = check_fn
	_player()
	_calendar()
	_resources()
	_cultivation_and_relationships()
	_game_state_roundtrip()
	_tolerant_loading()
	_save_service()


# Round trip through real JSON text, as a save file would.
func _json_roundtrip(d: Dictionary) -> Variant:
	return JSON.parse_string(JSON.stringify(d))


func _same(a: Dictionary, b: Dictionary) -> bool:
	return JSON.stringify(a, "", true) == JSON.stringify(b, "", true)


func _player() -> void:
	var p := PlayerState.new()
	check.call(p.get_attr("body") == 5 and p.get_attr("spirit") == 5, "player: five attributes start at 5")
	check.call(p.add_attr("power", 200) == 94 and p.get_attr("power") == 99, "player: attribute caps at 99, returns applied delta")
	check.call(p.add_attr("power", -500) == -98 and p.get_attr("power") == 1, "player: attribute floors at 1")
	check.call(p.add_attr("luck", 3) == 0, "player: unknown attribute ignored")
	check.call(p.learn("fist_1") and not p.learn("fist_1") and not p.learn(""), "player: learn is unique, rejects empty")
	p.path_id = "green_sword"
	var q = PlayerState.from_dict(_json_roundtrip(p.to_dict()))
	check.call(_same(p.to_dict(), q.to_dict()), "player: JSON round trip")


func _calendar() -> void:
	var c := CalendarState.new()
	check.call(c.week == 1 and c.slot == 1 and not c.finished and c.year() == 1 and c.month() == 1 and c.week_in_month() == 1, "calendar: starts in year 1, month 1, week 1, slot 1")
	check.call(CalendarState.WEEKS == 180 and CalendarState.TOTAL_SLOTS == 360, "calendar: three years are 180 weeks and 360 slots")
	var new_weeks := 0
	var new_months := 0
	var new_years := 0
	var steps := 0
	while not c.finished:
		var r: Dictionary = c.advance_slot()
		steps += 1
		if r.new_week:
			new_weeks += 1
		if r.new_month:
			new_months += 1
		if r.new_year:
			new_years += 1
		if steps == 9:
			check.call(c.week == 5 and c.slot == 2 and c.month() == 1, "calendar: nine advances end the first month's last slot")
		if steps == 10:
			check.call(c.week == 6 and c.slot == 1 and c.month() == 2 and c.week_in_month() == 1, "calendar: the tenth advance starts month 2")
		if steps == 60:
			check.call(c.year() == 1 and c.month() == 7 and c.season() == 2, "calendar: 60 advances reach month 7 (autumn)")
		if steps == 120:
			check.call(c.year() == 2 and c.month() == 1 and c.week_in_month() == 1, "calendar: 120 advances start year 2")
	check.call(steps == 360 and c.week == 180 and c.year() == 3 and c.month() == 12 and c.week_in_month() == 5, "calendar: 360 advances use every slot and finish in year 3, month 12, week 5")
	check.call(new_weeks == 179 and new_months == 35 and new_years == 2, "calendar: rollovers (weeks %d, months %d, years %d)" % [new_weeks, new_months, new_years])
	check.call(c.slots_used() == 360, "calendar: slots_used is 360 when finished")
	var after: Dictionary = c.advance_slot()
	check.call(not after.advanced and c.week == 180, "calendar: cannot advance past the end")
	var winter := CalendarState.new()
	winter.week = 50
	check.call(winter.month() == 10 and winter.season() == 3, "calendar: month 10 is winter")
	var bad = CalendarState.from_dict({"week": 999, "slot": -3, "finished": 1})
	check.call(bad.week == 180 and bad.slot == 1, "calendar: out-of-range values are clamped on load")
	var rt = CalendarState.from_dict(_json_roundtrip(c.to_dict()))
	check.call(_same(c.to_dict(), rt.to_dict()), "calendar: JSON round trip")


func _resources() -> void:
	var r := ResourceState.new()
	check.call(r.get_amount("coins") == 20 and r.get_amount("food") == 0, "resources: starting amounts")
	check.call(r.add("herbs", 5) == 5 and r.get_amount("herbs") == 5, "resources: add")
	check.call(r.add("herbs", -50) == -5 and r.get_amount("herbs") == 0, "resources: never below zero")
	check.call(not r.spend("coins", 21) and r.get_amount("coins") == 20, "resources: failed spend changes nothing")
	check.call(r.spend("coins", 8) and r.get_amount("coins") == 12, "resources: spend")
	check.call(not r.spend("coins", -5), "resources: negative spend rejected")
	check.call(r.can_afford({"coins": 12}) and not r.can_afford({"coins": 13, "food": 0}), "resources: can_afford")
	check.call(r.add("gold_bars", 9) == 0, "resources: unknown currency ignored")
	r.add_item("jade_pendant", 2)
	r.add_item("jade_pendant", -1)
	check.call(r.get_item("jade_pendant") == 1, "resources: items count")
	r.add_item("jade_pendant", -9)
	check.call(not r.items.has("jade_pendant"), "resources: item removed at zero")
	r.add_item("tea", 3)
	var q = ResourceState.from_dict(_json_roundtrip(r.to_dict()))
	check.call(_same(r.to_dict(), q.to_dict()), "resources: JSON round trip")


func _cultivation_and_relationships() -> void:
	var c := CultivationState.new()
	c.add_progress("green_sword", 3)
	c.add_progress("green_sword", -10)
	c.record_practice("fishing")
	c.record_practice("fishing")
	check.call(c.path_progress["green_sword"] == 0 and c.practice_counts["fishing"] == 2, "cultivation: progress floors at 0, practice counts")
	var cq = CultivationState.from_dict(_json_roundtrip(c.to_dict()))
	check.call(_same(c.to_dict(), cq.to_dict()), "cultivation: JSON round trip")

	var r := RelationshipState.new()
	check.call(r.add_score("shen_qinghe", 500) == 100 and r.get_score("shen_qinghe") == 100, "relationships: score caps at 100")
	check.call(r.add_score("shen_qinghe", -900) == -200 and r.get_score("shen_qinghe") == -100, "relationships: score floors at -100")
	check.call(r.get_status("lu_chenzhou") == "unknown", "relationships: default status")
	check.call(r.set_status("lu_chenzhou", "joined") and not r.set_status("lu_chenzhou", "bogus"), "relationships: invalid status rejected")
	r.set_flag("met_in_bamboo_pass")
	check.call(r.has_flag("met_in_bamboo_pass") and not r.has_flag("never_set"), "relationships: flags")
	var rq = RelationshipState.from_dict(_json_roundtrip(r.to_dict()))
	check.call(_same(r.to_dict(), rq.to_dict()), "relationships: JSON round trip")


func _busy_state() -> RefCounted:
	var g := GameState.new_game()
	g.player.add_attr("agility", 7)
	g.player.path_id = "listening_rain"
	g.player.learn("rain_step")
	g.calendar.advance_slot()
	g.calendar.advance_slot()
	g.resources.add("food", 4)
	g.resources.add_item("tea", 2)
	g.cultivation.record_practice("music")
	g.relationships.add_score("bai_yan", 12)
	g.relationships.set_status("bai_yan", "available")
	g.relationships.set_flag("day3_seen")
	return g


func _game_state_roundtrip() -> void:
	var g := _busy_state()
	var q = GameState.from_dict(_json_roundtrip(g.to_dict()))
	check.call(_same(g.to_dict(), q.to_dict()), "game state: full JSON round trip is lossless")
	check.call(q.calendar.week == 2 and q.calendar.slot == 1, "game state: calendar restored")
	check.call(q.resources.get_item("tea") == 2, "game state: items restored")


func _tolerant_loading() -> void:
	for junk in [null, "text", [], 42]:
		var g = GameState.from_dict(junk)
		check.call(g.calendar.week == 1 and g.player.get_attr("body") == 5, "tolerant: junk %s gives defaults, no crash" % str(junk))
	var partial = GameState.from_dict({"calendar": {"week": 4}, "extra_unknown_key": {"x": 1}, "player": "oops"})
	check.call(partial.calendar.week == 4 and partial.player.get_attr("body") == 5, "tolerant: partial data, unknown keys and bad sections handled")


# --- SaveService ---------------------------------------------------------------------------

func _wipe(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))


func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _save_service() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_wipe(TEST_DIR)
	var svc = SaveService.new()
	svc.dir = TEST_DIR
	var now := [1000]
	svc.clock = func() -> int:
		now[0] += 10
		return now[0]
	var m: String = TEST_DIR + SaveService.MANUAL
	var a: String = TEST_DIR + SaveService.AUTO

	check.call(not svc.has_any(), "save: empty folder has no saves")
	check.call(svc.read_slot(SaveService.MANUAL).error_key == "save.error.missing", "save: missing slot reports save.error.missing")
	check.call(svc.load_latest().error_key == "save.error.missing", "save: load_latest with nothing reports missing")

	var g := _busy_state()
	check.call(svc.write_slot(SaveService.MANUAL, g, "en").ok, "save: write ok")
	var r: Dictionary = svc.read_slot(SaveService.MANUAL)
	check.call(r.ok and _same(g.to_dict(), r.state.to_dict()), "save: read restores identical state")
	check.call(r.locale == "en" and not r.recovered, "save: locale recorded, not a recovery")

	# Second write keeps the previous good file as a backup.
	g.resources.add("coins", 5)
	svc.write_slot(SaveService.MANUAL, g)
	check.call(FileAccess.file_exists(m + ".bak"), "save: previous save kept as .bak")
	check.call(svc.read_slot(SaveService.MANUAL).state.resources.get_amount("coins") == 25, "save: newest write wins")

	# Corrupt the main file: the backup is used.
	_write_text(m, "{ this is not json")
	var rec: Dictionary = svc.read_slot(SaveService.MANUAL)
	check.call(rec.ok and rec.recovered and rec.state.resources.get_amount("coins") == 20, "save: corrupt main recovers from backup")

	# Corrupt both: typed error, no crash.
	_write_text(m + ".bak", "")
	var dead: Dictionary = svc.read_slot(SaveService.MANUAL)
	check.call(not dead.ok and dead.error_key == "save.error.corrupt", "save: corrupt main + empty backup reports save.error.corrupt")
	svc.delete_slot(SaveService.MANUAL)
	check.call(not svc.slot_exists(SaveService.MANUAL), "save: delete_slot removes main, backup and temp")

	# Interrupted write: a half-written temp file must not disturb the good save.
	svc.write_slot(SaveService.MANUAL, g)
	_write_text(m + ".tmp", '{"schema_version": 1, "sta')
	check.call(svc.read_slot(SaveService.MANUAL).ok, "save: leftover partial .tmp is ignored")
	svc.write_slot(SaveService.MANUAL, g)
	check.call(svc.read_slot(SaveService.MANUAL).ok, "save: next write succeeds over a stale .tmp")

	# Wrong or missing schema versions.
	var env: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(m))
	env["schema_version"] = 99
	_write_text(m, JSON.stringify(env))
	_write_text(m + ".bak", JSON.stringify(env))
	check.call(svc.read_slot(SaveService.MANUAL).error_key == "save.error.version", "save: newer schema version rejected with save.error.version")
	env["schema_version"] = 0
	_write_text(m, JSON.stringify(env))
	_write_text(m + ".bak", JSON.stringify(env))
	check.call(svc.read_slot(SaveService.MANUAL).error_key == "save.error.version", "save: version 0 rejected")

	# Tampering with the contents (valid JSON, wrong checksum) is detected.
	svc.delete_slot(SaveService.MANUAL)
	svc.write_slot(SaveService.MANUAL, g)
	var text := FileAccess.get_file_as_string(m)
	_write_text(m, text.replace('"coins": 25', '"coins": 99999'))
	check.call(svc.read_slot(SaveService.MANUAL).error_key == "save.error.corrupt", "save: edited contents fail the checksum")

	# Not-an-object and empty-state envelopes.
	for junk in ["[]", "42", '{"schema_version": 1}', '{"schema_version": 1, "state": 5}']:
		check.call(not svc.parse_envelope(junk).ok, "save: rejects %s" % junk)

	# Newest of two slots wins.
	svc.delete_slot(SaveService.MANUAL)
	var older := _busy_state()
	svc.write_slot(SaveService.MANUAL, older)
	var newer := _busy_state()
	newer.calendar.advance_slot()
	svc.write_slot(SaveService.AUTO, newer)
	var latest: Dictionary = svc.load_latest()
	check.call(latest.ok and latest.slot == SaveService.AUTO, "save: load_latest picks the newer slot")
	_write_text(a, "garbage")
	_write_text(a + ".bak", "garbage")
	var fallback: Dictionary = svc.load_latest()
	check.call(fallback.ok and fallback.slot == SaveService.MANUAL, "save: load_latest falls back to the readable slot")
	_write_text(m, "garbage")
	_write_text(m + ".bak", "garbage")
	check.call(svc.load_latest().error_key == "save.error.corrupt", "save: both slots unreadable reports corrupt")

	# Settings.
	check.call(svc.load_settings().is_empty(), "settings: empty by default")
	svc.save_settings({"locale": "en"})
	check.call(svc.load_settings().get("locale") == "en", "settings: locale persists")
	_write_text(TEST_DIR + SaveService.SETTINGS, "not json")
	check.call(svc.load_settings().is_empty(), "settings: corrupt file gives empty settings")

	check.call(svc.migrate({"a": 1}, GameState.SCHEMA_VERSION) == {"a": 1}, "save: migrate is identity for the current version")
	svc.free()
	_wipe(TEST_DIR)
