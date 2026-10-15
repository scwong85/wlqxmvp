extends "res://scenes/shared/chibi_skin.gd"
## The built-in chibi skin: everything is drawn with shapes (original design). Figure space is x -0.5..0.5, y 0..1.5.

const OUTLINE := Color(0.06, 0.1, 0.1, 0.9)

var _ci: CanvasItem
var _o: Vector2
var _s: float
var _lean: float = 0.0
var _pivot := Vector2(0, 1.2)


func _p(x: float, y: float) -> Vector2:
	return _o + Vector2(x, y) * _s


## Upper-body point: rotated by the lean around the hips.
func _u(x: float, y: float) -> Vector2:
	var v := Vector2(x, y) - _pivot
	return _p(_pivot.x + v.x * cos(_lean) - v.y * sin(_lean), _pivot.y + v.x * sin(_lean) + v.y * cos(_lean))


static func pose_params(pose: String, t: float) -> Dictionary:
	var sw := sin(t * 6.0)
	match pose:
		"walk": return {"lean": 0.04, "yoff": absf(sw) * 0.02, "la": sw * 0.7, "ra": -sw * 0.7, "tilt": 0.0}
		"bow": return {"lean": 0.55, "yoff": 0.0, "la": 0.3, "ra": 0.3, "tilt": 0.0}
		"laugh": return {"lean": -0.08, "yoff": absf(sin(t * 9.0)) * 0.04, "la": 0.9, "ra": 0.9, "tilt": sin(t * 9.0) * 0.08, "face": "happy"}
		"cry": return {"lean": 0.1, "yoff": 0.0, "la": 2.6, "ra": 2.6, "tilt": sin(t * 12.0) * 0.03, "face": "sad"}
		"angry": return {"lean": 0.0, "yoff": 0.0, "la": 0.5, "ra": 0.5, "tilt": 0.0, "face": "angry"}
		"think": return {"lean": 0.0, "yoff": 0.0, "la": 0.2, "ra": 2.3, "tilt": 0.12}
		"hit": return {"lean": -0.35, "yoff": 0.0, "la": 1.2, "ra": 1.0, "tilt": sin(t * 20.0) * 0.06, "face": "surprised"}
		"victory": return {"lean": -0.05, "yoff": absf(sin(t * 5.0)) * 0.05, "la": 2.9, "ra": 2.9, "tilt": 0.0, "face": "happy"}
		"kneel": return {"lean": 0.08, "yoff": 0.2, "la": 0.3, "ra": 0.8, "tilt": 0.0}
		"train": return {"lean": 0.05, "yoff": 0.0, "la": 1.57 if sw > 0 else 0.3, "ra": 0.3 if sw > 0 else 1.57, "tilt": 0.0}
		"sword": return {"lean": 0.1, "yoff": 0.0, "la": 0.4, "ra": 1.2 + sin(t * 5.0) * 1.1, "tilt": 0.0, "prop": "sword"}
		"fish": return {"lean": 0.05, "yoff": 0.0, "la": 0.6, "ra": 1.0 + sin(t * 2.0) * 0.15, "tilt": 0.0, "prop": "rod"}
		"mine": return {"lean": 0.05, "yoff": 0.0, "la": 2.0 + sin(t * 5.0) * 0.9, "ra": 2.0 + sin(t * 5.0) * 0.9, "tilt": 0.0, "prop": "pick"}
		"music": return {"lean": 0.0, "yoff": 0.0, "la": 1.3, "ra": 1.3, "tilt": sin(t * 3.0) * 0.05, "prop": "flute"}
		"chess": return {"lean": 0.1, "yoff": 0.0, "la": 0.3, "ra": 1.1 + sin(t * 1.5) * 0.1, "tilt": 0.05, "prop": "stone"}
	return {"lean": 0.0, "yoff": sin(t * 2.0) * 0.012, "la": 0.15, "ra": 0.15, "tilt": 0.0}


