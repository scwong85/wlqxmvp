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


func _ready() -> void:
	for code in SUPPORTED:
		_load_locale(code)


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
	return text
