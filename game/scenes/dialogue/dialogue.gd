extends Control
## Dialogue screen (M12): speaker, text, then either a Continue button or the choices. All rules are in
## DialogueSystem; this scene shows the current node and forwards the player's pick to Game, which autosaves.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const RecruitDialog = preload("res://scenes/shared/recruit_dialog.gd")
const StageView = preload("res://scenes/shared/stage_view.gd")
const OverlayUtil = preload("res://scenes/shared/overlay_util.gd")

const FONT := 28

# Public so tests can drive the screen like a player.
var continue_button: Button = null
var choice_buttons: Dictionary = {}   # choice id -> Button
var speaker_label: Label
var text_label: Label
var stage_view: Control
var log_button: Button
var log_panel: Control = null
var log_close_button: Button

var _box: VBoxContainer
var _panel: PanelContainer
var _choices: VBoxContainer
var _note: Label


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	var dest := Game.next_story_scene()
	if dest != "dialogue":  # nothing to say (e.g. opened by mistake): go where the story says
		Router.goto.call_deferred(dest if dest != "" else "cultivation")
		return
	add_child(Backdrop.new())
	var frame := SafeFrame.new()
	add_child(frame)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	frame.add_child(_box)
	stage_view = StageView.new()
	stage_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_view.size_flags_stretch_ratio = 1.15
	_box.add_child(stage_view)
	_panel = PanelContainer.new()
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.size_flags_stretch_ratio = 1.6
	_box.add_child(_panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	_panel.add_child(inner)
	var head := HBoxContainer.new()
	inner.add_child(head)
	speaker_label = UiKit.make_label(30)
	speaker_label.modulate = Color("9be3c3")
	speaker_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(speaker_label)
	log_button = UiKit.make_button(Vector2(110, 48))
	log_button.add_theme_font_size_override("font_size", 22)
	log_button.pressed.connect(_show_log)
	head.add_child(log_button)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(scroll)
	text_label = UiKit.make_label(FONT)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(text_label)
	_note = UiKit.make_label(22)
	_note.modulate = Color(1, 1, 1, 0.7)
	_box.add_child(_note)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 10)
	_box.add_child(_choices)
	Loc.locale_changed.connect(func(_c: String) -> void: _show())
	Layout.mode_changed.connect(func(_m: String) -> void: _show())
	_show()
	print("DIALOGUE_READY id=%s node=%s" % [Game.state.story.dialogue.id, Game.state.story.dialogue.node])


func _show() -> void:
	var dlg := Game.current_dialogue()
	var node := DialogueSystem.current_node(Game.state, dlg)
	if node.is_empty():
		_finish({"ended": true})
		return
	var stg: Dictionary = Game.state.story.dialogue.get("stage", {})
	stage_view.animate = Game.animations_enabled()
	stage_view.show_stage(stg, node.get("stage", []))
	log_button.text = Loc.t("dialogue.log")
	var skey := str(node.get("speaker_key", ""))
	speaker_label.text = Loc.t(skey) if skey != "" else ""
	speaker_label.visible = skey != ""
	text_label.text = Loc.t(str(node.text_key))
	_note.text = ""
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()
	choice_buttons.clear()
	continue_button = null
	var first: Button = null
	if node.has("choices"):
		var reasons: Array = []
		for cs in DialogueSystem.choice_states(Game.state, dlg, Content):
			var cid: String = cs.id
			var b := Button.new()
			b.theme_type_variation = "CardButton"
			b.custom_minimum_size = Vector2(0, 76)
			b.add_theme_font_size_override("font_size", 24)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.clip_text = true
			b.text = Loc.t(cs.label_key)
			b.disabled = not cs.available
			b.pressed.connect(func() -> void: _on_choice(cid))
			_choices.add_child(b)
			choice_buttons[cid] = b
			if not cs.available:
				reasons.append_array(cs.reasons)
			elif first == null:
				first = b
		if not reasons.is_empty():
			_note.text = RecruitDialog.reason_text(reasons)
	else:
		continue_button = UiKit.make_button(Vector2(0, 76))
		continue_button.add_theme_font_size_override("font_size", 24)
		continue_button.text = Loc.t("dialogue.continue")
		continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		continue_button.pressed.connect(_on_continue)
		_choices.add_child(continue_button)
		first = continue_button
	if first != null:
		first.grab_focus()
	_report_layout()


func _show_log() -> void:
	if log_panel != null:
		return
	var parts := OverlayUtil.make(780)
	log_panel = parts[0]
	var box: VBoxContainer = parts[1]
	var title := UiKit.make_label(30)
	title.text = Loc.t("dialogue.log")
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, maxf(220.0, Layout.usable_height() * 0.55))
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for e in Game.state.story.dialogue.get("log", []):
		var l := UiKit.make_label(22)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if str(e.get("choice_key", "")) != "":
			l.text = "> " + Loc.t(str(e.choice_key))
			l.modulate = Color("e1c06b")
		else:
			var line := Loc.t(str(e.text_key))
			l.text = Loc.t("dialogue.log_line", {"who": Loc.t(str(e.speaker_key)), "text": line}) if str(e.get("speaker_key", "")) != "" else line
		list.add_child(l)
	log_close_button = UiKit.make_button(Vector2(0, 60))
	log_close_button.add_theme_font_size_override("font_size", 24)
	log_close_button.text = Loc.t("dialogue.log_close")
	log_close_button.pressed.connect(func() -> void:
		log_panel.queue_free()
		log_panel = null)
	box.add_child(log_close_button)
	add_child(log_panel)
	log_close_button.grab_focus()
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _on_continue() -> void:
	_handle(Game.dialogue_advance())


func _on_choice(choice_id: String) -> void:
	_handle(Game.dialogue_choose(choice_id))


func choose(choice_id: String) -> void:
	_on_choice(choice_id)


func _handle(result: Dictionary) -> void:
	if not result.get("ok", false):
		return
	if result.ended:
		_finish(result)
	else:
		_show()


func _finish(result: Dictionary) -> void:
	Router.goto(Game.after_dialogue(result))


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var parts: Array[String] = []
	if continue_button != null:
		var p := continue_button.get_global_rect().get_center()
		parts.append("dlg_continue=%d,%d" % [int(p.x), int(p.y)])
	var i := 0
	for cid in choice_buttons:
		i += 1
		var q: Vector2 = choice_buttons[cid].get_global_rect().get_center()
		parts.append("dlg_choice%d=%d,%d" % [i, int(q.x), int(q.y)])
	var vp := get_viewport_rect().size
	print("UI_POS vp=%d,%d %s" % [int(vp.x), int(vp.y), " ".join(parts)])
	var problems := audit_layout()
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for pr in problems:
		print("  audit: ", pr)