func draw(ci: CanvasItem, rect: Rect2, look: Dictionary, pose: String, face: String, t: float) -> void:
	_ci = ci
	_s = minf(rect.size.x, rect.size.y / 1.5)
	if _s <= 1.0:
		return
	var prm := pose_params(pose, t)
	_o = Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 1.48 * _s)
	_o.y += float(prm.yoff) * _s
	_lean = float(prm.lean)
	var col := colors_of(look)
	var female := str(look.get("gender", "m")) == "f"
	var hair_style := int(look.get("hair", 0))
	var f := str(prm.get("face", face)) if face == "neutral" else face

	# Legs and shoes (kneeling shortens them).
	var kneel := pose == "kneel"
	var leg_top := 1.2
	var leg_bot := 1.38 if not kneel else 1.3
	var wob := 0.0 if pose != "walk" else sin(t * 6.0) * 0.06
	_ci.draw_line(_p(-0.09 + wob, leg_top), _p(-0.1 + wob, leg_bot), col.outfit.darkened(0.45), 0.1 * _s)
	_ci.draw_line(_p(0.09 - wob, leg_top), _p(0.1 - wob, leg_bot), col.outfit.darkened(0.45), 0.1 * _s)
	_ci.draw_circle(_p(-0.1 + wob, leg_bot + 0.02), 0.06 * _s, Color("1a1f1f"))
	_ci.draw_circle(_p(0.1 - wob, leg_bot + 0.02), 0.06 * _s, Color("1a1f1f"))

	# Far arm and weapon behind the body, then body.
	_arm(-1, float(prm.la), col, look, prm)
	var hem := 0.2 if female else 0.15
	var robe := PackedVector2Array([_u(-0.17, 0.66), _u(0.17, 0.66), _u(0.17 + hem * 0.4, 1.22), _u(-0.17 - hem * 0.4, 1.22)])
	_ci.draw_colored_polygon(robe, col.outfit)
	_ci.draw_polyline(robe + PackedVector2Array([robe[0]]), OUTLINE, 0.012 * _s)
	_ci.draw_line(_u(-0.17, 0.98), _u(0.17, 0.98), col.outfit.lightened(0.35), 0.05 * _s)   # sash
	var collar := PackedVector2Array([_u(-0.1, 0.66), _u(0.0, 0.8), _u(0.1, 0.66), _u(0.05, 0.64), _u(0.0, 0.7), _u(-0.05, 0.64)])
	_ci.draw_colored_polygon(collar, Color("ece6cf"))
	_arm(1, float(prm.ra), col, look, prm)

	# Head: back hair, face, front hair, features.
	var tilt := float(prm.tilt)
	var hc := _u(0.0 + tilt, 0.4)
	var hr := 0.3 * _s
	if hair_style == 3:
		_ci.draw_rect(Rect2(hc + Vector2(-hr * 1.02, 0), Vector2(hr * 2.04, hr * 1.5)), col.hair)
	if hair_style == 1:
		var tail := PackedVector2Array([hc + Vector2(hr * 0.8, -hr * 0.2), hc + Vector2(hr * 1.5, hr * 0.2 + sin(t * 2.0) * hr * 0.1), hc + Vector2(hr * 1.3, hr * 1.1), hc + Vector2(hr * 0.7, hr * 0.5)])
		_ci.draw_colored_polygon(tail, col.hair)
	_ci.draw_circle(hc, hr, col.skin)
	_ci.draw_arc(hc, hr, 0.0, TAU, 40, OUTLINE, 0.012 * _s, true)
	var cap := PackedVector2Array()
	for i in range(0, 17):
		var a := PI + PI * float(i) / 16.0
		cap.append(hc + Vector2(cos(a), sin(a)) * hr * 1.04)
	for i in range(0, 5):   # fringe
		cap.append(hc + Vector2(hr * (0.9 - 0.45 * i), -hr * (0.22 + 0.06 * (i % 2))))
	_ci.draw_colored_polygon(cap, col.hair)
	if hair_style == 0:
		_ci.draw_circle(hc + Vector2(0, -hr * 1.12), hr * 0.3, col.hair)
		_ci.draw_line(hc + Vector2(-hr * 0.2, -hr * 0.95), hc + Vector2(hr * 0.2, -hr * 0.95), Color("e1c06b"), 0.02 * _s)
	if bool(look.get("elder", false)):   # white brows and a beard line
		_ci.draw_line(hc + Vector2(-hr * 0.5, hr * 0.62), hc + Vector2(0, hr * 0.98), Color("e8e8e0"), 0.04 * _s)
		_ci.draw_line(hc + Vector2(hr * 0.5, hr * 0.62), hc + Vector2(0, hr * 0.98), Color("e8e8e0"), 0.04 * _s)
	_face(hc, hr, f, t)


