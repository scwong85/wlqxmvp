extends Node
## Minimal localization service for the engine spike.
## Mandarin (zh_CN) is the default. Missing keys in the active locale fall back to zh_CN.
## Named placeholders use {name} syntax.

const LOCALE_DIR := "res://content/localization/"
const DEFAULT_LOCALE := "zh_CN"

var locale: String = DEFAULT_LOCALE
var _tables: Dictionary = {}


func _ready() -> void:
	_load_locale(DEFAULT_LOCALE)
	_load_locale("en")


func _load_locale(code: String) -> void:
	var path := "%s%s.json" % [LOCALE_DIR, code]
	if not FileAccess.file_exists(path):
		_tables[code] = {}
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_tables[code] = parsed if parsed is Dictionary else {}


func set_locale(code: String) -> void:
	locale = code


func has_key(key: String, code: String = "") -> bool:
	var c := code if code != "" else locale
	return _tables.get(c, {}).has(key)


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
