extends RefCounted
## The hero's chosen name, gender and chibi look. Pure data and validation; the chibi rig reads it.

const GENDERS := ["m", "f"]
const HAIR_STYLES := 4                       # 0 topknot, 1 ponytail, 2 short, 3 long
const HAIR_COLORS := ["17201f", "4a3220", "8a5a2b", "c9c2b0", "2b3a67"]
const OUTFIT_COLORS := ["2f7a6a", "8a3b3b", "3d5a99", "7b5a2e", "5b4a8a"]
const SKINS := ["e9cfae", "d9b08c", "b88a64"]
const MAX_NAME := 8


static func default_look() -> Dictionary:
	return {"gender": "m", "hair": 0, "hair_color": 0, "outfit": 0, "skin": 0}


## Always returns a complete, in-range look (unknown or broken input falls back to defaults).
static func sanitize(d: Variant) -> Dictionary:
	var out := default_look()
	if not (d is Dictionary):
		return out
	if GENDERS.has(str(d.get("gender", ""))):
		out.gender = str(d.gender)
	out.hair = clampi(int(d.get("hair", 0)), 0, HAIR_STYLES - 1)
	out.hair_color = clampi(int(d.get("hair_color", 0)), 0, HAIR_COLORS.size() - 1)
	out.outfit = clampi(int(d.get("outfit", 0)), 0, OUTFIT_COLORS.size() - 1)
	out.skin = clampi(int(d.get("skin", 0)), 0, SKINS.size() - 1)
	return out


## Trims, limits to MAX_NAME characters and strips control characters / braces (names go into text templates).
static func clean_name(raw: String) -> String:
	var s := ""
	for i in raw.length():
		var ch := raw.substr(i, 1)
		if ch.unicode_at(0) < 32 or ch == "{" or ch == "}" or ch == "[" or ch == "]":
			continue
		s += ch
	s = s.strip_edges()
	if s.length() > MAX_NAME:
		s = s.substr(0, MAX_NAME)
	return s


## Colours for the rig: hex strings from the look tables, or an NPC's own explicit colours.
static func colors(look: Dictionary) -> Dictionary:
	var l := sanitize(look)
	return {"hair": Color(HAIR_COLORS[l.hair_color]), "outfit": Color(OUTFIT_COLORS[l.outfit]), "skin": Color(SKINS[l.skin])}