func _arm(side: int, ang: float, col: Dictionary, look: Dictionary, prm: Dictionary) -> void:
	var sh := _u(0.19 * side, 0.74)
	var length := 0.26 * _s
	var hand := sh + Vector2(sin(ang) * side, cos(ang)) * length
	_ci.draw_line(sh, hand, col.outfit.lightened(0.1), 0.085 * _s)
	_ci.draw_circle(hand, 0.05 * _s, col.skin)
	if side == 1:
		_prop(hand, ang, look, prm)


func _prop(hand: Vector2, ang: float, look: Dictionary, prm: Dictionary) -> void:
	var p := str(prm.get("prop", ""))
	var w := str(look.get("weapon", ""))
	var dir := Vector2(sin(ang), cos(ang)).normalized()
	var up := Vector2(-dir.y, dir.x) if dir.x >= 0 else Vector2(dir.y, -dir.x)
	if p == "sword" or (p == "" and (w == "sword" or w == "blade") and ang < 0.6):
		var tip := hand + Vector2(0.12, -0.38) * _s if p == "" else hand + dir * 0.36 * _s
		_ci.draw_line(hand, tip, Color("dfe6e3"), 0.035 * _s)
		_ci.draw_line(hand + Vector2(-0.05, 0.0) * _s, hand + Vector2(0.05, 0.0) * _s, Color("e1c06b"), 0.03 * _s)
	elif p == "rod":
		_ci.draw_line(hand, hand + Vector2(0.4, -0.42) * _s, Color("8a6a3a"), 0.02 * _s)
		_ci.draw_line(hand + Vector2(0.4, -0.42) * _s, hand + Vector2(0.4, -0.05) * _s, Color(1, 1, 1, 0.6), 0.008 * _s)
	elif p == "pick":
		_ci.draw_line(hand, hand + Vector2(0.0, -0.3) * _s, Color("8a6a3a"), 0.03 * _s)
		_ci.draw_line(hand + Vector2(-0.12, -0.3) * _s, hand + Vector2(0.12, -0.3) * _s, Color("aab2b0"), 0.04 * _s)
	elif p == "flute":
		_ci.draw_line(hand + Vector2(-0.2, 0.0) * _s, hand + Vector2(0.18, -0.04) * _s, Color("6aa86a"), 0.03 * _s)
	elif p == "stone":
		_ci.draw_circle(hand + Vector2(0.0, -0.04) * _s, 0.03 * _s, Color("f2f2ee"))
	elif w == "staff":
		_ci.draw_line(hand + Vector2(0.0, 0.3) * _s, hand + Vector2(0.0, -0.55) * _s, Color("8a6a3a"), 0.035 * _s)
	elif w == "herb":
		_ci.draw_circle(hand + Vector2(0.04, 0.05) * _s, 0.07 * _s, Color("7a5a2e"))
		_ci.draw_circle(hand + Vector2(0.04, -0.02) * _s, 0.04 * _s, Color("5fa86a"))
	elif w == "fan":
		_ci.draw_circle(hand + Vector2(0.03, -0.05) * _s, 0.09 * _s, Color("e8e2c8"))
	elif w == "sword" or w == "blade":
		_ci.draw_line(hand + Vector2(0.0, 0.05) * _s, hand + Vector2(0.1, -0.35) * _s, Color("dfe6e3"), 0.03 * _s)


