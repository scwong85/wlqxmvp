extends Control
## Runs a minigame for an activity (Game.pending_play = {activity, option}): intro with Start / Quick resolve,
## the play itself with fixed time steps, then a result with the grade and reward multiplier.
## Collect performs the activity with the play record and returns to training with the result shown.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const MinigameRules = preload("res://scripts/domain/minigame_rules.gd")
const FishingView = preload("res://scenes/minigame/fishing_view.gd")
const TapView = preload("res://scenes/minigame/tap_view.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const STEP := 1.0 / 60.0

# Public so tests can drive the screen like a player.
var start_button: Button
var quick_button: Button
var back_button: Button
var collect_button: Button
var title_label: Label
var help_label: Label
var result_label: Label
var view: Control
var game_logic: RefCounted = null
var phase: String = "intro"      # intro | play | result
var record: Dictionary = {}

var _activity_id: String = ""
var _option_id: String = ""
var _acc: float = 0.0
var _hold_keys: bool = false
var _hold_pointer: bool = false
var _time_label: Label
var _box: VBoxContainer


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	_activity_id = str(Game.pending_play.get("activity", ""))
	_option_id = str(Game.pending_play.get("option", ""))
	var mg: Dictionary = Content.minigame_for(_activity_id)
	if mg.is_empty():
		Router.goto.call_deferred("cultivation")
		return
	var def: Dictionary = ActivityRules.effective_def(Content.activity(_activity_id), _option_id)
	game_logic = MinigameRules.create(str(mg.id))
	var seed_value := MinigameRules.seed_for(int(Game.state.run_seed), Game.state.calendar.week, Game.state.calendar.slot, _activity_id)
	game_logic.start({"difficulty": MinigameRules.difficulty_for(def)}, seed_value)

	add_child(Backdrop.new())
	var frame := SafeFrame.new()
	add_child(frame)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	frame.add_child(_box)
	title_label = UiKit.make_label(36)
	title_label.text = Loc.t(str(mg.title_key))
	_box.add_child(title_label)
	help_label = UiKit.make_label(24)
	help_label.text = Loc.t(str(mg.help_key))
	_box.add_child(help_label)
	view = FishingView.new() if str(mg.id) == "fishing" else TapView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.custom_minimum_size = Vector2(0, 150)
	view.hold_changed.connect(func(d: bool) -> void:
		_hold_pointer = d
		_push_hold())
	view.set_hero_look(_hero_look())
	_box.add_child(view)
	_time_label = UiKit.make_label(22)
	_box.add_child(_time_label)
	result_label = UiKit.make_label(26)
	_box.add_child(result_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_box.add_child(row)
	back_button = _btn(row, "minigame.back", 150)
	quick_button = _btn(row, "minigame.quick", 0)
	start_button = _btn(row, "minigame.start", 0)
	collect_button = _btn(row, "minigame.collect", 0)
	back_button.pressed.connect(func() -> void: Router.goto("cultivation"))
	quick_button.pressed.connect(_on_quick)
	start_button.pressed.connect(_on_start)
	collect_button.pressed.connect(_on_collect)
	Layout.mode_changed.connect(func(_m: String) -> void: _refresh())
	_set_phase("intro")
	start_button.grab_focus()
	print("MINIGAME_READY %s" % str(mg.id))
	_report_layout()


func _btn(parent: Node, key: String, min_w: float) -> Button:
	var b := UiKit.make_button(Vector2(min_w, 64))
	b.add_theme_font_size_override("font_size", 24)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if min_w == 0 else Control.SIZE_SHRINK_BEGIN
	b.text = Loc.t(key)
	b.clip_text = true
	parent.add_child(b)
	return b


func _hero_look() -> Dictionary:
	var l: Dictionary = preload("res://scripts/domain/look_rules.gd").sanitize(Game.state.player.look)
	l["weapon"] = ""
	return l


func _set_phase(p: String) -> void:
	phase = p
	start_button.visible = p == "intro"
	quick_button.visible = p == "intro"
	collect_button.visible = p == "result"
	help_label.visible = p != "result"
	result_label.visible = p == "result"
	view.update_snapshot(game_logic.snapshot())
	_refresh()
	if p == "result":
		collect_button.grab_focus()


func _refresh() -> void:
	if phase == "play":
		_time_label.text = Loc.t("minigame.time", {"s": int(ceil(game_logic.snapshot().time_left))})
	else:
		_time_label.text = ""


func _on_start() -> void:
	game_logic.set_input("hold", false)
	_acc = 0.0
	_set_phase("play")


func _on_quick() -> void:
	record = MinigameRules.play_record(str(Content.minigame_for(_activity_id).id), 0.0, true)
	_show_result()


func _process(delta: float) -> void:
	if phase != "play":
		return
	_acc += minf(delta, 0.1)
	while _acc >= STEP and not game_logic.done:
		_acc -= STEP
		game_logic.step(STEP)
	view.update_snapshot(game_logic.snapshot())
	_refresh()
	if game_logic.done:
		record = MinigameRules.play_record(str(Content.minigame_for(_activity_id).id), float(game_logic.result().score))
		_show_result()


func _show_result() -> void:
	result_label.text = "%s\n%s" % [Loc.t("minigame.grade." + str(record.grade)), Loc.t("minigame.result.mult", {"m": record.mult})]
	_set_phase("result")
	print("MINIGAME_DONE grade=%s score=%s quick=%s" % [record.grade, str(record.score), str(record.quick)])


func _on_collect() -> void:
	var r: Dictionary = Game.perform_activity(_activity_id, _option_id, record)
	Game.pending_play = {}
	if r.ok:
		Game.pending_result = r
	Router.goto("cultivation")


func _push_hold() -> void:
	if game_logic != null:
		game_logic.set_input("hold", _hold_keys or _hold_pointer)


func _input(event: InputEvent) -> void:
	if phase != "play":
		return
	if event is InputEventKey and not event.echo and [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_UP, KEY_W].has(event.keycode):
		_hold_keys = event.pressed
		_push_hold()
		get_viewport().set_input_as_handled()


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var parts: Array[String] = []
	for pair in [["mg_start", start_button], ["mg_quick", quick_button], ["mg_back", back_button], ["mg_view", view]]:
		var c: Control = pair[1]
		if c.is_visible_in_tree():
			var ctr := c.get_global_rect().get_center()
			parts.append("%s=%d,%d" % [pair[0], int(ctr.x), int(ctr.y)])
	var vp := get_viewport_rect().size
	print("UI_POS vp=%d,%d %s" % [int(vp.x), int(vp.y), " ".join(parts)])
	var problems := audit_layout()
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)
