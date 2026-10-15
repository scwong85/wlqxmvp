extends Control
## New-game screen: name, gender and chibi look, with a live preview. Confirming starts the run.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const ChibiRig = preload("res://scenes/shared/chibi_rig.gd")
const LookRules = preload("res://scripts/domain/look_rules.gd")

# Public so tests can drive the screen like a player.
var name_edit: LineEdit
var gender_buttons: Dictionary = {}    # "m" | "f" -> Button
var hair_prev: Button
var hair_next: Button
var hair_color_buttons: Array = []
var outfit_buttons: Array = []
var skin_buttons: Array = []
var confirm_button: Button
var back_button: Button
var preview: Control
var look: Dictionary = LookRules.default_look()

var _body: BoxContainer
var _preview_panel: PanelContainer
var _title: Label
var _labels: Dictionary = {}
var _hair_label: Label


func _ready() -> void:
	UiKit.apply(self)
	add_child(Backdrop.new())
	var frame := SafeFrame.new()
	add_child(frame)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	frame.add_child(main)
	_title = UiKit.make_label(36)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	main.add_child(_title)

	_body = BoxContainer.new()
	_body.add_theme_constant_override("separation", 16)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(_body)
	_preview_panel = PanelContainer.new()
	_preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_panel.size_flags_stretch_ratio = 38.0
	_body.add_child(_preview_panel)
	preview = ChibiRig.new()
	_preview_panel.add_child(preview)

	var form_panel := PanelContainer.new()
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form_panel.size_flags_stretch_ratio = 62.0
	_body.add_child(form_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	form_panel.add_child(scroll)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 10)
	scroll.add_child(form)

	form.add_child(_section("name"))
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(0, 56)
	name_edit.add_theme_font_size_override("font_size", 28)
	name_edit.max_length = LookRules.MAX_NAME
	name_edit.text = Loc.t("hero.default_name")
	name_edit.select_all_on_focus = true
	name_edit.text_submitted.connect(func(_t: String) -> void: _on_confirm())
	form.add_child(name_edit)

	form.add_child(_section("gender"))
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 8)
	form.add_child(grow)
	for g in LookRules.GENDERS:
		var b := UiKit.make_button(Vector2(0, 56))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			look.gender = g
			_refresh())
		grow.add_child(b)
		gender_buttons[g] = b

	form.add_child(_section("hair"))
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 8)
	form.add_child(hrow)
	hair_prev = UiKit.make_button(Vector2(64, 56))
	hair_next = UiKit.make_button(Vector2(64, 56))
	hair_prev.text = "<"
	hair_next.text = ">"
	for b in [hair_prev, hair_next]:
		b.add_theme_font_size_override("font_size", 26)
	_hair_label = UiKit.make_label(24, HORIZONTAL_ALIGNMENT_CENTER)
	_hair_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hair_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hair_prev.pressed.connect(func() -> void:
		look.hair = (int(look.hair) + LookRules.HAIR_STYLES - 1) % LookRules.HAIR_STYLES
		_refresh())
	hair_next.pressed.connect(func() -> void:
		look.hair = (int(look.hair) + 1) % LookRules.HAIR_STYLES
		_refresh())
	hrow.add_child(hair_prev)
	hrow.add_child(_hair_label)
	hrow.add_child(hair_next)

	form.add_child(_section("hair_color"))
	form.add_child(_swatches(LookRules.HAIR_COLORS, "hair_color", hair_color_buttons))
	form.add_child(_section("outfit"))
	form.add_child(_swatches(LookRules.OUTFIT_COLORS, "outfit", outfit_buttons))
	form.add_child(_section("skin"))
	form.add_child(_swatches(LookRules.SKINS, "skin", skin_buttons))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	main.add_child(actions)
	back_button = UiKit.make_button(Vector2(160, 64))
	back_button.add_theme_font_size_override("font_size", 24)
	back_button.pressed.connect(func() -> void: Router.goto("title"))
	confirm_button = UiKit.make_button(Vector2(0, 64))
	confirm_button.add_theme_font_size_override("font_size", 28)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.pressed.connect(_on_confirm)
	actions.add_child(back_button)
	actions.add_child(confirm_button)

	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	Layout.mode_changed.connect(func(_m: String) -> void: _apply_layout())
	_apply_layout()
	_refresh()
	confirm_button.grab_focus()
	print("HERO_CREATE_READY")
	_report_layout()


func _section(id: String) -> Label:
	var l := UiKit.make_label(22)
	l.modulate = Color(0.8, 0.95, 0.85, 0.85)
	_labels[id] = l
	return l


func _swatches(colors: Array, key: String, store: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for i in colors.size():
		var b := UiKit.make_button(Vector2(56, 56))
		b.toggle_mode = true
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(str(colors[i]))
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(3)
		sb.border_color = Color(1, 1, 1, 0.35)
		var sel := sb.duplicate()
		sel.border_color = Color("e1c06b")
		sel.set_border_width_all(6)
		for st in ["normal", "hover", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		for st2 in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st2, sel)
		var idx := i
		b.pressed.connect(func() -> void:
			look[key] = idx
			_refresh())
		row.add_child(b)
		store.append(b)
	return row


func _apply_layout() -> void:
	_body.vertical = Layout.is_portrait()
	_preview_panel.size_flags_stretch_ratio = 34.0 if Layout.is_portrait() else 38.0


func _refresh() -> void:
	_title.text = Loc.t("hero.create.title")
	for id in _labels:
		_labels[id].text = Loc.t("hero.create." + id)
	for g in gender_buttons:
		gender_buttons[g].text = Loc.t("hero.gender." + g)
		gender_buttons[g].set_pressed_no_signal(look.gender == g)
	_hair_label.text = Loc.t("hero.hair." + str(look.hair))
	for pair in [[hair_color_buttons, "hair_color"], [outfit_buttons, "outfit"], [skin_buttons, "skin"]]:
		for i in pair[0].size():
			pair[0][i].set_pressed_no_signal(int(look[pair[1]]) == i)
	back_button.text = Loc.t("map.back")
	confirm_button.text = Loc.t("hero.create.confirm")
	preview.setup(_preview_look(), "idle", "happy")


func _preview_look() -> Dictionary:
	var l := LookRules.sanitize(look)
	l["weapon"] = "sword"
	return l


func _on_confirm() -> void:
	Game.new_game()
	Game.set_hero(name_edit.text, look)
	Router.goto("cultivation")


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var parts: Array[String] = []
	for k in ["confirm", "back"]:
		var c: Control = confirm_button if k == "confirm" else back_button
		var ctr := c.get_global_rect().get_center()
		parts.append("hero_%s=%d,%d" % [k, int(ctr.x), int(ctr.y)])
	var vp := get_viewport_rect().size
	print("UI_POS vp=%d,%d %s" % [int(vp.x), int(vp.y), " ".join(parts)])
	var problems := audit_layout()
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)
