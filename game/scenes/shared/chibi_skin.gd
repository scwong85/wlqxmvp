extends RefCounted
## Skin interface for chibi characters. A skin draws one character onto any CanvasItem, inside `rect`, from a look,
## a pose, a face and a time. The built-in skin draws shapes in code; a sprite-sheet skin can replace it later by
## overriding `draw` (same inputs), so no screen or rule needs to change.

const LookRules = preload("res://scripts/domain/look_rules.gd")


func draw(_ci: CanvasItem, _rect: Rect2, _look: Dictionary, _pose: String, _face: String, _t: float) -> void:
	pass


## Colours for a look: the hero's table indices, or an NPC's explicit hex values.
static func colors_of(look: Dictionary) -> Dictionary:
	var base := LookRules.colors(look)
	if look.has("hair_hex"):
		base.hair = Color(str(look.hair_hex))
	if look.has("outfit_hex"):
		base.outfit = Color(str(look.outfit_hex))
	if look.has("skin_hex"):
		base.skin = Color(str(look.skin_hex))
	return base
