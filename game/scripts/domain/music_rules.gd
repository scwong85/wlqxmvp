extends RefCounted
## Which music track fits the moment (pure rules). The catalog and mapping live in content/audio/music.json:
## scenes (by Router key), regions (exploration), backgrounds (dialogue stage), events (per scene overrides), battles.
## Priority: event override, then battle kind, then dialogue background, then screen, then region.

const CATALOG_PATH := "res://content/audio/music.json"


static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return parsed if parsed is Dictionary else {}


## context: {scene, bg, event_id, scenario_id, region}. Returns a track id from the catalog's rules.
static func track_for(context: Dictionary, catalog: Dictionary) -> String:
	var rules: Dictionary = catalog.get("rules", {})
	var scene := str(context.get("scene", ""))
	var fallback := str(rules.get("fallback", ""))
	var event_id := str(context.get("event_id", ""))
	if scene == "dialogue":
		if event_id != "" and rules.get("events", {}).has(event_id):
			return str(rules.events[event_id])
		var bg := str(context.get("bg", ""))
		var bgs: Dictionary = rules.get("backgrounds", {})
		return str(bgs.get(bg, bgs.get("default", fallback)))
	if scene == "battle":
		var sid := str(context.get("scenario_id", ""))
		var b: Dictionary = rules.get("battles", {})
		if b.get("boss", []).has(sid):
			return "boss_theme"
		if b.get("duel", []).has(sid):
			return "duel_theme"
		return str(b.get("default", fallback))
	if scene == "exploration" or scene == "map":
		if scene == "exploration" or str(context.get("region", "")) != "":
			var regions: Dictionary = rules.get("regions", {})
			return str(regions.get(str(context.get("region", "")), rules.scenes.get(scene, fallback)))
	var scenes: Dictionary = rules.get("scenes", {})
	return str(scenes.get(scene, fallback))


static func sting_for(kind: String, catalog: Dictionary) -> String:
	return str(catalog.get("rules", {}).get("stings", {}).get(kind, ""))


static func track_file(track_id: String, catalog: Dictionary) -> String:
	for t in catalog.get("tracks", []):
		if str(t.id) == track_id:
			return str(t.file)
	return ""
