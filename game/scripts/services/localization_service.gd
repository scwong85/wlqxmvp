extends Node
## Localization service. Mandarin (zh_CN) is the default and the fallback.
## Lookup order: active locale, then zh_CN, then "[key]" so gaps are visible.
## Named placeholders use {name} syntax.

signal locale_changed(code: String)

const LOCALE_DIR := "res://content/localization/"
const DEFAULT_LOCALE := "zh_CN"
const SUPPORTED := ["zh_CN", "en"]

var locale: String = DEFAULT_LOCALE
var _tables: Dictionary = {}


const FONT_PATH := "res://fonts/NotoSansSC-subset.otf"
## Tried, in order, for any character the bundled subset font lacks (desktop systems; the web has none, so it shows a box).
const SYSTEM_FONT_NAMES := ["Noto Sans CJK SC", "Microsoft YaHei", "PingFang SC", "WenQuanYi Micro Hei", "sans-serif"]

var _font: FontFile = null
var _own_chars: Dictionary = {}


func _ready() -> void:
	for code in SUPPORTED:
		_load_locale(code)
	_setup_font_fallback()


func _setup_font_fallback() -> void:
	_font = load(FONT_PATH) as FontFile
	if _font != null and _font.fallbacks.is_empty():
		var sys := SystemFont.new()
		sys.font_names = PackedStringArray(SYSTEM_FONT_NAMES)
		_font.fallbacks = [sys]


## Characters of `text` that the bundled font cannot draw (they rely on the system fallback font).
func missing_glyphs(text: String) -> Array:
	var out: Array = []
	if _font == null:
		return out
	if _own_chars.is_empty():  # has_char would also count the system fallback, so use the font's own character list
		var keep := _font.fallbacks
		_font.fallbacks = []
		var own := _font.get_supported_chars()
		_font.fallbacks = keep
		for i in own.length():
			_own_chars[own.unicode_at(i)] = true
	for i in text.length():
		var c := text.unicode_at(i)
		if c > 32 and not _own_chars.has(c) and not out.has(text[i]):
			out.append(text[i])
	return out


func _load_locale(code: String) -> void:
	var path := "%s%s.json" % [LOCALE_DIR, code]
	if not FileAccess.file_exists(path):
		_tables[code] = {}
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_tables[code] = parsed if parsed is Dictionary else {}


func set_locale(code: String) -> void:
	if code == locale or not SUPPORTED.has(code):
		return
	locale = code
	locale_changed.emit(code)


func has_key(key: String, code: String = "") -> bool:
	var c := code if code != "" else locale
	return _tables.get(c, {}).has(key)


func all_keys(code: String = DEFAULT_LOCALE) -> Array:
	return _tables.get(code, {}).keys()


## Text variables available to every string, e.g. {hero} (set by the game session).
var globals: Dictionary = {}


func t(key: String, params: Dictionary = {}) -> String:
	var text: String = ""
	if _tables.get(locale, {}).has(key):
		text = _tables[locale][key]
	elif _tables.get(DEFAULT_LOCALE, {}).has(key):
		text = _tables[DEFAULT_LOCALE][key]
	else:
		return "[%s]" % key
	for p in params:
		text = text.replace("{%s}" % p, str(params[p]))
	for g in globals:
		text = text.replace("{%s}" % g, str(globals[g]))
	return text
