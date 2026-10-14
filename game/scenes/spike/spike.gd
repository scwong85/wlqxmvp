extends Control
## Engine spike scene (M0). Shows Mandarin text, echoes mouse/touch/keyboard input,
## and reports viewport size and orientation. All player-visible text uses Loc keys.

const MAX_LOG_LINES := 8

var _title: Label
var _subtitle: Label
var _attributes: Label
var _paths: Label
var _viewport_label: Label
var _glyph_label: Label
var _fallback_label: Label
var _log_header: Label
var _log_label: Label
var _start_button: Button
var _toggle_button: Button
var _log_lines: Array[String] = []
var _press_count := 0


func _ready() -> void:
	_build_ui()
	_refresh_texts()
	get_viewport().size_changed.connect(_refresh_texts)
	_start_button.pressed.connect(_on_start_pressed)
	_toggle_button.pressed.connect(_on_toggle_pressed)
	_run_self_test()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	_title = _make_label(56)
	_subtitle = _make_label(28)
	_attributes = _make_label(28)
	_paths = _make_label(28)
	_viewport_label = _make_label(24)
	_glyph_label = _make_label(24)
	_fallback_label = _make_label(24)
	_log_header = _make_label(24)
	_log_label = _make_label(22)
	for l in [_title, _subtitle, _attributes, _paths, _viewport_label, _glyph_label,
			_fallback_label, _log_header, _log_label]:
		box.add_child(l)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	_start_button = _make_button()
	_toggle_button = _make_button()
	buttons.add_child(_start_button)
	buttons.add_child(_toggle_button)


func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	return l


func _make_button() -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(240, 64)
	b.add_theme_font_size_override("font_size", 28)
	return b


func _refresh_texts() -> void:
	var size := get_viewport_rect().size
	var is_landscape := size.x >= size.y
	var orientation_key := "spike.orientation.landscape" if is_landscape else "spike.orientation.portrait"
	_title.text = Loc.t("spike.title")
	_subtitle.text = Loc.t("spike.subtitle")
	_attributes.text = Loc.t("spike.attributes")
	_paths.text = Loc.t("spike.paths")
	_viewport_label.text = Loc.t("spike.viewport", {
		"w": int(size.x), "h": int(size.y), "orientation": Loc.t(orientation_key)})
	_glyph_label.text = Loc.t("spike.glyph_check")
	_fallback_label.text = Loc.t("spike.fallback_only_zh")
	_log_header.text = Loc.t("spike.input_header")
	_start_button.text = Loc.t("spike.button")
	_toggle_button.text = Loc.t("spike.toggle")
	_log_label.text = "\n".join(_log_lines)


func _push_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	_log_label.text = "\n".join(_log_lines)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_push_log(Loc.t("spike.input.mouse", {"x": int(event.position.x), "y": int(event.position.y)}))
	elif event is InputEventScreenTouch and event.pressed:
		_push_log(Loc.t("spike.input.touch", {"x": int(event.position.x), "y": int(event.position.y)}))
	elif event is InputEventKey and event.pressed and not event.echo:
		_push_log(Loc.t("spike.input.key", {"key": OS.get_keycode_string(event.keycode)}))


func _on_start_pressed() -> void:
	_press_count += 1
	_push_log(Loc.t("spike.input.button", {"count": _press_count}))


func _on_toggle_pressed() -> void:
	Loc.set_locale("en" if Loc.locale == "zh_CN" else "zh_CN")
	_refresh_texts()


func _run_self_test() -> void:
	# Machine-checkable evidence for headless runs (printed to stdout).
	var zh_ok := Loc.t("spike.title") == "玉谷传奇"
	Loc.set_locale("en")
	var en_ok := Loc.t("spike.title") == "Jade Valley Chronicles"
	var fallback_ok := Loc.t("spike.fallback_only_zh") == "此行只有中文文本，用于测试英文回退"
	var placeholder_ok := Loc.t("spike.input.button", {"count": 3}) == "Button pressed x 3"
	var missing_ok := Loc.t("no.such.key") == "[no.such.key]"
	Loc.set_locale("zh_CN")
	var font := get_theme_default_font()
	var glyph_ok: bool = font != null and font.has_char("玉".unicode_at(0)) and font.has_char("骨".unicode_at(0))
	print("SPIKE_SELFTEST zh=%s en=%s fallback=%s placeholder=%s missing=%s glyphs=%s" % [
		zh_ok, en_ok, fallback_ok, placeholder_ok, missing_ok, glyph_ok])
	if zh_ok and en_ok and fallback_ok and placeholder_ok and missing_ok and glyph_ok:
		print("SPIKE_OK")
	else:
		print("SPIKE_FAIL")