func _face(hc: Vector2, hr: float, f: String, t: float) -> void:
	var ey := hc.y + hr * 0.12
	var ex := hr * 0.4
	var blink := fmod(t, 3.6) > 3.45
	match f:
		"happy":
			for sx in [-1.0, 1.0]:
				_ci.draw_arc(Vector2(hc.x + sx * ex, ey + hr * 0.04), hr * 0.12, PI * 1.1, PI * 1.9, 8, OUTLINE, 0.02 * _s, true)
			_ci.draw_arc(Vector2(hc.x, hc.y + hr * 0.42), hr * 0.2, 0.15, PI - 0.15, 10, OUTLINE, 0.02 * _s, true)
		"sad":
			for sx in [-1.0, 1.0]:
				_ci.draw_circle(Vector2(hc.x + sx * ex, ey), hr * 0.08, OUTLINE)
				_ci.draw_line(Vector2(hc.x + sx * ex * 1.5, ey - hr * 0.3 + sx * hr * 0.05), Vector2(hc.x + sx * ex * 0.5, ey - hr * 0.2 - sx * hr * 0.05), OUTLINE, 0.018 * _s)
			_ci.draw_arc(Vector2(hc.x, hc.y + hr * 0.66), hr * 0.16, PI * 1.15, PI * 1.85, 8, OUTLINE, 0.02 * _s, true)
			_ci.draw_circle(Vector2(hc.x - ex, ey + hr * 0.3 + fmod(t * 0.6, 1.0) * hr * 0.3), hr * 0.05, Color("9fd4ff"))
		"angry":
			for sx in [-1.0, 1.0]:
				_ci.draw_circle(Vector2(hc.x + sx * ex, ey), hr * 0.08, OUTLINE)
				_ci.draw_line(Vector2(hc.x + sx * ex * 1.6, ey - hr * 0.18 - hr * 0.1), Vector2(hc.x + sx * ex * 0.5, ey - hr * 0.3 + hr * 0.1), OUTLINE, 0.025 * _s)
			_ci.draw_line(Vector2(hc.x - hr * 0.15, hc.y + hr * 0.5), Vector2(hc.x + hr * 0.15, hc.y + hr * 0.5), OUTLINE, 0.02 * _s)
		"surprised":
			for sx in [-1.0, 1.0]:
				_ci.draw_circle(Vector2(hc.x + sx * ex, ey), hr * 0.13, Color.WHITE)
				_ci.draw_circle(Vector2(hc.x + sx * ex, ey), hr * 0.06, OUTLINE)
			_ci.draw_circle(Vector2(hc.x, hc.y + hr * 0.5), hr * 0.09, OUTLINE)
		_:
			for sx in [-1.0, 1.0]:
				if blink:
					_ci.draw_line(Vector2(hc.x + sx * ex - hr * 0.08, ey), Vector2(hc.x + sx * ex + hr * 0.08, ey), OUTLINE, 0.018 * _s)
				else:
					_ci.draw_circle(Vector2(hc.x + sx * ex, ey), hr * 0.09, OUTLINE)
			_ci.draw_line(Vector2(hc.x - hr * 0.1, hc.y + hr * 0.5), Vector2(hc.x + hr * 0.1, hc.y + hr * 0.5), OUTLINE, 0.018 * _s)
	_ci.draw_circle(Vector2(hc.x - hr * 0.62, hc.y + hr * 0.38), hr * 0.12, Color(1, 0.55, 0.5, 0.35))
	_ci.draw_circle(Vector2(hc.x + hr * 0.62, hc.y + hr * 0.38), hr * 0.12, Color(1, 0.55, 0.5, 0.35))
