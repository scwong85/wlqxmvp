extends Node
## Restart test across two separate processes (run by scripts/build_web.sh):
##   godot --headless --path game res://tests/smoke/run_persist.tscn -- write
##   godot --headless --path game res://tests/smoke/run_persist.tscn -- read
## "write" plays a little and saves; "read" is a fresh process that must find the same state on disk.

const DIR := "user://persist_test/"


func _ready() -> void:
	Saves.dir = DIR
	var mode := "read"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	var ok := false
	if mode == "write":
		DirAccess.make_dir_recursive_absolute(DIR)
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(f))
		Game.new_game()
		Game.state.calendar.advance_slot()
		Game.state.calendar.advance_slot()
		Game.state.resources.add("coins", 7)
		Game.state.player.path_id = "green_sword"
		ok = Game.save_manual().ok
		print("PERSIST_WRITE_OK" if ok else "PERSIST_WRITE_FAIL")
	else:
		var r: Dictionary = Game.load_latest()
		var s = Game.state
		ok = r.ok and s.calendar.week == 2 and s.calendar.slot == 1 \
				and s.resources.get_amount("coins") == 27 and s.player.path_id == "green_sword"
		print("PERSIST_READ_OK" if ok else "PERSIST_READ_FAIL")
	get_tree().quit(0 if ok else 1)
